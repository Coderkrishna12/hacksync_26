from flask import Flask, request, jsonify
import pandas as pd
import os

app = Flask(__name__)

# ────────────────────────────────────────────────
#  Load dataset
# ────────────────────────────────────────────────
CSV_PATH = "carrier.csv"

if not os.path.exists(CSV_PATH):
    print(f"ERROR: {CSV_PATH} not found in current directory: {os.getcwd()}")
else:
    print(f"Loading dataset from: {CSV_PATH}")

try:
    df = pd.read_csv(CSV_PATH)
    print(f"Dataset loaded successfully — {len(df)} careers found")
    print("Columns:", list(df.columns))
except Exception as e:
    print(f"Failed to load CSV: {e}")
    df = pd.DataFrame()  # empty fallback

# ────────────────────────────────────────────────
#  Helpers (exactly same as standalone)
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

# ────────────────────────────────────────────────
#  Prepare careers (same as standalone)
# ────────────────────────────────────────────────
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
#  Very simple skill normalization (to fix 0 matches)
# ────────────────────────────────────────────────
def normalize_skill(skill):
    skill = skill.lower().strip()
    skill = skill.replace(" ", "")           # remove spaces
    skill = skill.replace("js", "javascript")
    skill = skill.replace("reactjs", "react")
    skill = skill.replace("next.js", "nextjs")
    skill = skill.replace("node.js", "nodejs")
    return skill

# ────────────────────────────────────────────────
#  Scoring logic — made almost identical to standalone
# ────────────────────────────────────────────────
def score_career(career, user_skills, user_education, user_interests):
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
#  API Endpoint
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

        # ── Prepare user data (similar to standalone) ──
        raw_skills = data.get("skills", [])
        user_education = data.get("education", "")
        raw_interests = data.get("interests", [])

        if not raw_skills or not user_education:
            print("Missing required fields")
            return jsonify({"error": "skills and education are required"}), 400

        # Normalize skills like in your test data
        user_skills = {normalize_skill(s) for s in raw_skills}
        user_interests = {i.strip().lower() for i in raw_interests}

        print(f"Normalized user skills ({len(user_skills)}): {sorted(user_skills)}")
        print(f"Education: {user_education}")
        print(f"User interests ({len(user_interests)}): {sorted(user_interests)}")

        # ── Scoring (very close to standalone loop) ──
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


@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "message": "Career Recommendation API is running",
        "endpoint": "POST /recommend",
        "example": {
            "skills": ["python", "sql", "javascript", "react js"],
            "education": "Bachelor",
            "interests": ["technical", "analytical"]
        }
    })


if __name__ == '__main__':
    print("Starting Flask server in debug mode...")
    app.run(host='0.0.0.0', port=5000, debug=True)