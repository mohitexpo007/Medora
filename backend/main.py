"""
FastAPI Backend for Clinical Summary Management
Stores and fetches AI-generated clinical summaries using Supabase
"""

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
import json
import os
from dotenv import load_dotenv
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions
import uuid  # Still needed for PDF filename generation
from pathlib import Path

# Load environment variables from .env file
# Try to load from backend directory first, then current directory
env_path = Path(__file__).parent / '.env'
if env_path.exists():
    load_dotenv(env_path)
else:
    # Fallback to current directory
    load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Medora Clinical Summary API",
    description="API for storing and fetching AI-generated clinical summaries",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "").strip()
SUPABASE_STORAGE_BUCKET = os.getenv("SUPABASE_STORAGE_BUCKET", "clinical-notes").strip()

# Validate environment variables
if not SUPABASE_URL or not SUPABASE_KEY:
    missing_vars = []
    if not SUPABASE_URL:
        missing_vars.append("SUPABASE_URL")
    if not SUPABASE_KEY:
        missing_vars.append("SUPABASE_KEY")
    
    env_file_path = Path(__file__).parent / '.env'
    error_msg = (
        f"Missing required environment variables: {', '.join(missing_vars)}\n"
        f"\nPlease check your .env file:\n"
        f"  Expected location: {env_file_path}\n"
        f"  File exists: {env_file_path.exists()}\n"
        f"  Current working directory: {os.getcwd()}\n"
        f"\nYour .env file should contain:\n"
        f"  SUPABASE_URL=https://your-project.supabase.co\n"
        f"  SUPABASE_KEY=your-supabase-anon-key\n"
        f"  SUPABASE_STORAGE_BUCKET=clinical-notes\n"
        f"\nRun 'python check_env.py' to verify your .env file is being loaded correctly."
    )
    raise ValueError(error_msg)

# Initialize Supabase client
try:
    supabase: Client = create_client(
        SUPABASE_URL,
        SUPABASE_KEY,
        options=ClientOptions(
            auto_refresh_token=True,
            persist_session=False
        )
    )
except Exception as e:
    raise ValueError(
        f"Failed to initialize Supabase client: {str(e)}\n"
        f"Please verify your SUPABASE_URL and SUPABASE_KEY in the .env file."
    )


# ==================== DATA MODELS ====================

# Note: SummaryCreate is not used directly since we use Form data
# Keeping for documentation purposes


class SummaryResponse(BaseModel):
    """Response model for summary data"""
    summary_id: str
    patient_id: str
    patient_name: str
    summary_text: str
    diagnoses: List[str]
    affected_system: Optional[str]
    affected_organ: Optional[str]
    animation_asset: Optional[str]
    raw_notes_type: str  # "text" | "pdf" | "none"
    raw_notes_text: Optional[str]
    raw_notes_file_url: Optional[str]
    created_at: datetime


class SummaryListItem(BaseModel):
    """Simplified summary for list views"""
    summary_id: str
    patient_name: str
    summary_text: str
    affected_organ: Optional[str]
    animation_asset: Optional[str]
    created_at: datetime


# ==================== HELPER FUNCTIONS ====================

async def upload_pdf_to_supabase(file: UploadFile, patient_id: str) -> str:
    """
    Upload PDF file to Supabase Storage and return public URL
    
    Args:
        file: The uploaded PDF file
        patient_id: Patient ID for organizing files
        
    Returns:
        Public URL of the uploaded file
    """
    try:
        # Generate unique filename
        file_extension = Path(file.filename).suffix or ".pdf"
        unique_filename = f"{patient_id}/{uuid.uuid4()}{file_extension}"
        
        # Read file content
        file_content = await file.read()
        
        # Upload to Supabase Storage
        response = supabase.storage.from_(SUPABASE_STORAGE_BUCKET).upload(
            unique_filename,
            file_content,
            file_options={"content-type": "application/pdf"}
        )
        
        # Get public URL
        public_url = supabase.storage.from_(SUPABASE_STORAGE_BUCKET).get_public_url(unique_filename)
        
        return public_url
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload PDF: {str(e)}"
        )


def determine_notes_type(raw_notes_text: Optional[str], raw_notes_file: Optional[UploadFile]) -> str:
    """Determine the type of raw notes provided"""
    if raw_notes_file:
        return "pdf"
    elif raw_notes_text:
        return "text"
    else:
        return "none"


def parse_supabase_datetime(datetime_str: str) -> datetime:
    """
    Parse datetime string from Supabase (handles both 'Z' and timezone formats)
    
    Args:
        datetime_str: ISO format datetime string from Supabase
        
    Returns:
        datetime object
    """
    if datetime_str.endswith('Z'):
        return datetime.fromisoformat(datetime_str.replace('Z', '+00:00'))
    elif '+' in datetime_str or datetime_str.count('-') > 2:
        # Has timezone info
        return datetime.fromisoformat(datetime_str)
    else:
        # No timezone, assume UTC
        return datetime.fromisoformat(datetime_str + '+00:00')


