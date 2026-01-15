import json
import os
from google import genai
from fpdf import FPDF
from fpdf.enums import XPos, YPos

# ───────────────────────────────────────────────
# CONFIG & STYLING CONSTANTS
# ───────────────────────────────────────────────
# AIzaSyDs4W2OjllyzfNzYoDZcodII-mZv1INdTc
GEMINI_API_KEY = "AIzaSyA5Mw2H_oT5_NadZl2HtwKVAOm2CfiWNuw"
MODEL_NAME = "gemini-2.5-flash"  # Updated to stable 2.0 version
PRODUCT_STATEMENT = "AI Resume Readiness Evaluator & Builder"

PAGE_WIDTH = 210
LEFT_MARGIN = 15
RIGHT_MARGIN = 15
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
ACCENT_COLOR = (26, 35, 126)  # Deep Navy Blue

# ───────────────────────────────────────────────
# GEMINI SETUP
# ───────────────────────────────────────────────
def setup_gemini():
    if not GEMINI_API_KEY.strip():
        raise ValueError("GEMINI_API_KEY is empty. Add your real key.")
    client = genai.Client(api_key=GEMINI_API_KEY)
    return client

# ───────────────────────────────────────────────
# AI EVALUATION + CONTENT GENERATION
# ───────────────────────────────────────────────
def generate_improved_resume_content(client, resume_dict, job_description):
    resume_json = json.dumps(resume_dict, indent=2)

    prompt = f"""You are an expert resume writer. Rewrite this resume for an entry-level Data Analyst role.

Original resume (JSON):
{resume_json}

Job description / requirements:
{job_description}

Instructions:
- Use strong action verbs and quantify achievements.
- Structure with sections: PROFESSIONAL SUMMARY, SKILLS, EDUCATION, PROJECTS, CERTIFICATIONS.
- For EDUCATION/PROJECTS headers, use the '|' symbol for right-alignment (e.g., Company Name | Date).
- Use '-' for bullet points.
- IMPORTANT: Do NOT use markdown bold (**) in the body. The system handles bolding automatically based on section.

Return ONLY the following structure:
Good: [one sentence]
Needs improvement: [one sentence]
Improved Resume:
[full rewritten resume body]
"""

    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt
        )
        text = response.text.strip()
        lines = text.split('\n')
        good, needs, improved_resume = "", "", []
        resume_start = False

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
            "good": good,
            "needs_improvement": needs,
            "improved_resume_text": "\n".join(improved_resume).strip()
        }
    except Exception as e:
        return {"error": str(e)}

# ───────────────────────────────────────────────
# PDF RESUME BUILDER LOGIC
# ───────────────────────────────────────────────
def clean_text(text: str) -> str:
    """Removes markdown artifacts and ensures Latin-1 compatibility."""
    if not text: return ""
    # Remove double asterisks (markdown bold)
    text = text.replace("**", "") 
    replacements = {"—": "-", "–": "-", "’": "'", "•": "-", "“": '"', "”": '"', "|": "|"}
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode("latin-1", "replace").decode("latin-1")

class StyledResume(FPDF):
    def add_section_header(self, title):
        self.ln(6)
        self.set_fill_color(*ACCENT_COLOR)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 11)
        self.cell(CONTENT_WIDTH, 7, f"  {title.upper()}", fill=True, new_y=YPos.NEXT, align='L')
        self.set_text_color(0, 0, 0)
        self.ln(2)

    def add_split_line(self, left_text, right_text):
        """Renders bold subheadings with right-aligned metadata."""
        self.set_font("Helvetica", "B", 10.5)
        current_y = self.get_y()
        self.set_x(LEFT_MARGIN)
        self.cell(CONTENT_WIDTH, 6, left_text, align='L')
        self.set_xy(LEFT_MARGIN, current_y)
        self.cell(CONTENT_WIDTH, 6, right_text, align='R', new_y=YPos.NEXT)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(LEFT_MARGIN + 4)
        self.cell(4, 5, chr(149), align='L') 
        self.set_x(LEFT_MARGIN + 8)
        self.multi_cell(CONTENT_WIDTH - 8, 5, text)
        self.ln(1)

    def add_sub_heading(self, text):
        """Explicitly bolds project titles and degree names."""
        self.set_font("Helvetica", "B", 10.5)
        self.cell(0, 6, text, new_y=YPos.NEXT)

