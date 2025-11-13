import { Router } from "express";
import { getPool } from "../db/connection.js";
const router = Router();

router.get("/", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request()
      // .input('AsOfDate', sql.Date, new Date()) // si quisieras forzar una fecha
      .query("EXEC dbo.usp_Dashboard_General_DiaAnterior @AsOfDate = NULL");

    const r = result.recordset && result.recordset[0];

    // formateo y clases de delta
    const fmtInt = (n) => Number(n || 0);
    const fmtPct = (n) => Number(n || 0).toFixed(1) + "%";

    const kpis = [
      { key: "enviados", label: "Enviados", 
        value: fmtInt(r?.Enviados), 
        delta: (r?.DeltaEnviados ?? 0) 
      },
      { key: "respuestas", label: "Respuestas", 
        value: fmtInt(r?.Respuestas), 
        delta: (r?.DeltaRespuestas ?? 0) 
      },
      { key: "pctRespuestas", label: "% Respuestas", 
        value: fmtPct(r?.PctRespuestas), 
        delta: Number(r?.DeltaPctRespuestas ?? 0).toFixed(1) + " pp" 
      },
      { key: "ok", label: "OK", 
        value: fmtInt(r?.Ok), 
        delta: (r?.DeltaOk ?? 0) 
      },
      { key: "pctOk", label: "% OK", 
        value: fmtPct(r?.PctOk), 
        delta: Number(r?.DeltaPctOk ?? 0).toFixed(1) + " pp" 
      },
    ].map(k => {
      // badge color: verde si delta > 0, rojo si < 0, gris si 0
      const raw = typeof k.delta === "string" ? parseFloat(k.delta) : Number(k.delta);
      const sign = isNaN(raw) ? 0 : (raw > 0 ? 1 : raw < 0 ? -1 : 0);
      return { ...k, 
        deltaText: (typeof k.delta === "string" ? (sign > 0 ? "+" : (sign < 0 ? "" : "")) + k.delta : 
                    (sign > 0 ? "+" : (sign < 0 ? "" : "")) + raw.toFixed(0)),
        badgeClass: sign > 0 ? "bg-success-subtle text-success" : sign < 0 ? "bg-danger-subtle text-danger" : "bg-secondary-subtle text-secondary"
      };
    });

    res.render("home", {
      title: "General",
      hero: {
        heading: "Día anterior",
        sub: "Resumen de actividad de WhatsApp (ayer vs promedio histórico)"
      },
      kpis
    });

  } catch (err) {
    console.error("Home error:", err);
    // fallback UI minimalista
    res.render("home", {
      title: "General",
      hero: { heading: "Día anterior", sub: "DB no disponible, sin datos" },
      kpis: []
    });
  }
});

export default router;
