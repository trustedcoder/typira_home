
import os
import traceback
from google import genai
from google.genai import types

class GeminiBusiness:
    # Initialize Gemini
    client = genai.Client()
    model_name = 'gemini-2.5-flash-lite'

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
    def canonicalize_sentence(sentence: str):
        """
        Uses Gemini to identify the 'Semantic Intent' of a sentence.
        Returns a canonical label for deduplication.
        """
        try:
            # More strict prompt for determinism
            prompt = f"""Identify the core 'Semantic Intent' of the following sentence. 
Rules:
1. Return a single, short, capitalized label (snake_case). 
2. Be highly consistent: if the sentence means the same thing, the label must be EXACTLY the same.
3. Remove specific fluff (e.g. "I want to eat rice" -> EAT_RICE, "I'm eating rice" -> EAT_RICE).
4. For general chat, return a simple summary (e.g. GREETING).

Sentence: "{sentence}"

Canonical Label:"""
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt
            )
            label = response.text.strip().upper().replace(" ", "_").replace('"', '')
            print(f"DEBUG: [Gemini] Canonical Label: '{label}' for sentence: '{sentence}'")
            return label
        except Exception as e:
            print(f"Canonicalization Error: {e}")
            return sentence.upper() # Fallback
