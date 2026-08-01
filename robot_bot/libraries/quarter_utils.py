import re
from datetime import datetime


def normalize_quarter_value(value: str) -> str:
    """Normalize a quarter value to the format 'Qn YYYY'."""
    if value is None:
        return ""

    normalized = str(value).strip()
    if not normalized:
        return ""

    match = re.fullmatch(r"([Qq][1-4])(\s+(\d{4}))?", normalized)
    if not match:
        return normalized

    quarter = match.group(1).upper()
    year = match.group(3) or str(datetime.now().year)
    return f"{quarter} {year}"
