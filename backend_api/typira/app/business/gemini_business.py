import json
import os
import traceback
import base64
from google import genai
from google.genai import types
from app.business.prompts import BASE_PERSONA, KEYBOARD_PERSONA, INSIGHTS_SCHEMA,OUTPUT_CONSTRAINTS, PRIORITY_TASK_GUIDELINES, STANDARD_CONTEXT_BLOCK, MULTI_STEP_THOUGHT_PROCESS, KEYBOARD_ACTION_DEFINITIONS, AGENTIC_ACTION_DEFINITIONS, KEYBOARD_CONTEXT_BLOCK, KEYBOARD_THOUGHT_PROCESS, KEYBOARD_INSTRUCTIONS, PROACTIVE_ACTIONS_INSTRUCTION, JSON_FORMAT_KEYBOARD_CONTEXT, JSON_FORMAT_INSIGHT, JSON_FORMAT_VOICE, JSON_FORMAT_EXECUTION, PRIORITY_TASK_GOAL, PRIORITY_TASK_EXECUTION_STEPS, AGENTIC_ACTION_PROMPT_TEMPLATE, AGENTIC_EXECUTION_PROMPT_TEMPLATE, AGENTIC_EXECUTION_INSTRUCTIONS, AGENTIC_EXECUTION_CONSTRAINTS_BLOCK, IMAGE_ANALYSIS_PROMPT_TEMPLATE, IMAGE_ANALYSIS_INSTRUCTIONS, VOICE_ANALYSIS_PROMPT_TEMPLATE, VOICE_ANALYSIS_INSTRUCTIONS, TEXT_ANALYSIS_PROMPT_TEMPLATE, TEXT_ANALYSIS_INSTRUCTIONS, JSON_FORMAT_SCHEDULED, SCHEDULED_INSIGHT_PROMPT_TEMPLATE

class GeminiBusiness:
    # Initialize Gemini
    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
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
    def analyze_context(text: str, history: list, app_context: str, current_time: str = None, user_platform: str = None):
        """
        Agentic Brain: Analyzes current text + full semantic history.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""
            
            
            prompt = f"""{KEYBOARD_PERSONA}
{time_context}
{KEYBOARD_CONTEXT_BLOCK.format(history_block=history_block, app_context=app_context, text=text)}

{KEYBOARD_INSTRUCTIONS}
{KEYBOARD_THOUGHT_PROCESS}

{PROACTIVE_ACTIONS_INSTRUCTION.format(user_platform=user_platform or "unknown")}
   {KEYBOARD_ACTION_DEFINITIONS}

5. {INSIGHTS_SCHEMA}

{JSON_FORMAT_KEYBOARD_CONTEXT}

