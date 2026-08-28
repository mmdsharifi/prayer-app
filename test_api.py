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
    "model": "nvidia/llama-3.1-nemotron-70b-instruct",
    "messages": [
        {"role": "system", "content": "You are a translator. Output JSON with fields 'fa' and 'ku'."},
        {"role": "user", "content": "Translate 'Hello world' to Persian and Kurdish Sorani."}
    ],
    "temperature": 0.2,
    "response_format": {"type": "json_object"}
}

resp = requests.post(API_URL, headers=headers, json=payload)
print(resp.status_code)
print(resp.text)
