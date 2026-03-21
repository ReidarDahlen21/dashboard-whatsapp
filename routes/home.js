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

    /** Subgrupo organización (cea revisador): "Campo: n — p%" vs total del KPI */
    const fmtCampoLine = (sub, total) => {
      const den = fmtInt(total);
      const num = fmtInt(sub);
      const p = den > 0 ? ((100 * num) / den).toFixed(1) : "0.0";
      return `Campo: ${num.toLocaleString("es-AR")} — ${p}%`;
    };

    const enviadosTot = fmtInt(r?.Enviados);
    const respuestasTot = fmtInt(r?.Respuestas);
    const okTot = fmtInt(r?.Ok);

    const kpis = [
      {
        key: "enviados",
        label: "Enviados",
        value: enviadosTot.toLocaleString("es-AR"),
        campoLine: fmtCampoLine(r?.CampoEnviados, enviadosTot),
      },
      {
        key: "respuestas",
        label: "Respuestas",
        value: respuestasTot.toLocaleString("es-AR"),
        campoLine: fmtCampoLine(r?.CampoRespuestas, respuestasTot),
      },
      {
        key: "pctRespuestas",
        label: "% Respuestas",
        value: fmtPct(r?.PctRespuestas),
      },
      {
        key: "ok",
        label: "OK",
        value: okTot.toLocaleString("es-AR"),
        campoLine: fmtCampoLine(r?.CampoOk, okTot),
      },
      {
        key: "pctOk",
        label: "% OK",
        value: fmtPct(r?.PctOk),
      },
    ].map((k) => {
      if (k.campoLine) return k;
      if (k.key === "pctRespuestas" || k.key === "pctOk") return k;
      const raw = typeof k.delta === "string" ? parseFloat(k.delta) : Number(k.delta);
      const sign = isNaN(raw) ? 0 : raw > 0 ? 1 : raw < 0 ? -1 : 0;
      return {
        ...k,
        deltaText:
          (typeof k.delta === "string"
            ? (sign > 0 ? "+" : sign < 0 ? "" : "") + k.delta
            : (sign > 0 ? "+" : sign < 0 ? "" : "") + raw.toFixed(0)),
        badgeClass:
          sign > 0
            ? "bg-success-subtle text-success"
            : sign < 0
              ? "bg-danger-subtle text-danger"
              : "bg-secondary-subtle text-secondary",
      };
    });

    res.render("home", {
      title: "General",
      hero: {
        heading: "Día anterior",
        sub: "Resumen de actividad de WhatsApp (día anterior)",
      },
      kpis
    });

  } catch (err) {
    console.error("Home error:", err);
    // fallback UI minimalista
    res.render("home", {
      title: "General",
      hero: { heading: "Día anterior", sub: "DB no disponible" },
      kpis: []
    });
  }
});

export default router;
