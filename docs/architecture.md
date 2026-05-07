# Arquitectura del proyecto

## Estructura de directorios (relevante)

```
dashboard-whatsapp-v2/
├── server.js              # Entrada Express: rutas, EJS, estáticos, puerto
├── package.json
├── db/
│   └── connection.js      # Pool mssql + configuración desde variables de entorno
├── routes/
│   ├── home.js            # GET / — KPIs + render home
│   ├── metricas.js        # GET /metricas — solo render
│   ├── cierres.js         # GET /cierres — solo render
│   ├── busqueda.js        # GET /busqueda — solo render
│   ├── api.js             # GET /api/* — JSON desde SQL
│   └── health.js          # GET /health/db
├── views/
│   ├── layout.ejs         # Shell: navbar, Bootstrap, Chart.js global
│   ├── home.ejs           # General: KPIs + tablas + gráfico + scripts
│   ├── metricas.ejs       # Detalle + script fetch /api/detalle
│   ├── cierres.ejs        # Cierres + script fetch /api/cierres + Chart
│   └── busqueda.ejs       # Búsqueda + script fetch /api/busqueda
└── public/
    ├── css/custom.css     # Tipografía, heatmap tablas cierres, navbar
    └── favicon.svg
```

## Componentes principales

### Backend (Express)

- **Rutas de página**: preparan el modelo mínimo para EJS (`title`, `hero`, `kpis` en home; el resto suele ser solo `title`).
- **Rutas API** (`routes/api.js`): validan query params, ejecutan stored procedures con `mssql`, devuelven JSON. Errores → `500` + `{ ok: false, error: message }` y log en consola.
- **Conexión a datos** (`db/connection.js`): un único pool singleton (`getPool()`), opciones `encrypt` / `trustServerCertificate` según variables de entorno.

### Frontend

- **Motor de vistas**: **EJS** con **express-ejs-layouts**; layout por defecto `views/layout.ejs`.
- **CSS/UI**: **Bootstrap 5.3** e **Bootstrap Icons** por CDN; fuente **Inter Tight** (Google Fonts); estilos propios en `public/css/custom.css`.
- **Gráficos**: **Chart.js 4.4** incluido en el layout (usado en `home.ejs` y `cierres.ejs`).
- **Excel (solo en home)**: **xlsx** (SheetJS) vía CDN en `home.ejs` (existe también la dependencia `xlsx` en `package.json`, pero el export actual es en el navegador).

## Variables de entorno relevantes

| Variable | Uso |
|----------|-----|
| `PORT` | Puerto HTTP (default `3007`). |
| `BASE_PATH` | Prefijo para enlaces estáticos y `fetch` (`res.locals.basePath`); despliegue detrás de subruta. |
| `DB_USER`, `DB_PASSWORD`, `DB_SERVER`, `DB_DATABASE`, `DB_PORT` | Conexión SQL Server. |
| `DB_ENCRYPT`, `DB_TRUST_CERT` | Opciones TLS del cliente mssql. |

## Cómo se organizan vistas y lógica

- **Lógica de negocio pesada**: en **SQL Server** (stored procedures); Node solo pasa parámetros y reenvía recordsets como JSON.
- **Presentación y agregación ligera**:
  - **Home**: KPIs y formateo en `routes/home.js`; series y tablas en JavaScript dentro de `views/home.ejs`.
  - **Otras pantallas**: el servidor solo renderiza el esqueleto HTML; el rellenado es **100 % cliente** con `fetch` a `/api/*`.

## Botón “Servicio OK” en la barra de navegación

En `layout.ejs` existe un botón `#svc-indicator` deshabilitado con el texto “Servicio OK”. **En el código del repositorio no hay script que actualice este elemento** ni que consulte `/health/db`; es solo UI presente en el layout.
