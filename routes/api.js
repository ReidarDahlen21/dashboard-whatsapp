import { Router } from "express";
import { getPool, sql } from "../db/connection.js";

const router = Router();

router.get("/ultimos7", async (req, res) => {
  try {
    const allowed = new Set(["total", "_1p", "_2p", "_3p"]);
    const motivo = allowed.has((req.query.motivo || "total")) ? req.query.motivo : "total";
    const dias = Math.max(1, Math.min(60, parseInt(req.query.dias || "7", 10)));

    const pool = await getPool();
    const r = await pool.request()
      .input("AsOfDate", sql.Date, null)
      .input("Motivo", sql.NVarChar, motivo)
       .input("DaysBack", sql.Int, dias)
      .execute("dbo.usp_Dashboard_EnvioUltimos7");

    const data = r.recordsets?.[0] || [];
    const avg  = r.recordsets?.[1]?.[0] || null;

    res.json({ ok: true, data, avg });
  } catch (e) {
    console.error("GET /api/ultimos7", e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

router.get("/detalle", async (req, res) => {
  try {
    const allowed = new Set(["total", "_1p", "_2p", "_3p"]);
    const motivo = allowed.has((req.query.motivo || "total")) ? req.query.motivo : "total";
    const dias = Math.max(1, Math.min(60, parseInt(req.query.dias || "10", 10)));
    const page = Math.max(1, parseInt(req.query.page || "1", 10));
    const pageSize = Math.max(1, Math.min(2000, parseInt(req.query.pageSize || "200", 10)));

    const pool = await getPool();
    const r = await pool.request()
      .input("AsOfDate", sql.Date, null)
      .input("Motivo", sql.NVarChar, motivo)
      .input("DaysBack", sql.Int, dias)
      .input("Page", sql.Int, page)
      .input("PageSize", sql.Int, pageSize)
      .execute("dbo.usp_Dashboard_DetalleIntradiario");

    const rows = r.recordsets?.[0] || [];
    const total = r.recordsets?.[1]?.[0]?.total || 0;

    res.json({ ok: true, data: rows, total, page, pageSize });
  } catch (e) {
    console.error("GET /api/detalle", e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

router.get("/busqueda", async (req, res) => {
  try {
    const term = (req.query.term || "").trim();
    if (!term) return res.json({ ok: true, data: [] });

    const pool = await getPool();
    const r = await pool.request()
      .input("Term", sql.NVarChar, term)
      .execute("dbo.usp_Busqueda_Seguimiento");

    // El SP puede devolver 0 o más filas (un solo recordset)
    const data = r.recordset || [];
    res.json({ ok: true, data, term });
  } catch (e) {
    console.error("GET /api/busqueda", e);
    res.status(500).json({ ok: false, error: e.message });
  }
});

router.get("/cierres", async (req, res) => {
  try {
    const dias = Math.max(1, Math.min(60, parseInt(req.query.dias || "15", 10)));
    const pool = await getPool();
    const r = await pool.request()
      .input("AsOfDate", sql.Date, null)
      .input("DaysBack", sql.Int, dias)
      .execute("dbo.usp_Dashboard_CierresPorDia");

    const data = r.recordsets?.[0] || [];
    const avg  = r.recordsets?.[1]?.[0]?.AvgCierresDia || 0;

    res.json({ ok: true, data, avg, dias });
  } catch (e) {
    console.error("GET /api/cierres", e);
    res.status(500).json({ ok: false, error: e.message });
  }
});



export default router;
