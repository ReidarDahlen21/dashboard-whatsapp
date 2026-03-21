USE [mensajeriaWhatsapp]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
  Dashboard — KPIs "día anterior" (misma fuente y definiciones que usp_Dashboard_EnvioUltimos7
  para motivo Total: agrega todos los registros de resumenEnvioWA por CAST(fcCarga AS date)).

  - Enviados: SUM(enviados)
  - Respuestas: SUM(ok) + SUM(mal)
  - % Respuestas: 100 * Respuestas / Enviados
  - OK: SUM(ok)
  - % OK: 100 * OK / (OK + Mal) cuando hubo respuestas (no sobre enviados)

  Subgrupo "Campo" (detalleEnvioOrganizacion, organizacion = @Organizacion):
  CampoEnviados, CampoRespuestas (fcRespuesta IS NOT NULL), CampoOk (resultado contiene "cliente ok").

  Ejecutar en SSMS contra mensajeriaWhatsapp (o ajustar USE).
*/
ALTER PROCEDURE [dbo].[usp_Dashboard_General_DiaAnterior]
  @AsOfDate     date = NULL,   -- si NULL toma CAST(GETDATE() AS date)
  @Organizacion nvarchar(120) = N'cea revisador'
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @today       date = ISNULL(@AsOfDate, CAST(GETDATE() AS date));
  DECLARE @target_date date = DATEADD(day, -1, @today);

  -------------------------------------------------------------------
  -- Métricas del día objetivo (ayer): total de todos los motivo
  -------------------------------------------------------------------
  ;WITH Y_metrics AS (
    SELECT
      Enviados = ISNULL(SUM(ISNULL(r.enviados, 0)), 0),
      OkCount  = ISNULL(SUM(ISNULL(r.ok, 0)), 0),
      MalCount = ISNULL(SUM(ISNULL(r.mal, 0)), 0)
    FROM dbo.resumenEnvioWA r WITH (NOLOCK)
    WHERE r.fcCarga >= @target_date
      AND r.fcCarga <  DATEADD(day, 1, @target_date)
  )
  , Y AS (
    SELECT
      Enviados,
      OkCount,
      MalCount,
      Respuestas = OkCount + MalCount,
      PctRespuestas = CASE
        WHEN Enviados > 0 THEN 100.0 * (OkCount + MalCount) / Enviados
        ELSE 0.0
      END,
      PctOk = CASE
        WHEN (OkCount + MalCount) > 0 THEN 100.0 * OkCount / (OkCount + MalCount)
        ELSE 0.0
      END
    FROM Y_metrics
  )
  -------------------------------------------------------------------
  -- Promedios históricos diarios (excluye el día objetivo), luego AVG
  -- Misma lógica de porcentajes por día que en usp_Dashboard_EnvioUltimos7
  -------------------------------------------------------------------
  , Dailies AS (
    SELECT
      Dia = CAST(r.fcCarga AS date),
      Enviados = ISNULL(SUM(ISNULL(r.enviados, 0)), 0),
      OkCount  = ISNULL(SUM(ISNULL(r.ok, 0)), 0),
      MalCount = ISNULL(SUM(ISNULL(r.mal, 0)), 0)
    FROM dbo.resumenEnvioWA r WITH (NOLOCK)
    WHERE CAST(r.fcCarga AS date) < @target_date
    GROUP BY CAST(r.fcCarga AS date)
  )
  , DailyRates AS (
    SELECT
      Enviados,
      OkCount,
      MalCount,
      Respuestas = OkCount + MalCount,
      PctRespuestas = CASE
        WHEN Enviados > 0 THEN 100.0 * (OkCount + MalCount) / Enviados
        ELSE 0.0
      END,
      PctOk = CASE
        WHEN (OkCount + MalCount) > 0 THEN 100.0 * OkCount / (OkCount + MalCount)
        ELSE 0.0
      END
    FROM Dailies
  )
  , Averages AS (
    SELECT
      AvgEnviados       = AVG(1.0 * Enviados),
      AvgRespuestas     = AVG(1.0 * Respuestas),
      AvgPctRespuestas  = AVG(1.0 * PctRespuestas),
      AvgOk             = AVG(1.0 * OkCount),
      AvgPctOk          = AVG(1.0 * PctOk)
    FROM DailyRates
  )
  -------------------------------------------------------------------
  -- Subgrupo por organización (mismo rango de fcCarga que el resumen del día)
  -------------------------------------------------------------------
  , Campo AS (
    SELECT
      CampoEnviados = ISNULL(COUNT_BIG(1), 0),
      CampoRespuestas = ISNULL(SUM(CASE WHEN d.fcRespuesta IS NOT NULL THEN 1 ELSE 0 END), 0),
      CampoOk = ISNULL(SUM(CASE
        WHEN LOWER(ISNULL(d.resultado, N'')) LIKE N'%cliente ok%' THEN 1
        ELSE 0
      END), 0)
    FROM dbo.detalleEnvioOrganizacion d WITH (NOLOCK)
    WHERE d.fcCarga >= @target_date
      AND d.fcCarga < DATEADD(day, 1, @target_date)
      AND LOWER(LTRIM(RTRIM(ISNULL(d.organizacion, N''))))
        = LOWER(LTRIM(RTRIM(@Organizacion)))
  )
  SELECT
    FechaObjetivo = @target_date,
    Enviados       = y.Enviados,
    Respuestas     = y.Respuestas,
    PctRespuestas  = y.PctRespuestas,
    Ok             = y.OkCount,
    PctOk          = y.PctOk,
    CampoEnviados     = c.CampoEnviados,
    CampoRespuestas   = c.CampoRespuestas,
    CampoOk           = c.CampoOk,
    AvgEnviados      = ISNULL(a.AvgEnviados, 0.0),
    AvgRespuestas    = ISNULL(a.AvgRespuestas, 0.0),
    AvgPctRespuestas = ISNULL(a.AvgPctRespuestas, 0.0),
    AvgOk            = ISNULL(a.AvgOk, 0.0),
    AvgPctOk         = ISNULL(a.AvgPctOk, 0.0),
    DeltaEnviados      = y.Enviados       - ISNULL(a.AvgEnviados, 0.0),
    DeltaRespuestas    = y.Respuestas     - ISNULL(a.AvgRespuestas, 0.0),
    DeltaPctRespuestas = y.PctRespuestas  - ISNULL(a.AvgPctRespuestas, 0.0),
    DeltaOk            = y.OkCount        - ISNULL(a.AvgOk, 0.0),
    DeltaPctOk         = y.PctOk          - ISNULL(a.AvgPctOk, 0.0)
  FROM Y y
  CROSS JOIN Averages a
  CROSS JOIN Campo c;
END
GO
