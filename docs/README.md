# Documentación técnica — Dashboard WhatsApp

Aplicación web **Node.js** que expone un panel para visualizar indicadores y tableros relacionados con el envío y seguimiento de mensajería por WhatsApp. El código en este repositorio **no llama a una API HTTP externa de mensajería**: obtiene los datos desde **Microsoft SQL Server** mediante el driver `mssql` y procedimientos almacenados definidos en la base (el origen “de negocio” puede ser la misma base que alimenta otros sistemas; aquí solo se documenta lo que hace esta app).

## Qué problema resuelve

Ofrece a operadores o analistas una interfaz unificada para:

- Ver un **resumen del día anterior** (KPIs de enviados, respuestas, OK y porcentajes, con desglose “Campo”).
- Analizar **mensajería por día o por mes** (tablas, gráfico mixto, exportación Excel en vista diaria/mensual desde el cliente).
- Consultar **detalle intradiario** paginado con desglose de pendientes y bloqueos.
- Ver **cierres** por día con desglose Campo / Centro Técnico / Otros y gráfico apilado.
- **Buscar** por número de WhatsApp, incident o CaseID y ver el estado narrativo de cada intento.

## Qué información muestra

| Ámbito | Contenido principal |
|--------|---------------------|
| General (`/`) | KPIs del día anterior; tabla y gráfico de mensajería (diario por rango de fechas o mensual). |
| Detalle (`/metricas`) | Filas intradiarias con columnas de conteos y estados. |
| Cierres (`/cierres`) | Cierres con motivo descrito en la UI, por día y canal. |
| Búsqueda (`/busqueda`) | Resultados en texto según coincidencia y fechas de envío/respuesta. |

## Relación con el backend de datos

- **Servidor Express** sirve páginas **EJS** y rutas JSON bajo **`/api/*`**.
- Esas rutas ejecutan **stored procedures** en SQL Server (por ejemplo `dbo.usp_Dashboard_*`). La forma exacta de las filas depende de lo que devuelvan esos SP en la base desplegada.
- Endpoint **`GET /health/db`** comprueba conectividad con `SELECT GETDATE()` (no es la “API de WhatsApp”, solo salud de BD).

Para el flujo completo, véase [overview.md](overview.md), [data-flow.md](data-flow.md) y [api-integration.md](api-integration.md).

## Índice de documentos

| Archivo | Contenido |
|---------|-----------|
| [overview.md](overview.md) | Flujo de uso y tipos de reportes. |
| [architecture.md](architecture.md) | Estructura del repo, stack y organización. |
| [views.md](views.md) | Cada pantalla, datos y renderizado. |
| [api-integration.md](api-integration.md) | Rutas `/api`, SPs y respuestas. |
| [data-flow.md](data-flow.md) | Camino de datos hasta la pantalla. |
| [maintenance.md](maintenance.md) | Cómo extender, depurar y riesgos. |
