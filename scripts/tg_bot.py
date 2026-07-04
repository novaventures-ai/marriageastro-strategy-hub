#!/usr/bin/env python3
"""
tg_bot.py — Telegram command poller
Runs every 5 min via GitHub Actions.
Supported commands:
  /analyze  — runs full nightly analysis and sends report
  /status   — confirms bot is alive
"""
import os, sys, datetime, subprocess, requests

TG_TOKEN   = os.environ["TELEGRAM_BOT_TOKEN"]
TG_CHAT_ID = str(os.environ["TELEGRAM_CHAT_ID"])
BASE_URL   = f"https://api.telegram.org/bot{TG_TOKEN}"

WINDOW_SEC = 310   # only respond to commands < 5m10s old (cron fires every 5m)


def tg_get(method, **params):
    r = requests.get(f"{BASE_URL}/{method}", params=params, timeout=15)
    return r.json()


def tg_send(text):
    requests.post(
        f"{BASE_URL}/sendMessage",
        json={"chat_id": TG_CHAT_ID, "text": text, "parse_mode": "HTML"},
        timeout=15,
    )


def main():
    now_utc = datetime.datetime.utcnow()

    # Fetch last 20 updates (no offset needed — we filter by age)
    data    = tg_get("getUpdates", limit=20, offset=-20)
    updates = data.get("result", [])

    for upd in reversed(updates):          # newest first
        msg     = upd.get("message", {})
        text    = msg.get("text", "").strip()
        chat_id = str(msg.get("chat", {}).get("id", ""))
        date    = msg.get("date", 0)
        age_sec = (now_utc - datetime.datetime.utcfromtimestamp(date)).total_seconds()

        # Only handle messages from the owner chat within the window
        if chat_id != TG_CHAT_ID:
            continue
        if age_sec > WINDOW_SEC:
            break   # older updates won't be relevant either (list is sorted)

        cmd = text.split()[0].lower() if text else ""

        if cmd == "/analyze":
            tg_send("⏳ <b>Running analysis…</b> Full report in ~30s")
            script_dir  = os.path.dirname(os.path.abspath(__file__))
            engine_path = os.path.join(script_dir, "nightly_engine.py")
            proc = subprocess.run(
                [sys.executable, engine_path],
                capture_output=True, text=True, timeout=180,
            )
            if proc.returncode != 0:
                tg_send(f"⚠️ Engine error:\n<pre>{proc.stderr[-600:]}</pre>")
            # nightly_engine sends its own Telegram message on success
            break

        elif cmd == "/status":
            tg_send(
                "✅ <b>Dhan Router Bot is live</b>\n"
                "Commands:\n"
                "  /analyze — run full market analysis now\n"
                "  /status  — check bot health"
            )
            break


if __name__ == "__main__":
    main()
