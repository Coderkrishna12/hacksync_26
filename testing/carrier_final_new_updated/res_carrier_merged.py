from flask import Flask, request, jsonify
import pandas as pd
import os
import json
import base64
from io import BytesIO
from fpdf import FPDF
from fpdf.enums import XPos, YPos
import google.generativeai as genai

print("Starting Flask app initialization...")

# ────────────────────────────────────────────────
# Gemini setup
# ────────────────────────────────────────────────
GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"  # CHANGE IF NEEDED
try:
    genai.configure(api_key=GEMINI_API_KEY)
    print("Gemini configured successfully")
except Exception as e:
    print(f"WARNING: Gemini setup failed: {e}")
    genai = None

# ────────────────────────────────────────────────
# PDF constants
# ────────────────────────────────────────────────
PAGE_WIDTH = 210
LEFT_MARGIN = 15
RIGHT_MARGIN = 15
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
ACCENT_COLOR = (26, 35, 126)

app = Flask(__name__)
print("Flask app created")

# ────────────────────────────────────────────────
# Load careers - FIXED CSV PATH
# ────────────────────────────────────────────────
CSV_PATH = "carrier.csv"  # Changed from "career.csv" to match working code
print(f"Checking for CSV at: {os.path.abspath(CSV_PATH)}")

df = pd.DataFrame()
if os.path.exists(CSV_PATH):
    try:
        df = pd.read_csv(CSV_PATH)
        print(f"Successfully loaded {len(df)} careers from CSV")
        print("Columns:", list(df.columns))
    except Exception as e:
        print(f"CSV loading failed: {e}")
else:
    print(f"CSV file NOT FOUND: {CSV_PATH}")

# ────────────────────────────────────────────────
# WORKING RECOMMENDATION LOGIC FROM SECOND CODE
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

def normalize_skill(skill):
    """Normalize skill names for matching"""
    skill = skill.lower().strip()
    skill = skill.replace(" ", "")           # remove spaces
    skill = skill.replace("js", "javascript")
    skill = skill.replace("reactjs", "react")
    skill = skill.replace("next.js", "nextjs")
    skill = skill.replace("node.js", "nodejs")
    return skill

# Prepare careers list
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

def score_career(career, user_skills, user_education, user_interests):
    """Score a career against user profile - WORKING VERSION"""
    if EDU_LEVEL[user_education] < EDU_LEVEL[career["min_education"]]:
        print(f"    → Education too low: {user_education} < {career['min_education']}")
        return None

    matched_weight = 0
    total_weight = sum(career["skills"].values())
    matched_skills = []

    for skill, weight in career["skills"].items():
        norm_skill = normalize_skill(skill)
        if norm_skill in user_skills:
            matched_weight += weight
            matched_skills.append(skill)   # keep original display name

    if matched_weight == 0:
        print("    → No matching skills")
        return None

    coverage = matched_weight / total_weight
    trend_bonus = career["trend_score"] / 10
    growth_bonus = GROWTH_WEIGHT.get(career["growth"], 1.0)
    interest_bonus = 0.1 if career["interests"] & user_interests else 0

    final_score = (
        0.6 * coverage +
        0.25 * trend_bonus +
        0.15 * growth_bonus +
        interest_bonus
    )

    score_percent = round(final_score * 100, 2)

    return {
        "career": career["career"],
        "score": score_percent,
        "fit": fit_label(score_percent),
        "matched_skills": matched_skills,
        "missing_skills": sorted(set(career["skills"]) - set(matched_skills)),
        "industry": career["industry"],
        "trend_score": career["trend_score"],
        "career_path": career["career_path"],
        "next_steps": career["next_steps"]
    }

