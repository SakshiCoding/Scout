import fs from 'node:fs';
import assert from 'node:assert/strict';
// Opt-in integration test: use only a dedicated, disposable circle and accounts.
const config=JSON.parse(fs.readFileSync(process.env.SCOUT_PICK_TEST_CONFIG,'utf8'));
assert.equal(config.disposable,true,'Explicit disposable fixture confirmation required');
assert.equal(config.accounts.length,3,'Two circle members and one outsider are required');
const f={circle:config.circleId,users:config.accounts.map(a=>a.userId)};
const key=config.anonKey;
const base=config.url.replace(/\/$/,'');
const tokens=[];
for(let i=0;i<3;i++) {
 const r=await fetch(base+'/auth/v1/token?grant_type=password',{signal:AbortSignal.timeout(20000),method:'POST',headers:{apikey:key,'Content-Type':'application/json'},body:JSON.stringify({email:config.accounts[i].email,password:config.accounts[i].password})});
 const body=await r.json(); assert.equal(r.status,200,body.msg||body.message||body.error); tokens.push(body.access_token);
}
async function request(user,path,body,method='POST') {
 const r=await fetch(base+'/rest/v1/'+path,{signal:AbortSignal.timeout(20000),method,headers:{apikey:key,Authorization:'Bearer '+(tokens[user]||key),'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
 const raw=await r.text(); return {status:r.status,data:raw?JSON.parse(raw):null};
}
async function rpc(user,action='sync',session=null,restaurant=null,yes=null) {
 const r=await request(user,'rpc/scout_pick',{p_circle_id:f.circle,p_action:action,p_session_id:session,p_restaurant_id:restaurant,p_yes:yes,p_window:1});
 assert.equal(r.status,200,JSON.stringify(r.data));return r.data;
}
const events=[];
const socket=new WebSocket(base.replace('https:','wss:')+'/realtime/v1/websocket?apikey='+key+'&vsn=1.0.0');
try {
 await new Promise((resolve,reject)=>{socket.onopen=resolve;socket.onerror=reject;});
 const joined=new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Realtime subscription timeout')),15000);socket.onmessage=e=>{const m=JSON.parse(e.data);if(m.event==='postgres_changes')events.push(m.payload);if(m.event==='system'){console.log('Realtime subscription:',JSON.stringify(m.payload));if(m.payload.status==='ok'){clearTimeout(timer);resolve();}else{clearTimeout(timer);reject(Error(JSON.stringify(m.payload)));}}if(m.event==='phx_reply'&&m.ref==='1'&&m.payload.status!=='ok'){clearTimeout(timer);reject(Error(JSON.stringify(m.payload)));}};});
 socket.send(JSON.stringify({topic:'realtime:scout-pr22',event:'phx_join',ref:'1',payload:{access_token:tokens[1],config:{broadcast:{ack:false,self:false},presence:{key:''},postgres_changes:[{event:'*',schema:'public',table:'pick_sessions',filter:'circle_id=eq.'+f.circle}]}}}));
 await joined;
 console.log('Testing simultaneous initial sync');
 let [a,b]=await Promise.all([rpc(0),rpc(1)]);
 assert.equal(a.id,b.id);assert.deepEqual(a.restaurant_ids,b.restaurant_ids);assert.equal(a.restaurant_ids.length,3);assert.equal(a.votes.length,0,'Start with a fresh disposable round');
 if(process.env.SCOUT_PICK_FIXTURE)fs.writeFileSync(process.env.SCOUT_PICK_FIXTURE,JSON.stringify(a));
 const card=a.restaurant_ids[0];
 a=await rpc(0,'vote',a.id,card,true);assert.equal(a.matched_restaurant_id,null);
 const deadline=Date.now()+15000;while(!events.some(e=>e.data?.record?.revision>=a.revision)&&Date.now()<deadline)await new Promise(r=>setTimeout(r,100));
 assert(events.some(e=>e.data?.record?.revision>=a.revision),'Partner did not receive vote revision over Realtime: '+JSON.stringify(events));
 const same=await rpc(0,'vote',a.id,card,true);assert.equal(same.revision,a.revision);
 a=await rpc(0,'undo',a.id,card);assert.equal(a.votes.length,0);
 const simultaneous=await Promise.all([rpc(0,'vote',a.id,card,true),rpc(1,'vote',a.id,card,true)]);
 b=await rpc(1);assert.equal(b.matched_restaurant_id,card);assert.equal(b.votes.length,2);
 const old=b.id;
 [a,b]=await Promise.all([rpc(0,'reset',old),rpc(1,'reset',old)]);assert.equal(a.id,b.id);assert.notEqual(a.id,old);
 const stale=await request(0,'rpc/scout_pick',{p_circle_id:f.circle,p_action:'vote',p_session_id:old,p_restaurant_id:card,p_yes:true});assert.equal(stale.status,409);assert.equal(stale.data.code,'PT409');
 for(const id of a.restaurant_ids){await rpc(0,'vote',a.id,id,true);b=await rpc(1,'vote',a.id,id,false);}
 assert.equal(b.matched_restaurant_id,null);assert.equal(b.votes.length,6);
 const denied=await request(2,'rpc/scout_pick',{p_circle_id:f.circle});assert.equal(denied.data.code,'42501');
 const invisible=await request(2,'pick_sessions?circle_id=eq.'+f.circle,null,'GET');assert.deepEqual(invisible.data,[]);
 const invisibleVotes=await request(2,'pick_votes?session_id=eq.'+b.id,null,'GET');assert.deepEqual(invisibleVotes.data,[]);
 const forged=await request(0,'pick_votes',{session_id:b.id,user_id:f.users[1],restaurant_id:b.restaurant_ids[0],is_yes:true});assert.equal(forged.data.code,'42501');
 const forgedWinner=await request(0,'pick_sessions?id=eq.'+b.id,{matched_restaurant_id:b.restaurant_ids[0]},'PATCH');assert.equal(forgedWinner.data.code,'42501');
 const anon=await request(9,'rpc/scout_pick',{p_circle_id:f.circle});assert.equal(anon.data.code,'42501');
 console.log('PASS hosted Auth + PostgREST: canonical deck, real member votes, persistence, undo, duplicate retries, concurrent unanimous match, concurrent rematch, stale round denial, disagreement, outsider RLS isolation, forged writes and anonymous RPC denial');
 console.log('PASS hosted WebSocket: partner receives session revision after another member votes');
} finally {socket.close();}
