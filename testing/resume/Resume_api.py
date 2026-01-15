from flask import Flask, request, jsonify
import pandas as pd
import os
import json
import base64
from io import BytesIO
from fpdf import FPDF
from fpdf.enums import XPos, YPos

# ────────────────────────────────────────────────
# Gemini / AI setup (replace with your real key)
# ────────────────────────────────────────────────
try:
    from google import genai
except ImportError:
    genai = None  # fallback if not installed

GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"  # ← CHANGE THIS
MODEL_NAME = "gemini-1.5-flash"  # or "gemini-1.5-pro" if you have access

def setup_gemini():
    if not GEMINI_API_KEY or not genai:
        raise ValueError("Gemini not configured properly")
    return genai.GenerativeModel(MODEL_NAME)

# ────────────────────────────────────────────────
# PDF styling constants
# ────────────────────────────────────────────────
PAGE_WIDTH = 210
LEFT_MARGIN = 15
RIGHT_MARGIN = 15
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
ACCENT_COLOR = (26, 35, 126)  # Deep Navy Blue

# ────────────────────────────────────────────────
# Flask app
# ────────────────────────────────────────────────
app = Flask(__name__)

# ────────────────────────────────────────────────
# Load career dataset
# ────────────────────────────────────────────────
CSV_PATH = "career.csv"

if not os.path.exists(CSV_PATH):
    print(f"ERROR: {CSV_PATH} not found in {os.getcwd()}")
    df = pd.DataFrame()
else:
    try:
        df = pd.read_csv(CSV_PATH)
        print(f"Loaded {len(df)} careers from {CSV_PATH}")
    except Exception as e:
        print(f"CSV load failed: {e}")
        df = pd.DataFrame()

# ────────────────────────────────────────────────
# Helpers (same as your standalone version)
# ────────────────────────────────────────────────
def parse_skills(skill_string):
    skills = {}
    for s in skill_string.split(","):
        s = s.strip().lower()
        if s.endswith("*"):
            skills[s.replace("*", "")] = 3
        else:
            skills[s] = 1
    return skills

EDU_LEVEL = {
    "High School": 1,
    "Diploma": 2,
    "Bachelor": 3,
    "Master": 4
}

GROWTH_WEIGHT = {
    "Low": 0.9,
    "Medium": 1.0,
    "High": 1.2
}

def fit_label(score):
    if score >= 80:
        return "Strong Match ✅"
    elif score >= 60:
        return "Good Match 👍"
    else:
        return "Emerging Option 🌱"

# Pre-process careers
careers = []
for _, row in df.iterrows():
    careers.append({
        "career": row["career"],
        "skills": parse_skills(row["skills"]),
        "growth": row["growth"],
        "min_education": row["min_education"],
        "interests": {i.strip().lower() for i in row["interests"].split(",")},
        "trend_score": row["trend_score"],
        "industry": row["industry"],
        "career_path": row["career_path"],
        "next_steps": row["next_steps"]
    })
print(f"Prepared {len(careers)} career entries")

# ────────────────────────────────────────────────
# Skill normalization (critical fix)
# ────────────────────────────────────────────────
def normalize_skill(s):
    s = str(s).lower().strip()
    s = s.replace(" ", "")
    s = s.replace("js", "javascript")
    s = s.replace("reactjs", "react")
    s = s.replace("next.js", "nextjs")
    s = s.replace("node.js", "nodejs")
    s = s.replace("powerbi", "power bi")
    return s

