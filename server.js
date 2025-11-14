import "dotenv/config";
import express from "express";
import morgan from "morgan";
import path from "path";
import { fileURLToPath } from "url";
import expressLayouts from "express-ejs-layouts";  // <-- NUEVO
import homeRouter from "./routes/home.js";
import metricasRouter from "./routes/metricas.js";
import cierresRouter from "./routes/cierres.js";
import busquedaRouter from "./routes/busqueda.js";
import healthRouter from "./routes/health.js";
import apiRouter from "./routes/api.js";



const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const BASE_PATH = process.env.BASE_PATH || "";

// EJS
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "ejs");
app.use(expressLayouts);                 // <-- NUEVO
app.set("layout", "layout");             // <-- usa views/layout.ejs por defecto

// Static
app.use("/public", express.static(path.join(__dirname, "public")));

// Logs
app.use(morgan("dev"));

// Base path para deploy detrás de /dashboard-whatsapp
app.use((req, res, next) => {
  res.locals.basePath = BASE_PATH;   // ej: "" en local, "/dashboard-whatsapp" en server
  next();
});

// Marca activa para navbar
app.use((req, res, next) => {
  res.locals.nav = {
    general:  req.path === "/",
    detalle:  req.path.startsWith("/metricas"),
    cierres:  req.path.startsWith("/cierres"),
    busqueda: req.path.startsWith("/busqueda"),
  };
  next();
});


// Rutas
app.use("/", homeRouter);
app.use("/metricas", metricasRouter);
app.use("/cierres", cierresRouter);
app.use("/busqueda", busquedaRouter);
app.use("/health", healthRouter);
app.use("/api", apiRouter);

const PORT = process.env.PORT || 3007;
app.listen(PORT, () => console.log(`Servidor en http://localhost:${PORT}`));
