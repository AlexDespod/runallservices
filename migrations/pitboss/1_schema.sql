-- pitobss core database

-- integrations (aka wallet systems: hub88, relax, ...)
CREATE TABLE IF NOT EXISTS integrations (
    id              UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    label           TEXT    UNIQUE NOT NULL,
    notes           TEXT    NOT NULL DEFAULT ''
);

-- operators (aka casinos: Redbet, MrGreen, ...)
-- operators belong to an integration
CREATE TABLE IF NOT EXISTS operators (
    id                          UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    label                       TEXT    NOT NULL DEFAULT '',
    integrationoperatorid       TEXT    NOT NULL DEFAULT '',
    integrationoperatorsubid    TEXT    NOT NULL DEFAULT '',
    integrationname             TEXT    REFERENCES integrations(label) NOT NULL,
    maxexposure                 BIGINT,
    notes                       TEXT    NOT NULL DEFAULT '',
    bonusenabled                BOOLEAN default TRUE,
    bonuslimit                  BIGINT,
    betlimit                    BIGINT,
    ukgcheader                  INT     DEFAULT 0,
    UNIQUE (integrationoperatorid, integrationoperatorsubid, integrationname)
);
CREATE INDEX IF NOT EXISTS idx_operators_integrationoperatorids on operators (integrationoperatorid, integrationoperatorsubid);

-- all "users" which are just an association between our UUID and an operator's "username"
-- this is our user ID, which is guaranteed unique for this pitboss instance, even across operators
-- users belong to an operator which belongs to an integration
CREATE TABLE IF NOT EXISTS users (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    operatorid      UUID        REFERENCES operators(id) NOT NULL,
    username        TEXT        NOT NULL,
    created         TIMESTAMPTZ DEFAULT now(),
    UNIQUE (operatorid, username)
);
CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);

-- A table who stores rng data
CREATE TABLE IF NOT EXISTS rngs
(
    certification_id TEXT PRIMARY KEY,
    software_id      TEXT,
    version          TEXT
);

-- this type defines all possible values for "category_type" columns
CREATE TYPE category_type AS ENUM ('Arcade', 'Slot', 'Table', '');
-- this type defines all possible values for "category_subtype" columns
CREATE TYPE category_subtype AS ENUM ('KO Slot', 'Blackjack', 'Baccarat', 'Puntobanco', 'Roulette', '');

-- a unique id for a given game archetype (eg: spoilsofwar, candywall, hammeroffortune, ...)
-- wagersetid           the associated set of reasonable wagers for this game
-- currencysetid        the associated set of valid currencies for this game
-- defaultwager         what should be offered as the default wager for a new player
-- gcd                  defines the bet divisor required by this game (e.g. 25 means you can bet in multiples of 25)
-- maxwinmultiplier     defines the maximum win multiplier possible for a given game (some games have no upper limit) - used by exposure limits
-- bufferpayouts        true if this game works well with buffering all payout requests to the wallet system
-- uniquepayouts       true if that this game will always use unique payout reasons (within the scope of a single wager)
-- multiwager           true if this game supports more than one wager open at the time
-- allowanybet          true if this game allows wagers that aren't specified in the associated wagerset (but they still must conform to limits)
-- forceclientmetrics   true if this game needs to use the cached clientmetrics even if the environment default is not to (e.g. on dev)
CREATE TABLE IF NOT EXISTS rulesets
(
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    label              TEXT    NOT NULL,
    title              TEXT    NOT NULL DEFAULT '',
    notes              TEXT    NOT NULL DEFAULT '',
    wagersetid         TEXT    NOT NULL DEFAULT '',
    currencysetid      TEXT    NOT NULL DEFAULT '',
    gcd                INT     NOT NULL DEFAULT 1,
    defaultwager       BIGINT  NOT NULL DEFAULT 100,
    betlimit           BIGINT           DEFAULT 2500,
    maxwinmultiplier   INT,
    bufferpayouts      BOOLEAN NOT NULL DEFAULT FALSE,
    uniquepayouts      BOOLEAN NOT NULL DEFAULT FALSE,
    multiwager         BOOLEAN NOT NULL DEFAULT FALSE,
    allowanybet        BOOLEAN NOT NULL DEFAULT FALSE,
    forceclientmetrics BOOLEAN NOT NULL DEFAULT FALSE,
    bonussetid         TEXT,
    categorytype       category_type NOT NULL DEFAULT '',
    categorysubtype    category_subtype NOT NULL DEFAULT '',
    rng                TEXT REFERENCES rngs (certification_id),

    UNIQUE (label)
);

