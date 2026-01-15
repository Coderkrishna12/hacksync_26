# # improved_resume_pdf.py
# # FINAL STABLE VERSION — NO UNICODE, NO FONT FILES, NO FPDF ERRORS

# from fpdf import FPDF
# from fpdf.enums import XPos, YPos

# PAGE_WIDTH = 210
# LEFT_MARGIN = 10
# RIGHT_MARGIN = 10
# CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN


# # ───────────────────────────────────────────────
# # ASCII NORMALIZER (MANDATORY FOR FPDF CORE FONTS)
# # ───────────────────────────────────────────────
# def ascii_safe(text: str) -> str:
#     if not text:
#         return ""
#     replacements = {
#         "—": "-",
#         "–": "-",
#         "’": "'",
#         "‘": "'",
#         "“": '"',
#         "”": '"',
#         "•": "-",
#     }
#     for k, v in replacements.items():
#         text = text.replace(k, v)

#     return text.encode("latin-1", "ignore").decode("latin-1")


# # ───────────────────────────────────────────────
# # RESUME TEXT
# # ───────────────────────────────────────────────
# IMPROVED_RESUME_TEXT = """
# Amit Vishwakarma
# amit@email.com | 9XXXXXXXXX

# Professional Summary
# Motivated final-year Computer Science student passionate about turning data into business insights.
# Proficient in SQL, Python, Power BI and Excel.
# Seeking entry-level Data Analyst role to apply technical skills and grow rapidly.

# Skills
# SQL - Python - Power BI - Excel - Data Visualization - Statistics - ETL Basics

# Education
# Bachelor of Computer Science
# XYZ University - Expected 2026

# Projects
# Sales Dashboard
# - Developed Power BI dashboard to visualize sales performance
# - Wrote SQL queries on large datasets
# - Improved reporting efficiency by 20 percent
# - Used Python for data cleaning and analysis

# Certifications
# - Google Data Analytics Certificate (In Progress)
# """


# # ───────────────────────────────────────────────
# # PDF CREATOR
# # ───────────────────────────────────────────────
# def create_basic_resume_pdf(text_content, filename="Amit_Resume.pdf"):
#     pdf = FPDF()
#     pdf.add_page()
#     pdf.set_auto_page_break(auto=True, margin=15)

#     text_content = ascii_safe(text_content)

#     # ───── HEADER ─────
#     pdf.set_font("Helvetica", "B", 20)
#     pdf.cell(0, 12, "Amit Vishwakarma", align="C", new_y=YPos.NEXT)

#     pdf.set_font("Helvetica", "", 10)
#     pdf.cell(0, 7, "amit@email.com | 9XXXXXXXXX", align="C", new_y=YPos.NEXT)

#     pdf.ln(6)
#     pdf.line(10, pdf.get_y(), 200, pdf.get_y())
#     pdf.ln(12)

#     lines = text_content.strip().split("\n")
#     current_section = ""

#     for line in lines:
#         line = ascii_safe(line.strip())

#         if not line:
#             pdf.ln(4)
#             continue

#         # ───── SECTION HEADINGS ─────
#         if line.upper() in [
#             "PROFESSIONAL SUMMARY",
#             "SKILLS",
#             "EDUCATION",
#             "PROJECTS",
#             "CERTIFICATIONS",
#         ]:
#             pdf.ln(4)
#             pdf.set_font("Helvetica", "B", 13)
#             pdf.cell(0, 9, line.upper(), new_y=YPos.NEXT)
#             pdf.ln(5)
#             current_section = line
#             continue

#         # ───── SUBHEADINGS ─────
#         if current_section in ["Education", "Projects"] and not line.startswith("-"):
#             pdf.set_font("Helvetica", "B", 11)
#             pdf.cell(0, 7, line, new_y=YPos.NEXT)
#             pdf.ln(3)
#             continue

#         # ───── BULLETS (VISIBLE INDENT) ─────
#         if line.startswith("-"):
#             pdf.set_font("Helvetica", "", 10.5)
#             pdf.set_x(25)  # <<< STRONG INDENT
#             pdf.multi_cell(0, 6, line)
#             pdf.ln(1)
#             continue

#         # ───── SKILLS CENTERED ─────
#         if current_section == "Skills":
#             pdf.set_font("Helvetica", "", 10.5)
#             pdf.multi_cell(0, 6, line, align="C")
#             pdf.ln(2)
#             continue

