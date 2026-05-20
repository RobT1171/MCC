-- =============================================
-- MONEY CHEAT CODES — D1 DATABASE SCHEMA
-- Deploy to Cloudflare D1
-- =============================================

-- PARENTS (the commander accounts)
-- Linked to GHL contacts. One parent can have up to 4 kids.
CREATE TABLE IF NOT EXISTS parents (
  id TEXT PRIMARY KEY,
  ghl_contact_id TEXT,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  plan TEXT NOT NULL DEFAULT 'free',
  referral_code TEXT UNIQUE,
  referred_by TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- CHILDREN (the agents)
-- Each kid has a profile with their codename, stats, and business.
CREATE TABLE IF NOT EXISTS children (
  id TEXT PRIMARY KEY,
  parent_id TEXT NOT NULL REFERENCES parents(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  agent_name TEXT NOT NULL,
  age INTEGER NOT NULL DEFAULT 10,
  avatar INTEGER NOT NULL DEFAULT 0,
  xp INTEGER NOT NULL DEFAULT 0,
  coins INTEGER NOT NULL DEFAULT 0,
  rank INTEGER NOT NULL DEFAULT 0,
  current_mission INTEGER NOT NULL DEFAULT 1,
  streak INTEGER NOT NULL DEFAULT 0,
  last_active_date TEXT,
  business_id TEXT,
  business_revenue REAL NOT NULL DEFAULT 0,
  business_costs REAL NOT NULL DEFAULT 0,
  savings REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Index for fast parent lookups
CREATE INDEX IF NOT EXISTS idx_children_parent ON children(parent_id);

-- TRANSACTIONS (income, expenses, savings)
-- Every dollar logged by a kid goes here. This powers the $100 tracker.
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  amount REAL NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('income', 'expense', 'savings')),
  description TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Index for pulling a kid's transaction history
CREATE INDEX IF NOT EXISTS idx_transactions_child ON transactions(child_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(created_at);

-- MISSION COMPLETIONS
-- Tracks which missions each kid has finished and their quiz scores.
CREATE TABLE IF NOT EXISTS mission_completions (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  mission_id INTEGER NOT NULL,
  quiz_score INTEGER,
  completed_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(child_id, mission_id)
);

CREATE INDEX IF NOT EXISTS idx_missions_child ON mission_completions(child_id);

-- BADGE AWARDS
-- Every badge a kid earns gets a row here.
CREATE TABLE IF NOT EXISTS badge_awards (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  badge_id TEXT NOT NULL,
  awarded_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(child_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_badges_child ON badge_awards(child_id);

-- DAILY COMPLETIONS
-- Tracks which daily challenges a kid completed on which day.
-- Resets daily — the UNIQUE constraint prevents double-completion.
CREATE TABLE IF NOT EXISTS daily_completions (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  task_id TEXT NOT NULL,
  date TEXT NOT NULL,
  data TEXT,
  completed_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(child_id, task_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_child_date ON daily_completions(child_id, date);

-- AI CONVERSATIONS
-- Chat history between each kid and their spy handler AI coach.
-- Stored so the AI has context across sessions.
CREATE TABLE IF NOT EXISTS ai_conversations (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_ai_child ON ai_conversations(child_id);

-- AI USAGE (rate limiting for free users)
-- Tracks how many AI messages a kid has sent today.
-- Free plan = 5/day, Paid = unlimited.
CREATE TABLE IF NOT EXISTS ai_usage (
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  message_count INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (child_id, date)
);

-- REFERRALS
-- Tracks affiliate relationships between parents.
CREATE TABLE IF NOT EXISTS referrals (
  id TEXT PRIMARY KEY,
  referrer_id TEXT NOT NULL REFERENCES parents(id),
  referred_id TEXT NOT NULL REFERENCES parents(id),
  status TEXT NOT NULL DEFAULT 'signed_up' CHECK(status IN ('signed_up', 'subscribed', 'active', 'cancelled')),
  commission_rate REAL NOT NULL DEFAULT 0.30,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
