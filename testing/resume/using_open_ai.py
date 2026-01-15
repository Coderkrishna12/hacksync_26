import json
import os
from openai import OpenAI
from fpdf import FPDF
from fpdf.enums import XPos, YPos

# ───────────────────────────────────────────────
# CONFIG & STYLING CONSTANTS
# ───────────────────────────────────────────────
# 🔑 Using the provided OpenAI API Key
OPENAI_API_KEY = "sk-401fbd42cf00493b8c28db07f3027460"
MODEL_NAME = "gpt-4o-mini"
PRODUCT_STATEMENT = "AI Resume Readiness Evaluator & Builder"

PAGE_WIDTH = 210
LEFT_MARGIN = 15
RIGHT_MARGIN = 15
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
ACCENT_COLOR = (26, 35, 126)  # Deep Navy Blue

# ───────────────────────────────────────────────
# OPENAI SETUP
# ───────────────────────────────────────────────
def setup_openai():
    if not OPENAI_API_KEY.strip():
        raise ValueError("OPENAI_API_KEY is empty. Add your real key.")
    # Initialize the OpenAI client
    client = OpenAI(api_key=OPENAI_API_KEY)
    return client

# ───────────────────────────────────────────────
# AI EVALUATION + CONTENT GENERATION
# ───────────────────────────────────────────────
def generate_improved_resume_content(client, resume_dict, job_description):
    resume_json = json.dumps(resume_dict, indent=2)

    prompt = f"""Role: You are a Senior Career Coach and Expert Resume Writer specializing in Data Analytics and Computer Science.
Task: Transform the provided raw resume data into a high-impact, ATS-optimized, and visually structured professional resume.
Core Instructions:
Framework: Use the Google X-Y-Z formula for all project bullet points: "Accomplished [X] as measured by [Y], by doing [Z]."
Technical Taxonomy: Categorize the Skills section into specific sub-groups (e.g., Technical Proficiencies, Data Analysis, Tools & Platforms) to increase keyword density.
Action Verbs: Start every bullet point with strong, varied action verbs (e.g., Engineered, Spearheaded, Orchestrated, Synthesized).

Formatting Protocol:
Use PROFESSIONAL SUMMARY, SKILLS, EDUCATION, PROJECTS, and CERTIFICATIONS as distinct, capitalized section headers.
Use the | symbol to separate location/date details for right-alignment (e.g., XYZ University | Expected 2026).
Do NOT use Markdown bolding (**) in the body text; use a clean, logical structure that my PDF builder can interpret.

Content Enhancements:
Professional Summary: Write a 3-sentence summary that highlights "Highly analytical and results-driven" traits and specific technical foundations in SQL and Python.
Projects: Elaborate on the "Sales Dashboard" project. Instead of "Analyzed trends," use "Synthesized historical sales data from multiple sources to visualize key performance indicators, resulting in a 20% increase in reporting efficiency".
New Project Addition: Infer and add a believable "Customer Churn Prediction" project using Python (Pandas, Scikit-learn) to demonstrate machine learning readiness.

Input Data (JSON): {resume_json}

Job Target: {job_description}

Output Requirement: Return only the "Good:", "Needs improvement:", and "Improved Resume:" sections.
"""

    try:
        # OpenAI Chat Completion call
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[
                {"role": "system", "content": "You are a professional resume writer."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        
        text = response.choices[0].message.content.strip()
        lines = text.split('\n')
        good, needs, improved_resume = "", "", []
        resume_start = False

        for line in lines:
            line_strip = line.strip()
            if line_strip.startswith("Good:"):
                good = line_strip.replace("Good:", "", 1).strip()
            elif line_strip.startswith("Needs improvement:"):
                needs = line_strip.replace("Needs improvement:", "", 1).strip()
            elif line_strip.startswith("Improved Resume:"):
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
    # Remove double asterisks (markdown bold) if AI ignores instructions
    text = text.replace("**", "") 
    replacements = {"—": "-", "–": "-", "’": "'", "•": "-", "“": '"', "”": '"', "|": "|"}
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode("latin-1", "replace").decode("latin-1")

class StyledResume(FPDF):
    def add_name_header(self, name, contact):
        self.set_font("Helvetica", "B", 22)
        self.set_text_color(*ACCENT_COLOR)
        self.cell(CONTENT_WIDTH / 2, 14, name.upper(), align="L")
        
        self.set_font("Helvetica", "", 10)
        self.set_text_color(60, 60, 60)
        self.cell(CONTENT_WIDTH / 2, 14, contact, align="R", new_y=YPos.NEXT)
        
        self.ln(4)
        self.set_draw_color(*ACCENT_COLOR)
        self.set_line_width(0.8)
        self.line(LEFT_MARGIN, self.get_y(), PAGE_WIDTH - RIGHT_MARGIN, self.get_y())
        self.ln(6)

    def add_section_header(self, title):
        self.ln(8)
        self.set_fill_color(*ACCENT_COLOR)
        self.set_text_color(255, 255, 255)
        self.set_font("Helvetica", "B", 11)
        self.cell(CONTENT_WIDTH, 8, f"  {title.upper()}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(5)

    def add_project_title(self, text):
        self.set_font("Helvetica", "B", 11)
        self.multi_cell(CONTENT_WIDTH, 6, text)
        self.ln(2)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(LEFT_MARGIN + 4)
        self.cell(4, 5, "*", align='L')          # ← safe & clean
        self.set_x(LEFT_MARGIN + 8)
        self.multi_cell(CONTENT_WIDTH - 8, 5, text)
        self.ln(2)                               # ← little more space after bullet

    def add_skills_line(self, category, items):
        self.set_font("Helvetica", "B", 10.5)
        self.write(6, f"{category}: ")
        self.set_font("Helvetica", "", 10)
        self.multi_cell(CONTENT_WIDTH - self.get_string_width(f"{category}: "), 6,
                        ", ".join(items), align="L")
        self.ln(2)

def create_styled_resume(text_content, filename="Amit_Resume_Final.pdf"):
    pdf = StyledResume()
    pdf.set_margins(LEFT_MARGIN, 15, RIGHT_MARGIN)
    pdf.add_page()
    
    # ───── 1. FIXED HEADER ─────
    # Name on the left
    pdf.set_font("Helvetica", "B", 26)
    pdf.set_text_color(*ACCENT_COLOR)
    pdf.cell(CONTENT_WIDTH / 2, 12, "AMIT VISHWAKARMA", align="L")
    
    # Contact on the right (same line)
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(80, 80, 80)
    pdf.cell(CONTENT_WIDTH / 2, 12, "amit@email.com | +91 9XXXXXXXXX", align="R", new_y=YPos.NEXT)
    
    pdf.set_font("Helvetica", "I", 9)
    pdf.cell(0, -2, "Mumbai, Maharashtra, India", align="R", new_y=YPos.NEXT)
    
    pdf.ln(8)   # ← slightly more breathing room after header line
    pdf.set_draw_color(*ACCENT_COLOR)
    pdf.set_line_width(0.7)
    pdf.line(LEFT_MARGIN, pdf.get_y(), PAGE_WIDTH - RIGHT_MARGIN, pdf.get_y())
    pdf.ln(6)
    
    # ───── 2. CONTENT PARSING ─────
    lines = text_content.strip().split("\n")
    current_section = ""

    for line in lines:
        clean_line = ascii_safe(line.strip())
        if not clean_line: 
            continue

        # Section Headers
        if clean_line in ["PROFESSIONAL SUMMARY", "SKILLS", "EDUCATION", "PROJECTS", "CERTIFICATIONS"]:
            pdf.add_section_header(clean_line)
            current_section = clean_line
            continue

        # Bullet Points ── changed chr(149) → "*" 
        if clean_line.startswith("-"):
            pdf.add_bullet(clean_line[1:].strip())
            continue

        # Smart Alignment for Education & Projects
        if current_section in ["EDUCATION", "PROJECTS"]:
            if "|" in clean_line:
                parts = clean_line.split("|", 1)   # better split (in case extra | exist)
                left = parts[0].strip()
                right = parts[1].strip() if len(parts) > 1 else ""
                pdf.add_split_line(left, right)
            else:
                pdf.set_font("Helvetica", "B", 10.5)
                pdf.cell(0, 6, clean_line, new_y=YPos.NEXT)
                pdf.ln(1)
        else:
            # Summary / Skills
            pdf.set_font("Helvetica", "", 10)
            pdf.multi_cell(CONTENT_WIDTH, 5.2, clean_line)
            pdf.ln(2)   # ← slightly more natural spacing

    pdf.output(filename)
    print(f"✨ Perfected Resume generated: {filename}")

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
        "education": {"degree": "Bachelor", "field": "Computer Science", "institution": "Abc University", "year": "2026"},
        "projects": [{"title": "Sales Dashboard", "description": "Analyzed sales trends", "impact": "20% gain"}],
        "experience": [],
        "certifications": ["Google Data Analytics Certificate"],
        "awards": [],
        "growth": "High"
    }

    job_desc = "Seeking a Data Analyst proficient in SQL, Python, and dashboard creation."

    try:
        # Setup OpenAI client
        client = setup_openai()
        print("AI is optimizing your content using OpenAI...")
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
            
            print("\nGood: " + result["good"])
            print("Needs improvement: " + result["needs_improvement"])
            
            create_styled_resume_pdf(result["improved_resume_text"], user_header_info, pdf_filename)
            print(f"\n✅ Success! PDF saved as: {pdf_filename}")

    except Exception as e:
        print("Process failed:", str(e))