#         # ───── NORMAL TEXT ─────
#         pdf.set_font("Helvetica", "", 10.5)
#         pdf.multi_cell(0, 6, line)
#         pdf.ln(1)

#     pdf.output(filename)
#     print(f"\nPDF created successfully: {filename}")




# # ───────────────────────────────────────────────
# # RUN
# # ───────────────────────────────────────────────
# if __name__ == "__main__":
#     create_basic_resume_pdf(IMPROVED_RESUME_TEXT)



from fpdf import FPDF
from fpdf.enums import XPos, YPos

# ───────────────────────────────────────────────
# CONSTANTS & STYLING
# ───────────────────────────────────────────────
PAGE_WIDTH = 210
LEFT_MARGIN = 15
RIGHT_MARGIN = 15
CONTENT_WIDTH = PAGE_WIDTH - LEFT_MARGIN - RIGHT_MARGIN
ACCENT_COLOR = (26, 35, 126)  # Deep Navy Blue

# ───────────────────────────────────────────────
# RESUME DATA
# ───────────────────────────────────────────────
IMPROVED_RESUME_TEXT = """
PROFESSIONAL SUMMARY
Motivated final-year Computer Science student passionate about turning data into business insights. Proficient in SQL, Python, Power BI and Excel. Seeking entry-level Data Analyst role to apply technical skills and grow rapidly.

SKILLS
SQL, Python, Power BI, Excel, Data Visualization, Statistics, ETL Basics

EDUCATION
Bachelor of Computer Science
XYZ University | Expected 2026

PROJECTS
Sales Dashboard
- Developed Power BI dashboard to visualize sales performance.
- Wrote SQL queries on large datasets.
- Improved reporting efficiency by 20 percent.
- Used Python for data cleaning and analysis.

CERTIFICATIONS
- Google Data Analytics Certificate (In Progress)
"""

def ascii_safe(text: str) -> str:
    if not text: return ""
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
        """Helper to put text on both ends of the same line"""
        self.set_font("Helvetica", "B", 10)
        current_y = self.get_y()
        # Left side
        self.set_x(LEFT_MARGIN)
        self.cell(CONTENT_WIDTH, 6, left_text, align='L')
        # Right side (reset to same Y)
        self.set_xy(LEFT_MARGIN, current_y)
        self.cell(CONTENT_WIDTH, 6, right_text, align='R', new_y=YPos.NEXT)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 10)
        self.set_x(LEFT_MARGIN + 4)
        self.cell(4, 5, chr(149), align='L') 
        self.set_x(LEFT_MARGIN + 8)
        self.multi_cell(CONTENT_WIDTH - 8, 5, text)
        self.ln(1)

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
    
    pdf.ln(6)
    pdf.set_draw_color(*ACCENT_COLOR)
    pdf.set_line_width(0.6)
    pdf.line(LEFT_MARGIN, pdf.get_y(), PAGE_WIDTH - RIGHT_MARGIN, pdf.get_y())
    
    # ───── 2. CONTENT PARSING ─────
    lines = text_content.strip().split("\n")
    current_section = ""

    for line in lines:
        clean_line = ascii_safe(line.strip())
        if not clean_line: continue

        # Section Headers
        if clean_line in ["PROFESSIONAL SUMMARY", "SKILLS", "EDUCATION", "PROJECTS", "CERTIFICATIONS"]:
            pdf.add_section_header(clean_line)
            current_section = clean_line
            continue

        # Bullet Points
        if clean_line.startswith("-"):
            pdf.add_bullet(clean_line[1:].strip())
            continue

        # Smart Alignment for Education & Projects
        if current_section in ["EDUCATION", "PROJECTS"]:
            if "|" in clean_line:
                parts = clean_line.split("|")
                pdf.add_split_line(parts[0].strip(), parts[1].strip())
            else:
                pdf.set_font("Helvetica", "B", 10.5)
                pdf.cell(0, 6, clean_line, new_y=YPos.NEXT)
        else:
            # Summary / Skills
            pdf.set_font("Helvetica", "", 10)
            pdf.multi_cell(CONTENT_WIDTH, 5, clean_line)
            pdf.ln(1)

    pdf.output(filename)
    print(f"✨ Perfected Resume generated: {filename}")

if __name__ == "__main__":
    create_styled_resume(IMPROVED_RESUME_TEXT)