-- set of base wager levels
-- used by freespins to convert an offer into a valid set of wagers
-- used by wagerlevels endpoint to retrieve wager levels for a given game + currency
CREATE TABLE wagersets (
    id              TEXT        NOT NULL,
    wagerlevel      BIGINT      NOT NULL,
    notes           TEXT        NOT NULL DEFAULT '',

    PRIMARY KEY (id, wagerlevel)
);
CREATE INDEX IF NOT EXISTS idx_wagersets_id ON wagersets(id);

-- game instances
-- this id is the "gameid" that a specific game server uses when communicating to its pitboss for all wallet transactions
-- it indicates a specific operator (casino), integration (wallet system), and ruleset (game archetype)
-- every instance of a game that gets spun up must have a unique gameid that associates it to this unique set of relationships)
CREATE TABLE IF NOT EXISTS games (
    id              UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    integrationid   UUID    REFERENCES integrations(id) NOT NULL,
    rulesetid       UUID    REFERENCES rulesets(id) NOT NULL,
    label           TEXT    NOT NULL,
    notes           TEXT    NOT NULL DEFAULT '',

    UNIQUE (integrationid, rulesetid)    -- we don't want two different game IDs for a single relationship of elements
);

-- WAGER TYPES
CREATE TYPE wagertype AS ENUM ('WAGER', 'BONUS', 'SPEED');

-- all wagers
CREATE TABLE IF NOT EXISTS wagers
(
    id            UUID PRIMARY KEY                    DEFAULT uuid_generate_v4(), -- pitboss wager ID
    iwagerid      TEXT                       NOT NULL,                            -- wallet wager ID
    userid        UUID REFERENCES users (id) NOT NULL,                            -- pitboss user ID
    gameid        UUID REFERENCES games (id) NOT NULL,                            -- pitboss game ID
    transactionid TEXT,                                                           -- wallet transaction ID.  Note this can be null for old entries, and for integrations that don't have transaction ids
    isessionid    TEXT,                                                           -- wallet session ID used to execute this wager
    amount        BIGINT,                                                         -- sum wagered
    currency      CHAR(3),                                                        -- currency
    freespinid    UUID,                                                           -- PFR ID (if any)
    historyid     UUID,                                                           -- parent wager ID (if any)
    sbpreserved   BIGINT,                                                         -- SBP reserved (if any)
    sbplevel      BIGINT,                                                         -- SBP wagerlevel this was reserved from
    sbpforfeit    BIGINT,                                                         -- SBP forfeit from unaccomplished winnings (can only do this once / wager)
    opentime      TIMESTAMPTZ                NOT NULL DEFAULT now(),              -- when created
    closetime     TIMESTAMPTZ,                                                    -- when closed (null when open)
    openbalance   BIGINT,                                                         -- player balance when round was created
    closebalance  BIGINT,                                                         -- player balance when round was closed (paid out)
    jurisdiction  CHAR(2),                                                        -- jurisdiction of the wager
    groupid       UUID,                                                           -- identifier for grouping similar type of wagers
    type          wagertype                  NOT NULL DEFAULT 'WAGER'             -- wager type (wager, speed, bonus)
);
CREATE INDEX IF NOT EXISTS idx_wagers_userid ON wagers(userid);
CREATE INDEX IF NOT EXISTS idx_wagers_gameid ON wagers(gameid);
CREATE INDEX IF NOT EXISTS idx_wagers_closetime ON wagers(closetime);
CREATE INDEX IF NOT EXISTS idx_wagers_iwagerid ON wagers (iwagerid);

