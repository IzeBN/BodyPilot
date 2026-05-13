"""
Core AI chat processing for two dedicated assistants:
  - training  → workouts, programs, exercise technique
  - nutrition → food, calories, macros, meal planning

Each assistant gets a rich system prompt built from the user's profile,
active program / nutrition goals, and recent progress.
"""
from datetime import date

from openai import AsyncOpenAI
from asyncpg import Pool

from app.config import get_settings
from app.repositories.chat import ChatRepository

# ─── System prompts ───────────────────────────────────────────────────────────

_TRAINING_BASE = """You are an expert personal trainer and sports scientist AI assistant built into a fitness app.

Your role:
- Help users with workout programs, exercise technique, progression, and training plans
- Answer questions about strength training, cardio, flexibility, recovery, and injury prevention
- Give specific, evidence-based advice tailored to the user's experience level and goals
- Analyse the user's current program and recent results when available
- Be motivating but realistic

Communication style: concise, practical, encouraging. Use numbered lists for exercises/steps."""

_NUTRITION_BASE = """You are an expert nutritionist and dietitian AI assistant built into a fitness app.

Your role:
- Help users with calorie counting, macro tracking, meal planning, and food choices
- Answer questions about nutrients, dietary strategies, supplements, and food composition
- Provide personalised advice based on the user's goals, current intake, and nutritional targets
- Point out gaps between the user's goals and actual intake when you can see the data
- Be specific: suggest actual foods, portions, meal timings

Communication style: clear, practical, supportive. Use bullet points for meal ideas."""


# ─── Context builders ─────────────────────────────────────────────────────────

async def _build_training_context(user_id: int, pool: Pool) -> str:
    parts: list[str] = []
    async with pool.acquire() as conn:
        user = await conn.fetchrow("SELECT fullname FROM users WHERE id = $1", user_id)
        if user and user["fullname"]:
            parts.append(f"User name: {user['fullname']}")

        profile = await conn.fetchrow(
            "SELECT * FROM user_training_profiles WHERE user_id = $1", user_id
        )
        if profile:
            if profile.get("experience"):
                parts.append(f"Training experience: {profile['experience']}")
            if profile.get("fitness_goal"):
                parts.append(f"Fitness goal: {profile['fitness_goal']}")
            if profile.get("injuries"):
                parts.append(f"Injuries / limitations: {profile['injuries']}")
            if profile.get("trainings_per_week"):
                parts.append(f"Target training days per week: {profile['trainings_per_week']}")

        active = await conn.fetchrow(
            """SELECT tp.title, tp.sample_type, us.week_number, us.scheduled_date
               FROM user_schedules us
               JOIN training_programs tp ON tp.id = us.program_id
               WHERE us.user_id = $1 AND us.status IN ('pending', 'in_progress')
               ORDER BY us.scheduled_date LIMIT 1""",
            user_id,
        )
        if active:
            parts.append(f"Active program: {active['title']} (type: {active['sample_type']})")
            if active["week_number"]:
                parts.append(f"Current week: {active['week_number']}")
            if active["scheduled_date"]:
                parts.append(f"Next workout: {active['scheduled_date']}")

        recent = await conn.fetch(
            """SELECT us.completed_at::date completed_date,
                      e.title exercise_title,
                      er.sets_done, er.reps_done, er.weight_kg
               FROM exercise_results er
               JOIN user_schedules us ON us.id = er.schedule_id
               JOIN exercises e ON e.id = er.exercise_id
               WHERE us.user_id = $1 AND us.status = 'completed'
               ORDER BY us.completed_at DESC LIMIT 5""",
            user_id,
        )
        if recent:
            parts.append("Recent workout results:")
            for r in recent:
                w = f" @ {r['weight_kg']} kg" if r.get("weight_kg") else ""
                parts.append(
                    f"  • {r['completed_date']}: {r['exercise_title']} — "
                    f"{r['sets_done']}x{r['reps_done']}{w}"
                )
    return "\n".join(parts)


