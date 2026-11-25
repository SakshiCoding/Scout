import assert from 'node:assert/strict';
import fs from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
const migration = fs.readdirSync('supabase/migrations').find(name => name.endsWith('_enforce_scout_storage_membership.sql'));
assert(migration, 'Missing production Storage migration');
const sql = fs.readFileSync(`supabase/migrations/${migration}`, 'utf8');
const db = new PGlite();
const a = '00000000-0000-0000-0000-000000000001';
const b = '00000000-0000-0000-0000-000000000002';
const outsider = '00000000-0000-0000-0000-000000000003';
const circleA = '11111111-1111-1111-1111-111111111111';
const circleB = '22222222-2222-2222-2222-222222222222';
const photoA = `circles/${circleA}/visits/a/photo.jpg`;
const photoB = `circles/${circleB}/visits/b/photo.jpg`;
await db.exec(`
 create role authenticated; create role anon;
 create schema auth; create schema storage;
 create function auth.uid() returns uuid language sql stable as
 $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 create function storage.foldername(text) returns text[] language sql immutable as
 $$ select (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;
 create table public.circle_members(circle_id uuid, user_id uuid, primary key(circle_id,user_id));
 insert into public.circle_members values ('${circleA}','${a}'), ('${circleB}','${b}');
 create function public.is_circle_member(uuid) returns boolean language sql stable security definer
 set search_path='' as $$ select exists(select 1 from public.circle_members where circle_id=$1 and user_id=auth.uid()) $$;
 create table storage.objects(bucket_id text, name text, primary key(bucket_id,name));
 alter table storage.objects enable row level security;
 grant usage on schema auth,storage to authenticated,anon;
 grant select,insert,update,delete on storage.objects to authenticated,anon;
 -- Reproduce the bucket-wide legacy policies, plus an intentionally broad fallback
 -- to prove even public/ALL policies cannot bypass the new restrictive guard.
 create policy "Circle members can read tf01ud_0" on storage.objects for select to authenticated using(bucket_id='scout-media');
 create policy "Circle members can upload tf01ud_0" on storage.objects for insert to authenticated with check(bucket_id='scout-media');
 create policy "Legacy broad fallback" on storage.objects for all to public using(true) with check(true);
 insert into storage.objects values ('scout-media','${photoA}'), ('scout-media','${photoB}'),
 ('scout-media','circles/not-a-uuid/photo.jpg'), ('scout-media','legacy/photo.jpg'), ('other-bucket','unrelated.jpg');
`);
async function asUser(user, role = 'authenticated') {
  await db.exec(`reset role; set role ${role}`);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [user ?? '']);
}
async function names() { return (await db.query('select name from storage.objects order by name')).rows.map(row => row.name); }
async function deny(query, params = []) {
  let failure;
  try { await db.query(query, params); } catch (error) { failure = error; }
  assert(failure, 'Forbidden write succeeded');
  assert.equal(failure.code, '42501', 'Denied by actual RLS, not a parser/fixture error');
}
await asUser(outsider);
assert((await names()).includes(photoA), 'Fixture must reproduce the old cross-circle leak');
await db.exec('reset role');
await db.exec(sql);
await db.exec(sql); // Idempotent repairs must preserve the guard.
await asUser(a);
assert.deepEqual(await names(), [photoA, 'unrelated.jpg']);
await asUser(b);
assert.deepEqual(await names(), [photoB, 'unrelated.jpg']);
for (const [user, role] of [[outsider, 'authenticated'], [null, 'anon']]) {
  await asUser(user, role);
  assert.deepEqual(await names(), ['unrelated.jpg']);
  await deny('insert into storage.objects values($1,$2)', ['scout-media', `circles/${circleA}/forged.jpg`]);
  assert.deepEqual((await db.query('delete from storage.objects where bucket_id=$1 returning name', ['scout-media'])).rows, []);
  assert.deepEqual((await db.query('update storage.objects set name=$1 where bucket_id=$2 returning name', ['forged.jpg', 'scout-media'])).rows, []);
}
await asUser(a);
await db.query('insert into storage.objects values($1,$2)', ['scout-media', `circles/${circleA}/new.jpg`]);
await deny('insert into storage.objects values($1,$2)', ['scout-media', `circles/${circleB}/forged.jpg`]);
for (const invalid of ['circles/not-a-uuid/photo.jpg', 'wrong-prefix/'+circleA+'/photo.jpg', 'legacy/new.jpg']) {
  await deny('insert into storage.objects values($1,$2)', ['scout-media', invalid]);
}
await deny('update storage.objects set name=$1 where name=$2', [`circles/${circleB}/moved.jpg`, photoA]);
const removed = await db.query('delete from storage.objects where name=$1 returning name', [`circles/${circleA}/new.jpg`]);
assert.equal(removed.rows.length, 1);
await db.query('insert into storage.objects values($1,$2)', ['other-bucket', 'still-allowed.jpg']);
await db.exec('reset role');
await db.query('delete from public.circle_members where user_id=$1', [a]);
await asUser(a);
assert(!(await names()).includes(photoA));
await deny('insert into storage.objects values($1,$2)', ['scout-media', `circles/${circleA}/revoked.jpg`]);
await db.close();
console.log('PASS actual Storage migration: reproduces legacy leak, enforces read/upload/update/delete membership, anonymous/outsider and malformed-path denial, revocation, idempotence, and other-bucket preservation');
