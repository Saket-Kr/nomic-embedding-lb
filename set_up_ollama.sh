#!/bin/bash

# Get configuration from environment variables
START_PORT=${START_PORT:-11001}
NUM_INSTANCES=${NUM_INSTANCES:-6}

echo "Starting $NUM_INSTANCES Ollama instances from port $START_PORT..."

# Function to check if port is in use
port_in_use() {
  local port=$1
  netstat -tuln | grep -q ":$port " && return 0 || return 1
}

# Function to kill process on port
kill_process_on_port() {
  local port=$1
  local pid=$(lsof -t -i:$port)
  
  if [ -n "$pid" ]; then
    echo "  → Found process $pid using port $port. Killing it..."
    kill -9 $pid
    sleep 1
    return 0
  else
    echo "  → No process found using port $port, but port appears busy. Strange!"
    return 1
  fi
}

declare -a PIDS

# Start Ollama instances
for i in $(seq 0 $(($NUM_INSTANCES-1))); do
  PORT=$(($START_PORT + $i))
  
  if port_in_use $PORT; then
    echo "Port $PORT is already in use. Attempting to kill existing process..."
    kill_process_on_port $PORT
    if port_in_use $PORT; then
      echo "  → Failed to free up port $PORT. Skipping this instance."
      continue
    fi
  fi
  
  echo "Starting Ollama instance #$((i+1)) on port $PORT..."
  nohup env OLLAMA_HOST="0.0.0.0:$PORT" ollama serve > /dev/null 2>&1 &
  
  PID=$!
  PIDS[$i]=$PID
  echo "  → Process ID: $PID"
  
  sleep 2
done

echo "All Ollama instances started."
echo "Started PIDs: ${PIDS[*]}"

# Wait a bit for instances to fully start
echo "Waiting for instances to fully start..."
sleep 10

# Pull the nomic-embed-text model for each instance
echo "Pulling 'nomic-embed-text' model for each Ollama instance..."
for i in $(seq 0 $(($NUM_INSTANCES-1))); do
  PORT=$(($START_PORT + $i))
  
  echo "Pulling 'nomic-embed-text' model for instance on port $PORT..."
  if port_in_use $PORT; then
    env OLLAMA_HOST="0.0.0.0:$PORT" ollama pull nomic-embed-text
    if [ $? -eq 0 ]; then
      echo "  → Successfully pulled 'nomic-embed-text' model for instance on port $PORT"
    else
      echo "  → Failed to pull 'nomic-embed-text' model for instance on port $PORT"
    fi
  else
    echo "  → Instance on port $PORT is not running, skipping model pull"
  fi
done

echo "Finished pulling 'nomic-embed-text' model for all running instances"
echo "Ollama setup complete!"