# ==================== API ENDPOINTS ====================

@app.post("/summaries", response_model=SummaryResponse, status_code=201)
async def create_summary(
    patient_id: str = Form(...),
    patient_name: str = Form(...),
    summary_text: str = Form(...),
    diagnoses: str = Form(default="[]"),  # JSON string array
    affected_system: Optional[str] = Form(None),
    affected_organ: Optional[str] = Form(None),
    animation_asset: Optional[str] = Form(None),
    raw_notes_text: Optional[str] = Form(None),
    raw_notes_file: Optional[UploadFile] = File(None)
):
    """
    Store a new clinical summary with optional raw notes
    
    Accepts multipart/form-data:
    - Required: patient_id, patient_name, summary_text
    - Optional: raw_notes_text (string) OR raw_notes_file (PDF)
    - Optional: diagnoses (JSON array string), affected_system, affected_organ, animation_asset
    
    If raw_notes_file is provided, it will be uploaded to Supabase Storage.
    """
    try:
        # Parse diagnoses from JSON string
        try:
            diagnoses_list = json.loads(diagnoses) if diagnoses else []
            if not isinstance(diagnoses_list, list):
                raise ValueError("Diagnoses must be a JSON array")
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=400,
                detail="Invalid JSON format for diagnoses field. Expected JSON array."
            )
        
        # Validate inputs
        if not patient_id or not patient_id.strip():
            raise HTTPException(status_code=400, detail="patient_id is required")
        if not patient_name or not patient_name.strip():
            raise HTTPException(status_code=400, detail="patient_name is required")
        if not summary_text or not summary_text.strip():
            raise HTTPException(status_code=400, detail="summary_text is required")
        
        # Validate that either text or file is provided, not both
        if raw_notes_text and raw_notes_file:
            raise HTTPException(
                status_code=400,
                detail="Cannot provide both raw_notes_text and raw_notes_file. Choose one."
            )
        
        # Determine notes type
        notes_type = determine_notes_type(raw_notes_text, raw_notes_file)
        
        # Handle PDF upload if provided
        raw_notes_file_url = None
        if raw_notes_file:
            # Validate file type
            if not raw_notes_file.filename.endswith('.pdf'):
                raise HTTPException(
                    status_code=400,
                    detail="Only PDF files are allowed for raw_notes_file"
                )
            raw_notes_file_url = await upload_pdf_to_supabase(raw_notes_file, patient_id)
        
        # Prepare data for Supabase
        # Note: summary_id and created_at will be generated by the database
        summary_data = {
            "patient_id": patient_id,
            "patient_name": patient_name,
            "summary_text": summary_text,
            "diagnoses": diagnoses_list,  # Supabase will convert list to JSONB
            "affected_system": affected_system,
            "affected_organ": affected_organ,
            "animation_asset": animation_asset,
            "raw_notes_type": notes_type,
            "raw_notes_text": raw_notes_text,
            "raw_notes_file_url": raw_notes_file_url,
            # created_at will be set by database DEFAULT NOW()
        }
        
        # Insert into Supabase
        response = supabase.table("clinical_summaries").insert(summary_data).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=500,
                detail="Failed to create summary in database"
            )
        
        # Return created summary
        created_summary = response.data[0]
        
        return SummaryResponse(
            summary_id=str(created_summary["summary_id"]),  # Ensure UUID is converted to string
            patient_id=created_summary["patient_id"],
            patient_name=created_summary["patient_name"],
            summary_text=created_summary["summary_text"],
            diagnoses=created_summary["diagnoses"] if isinstance(created_summary["diagnoses"], list) else [],
            affected_system=created_summary.get("affected_system"),
            affected_organ=created_summary.get("affected_organ"),
            animation_asset=created_summary.get("animation_asset"),
            raw_notes_type=created_summary["raw_notes_type"],
            raw_notes_text=created_summary.get("raw_notes_text"),
            raw_notes_file_url=created_summary.get("raw_notes_file_url"),
            created_at=parse_supabase_datetime(created_summary["created_at"])
        )
        
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=400,
            detail="Invalid JSON format for diagnoses field"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error creating summary: {str(e)}"
        )


