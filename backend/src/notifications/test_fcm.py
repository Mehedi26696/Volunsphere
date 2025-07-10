from fcm import send_fcm_push

# Replace this with a real device FCM token for testing
TEST_FCM_TOKEN = "dOL_Q1i2QiKAHuQXApHJpt:APA91bGOqt2MSoFEkCewcXeHbRHSdrvnBVysc1ENSu9GXn0p37ksniJSjwDdaCTExLNf6DQQ4t7NfiSf5II9DVwSwsBpVdyQ4vl46449cy2ZHNcl2ulpd6Q"

def main():
    if TEST_FCM_TOKEN == "YOUR_DEVICE_FCM_TOKEN_HERE":
        print("Please set TEST_FCM_TOKEN to a real FCM device token.")
        return
    try:
        response = send_fcm_push(
            token=TEST_FCM_TOKEN,
            title="Test Notification",
            body="This is a test push notification from backend!",
            data={"test": "true"}
        )
        print("Notification sent! Response:", response)
    except Exception as e:
        print("Error sending notification:", e)

if __name__ == "__main__":
    main()
