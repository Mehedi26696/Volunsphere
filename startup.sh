#!/bin/bash
echo "🚀 Starting Volunsphere Backend..."

# Navigate to backend directory
cd backend

echo "⏳ Waiting for database to be ready..."
sleep 5

echo "🔄 Running database migrations..."
python -m alembic upgrade head

if [ $? -eq 0 ]; then
    echo "✅ Migrations completed successfully"
    echo "🌟 Starting FastAPI server..."
    exec python -m uvicorn src:app --host 0.0.0.0 --port $PORT
else
    echo "❌ Migration failed, but starting server anyway..."
    echo "📝 Database tables will be created by FastAPI if needed..."
    exec python -m uvicorn src:app --host 0.0.0.0 --port $PORT
fi
