import { Router } from "express";
const router = Router();

router.get("/", (_req, res) => {
  res.render("metricas", { title: "Detalle" });
});

export default router;
