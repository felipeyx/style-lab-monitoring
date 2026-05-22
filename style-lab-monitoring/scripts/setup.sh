#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# setup.sh — Instala Docker e sobe o stack de monitoramento
# Testado em: Ubuntu 20.04 / 22.04 (Oracle Cloud Always Free)
# ─────────────────────────────────────────────────────────────────────────────
set -e

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║      Style Lab Monitoring — Setup Automático         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── 1. Atualizar sistema ──────────────────────────────────────────────────────
echo -e "${YELLOW}[1/5] Atualizando pacotes do sistema...${NC}"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get install -y -qq \
  ca-certificates curl gnupg lsb-release \
  git htop net-tools unzip stress-ng

# ── 2. Instalar Docker ────────────────────────────────────────────────────────
echo -e "${YELLOW}[2/5] Instalando Docker...${NC}"

if command -v docker &>/dev/null; then
  echo -e "${GREEN}  Docker já instalado: $(docker --version)${NC}"
else
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin

  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
  sudo systemctl start docker
  echo -e "${GREEN}  Docker instalado com sucesso!${NC}"
fi

# ── 3. Configurar firewall ────────────────────────────────────────────────────
echo -e "${YELLOW}[3/5] Configurando firewall (iptables)...${NC}"
sudo iptables -I INPUT -p tcp --dport 3000 -j ACCEPT  # Grafana
sudo iptables -I INPUT -p tcp --dport 9090 -j ACCEPT  # Prometheus
sudo iptables -I INPUT -p tcp --dport 9093 -j ACCEPT  # Alertmanager
sudo iptables -I INPUT -p tcp --dport 9100 -j ACCEPT  # Node Exporter
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT  # App
sudo iptables -I INPUT -p tcp --dport 8081 -j ACCEPT  # cAdvisor

# Persistir regras
sudo apt-get install -y -qq iptables-persistent 2>/dev/null || true
sudo netfilter-persistent save 2>/dev/null || true
echo -e "${GREEN}  Firewall configurado!${NC}"

# ── 4. Subir o stack ──────────────────────────────────────────────────────────
echo -e "${YELLOW}[4/5] Subindo containers...${NC}"
sudo docker compose up -d --build

# ── 5. Status ─────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[5/5] Verificando status...${NC}"
sleep 5
sudo docker compose ps

IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║              Stack no ar! Acesse:                    ║"
echo "╠══════════════════════════════════════════════════════╣"
printf "║  Grafana      →  http://%-28s║\n" "$IP:3000"
printf "║  Prometheus   →  http://%-28s║\n" "$IP:9090"
printf "║  Alertmanager →  http://%-28s║\n" "$IP:9093"
printf "║  App          →  http://%-28s║\n" "$IP:8080"
printf "║  cAdvisor     →  http://%-28s║\n" "$IP:8081"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Grafana login: admin / admin123                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}IMPORTANTE: Abra as portas acima na Security List do OCI!${NC}"
