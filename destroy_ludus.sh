#!/bin/bash

set -euo pipefail

echo "🧨 Destruction Ludus du CTF Bank..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier Ludus CLI
if ! command -v ludus &> /dev/null; then
    echo -e "${RED}Ludus CLI n'est pas installé.${NC}"
    exit 1
fi

# Confirmation
read -p "Voulez-vous vraiment détruire le déploiement Ludus ? (oui/non): " confirm
if [ "$confirm" != "oui" ] && [ "$confirm" != "OUI" ] && [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo -e "${YELLOW}Annulé.${NC}"
    exit 0
fi

echo -e "${YELLOW}Destruction en cours...${NC}"
ludus destroy

echo -e "${GREEN}✅ Destruction terminée.${NC}"

