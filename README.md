# Мониторинг системных ресурсов

Простой Bash-скрипт для периодического мониторинга основных ресурсов Linux.

В рамках проекта скрипт запускается в Docker-контейнере, а результаты мониторинга доступны по HTTP/HTTPS через Nginx reverse proxy.

## Script

Скрипт `script.sh` каждые 5 секунд записывает в файл `monitor.log`:

- текущие дату и время;
- время работы системы и среднюю нагрузку;
- использование оперативной памяти;
- использование дискового пространства.

Для корректной остановки скрипт обрабатывает сигналы `SIGINT` и `SIGTERM`.

Запуск напрямую:

```bash
chmod +x script.sh
./script.sh
```

Для остановки:

```text
Ctrl+C
```

## Docker

Для запуска скрипта используется Docker image на базе Ubuntu 22.04.

Сборка image:

```bash
docker build -t my-script .
```

Контейнер запускает:

- `script.sh`, который обновляет `monitor.log`;
- Python HTTP server на порту `8080`.

Проверить созданные images:

```bash
docker images
```

## Run

Для запуска проекта используется Docker Compose:

```bash
docker compose up -d --build
```

Контейнер имеет имя:

```text
my-app
```

Проверить работающий контейнер:

```bash
docker ps
```

Порт `8080` контейнера публикуется на порту `8080` Ubuntu VM.

Для хранения `monitor.log` используется Docker named volume, поэтому данные сохраняются при пересоздании контейнера.

## HTTP

Прямой доступ к приложению без Nginx:

```bash
curl -I http://127.0.0.1:8080/
```

Ожидается успешный ответ:

```text
HTTP/1.0 200 OK
```

Проверить содержимое файла мониторинга:

```bash
curl http://127.0.0.1:8080/monitor.log
```

Также результат работы скрипта можно проверить непосредственно внутри контейнера:

```bash
docker exec my-app tail -n 25 /data/monitor.log
```

## Storage

Для лабораторной части настроены RAID 1 и LVM на loop devices.

Файлы виртуальных дисков находятся вне Git-репозитория и используются только в лабораторной Ubuntu VM.

### RAID 1

Два loop device объединены в программный RAID 1:

```text
/dev/loop5 + /dev/loop6
          |
          v
       /dev/md0
          |
          v
         ext4
          |
          v
      /mnt/raid
```

Проверить состояние RAID:

```bash
cat /proc/mdstat
```

Рабочее состояние массива:

```text
[2/2] [UU]
```

Проверить файловую систему и точку монтирования:

```bash
df -h /mnt/raid
```

### LVM

На дополнительном loop device создана структура LVM:

```text
/dev/loop7
    |
    v
   PV
    |
    v
VG vg_data
    |
    v
LV lv_logs
    |
    v
   ext4
    |
    v
/mnt/logs
```

Проверить Physical Volume:

```bash
sudo pvs
```

Проверить Volume Group:

```bash
sudo vgs
```

Проверить Logical Volume:

```bash
sudo lvs
```

Проверить точку монтирования:

```bash
df -h /mnt/logs
```

Общая проверка RAID и LVM:

```bash
cat /proc/mdstat
sudo pvs
sudo vgs
sudo lvs
df -h /mnt/raid /mnt/logs
```

Файлы:

```text
disk1.img
disk2.img
disk3.img
```

не хранятся в Git.

## Nginx

Nginx используется как reverse proxy перед Docker-контейнером.

Схема обработки запроса:

```text
client
   |
   | HTTP :80 / HTTPS :443
   v
 Nginx
   |
   | HTTP
   v
127.0.0.1:8080
   |
   v
Docker container my-app
   |
   v
Python HTTP server
   |
   v
monitor.log
```

Проверить конфигурацию Nginx:

```bash
sudo nginx -t
```

Ожидается:

```text
syntax is ok
test is successful
```

## HTTPS

Для учебной среды используется self-signed TLS certificate.

HTTP-запросы на порт `80` перенаправляются на HTTPS:

```text
HTTP :80
   |
   v
301 redirect
   |
   v
HTTPS :443
```

Проверить HTTP redirect:

```bash
curl -I http://127.0.0.1/
```

Ожидается:

```text
HTTP/1.1 301 Moved Permanently
```

Проверить HTTPS:

```bash
curl -kI https://127.0.0.1/
```

Ожидается:

```text
HTTP/1.1 200 OK
```

Опция `-k` используется потому, что сертификат self-signed и не подписан доверенным Certificate Authority.

TLS certificate находится в:

```text
/etc/ssl/certs/my-app.crt
```

Приватный ключ находится в:

```text
/etc/ssl/private/my-app.key
```

Приватный TLS key не хранится в Git.

## systemd

Контейнер `my-app` управляется systemd service:

```text
my-app.service
```

Unit-файл расположен в:

```text
/etc/systemd/system/my-app.service
```

Проверить состояние сервиса:

```bash
sudo systemctl status my-app --no-pager
```

Ожидается:

```text
Active: active (running)
```

Проверить автозапуск:

```bash
systemctl is-enabled my-app
```

Ожидается:

```text
enabled
```

Посмотреть журнал сервиса:

```bash
sudo journalctl -u my-app -n 30 --no-pager
```

## Verification

Основные команды финальной проверки проекта:

```bash
docker ps
curl -I http://127.0.0.1:8080/

sudo nginx -t
curl -I http://127.0.0.1/
curl -kI https://127.0.0.1/

sudo systemctl status my-app --no-pager
systemctl is-enabled my-app
sudo journalctl -u my-app -n 30 --no-pager

cat /proc/mdstat
sudo pvs
sudo vgs
sudo lvs
df -h /mnt/raid /mnt/logs

git status
git log --oneline --graph --decorate --all
```

## Файлы проекта

- `script.sh` — Bash-скрипт мониторинга;
- `Dockerfile` — описание Docker image;
- `docker-compose.yml` — конфигурация контейнера, Docker volume и порта `8080`;
- `.gitignore` — исключения для runtime-файлов, disk images, private keys и временных файлов;
- `sample_output.txt` — пример результата мониторинга;
- `README.md` — описание проекта.
