# Integración de datos y API interna

En este proyecto, “consumir la API” desde el navegador significa llamar a rutas **del mismo servidor Express** bajo el prefijo **`/api`**. Esas rutas leen **Microsoft SQL Server** mediante procedimientos almacenados; no aparece en el código una URL base hacia un servicio HTTP de mensajería externo.

## Resumen de endpoints

| Método y ruta | Origen de datos (SQL) | Respuesta JSON (campos principales) |
|---------------|------------------------|-------------------------------------|
| `GET /api/ultimos7` | `dbo.usp_Dashboard_EnvioUltimos7` | `ok`, `data` (recordset 0), `avg` (recordset 1) |
| `GET /api/envio-mensual` | `dbo.usp_Dashboard_EnvioUltimos12Meses` | `ok`, `data`, `avg` |
| `GET /api/detalle` | `dbo.usp_Dashboard_DetalleIntradiario` | `ok`, `data`, `total`, `page`, `pageSize` |
| `GET /api/busqueda` | `dbo.usp_Busqueda_Seguimiento` | `ok`, `data`, `term` |
| `GET /api/cierres` | `dbo.usp_Dashboard_CierresPorDia` | `ok`, `data`, `avg`, `dias` |
| `GET /health/db` | `SELECT GETDATE()` | `ok`, `now` |

Cabecera `Cache-Control: no-store` en `ultimos7` y `envio-mensual`.

## Parámetros y validación

### `GET /api/ultimos7`

- **`motivo`**: `total` (default), `_1p`, `_2p`, `_3p`; otros valores se normalizan a `total`.
- **Sin `desde` ni `hasta`**: usa `dias` (query, default `10`, entre 1 y 60) y `AsOfDate` **null** en el SP.
- **Con `desde` y `hasta`** (`YYYY-MM-DD`): ambos obligatorios; rango máximo **60 días inclusive**; fechas validadas en UTC calendario; se calcula `DaysBack` y `AsOfDate` = día siguiente a `hasta` para el SP.
- Errores **400** con JSON `{ ok: false, error: "..." }` si faltan fechas, son inválidas o el rango es demasiado largo.

### `GET /api/envio-mensual`

- **`motivo`**: mismo conjunto permitido.
- **`asOf`** (opcional): si se envía, debe ser `YYYY-MM-DD`; pasa como `sql.Date` al SP; si no, **null**.

### `GET /api/detalle`

- **`motivo`**: mismo conjunto.
- **`dias`**: 1–60, default `10`.
- **`page`**: ≥ 1, default `1`.
- **`pageSize`**: 1–2000, default `200`.
- `AsOfDate` se pasa siempre como **null** en el código actual.

### `GET /api/busqueda`

- **`term`**: si está vacío tras `trim`, respuesta `200` con `data: []` sin ejecutar SP.

### `GET /api/cierres`

- **`dias`**: 1–60, default `15`.

## Qué datos recibe el cliente (nombres usados en el front)

Los nombres exactos de columnas dependen de los SP; el **frontend** asume al menos:

- **Mensajería (últimos 7 / mensual):** `fecha`, `enviados`, `prom_RefUtil`, `prom_RefUtilBloqueante`, `ok`, `mal`, `pctRespuestas`, `pctOk`. Promedios en `avg`: `AvgEnviados`, `AvgProm_RefUtil`, `AvgProm_RefUtilBloq`, `AvgOk`, `AvgMal` (y análogos en mensual).
- **Detalle:** `fcCarga`, `motivo`, `enviados`, `pendiente`, `cantPendienteTotalValidoEnvio`, `cantPendienteRefUtil`, `cantPendienteRefUtilBloqueante`, pendientes `Bloq*`, `ok`, `mal`, `sinRespuesta`.
- **Cierres:** `fecha`, `campo`/`Campo`, `centroTecnico`/`CentroTecnico`, `otros`/`Otros`, `total`; `avg` numérico o `AvgCierresDia` en recordset de promedios.
- **Búsqueda:** `matchColumn`, `fecha_envio`, `fecha_respuesta`, `resultado_cliente`, `estado`, `resultado_envio`, `intentoNumero`.

Si un SP cambia nombres o tipos, hay que alinear `routes/api.js` o los scripts en las vistas.

## Transformación para mostrar en UI

- **Servidor (`home.js`)**: convierte el primer row del SP general en tarjetas `kpis` con strings ya formateadas (`toLocaleString("es-AR")`, porcentajes con un decimal) y línea “Campo: n — p%”.
- **Cliente**: convierte números con `Number(x||0).toLocaleString('es-AR')`; porcentajes en tooltips del gráfico con `toFixed(1) + '%'`; fechas recortadas a 10 caracteres o mes en español en home; detalle usa ISO UTC en `fcCarga`.
- **Cierres**: heatmap por min/max del rango mostrado; fallback si solo llega `total`.

## Manejo de errores

| Capa | Comportamiento |
|------|----------------|
| **API Express** | `try/catch`: log `console.error("GET /api/…", e)` y `500` con `{ ok: false, error: e.message }`. |
| **Home route** | Si falla la consulta del día anterior, renderiza `home` con KPIs vacíos y mensaje “DB no disponible”. |
| **Cliente** | Tras `fetch`, si `ok` es falso lanza error con `error` del JSON; muestra filas con mensaje “Error al cargar datos” o alertas en búsqueda. Errores de validación en `ultimos7` devueltos como 400 se propagan al mensaje visible en `#ultimos7-fecha-error` en home. |

Errores de red (sin JSON) pueden producir excepciones al hacer `.json()`; el código en su mayoría asume respuesta JSON en el `try`.

## Relación con una “API de mensajería” externa

Este repositorio **no implementa** llamadas HTTP a otro backend de mensajería. Si el negocio carga datos en SQL vía otros procesos, ese vínculo está **fuera** de este código; aquí solo se documenta la dependencia de **SQL Server + SPs**.
