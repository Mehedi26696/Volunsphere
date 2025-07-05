#!/usr/bin/env python3

# Simple test script to validate database connection
import os
import sys

# Add the backend directory to Python path
sys.path.insert(0, '/app/backend')

try:
    from src.config import Config
    print(f"✅ Config loaded successfully")
    print(f"Environment: {Config.ENVIRONMENT}")
    print(f"Database URL (first 20 chars): {Config.DATABASE_URL[:20]}...")
    print(f"Sync Database URL (first 20 chars): {Config.sync_database_url[:20]}...")
    print(f"Async Database URL (first 20 chars): {Config.async_database_url[:20]}...")
except Exception as e:
    print(f"❌ Error loading config: {e}")
    sys.exit(1)

try:
    from sqlmodel import SQLModel
    print(f"✅ SQLModel imported successfully")
except Exception as e:
    print(f"❌ Error importing SQLModel: {e}")
    sys.exit(1)

print("🎉 All imports successful!")
