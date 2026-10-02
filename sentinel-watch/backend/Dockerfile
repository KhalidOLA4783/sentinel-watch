# ==============================================================================
# SentinelWatch Backend Dockerfile (Production & Google Cloud Run Ready)
# ==============================================================================

FROM python:3.11-slim AS base

# Empêche la génération de fichiers .pyc et active le flushing des logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8080

WORKDIR /app

# Installation des dépendances système nécessaires pour psycopg2 et scikit-learn
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copie et installation des dépendances Python
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Création d'un utilisateur non-root pour le durcissement sécurité (Principe du moindre privilège)
RUN useradd -m -u 1000 sentinel && \
    chown -R sentinel:sentinel /app

# Copie du code source de l'application
COPY --chown=sentinel:sentinel . /app

# Bascule sur l'utilisateur non-root
USER sentinel

# Exposition du port (Cloud Run utilise dynamiquement $PORT, par défaut 8080)
EXPOSE 8080

# Healthcheck natif Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/health || exit 1

# Démarrage avec Uvicorn liant le port dynamique $PORT
CMD ["sh", "-c", "exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]
