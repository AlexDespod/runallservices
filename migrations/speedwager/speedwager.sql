--
-- PostgreSQL database dump
--

-- Dumped from database version 11.12
-- Dumped by pg_dump version 12.9 (Ubuntu 12.9-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: speedwager; Type: SCHEMA; Schema: -; Owner: speedwager
--

CREATE SCHEMA speedwager;


ALTER SCHEMA speedwager OWNER TO speedwager;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: pb_tx_state; Type: TYPE; Schema: speedwager; Owner: speedwager
--

CREATE TYPE speedwager.pb_tx_state AS ENUM (
    'wager_open_intention',
    'wager_open',
    'wager_close_intention',
    'wager_discarded',
    'wager_closed'
);


ALTER TYPE speedwager.pb_tx_state OWNER TO speedwager;

--
-- Name: pb_tx_type; Type: TYPE; Schema: speedwager; Owner: speedwager
--

CREATE TYPE speedwager.pb_tx_type AS ENUM (
    'master_allocation_tx',
    'slave_allocation_tx',
    'reconciliation_tx'
);


ALTER TYPE speedwager.pb_tx_type OWNER TO speedwager;

--
-- Name: session_set_last_modified(); Type: FUNCTION; Schema: speedwager; Owner: speedwager
--

CREATE FUNCTION speedwager.session_set_last_modified() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION speedwager.session_set_last_modified() OWNER TO speedwager;

SET default_tablespace = '';

--
-- Name: audit; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.audit (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    request_time timestamp with time zone DEFAULT now() NOT NULL,
    request text NOT NULL,
    response_time timestamp with time zone,
    response text,
    error text,
    context text,
    round_id uuid,
    session_id uuid
);


ALTER TABLE speedwager.audit OWNER TO speedwager;

--
-- Name: config; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.config (
    game_id uuid NOT NULL,
    wallet_factor numeric(20,2) NOT NULL,
    reallocate_threshold numeric(20,2) NOT NULL,
    min_wager_throughput numeric(20,2) NOT NULL,
    max_wager_throughput numeric(20,2) NOT NULL,
    wager_multiply bigint DEFAULT 1 NOT NULL
);


ALTER TABLE speedwager.config OWNER TO speedwager;

--
-- Name: payout; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.payout (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    balance bigint NOT NULL,
    amount bigint NOT NULL,
    sbppayout bigint NOT NULL,
    wager_id uuid NOT NULL,
    round_id uuid NOT NULL,
    session_id uuid NOT NULL
);


ALTER TABLE speedwager.payout OWNER TO speedwager;

--
-- Name: pb_tx; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.pb_tx (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    round_id uuid NOT NULL,
    balance_before_wager bigint,
    wager_amount bigint,
    wager_time timestamp with time zone,
    wager_id uuid,
    balance_before_payout bigint,
    payout_amount bigint,
    payout_time timestamp with time zone,
    tx_state speedwager.pb_tx_state NOT NULL,
    tx_type speedwager.pb_tx_type NOT NULL,
    original_wager_id uuid,
    original_payout_id uuid
);


ALTER TABLE speedwager.pb_tx OWNER TO speedwager;

--
-- Name: reconciliation; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.reconciliation (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    round_id uuid NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE speedwager.reconciliation OWNER TO speedwager;

--
-- Name: reconciliation_tx; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.reconciliation_tx (
    reconciliation_id uuid,
    wager_id uuid,
    payout_id uuid
);


ALTER TABLE speedwager.reconciliation_tx OWNER TO speedwager;

--
-- Name: round; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.round (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    open_time timestamp with time zone NOT NULL,
    close_time timestamp with time zone,
    wager_amount bigint NOT NULL,
    wager_throughput numeric(20,2) NOT NULL,
    reallocate_threshold numeric(20,2) NOT NULL,
    wallet_factor numeric(20,2) NOT NULL,
    playable_amount bigint NOT NULL,
    session_id uuid NOT NULL,
    active_freespin jsonb
);


ALTER TABLE speedwager.round OWNER TO speedwager;

--
-- Name: session; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.session (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    currency text NOT NULL,
    session_ticket text NOT NULL,
    game_id uuid NOT NULL,
    idempotence_token uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    allocated_amount bigint DEFAULT 0 NOT NULL,
    pitboss_state jsonb,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT session_allocated_amount_check CHECK ((allocated_amount >= 0))
);


ALTER TABLE speedwager.session OWNER TO speedwager;

--
-- Name: wager; Type: TABLE; Schema: speedwager; Owner: speedwager
--

CREATE TABLE speedwager.wager (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    balance bigint NOT NULL,
    amount bigint NOT NULL,
    round_id uuid NOT NULL,
    session_id uuid NOT NULL,
    group_id uuid,
    freespin_id uuid,
    sbplevel bigint,
    sbpreserve bigint,
    sbpforfeit bigint,
    sbprefund bigint,
    payload text
);


ALTER TABLE speedwager.wager OWNER TO speedwager;

--
-- Data for Name: audit; Type: TABLE DATA; Schema: speedwager; Owner: speedwager
--

--
-- Data for Name: config; Type: TABLE DATA; Schema: speedwager; Owner: speedwager
--

COPY speedwager.config (game_id, wallet_factor, reallocate_threshold, min_wager_throughput, max_wager_throughput, wager_multiply) FROM stdin;
a78523c2-d78a-4dde-bd36-8989324591de	1.00	0.50	0.20	5.00	64
345b63fd-9256-490b-bf62-a82bf98ef3b2	1.00	0.50	0.20	5.00	64
cab6f065-5a27-41b7-a79d-5d53307ba9fe	1.00	0.50	0.20	5.00	64
79c20c17-1e7a-468f-ae89-46b7e809721f	1.00	0.50	0.20	5.00	64
87af1fc8-ef98-4752-ba36-207aa4c6da8b	1.00	0.50	0.20	5.00	64
47d19dea-67bb-4db9-9734-e958eca2df9c	1.00	0.50	0.20	5.00	64
c6029585-58dd-4d62-8131-d4cdf4f38e5e	1.00	0.50	0.20	5.00	64
fe0d1f99-3ffc-4efc-b90c-f2e80160cdd8	1.00	0.50	0.20	5.00	64
e9b9942b-32ce-4545-8afb-e1343aeafb16	1.00	0.50	0.20	5.00	64
7412c282-e9cc-4731-bede-8116121b7f0d	1.00	0.50	0.20	5.00	64
baaf2933-9605-45d3-ab6b-99cc00f7f6d3	1.00	0.50	0.20	5.00	64
0c08f08f-f7c7-4555-a359-2d58abe5253e	1.00	0.50	0.20	5.00	64
7d3c8beb-57eb-42ce-bf4a-30194a5f0dd0	1.00	0.50	0.20	5.00	64
5267f020-8826-401c-a1e4-bb724f80040a	1.00	0.50	0.20	5.00	64
df709a7c-854d-41a0-8a8e-2c6c191cb04a	1.00	0.50	0.20	5.00	64
637879b2-306c-4cf8-8980-59cf537fdb22	1.00	0.50	0.20	5.00	64
ff9235f8-6454-4df2-a154-51cabc8c1db5	1.00	0.50	0.20	5.00	64
33fdfbbc-6049-433b-b438-9fdd12842c5c	1.00	0.50	0.20	5.00	64
a9b07427-bbd2-4168-8d77-cd3ae4585a73	1.00	0.50	0.20	5.00	64
f28a683a-2e4e-48ed-8184-114a4bfb72d1	1.00	0.50	0.20	5.00	64
\.

--
-- Data for Name: session; Type: TABLE DATA; Schema: speedwager; Owner: speedwager
--


--
-- Name: audit audit_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.audit
    ADD CONSTRAINT audit_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (game_id);


--
-- Name: payout payout_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.payout
    ADD CONSTRAINT payout_pkey PRIMARY KEY (id);


--
-- Name: pb_tx pb_tx_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.pb_tx
    ADD CONSTRAINT pb_tx_pkey PRIMARY KEY (id);


--
-- Name: reconciliation reconciliation_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation
    ADD CONSTRAINT reconciliation_pkey PRIMARY KEY (id);


--
-- Name: reconciliation reconciliation_session_id_round_id_key; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation
    ADD CONSTRAINT reconciliation_session_id_round_id_key UNIQUE (session_id, round_id);


--
-- Name: round round_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.round
    ADD CONSTRAINT round_pkey PRIMARY KEY (id);


--
-- Name: session session_game_id_user_id_key; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.session
    ADD CONSTRAINT session_game_id_user_id_key UNIQUE (game_id, user_id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: wager wager_pkey; Type: CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.wager
    ADD CONSTRAINT wager_pkey PRIMARY KEY (id);


--
-- Name: game_session_ticket; Type: INDEX; Schema: speedwager; Owner: speedwager
--

CREATE UNIQUE INDEX game_session_ticket ON speedwager.session USING btree (game_id, session_ticket);


--
-- Name: pb_tx_session_id_round_id_idx; Type: INDEX; Schema: speedwager; Owner: speedwager
--

CREATE INDEX pb_tx_session_id_round_id_idx ON speedwager.pb_tx USING btree (session_id, round_id);


--
-- Name: session trigger_session_set_last_modified; Type: TRIGGER; Schema: speedwager; Owner: speedwager
--

CREATE TRIGGER trigger_session_set_last_modified BEFORE INSERT OR UPDATE ON speedwager.session FOR EACH ROW EXECUTE PROCEDURE speedwager.session_set_last_modified();


--
-- Name: payout payout_round_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.payout
    ADD CONSTRAINT payout_round_id_fkey FOREIGN KEY (round_id) REFERENCES speedwager.round(id);


--
-- Name: payout payout_session_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.payout
    ADD CONSTRAINT payout_session_id_fkey FOREIGN KEY (session_id) REFERENCES speedwager.session(id);


--
-- Name: payout payout_wager_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.payout
    ADD CONSTRAINT payout_wager_id_fkey FOREIGN KEY (wager_id) REFERENCES speedwager.wager(id);


--
-- Name: pb_tx pb_tx_original_payout_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.pb_tx
    ADD CONSTRAINT pb_tx_original_payout_id_fkey FOREIGN KEY (original_payout_id) REFERENCES speedwager.payout(id);


--
-- Name: pb_tx pb_tx_original_wager_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.pb_tx
    ADD CONSTRAINT pb_tx_original_wager_id_fkey FOREIGN KEY (original_wager_id) REFERENCES speedwager.wager(id);


--
-- Name: pb_tx pb_tx_round_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.pb_tx
    ADD CONSTRAINT pb_tx_round_id_fkey FOREIGN KEY (round_id) REFERENCES speedwager.round(id);


--
-- Name: pb_tx pb_tx_session_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.pb_tx
    ADD CONSTRAINT pb_tx_session_id_fkey FOREIGN KEY (session_id) REFERENCES speedwager.session(id);


--
-- Name: reconciliation reconciliation_round_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation
    ADD CONSTRAINT reconciliation_round_id_fkey FOREIGN KEY (round_id) REFERENCES speedwager.round(id);


--
-- Name: reconciliation reconciliation_session_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation
    ADD CONSTRAINT reconciliation_session_id_fkey FOREIGN KEY (session_id) REFERENCES speedwager.session(id);


--
-- Name: reconciliation_tx reconciliation_tx_payout_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation_tx
    ADD CONSTRAINT reconciliation_tx_payout_id_fkey FOREIGN KEY (payout_id) REFERENCES speedwager.payout(id);


--
-- Name: reconciliation_tx reconciliation_tx_reconciliation_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation_tx
    ADD CONSTRAINT reconciliation_tx_reconciliation_id_fkey FOREIGN KEY (reconciliation_id) REFERENCES speedwager.reconciliation(id);


--
-- Name: reconciliation_tx reconciliation_tx_wager_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.reconciliation_tx
    ADD CONSTRAINT reconciliation_tx_wager_id_fkey FOREIGN KEY (wager_id) REFERENCES speedwager.wager(id);


--
-- Name: round round_session_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.round
    ADD CONSTRAINT round_session_id_fkey FOREIGN KEY (session_id) REFERENCES speedwager.session(id);


--
-- Name: wager wager_round_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.wager
    ADD CONSTRAINT wager_round_id_fkey FOREIGN KEY (round_id) REFERENCES speedwager.round(id);


--
-- Name: wager wager_session_id_fkey; Type: FK CONSTRAINT; Schema: speedwager; Owner: speedwager
--

ALTER TABLE ONLY speedwager.wager
    ADD CONSTRAINT wager_session_id_fkey FOREIGN KEY (session_id) REFERENCES speedwager.session(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: speedwager
--

GRANT USAGE ON SCHEMA public TO speedwager;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: speedwager
--

ALTER DEFAULT PRIVILEGES FOR ROLE speedwager IN SCHEMA public GRANT SELECT ON TABLES  TO speedwager;


--
-- PostgreSQL database dump complete
--

