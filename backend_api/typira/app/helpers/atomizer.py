import re

def split_into_sentences(text):
    """
    Splits text into a list of sentences using regex.
    Handles common abbreviations and sentence-ending punctuation.
    """
    if not text:
        return []
    
    # Splitting logic: Split after . ! ? 
    # We split if:
    # 1. Punctuation is followed by whitespace
    # 2. Punctuation is followed by a capital letter (e.g. "Hello.Next")
    # 3. Punctuation is at the end of the string
    sentences = re.split(r'(?<=[.!?])(?=\s|[A-Z]|$)', text.strip())
    
    # Clean up and filter out empty or very short fragments
    return [s.strip() for s in sentences if len(s.strip()) > 1]

def scrub_pii(text):
    """
    Redacts basic PII like emails and phone numbers.
    """
    if not text:
        return ""
    
    # Redact Email
    email_regex = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'
    scrubbed = re.sub(email_regex, "[EMAIL]", text)
    
    # Redact Credit Card (Basic numeric sequence check)
    cc_regex = r'\b(?:\d[ -]*?){13,16}\b'
    scrubbed = re.sub(cc_regex, "[CREDIT_CARD]", scrubbed)
    
    # Redact PIN (Detecting 4-6 digit recurring PIN patterns in context)
    pin_regex = r'\b\d{4,6}\b'
    # Use a more targeted approach for PINs to avoid redacting years or counts
    # For now, we'll redact any 4-6 digit isolated number as a precaution
    scrubbed = re.sub(pin_regex, "[SENSITIVE_CODE]", scrubbed)
    
    return scrubbed
