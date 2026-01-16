#!/bin/bash

set -euo pipefail

echo "🚀 Déploiement Proxmox du CTF Bank..."

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier si on est root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}Ne pas exécuter en tant que root. Utilisez un utilisateur normal.${NC}"
   exit 1
fi

# Vérifier sudo et demander le mot de passe une fois
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}sudo n'est pas installé. Veuillez installer sudo puis relancer.${NC}"
    exit 1
fi

echo -e "${YELLOW}Vérification des droits sudo...${NC}"
sudo -v || {
    echo -e "${RED}Impossible d'obtenir les droits sudo. Abandon.${NC}"
    exit 1
}

# Réparer dpkg si interrompu
if dpkg --audit 2>/dev/null | grep -q "."; then
    echo -e "${YELLOW}dpkg est interrompu. Réparation en cours...${NC}"
    sudo dpkg --configure -a || {
        echo -e "${RED}Échec de la réparation dpkg. Corrigez manuellement puis relancez.${NC}"
        exit 1
    }
fi

# Installer dépendances
echo -e "${YELLOW}Installation des dépendances système...${NC}"
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    rsync \
    curl \
    git \
    sshpass \
    ansible || true

# Installer proxmoxer (module Proxmox)
if ! python3 -c "import proxmoxer" 2>/dev/null; then
    echo -e "${YELLOW}Installation de proxmoxer...${NC}"
    sudo apt-get install -y python3-proxmoxer || {
        sudo python3 -m pip install --break-system-packages proxmoxer requests
    }
fi

# Installer collection Ansible
echo -e "${YELLOW}Installation des collections Ansible...${NC}"
ansible-galaxy collection install -r infra/requirements.yml || true

# Vérifier le fichier de variables
if [ ! -f "infra/vars.yml" ]; then
    echo -e "${YELLOW}Fichier infra/vars.yml introuvable.${NC}"
    echo -e "${YELLOW}Création d'un fichier d'exemple...${NC}"
    cp infra/vars.example.yml infra/vars.yml
    echo -e "${RED}Veuillez éditer infra/vars.yml avec vos paramètres Proxmox, puis relancer.${NC}"
    exit 1
fi

# Lancer le déploiement
echo -e "${GREEN}Lancement du playbook de déploiement...${NC}"
ansible-playbook -i infra/inventory.ini infra/playbooks/site.yml -e @infra/vars.yml

# Résumé
WEB_IP=$(grep '^web_ip:' infra/vars.yml | awk '{print $2}' | tr -d '"')
DAB_IP=$(grep '^dab_ip:' infra/vars.yml | awk '{print $2}' | tr -d '"')
OLLAMA_IP=$(grep '^ollama_ip:' infra/vars.yml | awk '{print $2}' | tr -d '"')

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Déploiement terminé avec succès!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Web App : http://${WEB_IP}:5000${NC}"
echo -e "${GREEN}DAB Service : http://${DAB_IP}:8080${NC}"
echo -e "${GREEN}Ollama : http://${OLLAMA_IP}:11434${NC}"
echo ""

