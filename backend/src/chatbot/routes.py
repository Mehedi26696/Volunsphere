from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy import text
from src.db.main import get_session
from src.auth.dependencies import AccessTokenBearer
from src.config import Config

chatbot_router = APIRouter()

ALLOWED_TABLES = ["users", "events", "event_responses"]

client = OpenAI(
    api_key=Config.GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1"
)

@chatbot_router.post("/query")
async def query_chatbot(
    body: dict,
    token: dict = Depends(AccessTokenBearer()),
    session: AsyncSession = Depends(get_session)
):
    question = body.get("question", "").strip().lower()
    
    if not question:
        raise HTTPException(status_code=400, detail="Question is required.")

    # Reject casual or vague messages
    casual_inputs = {"hi", "hello", "hey", "how are you", "what's up", "yo"}
    if question in casual_inputs:
        return {
            "success": False,
            "question": question,
            "message": "This assistant is designed to help with SQL-based data queries only.",
            "suggestion": "Please ask something like: 'Show all events this week' or 'List users from Bangladesh'."
        }

    if len(question.split()) < 3:
        return {
            "success": False,
            "question": question,
            "message": "Please ask a more specific data-related question.",
            "suggestion": "Try something like: 'Get verified users from Dhaka' or 'Top rated events last month'."
        }

    prompt = f"""
You are a strict PostgreSQL SQL generator. You must generate ONLY the SQL query, with no greetings, explanations, or comments.

Tables you can use: {', '.join(ALLOWED_TABLES)}

Column names (use these exactly):
- users: uid, username, email, first_name, last_name, city, country, phone, is_verified, profile_image_url, created_at
- events: id, title, description, location, start_datetime, end_datetime, duration_minutes, latitude, longitude, image_urls, creator_id, created_at
- event_responses: id, event_id, user_id, work_time_hours, rating

Rules:
1. Use only the above column names and tables.
2. For "name", map to username, first_name, last_name, or title.
3. For past events: use start_datetime < NOW() or end_datetime < NOW()
4. For upcoming events: use start_datetime > NOW()
5. For recent/new/latest: use ORDER BY created_at DESC
6. For event_responses, use JOINs with users/events.
7. Add LIMIT for large result sets.
8. Do NOT respond to greetings or non-query prompts. If unsure, reply: "INVALID REQUEST".
9. Output ONLY the SQL query.

User question: "{question}"

SQL:
    """

    try:
        response = client.chat.completions.create(
            model="llama3-8b-8192",
            messages=[
                {"role": "system", "content": "You are a PostgreSQL SQL generator. Output ONLY SQL. Reject non-data prompts."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
        )
        generated_sql = response.choices[0].message.content.strip()

        if generated_sql.upper().startswith("INVALID REQUEST"):
            return {
                "success": False,
                "question": question,
                "message": "This assistant only handles structured database queries.",
                "suggestion": "Try asking: 'List users who joined recently' or 'Show upcoming events in Dhaka'."
            }

        # Clean up markdown formatting
        if generated_sql.startswith("```sql"):
            generated_sql = generated_sql.replace("```sql", "").replace("```", "").strip()
        elif generated_sql.startswith("```"):
            generated_sql = generated_sql.replace("```", "").strip()

        # Enforce limit if missing
        if "limit" not in generated_sql.lower():
            generated_sql += " LIMIT 20"

    except Exception as e:
        return {
            "success": False,
            "question": question,
            "error_type": "AI Service Error",
            "error_message": f"Failed to generate SQL query: {str(e)}",
            "suggestion": "Please try again or rephrase your question."
        }

    print("Generated SQL:", generated_sql)

    try:
        result = await session.exec(text(generated_sql))
        rows = result.fetchall()

        formatted_answer = []
        for row in rows:
            row_dict = dict(row._mapping)
            filtered_row = {
                key: value for key, value in row_dict.items()
                if not (
                    key.lower().endswith('_id') or 
                    key.lower() in {'id', 'uid'} or 
                    key.lower().endswith('_url') or 
                    key.lower().endswith('_urls') or 
                    'url' in key.lower() or 
                    'link' in key.lower()
                )
            }
            formatted_answer.append(filtered_row)

        if formatted_answer:
            return {
                "success": True,
                "question": question,
                "sql_query": generated_sql,
                "result_count": len(formatted_answer),
                "data": formatted_answer,
                "message": f"Found {len(formatted_answer)} result(s)."
            }
        else:
            return {
                "success": False,
                "question": question,
                "sql_query": generated_sql,
                "result_count": 0,
                "data": [],
                "message": "No results found or data does not match the query.",
                "suggestion": "Try rephrasing your question or check if data exists for your query."
            }

    except Exception as e:
        error_message = str(e)
        if "does not exist" in error_message:
            error_type = "Column or table does not exist"
        elif "syntax error" in error_message.lower():
            error_type = "SQL syntax error"
        elif "permission" in error_message.lower():
            error_type = "Permission denied"
        else:
            error_type = "Database query error"

        return {
            "success": False,
            "question": question,
            "sql_query": generated_sql,
            "error_type": error_type,
            "error_message": error_message,
            "suggestion": "Please rephrase your question or check the data/tables you're querying."
        }
