#!/usr/bin/env python3
import os
import sys
import subprocess

# Add the current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

print(f"🚀 Starting from: {current_dir}")
print(f"📁 Directory contents: {os.listdir(current_dir)}")

# Check if src directory exists
src_path = os.path.join(current_dir, 'src')
if os.path.exists(src_path):
    print(f"✅ Found src directory: {os.listdir(src_path)}")
else:
    print("❌ src directory not found!")
    sys.exit(1)

# Run migrations first
print("🔄 Running migrations...")
try:
    subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=current_dir, check=True)
    print("✅ Migrations completed")
except subprocess.CalledProcessError as e:
    print(f"⚠️ Migrations failed: {e}")

# Start the server
print("🌟 Starting FastAPI server...")
os.chdir(current_dir)

import uvicorn
from src import app

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
