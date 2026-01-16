# DAB Service

Ce répertoire contient les fichiers nécessaires au service DAB :
- `dab_service.py` : API Flask exposant `/api/execute_java` et `/api/replace_monitor`
- `monitor.sh` : script exécuté par cron (root) toutes les 30s
- `dab.service` : unité systemd
- `cron_dab` : configuration cron