# ────────────────────────────────────────────────
# Career recommendation endpoint (your original logic)
# ────────────────────────────────────────────────
@app.route('/recommend', methods=['POST'])
def recommend():
    print("\n" + "="*70)
    print("POST /recommend")

    try:
        data = request.get_json(force=True) or {}
        raw_skills = data.get("skills", [])
        user_education = data.get("education", "")
        raw_interests = data.get("interests", [])

        if not raw_skills or not user_education:
            return jsonify({"error": "skills and education are required"}), 400

        user_skills = {normalize_skill(s) for s in raw_skills}
        user_interests = {i.lower().strip() for i in raw_interests}

        print(f"Normalized skills: {sorted(user_skills)}")
        print(f"Education: {user_education}")
        print(f"Interests: {sorted(user_interests)}")

        results = []
        for career in careers:
            # ── Education check ──
            if EDU_LEVEL.get(user_education, 0) < EDU_LEVEL.get(career["min_education"], 999):
                continue

            matched_weight = 0
            total_weight = sum(career["skills"].values())
            matched_skills = []

            for skill, weight in career["skills"].items():
                if normalize_skill(skill) in user_skills:
                    matched_weight += weight
                    matched_skills.append(skill)

            if matched_weight == 0:
                continue

            coverage = matched_weight / total_weight
            trend_bonus = career["trend_score"] / 10
            growth_bonus = GROWTH_WEIGHT.get(career["growth"], 1.0)
            interest_bonus = 0.1 if career["interests"] & user_interests else 0

            final_score = 0.6 * coverage + 0.25 * trend_bonus + 0.15 * growth_bonus + interest_bonus
            score_percent = round(final_score * 100, 2)

            results.append({
                "career": career["career"],
                "score": score_percent,
                "fit": fit_label(score_percent),
                "matched_skills": matched_skills,
                "missing_skills": sorted(set(career["skills"]) - set(matched_skills)),
                "industry": career["industry"],
                "trend_score": career["trend_score"],
                "career_path": career["career_path"],
                "next_steps": career["next_steps"]
            })

        results.sort(key=lambda x: x["score"], reverse=True)
        print(f"Returning {len(results)} matches")

        return jsonify({
            "recommendations": results[:8],
            "count": len(results)
        })

    except Exception as e:
        print(f"Error in /recommend: {e}")
        return jsonify({"error": str(e)}), 500