-- all payouts
--  paytype TEXT NOT NULL, removed SSW - we literally don't use this ever
CREATE TABLE IF NOT EXISTS payouts (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    wagerid         UUID        REFERENCES wagers(id) NOT NULL,
    transactionid   TEXT,                                               -- wallet transaction ID.  note this can be null for old entries, for non-final payouts (if buffered) and for integrations that don't have transaction ids
    isessionid      TEXT,                                               -- wallet session ID used to execute this wager
    amount          BIGINT      NOT NULL,
    reason          TEXT        NOT NULL,
    executed        BOOLEAN     NOT NULL,
    final           BOOLEAN     NOT NULL,
    created         TIMESTAMPTZ NOT NULL DEFAULT now(),
    lastupdated     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payouts_wagerid ON payouts(wagerid);

-- active wager and idempotent state of each game
-- token            idempotent token for this game-user-state
-- activewager      the active wager (or NULL)
-- freespinid       the active freespin ID in use for this wager (or NULL)
CREATE TABLE IF NOT EXISTS gamestates (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    userid      UUID        REFERENCES users(id) NOT NULL,
    gameid      UUID        REFERENCES games(id) NOT NULL,
    token       UUID        DEFAULT uuid_generate_v4() NOT NULL,
    activewager UUID        REFERENCES wagers(id),

    UNIQUE (userid, gameid)
);

-- currency sets
-- used in conjunction with validwagers, and needed by freespins to convert an offer into a valid set of wagers for a given game (c.f. betlimits)
-- 'multiplier' is for wager levels
--    e.g. 100 means that you'd offer the player to bet 100x each standard wager level for that game
--     e.g. if a game's default wager levels are 25, 50, 100, 250; for a 10x multiplier, that game would offer the player to wager 250, 500, 1000, 2500 of their currency
-- 'coinratio' is for currency to GJG coins (e.g. 10 means 10 cents per coin)
--     e.g. when displaying an amount of 100 of a currency that has a 10 coinratio, you'd display it as 10 coins.
-- !! IMPORTANT !!
--     If you're offering the player to wager an amount in their chosen currency: use mulitiplier to determine appropriate bet levels.
--     If you're displaying an amount of money in terms of coins: use coinratio.
--    This means if you're display a list of bet levels to choose from in terms of coins, you apply both ratios (the actual amount is from multiplier, and the displayed coins applies the coinratio)
--     e.g. if a game's default wager levels are 25, 50, 100, 250; for a 10x mulitiplier and a 10x coin ratio, those would offset when displaying the bets in terms of coins.
-- NOTE: coins is a display issue only!  DO NOT EVER STORE MONEY AMOUNTS IN TERMS OF COINS!
-- NOTE: similarly, multiplier is only for determining appropriate bet levels - you still store the actual value in terms of real currency amounts!
-- id is the name of the set -- please keep it very short and simple - like 'spoilsofwar' or 'hammeroffortune' or 'gjg-2020' & etc.  Human readable, but MUST BE CONSISTENT to tie currency multipliers together into one set!
CREATE TABLE IF NOT EXISTS currencysets (
    id          TEXT        NOT NULL,
    currency    CHAR(3)     NOT NULL,
    multiplier  INTEGER     NOT NULL DEFAULT '1',
    coinratio   INTEGER     NOT NULL DEFAULT '1',
    notes       TEXT        NOT NULL DEFAULT '',

    PRIMARY KEY (id, currency)
);
CREATE INDEX IF NOT EXISTS idx_currencysets_id ON currencysets(id);

-- history
-- simple store of a json blob defined by the game servers themselves, plus a version tag so that we can corrrleate which version of this history data structure to use (if needed)
-- corresponds to a wager always
CREATE TABLE IF NOT EXISTS history (
	id 	        UUID        PRIMARY KEY REFERENCES wagers(id),
	version	    SMALLINT    NOT NULL,
	result      JSONB       NOT NULL
);

-- skill balance pots (classic)
-- stores the SBP for games that utilize this feature (through pitboss)
-- currently we're segmenting by game, by currency, and by wager-level
-- we can consider migrating data amongst pots using various algorithms at some point
-- in order to migrate towards well used wager-levels or currencies
CREATE TABLE IF NOT EXISTS skillbalancepots (
    gameid      UUID        REFERENCES games(id) NOT NULL,
    currency    CHAR(3)     NOT NULL,
    wagerlevel  BIGINT      NOT NULL,
    pot         BIGINT      NOT NULL default 0,

    PRIMARY KEY (gameid, currency, wagerlevel)
);
CREATE INDEX IF NOT EXISTS idx_skillbalancepots_wagerlevels ON skillbalancepots(gameid,currency);

-- trivial sbptransactions.reasons lookup table
CREATE TABLE IF NOT EXISTS sbptxreasons (
    id          SMALLINT    PRIMARY KEY,
    label       TEXT        NOT NULL
);
INSERT INTO sbptxreasons VALUES (1, 'reserved') ON CONFLICT DO NOTHING;
INSERT INTO sbptxreasons VALUES (2, 'forfeit')  ON CONFLICT DO NOTHING;
INSERT INTO sbptxreasons VALUES (3, 'refunded') ON CONFLICT DO NOTHING;

-- skill balance pot transaction ledger
-- we simply record money-in and money-out
--  positive is deposit (aka forfeit - since this is always money forfeited from their potential winnings)
--  negative is withdrawl
-- wagers has the wagerlevel and currency (i.e. which pot this is associated to)
-- note: these come from:
--   wager/rsvp   (sbppercent) (-)
--   rsvp/payout  (forfeit)    (+)
--   payout "sbp" (refund)     (+)
--  refund = payout "sbp" < sbpreserved
--  forfeit = total RNG win < total RNG award due to player's skill
CREATE TABLE IF NOT EXISTS sbptransactions (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(), -- unique ID of transaction
    wagerid     UUID        REFERENCES wagers(id) NOT NULL,         -- the wager this occurred through
    amount      BIGINT      NOT NULL,                               -- neg = withdrawl, pos = deposit
    created     TIMESTAMPTZ NOT NULL DEFAULT now(),                 -- when the transaction occurred
    reason      SMALLINT    REFERENCES sbptxreasons(id)             -- 11/12/2020 SSW - we now track a reason why this transaction occurred
-- reason codes:
	-- 1= SBPReserved
	-- 2= SBPForfeit
	-- 3= SBPRefunded
);
CREATE INDEX IF NOT EXISTS idx_sbptransactions_wagerid ON sbptransactions(wagerid);

-- helpful:
-- select wagerid, amount, r.label from sbptransactions t inner join sbptxreasons r on t.reason = r.id;

-- promotional free round offers
-- sent by wallet providers to our service API endpoints
-- which relay them to pitboss
-- pitboss records the common data
-- and forwards any extra data to the wallet integration to record as extended data (if needed)
CREATE TABLE IF NOT EXISTS freerounds (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(), -- unique identifier for pitboss (freespinid)

    userid      UUID        REFERENCES users(id) NOT NULL,          -- user -> operator (casino)
    gameid      UUID        REFERENCES games(id) NOT NULL,          -- game -> integration (wallet)
    offerid     TEXT        NOT NULL,                               -- id of this offer in wallet system

    value       BIGINT      NOT NULL,                               -- initial value of this offer (per round)
    currency    CHAR(3)     NOT NULL,                               -- initial currency of this offer
    rounds      INT         NOT NULL,                               -- initial count of rounds this offer had on it

    promocode   TEXT        NOT NULL DEFAULT '',                    -- optional: any associated promotional code
    author      TEXT        NOT NULL DEFAULT '',                    -- optional: what entity made this offer originally
    notes       TEXT        NOT NULL DEFAULT '',                    -- optional: any additional notes

    begins      TIMESTAMPTZ NOT NULL,                               -- when the offer begins (can be in the future)
    expires     TIMESTAMPTZ NOT NULL,                               -- when the offer expires
    revoked     TIMESTAMPTZ,                                        -- when this offer was revoked (if it was)

    gamevalue   BIGINT,                                             -- value of each round (once listed)
    gamecurrency CHAR(3),                                           -- currency of value (once listed)
    gamerounds  INT         NOT NULL DEFAULT 0,                     -- how many rounds have been wagered on thus far
    paidrounds  INT         NOT NULL DEFAULT 0,                     -- how many rounds have been paid out on thus far

    accepted    BOOLEAN,                                            -- true is accepted, false is rejected, NULL is neither accepted nor rejected

    started     TIMESTAMPTZ,                                        -- when this offer was realized into a freespin series
    completed   TIMESTAMPTZ,                                        -- when this series was completed (normally this means paid out, but if it's an Expired PFR, this just marks it as being in process of being paid out)

    winnings    BIGINT      NOT NULL DEFAULT 0,                     -- how much has been won on this freespin (so far / potentially)

    UNIQUE(userid, gameid, offerid)
);
CREATE INDEX IF NOT EXISTS idx_freerounds_userid ON freerounds(userid);
CREATE INDEX IF NOT EXISTS idx_freerounds_gameid ON freerounds(gameid);

-- For any wager that fails we permanently create a failed wager entry.
-- If eventually cancelled, its state changes and a corresponding payout is added, but the failed payout is left for reporting purposes.
CREATE TABLE IF NOT EXISTS failedwagers (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(), -- pitboss canceled wager ID
    cancelid        UUID        DEFAULT uuid_generate_v4(),             -- pitboss cancel ID
    userid          UUID        REFERENCES users(id) NOT NULL,          -- pitboss user ID
    gameid          UUID        REFERENCES games(id) NOT NULL,          -- pitboss game ID
    iwagerid        TEXT,                                               -- wallet wager ID if known
    transactionid   TEXT,                                               -- wallet transaction ID if known
    amount          BIGINT,                                             -- amount of the canceled wager
    currency        CHAR(3),                                            -- currency
    freespinid      UUID,                                               -- PFR ID (if any)
    created         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- For failed wagers in the cancel state we keep additional data about how to cancel them
-- Once a wager is successfully cancelled or given up it is removed from the cancelwager table
CREATE TABLE IF NOT EXISTS cancelwager (
    failedwagerid   UUID        PRIMARY KEY REFERENCES failedwagers(id) NOT NULL,
    retryattempts   INT         NOT NULL, -- count of additional attempts made
    nextretry       TIMESTAMPTZ NOT NULL, -- NOTE if no more retry time exists this record should be removed!
    sessionid       TEXT,                 -- Session ID used to make the original call
    clientmetrics   TEXT
);

-- Possible failed payout states.
-- NOTE: -1 is reserved (no state)
-- 0 retry if payout is currently being retried.
-- 1 succeeded if a retry fixed the failed payout.
-- 2 gave up if retries
CREATE TABLE IF NOT EXISTS failedpayoutstates (
    id              INT         PRIMARY KEY,
    label           TEXT
);
INSERT INTO failedpayoutstates VALUES(0, 'retrying') ON CONFLICT DO NOTHING;
INSERT INTO failedpayoutstates VALUES(1, 'succeeded') ON CONFLICT DO NOTHING;
INSERT INTO failedpayoutstates VALUES(2, 'gaveup') ON CONFLICT DO NOTHING;

-- For any payout that fails we permanently create a failed payout entry.
-- If eventually succesful its state changes and a corresponding payout is added, but the failed payout is left for reporting purposes.
CREATE TABLE IF NOT EXISTS failedpayouts (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    wagerid         UUID        REFERENCES wagers(id) NOT NULL,
    transactionid   TEXT,                                             -- wallet transaction ID.  note this can be null for old entries, for non-final payouts (if buffered) and for integrations that don't have transaction ids
    amount          BIGINT      NOT NULL,
    reason          TEXT        NOT NULL,
    final           BOOLEAN     NOT NULL,
    created         TIMESTAMPTZ NOT NULL DEFAULT now(),
    statechanged    TIMESTAMPTZ NOT NULL DEFAULT now(),
    stateid         INT         REFERENCES failedpayoutstates(id) NOT NULL,
    paytableforfeit BIGINT      NOT NULL DEFAULT 0
);

-- For failed payouts in the retry state we keep additional data about how to retry them
-- Once a payout is successful or given up it is removed from the retrypayouts table
CREATE TABLE IF NOT EXISTS retrypayouts (
    failedpayoutid  UUID        PRIMARY KEY REFERENCES failedpayouts(id) NOT NULL,
    retryattempts   INT         NOT NULL, -- Remove retries left, leave that up to integration
    nextretry       TIMESTAMPTZ NOT NULL, -- NOTE if no more retry time exists this should be removed!
    sessionid       TEXT,                 -- Session ID used to make the original call
    clientmetrics   TEXT
);
CREATE INDEX IF NOT EXISTS idx_retrypayouts_nextretry ON retrypayouts(nextretry);


-- Some jurisdicitons have specific bet limits.  Those are stored here
CREATE TABLE IF NOT EXISTS jurisdiction_betlimits (
    jurisdiction    CHAR(2)     PRIMARY KEY NOT NULL,
    betlimit        BIGINT
);

CREATE TABLE IF NOT EXISTS operator_ruleset_betlimits (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    operatorid      UUID        REFERENCES operators(id),
    rulesetid       UUID        REFERENCES rulesets(id),
    betlimit        BIGINT
);

CREATE TABLE IF NOT EXISTS bonussets
(
    id         VARCHAR,
    bonuslevel BIGINT,
    notes      VARCHAR,
    CONSTRAINT bonussets_pk
        UNIQUE (id, bonuslevel)
);

