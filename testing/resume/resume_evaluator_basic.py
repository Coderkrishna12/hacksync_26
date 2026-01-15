import json
from google import genai

# ───────────────────────────────────────────────
# CONFIG
# ───────────────────────────────────────────────
GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"

MODEL_NAME = "gemini-2.5-flash"  # or "gemini-2.0-flash" if needed

PRODUCT_STATEMENT = "AI Resume Readiness Evaluator"

# ───────────────────────────────────────────────
# GEMINI SETUP
# ───────────────────────────────────────────────
def setup_gemini():
    if not GEMINI_API_KEY.strip():
        raise ValueError("GEMINI_API_KEY is empty. Add your real key.")
    client = genai.Client(api_key=GEMINI_API_KEY)
    return client


# ───────────────────────────────────────────────
# MAIN EVALUATION + RESUME GENERATION
# ───────────────────────────────────────────────
def generate_improved_resume(client, resume_dict, job_description):
    resume_json = json.dumps(resume_dict, indent=2)

    prompt = f"""You are an expert resume writer for entry-level Data Analyst roles.

Original resume (JSON):
{resume_json}

Job description / requirements:
{job_description}

Rewrite and significantly improve this resume:
- Make it stronger, ATS-friendly, and results-oriented
- Add realistic, believable details/quantification where appropriate for a fresher
- Use strong action verbs
- Structure it clearly with sections: Name/Contact, Summary, Skills, Education, Projects, Certifications
- Keep it concise, professional, and realistic — do NOT invent fake companies or long experience
- Output in clean, readable text format (use markdown-like structure)

Return ONLY the following structure — nothing else:

Good: [one short sentence what is already good]
Needs improvement: [one short sentence main weakness]
Improved Resume:
[full rewritten resume in clean text format]
"""

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt
        )
        text = response.text.strip()

        # Simple parsing — assuming model follows the requested structure
        lines = text.split('\n')
        good = ""
        needs = ""
        resume_start = False
        improved_resume = []

        for line in lines:
            line = line.strip()
            if line.startswith("Good:"):
                good = line.replace("Good:", "", 1).strip()
            elif line.startswith("Needs improvement:"):
                needs = line.replace("Needs improvement:", "", 1).strip()
            elif line.startswith("Improved Resume:"):
                resume_start = True
            elif resume_start:
                improved_resume.append(line)

        return {
            "good": good or "Has basic relevant skills and education",
            "needs_improvement": needs or "Lacks strong evidence of skills and impact",
            "improved_resume_text": "\n".join(improved_resume).strip() if improved_resume else "Could not extract improved resume"
        }

    except Exception as e:
        return {"error": str(e)}


# ───────────────────────────────────────────────
# PRETTY PRINT
# ───────────────────────────────────────────────
def print_result(result):
    if "error" in result:
        print("\nError:", result["error"])
        return

    print("\n" + "="*60)
    print(f" {PRODUCT_STATEMENT} ")
    print("="*60)

    print("\nGood: " + result["good"])
    print("Needs improvement: " + result["needs_improvement"])

    print("\nImproved Resume (ready to use/copy):\n")
    print(result["improved_resume_text"])
    print("\n" + "="*60)


# ───────────────────────────────────────────────
# RUN
# ───────────────────────────────────────────────
if __name__ == "__main__":
    # Your current resume data
    resume = {
        "name": "Amit Vishwakarma",
        "email": "amit@email.com",
        "phone": "9XXXXXXXXX",
        "career_target": "Data Analyst",
        "summary": "Aspiring data analyst with strong SQL and Excel skills",
        "skills": ["SQL", "Excel", "Power BI", "Python"],
        "education": {
            "degree": "Bachelor",
            "field": "Computer Science",
            "institution": "XYZ University",
            "year": "2026"
        },
        "projects": [
            {
                "title": "Sales Dashboard",
                "description": "Analyzed sales trends",
                "impact": "leading to 20% efficiency gain"
            }
        ],
        "experience": [],
        "certifications": ["Google Data Analytics Certificate – In Progress"],
        "awards": [],
        "growth": "High"
    }

    job_description = (
        "Seeking a Data Analyst proficient in SQL, Python, data visualization with Tableau, "
        "ETL processes, and statistics for dashboard creation and business insights."
    )

    try:
        print("Connecting to Gemini...")
        client = setup_gemini()

        print("Generating improved resume...")
        result = generate_improved_resume(client, resume, job_description)

        print_result(result)

    except Exception as e:
        print("\nError occurred:", str(e))
        print("Most likely: API key invalid / quota exceeded / model unavailable")