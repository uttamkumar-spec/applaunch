"""Default content used until a coach or admin has set anything up. Mirrors
the Flutter app's own offline fallback plan so behavior is consistent
whether or not the backend has served a plan yet."""

DEFAULT_PLAN = {
    "id": "beginner-full-body",
    "title": "Beginner Full Body",
    "level": "Absolute beginner",
    "description": (
        "Three short full-body sessions a week. No equipment needed — just "
        "you, some floor space, and 20 minutes."
    ),
    "days": [
        {
            "id": "day-1",
            "name": "Day 1 · Full Body Basics",
            "exercises": [
                {
                    "id": "bodyweight-squat",
                    "name": "Bodyweight Squat",
                    "sets": 3,
                    "reps": "10",
                    "rest_seconds": 45,
                    "beginner_tip": "Sit back like you're reaching for a chair — knees stay behind your toes.",
                    "instructions": "Stand feet shoulder-width apart, lower hips down and back, then stand tall.",
                },
                {
                    "id": "incline-pushup",
                    "name": "Incline Push-Up (on a counter/table)",
                    "sets": 3,
                    "reps": "8",
                    "rest_seconds": 45,
                    "beginner_tip": "The higher the surface, the easier it is — start high, work your way down over weeks.",
                    "instructions": "Hands on a sturdy elevated surface, lower your chest, push back up.",
                },
                {
                    "id": "glute-bridge",
                    "name": "Glute Bridge",
                    "sets": 3,
                    "reps": "12",
                    "rest_seconds": 30,
                    "beginner_tip": "Squeeze your glutes at the top for a full second — quality over speed.",
                    "instructions": "Lie on your back, knees bent, lift hips toward the ceiling, lower slowly.",
                },
                {
                    "id": "plank-hold",
                    "name": "Plank Hold",
                    "sets": 3,
                    "reps": "20 sec",
                    "rest_seconds": 30,
                    "beginner_tip": "Drop to your knees if a full plank is too hard yet — that still counts.",
                    "instructions": "Forearms and toes on the ground, body in a straight line, brace your core.",
                },
            ],
        },
        {
            "id": "day-2",
            "name": "Day 2 · Easy Cardio + Mobility",
            "exercises": [
                {
                    "id": "brisk-walk",
                    "name": "Brisk Walk",
                    "sets": 1,
                    "reps": "15 min",
                    "rest_seconds": 0,
                    "beginner_tip": "Aim for a pace where you could talk but not sing.",
                    "instructions": "",
                },
                {
                    "id": "cat-cow",
                    "name": "Cat-Cow Stretch",
                    "sets": 2,
                    "reps": "10",
                    "rest_seconds": 15,
                    "beginner_tip": "Move slowly with your breath — inhale arch, exhale round.",
                    "instructions": "",
                },
            ],
        },
        {
            "id": "day-3",
            "name": "Day 3 · Full Body Basics (again!)",
            "exercises": [
                {
                    "id": "bodyweight-squat",
                    "name": "Bodyweight Squat",
                    "sets": 3,
                    "reps": "12",
                    "rest_seconds": 45,
                    "beginner_tip": "Two extra reps from Day 1 — notice that? That's progress.",
                    "instructions": "",
                },
                {
                    "id": "incline-pushup",
                    "name": "Incline Push-Up",
                    "sets": 3,
                    "reps": "10",
                    "rest_seconds": 45,
                    "beginner_tip": "If 10 feels easy, lower the surface height next time.",
                    "instructions": "",
                },
            ],
        },
    ],
}
