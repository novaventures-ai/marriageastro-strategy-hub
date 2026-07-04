# Dhan Strategy Router — Cloud Setup Guide
## From zero to live in ~1 hour

---

## STEP 1 — Supabase (10 min)

1. Go to https://supabase.com → New project
2. Name it `dhan-router`, pick a strong DB password, region = **Singapore** (closest to India)
3. Once created → **SQL Editor** → New Query → paste entire `supabase/schema.sql` → Run
4. Go to **Project Settings → API**:
   - Copy **Project URL** → save as `SUPABASE_URL`
   - Copy **service_role** key (secret) → save as `SUPABASE_SERVICE_KEY`
   - Copy **anon public** key → save as `SUPABASE_ANON_KEY`

---

## STEP 2 — Telegram Bot (5 min)

1. Open Telegram → search `@BotFather`
2. Send `/newbot` → give it a name like `DhanRouterBot`
3. BotFather gives you a **token** like `1234567890:AAFxxxxxx` → save as `TELEGRAM_BOT_TOKEN`
4. Start a chat with your new bot (send it `/start`)
5. Open browser: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
6. Find `"chat":{"id":XXXXXXX}` → that number is your `TELEGRAM_CHAT_ID`

---

## STEP 3 — GitHub Repository (10 min)

1. Go to https://github.com → New repository → name it `dhan-router` → Private
2. Upload these files keeping the folder structure:
   ```
   scripts/nightly_engine.py
   .github/workflows/nightly.yml
   web/index.html
   supabase/schema.sql
   ```
3. Go to repo **Settings → Secrets and variables → Actions → New repository secret**
   Add all 4 secrets:
   - `SUPABASE_URL`         → your Supabase project URL
   - `SUPABASE_SERVICE_KEY` → Supabase service_role key
   - `TELEGRAM_BOT_TOKEN`  → from BotFather
   - `TELEGRAM_CHAT_ID`    → your chat ID number

4. **Test it manually**: Go to **Actions tab** → `Nightly Strategy Engine` → `Run workflow`
   - Watch the logs — should see: market data fetched → Supabase saved → Telegram sent ✓
   - Check your Telegram — you should get the verdict message!

---

## STEP 4 — Vercel Web App (15 min)

1. Open `web/index.html` and fill in the 3 values near the top:
   ```js
   const SUPABASE_URL = 'https://xxxxx.supabase.co';   // your URL
   const SUPABASE_ANON_KEY = 'eyJhbGc...';             // anon key (NOT service key)
   const APP_PASSWORD = 'choose-a-strong-password';     // your login password
   ```

2. Go to https://vercel.com → New Project → Import your GitHub repo `dhan-router`
   - Framework: **Other** (it's just HTML)
   - Root directory: `web`
   - Click Deploy

3. Vercel gives you a URL like `https://dhan-router-xyz.vercel.app`
   - Optional: Add a custom domain in Vercel settings (e.g. `algo.yourdomain.in`)

4. Open the URL on your phone — enter your password — dashboard loads! ✓

---

## STEP 5 — Update Momentum Data (2 min, once a month)

After each month ends, update the strategy momentum in Supabase:

1. Go to Supabase → **Table Editor** → `strategy_momentum`
2. Insert a row with today's date + latest streaks from `strategy_momentum.json` on your PC:
   ```
   updated_date:    2026-07-01
   zen_streak:      4   (from strategy_momentum.json)
   zen_last5_wins:  4
   zen_total_pnl:   672917
   curv_streak:     -2
   curv_last5_wins: 1
   curv_total_pnl:  595498
   damp_streak:     -1
   damp_last5_wins: 3
   damp_total_pnl:  414673
   ```
   (Or sync this automatically — the nightly engine will do it once Dhan API momentum scraping is added)

---

## STEP 6 — Update Capital Log (2 min, each month-end)

1. Go to Supabase → **Table Editor** → `capital_log`
2. Insert the month's P&L row (same format as the seeded historical data)
3. The web app capital chart updates automatically

---

## Telegram message you'll receive every evening at 9:30 PM:

```
🤖 Dhan Strategy Router — 2026-06-27

✅ ACTIVATE ZEN CS
Zen leads by 10 pts (Zen=10 Curv=0 Damp=0). Strong signal.

📊 Scores:  Zen 10  |  Curv 0  |  Damp 0
📈 Streaks: Zen +4  |  Curv -2  |  Damp -1

🟡 Regime: SIDEWAYS  (20d +1.2%)
🇮🇳 India:  VIX 13.05 (-8.2%)  |  Nifty 24,850 (+0.4%)  |  PCR 1.05
🌍 Global:  S&P500 +0.3%  |  DXY 104.2  |  Crude 78.5  |  F&G 62

👉 Action:  ⏸ PAUSE Curv + Damp  →  ▶ Keep ZEN CS active
⏰ Orders fire 4:45 AM — do this before sleeping!
```

---

## Monthly cost: Rs.0
- Vercel hobby: Free
- Supabase free tier: 500 MB, plenty for years of data
- GitHub Actions: 2000 free minutes/month (you'll use ~150 min/month)
- Telegram bot: Free forever
