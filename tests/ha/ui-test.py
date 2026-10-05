"""Browser test for an add-on's web UI through Home Assistant ingress.

Runs inside the Playwright container on the test HA's network (see
ui-test.sh). Logs in through HA's login flow, hands the tokens to the
frontend the way it stores them itself, opens the add-on's ingress page and
checks that the add-on's own UI loads inside the ingress iframe.

Prints one JSON line with the result; the screenshot comes back base64-encoded
because the caller can't share a directory with this container.

    python - <slug> <expected-text> [<user> <password>]   (script on stdin)
"""

import base64
import json
import sys
import time
import urllib.parse
import urllib.request

from playwright.sync_api import TimeoutError as PlaywrightTimeout
from playwright.sync_api import sync_playwright

BASE = "http://localhost"
CLIENT_ID = f"{BASE}/"

slug, expected = sys.argv[1], sys.argv[2]
user = sys.argv[3] if len(sys.argv) > 3 else "test"
password = sys.argv[4] if len(sys.argv) > 4 else "test-bench-only"


def post(path, data, form=False):
    body = urllib.parse.urlencode(data).encode() if form else json.dumps(data).encode()
    headers = {"Content-Type": "application/x-www-form-urlencoded" if form else "application/json"}
    req = urllib.request.Request(BASE + path, data=body, headers=headers, method="POST")
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def login():
    flow = post(
        "/auth/login_flow",
        {"client_id": CLIENT_ID, "handler": ["homeassistant", None], "redirect_uri": f"{CLIENT_ID}?auth_callback=1"},
    )
    step = post(f"/auth/login_flow/{flow['flow_id']}", {"username": user, "password": password, "client_id": CLIENT_ID})
    if step.get("type") != "create_entry":
        raise SystemExit(f"login failed: {step.get('errors') or step}")
    tokens = post("/auth/token", {"grant_type": "authorization_code", "code": step["result"], "client_id": CLIENT_ID}, form=True)
    # The shape the frontend keeps in localStorage["hassTokens"].
    tokens.update(hassUrl=BASE, clientId=CLIENT_ID, expires=int(time.time() * 1000) + tokens["expires_in"] * 1000)
    return tokens


result = {"slug": slug, "expected": expected, "ok": False}
tokens = login()

with sync_playwright() as pw:
    browser = pw.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 800})
    # Any same-origin page that doesn't redirect: "/" sends the frontend to
    # /home/... and the write would race that navigation.
    page.goto(BASE + "/manifest.json")
    page.evaluate("t => localStorage.setItem('hassTokens', JSON.stringify(t))", tokens)

    # The frontend panel was renamed with add-ons -> apps: the old
    # /hassio/ingress/<slug> route is a 404 now.
    url = f"{BASE}/app/{slug}/ingress"
    page.goto(url)
    result["page_url"] = page.url
    try:
        # The ingress iframe lives in the frontend's shadow DOM; Playwright's
        # CSS engine pierces it.
        iframe = page.wait_for_selector("iframe[src*='/api/hassio_ingress/']", timeout=60_000)
        # The element can exist before its frame has navigated: take the frame
        # from the element and wait for the ingress URL instead of searching
        # page.frames, which could still miss it.
        frame = iframe.content_frame()
        if frame is None:
            raise PlaywrightTimeout("ingress iframe has no frame")
        frame.wait_for_url("**/api/hassio_ingress/**", timeout=60_000)
        frame.wait_for_load_state("load", timeout=60_000)
        frame.wait_for_function(
            "e => document.body && document.body.innerText.includes(e) || document.title.includes(e)",
            arg=expected,
            timeout=60_000,
        )
        result.update(ok=True, frame_url=frame.url, frame_title=frame.title())
    except PlaywrightTimeout as err:
        result["error"] = f"{type(err).__name__}: {str(err).splitlines()[0][:300]}"
        result["frames"] = [f.url for f in page.frames]
    page.wait_for_timeout(1_500)
    result["screenshot_png_b64"] = base64.b64encode(page.screenshot()).decode()
    browser.close()

print(json.dumps(result))
