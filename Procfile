web: cd backend && python -m uvicorn src:app --host 0.0.0.0 --port $PORT
release: cd backend && python -m alembic upgrade head
