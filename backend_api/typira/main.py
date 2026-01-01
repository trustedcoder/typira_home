import os
from fastapi import FastAPI, UploadFile, File, Form
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Typira AI Backend")

# Initialize Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel('gemini-3-flash-preview')

@app.get("/")
async def root():
    return {"message": "Typira AI Backend is running"}

@app.post("/stt")
async def speech_to_text(audio_file: UploadFile = File(...)):
    """
    Receives an audio file and transcribes it using Gemini.
    """
    try:
        # Create uploads directory if it doesn't exist
        upload_dir = "uploads"
        if not os.path.exists(upload_dir):
            os.makedirs(upload_dir)
            
        # Save file locally for testing
        file_path = os.path.join(upload_dir, f"test_{audio_file.filename}")
        content = await audio_file.read()
        with open(file_path, "wb") as f:
            f.write(content)
            
        # Use Gemini to transcribe
        # Gemini 1.5 Flash supports audio data in the prompt
        response = model.generate_content([
            "Transcribe this audio exactly as spoken. Return ONLY the transcribed text.",
            {"mime_type": audio_file.content_type or "audio/wav", "data": content}
        ])

        print(response.text)
        
        return {
            "transcript": response.text.strip(),
            "saved_locally": file_path
        }
    except Exception as e:
        print(e)
        return {"error": str(e)}

@app.post("/rewrite")
async def rewrite_text(text: str = Form(...), tone: str = Form("balanced"), context: str = Form("")):
    """
    Rewrites text according to a specific tone and user context.
    """
    try:
        prompt = f"User Context (Memories): {context}\n\n" if context else ""
        prompt += f"Rewrite the following text in a {tone} tone:\n\n{text}\n\nReturn only the rewritten text."
        
        response = model.generate_content(prompt)
        return {"rewritten_text": response.text.strip()}
    except Exception as e:
        return {"error": str(e)}

@app.post("/remember")
async def remember_context(text: str = Form(...)):
    """
    Stores text in a 'memory' for future context. 
    In a real app, this would be a database or vector store.
    """
    # For now, we'll just log it. 
    # TODO: Implement RAG storage.
    print(f"🧠 Memory stored: {text}")
    return {"status": "success"}

@app.post("/suggest")
async def suggest_text(text: str = Form(...), context: str = Form("")):
    """
    Provides a real-time suggestion based on current text and user context.
    optimized for speed (using gemini-3-flash).
    """
    print(text)
    try:
        # Prompt to generate a full sentence based on current input
        prompt = f"""You are Typira AI, a predictive text assistant.
User Background Context: {context}

User has typed: "{text}"

Generate a complete, grammatically correct sentence that continues naturally from the given text. The sentence should be self-contained and end properly.
Rules:
1. Return the full sentence (including the provided text) as a single string.
2. Do NOT truncate; ensure the sentence is complete.
3. Keep it concise and natural.
4. If no suitable sentence can be formed, return an empty string.

Sentence:"""
        
        response = model.generate_content(prompt)
        full_sentence = response.text.strip().replace('"', '')
        print(full_sentence)
        return {"suggestion": full_sentence}
    except Exception as e:
        print(f"Suggestion Error: {e}")
        return {"suggestion": ""}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
