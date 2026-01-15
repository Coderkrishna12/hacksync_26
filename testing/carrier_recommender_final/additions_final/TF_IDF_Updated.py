import pandas as pd

# -----------------------------
# Load dataset
# -----------------------------
df = pd.read_csv("carrier_recommender_final/additions_final/carrier.csv")

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
        "industry": row["industry"]
    })

# -----------------------------
# User input (buttons)
# -----------------------------
user_skills = {
    "IT Support","Troubleshooting"
}
user_skills = {s.lower() for s in user_skills}

user_education = "High School"
user_interests = {"analytical", "technical"}

# -----------------------------
# Scoring logic
# -----------------------------
def score_career(career):
    # Education filter
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
    growth_bonus = GROWTH_WEIGHT.get(career["growth"], 1.0)
    trend_bonus = career["trend_score"] / 10

    interest_bonus = 0.1 if career["interests"] & user_interests else 0

    final_score = (0.6 * coverage) + (0.25 * trend_bonus) + (0.15 * growth_bonus)
    final_score += interest_bonus

    return {
        "career": career["career"],
        "score": round(final_score * 100, 2),
        "matched_skills": matched_skills,
        "missing_skills": sorted(set(career["skills"]) - set(matched_skills)),
        "growth": career["growth"],
        "industry": career["industry"],
        "trend_score": career["trend_score"]
    }

# -----------------------------
# Rank & display
# -----------------------------
results = []

for career in careers:
    r = score_career(career)
    if r:
        results.append(r)

results.sort(key=lambda x: x["score"], reverse=True)

print("\n🔍 Career Recommendations:\n")

for r in results[:3]:
    print(f"🎯 Career: {r['career']}")
    print(f"✅ Match Score: {r['score']}%")
    print(f"📈 Growth: {r['growth']} | 🔥 Trend Score: {r['trend_score']}/10")
    print(f"🏭 Industry: {r['industry']}")
    print(f"🧠 Matched Skills: {', '.join(r['matched_skills'])}")
    print(f"⚠️ Missing Skills: {', '.join(r['missing_skills'])}")
    print("-" * 40)
