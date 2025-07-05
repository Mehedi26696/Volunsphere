#!/bin/bash
echo "Starting Volunsphere API..."
echo "Current directory: $(pwd)"
echo "Contents: $(ls -la)"
cd backend
echo "Changed to backend directory: $(pwd)"
echo "Contents: $(ls -la)"
python -m uvicorn src:app --host 0.0.0.0 --port $PORT
