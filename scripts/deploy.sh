#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
IMAGE="${2:-jenkins-cicd-demo:latest}"
CONTAINER_NAME="jenkins-cicd-demo-${ENVIRONMENT}"
HOST_PORT="${3:-5000}"

echo "==> Деплой в окружение: ${ENVIRONMENT}"
echo "==> Образ: ${IMAGE}"

case "$ENVIRONMENT" in
  dev|staging)
    echo "Останавливаю старый контейнер (если есть)..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

    echo "Запускаю новый контейнер ${CONTAINER_NAME} на порту ${HOST_PORT}..."
    docker run -d \
      --name "${CONTAINER_NAME}" \
      --restart unless-stopped \
      -p "${HOST_PORT}:5000" \
      "${IMAGE}"

    echo "Жду, пока приложение поднимется..."
    sleep 2
    curl -sf "http://localhost:${HOST_PORT}/health" && echo "OK: приложение отвечает" || echo "ВНИМАНИЕ: /health не ответил, проверьте docker logs ${CONTAINER_NAME}"
    ;;
  production)
    echo "Для production смотрите вариант деплоя по SSH или в Kubernetes (см. README)."
    exit 1
    ;;
  *)
    echo "Неизвестное окружение: ${ENVIRONMENT}"
    exit 1
    ;;
esac

echo "==> Деплой завершён"
