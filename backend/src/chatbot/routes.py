
from openai import OpenAI
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel.ext.asyncio.session import AsyncSession
from sqlalchemy import text
from src.db.main import get_session
from src.auth.dependencies import AccessTokenBearer
from src.config import Config

chatbot_router = APIRouter()

ALLOWED_TABLES = ["users", "events","event_responses"]

 
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
    question = body.get("question")
    if not question:
        raise HTTPException(status_code=400, detail="Question required")

    prompt = f"""
You are a PostgreSQL query generator. Generate ONLY the SQL query, no explanations.

Available tables: {', '.join(ALLOWED_TABLES)}

ACTUAL column names (use these exact names):
- For users table: uid, username, email, first_name, last_name, city, country, phone, is_verified, profile_image_url, created_at
- For events table: id, title, description, location, start_datetime, end_datetime, duration_minutes, latitude, longitude, image_urls, creator_id, created_at
- For event_responses table: id, event_id, user_id, work_time_hours, rating

Instructions:
1. Use ONLY the exact column names listed above
2. For date/time queries on events, use: start_datetime, end_datetime, or created_at
3. If user asks for "name" or "names":
   - For users: try first_name, last_name, username  
   - For events: try title
4. If user asks for "past events", use: WHERE start_datetime < NOW() OR WHERE end_datetime < NOW()
5. If user asks for "recent", "latest", "new", use ORDER BY created_at DESC
6. If user asks for "upcoming events", use: WHERE start_datetime > NOW()
7. For event_responses queries:
   - Use JOINs to connect with events and users tables
   - rating is between 0-5, work_time_hours is float
8. Always use proper PostgreSQL syntax
9. Use LIMIT when appropriate for large datasets

User question: "{question}"

SQL:"""

    try:
        response = client.chat.completions.create(
            model="llama3-8b-8192",  # Or "llama3-70b-8192"
            messages=[
                {"role": "system", "content": "You are a PostgreSQL SQL generator."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
        )
        generated_sql = response.choices[0].message.content.strip()
        
        # Clean up the SQL (remove any markdown formatting)
        if generated_sql.startswith("```sql"):
            generated_sql = generated_sql.replace("```sql", "").replace("```", "").strip()
        elif generated_sql.startswith("```"):
            generated_sql = generated_sql.replace("```", "").strip()
            
    except Exception as e:
        return {
            "success": False,
            "question": question,
            "error_type": "AI Service Error",
            "error_message": f"Failed to generate SQL query: {str(e)}",
            "suggestion": "Please try again or rephrase your question."
        }
 
    print("Generated SQL:", generated_sql)
 
    # Safely execute SQL
    try:
        result = await session.exec(text(generated_sql))
        rows = result.fetchall()
        
        # Format the response with better structure
        formatted_answer = []
        for row in rows:
            row_dict = dict(row._mapping)
            # Filter out ID fields and links
            filtered_row = {}
            for key, value in row_dict.items():
                # Skip ID fields and URL/link fields
                if not (
                    key.lower().endswith('_id') or 
                    key.lower() == 'id' or 
                    key.lower() == 'uid' or
                    key.lower().endswith('_url') or
                    key.lower().endswith('_urls') or
                    key.lower().endswith('url') or
                    key.lower().endswith('urls') or
                    'link' in key.lower()
                ):
                    filtered_row[key] = value
            formatted_answer.append(filtered_row)
        
        # Create a more informative response
        if formatted_answer:
            response_data = {
                "success": True,
                "question": question,
                "sql_query": generated_sql,
                "result_count": len(formatted_answer),
                "data": formatted_answer,
                "message": f"Found {len(formatted_answer)} result(s)"
            }
        else:
            response_data = {
                "success": False,
                "question": question,
                "sql_query": generated_sql,
                "result_count": 0,
                "data": [],
                "message": "We cannot provide this information right now. Please refactor or rephrase your question.",
                "suggestion": "Try asking in a different way or check if the data you're looking for exists in our system."
            }
        
        return response_data
        
    except Exception as e:
        # Better error formatting
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
            "suggestion": "Please try rephrasing your question or check if the requested data exists."
        }
