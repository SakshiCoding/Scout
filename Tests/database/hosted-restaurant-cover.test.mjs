import assert from 'node:assert/strict';
import fs from 'node:fs';
import { randomUUID } from 'node:crypto';

const configPath = process.env.SCOUT_COVER_TEST_CONFIG;
assert(configPath, 'Set SCOUT_COVER_TEST_CONFIG to a private disposable-fixture JSON file');
const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
assert.equal(config.disposable, true, 'Only disposable test circles/accounts are allowed');
for (const key of ['url', 'anonKey', 'circleId', 'restaurantId', 'visitId', 'photoFile', 'owner', 'outsider']) {
  assert(config[key], `Missing ${key}`);
}
assert.notEqual(config.owner.userId, config.outsider.userId);
for (const account of [config.owner, config.outsider]) {
  assert(account.email.startsWith('scout-cover-') && account.email.endsWith('@example.com'),
    'Use reserved scout-cover- fixture accounts only');
}
const mediaId = randomUUID();
const path = `circles/${config.circleId}/visits/${config.visitId}/${mediaId}.jpg`;
const sessions = [];
const uploadedPaths = [];
let inserted = false;
async function request(route, token, options = {}) {
  const response = await fetch(config.url + route, {
    ...options,
    headers: { apikey: config.anonKey, ...(token ? { Authorization: `Bearer ${token}` } : {}), ...options.headers },
    signal: AbortSignal.timeout(20_000)
  });
  return response;
}
async function login(account) {
  const response = await request('/auth/v1/token?grant_type=password', null, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: account.email, password: account.password })
  });
  assert.equal(response.status, 200, `Fixture login failed (${response.status})`);
  const session = await response.json();
  sessions.push(session.access_token);
  assert.equal(session.user.id, account.userId);
  return session.access_token;
}
try {
  const owner = await login(config.owner);
  const outsider = await login(config.outsider);
  const bytes = fs.readFileSync(config.photoFile);
  const upload = await request(`/storage/v1/object/scout-media/${path}`, owner, {
    method: 'POST', headers: { 'Content-Type': 'image/jpeg' }, body: bytes
  });
  if (!upload.ok) {
    const error = await upload.json().catch(() => ({}));
    assert.fail(`Fixture upload failed (${upload.status}): ${String(error.message ?? error.error ?? 'unknown error')}`);
  }
  uploadedPaths.push(path);
  const insert = await request('/rest/v1/media', owner, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: mediaId, restaurant_id: config.restaurantId, visit_id: config.visitId,
      circle_id: config.circleId, user_id: config.owner.userId, storage_path: path, media_type: 'photo' })
  });
  assert(insert.ok, `Fixture media insert failed (${insert.status})`);
  inserted = true;
  const route = `/rest/v1/media?circle_id=eq.${config.circleId}&select=*`;
  const media = await request(route, owner);
  assert.equal(media.status, 200);
  const photos = await media.json();
  assert.equal(photos.length, 1);
  assert.equal(photos[0].id, mediaId);
  const download = await request(`/storage/v1/object/authenticated/scout-media/${path}`, owner);
  assert.equal(download.status, 200);
  const downloaded = Buffer.from(await download.arrayBuffer());
  assert.deepEqual(downloaded, bytes);
  const outsideRows = await request(route, outsider);
  assert.equal(outsideRows.status, 200);
  assert.deepEqual(await outsideRows.json(), []);
  for (const [label, token] of [['outsider', outsider], ['anonymous', null]]) {
    const denied = await request(`/storage/v1/object/authenticated/scout-media/${path}`, token);
    assert([400, 401, 403, 404].includes(denied.status), `Private photo not denied to ${label} (${denied.status})`);
    const forgedPath = path.replace('.jpg', `-${label}.jpg`);
    const forged = await request(`/storage/v1/object/scout-media/${forgedPath}`, token, {
      method: 'POST', headers: { 'Content-Type': 'image/jpeg' }, body: bytes
    });
    if (forged.ok) uploadedPaths.push(forgedPath);
    assert([400, 401, 403, 404].includes(forged.status), `Private upload not denied to ${label} (${forged.status})`);
  }
  const publicDownload = await request(`/storage/v1/object/public/scout-media/${path}`, null);
  assert([400, 401, 403, 404].includes(publicDownload.status), 'Private object became publicly readable');
  if (process.env.SCOUT_COVER_FIXTURE) {
    const fixtureFile = process.env.SCOUT_COVER_FIXTURE;
    const downloadedFile = fixtureFile + '.jpg';
    fs.writeFileSync(downloadedFile, downloaded, { mode: 0o600 });
    fs.writeFileSync(fixtureFile, JSON.stringify({ circleId: config.circleId, restaurantId: config.restaurantId,
      photos, photoPath: path, downloadedFile }), { mode: 0o600 });
  }
  console.log('PASS hosted Auth/private Storage: owner upload/media read/photo download, identical bytes, outsider metadata isolation, outsider/anonymous upload+download denial and public URL denial');
} finally {
  const owner = sessions[0];
  const cleanup = [];
  if (owner && inserted) {
    cleanup.push(request(`/rest/v1/media?id=eq.${mediaId}`, owner, { method: 'DELETE' })
      .then(removed => assert(removed.ok, `Fixture media cleanup failed (${removed.status})`)));
  }
  if (owner && uploadedPaths.length) {
    cleanup.push(request('/storage/v1/object/scout-media', owner, {
      method: 'DELETE', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ prefixes: uploadedPaths })
    }).then(removed => assert(removed.ok, `Fixture object cleanup failed (${removed.status})`)));
  }
  const results = await Promise.allSettled(cleanup);
  const signouts = await Promise.allSettled(sessions.map(async token => {
    const ended = await request('/auth/v1/logout', token, { method: 'POST' });
    assert(ended.ok, `Fixture sign-out failed (${ended.status})`);
  }));
  const failures = [...results, ...signouts].filter(result => result.status === 'rejected');
  if (failures.length) throw new AggregateError(failures.map(result => result.reason), 'Fixture cleanup failed');
}
