from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from datetime import datetime
import requests
import uvicorn
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

SYSTEM_INSTRUCTIONS = (
    "You are a professional dermatology medical assistant. Follow these rules strictly: "
    "1. Respond in the SAME language as the user (Arabic or English). "
    "2. If Arabic, use Arabic numerals (١, ٢, ٣). If English, use (1, 2, 3). "
    "3. Provide useful and concise medical advice, including lifestyle and dietary tips. "
    "4. Cite reliable medical sources like Mayo Clinic, WHO, or medical textbooks. "
    "5. STRICTLY DO NOT use symbols like * or ** for bolding or lists. "
    "6. Use clear numbered paragraphs for your response. "
    "7. ALWAYS end your response with: 'This is not a medical diagnosis' or 'هذا ليس تشخيصاً طبياً'. "
    "8. Be polite and professional. If the user says 'hi' or 'السلام عليكم', respond with a friendly greeting. "
    "9. Use only plain text without markdown symbols."
)

# ✅ مهم: ناخد الداتا بيز من ENV
DATABASE_URL = os.getenv("DATABASE_URL")

conn = psycopg2.connect(DATABASE_URL)
cursor = conn.cursor()

# ✅ إنشاء الجداول (زي ما هي)
cursor.execute("""
CREATE TABLE IF NOT EXISTS chats (
    chat_id TEXT PRIMARY KEY,
    user_id TEXT,
    title TEXT,
    created_at TEXT,
    last_message TEXT
)
""")

cursor.execute("""
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    chat_id TEXT,
    role TEXT,
    text TEXT
)
""")

conn.commit()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
API_KEY = os.getenv("API_KEY", "123456")
GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = "llama-3.3-70b-versatile"

def create_chat(user_id):
    chat_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    cursor.execute(
        "INSERT INTO chats VALUES (%s, %s, %s, %s, %s)",
        (chat_id, user_id, "New Chat", datetime.now().strftime("%Y-%m-%d %H:%M"), "")
    )
    conn.commit()
    return chat_id

@app.get("/chats/{user_id}")
def get_chats(user_id: str):
    cursor.execute(
        "SELECT chat_id, title, created_at, last_message FROM chats WHERE user_id = %s ORDER BY created_at DESC",
        (user_id,)
    )
    rows = cursor.fetchall()
    return [{"chat_id": r[0], "title": r[1], "created_at": r[2], "last_message": r[3]} for r in rows]

@app.get("/chat/{chat_id}")
def get_messages(chat_id: str):
    cursor.execute(
        "SELECT role, text FROM messages WHERE chat_id = %s ORDER BY id ASC",
        (chat_id,)
    )
    rows = cursor.fetchall()
    return [f"{'Assistant' if r[0]=='assistant' else 'User'}: {r[1]}" for r in rows]

@app.post("/chat")
async def chat(request: Request):
    body = await request.json()

    if body.get("api_key") != API_KEY:
        return {"error": "Unauthorized"}

    user_id = body.get("user_id")
    chat_id = body.get("chat_id")
    text = body.get("text")

    if not text:
        return {"error": "Empty message"}

    is_first_msg = False
    if not chat_id:
        chat_id = create_chat(user_id)
        is_first_msg = True

    cursor.execute(
        "INSERT INTO messages (chat_id, role, text) VALUES (%s, %s, %s)",
        (chat_id, "user", text)
    )

    if is_first_msg:
        title = text[:30] + "..." if len(text) > 30 else text
        cursor.execute("UPDATE chats SET title = %s WHERE chat_id = %s", (title, chat_id))

    try:
        res = requests.post(
            GROQ_URL,
            json={
                "model": MODEL_NAME,
                "messages": [
                    {"role": "system", "content": SYSTEM_INSTRUCTIONS},
                    {"role": "user", "content": text}
                ]
            },
            headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
            timeout=25
        )
        reply = res.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print("❌ ERROR:", e)
        reply = "Server error, try again."

    cursor.execute(
        "INSERT INTO messages (chat_id, role, text) VALUES (%s, %s, %s)",
        (chat_id, "assistant", reply)
    )

    cursor.execute(
        "UPDATE chats SET last_message = %s WHERE chat_id = %s",
        (reply[:50], chat_id)
    )

    conn.commit()

    return {"paragraphs": reply.split("\n"), "chat_id": chat_id}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)