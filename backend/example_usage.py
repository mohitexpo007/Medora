"""
Example usage of the Clinical Summary API
Demonstrates how to interact with the endpoints
"""

import requests
import json
from pathlib import Path

BASE_URL = "http://localhost:8000"


def create_summary_with_text_notes():
    """Example: Create a summary with text-based raw notes"""
    print("Creating summary with text notes...")
    
    data = {
        "patient_id": "patient-001",
        "patient_name": "Anita Sharma",
        "summary_text": (
            "Patient presents with elevated HbA1c levels and persistent fatigue. "
            "Reports polyuria and polydipsia over the past few months. "
            "Findings suggest poor glycemic control consistent with Type 2 Diabetes Mellitus."
        ),
        "diagnoses": json.dumps(["Type 2 Diabetes Mellitus"]),
        "affected_system": "Endocrine",
        "affected_organ": "Pancreas",
        "animation_asset": "assets/animations/organs/pancreas.mp4",
        "raw_notes_text": (
            "Patient reports increased thirst and frequent urination. "
            "Blood glucose levels consistently elevated. "
            "Family history of Type 2 Diabetes."
        )
    }
    
    response = requests.post(f"{BASE_URL}/summaries", data=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json()


def create_summary_with_pdf_notes(pdf_path: str):
    """Example: Create a summary with PDF raw notes"""
    print(f"Creating summary with PDF notes from {pdf_path}...")
    
    data = {
        "patient_id": "patient-002",
        "patient_name": "Ravi Kumar",
        "summary_text": (
            "Patient reports chest discomfort and shortness of breath on exertion. "
            "Blood pressure readings remain persistently elevated. "
            "Clinical findings are suggestive of hypertension with cardiac involvement."
        ),
        "diagnoses": json.dumps(["Hypertension"]),
        "affected_system": "Cardiovascular",
        "affected_organ": "Heart",
        "animation_asset": "assets/animations/organs/heart.mp4"
    }
    
    files = {
        "raw_notes_file": ("notes.pdf", open(pdf_path, "rb"), "application/pdf")
    }
    
    response = requests.post(f"{BASE_URL}/summaries", data=data, files=files)
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json()


def get_summaries_by_patient(patient_id: str):
    """Example: Fetch all summaries for a patient"""
    print(f"Fetching summaries for patient {patient_id}...")
    
    response = requests.get(f"{BASE_URL}/summaries/by-patient/{patient_id}")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json()


def get_summaries_by_date(target_date: str):
    """Example: Fetch summaries for a specific date"""
    print(f"Fetching summaries for date {target_date}...")
    
    response = requests.get(f"{BASE_URL}/summaries/by-date", params={"date": target_date})
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json()


def get_summary_by_id(summary_id: str):
    """Example: Fetch a single summary by ID"""
    print(f"Fetching summary {summary_id}...")
    
    response = requests.get(f"{BASE_URL}/summaries/{summary_id}")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json()


if __name__ == "__main__":
    print("=" * 60)
    print("Clinical Summary API - Example Usage")
    print("=" * 60)
    print()
    
    # Example 1: Create summary with text notes
    summary = create_summary_with_text_notes()
    summary_id = summary.get("summary_id")
    patient_id = summary.get("patient_id")
    
    print("\n" + "=" * 60 + "\n")
    
    # Example 2: Get summaries by patient
    if patient_id:
        get_summaries_by_patient(patient_id)
    
    print("\n" + "=" * 60 + "\n")
    
    # Example 3: Get summaries by date (today)
    from datetime import datetime
    today = datetime.now().strftime("%Y-%m-%d")
    get_summaries_by_date(today)
    
    print("\n" + "=" * 60 + "\n")
    
    # Example 4: Get single summary
    if summary_id:
        get_summary_by_id(summary_id)
    
    print("\n" + "=" * 60)
    print("Examples completed!")
    print("=" * 60)
