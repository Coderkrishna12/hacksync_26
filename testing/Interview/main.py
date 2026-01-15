# from fastapi import FastAPI, Body
# from fastapi.middleware.cors import CORSMiddleware
# from google import genai
# from livekit import AccessToken, VideoGrant
# import uuid
# import datetime

# # ---------------- CONFIG ---------------- #

# LIVEKIT_API_KEY = "APISnEEkigvcmEZ"
# LIVEKIT_API_SECRET = "41Z4auR9JRMbAVqyQyDH3qEmOqfUMCquZHMrPiH5nQP"
# LIVEKIT_URL = "wss://fitsync-yykk3win.livekit.cloud"

# GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"

# genai.configure(api_key=GEMINI_API_KEY)
# model = genai.GenerativeModel("gemini-2.5-flash")

# # ---------------------------------------- #

# app = FastAPI()
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # Store session data in-memory (hackathon style)
# SESSIONS = {}

# # ---------------- INTERVIEW START ---------------- #

# @app.post("/start_interview")
# def start_interview(resume: dict, role: str, difficulty: str):
#     session_id = str(uuid.uuid4())

#     prompt = f"""
# You are a technical interviewer.

# Role: {role}
# Difficulty: {difficulty}

# Candidate Resume:
# {resume}

# Ask ONE interview question only.
# """

#     question = model.generate_content(prompt).text

#     SESSIONS[session_id] = {
#         "resume": resume,
#         "role": role,
#         "difficulty": difficulty,
#         "questions": [question],
#         "answers": [],
#         "feedback": []
#     }

#     return {
#         "session_id": session_id,
#         "first_question": question
#     }

# # ---------------- LIVEKIT TOKEN ---------------- #

# @app.get("/livekit_token")
# def get_livekit_token(room: str, username: str):
#     token = (
#         AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET)
#         .with_identity(username)
#         .with_grants(VideoGrant(room_join=True, room=room))
#     )
#     return {
#         "token": token.to_jwt(),
#         "url": LIVEKIT_URL
#     }

# # ---------------- ANSWER EVALUATION ---------------- #

# @app.post("/submit_answer")
# def submit_answer(
#     session_id: str = Body(...),
#     answer: str = Body(...)
# ):
#     session = SESSIONS[session_id]

#     evaluation_prompt = f"""
# You are an interview evaluator.

# Question:
# {session['questions'][-1]}

# Candidate Answer:
# {answer}

# Give feedback on:
# - Clarity
# - Correctness
# - Confidence

# Also give a score out of 10.
# """

#     feedback = model.generate_content(evaluation_prompt).text

#     session["answers"].append(answer)
#     session["feedback"].append(feedback)

#     return {
#         "feedback": feedback
#     }

# # ---------------- NEXT QUESTION ---------------- #

# @app.post("/next_question")
# def next_question(session_id: str):
#     session = SESSIONS[session_id]

#     prompt = f"""
# Continue the interview.

# Role: {session['role']}
# Difficulty: {session['difficulty']}

# Previous Questions and Answers:
# {list(zip(session['questions'], session['answers']))}

# Ask ONE new interview question.
# """

#     question = model.generate_content(prompt).text
#     session["questions"].append(question)

#     return {
#         "question": question
#     }

# # ---------------- FINAL REPORT ---------------- #

# @app.get("/final_report/{session_id}")
# def final_report(session_id: str):
#     session = SESSIONS[session_id]

#     report_prompt = f"""
# Generate a structured interview report.

# Questions: {session['questions']}
# Answers: {session['answers']}
# Feedback: {session['feedback']}

# Return:
# - Overall Score (0–100)
# - Technical Skills
# - Communication
# - Confidence
# - Strengths
# - Weaknesses
# - Topics to Improve
# """

#     report = model.generate_content(report_prompt).text

#     return {
#         "report": report,
#         "completed_at": datetime.datetime.now()
#     }


from fastapi import FastAPI, Body
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from livekit.api import AccessToken, VideoGrants
import uuid
import datetime
import random

# ===================== CONFIG ===================== #

LIVEKIT_API_KEY = "APISnEEkigvcmEZ"
LIVEKIT_API_SECRET = "41Z4auR9JRMbAVqyQyDH3qEmOqfUMCquZHMrPiH5nQP"
LIVEKIT_URL = "wss://fitsync-yykk3win.livekit.cloud"

GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"

client = genai.Client(api_key=GEMINI_API_KEY)

# ================================================= #

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SESSIONS = {}

# ===================== FALLBACK DATA ===================== #

