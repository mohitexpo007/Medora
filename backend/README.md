# Medora Clinical Summary API

FastAPI backend for storing and fetching AI-generated clinical summaries using Supabase.

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Configure environment variables:**
```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

3. **Run the server:**
```bash
uvicorn main:app --reload
```

## API Endpoints

### 1. Create Summary
**POST** `/summaries`

Stores a new clinical summary with optional raw notes (text or PDF).

**Request (multipart/form-data):**
- `patient_id` (required): Unique patient identifier
- `patient_name` (required): Patient's full name
- `summary_text` (required): AI-generated clinical summary
- `diagnoses` (optional): JSON array string of diagnoses
- `affected_system` (optional): Affected organ system
- `affected_organ` (optional): Affected organ name
- `animation_asset` (optional): Animation asset path
- `raw_notes_text` (optional): Raw medical notes as text
- `raw_notes_file` (optional): PDF file upload

**Response:**
```json
{
  "summary_id": "uuid",
  "patient_id": "string",
  "patient_name": "string",
  "summary_text": "string",
  "diagnoses": ["string"],
  "affected_system": "string",
  "affected_organ": "string",
  "animation_asset": "string",
  "raw_notes_type": "text|pdf|none",
  "raw_notes_text": "string|null",
  "raw_notes_file_url": "string|null",
  "created_at": "datetime"
}
```

### 2. Get Summaries by Patient
**GET** `/summaries/by-patient/{patient_id}`

Fetches all summaries for a specific patient, sorted by date (newest first).

### 3. Get Summaries by Date
**GET** `/summaries/by-date?date=YYYY-MM-DD`

Fetches all summaries created on a specific date.

### 4. Get Summary by ID
**GET** `/summaries/{summary_id}`

Fetches full details of a single summary.

## Supabase Setup

### 1. Create Table

Run this SQL in your Supabase SQL editor:

```sql
CREATE TABLE clinical_summaries (
  summary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  summary_text TEXT NOT NULL,
  diagnoses JSONB DEFAULT '[]'::jsonb,
  affected_system TEXT,
  affected_organ TEXT,
  animation_asset TEXT,
  raw_notes_type TEXT NOT NULL CHECK (raw_notes_type IN ('text', 'pdf', 'none')),
  raw_notes_text TEXT,
  raw_notes_file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_patient_id ON clinical_summaries(patient_id);
CREATE INDEX idx_created_at ON clinical_summaries(created_at);
CREATE INDEX idx_date ON clinical_summaries(DATE(created_at));
```

### 2. Create Storage Bucket

1. Go to Storage in Supabase dashboard
2. Create a new bucket named `clinical-notes`
3. Set it to **Public** (or configure RLS policies)
4. Enable file uploads

### 3. Row Level Security (Optional)

If you want to add RLS policies later:

```sql
-- Enable RLS
ALTER TABLE clinical_summaries ENABLE ROW LEVEL SECURITY;

-- Example policy (adjust based on your auth requirements)
CREATE POLICY "Allow all operations" ON clinical_summaries
  FOR ALL
  USING (true);
```

## Example Usage

### Create Summary with Text Notes

```bash
curl -X POST "http://localhost:8000/summaries" \
  -F "patient_id=patient-123" \
  -F "patient_name=John Doe" \
  -F "summary_text=Patient presents with elevated HbA1c..." \
  -F "diagnoses=[\"Type 2 Diabetes Mellitus\"]" \
  -F "raw_notes_text=Patient reports polyuria and polydipsia..."
```

### Create Summary with PDF Notes

```bash
curl -X POST "http://localhost:8000/summaries" \
  -F "patient_id=patient-123" \
  -F "patient_name=John Doe" \
  -F "summary_text=Patient presents with elevated HbA1c..." \
  -F "raw_notes_file=@/path/to/notes.pdf"
```

### Get Summaries by Date

```bash
curl "http://localhost:8000/summaries/by-date?date=2022-06-09"
```

## Development

- API docs available at: `http://localhost:8000/docs`
- ReDoc available at: `http://localhost:8000/redoc`
