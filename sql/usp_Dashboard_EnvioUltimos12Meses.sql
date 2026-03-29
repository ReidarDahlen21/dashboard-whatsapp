USE [mensajeriaWhatsapp]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
  Dashboard — agregado mensual (últimos 12 meses calendario completos).

  - Solo filas con fcCarga estrictamente antes del 1.er día del mes de @AsOfDate
    (el mes "en curso" respecto de @AsOfDate queda excluido).
  - RS1: hasta 12 filas, una por mes, mes más reciente primero. fecha = primer día del mes.
  - RS2: promedios de los totales mensuales (todos los meses en #Filtered), mismo criterio
    que el agregado diario para heatmap.

  Tras crear/alterar: GRANT EXECUTE ON OBJECT::dbo.usp_Dashboard_EnvioUltimos12Meses TO [mensa];

  Ejecutar en SSMS contra la base correcta (ajustar USE si aplica).
  Primera instalación: DROP + CREATE. Si ya existe, el DROP lo reemplaza.
*/
IF OBJECT_ID(N'dbo.usp_Dashboard_EnvioUltimos12Meses', N'P') IS NOT NULL
  DROP PROCEDURE dbo.usp_Dashboard_EnvioUltimos12Meses;
GO

CREATE PROCEDURE [dbo].[usp_Dashboard_EnvioUltimos12Meses]
  @AsOfDate date = NULL,
  @Motivo   nvarchar(10) = N'total'
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @today date = ISNULL(@AsOfDate, CAST(GETDATE() AS date));
  DECLARE @firstDayCurrentMonth date = DATEFROMPARTS(YEAR(@today), MONTH(@today), 1);

  DECLARE @m1 nvarchar(60) = N'av_segunda_prueba_1p';
  DECLARE @m2 nvarchar(60) = N'av_segunda_prueba_2p';
  DECLARE @m3 nvarchar(60) = N'av_segunda_prueba_3p';

  IF OBJECT_ID('tempdb..#MonthMotives') IS NOT NULL DROP TABLE #MonthMotives;
  IF OBJECT_ID('tempdb..#Filtered') IS NOT NULL DROP TABLE #Filtered;

  CREATE TABLE #MonthMotives(
    mes_inicio date NOT NULL,
    motivo nvarchar(60) NOT NULL,
    enviados int NULL,
    refUtil int NULL,
    refUtilBloq int NULL,
    ok int NULL,
    mal int NULL,
    sinRespuesta int NULL
  );

  INSERT INTO #MonthMotives(mes_inicio, motivo, enviados, refUtil, refUtilBloq, ok, mal, sinRespuesta)
  SELECT
    DATEFROMPARTS(YEAR(r.fcCarga), MONTH(r.fcCarga), 1) AS mes_inicio,
    r.motivo,
    SUM(r.enviados),
    SUM(r.cantPendienteRefUtil),
    SUM(r.cantPendienteRefUtilBloqueante),
    SUM(r.ok),
    SUM(r.mal),
    SUM(r.sinRespuesta)
  FROM dbo.resumenEnvioWA r WITH (NOLOCK)
  WHERE CAST(r.fcCarga AS date) < @firstDayCurrentMonth
  GROUP BY DATEFROMPARTS(YEAR(r.fcCarga), MONTH(r.fcCarga), 1), r.motivo;

  CREATE TABLE #Filtered(
    mes_inicio date NOT NULL,
    motivo nvarchar(60) NOT NULL,
    enviados int NULL,
    refUtil int NULL,
    refUtilBloq int NULL,
    ok int NULL,
    mal int NULL,
    sinRespuesta int NULL
  );

  INSERT INTO #Filtered
  SELECT *
  FROM #MonthMotives
  WHERE
      (@Motivo = N'total')
   OR (@Motivo = N'_1p' AND motivo = @m1)
   OR (@Motivo = N'_2p' AND motivo = @m2)
   OR (@Motivo = N'_3p' AND motivo = @m3);

  /* RS1: últimos 12 meses con datos */
  ;WITH M AS (
    SELECT
      mes_inicio,
      enviados               = SUM(enviados),
      prom_RefUtil           = SUM(refUtil),
      prom_RefUtilBloqueante = SUM(refUtilBloq),
      ok                     = SUM(ok),
      mal                    = SUM(mal)
    FROM #Filtered
    GROUP BY mes_inicio
  ),
  Ranked AS (
    SELECT
      mes_inicio,
      enviados,
      prom_RefUtil,
      prom_RefUtilBloqueante,
      ok,
      mal,
      ROW_NUMBER() OVER (ORDER BY mes_inicio DESC) AS rn
    FROM M
  )
  SELECT
    fecha = mes_inicio,
    enviados,
    prom_RefUtil,
    prom_RefUtilBloqueante,
    ok,
    mal,
    pctRespuestas = CASE WHEN enviados > 0
                         THEN 100.0 * (ok + mal) / enviados
                         ELSE 0.0 END,
    pctOk         = CASE WHEN (ok + mal) > 0
                         THEN 100.0 * ok / (ok + mal)
                         ELSE 0.0 END
  FROM Ranked
  WHERE rn <= 12
  ORDER BY mes_inicio DESC;

  /* RS2: promedios entre meses (misma idea que días en EnvioUltimos7) */
  ;WITH MonthlyAgg AS (
    SELECT
      mes_inicio,
      enviados               = SUM(enviados),
      prom_RefUtil           = SUM(refUtil),
      prom_RefUtilBloqueante = SUM(refUtilBloq),
      ok                     = SUM(ok),
      mal                    = SUM(mal)
    FROM #Filtered
    GROUP BY mes_inicio
  )
  SELECT
    AvgEnviados         = AVG(1.0 * enviados),
    AvgProm_RefUtil     = AVG(1.0 * prom_RefUtil),
    AvgProm_RefUtilBloq = AVG(1.0 * prom_RefUtilBloqueante),
    AvgOk               = AVG(1.0 * ok),
    AvgMal              = AVG(1.0 * mal)
  FROM MonthlyAgg;
END
GO

/*
  Permiso de ejecución para el usuario de la app (ejecutar en la misma base):

  GRANT EXECUTE ON OBJECT::dbo.usp_Dashboard_EnvioUltimos12Meses TO [mensa];
*/
