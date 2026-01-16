#!/bin/bash

set -e

echo "🧹 Désinstallation complète du CTF Bank..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Demander confirmation
read -p "Êtes-vous sûr de vouloir désinstaller complètement ? (oui/non): " confirm
if [ "$confirm" != "oui" ] && [ "$confirm" != "OUI" ] && [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    echo -e "${YELLOW}Désinstallation annulée.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Démarrage de la désinstallation...${NC}"
echo ""

# Arrêter et supprimer les containers Docker
echo -e "${YELLOW}Arrêt des containers Docker...${NC}"
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
    cd "$(dirname "$0")" 2>/dev/null || true
    
    if [ -f "docker-compose.yml" ]; then
        if docker ps > /dev/null 2>&1; then
            docker-compose down -v 2>/dev/null || docker compose down -v 2>/dev/null || true
        elif sudo docker ps > /dev/null 2>&1; then
            sudo docker-compose down -v 2>/dev/null || sudo docker compose down -v 2>/dev/null || true
        fi
    fi
    echo -e "${GREEN}✓ Containers arrêtés et supprimés${NC}"
else
    echo -e "${YELLOW}Docker Compose non trouvé, passage à l'étape suivante${NC}"
fi

# Supprimer les images Docker du projet
echo -e "${YELLOW}Suppression des images Docker du projet...${NC}"
if command -v docker &> /dev/null; then
    PROJECT_NAME="ctfipssi"
    if docker ps -a > /dev/null 2>&1; then
        docker images | grep -E "ctfipssi|bank" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
        docker images | grep "dab" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    elif sudo docker ps -a > /dev/null 2>&1; then
        sudo docker images | grep -E "ctfipssi|bank" | awk '{print $3}' | xargs -r sudo docker rmi -f 2>/dev/null || true
        sudo docker images | grep "dab" | awk '{print $3}' | xargs -r sudo docker rmi -f 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Images supprimées${NC}"
fi

# Nettoyer les volumes orphelins
echo -e "${YELLOW}Nettoyage des volumes Docker...${NC}"
if command -v docker &> /dev/null; then
    if docker ps > /dev/null 2>&1; then
        docker volume prune -f 2>/dev/null || true
    elif sudo docker ps > /dev/null 2>&1; then
        sudo docker volume prune -f 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Volumes nettoyés${NC}"
fi

# Arrêter Ollama si démarré par le script
echo -e "${YELLOW}Arrêt d'Ollama...${NC}"
if [ -f "/tmp/ollama.pid" ]; then
    OLLAMA_PID=$(cat /tmp/ollama.pid 2>/dev/null || echo "")
    if [ ! -z "$OLLAMA_PID" ] && kill -0 "$OLLAMA_PID" 2>/dev/null; then
        kill "$OLLAMA_PID" 2>/dev/null || true
        echo -e "${GREEN}✓ Processus Ollama arrêté${NC}"
    fi
    rm -f /tmp/ollama.pid
fi

# Arrêter Ollama via systemd si présent
if systemctl --user list-units --type=service 2>/dev/null | grep -q ollama; then
    systemctl --user stop ollama 2>/dev/null || true
    echo -e "${GREEN}✓ Service Ollama arrêté${NC}"
fi

# Tuer les processus Ollama restants
if pgrep -f "ollama" > /dev/null 2>&1; then
    pkill -f "ollama" 2>/dev/null || true
    sleep 2
    echo -e "${GREEN}✓ Processus Ollama terminés${NC}"
fi

# Supprimer les fichiers générés du projet
echo -e "${YELLOW}Suppression des fichiers générés...${NC}"
cd "$(dirname "$0")" 2>/dev/null || true

# Fichiers à supprimer
FILES_TO_REMOVE=(
    "bank.db"
    "flag.txt"
    "app/flag.txt"
    ".webassets-cache"
    "__pycache__"
    "app/__pycache__"
    "*.pyc"
    "*.pyo"
    "*.log"
    "dab_scripts/*"
)

for pattern in "${FILES_TO_REMOVE[@]}"; do
    find . -name "$pattern" -type f -delete 2>/dev/null || true
    find . -name "$pattern" -type d -exec rm -rf {} + 2>/dev/null || true
done

# Nettoyer dab_scripts mais garder le répertoire
if [ -d "dab_scripts" ]; then
    rm -rf dab_scripts/* 2>/dev/null || true
    find dab_scripts -type f ! -name ".gitkeep" -delete 2>/dev/null || true
fi

echo -e "${GREEN}✓ Fichiers générés supprimés${NC}"

# Demander si on veut supprimer Docker et Ollama
echo ""
read -p "Voulez-vous désinstaller Docker et Docker Compose ? (oui/non) [non]: " remove_docker
if [ "$remove_docker" = "oui" ] || [ "$remove_docker" = "OUI" ] || [ "$remove_docker" = "o" ] || [ "$remove_docker" = "O" ]; then
    echo -e "${YELLOW}Désinstallation de Docker...${NC}"
    
    # Arrêter Docker
    if command -v docker &> /dev/null; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            sudo systemctl stop docker 2>/dev/null || true
        fi
    fi
    
    # Désinstaller Docker (Ubuntu/Debian)
    if command -v apt-get &> /dev/null; then
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose 2>/dev/null || true
        sudo apt-get autoremove -y 2>/dev/null || true
        sudo rm -rf /var/lib/docker 2>/dev/null || true
        sudo rm -rf /etc/docker 2>/dev/null || true
        echo -e "${GREEN}✓ Docker désinstallé${NC}"
    fi
fi

echo ""
read -p "Voulez-vous désinstaller Ollama ? (oui/non) [non]: " remove_ollama
if [ "$remove_ollama" = "oui" ] || [ "$remove_ollama" = "OUI" ] || [ "$remove_ollama" = "o" ] || [ "$remove_ollama" = "O" ]; then
    echo -e "${YELLOW}Désinstallation d'Ollama...${NC}"
    
    # Arrêter Ollama
    if command -v ollama &> /dev/null; then
        ollama stop 2>/dev/null || true
    fi
    
    # Supprimer Ollama et les modèles
    if [ -f "/usr/local/bin/ollama" ]; then
        sudo rm -f /usr/local/bin/ollama 2>/dev/null || true
    fi
    
    # Supprimer les modèles (~/.ollama peut être gros)
    if [ -d "$HOME/.ollama" ]; then
        echo -e "${YELLOW}Suppression des modèles Ollama (~/.ollama)...${NC}"
        read -p "Cela supprimera tous les modèles téléchargés. Continuer ? (oui/non): " remove_models
        if [ "$remove_models" = "oui" ] || [ "$remove_models" = "OUI" ]; then
            rm -rf "$HOME/.ollama" 2>/dev/null || true
            echo -e "${GREEN}✓ Modèles Ollama supprimés${NC}"
        fi
    fi
    
    # Supprimer le service systemd
    if [ -f "$HOME/.config/systemd/user/ollama.service" ]; then
        systemctl --user stop ollama 2>/dev/null || true
        systemctl --user disable ollama 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/ollama.service" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓ Ollama désinstallé${NC}"
fi

# Nettoyer le cache Docker
echo -e "${YELLOW}Nettoyage du cache Docker...${NC}"
if command -v docker &> /dev/null; then
    if docker ps > /dev/null 2>&1; then
        docker system prune -af --volumes 2>/dev/null || true
    elif sudo docker ps > /dev/null 2>&1; then
        sudo docker system prune -af --volumes 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Cache Docker nettoyé${NC}"
fi

# Supprimer les fichiers temporaires Python
echo -e "${YELLOW}Nettoyage des fichiers Python...${NC}"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
echo -e "${GREEN}✓ Fichiers Python nettoyés${NC}"

# Résumé final
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Désinstallation terminée!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Fichiers restants dans le répertoire:${NC}"
echo "  - Code source de l'application (app/, templates/, etc.)"
echo "  - Fichiers de configuration (docker-compose.yml, Dockerfile, etc.)"
echo "  - Scripts (deploy.sh, uninstall.sh)"
echo ""
echo -e "${YELLOW}Pour réinstaller:${NC}"
echo "  ./deploy.sh"
echo ""
echo -e "${YELLOW}Pour supprimer complètement le projet:${NC}"
echo "  cd .. && rm -rf CTFIPSSI"
echo ""

