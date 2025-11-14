module.exports = {
  apps: [
    {
      name: "dashboard-whatsapp",
      script: "server.js",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "development",
        PORT: 3007,
        // opcional, por si querés cargar otro .env en dev
        DOTENV_CONFIG_PATH: ".env"
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 3007,
        // acá le decimos a dotenv que use .env.production
        DOTENV_CONFIG_PATH: ".env.production"
      }
    }
  ]
};
