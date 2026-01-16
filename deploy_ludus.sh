#!/bin/bash

set -euo pipefail

echo "🚀 Déploiement Ludus du CTF Bank..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier Ludus CLI
if ! command -v ludus &> /dev/null; then
    echo -e "${YELLOW}Installation de Ludus CLI...${NC}"
    curl -fsSL https://ludus.cloud/install.sh | bash
    export PATH="$HOME/.ludus/bin:$PATH"
fi

# Demander l'API key Ludus
if [ -z "${LUDUS_API_KEY:-}" ]; then
    echo -e "${YELLOW}Clé API Ludus requise.${NC}"
    read -sp "Entrez votre clé API Ludus: " LUDUS_API_KEY
    echo ""
    
    if [ -z "$LUDUS_API_KEY" ]; then
        echo -e "${RED}Clé API vide. Abandon.${NC}"
        exit 1
    fi
    
    export LUDUS_API_KEY
fi

# Configurer Ludus
ludus config set api-key "$LUDUS_API_KEY" || true

# Vérifier que la clé fonctionne
echo -e "${YELLOW}Vérification de la connexion Ludus...${NC}"
if ! ludus status &> /dev/null; then
    echo -e "${RED}Erreur de connexion à Ludus. Vérifiez votre clé API.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connexion Ludus OK${NC}"

# Déployer avec Ludus
echo -e "${GREEN}Déploiement du challenge CTF Bank...${NC}"
ludus deploy ludus/manifest.yml

# Récupérer les informations des modules déployés
echo ""
echo -e "${YELLOW}Récupération des informations de déploiement...${NC}"
sleep 5

WEB_INFO=$(ludus module info ctf-web 2>/dev/null || echo "")
DAB_INFO=$(ludus module info ctf-dab 2>/dev/null || echo "")
OLLAMA_INFO=$(ludus module info ctf-ollama 2>/dev/null || echo "")

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Déploiement terminé avec succès!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Pour voir les IPs des conteneurs:${NC}"
echo "  ludus module list"
echo ""
echo -e "${YELLOW}Pour voir les détails d'un module:${NC}"
echo "  ludus module info ctf-web"
echo "  ludus module info ctf-dab"
echo "  ludus module info ctf-ollama"
echo ""
echo -e "${YELLOW}Pour détruire le déploiement:${NC}"
echo "  ludus destroy"
echo ""

