import { DatabaseSync } from 'node:sqlite';
import { randomBytes, scryptSync, timingSafeEqual, createHash } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

export const ROLES = ['karyawan', 'manajer', 'kepala_departemen', 'hrd'];
export const STATUSES = ['menunggu_manajer', 'menunggu_kepala', 'menunggu_hrd', 'disetujui', 'ditolak'];
export const now = () => new Date().toISOString();
export const hashToken = (value) => createHash('sha256').update(value).digest('hex');
export function hashPassword(value) {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(value, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}
export function verifyPassword(value, encoded) {
  if (typeof value !== 'string' || typeof encoded !== 'string') return false;
  const [salt, saved] = encoded.split(':');
  if (!salt || !saved || saved.length !== 128) return false;
  const calc = scryptSync(value, salt, 64);
  return timingSafeEqual(Buffer.from(saved, 'hex'), calc);
}
export function createDb(file = process.env.NADI_DB_PATH || resolve('data/nadi.sqlite')) {
  mkdirSync(dirname(file), {recursive:true});
  const db = new DatabaseSync(file);
  db.exec('PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON; PRAGMA busy_timeout=5000;');
  db.exec(`
    CREATE TABLE IF NOT EXISTS departments (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY, employee_id TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE, password_hash TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('karyawan','manajer','kepala_departemen','hrd')),
      department_id INTEGER REFERENCES departments(id), active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS sessions (
      token_hash TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      expires_at TEXT NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS office_locations (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL,
      radius_m REAL NOT NULL CHECK(radius_m BETWEEN 30 AND 5000), updated_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS shifts (
      id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, start_time TEXT NOT NULL, end_time TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS schedules (
      id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id),
      shift_id INTEGER NOT NULL REFERENCES shifts(id), work_date TEXT NOT NULL,
      UNIQUE(user_id, work_date)
    );
    CREATE TABLE IF NOT EXISTS attendance (
      id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id), work_date TEXT NOT NULL,
      check_in_at TEXT NOT NULL, check_in_lat REAL NOT NULL, check_in_lon REAL NOT NULL,
      check_in_accuracy REAL NOT NULL, check_out_at TEXT, check_out_lat REAL,
      check_out_lon REAL, check_out_accuracy REAL, UNIQUE(user_id, work_date)
    );
    CREATE TABLE IF NOT EXISTS requests (
      id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id),
      kind TEXT NOT NULL CHECK(kind IN ('cuti','izin','sakit','lembur')),
      start_date TEXT NOT NULL, end_date TEXT NOT NULL, reason TEXT NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('menunggu_manajer','menunggu_kepala','menunggu_hrd','disetujui','ditolak')),
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS request_approvals (
      id INTEGER PRIMARY KEY, request_id INTEGER NOT NULL REFERENCES requests(id),
      reviewer_id INTEGER NOT NULL REFERENCES users(id), stage TEXT NOT NULL,
      decision TEXT NOT NULL CHECK(decision IN ('setujui','tolak')),
      note TEXT, created_at TEXT NOT NULL,
      UNIQUE(request_id, stage)
    );
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY, actor_id INTEGER REFERENCES users(id), action TEXT NOT NULL,
      entity TEXT NOT NULL, entity_id INTEGER, details TEXT, created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS ix_requests_user ON requests(user_id, created_at);
    CREATE INDEX IF NOT EXISTS ix_requests_status ON requests(status);
    CREATE INDEX IF NOT EXISTS ix_schedule_date ON schedules(work_date);
    CREATE INDEX IF NOT EXISTS ix_attendance_date ON attendance(work_date);
  `);
  // Safe, additive migration for databases created before optional profile photos.
  const cols = db.prepare('PRAGMA table_info(users)').all().map(c => c.name);
  if (!cols.includes('avatar_data')) db.exec('ALTER TABLE users ADD COLUMN avatar_data TEXT');
  return db;
}
export function seedDemo(db) {
  if (db.prepare('SELECT COUNT(*) AS c FROM users').get().c > 0) return;
  const password = process.env.NADI_SEED_PASSWORD || 'NadiDemo!2026';
  const digest = hashPassword(password), t = now();
  // DatabaseSync lacks transaction callbacks in some versions; explicit BEGIN works consistently.
  db.exec('BEGIN');
  try {
    for (const d of ['Quality Control', 'Production', 'Finance', 'Human Resources']) {
      db.prepare('INSERT INTO departments(name) VALUES(?)').run(d);
    }
    const insert = db.prepare('INSERT INTO users(employee_id,name,email,password_hash,role,department_id,created_at) VALUES(?,?,?,?,?,?,?)');
    insert.run('EMP-00042','Raka Pratama','raka@nadi.test',digest,'karyawan',1,t);
    insert.run('MGR-00001','Maya Putri','maya@nadi.test',digest,'manajer',1,t);
    insert.run('HOD-00001','Dimas Arga','dimas@nadi.test',digest,'kepala_departemen',1,t);
    insert.run('HRD-00001','Nadia Safira','nadia@nadi.test',digest,'hrd',4,t);
    insert.run('EMP-00043','Fajar Pratama','fajar@nadi.test',digest,'karyawan',1,t);
    db.prepare('INSERT INTO office_locations(name,latitude,longitude,radius_m,updated_at) VALUES(?,?,?,?,?)')
      .run('Kantor Utama — lokasi contoh', -6.198471, 106.993363, 350, t);
    for (const [name,start,end] of [['Shift Pagi','07:00','15:00'],['Shift Sore','15:00','23:00'],['Shift Malam','23:00','07:00']]) {
      db.prepare('INSERT INTO shifts(name,start_time,end_time) VALUES(?,?,?)').run(name,start,end);
    }
    // Demo schedules for local-day dates; Jakarta-date helper in API handles midnight.
    const today = new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Jakarta',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
    for (const uid of [1,2,3,4,5]) db.prepare('INSERT INTO schedules(user_id,shift_id,work_date) VALUES(?,?,?)').run(uid,1,today);
    db.exec('COMMIT');
  } catch (e) { db.exec('ROLLBACK'); throw e; }
}
export function audit(db, actorId, action, entity, entityId=null, details=null) {
  db.prepare('INSERT INTO audit_logs(actor_id,action,entity,entity_id,details,created_at) VALUES(?,?,?,?,?,?)')
    .run(actorId,action,entity,entityId,details?JSON.stringify(details):null,now());
}
