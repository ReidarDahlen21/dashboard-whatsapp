import { Router } from 'express';
import { getPool } from '../db/connection.js';
const router = Router();

router.get('/db', async (_req, res) => {
  try {
    const pool = await getPool();
    const r = await pool.request().query('SELECT GETDATE() as now');
    res.json({ ok: true, now: r.recordset[0].now });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

export default router;
