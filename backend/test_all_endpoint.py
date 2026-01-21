"""
Quick test script to verify the /summaries/all endpoint works
Run this after starting the backend server
"""

import requests
import json

def test_all_endpoint():
    base_url = "http://127.0.0.1:8000"
    
    print("Testing /summaries/all endpoint...")
    try:
        response = requests.get(f"{base_url}/summaries/all?limit=10")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success! Found {len(data)} summaries")
            if data:
                print(f"\nFirst summary:")
                print(f"  Patient: {data[0].get('patient_name')}")
                print(f"  Date: {data[0].get('created_at')}")
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_all_endpoint()
