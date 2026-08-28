import json
import requests
import os

API_KEY = os.environ.get("NVIDIA_API_KEY")
API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}
payload = {
    "model": "ibm/granite-3.0-8b-instruct",
    "messages": [
        {"role": "user", "content": "Return {\"test\": 1} as JSON"}
    ]
}

resp = requests.post(API_URL, headers=headers, json=payload)
print(resp.status_code)
print(resp.text)
