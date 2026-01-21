/// Dummy clinical cases for testing disease-to-animation mapping logic.
/// 
/// This file contains test cases with patient information, clinical summaries,
/// diagnoses, and expected animation paths. Use these cases to verify that
/// the animation selection logic correctly maps diseases to their corresponding
/// organ/system animations.
/// 
/// Usage:
/// 1. Loop through the cases in dummyCases
/// 2. Pass summaryText and diagnosisList into selectAnimationAsset()
/// 3. Compare returned asset with expectedAnimation
/// 4. Verify correct animation playback

final List<Map<String, dynamic>> dummyCases = [
  {
    "patientName": "Anita Sharma",
    "summaryText":
        "Patient presents with elevated HbA1c levels and persistent fatigue. "
        "Reports polyuria and polydipsia over the past few months. "
        "Findings suggest poor glycemic control consistent with Type 2 Diabetes Mellitus.",
    "diagnosisList": ["Type 2 Diabetes Mellitus"],
    "expectedAnimation": "assets/animations/organs/pancreas.mp4"
  },

  {
    "patientName": "Ravi Kumar",
    "summaryText":
        "Patient reports chest discomfort and shortness of breath on exertion. "
        "Blood pressure readings remain persistently elevated. "
        "Clinical findings are suggestive of hypertension with cardiac involvement.",
    "diagnosisList": ["Hypertension"],
    "expectedAnimation": "assets/animations/organs/heart.mp4"
  },

  {
    "patientName": "Mohit Verma",
    "summaryText":
        "Patient presents with sudden onset weakness on the right side of the body. "
        "Speech difficulty and facial asymmetry noted. "
        "Findings are concerning for an acute ischemic stroke.",
    "diagnosisList": ["Ischemic Stroke"],
    "expectedAnimation": "assets/animations/organs/brain.mp4"
  },

  {
    "patientName": "Neha Singh",
    "summaryText":
        "Patient complains of chronic cough and progressive breathlessness. "
        "Reduced oxygen saturation observed on room air. "
        "History and findings suggest chronic obstructive pulmonary disease.",
    "diagnosisList": ["Chronic Obstructive Pulmonary Disease"],
    "expectedAnimation": "assets/animations/organs/lungs.mp4"
  },

  {
    "patientName": "Suresh Patel",
    "summaryText":
        "Patient shows elevated serum creatinine and reduced urine output. "
        "Complains of generalized swelling and fatigue. "
        "Clinical picture suggests impaired renal function.",
    "diagnosisList": ["Chronic Kidney Disease"],
    "expectedAnimation": "assets/animations/organs/kidneys.mp4"
  },

  {
    "patientName": "Pooja Mehta",
    "summaryText":
        "Patient reports upper abdominal pain and nausea. "
        "Symptoms worsen after meals. "
        "Findings suggest gastritis with gastric inflammation.",
    "diagnosisList": ["Gastritis"],
    "expectedAnimation": "assets/animations/organs/stomach.mp4"
  },

  {
    "patientName": "Amit Joshi",
    "summaryText":
        "Patient presents with intermittent abdominal cramps, bloating, and altered bowel habits. "
        "Symptoms suggest intestinal involvement rather than gastric pathology. "
        "Clinical picture is consistent with irritable bowel syndrome.",
    "diagnosisList": ["Irritable Bowel Syndrome"],
    "expectedAnimation": "assets/animations/organs/intestines.mp4"
  },

  {
    "patientName": "Kiran Rao",
    "summaryText":
        "Patient complains of calf pain while walking that resolves with rest. "
        "Clinical signs indicate compromised peripheral blood flow. "
        "Findings suggest peripheral vascular disease.",
    "diagnosisList": ["Peripheral Vascular Disease"],
    "expectedAnimation": "assets/animations/organs/blood_vessels.mp4"
  },

  {
    "patientName": "Rohit Malhotra",
    "summaryText":
        "Patient reports localized pain and stiffness in the right hand. "
        "Pain increases with movement and grip activities. "
        "No systemic illness identified, suggesting localized musculoskeletal or nerve involvement.",
    "diagnosisList": [],
    "expectedAnimation": "assets/animations/regions/body_hand_red.mp4"
  },

  {
    "patientName": "Kiran Desai",
    "summaryText":
        "Patient complains of persistent pain and heaviness in the left leg, "
        "especially after prolonged walking. "
        "Symptoms are localized to the lower limb with no clear organ involvement.",
    "diagnosisList": [],
    "expectedAnimation": "assets/animations/regions/body_leg_red.mp4"
  },

  {
    "patientName": "Uncertain Case",
    "summaryText":
        "Patient presents with generalized fatigue and nonspecific symptoms. "
        "No clear organ system involvement identified at this stage. "
        "Further evaluation required.",
    "diagnosisList": [],
    "expectedAnimation": "assets/animations/fallback/body_general_uncertain.mp4"
  }
];
