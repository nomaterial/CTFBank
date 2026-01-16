# Déploiement Manuel - CTF Bank

Guide simple pour déployer manuellement sur 3 VMs.

## 📋 Prérequis

- 3 VMs/Conteneurs LXC sur Proxmox (Debian 12)
- Accès SSH à chaque VM
- Git installé sur chaque VM

## 🖥️ VMs à Créer

1. **VM Web** (`ctf-web`) - Application Flask
2. **VM DAB** (`ctf-dab`) - Service DAB + cron root
3. **VM Ollama** (`ctf-ollama`) - Modèle LLM Ollama

## 🚀 Déploiement VM Web

```bash
# Se connecter à la VM web
ssh debian@VM_WEB_IP

# Cloner le repo
git clone https://github.com/nomaterial/CTFBank.git
cd CTFBank

# Installer Python et dépendances
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv sqlite3

# Créer environnement virtuel
python3 -m venv .venv
source .venv/bin/activate

# Installer dépendances
pip install -r requirements.txt

# Initialiser la base de données
python init_db.py

# Configurer les variables d'environnement (remplacer par les IPs réelles)
export OLLAMA_HOST="http://VM_OLLAMA_IP:11434"
export DAB_HOST="http://VM_DAB_IP:8080"

# Créer le service systemd
sudo tee /etc/systemd/system/ctfbank.service > /dev/null <<EOF
[Unit]
Description=CTF Bank Web App
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=OLLAMA_HOST=http://VM_OLLAMA_IP:11434
Environment=DAB_HOST=http://VM_DAB_IP:8080
ExecStart=$(pwd)/.venv/bin/python $(pwd)/app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Démarrer le service
sudo systemctl daemon-reload
sudo systemctl enable ctfbank
sudo systemctl start ctfbank

# Vérifier
sudo systemctl status ctfbank
```

## 🏧 Déploiement VM DAB

```bash
# Se connecter à la VM DAB
ssh debian@VM_DAB_IP

# Cloner le repo
git clone https://github.com/nomaterial/CTFBank.git
cd CTFBank/dab

# Installer dépendances
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv openjdk-11-jdk cron

# Créer environnement virtuel
python3 -m venv .venv
source .venv/bin/activate

# Installer Flask
pip install -r requirements.txt

# Créer les répertoires
sudo mkdir -p /opt/dab/logs
sudo cp -r * /opt/dab/
sudo chmod +x /opt/dab/monitor.sh

# Installer le service DAB
sudo tee /etc/systemd/system/dab.service > /dev/null <<EOF
[Unit]
Description=DAB Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/dab
ExecStart=/opt/dab/.venv/bin/python /opt/dab/dab_service.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Installer le cron
sudo cp cron_dab /etc/cron.d/dab-monitor
sudo chmod 0644 /etc/cron.d/dab-monitor

# Démarrer les services
sudo systemctl daemon-reload
sudo systemctl enable cron
sudo systemctl enable dab
sudo systemctl restart cron
sudo systemctl start dab

# Vérifier
sudo systemctl status dab
```

## 🤖 Déploiement VM Ollama

```bash
# Se connecter à la VM Ollama
ssh debian@VM_OLLAMA_IP

# Installer Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Configurer Ollama pour écouter sur le réseau
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment=OLLAMA_HOST=0.0.0.0:11434
EOF

# Redémarrer Ollama
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Télécharger le modèle (peut prendre plusieurs minutes)
ollama pull llama2:7b

# Vérifier
curl http://localhost:11434/api/tags
```

## 🔗 Configuration Réseau

Une fois les 3 VMs déployées :

1. **Sur la VM Web** : Modifier les variables d'environnement dans `/etc/systemd/system/ctfbank.service`
   - `OLLAMA_HOST=http://VM_OLLAMA_IP:11434`
   - `DAB_HOST=http://VM_DAB_IP:8080`

2. **Redémarrer le service web** :
   ```bash
   sudo systemctl restart ctfbank
   ```

## ✅ Vérification

- **Web** : `http://VM_WEB_IP:5000`
- **DAB** : `http://VM_DAB_IP:8080`
- **Ollama** : `http://VM_OLLAMA_IP:11434`

## 📝 Notes

- Les services démarrent automatiquement au boot
- Les logs : `sudo journalctl -u ctfbank -f` (web) ou `sudo journalctl -u dab -f` (dab)
- Pour mettre à jour : `git pull` dans chaque repo, puis redémarrer les services

