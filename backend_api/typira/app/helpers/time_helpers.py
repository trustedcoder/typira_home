import datetime

def get_time_ago(dt):
    now = datetime.datetime.utcnow()
    diff = now - dt
    
    seconds = diff.total_seconds()
    if seconds < 60:
        return "just now"
    
    minutes = seconds // 60
    if minutes < 60:
        return f"{int(minutes)}m ago"
    
    hours = minutes // 60
    if hours < 24:
        return f"{int(hours)}h ago"
    
    days = hours // 24
    if days < 30:
        return f"{int(days)}d ago"
    
    months = days // 30
    if months < 12:
        return f"{int(months)}mo ago"
    
    years = months // 12
    return f"{int(years)}y ago"
