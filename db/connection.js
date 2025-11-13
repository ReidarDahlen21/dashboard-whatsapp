import 'dotenv/config';
import sql from 'mssql';

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,        // p.ej. "localhost" o "localhost\\SQLEXPRESS"
  database: process.env.DB_DATABASE,
  port: Number(process.env.DB_PORT || 1433),
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',           // Azure: true
    trustServerCertificate: process.env.DB_TRUST_CERT !== 'false', // local: true
  },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

let pool;
export async function getPool() {
  if (pool) return pool;
  pool = await sql.connect(config);
  return pool;
}

export { sql };
