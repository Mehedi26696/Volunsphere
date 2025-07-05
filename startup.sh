#!/bin/bash
echo "🚀 Starting Volunsphere Backend..."

# Check current directory
echo "Current directory: $(pwd)"
echo "Directory contents: $(ls -la)"

# Navigate to backend directory
cd backend

echo "After cd backend: $(pwd)"
echo "Backend contents: $(ls -la)"

# Check if src directory exists
if [ -d "src" ]; then
    echo "✅ src directory found"
    echo "src contents: $(ls -la src/)"
else
    echo "❌ src directory not found"
fi

echo "⏳ Waiting for database to be ready..."
sleep 5

echo "🔄 Running database migrations..."
python -m alembic upgrade head

if [ $? -eq 0 ]; then
    echo "✅ Migrations completed successfully"
else
    echo "⚠️ Migration failed, but continuing..."
fi

echo "🌟 Starting FastAPI server..."
echo "Python path: $(which python)"
echo "Current working directory: $(pwd)"

# Start the server
exec python -m uvicorn src:app --host 0.0.0.0 --port $PORT
