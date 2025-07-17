import firebase_admin
from firebase_admin import credentials, messaging
import os
import json

# Load Firebase credentials from environment variable
firebase_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
cred_dict = json.loads(firebase_json)

# Initialize Firebase if not already initialized
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_dict)
    firebase_admin.initialize_app(cred)

def send_fcm_push(token: str, title: str, body: str, data: dict = None):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        token=token,
        data=data or {},
    )
    response = messaging.send(message)
    return response
