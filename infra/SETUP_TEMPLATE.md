# Configuration du Template LXC Proxmox

## ⚠️ IMPORTANT : Template requis

Le déploiement nécessite un **template LXC Debian 12** préalablement téléchargé sur Proxmox.

## Méthode 1 : Via SSH (Recommandé)

```bash
# Se connecter à Proxmox
ssh root@VOTRE_PROXMOX_IP

# Mettre à jour la liste des templates
pveam update

# Voir les templates Debian 12 disponibles
pveam available --section system | grep debian-12

# Télécharger le template (environ 200-300 MB)
pveam download local debian-12-standard_12.7-1_amd64.tar.zst

# Vérifier que le template est présent
pveam list local | grep debian-12
```

## Méthode 2 : Via l'interface Proxmox

1. Se connecter à l'interface web Proxmox
2. Aller dans **Datacenter** > `local` (ou votre storage) > **Content**
3. Onglet **Templates**
4. Cliquer sur **"Templates"** en haut
5. Rechercher `debian-12-standard`
6. Télécharger `debian-12-standard_12.7-1_amd64.tar.zst`

## Vérification

Après téléchargement, vérifier que le template existe :

```bash
pveam list local | grep debian-12
```

Vous devriez voir :
```
local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
```

## Note sur le storage

Le template doit être téléchargé sur le **même storage** que celui défini dans `vars.yml` :
- Par défaut : `local` ou `local-lvm`
- Vérifier dans `vars.yml` : `proxmox_storage: "local"`

## Template Kali Linux (pour participants)

Pour créer des conteneurs Kali pour les participants :

```bash
ssh root@VOTRE_PROXMOX_IP
pveam update
pveam available --section system | grep kali
pveam download local kali-rolling-standard_2024.1-1_amd64.tar.zst
```

**Note** : Le template Kali est plus volumineux (~500-700 MB).

## Alternative : Autres versions Debian

Si vous préférez une autre version :
- `debian-11-standard` (Debian 11)
- `ubuntu-22.04-standard` (Ubuntu 22.04)

**Modifier** dans `infra/vars.yml` :
```yaml
proxmox_template: "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
```

⚠️ Assurez-vous que l'utilisateur SSH configuré (`ssh_user`) existe dans le template choisi.
