--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.8
-- Dumped by pg_dump version 9.6.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: http_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.http_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    scheme character varying(255),
    userinfo text,
    host text,
    port integer,
    path text,
    query text,
    fragment text,
    method character varying(255),
    response_status integer,
    duration integer,
    started_at timestamp without time zone
);


--
-- Name: schema_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_info (
    version integer DEFAULT 0 NOT NULL
);


--
-- Name: http_requests http_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.http_requests
    ADD CONSTRAINT http_requests_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