# ────────────────────────────────────────────────
# PDF Resume Builder Class (from your original code)
# ────────────────────────────────────────────────
class StyledResume(FPDF):
    def add_section_header(self, title):
        self.ln(6)
        self.set_fill_color(*ACCENT_COLOR)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 11)
        self.cell(CONTENT_WIDTH, 7, f"  {title.upper()}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(2)

    def add_split_line(self, left_text, right_text):
        self.set_font("Helvetica", "B", 10.5)
        current_y = self.get_y()
        self.set_x(LEFT_MARGIN)
        self.cell(CONTENT_WIDTH, 6, left_text, align='L')
        self.set_xy(LEFT_MARGIN, current_y)
        self.cell(CONTENT_WIDTH, 6, right_text, align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(LEFT_MARGIN + 4)
        self.cell(4, 5, chr(149), align='L')
        self.set_x(LEFT_MARGIN + 8)
        self.multi_cell(CONTENT_WIDTH - 8, 5, text)
        self.ln(1)

# ────────────────────────────────────────────────
# Clean text for PDF
# ────────────────────────────────────────────────
def clean_text(text: str) -> str:
    if not text:
        return ""
    text = text.replace("**", "")
    replacements = {"—": "-", "–": "-", "’": "'", "•": "-", "“": '"', "”": '"', "|": "|"}
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode("latin-1", "replace").decode("latin-1")

# ────────────────────────────────────────────────
# Generate improved resume content with Gemini
# ────────────────────────────────────────────────
def generate_improved_resume_content(resume_dict, job_description):
    if not genai:
        return {"error": "Gemini library not available"}

    try:
        model = setup_gemini()
        resume_json = json.dumps(resume_dict, indent=2)

        prompt = f"""You are an expert resume writer.
Rewrite this resume tailored for the role: {job_description}

Original resume data (JSON):
{resume_json}

Instructions:
- Use strong action verbs and quantify achievements where possible.
- Structure: PROFESSIONAL SUMMARY, SKILLS, EDUCATION, PROJECTS, CERTIFICATIONS
- Use '|' for right-align dates/institutions (e.g. University | 2020-2024)
- Use '-' for bullet points
- Do NOT use markdown **bold** in body text

Return exactly this format:
Good: [one sentence summary of strengths]
Needs improvement: [one sentence on what to improve]
Improved Resume:
[full rewritten resume text]
"""

        response = model.generate_content(prompt)
        text = response.text.strip()

        lines = text.splitlines()
        good = ""
        needs = ""
        improved = []
        collecting = False

        for line in lines:
            line = line.strip()
            if line.startswith("Good:"):
                good = line[5:].strip()
            elif line.startswith("Needs improvement:"):
                needs = line[18:].strip()
            elif line.startswith("Improved Resume:"):
                collecting = True
            elif collecting and line:
                improved.append(line)

        return {
            "good": good or "Strong foundation detected.",
            "needs_improvement": needs or "Consider adding quantifiable achievements.",
            "improved_resume_text": "\n".join(improved).strip()
        }
    except Exception as e:
        return {"error": f"Gemini error: {str(e)}"}

# ────────────────────────────────────────────────
# Create PDF in memory
# ────────────────────────────────────────────────
def create_resume_pdf(text_content, user_info):
    pdf = StyledResume()
    pdf.set_margins(LEFT_MARGIN, 15, RIGHT_MARGIN)
    pdf.add_page()

    # Header
    pdf.set_font("Helvetica", "B", 26)
    pdf.set_text_color(*ACCENT_COLOR)
    pdf.cell(CONTENT_WIDTH / 2, 12, user_info.get('name', 'NAME').upper(), align="L")

    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(80, 80, 80)
    contact = f"{user_info.get('email', '')} | {user_info.get('phone', '')}"
    pdf.cell(CONTENT_WIDTH / 2, 12, contact, align="R", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.ln(4)
    pdf.set_draw_color(*ACCENT_COLOR)
    pdf.set_line_width(0.6)
    pdf.line(LEFT_MARGIN, pdf.get_y(), PAGE_WIDTH - RIGHT_MARGIN, pdf.get_y())

    # Content
    lines = text_content.strip().split("\n")
    current_section = ""

    for line in lines:
        clean_line = clean_text(line.strip())
        if not clean_line:
            continue

        if clean_line.upper() in ["PROFESSIONAL SUMMARY", "SKILLS", "EDUCATION", "PROJECTS", "CERTIFICATIONS"]:
            pdf.add_section_header(clean_line)
            current_section = clean_line.upper()
            continue

        if clean_line.startswith("-"):
            pdf.add_bullet(clean_line[1:].strip())
            continue

        if current_section in ["EDUCATION", "PROJECTS"]:
            if "|" in clean_line:
                left, right = [p.strip() for p in clean_line.split("|", 1)]
                pdf.add_split_line(left, right)
            else:
                pdf.set_font("Helvetica", "B", 10.5)
                pdf.multi_cell(CONTENT_WIDTH, 6, clean_line)
        else:
            pdf.set_font("Helvetica", "", 10)
            pdf.multi_cell(CONTENT_WIDTH, 5, clean_line)
            pdf.ln(1)

    buffer = BytesIO()
    pdf.output(buffer)
    buffer.seek(0)
    return buffer

# ────────────────────────────────────────────────
# New endpoint: generate resume
# ────────────────────────────────────────────────
@app.route('/generate-resume', methods=['POST'])
def generate_resume():
    print("\n" + "="*70)
    print("POST /generate-resume")

    try:
        data = request.get_json(force=True) or {}
        user_info = data.get('user_info', {})
        career = data.get('career', 'Target Role')
        job_desc = data.get('job_description', f"Entry-level {career} position")
        matched_skills = data.get('matched_skills', [])
        missing_skills = data.get('missing_skills', [])

        # Build minimal resume dict
        resume_dict = {
            "name": user_info.get("name", "Your Name"),
            "email": user_info.get("email", ""),
            "phone": user_info.get("phone", ""),
            "summary": user_info.get("bio", f"Looking for opportunities in {career}"),
            "skills": user_info.get("skills", []) + matched_skills,
            "education": {
                "degree": user_info.get("education", "Bachelor's Degree"),
                "year": "Recent"
            },
            # You can extend later with projects, experience, etc.
        }

        # Generate improved content
        ai_result = generate_improved_resume_content(resume_dict, job_desc)

        if "error" in ai_result:
            return jsonify({"error": ai_result["error"]}), 500

        # Create PDF
        pdf_buffer = create_resume_pdf(
            ai_result["improved_resume_text"],
            {
                "name": user_info.get("name", "User"),
                "email": user_info.get("email", ""),
                "phone": user_info.get("phone", "")
            }
        )

        pdf_base64 = base64.b64encode(pdf_buffer.read()).decode('utf-8')

        # Simple readiness score heuristic
        readiness = 90 if len(missing_skills) <= 2 else 70 if len(missing_skills) <= 5 else 50

        return jsonify({
            "good": ai_result["good"],
            "needs_improvement": ai_result["needs_improvement"],
            "readiness_score": readiness,
            "pdf_base64": pdf_base64
        })

    except Exception as e:
        print(f"Error in /generate-resume: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# ────────────────────────────────────────────────
# Simple home route for testing
# ────────────────────────────────────────────────
@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "Career & Resume API running",
        "endpoints": [
            "POST /recommend",
            "POST /generate-resume"
        ]
    })

if __name__ == '__main__':
    print("Starting Flask server...")
    app.run(host='0.0.0.0', port=5000, debug=True)