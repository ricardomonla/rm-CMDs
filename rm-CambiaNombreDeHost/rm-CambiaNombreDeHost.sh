#!/bin/bash

# Lic. Ricardo MONLA (https://github.com/ricardomonla)
#
# rm-CambiaNombreDeHost: v251222-1830
#
# rmCMD=rm-CambiaNombreDeHost.sh && bash -c "$(curl -fsSL https://github.com/ricardomonla/RM-rmCMDs/raw/refs/heads/main/rm-CambiaNombreDeHost/${rmCMD})"

rmCMD="rm-CambiaNombreDeHost.sh"

cat << 'SHELL' > "${rmCMD}"
#!/usr/bin/env bash
# ==============================================================
# Script de Cambio de Hostname en Debian 12
# Autor: Lic. Ricardo MONLA (https://github.com/ricardomonla)
# Versión: v251222-1830
# ==============================================================

# --- Variables de Identificación ---
SCRIPT_NAME=$(basename "$0")
SCRIPT_VERSION="v251222-1830"

# --- Colores ---
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# --- Asegurar ejecución como root ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}🔒 Se requieren permisos de root. Reejecutando con sudo...${RESET}"
  exec sudo bash "$0" "$@"
fi

# --- Funciones ---

banner() {
  clear
  echo -e "${BOLD}${CYAN}==============================================================${RESET}"
  echo -e "${BOLD}${GREEN} Script: $SCRIPT_NAME${RESET}"
  echo -e "${BOLD}${GREEN} Autor : Lic. Ricardo MONLA (https://github.com/ricardomonla)${RESET}"
  echo -e "${BOLD}${GREEN} Vers. : $SCRIPT_VERSION${RESET}"
  echo -e "${BOLD}${CYAN}==============================================================${RESET}"
}

sanitizar_input() {
  # Convierte a minúsculas, cambia _ por - y elimina caracteres no permitidos
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | sed 's/[^a-z0-9-]//g'
}

aplicar_cambios() {
  local nuevo_host=$1
  
  echo -e "\n${BOLD}${BLUE}⏳ Aplicando cambios...${RESET}"
  
  # 1. Cambiar hostname del sistema (kernel y systemd)
  hostnamectl set-hostname "$nuevo_host"
  
  # 2. Asegurar archivo /etc/hostname
  echo "$nuevo_host" > /etc/hostname

  # 3. Actualizar /etc/hosts preservando la estructura
  # Busca la línea que empieza por 127.0.1.1 y reemplaza el segundo campo
  if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$nuevo_host/" /etc/hosts
  else
    echo -e "127.0.1.1\t$nuevo_host" >> /etc/hosts
  fi

  echo -e "${GREEN}✅ Hostname cambiado exitosamente a: ${BOLD}$nuevo_host${RESET}"
  echo -e "${CYAN}ℹ️  Nota: Es recomendable reiniciar la sesión o el servidor para que todos los procesos detecten el cambio.${RESET}"
}

# --- Flujo Principal ---
banner

CUR_HOST=$(hostnamectl --static)
echo -e "${BOLD}Hostname Actual:${RESET} ${RED}$CUR_HOST${RESET}"
echo ""
echo -e "Ingrese el nuevo nombre para el servidor."
echo -e "${YELLOW}Nota: Se corregirán automáticamente mayúsculas y guiones bajos (_).${RESET}"
read -p "Nuevo Hostname (Enter para cancelar): " USER_INPUT

# Si está vacío, salir
if [ -z "$USER_INPUT" ]; then
  echo -e "${RED}❌ Cancelado por el usuario.${RESET}"
  exit 0
fi

# Sanitización automática
FINAL_HOST=$(sanitizar_input "$USER_INPUT")

echo -e "\n${BOLD}${BLUE}📊 Verificación:${RESET}"
echo -e "  Entrada original : $USER_INPUT"
echo -e "  Nombre válido    : ${MAGENTA}$FINAL_HOST${RESET} (Estándar RFC 1123)"

if [ "$CUR_HOST" == "$FINAL_HOST" ]; then
  echo -e "${YELLOW}⚠️  El nombre nuevo es igual al actual. No se requieren cambios.${RESET}"
  exit 0
fi

echo ""
read -p "¿Desea aplicar este cambio ahora? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
  aplicar_cambios "$FINAL_HOST"
else
  echo -e "${RED}❌ Operación cancelada.${RESET}"
fi

SHELL

# Dar permisos de ejecución al script generado
chmod +x "${rmCMD}"

# Ejecutar el script
./"${rmCMD}"
