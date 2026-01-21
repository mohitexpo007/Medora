"""
Quick script to check if .env file is being loaded correctly
Run this before starting the server to debug environment variable issues
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env file
env_path = Path(__file__).parent / '.env'
print(f"Looking for .env file at: {env_path}")
print(f"File exists: {env_path.exists()}")

if env_path.exists():
    load_dotenv(env_path)
    print("✓ .env file loaded")
else:
    load_dotenv()
    print("⚠ .env file not found in backend directory, trying current directory")

print("\n" + "=" * 60)
print("Environment Variables Check:")
print("=" * 60)

SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "").strip()
SUPABASE_STORAGE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "clinical-notes").strip()

print(f"SUPABASE_URL: {'✓ Set' if SUPABASE_URL else '✗ Missing'}")
if SUPABASE_URL:
    print(f"  Value: {SUPABASE_URL[:30]}..." if len(SUPABASE_URL) > 30 else f"  Value: {SUPABASE_URL}")

print(f"SUPABASE_KEY: {'✓ Set' if SUPABASE_KEY else '✗ Missing'}")
if SUPABASE_KEY:
    print(f"  Value: {SUPABASE_KEY[:30]}..." if len(SUPABASE_KEY) > 30 else f"  Value: {SUPABASE_KEY}")
    print(f"  Length: {len(SUPABASE_KEY)} characters")
    print(f"  Starts with: {SUPABASE_KEY[:10]}...")
    print(f"  Key type: {'Service Role' if SUPABASE_KEY.startswith('sb_secret_') or 'service_role' in SUPABASE_KEY.lower() else 'Anon/Public' if SUPABASE_KEY.startswith('eyJ') else 'Unknown format'}")

print(f"SUPABASE_STORAGE_BUCKET: {SUPABASE_STORAGE_BUCKET}")

print("\n" + "=" * 60)
if SUPABASE_URL and SUPABASE_KEY:
    print("✓ All required environment variables are set!")
    print("You can now run: uvicorn main:app --reload")
else:
    print("✗ Missing required environment variables!")
    print("\nPlease check your .env file:")
    print(f"  Location: {env_path}")
    print("\nRequired variables:")
    print("  SUPABASE_URL=https://your-project.supabase.co")
    print("  SUPABASE_KEY=your-supabase-anon-key")
    print("  SUPABASE_STORAGE_BUCKET=clinical-notes (optional)")
print("=" * 60)
