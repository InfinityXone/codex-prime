-- Logs table for swarm-grade operations

create table if not exists logs (
  id bigint generated always as identity primary key,
  category text not null check (category in ('system','agent','wallet','faucet','profit','key_rotation')),
  agent text,
  level text not null check (level in ('DEBUG','INFO','WARN','ERROR','CRITICAL')),
  message text not null,
  payload jsonb,
  created_at timestamptz default now()
);
