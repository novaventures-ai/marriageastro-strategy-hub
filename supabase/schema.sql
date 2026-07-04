-- ============================================================
--  DHAN STRATEGY ROUTER — Supabase Schema
--  Run this once in Supabase SQL Editor → New Query
-- ============================================================

-- 1. Daily market snapshots (one row per evening run)
CREATE TABLE IF NOT EXISTS market_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    snapshot_date   DATE        NOT NULL UNIQUE,
    -- India
    vix             NUMERIC(6,2),
    vix_chg_pct     NUMERIC(6,2),   -- % change vs prev close
    nifty           NUMERIC(8,2),
    nifty_chg_pct   NUMERIC(6,2),
    pcr             NUMERIC(5,3),
    ret_20d         NUMERIC(6,2),   -- 20-day return %
    dma_50          NUMERIC(8,2),
    above_dma50     BOOLEAN,
    regime          TEXT,           -- BULL / BEAR / SIDEWAYS / EXTREME
    -- Global
    sp500           NUMERIC(8,2),
    sp500_chg_pct   NUMERIC(6,2),
    nasdaq_chg_pct  NUMERIC(6,2),
    dxy             NUMERIC(6,2),   -- Dollar index
    crude_oil       NUMERIC(7,2),
    gold            NUMERIC(8,2),
    us_vix          NUMERIC(6,2),   -- CBOE VIX
    fear_greed      INTEGER,        -- 0-100 CNN Fear & Greed
    sgx_nifty       NUMERIC(8,2),   -- SGX Nifty (overnight signal)
    -- Meta
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Strategy scores + verdict (one row per evening run)
CREATE TABLE IF NOT EXISTS strategy_verdicts (
    id              BIGSERIAL PRIMARY KEY,
    verdict_date    DATE        NOT NULL UNIQUE,
    -- Scores (v2 engine)
    zen_score       INTEGER,
    curv_score      INTEGER,
    damp_score      INTEGER,
    -- Verdict
    winner          TEXT,           -- ZEN / CURVATURE / DAMPER / PAUSE
    verdict_text    TEXT,           -- e.g. "ACTIVATE ZEN CS"
    reason          TEXT,
    signal_strength TEXT,           -- ACTIVATE / LEAN / REGIME DEFAULT / PAUSE
    gap             INTEGER,        -- score gap between winner and runner-up
    regime          TEXT,
    -- Streak snapshot at time of verdict
    zen_streak      INTEGER,
    curv_streak     INTEGER,
    damp_streak     INTEGER,
    -- Did we follow it? (manual update next day)
    followed        BOOLEAN,
    actual_pnl      NUMERIC(10,2),  -- fill after trading day
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Monthly capital log (update manually each month-end)
CREATE TABLE IF NOT EXISTS capital_log (
    id              BIGSERIAL PRIMARY KEY,
    month           TEXT NOT NULL UNIQUE,  -- '2025-07'
    active_strategy TEXT,                  -- ZEN / CURVATURE / DAMPER
    regime          TEXT,
    trade_count     INTEGER,
    wins            INTEGER,
    losses          INTEGER,
    gross_pnl       NUMERIC(10,2),
    withdrawn_30pct NUMERIC(10,2),
    reinvested_70pct NUMERIC(10,2),
    portfolio_after NUMERIC(10,2),
    cum_withdrawn   NUMERIC(10,2),
    notes           TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Strategy momentum (updated nightly by scoring engine)
CREATE TABLE IF NOT EXISTS strategy_momentum (
    id              BIGSERIAL PRIMARY KEY,
    updated_date    DATE NOT NULL UNIQUE,
    zen_streak      INTEGER,
    zen_last5_wins  INTEGER,
    zen_total_pnl   NUMERIC(12,2),
    curv_streak     INTEGER,
    curv_last5_wins INTEGER,
    curv_total_pnl  NUMERIC(12,2),
    damp_streak     INTEGER,
    damp_last5_wins INTEGER,
    damp_total_pnl  NUMERIC(12,2),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Indexes ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_snapshots_date   ON market_snapshots(snapshot_date DESC);
CREATE INDEX IF NOT EXISTS idx_verdicts_date    ON strategy_verdicts(verdict_date DESC);
CREATE INDEX IF NOT EXISTS idx_capital_month    ON capital_log(month DESC);

-- ── Row Level Security (private — only your service key) ─────
ALTER TABLE market_snapshots    ENABLE ROW LEVEL SECURITY;
ALTER TABLE strategy_verdicts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE capital_log         ENABLE ROW LEVEL SECURITY;
ALTER TABLE strategy_momentum   ENABLE ROW LEVEL SECURITY;

-- Allow all operations via service_role key (used by GitHub Actions)
CREATE POLICY "service_role_all" ON market_snapshots  FOR ALL USING (true);
CREATE POLICY "service_role_all" ON strategy_verdicts FOR ALL USING (true);
CREATE POLICY "service_role_all" ON capital_log       FOR ALL USING (true);
CREATE POLICY "service_role_all" ON strategy_momentum FOR ALL USING (true);

-- ── Seed historical capital data (Jul 2025 – Jun 2026) ───────
INSERT INTO capital_log (month, active_strategy, regime, gross_pnl, withdrawn_30pct, reinvested_70pct, portfolio_after, cum_withdrawn) VALUES
('2025-07','ZEN','BULL',45100,13530,31570,131570,13530),
('2025-08','ZEN','SIDEWAYS',71500,21450,50050,181620,34980),
('2025-09','CURVATURE','BEAR',95800,28740,67060,248680,63720),
('2025-10','DAMPER','BULL',93200,27960,65240,313920,91680),
('2025-11','ZEN','SIDEWAYS',56100,16830,39270,353190,108510),
('2025-12','ZEN','SIDEWAYS',16200,4860,11340,364530,113370),
('2026-01','CURVATURE','BEAR',33300,9990,23310,387840,123360),
('2026-02','DAMPER','BULL',90900,27270,63630,451470,150630),
('2026-03','ZEN','SIDEWAYS',128600,38580,90020,541490,189210),
('2026-04','DAMPER','BULL',32900,9870,23030,564520,199080),
('2026-05','DAMPER','BULL',39300,11790,27510,592030,210870),
('2026-06','ZEN','SIDEWAYS',149700,44910,104790,696820,255780)
ON CONFLICT (month) DO NOTHING;
