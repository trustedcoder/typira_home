import hashlib
from app.business.gemini_business import GeminiBusiness

def get_semantic_hash(sentence):
    """
    Returns a SHA-256 hash of the canonical intent of the sentence.
    """
    if not sentence:
        return None
    
    canonical = GeminiBusiness.canonicalize_sentence(sentence)
    if not canonical:
        return None
        
    return hashlib.sha256(canonical.encode('utf-8')).hexdigest()
