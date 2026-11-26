import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createDb, seedDemo, hashToken, verifyPassword, hashPassword, now, ROLES, STATUSES, audit } from './database.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const isProd = process.env.NODE_ENV === 'production';
export const jakartaDate = (d=new Date()) => new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Jakarta',year:'numeric',month:'2-digit',day:'2-digit'}).format(d);
const datePattern = /^\d{4}-\d{2}-\d{2}$/;
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const safeUser = u => u && ({id:u.id,employee_id:u.employee_id,name:u.name,email:u.email,role:u.role,department_id:u.department_id,department_name:u.department_name||null,avatar_data:u.avatar_data||null});
const err = (status, message) => Object.assign(new Error(message), {status});
const validDate = v => {
  if(typeof v!=='string'||!datePattern.test(v))return false;
  const d=new Date(`${v}T00:00:00Z`);return !Number.isNaN(d.getTime())&&d.toISOString().startsWith(v);
};
const validateStr = (v,min=1,max=500) => typeof v==='string' && v.trim().length>=min && v.trim().length<=max;
const rad = n => n*Math.PI/180;
export function distanceMeters(a,b,c,d) {
  const dlat=rad(c-a), dlon=rad(d-b);
  const h=Math.sin(dlat/2)**2+Math.cos(rad(a))*Math.cos(rad(c))*Math.sin(dlon/2)**2;
  return 6371000*2*Math.asin(Math.min(1,Math.sqrt(h)));
}
export function assessGeofence(lat,lon,accuracy,office){
  if (![lat,lon,accuracy].every(n=>typeof n==='number'&&Number.isFinite(n)) || Math.abs(lat)>90||Math.abs(lon)>180 || accuracy<0)
    throw err(422,'Koordinat atau akurasi GPS tidak valid');
  const distance=distanceMeters(lat,lon,office.latitude,office.longitude);
  if(accuracy>100) return {allowed:false,reason:'Akurasi GPS terlalu rendah (maksimal 100 m)',distance_m:Math.round(distance)};
  if(distance+accuracy>office.radius_m) return {allowed:false,reason:'Lokasi belum terbukti berada sepenuhnya di area kantor',distance_m:Math.round(distance)};
  return {allowed:true,distance_m:Math.round(distance)};
}
function reply(res,status,body,origin){
  const headers={'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer'};
  if(origin) {headers['Access-Control-Allow-Origin']=origin;headers['Vary']='Origin';headers['Access-Control-Allow-Headers']='Authorization, Content-Type';headers['Access-Control-Allow-Methods']='GET,POST,PATCH,OPTIONS';}
  res.writeHead(status,headers);res.end(JSON.stringify(body));
}
async function bodyJson(req){
  let buff='';
  for await (const chunk of req){buff+=chunk;if(buff.length>1_000_000)throw err(413,'Payload terlalu besar');}
  if(!buff)return {};
  try{const parsed=JSON.parse(buff);if(parsed===null||typeof parsed!=='object'||Array.isArray(parsed))throw Error();return parsed;}
  catch{throw err(400,'JSON tidak valid');}
}
function withUser(db,req){
  const auth=req.headers.authorization||'';
  if(!auth.startsWith('Bearer '))throw err(401,'Sesi belum aktif');
  const token=auth.slice(7);if(token.length<20)throw err(401,'Token tidak valid');
  const user=db.prepare(`SELECT u.*, d.name department_name FROM sessions s JOIN users u ON s.user_id=u.id
    LEFT JOIN departments d ON d.id=u.department_id WHERE s.token_hash=? AND s.expires_at>? AND u.active=1`)
    .get(hashToken(token),now());
  if(!user) throw err(401,'Sesi habis atau tidak valid');
  return user;
}
function requireRole(u,roles){if(!roles.includes(u.role))throw err(403,'Role tidak memiliki izin untuk aksi ini');}
function office(db){return db.prepare('SELECT * FROM office_locations ORDER BY id LIMIT 1').get();}
function joinRequests(db, where='', params=[]){
  return db.prepare(`SELECT r.id,r.user_id,r.kind,r.start_date,r.end_date,r.reason,r.status,r.created_at,r.updated_at,
    u.name employee_name,u.employee_id,u.department_id,u.role employee_role FROM requests r
    JOIN users u ON u.id=r.user_id ${where} ORDER BY r.created_at DESC, r.id DESC`).all(...params);
}
const requestStages = {menunggu_manajer:'manajer',menunggu_kepala:'kepala_departemen',menunggu_hrd:'hrd'};
function canReview(u,request){
  if(u.id===request.user_id) return false;
  if(u.role!=='hrd' && u.department_id !== request.department_id) return false;
  return requestStages[request.status]===u.role;
}
function originAllowed(origin){
  if(!origin)return null;
  const allow=(process.env.CORS_ORIGINS||'').split(',').map(x=>x.trim()).filter(Boolean);
  if(allow.includes(origin))return origin;
  if(!isProd && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin))return origin;
  return null;
}
const queryUser = db => id => db.prepare(`SELECT u.id,u.employee_id,u.name,u.email,u.role,u.department_id,u.avatar_data,d.name department_name
    FROM users u LEFT JOIN departments d ON d.id=u.department_id WHERE u.id=?`).get(id);
