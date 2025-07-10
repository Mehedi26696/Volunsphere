import firebase_admin
from firebase_admin import credentials, messaging
import os

# Path to your Firebase service account key JSON file
FIREBASE_CRED_PATH = os.getenv("FIREBASE_CRED_PATH", "volunsphere-bce64-6dbdaedacce9.json")

if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CRED_PATH)
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
