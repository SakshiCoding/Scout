import fs from 'node:fs';
import assert from 'node:assert/strict';
const config=JSON.parse(fs.readFileSync(process.env.SCOUT_INVITATION_TEST_CONFIG,'utf8'));
assert.equal(config.disposable,true,'Use dedicated disposable accounts and circles only');
assert.equal(config.accounts.length,3);
const base=config.url.replace(/\/$/,'');
const tokens=[];
for(const account of config.accounts) {
  const response=await fetch(base+'/auth/v1/token?grant_type=password',{method:'POST',signal:AbortSignal.timeout(20000),
    headers:{apikey:config.anonKey,'Content-Type':'application/json'},body:JSON.stringify({email:account.email,password:account.password})});
  const data=await response.json();assert.equal(response.status,200,data.msg||data.message||data.error);tokens.push(data.access_token);
}
async function request(user,path,body,method='POST') {
  const response=await fetch(base+'/rest/v1/'+path,{method,signal:AbortSignal.timeout(20000),
    headers:{apikey:config.anonKey,Authorization:'Bearer '+(tokens[user]||config.anonKey),'Content-Type':'application/json'},
    ...(body?{body:JSON.stringify(body)}:{})});
  const text=await response.text();return {status:response.status,data:text?JSON.parse(text):null};
}
async function rpc(user,action,circleId=null,code=null,id=null) {
  return request(user,'rpc/scout_circle_invite',{p_action:action,p_circle_id:circleId,p_code:code,p_invite_id:id,p_initials:'QA'});
}
async function ok(promise) {const r=await promise;assert.equal(r.status,200,JSON.stringify(r.data));return r.data;}
const cid=config.circleId;
assert(!(await ok(request(1,'rpc/scout_my_circles',{}))).some(c=>c.id===cid),'Recipient must start outside the fixture circle');
assert.equal((await rpc(2,'status',cid)).status,403);
assert.equal((await rpc(9,'preview',null,'f'.repeat(32))).status,401);
assert.equal((await ok(rpc(0,'status',cid))).is_active,false);
const before=await ok(request(0,'rpc/scout_pick',{p_circle_id:cid,p_window:1}));
assert.equal(before.member_ids.length,1);
let invite=await ok(rpc(0,'create',cid));
assert.match(invite.code,/^[0-9a-f]{32}$/);
const preview=await ok(rpc(1,'preview',null,invite.code));assert.equal(preview.is_member,false);
assert.equal((await ok(request(0,'rpc/scout_my_circles',{}))).find(c=>c.id===cid).circle_members.length,1);
const [joined,retry]=await Promise.all([ok(rpc(1,'join',null,invite.code)),ok(rpc(1,'join',null,invite.code))]);
assert.equal(joined.circle_id,retry.circle_id);assert.equal(joined.is_member,true);
const circles=await ok(request(1,'rpc/scout_my_circles',{}));
assert.equal(circles.find(c=>c.id===cid).circle_members.length,2);
assert(!circles.some(c=>c.id===config.otherCircleId));
const after=await ok(request(0,'rpc/scout_pick',{p_circle_id:cid,p_window:1}));
assert.equal(after.member_ids.length,2);assert.notEqual(after.id,before.id);
if(process.env.SCOUT_INVITE_FIXTURE)fs.writeFileSync(process.env.SCOUT_INVITE_FIXTURE,JSON.stringify({invite,preview,joined,circles}),{mode:0o600});
assert.equal((await request(1,'circle_invitations?select=*',null,'GET')).status,403);
assert.equal((await request(1,'circle_members',{circle_id:config.otherCircleId,user_id:config.accounts[1].userId,initials:'XX'})).status,403);
assert.equal((await rpc(2,'join',config.otherCircleId,invite.code)).status,400);
const conflict=await rpc(0,'create',cid);assert.equal(conflict.status,409);assert.equal(conflict.data.code,'PT409');
const old=invite;
invite=await ok(rpc(1,'create',cid,null,invite.id));
assert.notEqual(invite.code,old.code);
assert.equal((await rpc(2,'preview',null,old.code)).status,400);
assert.equal((await rpc(0,'revoke',cid,null,old.id)).status,409);
await ok(rpc(1,'revoke',cid,null,invite.id));
assert.equal((await rpc(2,'join',null,invite.code)).status,400);
assert((await ok(request(1,'rpc/scout_my_circles',{}))).some(c=>c.id===cid));
invite=await ok(rpc(0,'create',cid));
if(process.env.SCOUT_INVITE_UI_CODE)fs.writeFileSync(process.env.SCOUT_INVITE_UI_CODE,invite.code,{mode:0o600});
else await ok(rpc(0,'revoke',cid,null,invite.id));
console.log('PASS hosted Auth/PostgREST: member-only management, anonymous denial, preview without membership, concurrent/idempotent acceptance, nested member snapshots, cross-circle/forged-write denial, immediate stale HTTP 409, token rotation/revocation, and shared-pick membership invalidation');
