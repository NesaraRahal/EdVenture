#!/usr/bin/env python3
"""
Generate 500 quiz questions for EdVenture:
5 categories × 10 levels × 10 questions.
Includes adaptive difficulty metadata and XP ranges.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
import random

LESSONS = [
    "astronomy",
    "philosophy",
    "biology",
    "mathematics",
    "computer_science",
]

SEED = 20260405
random.seed(SEED)


@dataclass
class Question:
    id: str
    lessonId: str
    level: int
    order: int
    difficulty: int
    xpMin: int
    xpMax: int
    xpSuggested: int
    prompt: str
    choices: list[str]
    correctIndex: int
    explanation: str
    tags: list[str]
    isActive: bool
    createdAt: str


def difficulty_for(level: int, order: int) -> int:
    return (level - 1) * 10 + order  # 1..100


def xp_range_for(level: int, order: int, difficulty: int) -> tuple[int, int, int]:
    base = 8 + level * 2 + (order // 2)
    span = 5 + max(1, difficulty // 15)
    xp_min = base
    xp_max = base + span
    xp_suggested = (xp_min + xp_max) // 2
    return xp_min, xp_max, xp_suggested


def shuffled_choices(correct: str, distractors: list[str]) -> tuple[list[str], int]:
    options = [correct] + distractors[:3]
    random.shuffle(options)
    return options, options.index(correct)


ASTRONOMY_BANK = [
    ("Mercury", "It is the closest planet to the Sun."),
    ("Venus", "It is the hottest planet due to a strong greenhouse atmosphere."),
    ("Earth", "It is the only known planet with stable surface liquid water."),
    ("Mars", "It is known as the Red Planet."),
    ("Jupiter", "It is the largest planet in the Solar System."),
    ("Saturn", "It is famous for its prominent ring system."),
    ("Uranus", "It rotates on its side with an extreme axial tilt."),
    ("Neptune", "It is the farthest major planet from the Sun."),
    ("Milky Way", "It is the galaxy that contains our Solar System."),
    ("Black Hole", "It is an object with gravity so strong that light cannot escape."),
    ("Supernova", "It is an explosive death event of a massive star."),
    ("Nebula", "It is an interstellar cloud where stars can form."),
    ("Red Giant", "It is a late stage of stellar evolution after core hydrogen is depleted."),
    ("White Dwarf", "It is the dense stellar remnant of a low or medium mass star."),
    ("Light-year", "It is a distance unit equal to how far light travels in one year."),
    ("Astronomical Unit", "It is approximately the average Earth-Sun distance."),
    ("Exoplanet", "It is a planet that orbits a star outside our Solar System."),
    ("Transit Method", "It detects planets when they pass in front of their star."),
    ("Spectroscopy", "It studies light to infer composition and motion of celestial objects."),
    ("Event Horizon", "It is the boundary around a black hole beyond which escape is impossible."),
]

PHILOSOPHY_BANK = [
    ("Socrates", "He is associated with the Socratic method of questioning."),
    ("Plato", "He founded the Academy in Athens."),
    ("Aristotle", "He wrote extensively on logic, ethics, and metaphysics."),
    ("Stoicism", "This school emphasizes virtue and control over responses to events."),
    ("Epicureanism", "This school values moderate pleasure and freedom from fear."),
    ("Existentialism", "It focuses on individual freedom, meaning, and responsibility."),
    ("Nihilism", "It is often linked to rejection of objective meaning or value."),
    ("Utilitarianism", "It evaluates actions by outcomes and overall well-being."),
    ("Deontology", "It emphasizes duties and rules rather than consequences."),
    ("Virtue Ethics", "It focuses on moral character traits rather than only acts."),
    ("Kant", "He is known for the categorical imperative."),
    ("Hume", "He is known for empiricism and skepticism about causation certainty."),
    ("Descartes", "He is known for methodological doubt and mind-body dualism."),
    ("Rationalism", "It prioritizes reason as a source of knowledge."),
    ("Empiricism", "It prioritizes sensory experience as a source of knowledge."),
    ("Phenomenology", "It studies structures of conscious experience."),
    ("Pragmatism", "It evaluates ideas by practical consequences and usefulness."),
    ("Absurdism", "It addresses tension between desire for meaning and indifferent universe."),
    ("Social Contract", "It explains authority through agreement among people."),
    ("Determinism", "It holds that events are necessitated by prior causes."),
]

BIOLOGY_BANK = [
    ("Nucleus", "It stores most genetic material in eukaryotic cells."),
    ("Mitochondria", "It is known for ATP production through cellular respiration."),
    ("Ribosome", "It is the molecular machine that synthesizes proteins."),
    ("Cell Membrane", "It regulates what enters and leaves the cell."),
    ("Osmosis", "It is the diffusion of water across a selectively permeable membrane."),
    ("Diffusion", "It is movement from higher to lower concentration."),
    ("Photosynthesis", "It converts light energy into chemical energy in plants."),
    ("Cellular Respiration", "It releases energy from glucose for ATP production."),
    ("DNA", "It carries hereditary genetic information."),
    ("RNA", "It helps express genetic information, including during translation."),
    ("Mitosis", "It produces two genetically identical daughter cells."),
    ("Meiosis", "It produces gametes with half the chromosome number."),
    ("Natural Selection", "It favors traits that improve survival and reproduction."),
    ("Mutation", "It is a change in DNA sequence."),
    ("Ecosystem", "It includes organisms and their physical environment interactions."),
    ("Homeostasis", "It maintains stable internal conditions in an organism."),
    ("Enzyme", "It speeds up biochemical reactions by lowering activation energy."),
    ("Hormone", "It is a signaling molecule often transported via bloodstream."),
    ("Neuron", "It transmits electrical and chemical signals in nervous systems."),
    ("Antibody", "It is produced by immune cells to bind specific antigens."),
]

CS_BANK = [
    ("Array", "It stores elements in contiguous memory and supports index access."),
    ("Linked List", "It stores nodes connected by references."),
    ("Stack", "It follows LIFO: last in, first out."),
    ("Queue", "It follows FIFO: first in, first out."),
    ("Hash Table", "It maps keys to values using hash functions."),
    ("Binary Search", "It repeatedly halves a sorted search space."),
    ("Big O", "It describes asymptotic upper-bound growth of runtime."),
    ("Recursion", "It solves a problem by defining it in terms of smaller subproblems."),
    ("Compiler", "It translates source code into machine code or bytecode."),
    ("Interpreter", "It executes code directly, statement by statement."),
    ("TCP", "It is a reliable connection-oriented transport protocol."),
    ("UDP", "It is a low-overhead connectionless transport protocol."),
    ("HTTP", "It is an application-layer protocol for web communication."),
    ("HTTPS", "It secures HTTP with TLS encryption."),
    ("Operating System", "It manages hardware resources and process scheduling."),
    ("Thread", "It is a lightweight execution unit within a process."),
    ("Deadlock", "It is a state where processes wait indefinitely on each other."),
    ("Database Index", "It speeds up data retrieval operations."),
    ("Normalization", "It structures relational data to reduce redundancy."),
    ("Machine Learning", "It enables systems to learn patterns from data."),
]


def bank_question(lesson: str, level: int, order: int, bank: list[tuple[str, str]], tags: list[str]) -> Question:
    d = difficulty_for(level, order)
    xp_min, xp_max, xp_suggested = xp_range_for(level, order, d)

    idx = (level * 17 + order * 11) % len(bank)
    term, clue = bank[idx]

    # Harder levels use less direct wording.
    if d <= 35:
        prompt = f"Which concept matches this description: {clue}"
    elif d <= 70:
        prompt = f"Identify the most accurate term for this statement: {clue}"
    else:
        prompt = f"Choose the best concept that explains the following scenario-level statement: {clue}"

    distractor_terms = []
    j = idx + 1
    while len(distractor_terms) < 3:
        candidate = bank[j % len(bank)][0]
        if candidate != term and candidate not in distractor_terms:
            distractor_terms.append(candidate)
        j += 1

    choices, correct_index = shuffled_choices(term, distractor_terms)

    qid = f"{lesson}_L{level:02d}_Q{order:02d}"
    return Question(
        id=qid,
        lessonId=lesson,
        level=level,
        order=order,
        difficulty=d,
        xpMin=xp_min,
        xpMax=xp_max,
        xpSuggested=xp_suggested,
        prompt=prompt,
        choices=choices,
        correctIndex=correct_index,
        explanation=f"Correct answer: {term}. {clue}",
        tags=tags,
        isActive=True,
        createdAt=datetime.now(timezone.utc).isoformat(),
    )


def math_question(level: int, order: int) -> Question:
    lesson = "mathematics"
    d = difficulty_for(level, order)
    xp_min, xp_max, xp_suggested = xp_range_for(level, order, d)

    rng = random.Random(SEED + level * 100 + order)

    if level <= 3:
        a, b = rng.randint(2, 25), rng.randint(2, 25)
        prompt = f"What is {a} + {b} × 2?"
        correct = str(a + b * 2)
        distractors = [str(a + b), str((a + b) * 2), str(a * b)]
        tags = ["arithmetic", "order_of_operations"]
    elif level <= 6:
        a = rng.randint(2, 12)
        b = rng.randint(10, 40)
        x = rng.randint(2, 12)
        c = a * x + b
        prompt = f"Solve for x: {a}x + {b} = {c}"
        correct = str(x)
        distractors = [str(x + 1), str(max(1, x - 1)), str(x + 2)]
        tags = ["algebra", "linear_equation"]
    elif level <= 8:
        n = rng.randint(2, 6)
        prompt = f"What is the derivative of x^{n}?"
        correct = f"{n}x^{n-1}"
        distractors = [f"x^{n-1}", f"{n-1}x^{n}", f"{n+1}x^{n}"]
        tags = ["calculus", "derivative"]
    else:
        p = rng.randint(1, 7)
        q = rng.randint(8, 15)
        prompt = f"If P(A)={p}/{q}, what is P(not A)?"
        correct = f"{q-p}/{q}"
        distractors = [f"{p}/{q}", f"{p}/{q-p}", f"{q}/{p}"]
        tags = ["probability"]

    choices, correct_index = shuffled_choices(correct, distractors)
    qid = f"{lesson}_L{level:02d}_Q{order:02d}"

    return Question(
        id=qid,
        lessonId=lesson,
        level=level,
        order=order,
        difficulty=d,
        xpMin=xp_min,
        xpMax=xp_max,
        xpSuggested=xp_suggested,
        prompt=prompt,
        choices=choices,
        correctIndex=correct_index,
        explanation=f"Correct answer: {correct}.",
        tags=tags,
        isActive=True,
        createdAt=datetime.now(timezone.utc).isoformat(),
    )


def generate_all_questions() -> list[Question]:
    out: list[Question] = []

    for level in range(1, 11):
        for order in range(1, 11):
            out.append(bank_question("astronomy", level, order, ASTRONOMY_BANK, ["space", "science"]))
            out.append(bank_question("philosophy", level, order, PHILOSOPHY_BANK, ["humanities", "thinking"]))
            out.append(bank_question("biology", level, order, BIOLOGY_BANK, ["life_science"]))
            out.append(math_question(level, order))
            out.append(bank_question("computer_science", level, order, CS_BANK, ["computing", "algorithms"]))

    return out


def write_outputs(questions: list[Question], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    all_data = [asdict(q) for q in questions]
    (out_dir / "questions_all_500.json").write_text(json.dumps(all_data, indent=2), encoding="utf-8")

    for lesson in LESSONS:
        lesson_data = [asdict(q) for q in questions if q.lessonId == lesson]
        (out_dir / f"questions_{lesson}.json").write_text(json.dumps(lesson_data, indent=2), encoding="utf-8")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out_dir = root / "EdVenture" / "Resources" / "QuestionBank"

    questions = generate_all_questions()
    write_outputs(questions, out_dir)

    print(f"Generated {len(questions)} questions")
    for lesson in LESSONS:
        count = sum(1 for q in questions if q.lessonId == lesson)
        print(f"  {lesson}: {count}")
    print(f"Saved to: {out_dir}")


if __name__ == "__main__":
    main()
