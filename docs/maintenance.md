# Mantenimiento y operación

## Cómo arrancar el proyecto

- Script en `package.json`: **`npm run dev`** → ejecuta `node server.js`.
- Requiere variables de entorno de BD configuradas (véase `db/connection.js`).
- Puerto por defecto **3007** (`PORT`).

## Cómo agregar un nuevo reporte o pantalla

1. **Definir el contrato de datos** (idealmente un SP nuevo o extensión documentada en SQL) que devuelva columnas estables.
2. **Backend:** en `routes/api.js`, añadir un `router.get("/mi-reporte", …)` que use `getPool()`, `.input(...)`, `.execute("dbo.usp_MiReporte")` y devuelva JSON consistente (`ok`, `data`, …).
3. **Registrar la ruta** si creás un archivo nuevo: importar en `server.js` y `app.use(...)`.
4. **Frontend:** opciones habituales en este repo:
   - Nueva vista **`views/mi-vista.ejs`** + ruta en `routes/*.js` con `res.render`.
   - Añadir enlace en **`views/layout.ejs`** y extender el objeto `nav` en **`server.js`** si querés resaltar la pestaña activa igual que las demás.
5. **Cliente:** script embebido al final de la EJS con `fetch(\`${BASE}/api/mi-reporte\`)` y render de tabla o Chart.js (según patrón de `home.ejs` o `cierres.ejs`).

Sin cambios en SQL, solo se pueden combinar datos existentes en Node o en el cliente; evitá duplicar lógica ya encapsulada en SPs si el equipo de datos es el dueño de las métricas.

## Cómo modificar una vista existente

| Cambio deseado | Dónde tocar |
|----------------|-------------|
| Textos, columnas de tabla estática, títulos | `views/*.ejs` |
| KPIs del día anterior o labels | `routes/home.js` + columnas del SP general |
| Query params o procedimiento de un JSON | `routes/api.js` |
| Gráfico (datasets, colores, ejes) | Script Chart.js en `home.ejs` / `cierres.ejs` |
| Estilos, heatmap tabla cierres | `public/css/custom.css` |
| Navbar, assets globales | `views/layout.ejs` |
| Días de detalle intradiario | Constante **`DIAS`** en `views/metricas.ejs` (hoy fija en **10**) |

Tras tocar SPs en SQL, probá cada pantalla que los consume y revisá nombres de propiedades en el mapeo del cliente.

## Dónde debuggear

1. **Logs HTTP:** `morgan("dev")` en `server.js` (consola del proceso Node).
2. **Errores de API:** `console.error` en cada `catch` de `routes/api.js` y `routes/home.js`.
3. **Cliente:** DevTools → pestaña **Red** (respuestas `/api/*`, códigos 400/500); **Consola** para excepciones en scripts de las vistas.
4. **Base de datos:** ejecutar los mismos SP con los mismos parámetros que envía `routes/api.js` (incluido `AsOfDate` null o calculado en `ultimos7`).
5. **Conectividad rápida:** `GET /health/db`.

## Problemas comunes

| Síntoma | Causa probable |
|---------|----------------|
| KPIs vacíos / “DB no disponible” | Credenciales, red, firewall, nombre de instancia SQL, o fallo del SP general. |
| `500` en `/api/*` | SP inexistente, permisos, timeout, o error dentro del SP. |
| Datos “desfasados” un día | Mezcla de fechas locales en el browser vs `sql.Date` / UTC en servidor para rangos. |
| Tabla detalle siempre 10 días | El valor está hardcodeado como **`DIAS = 10`** en `metricas.ejs`. |
| Gráfico de cierres solo en “Otros” | Respuesta sin desglose; el código activa modo “legacy” que apila todo en Otros. |
| Excel no descarga | Bloqueo de CDN de SheetJS, `XLSX` no cargado, o `lastRows` vacío por error previo. |
| Assets o fetch 404 en producción | `BASE_PATH` mal configurado respecto al prefijo del reverse proxy. |

## Riesgos y limitaciones

- **Lógica en SQL:** cambios de negocio requieren coordinación con DBA/equipo de datos; el dashboard es sensible al contrato de los SP.
- **SQL injection:** las entradas van mayormente por parámetros tipados `mssql`; mantener ese patrón en código nuevo.
- **Seguridad:** no hay autenticación visible en el código del repositorio; el despliegue debe proteger la app (VPN, reverse proxy con auth, etc.).
- **Paginación de detalle:** `pageSize` puede llegar hasta **2000** por solicitud; puede cargar mucho en BD y en el navegador.
- **Rangos largos en `ultimos7`:** tope **60 días** en API; más volumen implica más filas y más trabajo en Chart.js.
- **Dependencias CDN:** Bootstrap, Chart.js, fonts y SheetJS en home dependen de la disponibilidad del CDN y de políticas CSP en el entorno.
- **Cliente mezclado con vista:** gran parte de la lógica de presentación está en `<script>` dentro de EJS; refactorizar con cuidado para no romper el orden de ejecución o `BASE_PATH`.
