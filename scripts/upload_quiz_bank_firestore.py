#!/usr/bin/env python3
"""
Upload generated EdVenture questions to Firestore.

Usage:
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
  python3 scripts/upload_quiz_bank_firestore.py

Optional:
  export FIREBASE_PROJECT_ID=your-project-id
  export FIRESTORE_BATCH_SIZE=400
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


def init_firestore():
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred_path:
        raise RuntimeError("GOOGLE_APPLICATION_CREDENTIALS is not set")

    project_id = os.getenv("FIREBASE_PROJECT_ID")
    cred = credentials.Certificate(cred_path)

    if not firebase_admin._apps:
        if project_id:
            firebase_admin.initialize_app(cred, {"projectId": project_id})
        else:
            firebase_admin.initialize_app(cred)

    return firestore.client()


def load_questions() -> list[dict]:
    root = Path(__file__).resolve().parents[1]
    path = root / "EdVenture" / "Resources" / "QuestionBank" / "questions_all_500.json"
    if not path.exists():
        raise FileNotFoundError(f"Question file not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def ensure_lesson_docs(db, questions: list[dict]):
    grouped: dict[str, list[dict]] = {}
    for q in questions:
        grouped.setdefault(q["lessonId"], []).append(q)

    for lesson_id, lesson_questions in grouped.items():
        ref = db.collection("lessons").document(lesson_id)
        ref.set({
            "title": lesson_id.replace("_", " ").title(),
            "totalLevels": 10,
            "questionsPerLevel": 10,
            "questionCount": len(lesson_questions),
            "xpReward": lesson_questions[0].get("xpSuggested", 20),
            "isActive": True,
        }, merge=True)


def upload_questions(db, questions: list[dict]):
    batch_size = int(os.getenv("FIRESTORE_BATCH_SIZE", "400"))

    batch = db.batch()
    count = 0
    total = 0

    for q in questions:
        lesson_id = q["lessonId"]
        qid = q["id"]
        ref = db.collection("lessons").document(lesson_id).collection("questions").document(qid)

        payload = {
            "level": q["level"],
            "order": q["order"],
            "difficulty": q["difficulty"],
            "xpMin": q["xpMin"],
            "xpMax": q["xpMax"],
            "xpSuggested": q["xpSuggested"],
            "prompt": q["prompt"],
            "choices": q["choices"],
            "correctIndex": q["correctIndex"],
            "explanation": q["explanation"],
            "tags": q.get("tags", []),
            "type": "mcq",
            "isActive": q.get("isActive", True),
        }

        batch.set(ref, payload, merge=True)
        count += 1
        total += 1

        if count >= batch_size:
            batch.commit()
            batch = db.batch()
            count = 0

    if count > 0:
        batch.commit()

    return total


def main():
    questions = load_questions()
    db = init_firestore()

    ensure_lesson_docs(db, questions)
    total = upload_questions(db, questions)

    print(f"Uploaded {total} questions to Firestore")


if __name__ == "__main__":
    main()
