#!/bin/bash
cd backend
uvicorn src:app --host 0.0.0.0 --port $PORT