# ────────────────────────────────────────────────
# Route: /recommend - REPLACED WITH WORKING VERSION
# ────────────────────────────────────────────────
@app.route('/recommend', methods=['POST'])
def recommend():
    print("\n" + "="*70)
    print("Received POST /recommend")

    try:
        data = request.get_json(force=True)
        if not data:
            print("No JSON body received")
            return jsonify({"error": "No JSON data provided"}), 400

        print("Received data:", data)

        # Prepare user data
        raw_skills = data.get("skills", [])
        user_education = data.get("education", "")
        raw_interests = data.get("interests", [])

        if not raw_skills or not user_education:
            print("Missing required fields")
            return jsonify({"error": "skills and education are required"}), 400

        # Normalize skills
        user_skills = {normalize_skill(s) for s in raw_skills}
        user_interests = {i.strip().lower() for i in raw_interests}

        print(f"Normalized user skills ({len(user_skills)}): {sorted(user_skills)}")
        print(f"Education: {user_education}")
        print(f"User interests ({len(user_interests)}): {sorted(user_interests)}")

        # Score all careers
        results = []
        for career in careers:
            r = score_career(career, user_skills, user_education, user_interests)
            if r:
                results.append(r)

        results.sort(key=lambda x: x["score"], reverse=True)

        print(f"Found {len(results)} matching careers")

        return jsonify({
            "recommendations": results[:8],
            "count": len(results)
        })

    except Exception as e:
        print(f"Server error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# ────────────────────────────────────────────────
# PDF Builder Classes & Functions
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
        y = self.get_y()
        self.set_font("Helvetica", "B", 10.5)
        self.set_x(LEFT_MARGIN)
        self.cell(CONTENT_WIDTH, 6, left_text, align='L')
        self.set_xy(LEFT_MARGIN, y)
        self.cell(CONTENT_WIDTH, 6, right_text, align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(LEFT_MARGIN + 4)
        self.cell(4, 5, chr(149), align='L')
        self.set_x(LEFT_MARGIN + 8)
        self.multi_cell(CONTENT_WIDTH - 8, 5, text)
        self.ln(1)

def clean_text(text):
    text = (text or "").replace("**", "")
    for a, b in {"—": "-", "–": "-", "'": "'", "•": "-", """: '"', """: '"', "|": "|"}.items():
        text = text.replace(a, b)
    return text.encode("latin-1", "replace").decode("latin-1")

def create_resume_pdf(text_content, user_info):
    print("Creating PDF...")
    pdf = StyledResume()
    pdf.set_margins(LEFT_MARGIN, 15, RIGHT_MARGIN)
    pdf.add_page()

    pdf.set_font("Helvetica", "B", 26)
    pdf.set_text_color(*ACCENT_COLOR)
    pdf.cell(CONTENT_WIDTH/2, 12, user_info['name'].upper(), align='L')

    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(80, 80, 80)
    contact = f"{user_info['email']} | {user_info['phone']}"
    pdf.cell(CONTENT_WIDTH/2, 12, contact, align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.ln(4)
    pdf.set_draw_color(*ACCENT_COLOR)
    pdf.line(LEFT_MARGIN, pdf.get_y(), PAGE_WIDTH - RIGHT_MARGIN, pdf.get_y())

    for line in (text_content or "").splitlines():
        cl = clean_text(line.strip())
        if not cl: continue

        if cl.upper() in ["PROFESSIONAL SUMMARY","SKILLS","EDUCATION","PROJECTS","CERTIFICATIONS"]:
            pdf.add_section_header(cl)
            continue

        if cl.startswith("-"):
            pdf.add_bullet(cl[1:].strip())
            continue

        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(CONTENT_WIDTH, 5, cl)
        pdf.ln(1)

    buffer = BytesIO()
    pdf.output(buffer)
    buffer.seek(0)
    print("PDF created successfully")
    return buffer

# ────────────────────────────────────────────────
# Route: /generate-resume
# ────────────────────────────────────────────────
@app.route('/generate-resume', methods=['POST'])
def generate_resume():
    print("\n" + "="*60)
    print("REQUEST RECEIVED: POST /generate-resume")
    print("Request headers:", dict(request.headers))
    print("Raw request body:", request.data)

    try:
        data = request.get_json(force=True)
        if not data:
            print("No JSON payload received")
            return jsonify({"error": "No JSON data"}), 400

        print("Parsed JSON:", data)

        user_info = data.get('user_info', {})
        career = data.get('career', 'Unknown Role')
        job_desc = data.get('job_description', f"Entry-level {career}")

        print(f"Career: {career}")
        print(f"Job desc: {job_desc}")
        print(f"User info keys: {list(user_info.keys())}")

        resume_dict = {
            "name": user_info.get("name", "User"),
            "email": user_info.get("email", ""),
            "phone": user_info.get("phone", ""),
            "summary": user_info.get("bio", "Professional summary missing."),
            "skills": user_info.get("skills", []),
            "education": {"degree": user_info.get("education", "Degree"), "year": "Recent"},
        }

        print("Resume dict prepared:", resume_dict)

        # Try Gemini
        improved_text = ""
        good = "Good foundation."
        needs = "Add projects and metrics."

        if genai:
            try:
                model = genai.GenerativeModel('gemini-2.5-flash')
                prompt = f"""Rewrite resume for: {job_desc}

JSON:
{json.dumps(resume_dict, indent=2)}

Return:
Good: [sentence]
Needs improvement: [sentence]
Improved Resume:
[resume text]
"""

                response = model.generate_content(prompt)
                text = response.text.strip()
                print("Gemini response received")

                lines = text.splitlines()
                collecting = False
                improved_lines = []

                for line in lines:
                    line = line.strip()
                    if line.startswith("Good:"):
                        good = line[5:].strip()
                    elif line.startswith("Needs improvement:"):
                        needs = line[18:].strip()
                    elif line.startswith("Improved Resume:"):
                        collecting = True
                    elif collecting:
                        improved_lines.append(line)

                improved_text = "\n".join(improved_lines).strip()
            except Exception as gemini_err:
                print(f"Gemini failed: {gemini_err}")
                improved_text = "Resume content generation failed - using placeholder."
        else:
            print("Gemini not available - using placeholder")
            improved_text = "Professional Summary\nSkills: " + ", ".join(resume_dict["skills"])

        # Create PDF
        pdf_buffer = create_resume_pdf(improved_text, user_info)
        pdf_base64 = base64.b64encode(pdf_buffer.read()).decode('utf-8')
        print("PDF base64 generated (length:", len(pdf_base64), ")")

        return jsonify({
            "good": good,
            "needs_improvement": needs,
            "readiness_score": 75,
            "pdf_base64": pdf_base64
        })

    except Exception as e:
        print(f"CRITICAL ERROR in /generate-resume: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# ────────────────────────────────────────────────
# Home route (for testing)
# ────────────────────────────────────────────────
@app.route('/', methods=['GET'])
def home():
    print("GET / - Home route hit")
    return jsonify({
        "status": "API running",
        "endpoints": ["/recommend", "/generate-resume"],
        "example_recommend": {
            "skills": ["python", "sql", "javascript", "react js"],
            "education": "Bachelor",
            "interests": ["technical", "analytical"]
        }
    })

print("Registering routes...")
print("Routes registered:", list(app.url_map.iter_rules()))

if __name__ == '__main__':
    print("Starting server...")
    app.run(host='0.0.0.0', port=5000, debug=True)