export function makeHandler(db){
  const getUser=queryUser(db);
  const attempts=new Map();
  return async (req,res)=>{
    const origin=originAllowed(req.headers.origin);
    if(req.method==='OPTIONS'){
      if(req.headers.origin&&!origin)return reply(res,403,{error:'Origin not allowed'},null);
      return reply(res,204,{},origin);
    }
    const path=new URL(req.url,'http://localhost').pathname.replace(/\/$/,'')||'/';
    try{
      if(req.method==='GET'&&path==='/health')return reply(res,200,{status:'ok',service:'NADI HRIS API',storage:'sqlite'},origin);
      if(req.method==='POST'&&path==='/api/login'){
        const ip=req.socket.remoteAddress||'unknown';
        const throttle=attempts.get(ip)||{n:0,at:Date.now()};
        if(Date.now()-throttle.at>15*60_000){throttle.n=0;throttle.at=Date.now();}
        if(throttle.n>=12)throw err(429,'Terlalu banyak percobaan. Ulangi dalam 15 menit');
        const b=await bodyJson(req);
        if(!validateStr(b.email,3,120)||!validateStr(b.password,1,200))throw err(422,'Email dan kata sandi diperlukan');
        const u=db.prepare('SELECT * FROM users WHERE email=? AND active=1').get(b.email.trim().toLowerCase());
        if(!u||!verifyPassword(b.password,u.password_hash)){
          attempts.set(ip,{n:throttle.n+1,at:throttle.at});throw err(401,'Email atau kata sandi salah');
        }
        attempts.delete(ip);
        const token=randomBytes(32).toString('hex');
        const expires=new Date(Date.now()+12*3600_000).toISOString();
        db.prepare('INSERT INTO sessions(token_hash,user_id,expires_at,created_at) VALUES(?,?,?,?)').run(hashToken(token),u.id,expires,now());
        audit(db,u.id,'login','session');
        return reply(res,200,{token,expires_at:expires,user:safeUser(getUser(u.id))},origin);
      }
      if(!path.startsWith('/api/'))throw err(404,'Endpoint tidak ditemukan');
      const u=withUser(db,req), method=req.method;
      if(path==='/api/logout'&&method==='POST'){
        db.prepare('DELETE FROM sessions WHERE token_hash=?').run(hashToken(req.headers.authorization.slice(7)));
        return reply(res,200,{ok:true},origin);
      }
      if(path==='/api/me'&&method==='GET')return reply(res,200,{user:safeUser(getUser(u.id))},origin);
      if(path==='/api/me/avatar'&&method==='PATCH'){
        const b=await bodyJson(req);
        if(!Object.hasOwn(b,'avatar_data'))throw err(422,'Foto profil wajib diberikan atau dihapus dengan null');
        let data=null;
        if(b.avatar_data!==null){
          if(typeof b.avatar_data!=='string'||b.avatar_data.length>210_000)throw err(422,'Ukuran foto profil terlalu besar');
          const m=/^data:image\/(png|jpeg);base64,([A-Za-z0-9+/]+={0,2})$/.exec(b.avatar_data);
          if(!m||m[2].length%4!==0)throw err(422,'Foto profil harus PNG atau JPEG');
          const bytes=Buffer.from(m[2],'base64');
          if(bytes.length===0||bytes.length>150_000||bytes.toString('base64')!==m[2])throw err(422,'Foto profil maksimal 150 KB');
          const validPng=bytes.length>=8&&bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
          const validJpg=bytes.length>=3&&bytes[0]===255&&bytes[1]===216&&bytes[2]===255;
          if((m[1]==='png'&&!validPng)||(m[1]==='jpeg'&&!validJpg))throw err(422,'Isi file foto tidak sesuai format');
          data=b.avatar_data;
        }
        db.prepare('UPDATE users SET avatar_data=? WHERE id=?').run(data,u.id);
        audit(db,u.id,data?'update_avatar':'delete_avatar','user',u.id);
        return reply(res,200,{user:safeUser(getUser(u.id))},origin);
      }
      if(path==='/api/me/password'&&method==='POST'){
        const b=await bodyJson(req);
        if(!validateStr(b.current_password,1,200)||!validateStr(b.new_password,10,120))
          throw err(422,'Kata sandi lama dan kata sandi baru minimal 10 karakter wajib diisi');
        const current=db.prepare('SELECT password_hash FROM users WHERE id=?').get(u.id);
        if(!verifyPassword(b.current_password,current.password_hash))throw err(403,'Kata sandi lama tidak sesuai');
        if(b.current_password===b.new_password)throw err(422,'Kata sandi baru harus berbeda');
        db.prepare('UPDATE users SET password_hash=? WHERE id=?').run(hashPassword(b.new_password),u.id);
        // Preserve the current session, invalidate other devices.
        db.prepare('DELETE FROM sessions WHERE user_id=? AND token_hash<>?')
          .run(u.id,hashToken(req.headers.authorization.slice(7)));
        audit(db,u.id,'change_password','user',u.id);
        return reply(res,200,{ok:true},origin);
      }
      if(path==='/api/office'&&method==='GET')return reply(res,200,{office:office(db)},origin);
      if(path==='/api/office'&&method==='PATCH'){
        requireRole(u,['hrd']);const b=await bodyJson(req);
        if(!validateStr(b.name,3,120)||!Number.isFinite(b.latitude)||Math.abs(b.latitude)>90||!Number.isFinite(b.longitude)||Math.abs(b.longitude)>180||!Number.isFinite(b.radius_m)||b.radius_m<30||b.radius_m>5000) throw err(422,'Parameter zona tidak valid');
        db.prepare('UPDATE office_locations SET name=?,latitude=?,longitude=?,radius_m=?,updated_at=? WHERE id=?')
          .run(b.name.trim(),b.latitude,b.longitude,b.radius_m,now(),office(db).id);
        audit(db,u.id,'update_office','office',office(db).id);
        return reply(res,200,{office:office(db)},origin);
      }
      if(path==='/api/attendance/today'&&method==='GET'){
        const row=db.prepare('SELECT * FROM attendance WHERE user_id=? AND work_date=?').get(u.id,jakartaDate());
        return reply(res,200,{attendance:row||null},origin);
      }
      if(path==='/api/attendance'&&method==='GET'){
        const rows=db.prepare('SELECT * FROM attendance WHERE user_id=? ORDER BY work_date DESC LIMIT 60').all(u.id);
        return reply(res,200,{attendance:rows},origin);
      }
      if((path==='/api/attendance/check-in'||path==='/api/attendance/check-out')&&method==='POST'){
        const b=await bodyJson(req);const loc=office(db);
        const result=assessGeofence(b.latitude,b.longitude,b.accuracy_m,loc);
        if(!result.allowed)throw err(422,result.reason+` (perkiraan jarak ${result.distance_m} m)`);
        const today=jakartaDate();
        const current=db.prepare('SELECT * FROM attendance WHERE user_id=? AND work_date=?').get(u.id,today);
        if(path.endsWith('check-in')){
          if(current)throw err(409,'Sudah check-in hari ini');
          const r=db.prepare('INSERT INTO attendance(user_id,work_date,check_in_at,check_in_lat,check_in_lon,check_in_accuracy) VALUES(?,?,?,?,?,?)')
            .run(u.id,today,now(),b.latitude,b.longitude,b.accuracy_m);
          audit(db,u.id,'check_in','attendance',Number(r.lastInsertRowid),result);
        }else{
          if(!current)throw err(409,'Belum melakukan check-in hari ini');
          if(current.check_out_at)throw err(409,'Sudah check-out hari ini');
          db.prepare('UPDATE attendance SET check_out_at=?,check_out_lat=?,check_out_lon=?,check_out_accuracy=? WHERE id=?')
            .run(now(),b.latitude,b.longitude,b.accuracy_m,current.id);
          audit(db,u.id,'check_out','attendance',current.id,result);
        }
        return reply(res,200,{attendance:db.prepare('SELECT * FROM attendance WHERE user_id=? AND work_date=?').get(u.id,today),geofence:result},origin);
      }
      if(path==='/api/requests'&&method==='GET')return reply(res,200,{requests:joinRequests(db,'WHERE r.user_id=?',[u.id])},origin);
      if(path==='/api/requests'&&method==='POST'){
        const b=await bodyJson(req);
        if(!['cuti','izin','sakit','lembur'].includes(b.kind)||!validDate(b.start_date)||!validDate(b.end_date)||b.start_date>b.end_date||!validateStr(b.reason,8,1000))
          throw err(422,'Jenis, tanggal, atau alasan pengajuan belum valid');
        if(b.start_date<'2020-01-01'||b.end_date>'2100-01-01')throw err(422,'Tanggal di luar rentang');
        // A manager's own request skips manager stage; a dept head's own request cannot be self-approved.
        if(u.role==='hrd')throw err(403,'Pengajuan HRD memerlukan alur atasan HRD tersendiri yang belum ditetapkan');
        const status=u.role==='manajer'?'menunggu_kepala':u.role==='kepala_departemen'?'menunggu_hrd':'menunggu_manajer';
        const t=now();const r=db.prepare('INSERT INTO requests(user_id,kind,start_date,end_date,reason,status,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?)')
          .run(u.id,b.kind,b.start_date,b.end_date,b.reason.trim(),status,t,t);
        audit(db,u.id,'create_request','request',Number(r.lastInsertRowid));
        return reply(res,201,{request:joinRequests(db,'WHERE r.id=?',[Number(r.lastInsertRowid)])[0]},origin);
      }
      if(path==='/api/approvals'&&method==='GET'){
        requireRole(u,['manajer','kepala_departemen','hrd']);
        const rows=u.role==='hrd' ? joinRequests(db,'WHERE r.status=? AND r.user_id<>?', ['menunggu_hrd',u.id])
          : joinRequests(db,'WHERE r.status=? AND u.department_id=? AND r.user_id<>?',
            [u.role==='manajer'?'menunggu_manajer':'menunggu_kepala',u.department_id,u.id]);
        return reply(res,200,{requests:rows},origin);
      }
      const approval=path.match(/^\/api\/requests\/(\d+)\/(approve|reject)$/);
      if(approval&&method==='POST'){
        requireRole(u,['manajer','kepala_departemen','hrd']);
        const rid=Number(approval[1]), b=await bodyJson(req);
        const row=joinRequests(db,'WHERE r.id=?',[rid])[0];if(!row)throw err(404,'Pengajuan tidak ditemukan');
        if(!canReview(u,row))throw err(403,'Tidak berwenang memutuskan permohonan ini');
        if(b.note!==undefined&&!validateStr(b.note,0,500))throw err(422,'Catatan maksimal 500 karakter');
        const status=approval[2]==='reject'?'ditolak':u.role==='manajer'?'menunggu_kepala':'disetujui';
        // Conditional update prevents double-approval at the same stage.
        db.exec('BEGIN IMMEDIATE');
        try {
          const r=db.prepare('UPDATE requests SET status=?,updated_at=? WHERE id=? AND status=?').run(status,now(),rid,row.status);
          if(r.changes!==1)throw err(409,'Status permohonan sudah berubah, segarkan daftar');
          db.prepare('INSERT INTO request_approvals(request_id,reviewer_id,stage,decision,note,created_at) VALUES(?,?,?,?,?,?)')
            .run(rid,u.id,u.role,approval[2]==='reject'?'tolak':'setujui',b.note||'',now());
          audit(db,u.id,approval[2],'request',rid,{new_status:status});
          db.exec('COMMIT');
        } catch(e) {db.exec('ROLLBACK');throw e;}
        return reply(res,200,{request:joinRequests(db,'WHERE r.id=?',[rid])[0]},origin);
      }
      if(path==='/api/schedules'&&method==='GET'){
        const rows=db.prepare(`SELECT sc.id,sc.user_id,sc.work_date,s.name shift_name,s.start_time,s.end_time
          FROM schedules sc JOIN shifts s ON sc.shift_id=s.id WHERE sc.user_id=? AND sc.work_date>=? AND sc.work_date<=? ORDER BY work_date`)
          .all(u.id,validDate(new URL(req.url,'http://localhost').searchParams.get('from'))?new URL(req.url,'http://localhost').searchParams.get('from'):'2000-01-01',
            validDate(new URL(req.url,'http://localhost').searchParams.get('to'))?new URL(req.url,'http://localhost').searchParams.get('to'):'2100-01-01');
        return reply(res,200,{schedules:rows},origin);
      }
      if(path==='/api/shifts'&&method==='GET')return reply(res,200,{shifts:db.prepare('SELECT * FROM shifts ORDER BY id').all()},origin);
      if(path==='/api/schedules/assign'&&method==='POST'){
        requireRole(u,['hrd']);const b=await bodyJson(req);
        if(!Number.isInteger(b.user_id)||!Number.isInteger(b.shift_id)||!validDate(b.work_date))throw err(422,'User, shift, dan tanggal wajib valid');
        if(!db.prepare('SELECT id FROM users WHERE id=? AND active=1').get(b.user_id)||!db.prepare('SELECT id FROM shifts WHERE id=?').get(b.shift_id)) throw err(404,'User atau shift tidak ditemukan');
        db.prepare('INSERT INTO schedules(user_id,shift_id,work_date) VALUES(?,?,?) ON CONFLICT(user_id,work_date) DO UPDATE SET shift_id=excluded.shift_id')
          .run(b.user_id,b.shift_id,b.work_date);
        audit(db,u.id,'assign_shift','schedule',b.user_id,{date:b.work_date,shift_id:b.shift_id});
        return reply(res,200,{ok:true},origin);
      }
      if(path==='/api/staff'&&method==='GET'){
        requireRole(u,['hrd','manajer','kepala_departemen']);
        const all=db.prepare('SELECT u.id,u.name,u.employee_id,u.email,u.role,u.department_id,u.active,d.name department_name FROM users u LEFT JOIN departments d ON d.id=u.department_id WHERE (? = 1 OR u.department_id=?) ORDER BY u.name')
          .all(u.role==='hrd'?1:0,u.department_id);
        return reply(res,200,{staff:all},origin);
      }
      if(path==='/api/staff'&&method==='POST'){
        requireRole(u,['hrd']);const b=await bodyJson(req);
        if(!validateStr(b.employee_id,3,30)||!validateStr(b.name,3,120)||!emailPattern.test(b.email||'')||!ROLES.includes(b.role)||!Number.isInteger(b.department_id)||!validateStr(b.password,10,120)) throw err(422,'Data karyawan tidak valid (password minimal 10 karakter)');
        if(!db.prepare('SELECT id FROM departments WHERE id=?').get(b.department_id))throw err(422,'Departemen tidak tersedia');
        try{
          const r=db.prepare('INSERT INTO users(employee_id,name,email,password_hash,role,department_id,created_at) VALUES(?,?,?,?,?,?,?)')
            .run(b.employee_id.trim(),b.name.trim(),b.email.trim().toLowerCase(),hashPassword(b.password),b.role,b.department_id,now());
          audit(db,u.id,'create_staff','user',Number(r.lastInsertRowid));return reply(res,201,{user:safeUser(getUser(Number(r.lastInsertRowid)))},origin);
        }catch(e){if(e.message.includes('UNIQUE'))throw err(409,'ID atau email sudah dipakai');throw e;}
      }
      if(path==='/api/dashboard'&&method==='GET'){
        const count=db.prepare('SELECT COUNT(*) n FROM users WHERE active=1').get().n;
        const pending=db.prepare('SELECT COUNT(*) n FROM requests WHERE status IN (?,?,?)').get('menunggu_manajer','menunggu_kepala','menunggu_hrd').n;
        const attendance=db.prepare('SELECT COUNT(*) n FROM attendance WHERE work_date=?').get(jakartaDate()).n;
        const deps=db.prepare('SELECT COUNT(*) n FROM departments').get().n;
        return reply(res,200,{stats:{active_staff:u.role==='hrd'?count:null,departments:u.role==='hrd'?deps:null,pending_requests:pending,attendance_today:attendance},today:jakartaDate()},origin);
      }
      if(path==='/api/audit'&&method==='GET'){
        requireRole(u,['hrd']);return reply(res,200,{logs:db.prepare('SELECT id,actor_id,action,entity,entity_id,created_at FROM audit_logs ORDER BY id DESC LIMIT 200').all()},origin);
      }
      throw err(404,'Endpoint tidak ditemukan');
    }catch(e){const status=e.status||500;if(status>=500)console.error('API internal error:',e);reply(res,status,{error:status>=500?'Kesalahan server internal':e.message},origin);}
  };
}
export function start({port=Number(process.env.NADI_PORT||3000),dbFile=process.env.NADI_DB_PATH||resolve(ROOT,'data/nadi.sqlite')}={}) {
  if(isProd && process.env.NADI_DEMO_SEED==='1')throw new Error('Demo seeding dilarang pada production');
  const db=createDb(dbFile);
  if(!isProd && process.env.NADI_DEMO_SEED!=='0') seedDemo(db);
  const server=http.createServer(makeHandler(db));
  const host=process.env.NADI_HOST||'127.0.0.1';
  return new Promise(resolveStart=>server.listen(port,host,()=>resolveStart({server,db,host,port:server.address().port})));
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  start().then(({port,host})=>console.log(`NADI local API listening at http://${host}:${port} (NODE_ENV=${process.env.NODE_ENV||'development'})`)).catch(e=>{console.error(e);process.exit(1)});
}