@app.get("/summaries/by-patient/{patient_id}", response_model=List[SummaryListItem])
async def get_summaries_by_patient(patient_id: str):
    """
    Fetch all summaries for a specific patient
    
    Returns summaries sorted by created_at DESC (most recent first)
    """
    try:
        response = supabase.table("clinical_summaries")\
            .select("summary_id, patient_name, summary_text, affected_organ, animation_asset, created_at")\
            .eq("patient_id", patient_id)\
            .order("created_at", desc=True)\
            .execute()
        
        if not response.data:
            return []
        
        return [
            SummaryListItem(
                summary_id=str(item["summary_id"]),  # Ensure UUID is converted to string
                patient_name=item["patient_name"],
                summary_text=item["summary_text"],
                affected_organ=item.get("affected_organ"),
                animation_asset=item.get("animation_asset"),
                created_at=parse_supabase_datetime(item["created_at"])
            )
            for item in response.data
        ]
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching summaries: {str(e)}"
        )


@app.get("/summaries/by-date", response_model=List[SummaryListItem])
async def get_summaries_by_date(
    date: str = Query(..., description="Date in YYYY-MM-DD format")
):
    """
    Fetch all summaries created on a specific date
    
    Query parameter: date (YYYY-MM-DD format)
    Returns summaries for that date, sorted by created_at DESC
    """
    try:
        # Parse and validate date
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Invalid date format. Use YYYY-MM-DD"
            )
        
        # Query Supabase for summaries on that date
        # Use date casting for timezone-aware comparison
        # Supabase stores timestamps in UTC, so we query by date range
        start_datetime = datetime.combine(target_date, datetime.min.time())
        end_datetime = datetime.combine(target_date, datetime.max.time())
        
        # Format for Supabase (ISO format with timezone)
        start_iso = start_datetime.isoformat() + "Z"
        end_iso = end_datetime.isoformat() + "Z"
        
        response = supabase.table("clinical_summaries")\
            .select("summary_id, patient_name, summary_text, affected_organ, animation_asset, created_at")\
            .gte("created_at", start_iso)\
            .lte("created_at", end_iso)\
            .order("created_at", desc=True)\
            .execute()
        
        if not response.data:
            return []
        
        return [
            SummaryListItem(
                summary_id=str(item["summary_id"]),  # Ensure UUID is converted to string
                patient_name=item["patient_name"],
                summary_text=item["summary_text"],
                affected_organ=item.get("affected_organ"),
                animation_asset=item.get("animation_asset"),
                created_at=parse_supabase_datetime(item["created_at"])
            )
            for item in response.data
        ]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching summaries by date: {str(e)}"
        )


@app.get("/summaries/all", response_model=List[SummaryListItem])
async def get_all_summaries(
    limit: int = Query(default=100, ge=1, le=1000, description="Maximum number of summaries to return")
):
    """
    Fetch all summaries (useful for debugging and testing)
    
    Returns summaries sorted by created_at DESC (most recent first)
    Limited to 1000 records by default
    
    NOTE: This endpoint must be defined BEFORE /summaries/{summary_id} to avoid route conflicts
    """
    try:
        response = supabase.table("clinical_summaries")\
            .select("summary_id, patient_name, summary_text, affected_organ, animation_asset, created_at")\
            .order("created_at", desc=True)\
            .limit(limit)\
            .execute()
        
        if not response.data:
            return []
        
        return [
            SummaryListItem(
                summary_id=str(item["summary_id"]),
                patient_name=item["patient_name"],
                summary_text=item["summary_text"],
                affected_organ=item.get("affected_organ"),
                animation_asset=item.get("animation_asset"),
                created_at=parse_supabase_datetime(item["created_at"])
            )
            for item in response.data
        ]
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching all summaries: {str(e)}"
        )


@app.get("/summaries/{summary_id}", response_model=SummaryResponse)
async def get_summary_by_id(summary_id: str):
    """
    Fetch a single summary by its ID
    
    Returns full summary details including raw notes
    """
    try:
        response = supabase.table("clinical_summaries")\
            .select("*")\
            .eq("summary_id", summary_id)\
            .single()\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=404,
                detail=f"Summary with ID {summary_id} not found"
            )
        
        summary = response.data
        return SummaryResponse(
            summary_id=str(summary["summary_id"]),  # Ensure UUID is converted to string
            patient_id=summary["patient_id"],
            patient_name=summary["patient_name"],
            summary_text=summary["summary_text"],
            diagnoses=summary["diagnoses"] if isinstance(summary["diagnoses"], list) else [],
            affected_system=summary.get("affected_system"),
            affected_organ=summary.get("affected_organ"),
            animation_asset=summary.get("animation_asset"),
            raw_notes_type=summary["raw_notes_type"],
            raw_notes_text=summary.get("raw_notes_text"),
            raw_notes_file_url=summary.get("raw_notes_file_url"),
            created_at=parse_supabase_datetime(summary["created_at"])
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching summary: {str(e)}"
        )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "Medora Clinical Summary API"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
