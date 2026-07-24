#!/bin/bash
set -e

if [ "$DBENGINE" = "django.db.backends.postgresql" ] && [ -n "$DBHOST" ]; then
  DBPORT="${DBPORT:-5432}"
  echo "Waiting for PostgreSQL at ${DBHOST}:${DBPORT}..."
  retries=0
  max_retries=60
  while ! python - <<'PY' 2>/dev/null
import os
import socket
host = os.environ.get("DBHOST", "db")
port = int(os.environ.get("DBPORT", "5432"))
with socket.create_connection((host, port), timeout=2):
    pass
PY
  do
      retries=$((retries + 1))
      if [ "$retries" -ge "$max_retries" ]; then
          echo "ERROR: Could not connect to PostgreSQL after $max_retries attempts."
          exit 1
      fi
      echo "  PostgreSQL not ready yet (attempt $retries/$max_retries)..."
      sleep 2
  done
  echo "PostgreSQL is ready."
else
  echo "Using SQLite database; skipping PostgreSQL connection check."
fi

echo "Running migrations..."
python manage.py migrate --noinput

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting server (Gunicorn with Threaded Workers)..."
exec gunicorn crm.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --threads 4 \
    --worker-class gthread \
    --worker-connections 1000 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -