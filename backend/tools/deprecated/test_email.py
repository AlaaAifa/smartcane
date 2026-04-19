import requests
import json

# Test email verification
url = "http://localhost:8000/auth/request-reset"
headers = {"Content-Type": "application/json"}
data = {"email": "aifaalaa97@gmail.com"}

try:
    response = requests.post(url, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
