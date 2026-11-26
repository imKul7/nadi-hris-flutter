import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {start} from '../src/server.mjs';
import {assessGeofence,distanceMeters} from '../src/server.mjs';

let server,db,url,dir;
const pw=process.env.NADI_SEED_PASSWORD||'NadiDemo!2026';
const json=async(r)=>({...await r.json(),status:r.status});
async function request(method,path,token,body){return json(await fetch(url+path,{method,headers:{...(token?{Authorization:'Bearer '+token}:{}),...(body?{'Content-Type':'application/json'}:{})},body:body?JSON.stringify(body):undefined}));}
async function login(email){const r=await request('POST','/api/login',null,{email,password:pw});assert.equal(r.status,200,r.error);return r.token;}

test.before(async()=>{
  dir=mkdtempSync(join(tmpdir(),'nadi-test-'));
  const s=await start({port:0,dbFile:join(dir,'nadi.sqlite')});server=s.server;db=s.db;url='http://127.0.0.1:'+s.port;
});
test.after(async()=>{await new Promise(done=>server.close(done));db.close();rmSync(dir,{recursive:true,force:true});});

test('service health and protected endpoints',async()=>{
 assert.equal((await request('GET','/health')).status,200);
 assert.equal((await request('GET','/api/me')).status,401);
 assert.equal((await request('POST','/api/login',null,{email:'wrong@nadi.test',password:'wrong'})).status,401);
});
test('authentication and four roles',async()=>{
 for(const [email,role] of [['raka@nadi.test','karyawan'],['maya@nadi.test','manajer'],['dimas@nadi.test','kepala_departemen'],['nadia@nadi.test','hrd']]){
   const token=await login(email);const me=await request('GET','/api/me',token);
   assert.equal(me.user.role,role);assert.equal(me.user.password_hash,undefined);
 }
});
test('Haversine and GPS bounds are conservative',async()=>{
 const loc={latitude:-6.198471,longitude:106.993363,radius_m:350};
 assert.equal(assessGeofence(loc.latitude,loc.longitude,10,loc).allowed,true);
 assert.equal(assessGeofence(loc.latitude,loc.longitude,120,loc).allowed,false);
 assert.equal(assessGeofence(-6.23,107,8,loc).allowed,false);
 assert.ok(distanceMeters(-6.198471,106.993363,-6.198471,106.993363)<0.01);
 assert.throws(()=>assessGeofence(999,0,2,loc));
});
test('employee: request approval two stages; cannot approve own or other scope',async()=>{
 const employee=await login('raka@nadi.test'), manager=await login('maya@nadi.test'), head=await login('dimas@nadi.test'),hrd=await login('nadia@nadi.test');
 const created=await request('POST','/api/requests',employee,{kind:'cuti',start_date:'2026-12-02',end_date:'2026-12-03',reason:'Keperluan keluarga'});
 assert.equal(created.status,201);assert.equal(created.request.status,'menunggu_manajer');
 const id=created.request.id;
 assert.equal((await request('POST',`/api/requests/${id}/approve`,employee,{})).status,403);
 assert.equal((await request('POST',`/api/requests/${id}/approve`,head,{})).status,403);
 assert.equal((await request('POST',`/api/requests/${id}/approve`,hrd,{})).status,403);
 assert.equal((await request('GET','/api/approvals',manager)).requests.length,1);
 assert.equal((await request('POST',`/api/requests/${id}/approve`,manager,{note:'Disetujui tahap 1'})).request.status,'menunggu_kepala');
 assert.equal((await request('POST',`/api/requests/${id}/approve`,manager,{})).status,403);
 assert.equal((await request('POST',`/api/requests/${id}/approve`,head,{})).request.status,'disetujui');
 assert.equal((await request('GET','/api/requests',employee)).requests[0].status,'disetujui');
});
test('attendance rejects inaccurate or out-of-area GPS, accepts legitimate coordinates',async()=>{
 const employee=await login('raka@nadi.test');
 assert.equal((await request('POST','/api/attendance/check-in',employee,{latitude:0,longitude:0,accuracy_m:5})).status,422);
 assert.equal((await request('POST','/api/attendance/check-in',employee,{latitude:-6.198471,longitude:106.993363,accuracy_m:140})).status,422);
 const r=await request('POST','/api/attendance/check-in',employee,{latitude:-6.198471,longitude:106.993363,accuracy_m:8});
 assert.equal(r.status,200,r.error);assert.equal(r.attendance.check_out_at,null);
 assert.equal((await request('POST','/api/attendance/check-in',employee,{latitude:-6.198471,longitude:106.993363,accuracy_m:8})).status,409);
 const out=await request('POST','/api/attendance/check-out',employee,{latitude:-6.198471,longitude:106.993363,accuracy_m:8});
 assert.equal(out.status,200);assert.ok(out.attendance.check_out_at);
});
test('HRD can assign schedules and create staff; employee cannot',async()=>{
 const hrd=await login('nadia@nadi.test'), employee=await login('raka@nadi.test');
 assert.equal((await request('GET','/api/staff',employee)).status,403);
 const created=await request('POST','/api/staff',hrd,{employee_id:'EMP-00999',name:'Salsa Demo',email:'salsa@nadi.test',password:'passwordSementara12',role:'karyawan',department_id:1});
 assert.equal(created.status,201,created.error);
 assert.equal((await request('POST','/api/schedules/assign',employee,{user_id:created.user.id,shift_id:1,work_date:'2026-12-01'})).status,403);
 assert.equal((await request('POST','/api/schedules/assign',hrd,{user_id:created.user.id,shift_id:1,work_date:'2026-12-01'})).status,200);
 assert.equal((await request('GET','/api/audit',hrd)).status,200);
});
test('logout invalidates token',async()=>{
 const token=await login('raka@nadi.test');
 assert.equal((await request('POST','/api/logout',token,{})).status,200);
 assert.equal((await request('GET','/api/me',token)).status,401);
});
test('department head requests require HRD, and invalid dates are rejected',async()=>{
 const head=await login('dimas@nadi.test'),hrd=await login('nadia@nadi.test');
 const invalid=await request('POST','/api/requests',head,{kind:'cuti',start_date:'2026-02-30',end_date:'2026-03-02',reason:'Keperluan pribadi'});
 assert.equal(invalid.status,422);
 const created=await request('POST','/api/requests',head,{kind:'izin',start_date:'2026-12-04',end_date:'2026-12-04',reason:'Kepentingan pribadi'});
 assert.equal(created.status,201);
 assert.equal(created.request.status,'menunggu_hrd');
 const approved=await request('POST',`/api/requests/${created.request.id}/approve`,hrd,{});
 assert.equal(approved.status,200);assert.equal(approved.request.status,'disetujui');
 assert.equal((await request('POST','/api/requests',hrd,{kind:'cuti',start_date:'2026-12-05',end_date:'2026-12-05',reason:'Keperluan pribadi'})).status,403);
});

