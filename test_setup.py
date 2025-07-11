#!/usr/bin/env python3
"""
Test script for Nomic Embedding Load Balancer
"""

import json
import sys
import time

import requests


def test_embedding_service(base_url="http://localhost:11000"):
    """Test the embedding service"""
    
    print(f"Testing Nomic Embedding Service at {base_url}")
    print("=" * 50)
    
    # Test 1: Check if service is running
    try:
        response = requests.get(f"{base_url}/api/tags", timeout=10)
        if response.status_code == 200:
            print("✅ Service is running")
        else:
            print(f"❌ Service returned status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to service: {e}")
        return False
    
    # Test 2: Test embedding generation
    test_prompts = [
        "Hello world",
        "This is a test sentence for embedding generation",
        "Machine learning is fascinating"
    ]
    
    print("\nTesting embedding generation...")
    for i, prompt in enumerate(test_prompts, 1):
        try:
            payload = {
                "model": "nomic-embed-text",
                "prompt": prompt
            }
            
            response = requests.post(
                f"{base_url}/api/embeddings",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                embedding = result.get("embedding", [])
                print(f"✅ Test {i}: Generated embedding with {len(embedding)} dimensions")
            else:
                print(f"❌ Test {i}: Failed with status {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Test {i}: Request failed: {e}")
            return False
    
    # Test 3: Test load balancing (multiple requests)
    print("\nTesting load balancing with multiple requests...")
    start_time = time.time()
    
    try:
        for i in range(10):
            payload = {
                "model": "nomic-embed-text",
                "prompt": f"Load balancing test request {i+1}"
            }
            
            response = requests.post(
                f"{base_url}/api/embeddings",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            if response.status_code != 200:
                print(f"❌ Load balancing test {i+1} failed")
                return False
        
        end_time = time.time()
        print(f"✅ Load balancing test completed in {end_time - start_time:.2f} seconds")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Load balancing test failed: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 All tests passed! The Nomic Embedding Load Balancer is working correctly.")
    return True

if __name__ == "__main__":
    # Allow custom URL
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:11000"
    
    success = test_embedding_service(base_url)
    sys.exit(0 if success else 1) 