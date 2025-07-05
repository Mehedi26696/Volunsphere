[build]
command = "cd backend && pip install -r requirements.txt"

[start]  
command = "cd backend && uvicorn src:app --host 0.0.0.0 --port $PORT"
