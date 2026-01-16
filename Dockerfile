FROM python:3.11-slim

WORKDIR /app

# Installer dépendances système + Java (pour compiler/exécuter le code Java)
RUN apt-get update && apt-get install -y \
    gcc \
    netcat-traditional \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

# Copier requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier l'application
COPY app/ /app/
COPY init_db.py /app/

# Créer un utilisateur non-root pour la sécurité
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]

