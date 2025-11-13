import { Router } from "express";
const router = Router();

router.get("/", (_req, res) => {
  res.render("cierres", { title: "Cierres" });
});

export default router;
