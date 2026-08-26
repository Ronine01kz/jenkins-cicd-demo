#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

echo "==> Деплой в окружение: ${ENVIRONMENT}"

case "$ENVIRONMENT" in
  dev)
    echo "Деплой в dev (заглушка): kubectl apply -f k8s/dev/ или docker-compose up -d"
    ;;
  staging)
    echo "Деплой в staging (заглушка): kubectl apply -f k8s/staging/"
    ;;
  production)
    echo "Деплой в production (заглушка): kubectl apply -f k8s/production/"
    ;;
  *)
    echo "Неизвестное окружение: ${ENVIRONMENT}"
    exit 1
    ;;
esac

echo "==> Деплой завершён"
