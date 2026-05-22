#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# troubleshoot.sh — Comandos úteis para diagnóstico e troubleshooting
# ─────────────────────────────────────────────────────────────────────────────

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

show_menu() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║        Troubleshooting — Style Lab           ║"
  echo "╠══════════════════════════════════════════════╣"
  echo "║  1) Status de todos os containers            ║"
  echo "║  2) Logs em tempo real (todos)               ║"
  echo "║  3) Logs de um container específico          ║"
  echo "║  4) Uso de recursos (CPU/RAM)                ║"
  echo "║  5) Simular carga de CPU                     ║"
  echo "║  6) Simular uso de memória                   ║"
  echo "║  7) Verificar targets do Prometheus          ║"
  echo "║  8) Verificar alertas ativos                 ║"
  echo "║  9) Reiniciar todos os serviços              ║"
  echo "║ 10) Limpar volumes (CUIDADO: apaga dados)    ║"
  echo "║  0) Sair                                     ║"
  echo "╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "Escolha: " opcao
}

while true; do
  show_menu
  case $opcao in
    1)
      echo -e "${YELLOW}Status dos containers:${NC}"
      docker compose ps
      ;;
    2)
      echo -e "${YELLOW}Logs em tempo real (Ctrl+C para sair):${NC}"
      docker compose logs -f
      ;;
    3)
      read -rp "Nome do container (prometheus/grafana/app/node-exporter/cadvisor/alertmanager): " svc
      docker compose logs -f "$svc"
      ;;
    4)
      echo -e "${YELLOW}Uso de recursos (Ctrl+C para sair):${NC}"
      docker stats
      ;;
    5)
      read -rp "Duração em segundos (ex: 60): " dur
      echo -e "${YELLOW}Simulando carga de CPU por ${dur}s...${NC}"
      stress-ng --cpu "$(nproc)" --timeout "${dur}s" --metrics-brief
      ;;
    6)
      read -rp "Quantidade de memória (ex: 2G): " mem
      read -rp "Duração em segundos (ex: 30): " dur
      echo -e "${YELLOW}Simulando uso de ${mem} RAM por ${dur}s...${NC}"
      stress-ng --vm 1 --vm-bytes "$mem" --timeout "${dur}s"
      ;;
    7)
      echo -e "${YELLOW}Targets ativos no Prometheus:${NC}"
      curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool 2>/dev/null \
        || curl -s http://localhost:9090/api/v1/targets
      ;;
    8)
      echo -e "${YELLOW}Alertas ativos:${NC}"
      curl -s http://localhost:9090/api/v1/alerts | python3 -m json.tool 2>/dev/null \
        || curl -s http://localhost:9090/api/v1/alerts
      ;;
    9)
      echo -e "${YELLOW}Reiniciando todos os serviços...${NC}"
      docker compose restart
      docker compose ps
      ;;
    10)
      read -rp "Tem certeza? Isso apagará todos os dados (s/N): " conf
      if [[ "$conf" =~ ^[sS]$ ]]; then
        docker compose down -v
        echo -e "${GREEN}Volumes removidos.${NC}"
      fi
      ;;
    0)
      echo -e "${GREEN}Até mais!${NC}"
      exit 0
      ;;
    *)
      echo -e "${YELLOW}Opção inválida.${NC}"
      ;;
  esac
  echo ""
  read -rp "Pressione Enter para continuar..."
done
