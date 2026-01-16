#!/bin/bash

set -euo pipefail

echo "🧨 Destruction Proxmox du CTF Bank..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Ne pas exécuter en tant que root. Utilisez un utilisateur normal.${NC}"
   exit 1
fi

if [ ! -f "infra/vars.yml" ]; then
    echo -e "${RED}Fichier infra/vars.yml introuvable.${NC}"
    exit 1
fi

# Confirmation
read -p "Voulez-vous vraiment supprimer les conteneurs Proxmox ? (oui/non): " confirm
if [ "$confirm" != "oui" ] && [ "$confirm" != "OUI" ] && [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo -e "${YELLOW}Annulé.${NC}"
    exit 0
fi

echo -e "${YELLOW}Lancement du playbook de destruction...${NC}"
ansible-playbook -i infra/inventory.ini infra/playbooks/destroy.yml -e @infra/vars.yml

echo -e "${GREEN}✅ Destruction terminée.${NC}"
