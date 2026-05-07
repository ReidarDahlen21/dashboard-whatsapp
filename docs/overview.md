# Visión general — Flujo y reportes

## Flujo general

1. **El usuario accede** al servidor Express (por defecto puerto `3007`, configurable con `PORT`). Las rutas HTML son `/`, `/metricas`, `/cierres`, `/busqueda`.
2. **El servidor renderiza** plantillas **EJS** con layout común (`views/layout.ejs`). En la ruta **General** (`/`), el servidor además ejecuta en el mismo request un `EXEC dbo.usp_Dashboard_General_DiaAnterior` para armar los KPIs del día anterior.
3. **El navegador pide datos JSON** a las rutas internas **`/api/*`** mediante `fetch` (JavaScript embebido en las vistas). Esas rutas consultan SQL Server y devuelven JSON (`ok`, `data`, metadatos de paginación o promedios según el endpoint).
4. **El cliente procesa** la respuesta: formatea números (`es-AR`), construye filas de tabla en HTML, y en **General**, **Cierres** y el gráfico de mensajería usa **Chart.js** para dibujar gráficos. La exportación Excel de mensajería en **General** usa la librería **SheetJS** cargada por CDN en esa vista.

No hay en el código una capa que invoque una API REST externa de mensajería; la integración operativa es **SQL Server → Express → JSON → EJS + JS en el cliente**.

## Tipos de métricas y reportes (según pantallas)

### General (`/`)

- **Tarjetas KPI** (servidor): Enviados, Respuestas, % Respuestas, OK, % OK; línea adicional “Campo” donde aplica (proporción respecto del total del KPI).
- **Mensajería “por día”**: tabla y gráfico alimentados por `GET /api/ultimos7` con rango `desde`/`hasta` (máx. 60 días inclusive) y filtro `motivo` (`total`, `_1p`, `_2p`, `_3p`). Columnas de tabla: Fecha, Enviados, Prom. RefUtil, Prom. RefUtil Bloq, OK, Mal.
- **Mensajería “por mes”**: misma área de UI, datos de `GET /api/envio-mensual`; eje temporal mensual y mismas columnas sustituyendo “Fecha” por mes en español.

### Detalle (`/metricas`)

- Tabla paginada de **detalle intradiario** para los **últimos 10 días** (valor fijado en el cliente en `views/metricas.ejs`), con filtro `motivo` y parámetros `page` / `pageSize`.

### Cierres (`/cierres`)

- Tabla diaria con columnas Campo, Centro Técnico, Otros, Total y **heatmap** por columna numérica; gráfico de barras apiladas + línea de promedio histórico. Rango de días seleccionable (7, 15, 30).

### Búsqueda (`/busqueda`)

- Resultados narrativos por fila (fechas de envío/respuesta, resultado del cliente, estado, etc.) según `GET /api/busqueda?term=…`.

### Salud

- `GET /health/db`: respuesta JSON con fecha/hora del servidor SQL si la conexión funciona.
