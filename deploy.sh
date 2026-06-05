#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/Killpir/shvirtd-example-python.git"
APP_DIR="/opt/shvirtd-example-python"
COMPOSE_FILE="${APP_DIR}/compose.yaml"

echo "[1/9] Проверка зависимостей"
command -v git >/dev/null 2>&1 || { echo "git not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "docker compose not found"; exit 1; }

echo "[2/9] Подготовка каталога /opt"
mkdir -p /opt

echo "[3/9] Клонирование или обновление репозитория"
if [ -d "${APP_DIR}/.git" ]; then
  git -C "${APP_DIR}" fetch --all
  git -C "${APP_DIR}" reset --hard origin/main
else
  git clone "${REPO_URL}" "${APP_DIR}"
fi

echo "[4/9] Проверка compose-файла"
if [ ! -f "${COMPOSE_FILE}" ]; then
  echo "ERROR: ${COMPOSE_FILE} not found"
  exit 1
fi

echo "[5/9] Переход в каталог проекта"
cd "${APP_DIR}"

echo "[6/9] Остановка старого стека, если был"
docker compose -f "${COMPOSE_FILE}" down || true

echo "[7/9] Удаление старых одиночных контейнеров, если были ручные тесты"
docker rm -f shvirtd-mysql >/dev/null 2>&1 || true
docker rm -f shvirtd-app >/dev/null 2>&1 || true

echo "[8/9] Сборка и запуск проекта"
docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[9/9] Текущий статус"
docker compose -f "${COMPOSE_FILE}" ps
echo
echo "Локальная проверка:"
echo "curl -L http://127.0.0.1:8090"