async def _build_nutrition_context(user_id: int, pool: Pool) -> str:
    parts: list[str] = []
    async with pool.acquire() as conn:
        user = await conn.fetchrow("SELECT fullname FROM users WHERE id = $1", user_id)
        if user and user["fullname"]:
            parts.append(f"User name: {user['fullname']}")

        profile = await conn.fetchrow(
            "SELECT * FROM nutrition_profiles WHERE user_id = $1", user_id
        )
        if profile:
            if profile.get("weight_kg"):
                parts.append(f"Weight: {profile['weight_kg']} kg")
            if profile.get("height_cm"):
                parts.append(f"Height: {profile['height_cm']} cm")
            if profile.get("age"):
                parts.append(f"Age: {profile['age']}")
            if profile.get("goal"):
                parts.append(f"Goal: {profile['goal']}")
            if profile.get("activity_level"):
                parts.append(f"Activity level: {profile['activity_level']}")

        goals = await conn.fetchrow(
            """SELECT calories, protein_g, fat_g, carbs_g, water_ml
               FROM nutrition_goals WHERE user_id = $1
               ORDER BY valid_from DESC LIMIT 1""",
            user_id,
        )
        if goals:
            goal_str = f"Daily targets: {goals['calories']} kcal"
            macros = []
            if goals["protein_g"]:
                macros.append(f"protein {goals['protein_g']}g")
            if goals["fat_g"]:
                macros.append(f"fat {goals['fat_g']}g")
            if goals["carbs_g"]:
                macros.append(f"carbs {goals['carbs_g']}g")
            if macros:
                goal_str += " / " + " / ".join(macros)
            if goals["water_ml"]:
                goal_str += f" / water {goals['water_ml']}ml"
            parts.append(goal_str)

        today = date.today()
        summary = await conn.fetchrow(
            """SELECT COALESCE(SUM(calories),0) cal, COALESCE(SUM(protein),0) prot,
                      COALESCE(SUM(fat),0) fat, COALESCE(SUM(carbs),0) carbs, COUNT(*) meals
               FROM meal_logs WHERE user_id = $1 AND log_date = $2""",
            user_id, today,
        )
        if summary and summary["meals"] > 0:
            s = summary
            parts.append(
                f"Today's intake ({s['meals']} meals): "
                f"{s['cal']:.0f} kcal / protein {s['prot']:.1f}g / "
                f"fat {s['fat']:.1f}g / carbs {s['carbs']:.1f}g"
            )
            if goals and goals["calories"]:
                remaining = float(goals["calories"]) - float(s["cal"])
                parts.append(f"Remaining today: {remaining:.0f} kcal")

        recent_meals = await conn.fetch(
            """SELECT food_name, amount_g, calories, meal_type
               FROM meal_logs WHERE user_id = $1 AND log_date = $2
               ORDER BY created_at DESC LIMIT 5""",
            user_id, today,
        )
        if recent_meals:
            parts.append("Today's meals:")
            for m in recent_meals:
                parts.append(
                    f"  • [{m['meal_type']}] {m['food_name'] or '-'} "
                    f"- {m['amount_g']}g / {m['calories']:.0f} kcal"
                )
    return "\n".join(parts)


# ─── Core processor ───────────────────────────────────────────────────────────

async def _process(
    agent_type: str,
    system_base: str,
    context_fn,
    user_id: int,
    message: str,
    thread_id: "str | None",
    pool: Pool,
) -> dict:
    s = get_settings()
    client = AsyncOpenAI(api_key=s.openai_api_key)
    chat_repo = ChatRepository(pool)

    if not thread_id:
        thread_id = f"{agent_type}_{user_id}"

    context = await context_fn(user_id, pool)
    system_prompt = system_base
    if context:
        system_prompt += f"\n\n--- User context ---\n{context}"

    history = await chat_repo.get_thread_context(user_id, thread_id, limit=20)
    messages = [{"role": "system", "content": system_prompt}]
    for h in reversed(history):
        messages.append({"role": h["role"], "content": h["content"]})
    messages.append({"role": "user", "content": message})

    await chat_repo.add_message(user_id, thread_id, "user", message, agent_type)

    response = await client.chat.completions.create(
        model=s.openai_model,
        messages=messages,
        max_tokens=1200,
        temperature=0.7,
    )
    reply = response.choices[0].message.content

    await chat_repo.add_message(user_id, thread_id, "assistant", reply, agent_type)
    return {"reply": reply, "thread_id": thread_id, "agent_type": agent_type}


async def process_training_message(
    user_id: int, message: str, thread_id: "str | None", pool: Pool
) -> dict:
    return await _process(
        "training", _TRAINING_BASE, _build_training_context,
        user_id, message, thread_id, pool,
    )


async def process_nutrition_message(
    user_id: int, message: str, thread_id: "str | None", pool: Pool
) -> dict:
    return await _process(
        "nutrition", _NUTRITION_BASE, _build_nutrition_context,
        user_id, message, thread_id, pool,
    )


# ─── Legacy shim (keeps existing tests passing) ───────────────────────────────

async def process_chat_message(
    user_id: int, message: str, thread_id: "str | None", pool: Pool
) -> dict:
    training_kw = (
        "workout", "exercise", "тренировк", "упражнени", "программ",
        "подход", "повторени", "muscle", "gym", "зал", "lifting",
    )
    if any(k in message.lower() for k in training_kw):
        return await process_training_message(user_id, message, thread_id, pool)
    return await process_nutrition_message(user_id, message, thread_id, pool)
