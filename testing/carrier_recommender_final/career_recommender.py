# import pandas as pd
# from sklearn.feature_extraction.text import TfidfVectorizer
# from sklearn.metrics.pairwise import cosine_similarity

# # -----------------------------
# # Load career dataset
# # -----------------------------
# df = pd.read_csv("careers.csv")

# career_names = df["career"].tolist()
# career_skills = df["skills"].tolist()
# career_growth = df["growth"].tolist()

# # -----------------------------
# # User input (test example)
# # -----------------------------
# user_skills = "Python SQL Statistics"

# # -----------------------------
# # TF-IDF Vectorization
# # -----------------------------
# vectorizer = TfidfVectorizer(stop_words="english")

# career_vectors = vectorizer.fit_transform(career_skills)
# user_vector = vectorizer.transform([user_skills])

# # -----------------------------
# # Similarity calculation
# # -----------------------------
# similarity_scores = cosine_similarity(user_vector, career_vectors)[0]

# # -----------------------------
# # Rank careers
# # -----------------------------
# results = []
# for i, score in enumerate(similarity_scores):
#     required = set(career_skills[i].split())
#     user = set(user_skills.split())
#     missing_skills = list(required - user)

#     results.append({
#         "career": career_names[i],
#         "match_percentage": round(score * 100, 2),
#         "missing_skills": missing_skills,
#         "growth": career_growth[i]
#     })

# results = sorted(results, key=lambda x: x["match_percentage"], reverse=True)

# # -----------------------------
# # Display Top 3 Results
# # -----------------------------
# print("\n🔍 Career Recommendations:\n")
# for r in results[:3]:
#     print(f"🎯 Career: {r['career']}")
#     print(f"✅ Match: {r['match_percentage']}%")
#     print(f"📈 Growth: {r['growth']}")
#     print(f"⚠️ Missing Skills: {', '.join(r['missing_skills']) if r['missing_skills'] else 'None'}")
#     print("-" * 40)



import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# -----------------------------
# Skill normalization
# -----------------------------
SKILL_ALIASES = {
    "ml": "machine learning",
    "ai": "artificial intelligence",
    "js": "javascript",
    "py": "python",
    "dl": "deep learning"
}

def normalize_skills(text):
    text = text.lower()
    for k, v in SKILL_ALIASES.items():
        text = text.replace(k, v)
    return text

# -----------------------------
# Optional: core skill weighting
# Use * to mark important skills in dataset
# -----------------------------
def weight_core_skills(text):
    words = text.split()
    weighted = []
    for w in words:
        if w.endswith("*"):
            weighted.extend([w.replace("*", "")] * 3)
        else:
            weighted.append(w)
    return " ".join(weighted)

# -----------------------------
# Load career dataset
# -----------------------------
df = pd.read_csv("careers.csv")

career_names = df["career"].tolist()
career_growth = df["growth"].tolist()

career_skills = [
    weight_core_skills(normalize_skills(s))
    for s in df["skills"].tolist()
]

# -----------------------------
# User input (test example)
# -----------------------------
user_skills = normalize_skills("python sql pandas statistics  ml numpython")

# -----------------------------
# TF-IDF Vectorization (improved)
# -----------------------------
vectorizer = TfidfVectorizer(
    stop_words="english",
    ngram_range=(1, 2),      # BIG accuracy gain
    min_df=1
)

career_vectors = vectorizer.fit_transform(career_skills)
user_vector = vectorizer.transform([user_skills])

# -----------------------------
# Similarity calculation
# -----------------------------
similarity_scores = cosine_similarity(user_vector, career_vectors)[0]

# -----------------------------
# Rank careers with threshold
# -----------------------------
results = []
SIMILARITY_THRESHOLD = 0.25  # ignore weak matches

user_skill_set = set(user_skills.split())

for i, score in enumerate(similarity_scores):
    if score < SIMILARITY_THRESHOLD:
        continue

    required_skills = set(career_skills[i].split())
    missing_skills = list(required_skills - user_skill_set)

    results.append({
        "career": career_names[i],
        "match_percentage": round(score * 100, 2),
        "missing_skills": missing_skills,
        "growth": career_growth[i]
    })

results = sorted(results, key=lambda x: x["match_percentage"], reverse=True)

# -----------------------------
# Display Top 3 Results
# -----------------------------
print("\n🔍 Career Recommendations:\n")

if not results:
    print("No strong matches found. Try adding more skills.")
else:
    for r in results[:3]:
        print(f"🎯 Career: {r['career']}")
        print(f"✅ Match: {r['match_percentage']}%")
        print(f"📈 Growth: {r['growth']}")
        print(
            f"⚠️ Missing Skills: "
            f"{', '.join(r['missing_skills']) if r['missing_skills'] else 'None'}"
        )
        print("-" * 40)
