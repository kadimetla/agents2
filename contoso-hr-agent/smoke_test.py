"""One-shot end-to-end pipeline smoke test.

Reads a sample resume into memory and submits the TEXT (not the file path)
to process_resume_text. This is critical: process_resume_file would move the
source file to data/processed/, removing it from sample_resumes/. The text
pathway leaves sample_resumes/ untouched so the smoke test is idempotent.

Run from contoso-hr-agent/:
    uv run python smoke_test.py
"""

import sys
import time
from pathlib import Path

from contoso_hr.watcher.process_resume import process_resume_text

resume = Path("sample_resumes/RESUME_Alice_Zhang_Azure_Trainer-v1.txt")
if not resume.exists():
    print(f"FAIL: {resume} not found")
    sys.exit(2)

print(f"Submitting: {resume.name}")
raw_text = resume.read_text(encoding="utf-8")
t0 = time.time()
result = process_resume_text(raw_text, resume.name, source_path=None)
elapsed = time.time() - t0

if result is None:
    print(f"FAIL: pipeline returned None after {elapsed:.1f}s")
    sys.exit(3)

print(f"Pipeline elapsed: {elapsed:.1f}s")
print(f"Candidate ID: {result.candidate_id}")
print(f"Candidate name: {result.candidate_name}")
print(f"Disposition: {result.hr_decision.decision}")
print(f"Overall score: {result.hr_decision.overall_score}")
print(f"Skills score: {result.candidate_eval.skills_match_score}")
print(f"Experience score: {result.candidate_eval.experience_score}")
print(f"Strengths (first 2): {result.candidate_eval.strengths[:2]}")
print(f"Reasoning (first 200 chars): {result.hr_decision.reasoning[:200]}")