test('optional profile avatar: upload, read after login, reject invalid image, remove',async()=>{
  const employee=await login('fajar@nadi.test');
  const data='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg==';
  const first=await request('PATCH','/api/me/avatar',employee,{avatar_data:data});
  assert.equal(first.status,200,first.error);
  assert.equal(first.user.avatar_data,data);
  const another=await login('fajar@nadi.test');
  assert.equal((await request('GET','/api/me',another)).user.avatar_data,data);
  assert.equal((await request('PATCH','/api/me/avatar',employee,{avatar_data:'data:image/svg+xml;base64,PHN2Zz4='})).status,422);
  assert.equal((await request('PATCH','/api/me/avatar',employee,{avatar_data:'data:image/png;base64,YWJjZA=='})).status,422);
  assert.equal((await request('PATCH','/api/me/avatar',employee,{avatar_data:'data:image/png;base64,'+'A'.repeat(200004)})).status,422);
  assert.equal((await request('PATCH','/api/me/avatar',null,{avatar_data:data})).status,401);
  const removed=await request('PATCH','/api/me/avatar',employee,{avatar_data:null});
  assert.equal(removed.status,200,removed.error);
  assert.equal(removed.user.avatar_data,null);
  assert.equal((await request('GET','/api/me',another)).user.avatar_data,null);
});

test('account password update requires old password, keeps current session',async()=>{
  const token=await login('fajar@nadi.test');
  assert.equal((await request('POST','/api/me/password',token,{current_password:'wrong',new_password:'NewSecurePass!2026'})).status,403);
  assert.equal((await request('POST','/api/me/password',token,{current_password:pw,new_password:'short'})).status,422);
  const updated=await request('POST','/api/me/password',token,{current_password:pw,new_password:'NewSecurePass!2026'});
  assert.equal(updated.status,200,updated.error);
  assert.equal((await request('GET','/api/me',token)).status,200);
  assert.equal((await request('POST','/api/login',null,{email:'fajar@nadi.test',password:pw})).status,401);
  assert.equal((await request('POST','/api/login',null,{email:'fajar@nadi.test',password:'NewSecurePass!2026'})).status,200);
});
