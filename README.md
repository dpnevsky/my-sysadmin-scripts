# Мониторинг системных ресурсов

Простой Bash-скрипт для периодического мониторинга основных ресурсов Linux.

В рамках проекта скрипт запускается в Docker-контейнере, а результаты мониторинга доступны через HTTP/HTTPS через Nginx reverse proxy.

## Что делает скрипт

Скрипт каждые 5 секунд записывает в файл `monitor.log`:

- текущие дату и время;
- время работы системы и среднюю нагрузку;
- использование оперативной памяти;
- использование дискового пространства.

Для корректной остановки обрабатываются сигналы `SIGINT` и `SIGTERM`.

## Docker

Собрать Docker image:

```bash
docker build -t my-script .
```

Для запуска проекта используется Docker Compose:

```bash
docker compose up -d --build
```

Контейнер имеет имя:

```text
my-app
```

Файл `monitor.log` хранится в Docker volume, поэтому данные сохраняются при пересоздании контейнера.

## HTTP

Внутри контейнера работает Python HTTP server на порту `8080`.

Проверка приложения напрямую:

```bash
curl -I http://127.0.0.1:8080/
```

Проверка файла мониторинга:

```bash
curl http://127.0.0.1:8080/monitor.log
```

## Storage

В лабораторной части настроены RAID 1 и LVM на loop devices.

### RAID 1

Два loop device объединены в RAID 1:

```text
/dev/loop5 + /dev/loop6
          ↓
       /dev/md0
          ↓
         ext4
          ↓
      /mnt/raid
```

Проверка:

```bash
cat /proc/mdstat
```

Рабочее состояние RAID:

```text
[2/2] [UU]
```

### LVM

На дополнительном loop device создана структура:

```text
/dev/loop7
    ↓
PV
    ↓
VG vg_data
    ↓
LV lv_logs
    ↓
ext4
    ↓
/mnt/logs
```

Проверка:

```bash
sudo pvs
sudo vgs
sudo lvs
df -h /mnt/raid /mnt/logs
```

Файлы `disk1.img`, `disk2.img` и `disk3.img` являются локальными файлами лабораторной VM и не хранятся в Git.

## Nginx

Nginx используется как reverse proxy.

Схема обработки запроса:

```text
client
   ↓
Nginx :80 / :443
   ↓
127.0.0.1:8080
   ↓
Docker container my-app
   ↓
Python HTTP server
   ↓
monitor.log
```

Проверка конфигурации:

```bash
sudo nginx -t
```

## HTTPS

Для учебной среды используется self-signed TLS-сертификат.

HTTP-запросы перенаправляются на HTTPS:

```text
HTTP :80
   ↓
301 redirect
   ↓
HTTPS :443
```

Проверка redirect:

```bash
curl -I http://127.0.0.1/
```

Проверка HTTPS:

```bash
curl -kI https://127.0.0.1/
```

Опция `-k` используется из-за self-signed сертификата.

Приватный TLS-ключ не хранится в Git.

## systemd

Контейнер `my-app` управляется systemd-сервисом:

```text
my-app.service
```

Проверить состояние:

```bash
sudo systemctl status my-app --no-pager
```

Проверить автозапуск:

```bash
systemctl is-enabled my-app
```

Посмотреть журнал сервиса:

```bash
sudo journalctl -u my-app -n 30 --no-pager
```

## Nginx access log

Последние запросы:

```bash
sudo tail -n 10 /var/log/nginx/access.log
```

Просмотр запросов в реальном времени:

```bash
sudo tail -f /var/log/nginx/access.log
```

## Verification

Основные команды финальной проверки:

```bash
docker ps
curl -I http://127.0.0.1:8080/
sudo nginx -t
curl -I http://127.0.0.1/
curl -kI https://127.0.0.1/
sudo systemctl status my-app --no-pager
systemctl is-enabled my-app
cat /proc/mdstat
sudo pvs
sudo vgs
sudo lvs
df -h /mnt/raid /mnt/logs
```

## Файлы проекта

- `script.sh` — Bash-скрипт мониторинга;
- `Dockerfile` — описание Docker image;
- `docker-compose.yml` — конфигурация контейнера, volume и порта `8080`;
- `.gitignore` — исключения для runtime-файлов и локальных артефактов;
- `sample_output.txt` — пример результата мониторинга;
- `README.md` — описание проекта.
