-- Codex Prime Neural Ledger (Level 10)

create table if not exists memory (
  id bigint generated always as identity primary key,
  agent text not null,
  role text,
  vector double precision[],
  content text,
  created_at timestamptz default now()
);

create table if not exists ledger (
  id bigint generated always as identity primary key,
  event text not null,
  payload jsonb,
  created_at timestamptz default now()
);

create table if not exists handshake (
  id bigint generated always as identity primary key,
  agent_name text not null,
  handshake_hash text not null,
  created_at timestamptz default now()
);

create table if not exists integrity (
  id bigint generated always as identity primary key,
  file_path text not null,
  hash text not null,
  created_at timestamptz default now()
);
