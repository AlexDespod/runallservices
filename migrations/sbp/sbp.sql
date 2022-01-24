CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS sbp;

-- skill balance pots (classic)
-- stores the SBP for games that utilize this feature
-- currently we're segmenting by game, by currency, and by wager-level
CREATE TABLE IF NOT EXISTS sbp.skillbalancepots
(
    gameid   UUID    NOT NULL,
    currency CHAR(3) NOT NULL,
    level    BIGINT  NOT NULL,
    pot      BIGINT  NOT NULL default 0,
    PRIMARY KEY (gameid, currency, level)
);
CREATE INDEX IF NOT EXISTS idx_skillbalancepots_wagerlevels ON sbp.skillbalancepots (gameid, currency);

CREATE TYPE sbp.txreason AS ENUM ('reserved', 'forfeit', 'refunded');

-- skill balance pot transaction ledger, we simply record money-in and money-out
-- positive is deposit (for forfeit & refund reasons)
-- negative is withdrawl (for reserved reason)
CREATE TABLE IF NOT EXISTS sbp.transactions
(
    id         UUID PRIMARY KEY      DEFAULT uuid_generate_v4(), -- unique ID of transaction
    externalid UUID         NOT NULL,                            -- an external reference related to this sbp transaction (e.g. wager_id)
    amount     BIGINT       NOT NULL,                            -- neg = withdrawl, pos = deposit
    created    TIMESTAMPTZ  NOT NULL DEFAULT now(),              -- when the transaction occurred
    reason     sbp.txreason NOT NULL                             -- reason why this transaction occurred
);
CREATE INDEX IF NOT EXISTS idx_sbptransactions_wagerid ON sbp.transactions (externalid);