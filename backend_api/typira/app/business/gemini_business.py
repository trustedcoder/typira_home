
import os
import traceback
from google import genai
from google.genai import types

class GeminiBusiness:
    # Initialize Gemini
    client = genai.Client()
    model_name = 'gemini-3-flash-preview'

    @staticmethod
    def speech_to_text(audio_file):
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
            audio_file.save(file_path)

            with open(file_path, "rb") as f:
                content = f.read()
                
            # Use Gemini to transcribe
            audio_part = types.Part.from_bytes(
                data=content,
                mime_type=audio_file.content_type or "audio/wav"
            )
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=[
                    "Transcribe this audio exactly as spoken. Return ONLY the transcribed text.",
                    audio_part
                ]
            )

            print(response.text)
            
            return {
                "transcript": response.text.strip(),
                "saved_locally": file_path
            }
        except Exception as e:
            print(traceback.format_exc())
            return {"error": str(e)}

    @staticmethod
    def rewrite_text(text: str, tone: str, context: str):
        """
        Rewrites text according to a specific tone and user context.
        """
        try:
            prompt = f"User Context (Memories): {context}\n\n" if context else ""
            prompt += f"Rewrite the following text in a {tone} tone:\n\n{text}\n\nReturn only the rewritten text."
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt
            )
            return {"rewritten_text": response.text.strip()}
        except Exception as e:
            print(traceback.format_exc())
            return {"error": str(e)}

    @staticmethod
    def remember_context(text: str):
        """
        Stores text in a 'memory' for future context. 
        In a real app, this would be a database or vector store.
        """
        # For now, we'll just log it. 
        # TODO: Implement RAG storage.
        print(f"🧠 Memory stored: {text}")
        return {"status": "success"}

    @staticmethod
    def suggest_text(text: str, context: str):
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
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt
            )
            full_sentence = response.text.strip().replace('"', '')
            print(full_sentence)
            return {"suggestion": full_sentence}
        except Exception as e:
            print(f"Suggestion Error: {e}")
            print(traceback.format_exc())
            return {"suggestion": ""}

    @staticmethod
    def analyze_context(text: str, history: list, app_context: str):
        """
        Agentic Brain: Analyzes current text + full semantic history.
        Returns a JSON with 'thoughts' (list) and 'actions' (list of {id, label}).
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            
            prompt = f"""You are 'Typira Agent', a proactive AI companion integrated into a smartphone keyboard.
Your goal is to anticipate the user's needs based on their current typing AND their deep typing history.

USER HISTORY (Top Intents/Frequent Topics):
{history_block}

CURRENT APP CONTEXT: {app_context}
USER IS CURRENTLY TYPING: "{text}"

INSTRUCTIONS:
1. Analyze the 'Inferred Intent' of the user's current text.
2. Cross-reference with their 'History' to find patterns or relevant topics.
3. Formulate a multi-step 'Thought Process' describing what you are doing.
4. If a clear task is detected (e.g. scheduling, drafting, searching, calculation), suggest 2-4 'Proactive Actions'.

OUTPUT FORMAT (Strict JSON):
{{
  "thoughts": ["Initial observation...", "History lookup result...", "Intent confirmed..."],
  "final_thought": "Short summary of your conclusion for the user.",
  "actions": [
    {{"id": "suggest_draft", "label": "✍️ Draft Response"}},
    {{"id": "schedule_event", "label": "📅 Schedule meeting"}}
  ]
}}

Return ONLY the JSON object."""
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            
            import json
            return json.loads(response.text)
        except Exception as e:
            print(f"Agentic Analysis Error: {e}")
            return {
                "thoughts": ["Analyzing context..."],
                "final_thought": "Agent is active.",
                "actions": []
            }