{OUTPUT_CONSTRAINTS}"""
            
            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            
            import json
            if not response.text:
                raise Exception("Empty response from AI")
            return json.loads(response.text)
            
        except Exception as e:
            print(f"Agentic Analysis Error: {e}")
            return {
                "thoughts": ["Analyzing context..."],
                "final_thought": "Agent is active.",
                "actions": []
            }

    @staticmethod
    def get_priority_task(history: list, memories: list, action_history: list, app_context: str, current_time: str = None, user_platform: str = None):
        """
        Looks through user's deep history and memories to find the ONE most important
        priority task they need to handle right now.
        Uses Single-Shot CoT Verification in the prompt.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            memory_block = "\n".join([f"- {m}" for m in memories])
            action_block = "\n".join([f"- {a}" for a in action_history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""
            
            context_filled = STANDARD_CONTEXT_BLOCK.format(
                history_block=history_block,
                memory_block=memory_block,
                action_block=action_block,
                user_platform=user_platform or "unknown"
            )

            prompt = f"""{BASE_PERSONA} 
{time_context}{PRIORITY_TASK_GOAL}

{context_filled}

{PRIORITY_TASK_GUIDELINES}
{PRIORITY_TASK_EXECUTION_STEPS.format(user_platform=user_platform or "unknown", action_definitions=AGENTIC_ACTION_DEFINITIONS)}

7. {INSIGHTS_SCHEMA}

{JSON_FORMAT_INSIGHT}

{OUTPUT_CONSTRAINTS}"""

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI")
            return json.loads(response.text)
            
        except Exception as e:
            print(f"Priority Task Error: {e}")
            return {
                "thoughts": ["I'm having a bit of trouble connecting to my brain..."],
                "title": "Standing by",
                "plan": "I'm standing by to assist with your tasks.",
                "actions": [
                    {
                        "id": "none",
                        "label": "Ready",
                        "type": "none",
                        "payload": ""
                    }
                ]
            }

    @staticmethod
    def perform_keyboard_agentic_action(action_id: str, payload: str, context: str, history: list, current_time: str = None):
        """
        Executes a specific agentic task (Step 2 of the loop).
        Returns a final result (usually text to be inserted).
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""
            
            prompt = AGENTIC_ACTION_PROMPT_TEMPLATE.format(
                time_context=time_context,
                history_block=history_block,
                context=context,
                action_id=action_id,
                payload=payload,
                INSIGHTS_SCHEMA=INSIGHTS_SCHEMA,
                JSON_FORMAT_EXECUTION=JSON_FORMAT_EXECUTION,
                OUTPUT_CONSTRAINTS=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI")
            return json.loads(response.text)
        except Exception as e:
            print(f"Action Execution Error: {e}")
            return {
                "thoughts": ["I encountered an error while executing the action."],
                "title": "Failed to execute action.",
                "plan": "I'm having trouble executing the action.",
                "actions": [{"id": "none", "label": "Ok", "type": "none", "payload": ""}]
            }

    @staticmethod
    def perform_agentic_action(action_id: str, payload: str, history: list, user_input: str = None, current_time: str = None, user_platform: str = None):
        """
        Executes a specific agentic task (Step 2 of the loop).
        Returns a final result with a multi-step thinking process.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""
            input_context = f"MY ADDITIONAL INPUT: \"{user_input}\"\n" if user_input else ""

            prompt = AGENTIC_EXECUTION_PROMPT_TEMPLATE.format(
                base_persona=BASE_PERSONA,
                time_context=time_context,
                input_context=input_context,
                history_block=history_block,
                action_id=action_id,
                payload=payload,
                execution_instructions=AGENTIC_EXECUTION_INSTRUCTIONS,
                insights_schema=INSIGHTS_SCHEMA,
                execution_constraints=AGENTIC_EXECUTION_CONSTRAINTS_BLOCK,
                json_format=JSON_FORMAT_EXECUTION,
                output_constraints=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI")
            return json.loads(response.text)
        except Exception as e:
            print(f"Action Execution Error: {e}")
            return {
                "thoughts": ["I encountered an error while executing the action."],
                "title": "Failed to execute action.",
                "plan": "I'm having trouble executing the action.",
                "actions": [{"id": "none", "label": "Ok", "type": "none", "payload": ""}]
            }

    @staticmethod
    def analyze_image(image_base64: str, mime_type: str, history: list, memories: list, action_history: list, current_time: str = None, user_platform: str = None):
        """
        Analyzes an image using Gemini Vision and context.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            memory_block = "\n".join([f"- {m}" for m in memories])
            action_block = "\n".join([f"- {a}" for a in action_history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""

            # Prepare Image Part
            image_data = base64.b64decode(image_base64)
            image_part = types.Part.from_bytes(data=image_data, mime_type=mime_type)

            prompt = IMAGE_ANALYSIS_PROMPT_TEMPLATE.format(
                time_context=time_context,
                standard_context_block=STANDARD_CONTEXT_BLOCK.format(history_block=history_block, memory_block=memory_block, action_block=action_block, user_platform=user_platform or "unknown"),
                image_analysis_instructions=IMAGE_ANALYSIS_INSTRUCTIONS.format(multi_step_thought_process=MULTI_STEP_THOUGHT_PROCESS, insights_schema=INSIGHTS_SCHEMA),
                json_format=JSON_FORMAT_INSIGHT,
                output_constraints=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=[prompt, image_part],
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            result = json.loads(response.text)
            
            # Store representation in memory is handled by the 'save_to_memory' action being triggered or manual call
            # But the user specifically asked: "The text representation of the image should be stored in the user memory."
            # We will return the result, and the socket handler will handle the memory storage of the representation.
            
            return result

        except Exception as e:
            print(f"Image Analysis Error: {e}")
            print(traceback.format_exc())
            return {
                "thoughts": ["I encountered an error while looking at the image."],
                "title": "Vision Error",
                "plan": "I'm having trouble analyzing this specific image right now.",
                "actions": [{"id": "none", "label": "Ok", "type": "none", "payload": ""}]
            }

    @staticmethod
    def analyze_voice(audio_base64: str, mime_type: str, history: list, memories: list, action_history: list, current_time: str = None, user_platform: str = None):
        """
        Analyzes audio using Gemini and context.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            memory_block = "\n".join([f"- {m}" for m in memories])
            action_block = "\n".join([f"- {a}" for a in action_history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""

            # Prepare Audio Part
            audio_data = base64.b64decode(audio_base64)
            audio_part = types.Part.from_bytes(data=audio_data, mime_type=mime_type)

            prompt = VOICE_ANALYSIS_PROMPT_TEMPLATE.format(
                time_context=time_context,
                standard_context_block=STANDARD_CONTEXT_BLOCK.format(history_block=history_block, memory_block=memory_block, action_block=action_block, user_platform=user_platform or "unknown"),
                voice_analysis_instructions=VOICE_ANALYSIS_INSTRUCTIONS.format(multi_step_thought_process=MULTI_STEP_THOUGHT_PROCESS, insights_schema=INSIGHTS_SCHEMA),
                json_format=JSON_FORMAT_VOICE,
                output_constraints=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=[prompt, audio_part],
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI or blocked by safety filters.")
            return json.loads(response.text)

        except Exception as e:
            print(f"Voice Analysis Error: {e}")
            print(traceback.format_exc())
            return {
                "thoughts": ["I encountered an error while listening to the audio."],
                "title": "Voice Error",
                "plan": "I'm having trouble analyzing your voice recording right now.",
                "actions": [{"id": "none", "label": "Ok", "type": "none", "payload": ""}]
            }

    @staticmethod
    def analyze_text_command(text: str, history: list, memories: list, action_history: list, current_time: str = None, user_platform: str = None):
        """
        Analyzes manually entered text using Gemini and context.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            memory_block = "\n".join([f"- {m}" for m in memories])
            action_block = "\n".join([f"- {a}" for a in action_history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""

            prompt = TEXT_ANALYSIS_PROMPT_TEMPLATE.format(
                base_persona=BASE_PERSONA,
                time_context=time_context,
                standard_context_block=STANDARD_CONTEXT_BLOCK.format(history_block=history_block, memory_block=memory_block, action_block=action_block, user_platform=user_platform or "unknown"),
                text=text,
                text_analysis_instructions=TEXT_ANALYSIS_INSTRUCTIONS.format(multi_step_thought_process=MULTI_STEP_THOUGHT_PROCESS, insights_schema=INSIGHTS_SCHEMA),
                json_format=JSON_FORMAT_INSIGHT,
                output_constraints=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI or blocked by safety filters.")
            return json.loads(response.text)

        except Exception as e:
            print(f"Text Analysis Error: {e}")
            print(traceback.format_exc())
            return {
                "thoughts": ["I encountered an error while processing your text."],
                "title": "Text Error",
                "plan": "I'm having trouble analyzing your request right now.",
                "actions": [{"id": "none", "label": "Ok", "type": "none", "payload": ""}]
            }
    @staticmethod
    def generate_scheduled_insight(action_description: str, history: list, memories: list, action_history: list, current_time: str = None, user_platform: str = None):
        """
        Generates a personalized insight for a scheduled moment, using Google Search grounding.
        Returns: {title, short_description, full_formatted_result}
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            memory_block = "\n".join([f"- {m}" for m in memories])
            action_block = "\n".join([f"- {a}" for a in action_history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""

            prompt = SCHEDULED_INSIGHT_PROMPT_TEMPLATE.format(
                base_persona=BASE_PERSONA,
                time_context=time_context,
                standard_context_block=STANDARD_CONTEXT_BLOCK.format(history_block=history_block, memory_block=memory_block, action_block=action_block, user_platform=user_platform or "unknown"),
                action_description=action_description or "None provided. Find an insightful thing about me.",
                multi_step_thought_process=MULTI_STEP_THOUGHT_PROCESS,
                json_format=JSON_FORMAT_SCHEDULED,
                output_constraints=OUTPUT_CONSTRAINTS
            )

            response = GeminiBusiness.client.models.generate_content(
                model=GeminiBusiness.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json',
                    tools=[types.Tool(google_search=types.GoogleSearch())]
                )
            )
            import json
            if not response.text:
                raise Exception("Empty response from AI or blocked by safety filters.")
            return json.loads(response.text)

        except Exception as e:
            print(f"Scheduled Insight Error: {e}")
            return {
                "title": "Scheduled Helper",
                "short_description": "I noticed it's time for your scheduled update!",
                "full_formatted_result": "I'm having trouble connecting to my live search brain right now, but I haven't forgotten about your schedule. I'll check back soon!"
            }
