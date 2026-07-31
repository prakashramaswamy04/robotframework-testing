"""
ai_xpath_finder.py

The one piece of this popup-handling setup that genuinely needs Python:
calling an AI API with the popup screenshot and getting back a suggested
xpath + category. Everything else (clicking, waiting, screenshots, JSON
read/write) lives in popup_keywords.resource as native Robot keywords.

Usage from Robot:
    Library    ./ai_xpath_finder.py

    ${category}    ${xpath}    ${confidence}    ${reasoning}=
    ...    Get Xpath Suggestion From AI    ${screenshot_path}    ${dom_path}
    ...    notes=Blocked checkout after clicking some-button

Requires:
    pip install requests
    (optional, recommended) pip install Pillow  -> shrinks the screenshot
    before sending it, since image cost scales with pixel count. Without
    Pillow, the full-size screenshot is sent as-is.
    An ANTHROPIC_API_KEY environment variable set (or pass api_key= directly).

COST NOTES (kept deliberately cheap):
  - Screenshot is downscaled to MAX_IMAGE_WIDTH px before sending — image
    tokens scale with pixel count, so this is the single biggest saver.
  - DOM snippet is stripped of <script>/<style> and whitespace, then capped
    at MAX_DOM_CHARS characters.
  - Prompt text is minimal, and max_tokens is capped since the reply is a
    tiny JSON object, not prose.
"""

import base64
import json
import mimetypes
import os
import re

import requests

from robot.api.deco import keyword, library

try:
    from PIL import Image
    import io
    _HAS_PIL = True
except ImportError:
    _HAS_PIL = False

ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
DEFAULT_MODEL = "claude-sonnet-5"

MAX_IMAGE_WIDTH = 800     # px — bigger just costs more tokens, rarely helps
MAX_DOM_CHARS = 1200      # chars of DOM sent, after cleanup
MAX_OUTPUT_TOKENS = 150   # reply is one small JSON object

# Short and cheap on purpose — every extra sentence here costs tokens on
# every single call. Keep instructions terse; the JSON shape does the work.
PROMPT_TEMPLATE = (
    "Find the button to dismiss this popup. Priority if multiple fit: "
    "cross(X) > no > close > yes.\n"
    "DOM snippet: {dom_snippet}\n"
    "Context: {notes}\n"
    'Reply with ONLY this JSON, nothing else: '
    '{{"category":"cross|no|close|yes","xpath":"...","confidence":"high|medium|low","reasoning":"<10 words"}}'
)


def _encode_image(screenshot_path):
    """Downscales the screenshot (if Pillow is available) before base64
    encoding, since image token cost scales with pixel count, not file size."""
    media_type, _ = mimetypes.guess_type(screenshot_path)

    if not _HAS_PIL:
        if media_type is None:
            media_type = "image/png"
        with open(screenshot_path, "rb") as f:
            return media_type, base64.standard_b64encode(f.read()).decode("utf-8")

    with Image.open(screenshot_path) as img:
        img = img.convert("RGB")
        if img.width > MAX_IMAGE_WIDTH:
            new_height = int(img.height * (MAX_IMAGE_WIDTH / img.width))
            img = img.resize((MAX_IMAGE_WIDTH, new_height), Image.LANCZOS)
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=60)  # jpeg+lower quality = smaller payload
        encoded = base64.standard_b64encode(buf.getvalue()).decode("utf-8")

    return "image/jpeg", encoded


def _load_dom_snippet(dom_path, max_chars=MAX_DOM_CHARS):
    if not dom_path or not os.path.exists(dom_path):
        return "(none)"
    with open(dom_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # Strip script/style blocks and collapse whitespace — these add lots of
    # tokens and almost never help identify a close/no/close/yes button.
    content = re.sub(r"<script.*?</script>", "", content, flags=re.S | re.I)
    content = re.sub(r"<style.*?</style>", "", content, flags=re.S | re.I)
    content = re.sub(r"\s+", " ", content).strip()

    if len(content) > max_chars:
        content = content[:max_chars] + "...(truncated)"
    return content


def get_ai_xpath_suggestion(
    screenshot_path,
    dom_path=None,
    notes="",
    api_key=None,
    model=DEFAULT_MODEL,
    timeout=60,
):
    """Calls the Anthropic API with the (downscaled) popup screenshot and
    returns a dict: {"category", "xpath", "confidence", "reasoning"}, or a
    dict with an "error" key if the call/parse failed.

    Plain Python function (no Robot dependency) so it can also be unit
    tested or reused outside Robot Framework.
    """
    api_key = api_key or os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        return {"error": "No API key provided (set ANTHROPIC_API_KEY or pass api_key=)."}

    if not os.path.exists(screenshot_path):
        return {"error": f"Screenshot not found: {screenshot_path}"}

    media_type, image_b64 = _encode_image(screenshot_path)
    dom_snippet = _load_dom_snippet(dom_path)
    prompt = PROMPT_TEMPLATE.format(dom_snippet=dom_snippet, notes=notes or "none")

    payload = {
        "model": model,
        "max_tokens": MAX_OUTPUT_TOKENS,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {"type": "base64", "media_type": media_type, "data": image_b64},
                    },
                    {"type": "text", "text": prompt},
                ],
            }
        ],
    }

    headers = {
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }

    try:
        response = requests.post(ANTHROPIC_API_URL, headers=headers, json=payload, timeout=timeout)
        response.raise_for_status()
    except requests.RequestException as exc:
        return {"error": f"API request failed: {exc}"}

    try:
        data = response.json()
        text_blocks = [b["text"] for b in data.get("content", []) if b.get("type") == "text"]
        raw_text = "\n".join(text_blocks).strip()

        if raw_text.startswith("```"):
            raw_text = raw_text.strip("`")
            if raw_text.lower().startswith("json"):
                raw_text = raw_text[4:].strip()

        suggestion = json.loads(raw_text)
    except (ValueError, KeyError, json.JSONDecodeError) as exc:
        return {"error": f"Could not parse AI response: {exc}", "raw_response": response.text}

    for field in ("category", "xpath"):
        if field not in suggestion:
            return {"error": f"AI response missing '{field}' field", "raw_response": raw_text}

    suggestion.setdefault("confidence", "unknown")
    suggestion.setdefault("reasoning", "")
    return suggestion


@library
class ai_xpath_finder:
    """Thin Robot Framework wrapper around get_ai_xpath_suggestion()."""

    @keyword("Get Xpath Suggestion From AI")
    def get_xpath_suggestion_from_ai(self, screenshot_path, dom_path=None, notes="", model=DEFAULT_MODEL):
        """Sends the given screenshot (and optional DOM snippet) to the AI
        and returns four values: category, xpath, confidence, reasoning.

        On failure, category and xpath are returned as empty strings and
        the error message is put in `reasoning` — check confidence == "error"
        to detect this in your test.
        """
        result = get_ai_xpath_suggestion(
            screenshot_path=screenshot_path, dom_path=dom_path, notes=notes, model=model
        )

        if "error" in result:
            return "", "", "error", result["error"]

        return result["category"], result["xpath"], result["confidence"], result["reasoning"]
