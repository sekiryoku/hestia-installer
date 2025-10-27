# HestiaCP Installer

Скрипт для быстрой установки HestiaCP на сервере Ubuntu/Debian с минимальным набором компонентов и последующим патчем шаблонов Nginx (добавление `try_files $uri $uri/ /index.html;` в `location /`).

## Требования
- Запуск от `root` или через `sudo` (используются `systemctl`, `apt-get`, правка системных файлов).
- `bash`, `wget`, доступ в интернет.

## Быстрый запуск через SSH (одной командой)

```bash
curl -fsSL https://raw.githubusercontent.com/sekiryoku/hestia-installer/main/install-hestia.sh | sudo bash
```

Альтернативный вариант:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/sekiryoku/hestia-installer/main/install-hestia.sh)
```

## Кастомизация переменных

Скрипт поддерживает переопределение параметров через переменные окружения. По умолчанию используются:

- `HOSTNAME="panel.example.com"`
- `USERNAME="admin123"`
- `EMAIL="admin@example.com"`
- `PASSWORD="346@1MuXpl'e+TR"`
- `PHP_VERSION="8.4"`

Пример запуска с собственными значениями:

```bash
HOSTNAME=panel.mydomain.com \
USERNAME=myadmin \
EMAIL=admin@mydomain.com \
PASSWORD='S3cUr3Pa$$' \
PHP_VERSION=8.3 \
curl -fsSL https://raw.githubusercontent.com/sekiryoku/hestia-installer/main/install-hestia.sh | sudo bash
```

## Что делает скрипт
- Временно отключает автообновления и ждёт освобождения `apt/dpkg`.
- Скачивает официальный установщик HestiaCP (`hst-install.sh`).
- Запускает установку с параметрами: без Apache, Bind, ClamAV, SpamAssassin, MySQL; включён MultiPHP с выбранной версией PHP.
- После установки патчит шаблоны Nginx (`default.tpl` и `default.stpl`) для фронтендов (SPA), вставляя `try_files`.
- Проверяет конфигурацию Nginx (`nginx -t`).
- Возвращает настройки автообновлений.

## Вывод после установки
Скрипт выводит адрес панели и данные доступа:

```
Панель: https://<server-ip>:8083
Username: <USERNAME>
Password: <PASSWORD>
```

## Примечания
- Скрипт рассчитан на чистую/минимальную установку HestiaCP; при необходимости включайте дополнительные сервисы в установщике HestiaCP.
- Если `wget` отсутствует, скрипт установит его через `apt`.
- Для безопасного хранения пароля используйте переменные окружения и секреты CI/CD, не коммитьте реальные пароли в репозиторий.