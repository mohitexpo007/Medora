-- ============================================
-- Supabase Database Setup for Clinical Summaries
-- ============================================

-- Create the clinical_summaries table
CREATE TABLE IF NOT EXISTS clinical_summaries (
  summary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id TEXT NOT NULL,
  patient_name TEXT NOT NULL,
  summary_text TEXT NOT NULL,
  diagnoses JSONB DEFAULT '[]'::jsonb,
  affected_system TEXT,
  affected_organ TEXT,
  animation_asset TEXT,
  raw_notes_type TEXT NOT NULL CHECK (raw_notes_type IN ('text', 'pdf', 'none')) DEFAULT 'none',
  raw_notes_text TEXT,
  raw_notes_file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT check_notes_type CHECK (
    (raw_notes_type = 'text' AND raw_notes_text IS NOT NULL) OR
    (raw_notes_type = 'pdf' AND raw_notes_file_url IS NOT NULL) OR
    (raw_notes_type = 'none' AND raw_notes_text IS NULL AND raw_notes_file_url IS NULL)
  )
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_clinical_summaries_patient_id 
  ON clinical_summaries(patient_id);

CREATE INDEX IF NOT EXISTS idx_clinical_summaries_created_at 
  ON clinical_summaries(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_clinical_summaries_date 
  ON clinical_summaries(DATE(created_at));

-- Create index for patient name searches (if needed)
CREATE INDEX IF NOT EXISTS idx_clinical_summaries_patient_name 
  ON clinical_summaries(patient_name);

-- Add comments for documentation
COMMENT ON TABLE clinical_summaries IS 'Stores AI-generated clinical summaries with associated raw medical notes';
COMMENT ON COLUMN clinical_summaries.summary_id IS 'Unique identifier for each summary';
COMMENT ON COLUMN clinical_summaries.patient_id IS 'Unique identifier for the patient';
COMMENT ON COLUMN clinical_summaries.raw_notes_type IS 'Type of raw notes: text, pdf, or none';
COMMENT ON COLUMN clinical_summaries.diagnoses IS 'JSON array of diagnosis strings';

-- ============================================
-- Row Level Security (RLS) - Optional
-- ============================================
-- Uncomment if you want to enable RLS later

-- ALTER TABLE clinical_summaries ENABLE ROW LEVEL SECURITY;

-- Example policy: Allow all operations (adjust based on your auth requirements)
-- CREATE POLICY "Allow all operations" ON clinical_summaries
--   FOR ALL
--   USING (true);

-- ============================================
-- Storage Bucket Setup
-- ============================================
-- Note: Storage buckets must be created via Supabase Dashboard
-- Go to Storage > Create Bucket
-- Name: clinical-notes
-- Public: true (or configure RLS policies)
