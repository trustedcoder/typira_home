import json
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
    def analyze_context(text: str, history: list, app_context: str, current_time: str = None, user_platform: str = None):
        """
        Agentic Brain: Analyzes current text + full semantic history.
        """
        try:
            history_block = "\n".join([f"- {h}" for h in history])
            time_context = f"CURRENT TIME: {current_time}\n" if current_time else ""
            
            prompt = f"""You are Typira, my personal assistant integrated into my smartphone keyboard.
{time_context}Your goal is to anticipate my needs based on what I'm typing AND my deep typing history.

MY HISTORY (Top Intents/Frequent Topics):
{history_block}

CURRENT APP CONTEXT: {app_context}
I AM CURRENTLY TYPING: "{text}"

INSTRUCTIONS:
1. Analyze my 'Inferred Intent' based on the text.
2. Cross-reference with my 'History' to find patterns or relevant topics. Use the 'Logged on' timestamps provided in the history to resolve relative time expressions (e.g., 'tomorrow', 'next day') relative to the context they were typed in, and then map them to absolute dates relative to the CURRENT TIME.
3. Formulate a multi-step 'Thought Process':
   - First, analyze the intent and history.
   - Second, propose initial actions (provisional).
   - Third, CRITIQUE your own actions within these thoughts. Check if deep links use valid schemes (NO 'whatsapp://', use 'mailto:', 'maps://', 'tel:', 'sms:'). Ensure the calendar event structure is correct.
   - Fourth, finalize the actions.
   - IMPORTANT: When writing these 'thoughts', use natural language. Do NOT mention internal keys like 'prompt_trigger', 'calendar_event', 'deep_link', or 'payload'. Say "reminder", "map link", "drafting assistant", etc.

4. Suggest 2-4 'Proactive Actions'.
   - USER PLATFORM: {user_platform or "unknown"}
   - 'type' MUST be: 
     - 'deep_link': for DIRECT system calls like Maps.
     - 'calendar_event': for setting reminders or calendar events. Mandatory payload: {{ "title": "...", "description": "...", "start": "ISO_DATETIME", "end": "ISO_DATETIME" }}.
     - 'prompt_trigger': for tasks needing AI processing/synthesis.

OUTPUT FORMAT (Strict JSON):
{{
  "thoughts": [
      "I'm checking your history...", 
      "Initial thought: Send a WhatsApp message...", 
      "CRITIQUE: WhatsApp deep links are unreliable on iOS. Switching to a standard SMS link for safety.",
      "Final Plan: Draft SMS invitation."
  ],
  "final_thought": "Short summary of your conclusion for me.",
  "actions": [
    {{
      "id": "draft_invite", 
      "label": "✍️ Draft Response", 
      "type": "prompt_trigger", 
      "payload": "Please draft a polite lunch invitation based on my schedule."
    }},
    {{
      "id": "show_map", 
      "label": "📍 Show on Map", 
      "type": "deep_link", 
      "payload": "maps://?q=Lagos+Restaurants"
    }}
  ]
}}

- Use 'I' and 'you' (me). NEVER refer to me as 'the user'.
- For generic system tasks (Search, Maps, Browser), use 'type': 'deep_link' with a valid URL scheme or URL as 'payload'.
- For Reminders/Events/Calendar, use 'type': 'calendar_event' with a structured JSON payload.
- For iterative AI tasks (Drafting, Rewriting, Formalizing), use 'type': 'prompt_trigger' with a specific instruction as 'payload'.

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

            prompt = f"""You are Typira, my personal assistant. 
{time_context}Your goal is to find the SINGLE MOST IMPORTANT and TIME-CRITICAL task for me based on my history and memories.

MY TYPING HISTORY (Intents/Frequent Topics):
{history_block}

MY MEMORIES (Past events/decisions):
{memory_block}

MY RECENT ACTIONS (Approved/Declined):
{action_block}

CURRENT APP CONTEXT: {app_context}

INSTRUCTIONS:
1. Identify a task that is actionable and likely requires my approval or input.
2. It MUST be something I haven't finished yet or something recurring that needs attention NOW.
3. Formulate a multi-step 'Thought Process' describing what you are doing. Speak to me directly.
   - CRITICAL: You must explicitly VERIFY your own plan within your thoughts.
   - Check against MY RECENT ACTIONS. Do not propose the SAME task (same instruction or intent) that I recently approved or declined, UNLESS there is a fresh, time-critical reason to do so.
   - Check if your deep links are valid (e.g., Use 'mailto:', 'maps://', 'sms:', 'tel:'. Avoid 'whatsapp://' or custom schemes unless certain).
   - Check if your calendar payloads are valid JSON.
   - If a task is too complex for a deep link, downgrade it to a generic drafting task.
   - IMPORTANT: When writing these 'thoughts', use natural language. Do NOT mention internal keys like 'prompt_trigger', 'calendar_event', 'deep_link', or 'payload'. Say "reminder", "map link", "drafting assistant", etc.

