USE [mensajeriaWhatsapp]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
  Cierres por día: total y desglose por organización (JOIN detalleEnvioOrganizacion).

  - RS1: fecha, campo (organizacion LIKE 'cea%'), centroTecnico ('back%' o 'bo%'), otros, total
  - RS2: AvgCierresDia (promedio de totales diarios históricos antes de @dEnd)

  Una fila de detalle por incidentNumber (última fcCarga). Sin match en detalle => otros.

  Ejecutar en SSMS (ALTER reemplaza la definición existente).
*/
ALTER PROCEDURE [dbo].[usp_Dashboard_CierresPorDia]
  @AsOfDate date = NULL,
  @DaysBack int = 15
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @today  date = ISNULL(@AsOfDate, CAST(GETDATE() AS date));
  DECLARE @dStart date = DATEADD(day, -@DaysBack, @today);
  DECLARE @dEnd   date = @today;

  ;WITH DetalleUna AS (
    SELECT incidentNumber, organizacion
    FROM (
      SELECT
        d.incidentNumber,
        d.organizacion,
        ROW_NUMBER() OVER (
          PARTITION BY d.incidentNumber
          ORDER BY d.fcCarga DESC
        ) AS rn
      FROM dbo.detalleEnvioOrganizacion d WITH (NOLOCK)
    ) x
    WHERE rn = 1
  )
  , Base AS (
    SELECT
      Dia = CAST(c.FcCargado AS date),
      org = LOWER(LTRIM(RTRIM(ISNULL(det.organizacion, N''))))
    FROM dbo.cierresEnviadosWA c WITH (NOLOCK)
    LEFT JOIN DetalleUna det ON det.incidentNumber = c.incidentNumber
    WHERE c.FcCargado >= @dStart
      AND c.FcCargado < @dEnd
  )
  SELECT
    fecha = Dia,
    campo = SUM(CASE WHEN org LIKE N'cea%' THEN 1 ELSE 0 END),
    centroTecnico = SUM(CASE
      WHEN org NOT LIKE N'cea%'
       AND (org LIKE N'back%' OR org LIKE N'bo%')
      THEN 1 ELSE 0 END),
    otros = SUM(CASE
      WHEN org NOT LIKE N'cea%'
       AND org NOT LIKE N'back%'
       AND org NOT LIKE N'bo%'
      THEN 1 ELSE 0 END),
    total = COUNT_BIG(1)
  FROM Base
  GROUP BY Dia
  ORDER BY Dia DESC;

  ;WITH DailyHist AS (
    SELECT
      Dia = CAST(c.FcCargado AS date),
      tot = COUNT_BIG(1)
    FROM dbo.cierresEnviadosWA c WITH (NOLOCK)
    WHERE c.FcCargado IS NOT NULL
      AND CAST(c.FcCargado AS date) < @dEnd
    GROUP BY CAST(c.FcCargado AS date)
  )
  SELECT
    AvgCierresDia = ISNULL(AVG(1.0 * tot), 0.0)
  FROM DailyHist;
END
GO
