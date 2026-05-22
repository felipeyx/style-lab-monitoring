const http = require("http");
const { Registry, Counter, Histogram, Gauge } = require("prom-client");

const register = new Registry();

// ── Métricas personalizadas ────────────────────────────────────────────────
const httpRequestsTotal = new Counter({
  name: "http_requests_total",
  help: "Total de requisições HTTP recebidas",
  labelNames: ["method", "route", "status_code"],
  registers: [register],
});

const httpDuration = new Histogram({
  name: "http_request_duration_seconds",
  help: "Duração das requisições HTTP em segundos",
  labelNames: ["method", "route"],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5],
  registers: [register],
});

const activeConnections = new Gauge({
  name: "app_active_connections",
  help: "Conexões ativas no momento",
  registers: [register],
});

const appInfo = new Gauge({
  name: "app_info",
  help: "Informações da aplicação",
  labelNames: ["version", "node_version"],
  registers: [register],
});

appInfo.set({ version: "1.0.0", node_version: process.version }, 1);

// ── Servidor HTTP ──────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const start = Date.now();
  activeConnections.inc();

  // Endpoint de métricas para o Prometheus
  if (req.url === "/metrics") {
    res.setHeader("Content-Type", register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
    activeConnections.dec();
    return;
  }

  // Health check
  if (req.url === "/health") {
    const body = JSON.stringify({ status: "ok", uptime: process.uptime() });
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(body);
    httpRequestsTotal.inc({ method: req.method, route: "/health", status_code: 200 });
    httpDuration.observe({ method: req.method, route: "/health" }, (Date.now() - start) / 1000);
    activeConnections.dec();
    return;
  }

  // Rota principal
  if (req.url === "/") {
    const body = JSON.stringify({
      message: "Style Lab Monitoring — API rodando!",
      endpoints: ["/", "/health", "/metrics", "/simulate/load"],
    });
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(body);
    httpRequestsTotal.inc({ method: req.method, route: "/", status_code: 200 });
    httpDuration.observe({ method: req.method, route: "/" }, (Date.now() - start) / 1000);
    activeConnections.dec();
    return;
  }

  // Simulação de carga para testes
  if (req.url === "/simulate/load") {
    let sum = 0;
    for (let i = 0; i < 1e7; i++) sum += Math.sqrt(i);
    const body = JSON.stringify({ result: sum, message: "Carga simulada com sucesso" });
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(body);
    httpRequestsTotal.inc({ method: req.method, route: "/simulate/load", status_code: 200 });
    httpDuration.observe({ method: req.method, route: "/simulate/load" }, (Date.now() - start) / 1000);
    activeConnections.dec();
    return;
  }

  // 404
  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Rota não encontrada" }));
  httpRequestsTotal.inc({ method: req.method, route: "unknown", status_code: 404 });
  activeConnections.dec();
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`App rodando na porta ${PORT}`);
  console.log(`Métricas disponíveis em http://localhost:${PORT}/metrics`);
});
