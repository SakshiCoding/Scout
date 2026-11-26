import assert from 'node:assert/strict';
import fs from 'node:fs';
import { randomUUID } from 'node:crypto';
const configPath = process.env.SCOUT_UPLOAD_TEST_CONFIG;
assert(configPath, 'Set SCOUT_UPLOAD_TEST_CONFIG to a private disposable fixture JSON');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
assert.equal(config.disposable, true);
assert(config.files?.length >= 3, 'Provide real JPEG and native video fixtures');
for (const account of [config.owner, config.outsider]) {
  assert(account.email.startsWith('scout-cover-') && account.email.endsWith('@example.com'));
}
assert.notEqual(config.owner.userId, config.outsider.userId);
const sessions = [], paths = [], mediaIds = [];
async function request(route, token, options = {}) {
  return fetch(config.url + route, {...options,
    headers: { apikey: config.anonKey, ...(token ? {Authorization: `Bearer ${token}`} : {}), ...options.headers },
    signal: AbortSignal.timeout(60_000)});
}
async function login(account) {
  const response = await request('/auth/v1/token?grant_type=password', null, {
    method:'POST', headers:{'Content-Type':'application/json'},
    body:JSON.stringify({email:account.email,password:account.password})});
  assert.equal(response.status,200,`Fixture login failed (${response.status})`);
  const data = await response.json();
  sessions.push(data.access_token);
  assert.equal(data.user.id,account.userId);
  return data.access_token;
}
try {
  const owner = await login(config.owner), outsider = await login(config.outsider);
  for (const fixture of config.files) {
    const bytes = fs.readFileSync(fixture.file), id = randomUUID();
    assert(bytes.length > 100 && bytes.length < 50*1024*1024);
    assert(['jpg','png','heic','heif','mov','mp4','m4v'].includes(fixture.ext));
    const path = `circles/${config.circleId}/visits/${config.visitId}/${id}.${fixture.ext}`;
    const upload = await request(`/storage/v1/object/scout-media/${path}`,owner,{
      method:'POST',headers:{'Content-Type':fixture.mime},body:bytes});
    assert(upload.ok,`Owner ${fixture.ext} upload failed (${upload.status})`);
    paths.push(path);
    const insert = await request('/rest/v1/media',owner,{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({id,restaurant_id:config.restaurantId,visit_id:config.visitId,circle_id:config.circleId,
        user_id:config.owner.userId,storage_path:path,media_type:fixture.mediaType})});
    assert(insert.ok,`Media metadata insert failed (${insert.status})`);
    mediaIds.push(id);
    const download = await request(`/storage/v1/object/authenticated/scout-media/${path}`,owner);
    assert.equal(download.status,200);
    assert.deepEqual(Buffer.from(await download.arrayBuffer()),bytes);
    for (const [label,token] of [['outsider',outsider],['anonymous',null]]) {
      const denied = await request(`/storage/v1/object/authenticated/scout-media/${path}`,token);
      assert([400,401,403,404].includes(denied.status),`${label} downloaded ${fixture.ext}`);
      const forged = path.replace(`.${fixture.ext}`,`-${label}.${fixture.ext}`);
      const deniedUpload = await request(`/storage/v1/object/scout-media/${forged}`,token,{
        method:'POST',headers:{'Content-Type':fixture.mime},body:bytes});
      if (deniedUpload.ok) paths.push(forged);
      assert([400,401,403,404].includes(deniedUpload.status),`${label} uploaded ${fixture.ext}`);
    }
    const publicRead = await request(`/storage/v1/object/public/scout-media/${path}`,null);
    assert([400,401,403,404].includes(publicRead.status));
    console.log(`PASS hosted ${fixture.ext}: upload, metadata, exact download bytes, outsider/anonymous read+write denial, private URL`);
  }
  const rowsRoute = `/rest/v1/media?circle_id=eq.${config.circleId}&select=id,media_type`;
  const owned = await request(rowsRoute,owner);
  assert.equal((await owned.json()).length,mediaIds.length);
  const forbidden = await request(rowsRoute,outsider);
  assert.deepEqual(await forbidden.json(),[]);
  for (const [label,mime,bytes] of [
    ['unsupported','application/pdf',Buffer.from('%PDF-1.7 fixture')],
    ['oversized','video/mp4',Buffer.alloc(50*1024*1024+1)]]) {
    const path = `circles/${config.circleId}/visits/${config.visitId}/${randomUUID()}.mp4`;
    const response = await request(`/storage/v1/object/scout-media/${path}`,owner,{
      method:'POST',headers:{'Content-Type':mime},body:bytes});
    if (response.ok) paths.push(path);
    const error = await response.json().catch(()=>({}));
    assert(!response.ok,`${label} upload unexpectedly succeeded`);
    const code = String(error.statusCode ?? response.status);
    assert(['400','413','415'].includes(code),`${label} rejected for unexpected reason (${code})`);
    console.log(`PASS hosted ${label} bucket rejection`);
  }
} finally {
  const owner = sessions[0], failures=[];
  if (owner && mediaIds.length) {
    const response = await request(`/rest/v1/media?id=in.(${mediaIds.join(',')})`,owner,{method:'DELETE'});
    if (!response.ok) failures.push('media cleanup');
  }
  if (owner && paths.length) {
    const response = await request('/storage/v1/object/scout-media',owner,{method:'DELETE',
      headers:{'Content-Type':'application/json'},body:JSON.stringify({prefixes:paths})});
    if (!response.ok) failures.push('object cleanup');
  }
  for (const token of sessions) {
    const response=await request('/auth/v1/logout',token,{method:'POST'});
    if (!response.ok) failures.push('session cleanup');
  }
  assert.equal(failures.length,0,failures.join(', '));
}
