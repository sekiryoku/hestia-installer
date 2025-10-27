#!/usr/bin/env bash
set -euo pipefail

# ==============================
#  Настройки пользователя (можно переопределить переменными окружения)
# ==============================
HOSTNAME=${HOSTNAME:-"panel.example.com"}
USERNAME=${USERNAME:-"admin123"}
EMAIL=${EMAIL:-"admin@example.com"}
PASSWORD=${PASSWORD:-"346@1MuXpl'e+TR"}
PHP_VERSION=${PHP_VERSION:-"8.4"}

# ==============================
#  Функции
# ==============================

disable_auto_updates() {
  echo "🧯 Отключаю автообновления..."
  systemctl stop unattended-upgrades apt-daily apt-daily-upgrade >/dev/null 2>&1 || true
  systemctl disable unattended-upgrades apt-daily apt-daily-upgrade >/dev/null 2>&1 || true
  echo "✅ Автообновления отключены."
}

enable_auto_updates() {
  echo "🔄 Включаю автообновления обратно..."
  systemctl enable unattended-upgrades apt-daily apt-daily-upgrade >/dev/null 2>&1 || true
  systemctl start unattended-upgrades apt-daily apt-daily-upgrade >/dev/null 2>&1 || true
  echo "✅ Автообновления снова включены."
}

wait_for_apt() {
  echo "⏳ Проверка: не занят ли apt/dpkg..."
  local timeout=600  # максимум 10 минут ожидания
  local interval=10
  local elapsed=0

  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        pgrep -x "apt" >/dev/null || \
        pgrep -x "apt-get" >/devnull || \
        pgrep -x "unattended-upgrade" >/dev/null; do
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "❌ Время ожидания apt истекло (10 минут). Прерываю."
      exit 1
    fi
    echo "⚙️  APT в данный момент используется. Жду освобождения..."
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  echo "✅ APT свободен — продолжаем установку!"
}

ensure_wget() {
  if ! command -v wget >/dev/null 2>&1; then
    echo "📦 Устанавливаю wget..."
    apt-get update -y
    apt-get install -y wget
  fi
}

# На любой выход стараемся вернуть автообновления
trap 'enable_auto_updates' EXIT

# ==============================
#  Основной процесс установки
# ==============================

disable_auto_updates
wait_for_apt
ensure_wget

echo "⬇️  Скачиваю установщик HestiaCP..."
wget -q https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh -O hst-install.sh

if [ ! -f "hst-install.sh" ]; then
  echo "❌ Ошибка: не удалось загрузить установочный скрипт!"
  exit 1
fi

echo "🚀 Запускаю установку HestiaCP..."
bash hst-install.sh \
  --interactive no \
  --hostname "$HOSTNAME" \
  --username "$USERNAME" \
  --email "$EMAIL" \
  --password "$PASSWORD" \
  --apache no \
  --named no \
  --clamav no \
  --spamassassin no \
  --mysql no \
  --multiphp "$PHP_VERSION" \
  --quota no \
  --webterminal no \
  --iptables no \
  --fail2ban no \
  --force

# Если добрались сюда — установка прошла успешно (set -e)
IP=$(hostname -I | awk '{print $1}')
echo
echo "============================================================"
echo "✅ Установка HestiaCP завершена!"
echo "Панель: https://$IP:8083"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "============================================================"

# ==============================
#  Патчим шаблоны Nginx
# ==============================
echo "⚙️  Вношу изменения в шаблоны Hestia (default.tpl и default.stpl)..."
TEMPLATE_DIR="/usr/local/hestia/data/templates/web/nginx/php-fpm"

for FILE in "$TEMPLATE_DIR/default.tpl" "$TEMPLATE_DIR/default.stpl"; do
  if [ -f "$FILE" ]; then
    cp "$FILE" "${FILE}.bak_$(date +%F_%H-%M-%S)"
    if grep -q "try_files \$uri \$uri/ /index.html;" "$FILE"; then
      echo "⚠️  В $FILE строка уже существует, пропускаю."
    else
      sed -i '/location \/ {/a\    try_files $uri $uri/ /index.html;' "$FILE"
    fi
  else
    echo "❌ Файл $FILE не найден!"
  fi
done

echo "🔍 Проверка конфигурации Nginx..."
if nginx -t; then
  echo "✅ Конфигурация Nginx корректна."
else
  echo "⚠️ ВНИМАНИЕ: возможна ошибка в шаблоне. Проверь вручную!"
fi

echo "🏁 Скрипт завершён!"