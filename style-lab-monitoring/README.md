# Style Lab Monitoring 📊

Ambiente de **infraestrutura em nuvem** com monitoramento e observabilidade completos, rodando na **Oracle Cloud Always Free** com Docker, Prometheus e Grafana.

![CI](https://github.com/SEU_USUARIO/style-lab-monitoring/actions/workflows/ci.yml/badge.svg)

---

## Arquitetura

```
Internet
    │
    ▼
VM Oracle Cloud (Ubuntu 22.04 — Ampere ARM, Always Free)
    │
    └── Docker Compose Stack
            ├── App (Node.js)          :8080  → métricas customizadas
            ├── Node Exporter          :9100  → métricas do host
            ├── cAdvisor               :8081  → métricas dos containers
            ├── Prometheus             :9090  → coleta e armazena
            ├── Alertmanager           :9093  → dispara alertas
            └── Grafana                :3000  → dashboards visuais
```

---

## Pré-requisitos

- Conta Oracle Cloud ([sempre gratuita](https://www.oracle.com/cloud/free/))
- VM criada: **Ubuntu 22.04**, shape **VM.Standard.A1.Flex** (4 vCPU / 24 GB RAM)
- Portas abertas na Security List: `22`, `3000`, `8080`, `8081`, `9090`, `9093`, `9100`

---

## Deploy rápido

```bash
# 1. Conectar na VM
ssh -i sua-chave.key ubuntu@SEU_IP

# 2. Clonar o repositório
git clone https://github.com/SEU_USUARIO/style-lab-monitoring.git
cd style-lab-monitoring

# 3. Rodar o setup (instala Docker e sobe tudo)
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Pronto. Acesse `http://SEU_IP:3000` e faça login no Grafana.

---

## Acesso aos serviços

| Serviço       | URL                          | Login         |
|---------------|------------------------------|---------------|
| Grafana        | `http://SEU_IP:3000`        | admin / admin123 |
| Prometheus     | `http://SEU_IP:9090`        | —             |
| Alertmanager   | `http://SEU_IP:9093`        | —             |
| App (API)      | `http://SEU_IP:8080`        | —             |
| cAdvisor       | `http://SEU_IP:8081`        | —             |

---

## Configurar dashboard no Grafana

1. Acesse Grafana → **Dashboards → Import**
2. Digite o ID `1860` (Node Exporter Full) e clique **Load**
3. Selecione o datasource **Prometheus** e clique **Import**

Você terá CPU, memória, disco, rede e temperatura em tempo real.

---

## Estrutura do projeto

```
style-lab-monitoring/
├── docker-compose.yml          # Orquestração de todos os serviços
├── prometheus/
│   ├── prometheus.yml          # Configuração de scrape
│   └── alerts.yml              # Regras de alertas
├── alertmanager/
│   └── alertmanager.yml        # Roteamento de alertas
├── grafana/
│   └── provisioning/
│       ├── datasources/        # Prometheus configurado automaticamente
│       └── dashboards/         # Dashboards carregados automaticamente
├── app/
│   ├── index.js                # API Node.js com métricas Prometheus
│   ├── package.json
│   └── Dockerfile
├── scripts/
│   ├── setup.sh                # Instalação completa automatizada
│   └── troubleshoot.sh         # Menu interativo de diagnóstico
└── .github/
    └── workflows/
        └── ci.yml              # CI: valida configs e build da imagem
```

---

## Alertas configurados

| Alerta           | Condição                        | Severidade |
|------------------|---------------------------------|------------|
| CPU_Alta         | CPU > 80% por 2 minutos         | warning    |
| CPU_Critica      | CPU > 95% por 1 minuto          | critical   |
| Memoria_Baixa    | RAM disponível < 20%            | warning    |
| Memoria_Critica  | RAM disponível < 5%             | critical   |
| Disco_Cheio      | Disco > 80%                     | warning    |
| Disco_Critico    | Disco > 95%                     | critical   |
| Instancia_Fora   | Target inacessível por 1 min    | critical   |
| Rede_Saturada    | > 100 MB/s por 5 minutos        | warning    |

---

## Comandos úteis

```bash
# Subir o stack
docker compose up -d

# Ver status de todos os containers
docker compose ps

# Logs em tempo real
docker compose logs -f

# Logs de um serviço específico
docker compose logs -f prometheus

# Uso de recursos
docker stats

# Reiniciar um serviço
docker compose restart grafana

# Parar tudo
docker compose down

# Parar e remover volumes (apaga dados)
docker compose down -v
```

### Simulação de carga para testes

```bash
# Instalar stress-ng (se ainda não tiver)
sudo apt install stress-ng -y

# Simular carga de CPU por 60 segundos
stress-ng --cpu $(nproc) --timeout 60s

# Simular uso de 4GB de RAM por 30 segundos
stress-ng --vm 1 --vm-bytes 4G --timeout 30s
```

### Usar o menu de troubleshooting

```bash
chmod +x scripts/troubleshoot.sh
./scripts/troubleshoot.sh
```

---

## Endpoints da App

| Método | Rota              | Descrição                        |
|--------|-------------------|----------------------------------|
| GET    | `/`               | Informações da API               |
| GET    | `/health`         | Health check                     |
| GET    | `/metrics`        | Métricas no formato Prometheus   |
| GET    | `/simulate/load`  | Simula carga de CPU              |

---

## Tecnologias

- **Oracle Cloud Always Free** — Infraestrutura gratuita
- **Ubuntu 22.04** — Sistema operacional
- **Docker + Docker Compose** — Containerização
- **Prometheus** — Coleta e armazenamento de métricas
- **Grafana** — Visualização e dashboards
- **Alertmanager** — Gerenciamento de alertas
- **Node Exporter** — Métricas do sistema operacional
- **cAdvisor** — Métricas dos containers
- **Node.js** — Aplicação de exemplo com métricas customizadas
- **GitHub Actions** — CI/CD

---

## Licença

MIT