def create_styled_resume_pdf(text_content, user_info, filename="Improved_Resume.pdf"):
    pdf = StyledResume()
    pdf.set_margins(LEFT_MARGIN, 15, RIGHT_MARGIN)
    pdf.add_page()
    
    # ───── 1. HEADER ─────
    pdf.set_font("Helvetica", "B", 26)
    pdf.set_text_color(*ACCENT_COLOR)
    pdf.cell(CONTENT_WIDTH / 2, 12, user_info['name'].upper(), align="L")
    
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(80, 80, 80)
    contact_str = f"{user_info['email']} | {user_info['phone']}"
    pdf.cell(CONTENT_WIDTH / 2, 12, contact_str, align="R", new_y=YPos.NEXT)
    
    pdf.ln(4)
    pdf.set_draw_color(*ACCENT_COLOR)
    pdf.set_line_width(0.6)
    pdf.line(LEFT_MARGIN, pdf.get_y(), PAGE_WIDTH - RIGHT_MARGIN, pdf.get_y())
    
    # ───── 2. CONTENT PARSING ─────
    lines = text_content.strip().split("\n")
    current_section = ""

    for line in lines:
        clean_line = clean_text(line.strip())
        if not clean_line: continue

        # Section Headers
        if clean_line.upper() in ["PROFESSIONAL SUMMARY", "SKILLS", "EDUCATION", "PROJECTS", "CERTIFICATIONS"]:
            pdf.add_section_header(clean_line)
            current_section = clean_line.upper()
            continue

        # Bullet Points
        if clean_line.startswith("-"):
            pdf.add_bullet(clean_line[1:].strip())
            continue

        # Bold formatting for Education & Projects sub-headers
        if current_section in ["EDUCATION", "PROJECTS"]:
            if "|" in clean_line:
                parts = clean_line.split("|")
                pdf.add_split_line(parts[0].strip(), parts[1].strip())
            else:
                pdf.add_sub_heading(clean_line)
        else:
            # Summary / Skills
            pdf.set_font("Helvetica", "", 10)
            pdf.multi_cell(CONTENT_WIDTH, 5, clean_line)
            pdf.ln(1)

    pdf.output(filename)
    return filename

# ───────────────────────────────────────────────
# RUN
# ───────────────────────────────────────────────
if __name__ == "__main__":
    resume_data = {
        "name": "Amit Vishwakarma",
        "email": "amit@email.com",
        "phone": "9XXXXXXXXX",
        "career_target": "Data Analyst",
        "summary": "Computer Science student with SQL and Python skills.",
        "skills": ["SQL", "Excel", "Power BI", "Python"],
        "education": {"degree": "Bachelor", "field": "Computer Science", "institution": "XYZ University", "year": "2026"},
        "projects": [{"title": "Sales Dashboard", "description": "Analyzed sales trends", "impact": "20% gain"}],
        "experience": [],
        "certifications": ["Google Data Analytics Certificate"],
        "awards": [],
        "growth": "High"
    }

    job_desc = "Seeking a Data Analyst proficient in SQL, Python, and dashboard creation."

    try:
        client = setup_gemini()
        print("AI is optimizing your content...")
        result = generate_improved_resume_content(client, resume_data, job_desc)

        if "error" in result:
            print("Error:", result["error"])
        else:
            user_header_info = {
                "name": resume_data.get("name", "User"),
                "email": resume_data.get("email", ""),
                "phone": resume_data.get("phone", "")
            }
            pdf_filename = f"{user_header_info['name'].replace(' ', '_')}_Resume.pdf"
            create_styled_resume_pdf(result["improved_resume_text"], user_header_info, pdf_filename)
            print(f"✅ Success! PDF saved as: {pdf_filename}")

    except Exception as e:
        print("Process failed:", str(e))




