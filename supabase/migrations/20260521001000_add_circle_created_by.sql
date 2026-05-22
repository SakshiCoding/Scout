-- Adds creator ownership for existing Scout databases.
-- The initial schema includes this column, but older circles tables may already
-- exist without it because create table if not exists does not add new columns.

alter table public.circles
  add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.circles
  alter column created_by set default auth.uid();
