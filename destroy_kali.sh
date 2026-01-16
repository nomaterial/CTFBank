#!/bin/bash

set -euo pipefail

echo "🧨 Suppression de conteneurs Kali Linux..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Ne pas exécuter en tant que root.${NC}"
   exit 1
fi

if [ ! -f "infra/vars.yml" ]; then
    echo -e "${RED}Fichier infra/vars.yml introuvable.${NC}"
    exit 1
fi

# Demander le nombre de conteneurs à supprimer
read -p "Combien de conteneurs Kali voulez-vous supprimer ? [1]: " kali_count
kali_count=${kali_count:-1}

if ! [[ "$kali_count" =~ ^[0-9]+$ ]] || [ "$kali_count" -lt 1 ]; then
    echo -e "${RED}Nombre invalide.${NC}"
    exit 1
fi

# Demander l'ID de départ
read -p "ID de départ ? [210]: " kali_start_id
kali_start_id=${kali_start_id:-210}

# Confirmation
read -p "Voulez-vous vraiment supprimer ${kali_count} conteneur(s) Kali ? (oui/non): " confirm
if [ "$confirm" != "oui" ] && [ "$confirm" != "OUI" ] && [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo -e "${YELLOW}Annulé.${NC}"
    exit 0
fi

echo -e "${YELLOW}Suppression de ${kali_count} conteneur(s) Kali...${NC}"

ansible-playbook -i infra/inventory.ini infra/playbooks/destroy_kali.yml \
    -e @infra/vars.yml \
    -e "kali_count=${kali_count}" \
    -e "kali_start_id=${kali_start_id}"

echo -e "${GREEN}✅ Suppression terminée.${NC}"
