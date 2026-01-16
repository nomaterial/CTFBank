#!/bin/bash

set -euo pipefail

echo "🖥️  Création de conteneurs Kali Linux pour participants..."

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
    echo -e "${YELLOW}Créez-le d'abord : cp infra/vars.example.yml infra/vars.yml${NC}"
    exit 1
fi

# Demander le nombre de conteneurs Kali
read -p "Combien de conteneurs Kali voulez-vous créer ? [1]: " kali_count
kali_count=${kali_count:-1}

if ! [[ "$kali_count" =~ ^[0-9]+$ ]] || [ "$kali_count" -lt 1 ]; then
    echo -e "${RED}Nombre invalide.${NC}"
    exit 1
fi

# Demander l'ID de départ
read -p "ID de départ pour les conteneurs ? [210]: " kali_start_id
kali_start_id=${kali_start_id:-210}

echo -e "${YELLOW}Création de ${kali_count} conteneur(s) Kali...${NC}"

# Lancer le playbook
ansible-playbook -i infra/inventory.ini infra/playbooks/create_kali.yml \
    -e @infra/vars.yml \
    -e "kali_count=${kali_count}" \
    -e "kali_start_id=${kali_start_id}"

echo ""
echo -e "${GREEN}✅ Conteneurs Kali créés avec succès!${NC}"
echo ""
echo -e "${YELLOW}Pour se connecter :${NC}"
echo "  ssh debian@<IP_KALI>"
echo ""
echo -e "${YELLOW}Pour voir les IPs, consultez Proxmox ou relancez avec -v${NC}"
