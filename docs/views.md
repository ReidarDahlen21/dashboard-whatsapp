# Vistas y pantallas

Convención: todas las páginas usan `views/layout.ejs` como marco (`<%- body %>`). `window.BASE_PATH` se define en el layout para que los `fetch` funcionen con prefijo de despliegue.

---

## `layout.ejs` (plantilla base)

| Aspecto | Detalle |
|---------|---------|
| **Qué muestra** | Navbar (enlaces General, Detalle, Cierres, Búsqueda), botón estático “Servicio OK”, contenedor `<main>` para el cuerpo de cada vista. |
| **Datos** | `title`, `basePath`, `nav.*` (clase `active` por ruta), sin datos de negocio. |
| **Renderizado** | EJS; incluye Bootstrap, Chart.js, `custom.css`, `bootstrap.bundle.js`. |

---

## General — `home.ejs` (ruta `/`)

| Aspecto | Detalle |
|---------|---------|
| **Nombre en UI** | “Día Anterior” (KPIs) y “Mensajería por día / por mes”. |
| **Qué muestra** | Hasta cinco tarjetas KPI; bloque de mensajería con toggle Diario/Mensual, filtro de motivo (`total`, `_1p`, `_2p`, `_3p`), en vista diaria inputs Desde/Hasta + Aplicar; tablas `#tabla-ultimos7` o `#tabla-mensual`; gráfico `mensajeriaChart` (Chart.js); botón Excel. |
| **Datos que necesita** | **Servidor (EJS):** arreglo `kpis` producido en `routes/home.js` desde `usp_Dashboard_General_DiaAnterior`. **Cliente:** JSON de `GET /api/ultimos7` o `GET /api/envio-mensual` según el modo. |
| **Cómo se renderiza** | KPIs con bucle EJS `kpis.forEach`. Tablas y gráfico: JavaScript sustituye `innerHTML` del tbody y llama `buildChart()`. Si no hay KPIs, alerta “No hay datos…”. Si falla la BD en home, el servidor igual renderiza con `kpis: []` y subtítulo “DB no disponible”. |
| **Componentes clave** | Cards Bootstrap, tablas responsives, Chart.js (área enviados, barras OK/Mal, líneas %), SheetJS para Excel. Heatmap de celdas en tablas usa clases generadas por `heatClass()` cuando `ENABLE_HEATMAP` es `true` (por defecto **false** en código). |

---

## Detalle — `metricas.ejs` (ruta `/metricas`)

| Aspecto | Detalle |
|---------|---------|
| **Nombre en UI** | “Detalle Intradiario Últimos N días”. |
| **Qué muestra** | Tabla `#tabla-detalle` con muchas columnas numéricas; paginación Anterior/Siguiente; total de filas y página actual; filtro motivo; selector “Filas por página” (100–1000). |
| **Datos que necesita** | `GET /api/detalle` con `motivo`, `dias`, `page`, `pageSize`. En el código del cliente, **`DIAS` está fijo en `10`**. |
| **Cómo se renderiza** | Plantilla EJS con thead fijo; el tbody se arma en JS con `data.map` a filas `<tr>`. Fechas `fcCarga` formateadas con `toISOString()` truncado (UTC). |
| **Componentes clave** | Tabla ancha (`table-sm`); sin gráfico en esta vista. |

---

## Cierres — `cierres.ejs` (ruta `/cierres`)

| Aspecto | Detalle |
|---------|---------|
| **Nombre en UI** | “Cierres” con subtítulo que menciona el motivo *CIERRE TT - CLIENTE CONFIRMA OK WHATSAPP* (texto fijo en la plantilla, no viene de la API). |
| **Qué muestra** | Tabla `#tabla-cierres` con heatmap por columnas numéricas; selector de días (7, 15, 30); gráfico `cierresChart` (barras apiladas + línea de promedio). |
| **Datos que necesita** | `GET /api/cierres?dias=N`. |
| **Cómo se renderiza** | JS calcula estilos inline por celda (`heatCellStyle`). Si la API solo devuelve `total` sin desglose, el código puede asignar todo a la serie “Otros” para el gráfico (`needsLegacyStack`). |
| **Componentes clave** | Chart.js apilado, heatmap en tabla (CSS `table-cierres-heatmap`). |

---

## Búsqueda — `busqueda.ejs` (ruta `/busqueda`)

| Aspecto | Detalle |
|---------|---------|
| **Nombre en UI** | “Búsqueda”. |
| **Qué muestra** | Campo de texto + botón Buscar; resultados como bloques de texto en `#resultado`. |
| **Datos que necesita** | `GET /api/busqueda?term=…`. Si `term` vacío en servidor, responde `{ ok: true, data: [] }` sin consultar SP. |
| **Cómo se renderiza** | Plantillas de string en JS que mencionan `matchColumn`, fechas de envío/respuesta, `resultado_cliente`, `estado`, `resultado_envio`, `intentoNumero`. |
| **Componentes clave** | Alertas Bootstrap; sin tablas ni gráficos. |

---

## Pantalla de salud (no EJS)

`GET /health/db` devuelve JSON; no hay vista asociada en `views/`.
