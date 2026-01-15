import pandas as pd

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv("carrier.csv")

# -----------------------------
# Helpers
# -----------------------------
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

# -----------------------------
# Prepare careers
# -----------------------------
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

# -----------------------------
# User input (buttons)
# -----------------------------
user_skills = {"SQL", "javaScript", "Python", "Pandas"}
user_skills = {s.lower() for s in user_skills}

user_education = "Bachelor"
user_interests = {"technical"}

# -----------------------------
# Scoring logic
# -----------------------------
def score_career(career):
    if EDU_LEVEL[user_education] < EDU_LEVEL[career["min_education"]]:
        return None

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

# -----------------------------
# Rank careers
# -----------------------------
results = []

for career in careers:
    r = score_career(career)
    if r:
        results.append(r)

results.sort(key=lambda x: x["score"], reverse=True)

# -----------------------------
# Display results
# -----------------------------
print("\n🔍 Career Recommendations\n")

for r in results[:3]:
    print(f"🎯 Career: {r['career']}")
    print(f"🏷️ Fit Level: {r['fit']}")
    print(f"✅ Match Score: {r['score']}%")
    print(f"🔥 Trend Score: {r['trend_score']}/10")
    print(f"🏭 Industry: {r['industry']}")
    print(f"🛣️ Career Path: {r['career_path']}")
    print(f"🧠 Matched Skills: {', '.join(r['matched_skills'])}")
    print(f"⚠️ Missing Skills: {', '.join(r['missing_skills'])}")
    print(f"📘 Next Steps: {r['next_steps']}")
    print("-" * 50)

# -----------------------------
# Overall guidance
# -----------------------------
if results:
    top = results[0]
    print("\n📌 Personalized Guidance:")
    print(
        f"You are closest to **{top['career']}** roles. "
        f"Focus on learning **{', '.join(top['missing_skills'][:3])}** "
        "to unlock higher-paying opportunities."
    )
