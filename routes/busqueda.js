import { Router } from "express";
const router = Router();

router.get("/", (_req, res) => {
  res.render("busqueda", { title: "Búsqueda" });
});

export default router;
