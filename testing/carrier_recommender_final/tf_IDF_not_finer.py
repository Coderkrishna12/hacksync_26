import pandas as pd

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv("Carrier_updated.csv")

# -----------------------------
# Parse skills (comma-safe)
# -----------------------------
def parse_skills(skill_string):
    skills = {}
    for s in skill_string.split(","):
        s = s.strip().lower()
        if s.endswith("*"):
            skills[s.replace("*", "")] = 3  # core skill
        else:
            skills[s] = 1  # optional skill
    return skills

careers = []

for _, row in df.iterrows():
    careers.append({
        "career": row["career"],
        "skills": parse_skills(row["skills"]),
        "growth": row["growth"]
    })

# -----------------------------
# User input (from buttons)
# -----------------------------
user_skills_list = [
    "sql",
    "statistics",
    "excel",
    "hadoop",
    "power bi",
    "etl"
]

user_skills = {s.lower().strip() for s in user_skills_list}


# -----------------------------
# Growth multiplier
# -----------------------------
GROWTH_WEIGHT = {
    "Low": 0.9,
    "Medium": 1.0,
    "High": 1.2
}

# -----------------------------
# Scoring logic
# -----------------------------
def score_career(user_skills, career):
    matched_weight = 0
    total_weight = sum(career["skills"].values())
    matched_skills = []

    for skill, weight in career["skills"].items():
        if skill in user_skills:
            matched_weight += weight
            matched_skills.append(skill)

    if matched_weight == 0:
        return None

    coverage = matched_weight / total_weight
    growth_bonus = GROWTH_WEIGHT.get(career["growth"], 1.0)

    final_score = coverage * growth_bonus

    return {
        "career": career["career"],
        "score": round(final_score * 100, 2),
        "matched_skills": matched_skills,
        "missing_skills": sorted(
            set(career["skills"]) - set(matched_skills)
        ),
        "growth": career["growth"]
    }

# -----------------------------
# Rank careers
# -----------------------------
results = []

for career in careers:
    r = score_career(user_skills, career)
    if r:
        results.append(r)

results.sort(key=lambda x: x["score"], reverse=True)

# -----------------------------
# Display results
# -----------------------------
print("\n🔍 Career Recommendations:\n")

for r in results[:3]:
    print(f"🎯 Career: {r['career']}")
    print(f"✅ Match Score: {r['score']}%")
    print(f"📈 Growth: {r['growth']}")
    print(f"🧠 Matched Skills: {', '.join(r['matched_skills'])}")
    print(
        f"⚠️ Missing Skills: "
        f"{', '.join(r['missing_skills']) if r['missing_skills'] else 'None'}"
    )
    print("-" * 40)
