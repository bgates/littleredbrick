--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE assignments (
    id integer NOT NULL,
    section_id integer NOT NULL,
    title character varying(100) DEFAULT ''::character varying NOT NULL,
    description text,
    date_assigned date,
    date_due date,
    category character varying(20) DEFAULT NULL::character varying,
    reported_grade_id integer,
    "position" smallint NOT NULL,
    point_value integer DEFAULT 0
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE assignments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE assignments_id_seq OWNED BY assignments.id;


--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    user_id integer,
    login character varying(60) DEFAULT NULL::character varying,
    crypted_password character varying(40) DEFAULT NULL::character varying,
    salt character varying(40) DEFAULT NULL::character varying,
    school_id integer,
    login_key character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authorizations_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE departments (
    id integer NOT NULL,
    name character varying(30) DEFAULT ''::character varying NOT NULL,
    school_id integer
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE departments_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE departments_id_seq OWNED BY departments.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE events (
    id integer NOT NULL,
    name character varying(60) DEFAULT ''::character varying NOT NULL,
    description character varying(256) DEFAULT ''::character varying NOT NULL,
    date date NOT NULL,
    creator_id integer,
    invitable_type character varying(10) DEFAULT NULL::character varying,
    invitable_id integer
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_id_seq OWNED BY events.id;


--
-- Name: forum_activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE forum_activities (
    id integer NOT NULL,
    user_id integer,
    posts_count smallint DEFAULT 0,
    discussable_id integer,
    discussable_type character varying(10) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: forum_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forum_activities_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forum_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forum_activities_id_seq OWNED BY forum_activities.id;


--
-- Name: forums; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE forums (
    id integer NOT NULL,
    name character varying(255) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    topics_count smallint DEFAULT 0,
    posts_count integer DEFAULT 0,
    "position" smallint,
    description_html text,
    discussable_id integer,
    discussable_type character varying(10) DEFAULT NULL::character varying,
    owner_id integer,
    open boolean
);


--
-- Name: forums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE forums_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: forums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE forums_id_seq OWNED BY forums.id;


--
-- Name: grades; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE grades (
    id integer NOT NULL,
    assignment_id integer DEFAULT 0,
    rollbook_entry_id integer,
    score character varying(5) DEFAULT NULL::character varying,
    updated_at date,
    section_id integer,
    date_due date
);


--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE grades_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE grades_id_seq OWNED BY grades.id;


--
-- Name: invites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invites (
    id integer NOT NULL,
    event_id integer NOT NULL,
    invitable_id integer NOT NULL,
    invitable_type character varying(10) DEFAULT ''::character varying NOT NULL
);


--
-- Name: invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invites_id_seq OWNED BY invites.id;


--
-- Name: logged_exceptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logged_exceptions (
    id integer NOT NULL,
    exception_class character varying(255) DEFAULT NULL::character varying,
    controller_name character varying(255) DEFAULT NULL::character varying,
    action_name character varying(255) DEFAULT NULL::character varying,
    message text DEFAULT NULL::character varying,
    backtrace text,
    environment text,
    request text,
    created_at timestamp without time zone
);


--
-- Name: logged_exceptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE logged_exceptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: logged_exceptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE logged_exceptions_id_seq OWNED BY logged_exceptions.id;


--
-- Name: logins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logins (
    id integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    logout timestamp without time zone
);


--
-- Name: logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE logins_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE logins_id_seq OWNED BY logins.id;


--
-- Name: marking_periods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE marking_periods (
    id integer NOT NULL,
    track_id integer,
    start date,
    finish date,
    reported_grade_id integer,
    "position" smallint
);


--
-- Name: marking_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE marking_periods_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: marking_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE marking_periods_id_seq OWNED BY marking_periods.id;


--
-- Name: milestones; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE milestones (
    id integer NOT NULL,
    rollbook_entry_id integer,
    earned numeric(5,1) DEFAULT 0.0,
    possible integer DEFAULT 0,
    reported_grade_id integer
);


--
-- Name: milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE milestones_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE milestones_id_seq OWNED BY milestones.id;


--
-- Name: moderatorships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE moderatorships (
    id integer NOT NULL,
    forum_id integer,
    user_id integer
);


--
-- Name: moderatorships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE moderatorships_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: moderatorships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE moderatorships_id_seq OWNED BY moderatorships.id;


--
-- Name: monitorships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE monitorships (
    id integer NOT NULL,
    topic_id integer,
    user_id integer,
    active boolean
);


--
-- Name: monitorships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE monitorships_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: monitorships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE monitorships_id_seq OWNED BY monitorships.id;


--
-- Name: parents_students; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parents_students (
    parent_id integer NOT NULL,
    student_id integer NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posts (
    id integer NOT NULL,
    user_id integer,
    topic_id integer,
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    forum_id integer,
    body_html text,
    discussable_id integer,
    discussable_type character varying(10) DEFAULT NULL::character varying
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posts_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: reported_grades; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reported_grades (
    id integer NOT NULL,
    reportable_id integer,
    reportable_type character varying(10) DEFAULT NULL::character varying,
    description character varying(255) DEFAULT NULL::character varying,
    predecessor_id integer
);


--
-- Name: reported_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reported_grades_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: reported_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reported_grades_id_seq OWNED BY reported_grades.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    title character varying(20) DEFAULT NULL::character varying
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles_users (
    role_id smallint,
    user_id integer
);


--
-- Name: rollbook_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rollbook_entries (
    id integer NOT NULL,
    student_id integer DEFAULT 0,
    section_id integer,
    "position" smallint,
    x smallint,
    y smallint
);


--
-- Name: rollbook_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rollbook_entries_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: rollbook_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rollbook_entries_id_seq OWNED BY rollbook_entries.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: schools; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schools (
    id integer NOT NULL,
    name character varying(100) DEFAULT NULL::character varying,
    domain_name character varying(50) DEFAULT NULL::character varying,
    low_grade smallint,
    high_grade smallint,
    teacher_limit smallint,
    setup boolean
);


--
-- Name: schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE schools_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE schools_id_seq OWNED BY schools.id;


--
-- Name: sections; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sections (
    id integer NOT NULL,
    teacher_id integer,
    "time" character varying(3) DEFAULT NULL::character varying,
    subject_id integer,
    track_id integer,
    grade_scale text,
    enrollment smallint DEFAULT 0,
    posts_count smallint DEFAULT 0,
    topics_count smallint DEFAULT 0,
    current boolean
);


--
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sections_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sections_id_seq OWNED BY sections.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(32) DEFAULT NULL::character varying,
    data text,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subjects (
    id integer NOT NULL,
    name character varying(100) DEFAULT ''::character varying NOT NULL,
    credit character varying(3) DEFAULT NULL::character varying,
    department_id integer
);


--
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subjects_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subjects_id_seq OWNED BY subjects.id;


--
-- Name: terms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE terms (
    id integer NOT NULL,
    school_id smallint,
    low_period smallint,
    high_period smallint
);


--
-- Name: terms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE terms_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: terms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE terms_id_seq OWNED BY terms.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE topics (
    id integer NOT NULL,
    forum_id integer,
    user_id integer,
    title character varying(255) DEFAULT NULL::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    hits integer DEFAULT 0,
    sticky smallint DEFAULT 0,
    posts_count integer DEFAULT 0,
    replied_at timestamp without time zone,
    replied_by integer,
    last_post_id integer,
    locked boolean
);


--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE topics_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE topics_id_seq OWNED BY topics.id;


--
-- Name: tracks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tracks (
    id integer NOT NULL,
    term_id integer,
    archive date,
    "position" integer
);


--
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracks_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracks_id_seq OWNED BY tracks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    type character varying(10) DEFAULT ''::character varying,
    school_id integer DEFAULT 0,
    id_number integer,
    first_name character varying(25) DEFAULT NULL::character varying,
    last_name character varying(25) DEFAULT NULL::character varying,
    title character varying(10) DEFAULT NULL::character varying,
    email character varying(100) DEFAULT NULL::character varying,
    grade smallint,
    last_login timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE assignments ALTER COLUMN id SET DEFAULT nextval('assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE departments ALTER COLUMN id SET DEFAULT nextval('departments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE events ALTER COLUMN id SET DEFAULT nextval('events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE forum_activities ALTER COLUMN id SET DEFAULT nextval('forum_activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE forums ALTER COLUMN id SET DEFAULT nextval('forums_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE grades ALTER COLUMN id SET DEFAULT nextval('grades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE invites ALTER COLUMN id SET DEFAULT nextval('invites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE logged_exceptions ALTER COLUMN id SET DEFAULT nextval('logged_exceptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE logins ALTER COLUMN id SET DEFAULT nextval('logins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE marking_periods ALTER COLUMN id SET DEFAULT nextval('marking_periods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE milestones ALTER COLUMN id SET DEFAULT nextval('milestones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE moderatorships ALTER COLUMN id SET DEFAULT nextval('moderatorships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE monitorships ALTER COLUMN id SET DEFAULT nextval('monitorships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE reported_grades ALTER COLUMN id SET DEFAULT nextval('reported_grades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE rollbook_entries ALTER COLUMN id SET DEFAULT nextval('rollbook_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE schools ALTER COLUMN id SET DEFAULT nextval('schools_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sections ALTER COLUMN id SET DEFAULT nextval('sections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE subjects ALTER COLUMN id SET DEFAULT nextval('subjects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE terms ALTER COLUMN id SET DEFAULT nextval('terms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE topics ALTER COLUMN id SET DEFAULT nextval('topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE tracks ALTER COLUMN id SET DEFAULT nextval('tracks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: forum_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forum_activities
    ADD CONSTRAINT forum_activities_pkey PRIMARY KEY (id);


--
-- Name: forums_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY forums
    ADD CONSTRAINT forums_pkey PRIMARY KEY (id);


--
-- Name: grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: logged_exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logged_exceptions
    ADD CONSTRAINT logged_exceptions_pkey PRIMARY KEY (id);


--
-- Name: logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logins
    ADD CONSTRAINT logins_pkey PRIMARY KEY (id);


--
-- Name: marking_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY marking_periods
    ADD CONSTRAINT marking_periods_pkey PRIMARY KEY (id);


--
-- Name: milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY milestones
    ADD CONSTRAINT milestones_pkey PRIMARY KEY (id);


--
-- Name: moderatorships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY moderatorships
    ADD CONSTRAINT moderatorships_pkey PRIMARY KEY (id);


--
-- Name: monitorships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY monitorships
    ADD CONSTRAINT monitorships_pkey PRIMARY KEY (id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: reported_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reported_grades
    ADD CONSTRAINT reported_grades_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: rollbook_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rollbook_entries
    ADD CONSTRAINT rollbook_entries_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations_version_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);


--
-- Name: schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- Name: terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY terms
    ADD CONSTRAINT terms_pkey PRIMARY KEY (id);


--
-- Name: topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: by_all; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX by_all ON forum_activities USING btree (discussable_type, discussable_id, user_id);


--
-- Name: by_discuss_and_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX by_discuss_and_date ON posts USING btree (discussable_id, discussable_type, created_at);


--
-- Name: by_discussable_and_position; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX by_discussable_and_position ON forums USING btree (discussable_type, discussable_id, "position");


--
-- Name: by_user_id_and_discussable; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX by_user_id_and_discussable ON posts USING btree (discussable_type, discussable_id, user_id, created_at);


--
-- Name: fk_grades_assignment; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fk_grades_assignment ON grades USING btree (assignment_id);


--
-- Name: fk_grades_student; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fk_grades_student ON grades USING btree (rollbook_entry_id);


--
-- Name: fk_sections_subject; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fk_sections_subject ON sections USING btree (subject_id);


--
-- Name: fk_ss_student; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fk_ss_student ON rollbook_entries USING btree (student_id);


--
-- Name: index_assignments_on_reported_grade_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assignments_on_reported_grade_id ON assignments USING btree (reported_grade_id);


--
-- Name: index_assignments_on_section_id_and_category; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assignments_on_section_id_and_category ON assignments USING btree (section_id, category);


--
-- Name: index_assignments_on_section_id_and_position; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_assignments_on_section_id_and_position ON assignments USING btree (section_id, "position");


--
-- Name: index_authorizations_on_login_and_school_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_authorizations_on_login_and_school_id ON authorizations USING btree (login, school_id);


--
-- Name: index_authorizations_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_authorizations_on_user_id ON authorizations USING btree (user_id);


--
-- Name: index_departments_on_school_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_departments_on_school_id ON departments USING btree (school_id, name);


--
-- Name: index_events_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_creator_id ON events USING btree (creator_id);


--
-- Name: index_events_on_invitable_type_and_invitable_id_and_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_events_on_invitable_type_and_invitable_id_and_date ON events USING btree (invitable_type, invitable_id, date);


--
-- Name: index_forums_on_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_forums_on_owner_id ON forums USING btree (owner_id);


--
-- Name: index_grades_on_section_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_grades_on_section_id ON grades USING btree (section_id);


--
-- Name: index_logins_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_logins_on_user_id_and_created_at ON logins USING btree (user_id, created_at);


--
-- Name: index_marking_periods_on_reported_grade_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_marking_periods_on_reported_grade_id ON marking_periods USING btree (reported_grade_id);


--
-- Name: index_marking_periods_on_track_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_marking_periods_on_track_id ON marking_periods USING btree (track_id, start);


--
-- Name: index_milestones_on_reported_grade_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestones_on_reported_grade_id ON milestones USING btree (reported_grade_id);


--
-- Name: index_milestones_on_rollbook_entry_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_milestones_on_rollbook_entry_id ON milestones USING btree (rollbook_entry_id);


--
-- Name: index_moderatorships_on_forum_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_moderatorships_on_forum_id ON moderatorships USING btree (forum_id);


--
-- Name: index_moderatorships_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_moderatorships_on_user_id ON moderatorships USING btree (user_id);


--
-- Name: index_monitorships_on_topic_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_monitorships_on_topic_id ON monitorships USING btree (topic_id);


--
-- Name: index_monitorships_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_monitorships_on_user_id ON monitorships USING btree (user_id);


--
-- Name: index_parents_students_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_parents_students_on_parent_id ON parents_students USING btree (parent_id);


--
-- Name: index_parents_students_on_student_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_parents_students_on_student_id ON parents_students USING btree (student_id);


--
-- Name: index_posts_on_forum_id_and_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_forum_id_and_created_at ON posts USING btree (forum_id, created_at);


--
-- Name: index_posts_on_topic_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posts_on_topic_id ON posts USING btree (topic_id, created_at);


--
-- Name: index_reported_grades_on_reportable_type_and_reportable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reported_grades_on_reportable_type_and_reportable_id ON reported_grades USING btree (reportable_type, reportable_id);


--
-- Name: index_roles_users_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_users_on_user_id_and_role_id ON roles_users USING btree (user_id, role_id);


--
-- Name: index_rollbook_entries_on_section_id_and_position; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_rollbook_entries_on_section_id_and_position ON rollbook_entries USING btree (section_id, "position");


--
-- Name: index_schools_on_domain_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_schools_on_domain_name ON schools USING btree (domain_name);


--
-- Name: index_subjects_on_department_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_subjects_on_department_id_and_name ON subjects USING btree (department_id, name);


--
-- Name: index_terms_on_school_id_and_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_terms_on_school_id_and_id ON terms USING btree (school_id, id);


--
-- Name: index_topics_on_forum_id_and_replied_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_forum_id_and_replied_at ON topics USING btree (forum_id, replied_at);


--
-- Name: index_topics_on_forum_id_and_sticky_and_replied_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_forum_id_and_sticky_and_replied_at ON topics USING btree (forum_id, sticky, replied_at);


--
-- Name: index_topics_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_topics_on_user_id ON topics USING btree (user_id);


--
-- Name: index_tracks_on_term_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tracks_on_term_id ON tracks USING btree (term_id);


--
-- Name: index_users_on_school_id_and_type_and_last_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_school_id_and_type_and_last_name ON users USING btree (school_id, type, last_name);


--
-- Name: sessions_session_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX sessions_session_id_index ON sessions USING btree (session_id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('19');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('20081017025925');

INSERT INTO schema_migrations (version) VALUES ('20081017042837');

INSERT INTO schema_migrations (version) VALUES ('20081022151831');

INSERT INTO schema_migrations (version) VALUES ('20081023170733');

INSERT INTO schema_migrations (version) VALUES ('20081110034903');

INSERT INTO schema_migrations (version) VALUES ('20081115075951');

INSERT INTO schema_migrations (version) VALUES ('20081127045630');

INSERT INTO schema_migrations (version) VALUES ('20081129032134');

INSERT INTO schema_migrations (version) VALUES ('20081205191715');

INSERT INTO schema_migrations (version) VALUES ('20081206205039');

INSERT INTO schema_migrations (version) VALUES ('20081214090336');

INSERT INTO schema_migrations (version) VALUES ('21');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('23');

INSERT INTO schema_migrations (version) VALUES ('24');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('31');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');

INSERT INTO schema_migrations (version) VALUES ('20090109032246');

INSERT INTO schema_migrations (version) VALUES ('20090109141357');

INSERT INTO schema_migrations (version) VALUES ('20090110120503');

INSERT INTO schema_migrations (version) VALUES ('20090111173622');

INSERT INTO schema_migrations (version) VALUES ('20090112184247');

INSERT INTO schema_migrations (version) VALUES ('20090118050429');

INSERT INTO schema_migrations (version) VALUES ('20090122031040');

INSERT INTO schema_migrations (version) VALUES ('20090130113651');

INSERT INTO schema_migrations (version) VALUES ('20090601103415');