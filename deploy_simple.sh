#!/bin/bash

set -euo pipefail

echo "🚀 Déploiement Simplifié du CTF Bank..."
echo "   (Juste une clé API, on gère le reste !)"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier si on est root
if [ "$EUID" -eq 0 ]; then 
   ROOT_MODE=true
   SUDO_CMD=""
   SSH_KEY_DIR="/root/.ssh"
else
   ROOT_MODE=false
   SUDO_CMD="sudo"
   SSH_KEY_DIR="$HOME/.ssh"
fi

# Demander juste l'API key Proxmox
echo ""
echo -e "${YELLOW}Configuration minimale requise :${NC}"
read -p "API Key Proxmox (ou appuyez sur Entrée pour utiliser Ludus) : " PROXMOX_API_KEY

if [ -z "$PROXMOX_API_KEY" ]; then
    # Mode Ludus
    echo -e "${GREEN}Mode Ludus détecté${NC}"
    read -sp "Ludus API Key: " LUDUS_API_KEY
    echo ""
    
    if [ -z "$LUDUS_API_KEY" ]; then
        echo -e "${RED}Clé API requise. Abandon.${NC}"
        exit 1
    fi
    
    # Utiliser Ludus
    export LUDUS_API_KEY
    if ! command -v ludus &> /dev/null; then
        echo -e "${YELLOW}Installation de Ludus CLI...${NC}"
        curl -fsSL https://ludus.cloud/install.sh | bash
    fi
    
    ludus config set api-key "$LUDUS_API_KEY"
    echo -e "${GREEN}Déploiement via Ludus...${NC}"
    ludus deploy ludus/manifest.yml || {
        echo -e "${YELLOW}Ludus n'est pas configuré. Utilisons le mode Proxmox direct...${NC}"
        # Fallback sur mode Proxmox
        PROXMOX_API_KEY=""
    }
fi

# Mode Proxmox direct (si pas Ludus ou si Ludus échoue)
if [ -n "${PROXMOX_API_KEY:-}" ] || [ -z "${LUDUS_API_KEY:-}" ]; then
    echo -e "${GREEN}Mode Proxmox direct${NC}"
    
    # Questions minimales
    read -p "Hostname/IP Proxmox [192.168.1.100]: " PROXMOX_HOST
    PROXMOX_HOST=${PROXMOX_HOST:-192.168.1.100}
    
    read -p "Gateway réseau [192.168.1.1]: " GATEWAY
    GATEWAY=${GATEWAY:-192.168.1.1}
    
    # Générer les IPs automatiquement
    BASE_IP=$(echo "$GATEWAY" | cut -d'.' -f1-3)
    WEB_IP="${BASE_IP}.101"
    DAB_IP="${BASE_IP}.102"
    OLLAMA_IP="${BASE_IP}.103"
    
    echo -e "${GREEN}IPs générées automatiquement :${NC}"
    echo "  Web: $WEB_IP"
    echo "  DAB: $DAB_IP"
    echo "  Ollama: $OLLAMA_IP"
    
    # Générer les clés SSH si elles n'existent pas
    if [ ! -f "$SSH_KEY_DIR/id_rsa.pub" ]; then
        echo -e "${YELLOW}Génération des clés SSH...${NC}"
        mkdir -p "$SSH_KEY_DIR"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_DIR/id_rsa" -N "" -q
    fi
    
    # Créer vars.yml automatiquement
    cat > infra/vars.yml << EOF
---
# Généré automatiquement par deploy_simple.sh

# Proxmox API
proxmox_host: "$PROXMOX_HOST"
proxmox_user: "root@pam"
proxmox_token_id: "CTF"
proxmox_token_secret: "$PROXMOX_API_KEY"
proxmox_node: "pve"
proxmox_storage: "local"
proxmox_template: "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
proxmox_bridge: "vmbr0"
proxmox_gateway: "$GATEWAY"
proxmox_cidr: 24
proxmox_pool: "ctf"

# SSH
ssh_user: "debian"
ssh_public_key: "$SSH_KEY_DIR/id_rsa.pub"
ssh_private_key: "$SSH_KEY_DIR/id_rsa"

# Réseau des conteneurs
web_ip: "$WEB_IP"
dab_ip: "$DAB_IP"
ollama_ip: "$OLLAMA_IP"

# Ressources
web_ct_id: 201
web_cores: 2
web_memory: 2048
web_disk_gb: 8

dab_ct_id: 202
dab_cores: 2
dab_memory: 2048
dab_disk_gb: 8

ollama_ct_id: 203
ollama_cores: 4
ollama_memory: 8192
ollama_disk_gb: 20

# Modèle Ollama
ollama_model: "llama2:7b"

# Kali Linux
kali_template: "local:vztmpl/kali-rolling-standard_2024.1-1_amd64.tar.zst"
kali_base_ip: "${BASE_IP}.110"
kali_network_range: "${BASE_IP}.0/24"
kali_gateway: "$GATEWAY"
kali_base_ct_id: 210
kali_cores: 2
kali_memory: 4096
kali_disk_gb: 20
EOF

    echo -e "${GREEN}✅ Configuration générée automatiquement${NC}"
    
    # Lancer le déploiement normal
    ./deploy.sh
fi