4. Formulate a 'Plan' or 'Walkthrough' of what you intend to do. This MUST be exhaustive and standalone.
5. Provide a 'title' for this priority (short, max 3-4 words, e.g. "Meeting Prep", "Drafting Response").
6. Provide a list of 'actions' (buttons) I can take. 
   - Each action must have an 'id', 'label', 'type', and 'payload' (instructions).
    - USER PLATFORM: {user_platform or "unknown"}
    - 'type' MUST be one of: 
      - 'deep_link': for URLs/URI schemes. Use this for DIRECT system actions like Maps or Messaging.
      - 'calendar_event': for setting reminders, tasks, or calendar events. 
        - Payload MUST be a JSON object: {{ "title": "...", "description": "...", "start": "ISO_DATETIME", "end": "ISO_DATETIME" }}.
      - 'prompt_trigger': for iterative AI tasks like drafting, researching, or synthesizing content where I should "think" more first. Payload should be the instruction. Use this if the task cannot be handled by a reliable deep link or calendar event.
      - 'input': if you need more information from me to proceed.
      - 'none': for skipping/declining.
   - For 'prompt_trigger' and 'input', the 'payload' MUST contain the full initial plan or the precise instruction I need to execute, so I have context when I start working on it.
   - Always provide at least one positive/affirmative action (trigger or input) and one to skip/decline.

OUTPUT FORMAT (Strict JSON):
{{
  "thoughts": [
      "I'm looking through your recent activity...", 
      "I see you have an upcoming meeting...", 
      "Drafting potential actions...",
      "VERIFICATION: Checking if the map link is valid... Yes.",
      "VERIFICATION: WhatsApp direct links are risky, so I'm switching to a drafting assistant to help you write the message instead.",
      "I've decided this is the top priority."
  ],
  "title": "Project Update",
  "plan": "I noticed you mentioned a deadline for tomorrow. I will draft a comprehensive project update for you.",
  "actions": [
     {{
       "id": "set_event",
       "label": "🔔 Set Event",
       "type": "calendar_event",
       "payload": {{
         "title": "Bank Visit",
         "description": "Bring ID and account number.",
         "start": "2026-01-19T10:00:00Z",
         "end": "2026-01-19T11:00:00Z"
       }}
     }}
,
    {{
      "id": "draft_update",
      "label": "✍️ Draft Update",
      "type": "prompt_trigger",
      "payload": "Draft a comprehensive project update for [Context] based on my initial plan: I noticed a deadline tomorrow and will synthesize the latest status."
    }},
    {{
      "id": "more_details",
      "label": "🤔 Give more info",
      "type": "input",
      "payload": "I'm planning to draft a project update. Please tell me which specific milestones I should highlight."
    }},
    {{
      "id": "none",
      "label": "❌ Not now",
      "type": "none",
      "payload": ""
    }}
  ]
}}

- Use 'I' and 'you' (me). NEVER refer to me as 'the user'.
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
            
            prompt = f"""You are Typira, my personal assistant. I have triggered a specific action.
{time_context}MY HISTORY:
{history_block}

CURRENT CONTEXT: "{context}"
ACTION TRIGGERED: {action_id}
INSTRUCTION: "{payload}"

TASK:
Carry out the instruction precisely using my history for personalization. 
If the task is to 'Draft', 'Rewrite', 'Research', or 'Search', return the full resulting text or findings. 
Return the result in a JSON format.

OUTPUT FORMAT:
{{
  "thought": "Briefly explain what you did (e.g. 'I've synthesized a formal draft based on your typical style').",
  "result": "The actual text/data to be used/inserted."
}}

- Use 'I' and 'you' (me). NEVER refer to me as 'the user'."""

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
            print(f"Action Execution Error: {e}")
            return {"thought": "Error executing action.", "result": ""}

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

            prompt = f"""You are Typira, my personal assistant. I have triggered a specific action.
{time_context}{input_context}MY HISTORY:
{history_block}

ACTION TRIGGERED: {action_id}
INSTRUCTION: "{payload}"

TASK:
Carry out the instruction precisely using my history and any additional input provided for personalization. 

INSTRUCTIONS:
1. Formulate a multi-step 'Thought Process' describing your execution. Speak to me directly.
   - First, analyze the specific request and my provided context/history.
   - Second, plan the execution steps.
   - Third, VERIFY the result. Ensure all links are valid, grammar is perfect, and the tone matches my history.
   - IMPORTANT: When writing these 'thoughts', use natural language. Say "drafting the email", "checking the address", "verifying the tone", etc.
2. Provide a 'final_result'. This MUST be the complete, finished text or data.

CONSTRAINTS:
- DO NOT ASK ME ANY QUESTIONS.
- DO NOT ask for clarification.
- DO NOT request additional input.
- If you need more information (e.g., a name, a date, a location) and it wasn't provided, MAKE the most reasonable assumption based on my history or common sense and FINISH the task.
- The output in the "result" field must be a final, usable piece of content, not a draft with placeholders or questions.

OUTPUT FORMAT (Strict JSON):
{{
  "thoughts": [
      "I'm analyzing your request...", 
      "I'm drafting the response based on your previous style...", 
      "VERIFICATION: Checking for clarity and tone... Looks consistent.",
      "Finishing up the draft."
  ],
  "result": "The actual final text/data."
}}

- Use 'I' and 'you' (me). NEVER refer to me as 'the user'.
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
            print(f"Action Execution Error: {e}")
            return {"thoughts": ["Error executing action."], "result": ""}
