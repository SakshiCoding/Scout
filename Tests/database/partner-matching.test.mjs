import { PGlite } from '@electric-sql/pglite';
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
const db = new PGlite();
const ids = Array.from({length: 12}, (_, i) => `00000000-0000-0000-0000-${String(i+1).padStart(12,'0')}`);
const [a,b,c,outsider,circle,other,r1,r2,r3] = ids;
await db.exec(`
create role anon; create role authenticated;
create schema auth; create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true),'')::uuid $$;
grant usage on schema auth, public to authenticated, anon;
create table public.circles(id uuid primary key);
create table public.circle_members(circle_id uuid references circles(id), user_id uuid references auth.users(id), primary key(circle_id,user_id));
create table public.restaurants(id uuid primary key, circle_id uuid references circles(id), name text, status text, establishment_type text, created_at timestamptz not null default now());
create function public.is_circle_member(cid uuid) returns boolean language sql security definer set search_path='' as $$
 select exists(select 1 from public.circle_members where circle_id=cid and user_id=auth.uid()) $$;
insert into auth.users values ('${a}'),('${b}'),('${c}'),('${outsider}');
insert into circles values ('${circle}'),('${other}');
insert into circle_members values ('${circle}','${a}'),('${circle}','${b}'),('${other}','${outsider}');
insert into restaurants(id,circle_id,name,status,establishment_type) values ('${r1}','${circle}','One','want_to_try','restaurant'),('${r2}','${circle}','Two','want_to_try','restaurant'),('${r3}','${circle}','Three','want_to_try','cafe');
`);
for (const name of ['20261020230236_real_partner_matching.sql',
  '20261027011354_optimize_shared_pick_read_policy.sql',
  '20261027011514_fix_shared_pick_stale_round_error.sql']) {
  await db.exec(await readFile(new URL('../../supabase/migrations/'+name, import.meta.url), 'utf8'));
}
async function rpc(user, action='sync', session=null, restaurant=null, yes=null, window=1, circleId=circle) {
  return db.transaction(async tx => {
    await tx.exec(`set local role authenticated; select set_config('request.jwt.claim.sub','${user}',true)`);
    const result = await tx.query('select public.scout_pick($1,$2,$3,$4,$5,$6) as value', [circleId,action,session,restaurant,yes,window]);
    return result.rows[0].value;
  });
}
let s = await rpc(a);
assert.equal(s.restaurant_ids.length,3);
if (process.env.SCOUT_PICK_FIXTURE) await writeFile(process.env.SCOUT_PICK_FIXTURE, JSON.stringify(s));
assert.deepEqual((await rpc(b,'sync',null,null,null,0)).restaurant_ids,s.restaurant_ids);
assert.equal(s.id,(await rpc(b)).id); // different clients/windows join one canonical deck
const first=s.restaurant_ids[0], second=s.restaurant_ids[1];
s=await rpc(a,'vote',s.id,first,true);
assert.equal(s.matched_restaurant_id,null);
assert.equal(s.votes.length,1);
const revision=s.revision;
assert.equal((await rpc(a,'vote',s.id,first,true)).revision,revision); // retry is idempotent
await assert.rejects(rpc(a,'vote',s.id,s.restaurant_ids[2],true), /next card/);
await assert.rejects(rpc(a,'reset',s.id), /everyone/);
s=await rpc(a,'undo',s.id,first);
assert.equal(s.votes.length,0);
s=await rpc(a,'vote',s.id,first,true);
s=await rpc(b,'vote',s.id,first,true);
assert.equal(s.matched_restaurant_id,first);
assert.equal((await rpc(a)).matched_restaurant_id,first); // reopening restores authoritative match
await assert.rejects(rpc(a,'undo',s.id,first), /has matched/);
console.log('PASS shared deck, real mutual match, persistence, duplicate retry, ordered voting, undo, locked match');

const old=s.id;
const [reset1,reset2]=await Promise.all([rpc(a,'reset',old),rpc(b,'reset',old)]);
assert.equal(reset1.id,reset2.id);
assert.notEqual(reset1.id,old);
assert.equal(reset2.votes.length,0);
assert.equal(reset2.matched_restaurant_id,null);
await assert.rejects(rpc(a,'vote',old,first,true), error => {
  assert.match(error.message, /round changed/);
  assert.equal(error.code, 'PT409'); // application conflict must not trigger PostgREST's 40001 retry loop
  return true;
});
s=reset2;
for (const restaurant of s.restaurant_ids) {
  await rpc(a,'vote',s.id,restaurant,true);
  s=await rpc(b,'vote',s.id,restaurant,false);
}
assert.equal(s.matched_restaurant_id,null);
s=await rpc(a,'reset',s.id);
console.log('PASS simultaneous rematch retries share one new round, stale requests rejected, disagreement never matches');