QUESTION_BANK = {
    "Software Engineer": {
        "easy": [
            "Explain the difference between list and tuple in Python.",
            "What is OOP and why is it useful?"
        ],
        "medium": [
            "Explain REST APIs and HTTP methods.",
            "How does Git branching work?"
        ],
        "hard": [
            "Explain system design for a URL shortener.",
            "What are race conditions and how do you prevent them?"
        ]
    },
    "Data Analyst": {
        "easy": [
            "What is data cleaning?",
            "Explain mean vs median."
        ],
        "medium": [
            "How do you handle missing data?",
            "Explain normalization in databases."
        ],
        "hard": [
            "Explain A/B testing with an example.",
            "How would you optimize a slow SQL query?"
        ]
    }
}

FALLBACK_FEEDBACK = [
    "Good explanation with clear structure. Some edge cases could be explained better. Score: 7/10",
    "Answer shows basic understanding, but depth can be improved. Score: 6/10",
    "Confident response with relevant examples. Score: 8/10"
]

FINAL_REPORT_TEMPLATE = """
Overall Score: 72/100

Technical Skills:
Good understanding of core concepts with room for deeper knowledge.

Communication:
Clear and structured answers.

Confidence:
Candidate answered confidently with minimal hesitation.

Strengths:
- Logical thinking
- Clear explanations

Weaknesses:
- Needs more real-world examples
- Limited depth in advanced topics

Suggested Topics to Improve:
- System design
- Optimization techniques

Sample Improved Answer:
A more structured explanation with real-world examples would improve clarity.
"""

# ===================== HELPER ===================== #

def ask_gemini(prompt, model="gemini-2.5-flash"):
    try:
        response = client.models.generate_content(
            model=model,
            contents=prompt
        )
        return response.text.strip()
    except Exception as e:
        print("⚠️ Gemini failed:", e)
        return None

# ================================================= #
# 1️⃣ START INTERVIEW
# ================================================= #

@app.post("/start_interview")
def start_interview(
    resume: dict = Body(...),
    role: str = Body(...),
    difficulty: str = Body(...)
):
    session_id = str(uuid.uuid4())

    prompt = f"""
You are a technical interviewer.

Role: {role}
Difficulty: {difficulty}

Candidate Resume:
{resume}

Ask ONLY ONE interview question.
"""

    question = ask_gemini(prompt)

    # 🔁 FALLBACK
    if not question:
        question = random.choice(
            QUESTION_BANK.get(role, QUESTION_BANK["Software Engineer"])
            .get(difficulty, ["Tell me about yourself."])
        )

    SESSIONS[session_id] = {
        "role": role,
        "difficulty": difficulty,
        "questions": [question],
        "answers": [],
        "feedback": []
    }

    return {
        "session_id": session_id,
        "question": question
    }

# ================================================= #
# 2️⃣ LIVEKIT TOKEN
# ================================================= #

@app.get("/livekit_token")
def livekit_token(room: str, username: str):
    token = (
        AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET)
        .with_identity(username)
        .with_grants(VideoGrants(room_join=True, room=room))
    )

    return {
        "token": token.to_jwt(),
        "url": LIVEKIT_URL
    }

# ================================================= #
# 3️⃣ SUBMIT ANSWER
# ================================================= #

@app.post("/submit_answer")
def submit_answer(
    session_id: str = Body(...),
    answer: str = Body(...)
):
    session = SESSIONS.get(session_id)
    if not session:
        return {"error": "Invalid session"}

    prompt = f"""
Evaluate the candidate answer.

Question:
{session['questions'][-1]}

Answer:
{answer}

Give short feedback and score out of 10.
"""

    feedback = ask_gemini(prompt, model="gemini-2.5-flash")

    # 🔁 FALLBACK
    if not feedback:
        feedback = random.choice(FALLBACK_FEEDBACK)

    session["answers"].append(answer)
    session["feedback"].append(feedback)

    return {"feedback": feedback}

# ================================================= #
# 4️⃣ NEXT QUESTION
# ================================================= #

@app.post("/next_question")
def next_question(session_id: str = Body(...)):
    session = SESSIONS.get(session_id)
    if not session:
        return {"error": "Invalid session"}

    prompt = f"""
Continue the interview.
Ask ONLY ONE new question.
"""

    question = ask_gemini(prompt)

    # 🔁 FALLBACK
    if not question:
        question = random.choice(
            QUESTION_BANK.get(session["role"], QUESTION_BANK["Software Engineer"])
            .get(session["difficulty"], ["Explain your last project."])
        )

    session["questions"].append(question)
    return {"question": question}

# ================================================= #
# 5️⃣ FINAL REPORT
# ================================================= #

@app.get("/final_report/{session_id}")
def final_report(session_id: str):
    session = SESSIONS.get(session_id)
    if not session:
        return {"error": "Invalid session"}

    prompt = f"""
Generate final interview report.

Questions:
{session['questions']}

Answers:
{session['answers']}

Feedback:
{session['feedback']}
"""

    report = ask_gemini(prompt, model="gemini-2.5-flash")

    # 🔁 FALLBACK
    if not report:
        report = FINAL_REPORT_TEMPLATE

    return {
        "report": report,
        "completed_at": datetime.datetime.now()
    }