await assert.rejects(rpc(outsider), /membership/);
await assert.rejects(rpc(a,'sync',null,null,null,1,other), /membership/);
await assert.rejects(rpc(a,'vote',s.id,ids[10],true), /next card/);
await assert.rejects(rpc(a,'vote',s.id,null,true), /next card/);
await assert.rejects(rpc(a,'vote',s.id,s.restaurant_ids[0],null), /next card/);
await assert.rejects(rpc(a,'bogus'), /Invalid pick/);
await assert.rejects(rpc(a,'sync',null,null,null,9), /Invalid pick/);
await assert.rejects(rpc(''), /membership/);
const audit = await db.query(`select n.nspname, p.prosecdef, p.proconfig from pg_proc p
 join pg_namespace n on n.oid=p.pronamespace where (n.nspname='public' and p.proname='scout_pick')
 or (n.nspname='scout_private' and p.proname='pick_action')`);
assert.equal(audit.rows.find(r=>r.nspname==='public').prosecdef,false);
assert.equal(audit.rows.find(r=>r.nspname==='scout_private').prosecdef,true);
assert(audit.rows.every(r=>r.proconfig.some(c=>c.startsWith('search_path='))));
const policies = await db.query("select relrowsecurity from pg_class where oid in ('public.pick_sessions'::regclass,'public.pick_votes'::regclass)");
assert(policies.rows.length===2 && policies.rows.every(r=>r.relrowsecurity));
await assert.rejects(db.transaction(async tx=>{
 await tx.exec(`set local role authenticated; select set_config('request.jwt.claim.sub','${a}',true)`);
 await tx.exec(`update public.pick_sessions set matched_restaurant_id='${first}'`);
}), /permission denied/);
await assert.rejects(db.transaction(async tx=>{
 await tx.exec(`set local role authenticated; select set_config('request.jwt.claim.sub','${a}',true)`);
 await tx.exec(`insert into public.pick_votes values ('${s.id}','${b}','${s.restaurant_ids[0]}',true)`);
}), /permission denied/);
await db.transaction(async tx=>{
 await tx.exec(`set local role authenticated; select set_config('request.jwt.claim.sub','${outsider}',true)`);
 assert.equal((await tx.query('select * from public.pick_sessions')).rows.length,0);
 assert.equal((await tx.query('select * from public.pick_votes')).rows.length,0);
});
await assert.rejects(db.exec(`set role anon; select public.scout_pick('${circle}');`), /permission denied/);
await db.exec('reset role');
console.log('PASS outsider/other-circle denial, RLS reads, forged partner vote/match writes blocked, anon denial');

// Membership changes invalidate the old round and require all three real members.
await db.exec(`insert into circle_members values ('${circle}','${c}')`);
s=await rpc(c);
assert.equal(s.member_ids.length,3);
assert.equal(s.votes.length,0);
let card=s.restaurant_ids[0];
await rpc(a,'vote',s.id,card,true); s=await rpc(b,'vote',s.id,card,true);
assert.equal(s.matched_restaurant_id,null);
s=await rpc(c,'vote',s.id,card,true);
assert.equal(s.matched_restaurant_id,card);
// A visited/deleted card regenerates the deck; a UTC day rollover drops old matches/votes.
await db.exec(`update restaurants set status='visited' where id='${card}'`);
s=await rpc(a);
assert(!s.restaurant_ids.includes(card)); assert.equal(s.matched_restaurant_id,null);
const beforeDay=s.id;
await db.exec(`update pick_sessions set session_day=session_day-1 where circle_id='${circle}'`);
s=await rpc(b);
assert.notEqual(s.id,beforeDay); assert.equal(s.votes.length,0);
const solo=await rpc(outsider,'sync',null,null,null,1,other);
assert.equal(solo.member_ids.length,1); assert.equal(solo.restaurant_ids.length,0);
await assert.rejects(rpc(outsider,'vote',solo.id,first,true,1,other), /two circle members/);
await db.exec(`delete from circle_members where circle_id='${circle}' and user_id='${b}'`);
await assert.rejects(rpc(b), /membership/);
const afterRemoval=await rpc(a);
assert.equal(afterRemoval.member_ids.length,2); assert.equal(afterRemoval.votes.length,0);
console.log('PASS group unanimity, membership changes/revocation, visited cards, UTC rollover, solo/empty circle');
await db.close();
