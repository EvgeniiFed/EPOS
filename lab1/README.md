# 🌤️ Weather Dashboard - Лабораторная работа

Автоматическая система мониторинга погоды с веб-интерфейсом на базе **bash**, **nginx** и **cron**.

## 📋 Описание

Проект получает актуальные данные о температуре и влажности для указанного города через API [wttr.in](https://github.com/chubin/wttr.in), парсит JSON с помощью `jq` и отображает информацию на веб-странице, которая обновляется каждую минуту.

### ✨ Возможности
- 🌍 Получение погоды для любого города мира
- 🔄 Автоматическое обновление каждую минуту (cron)
- 📊 Красивый веб-интерфейс (HTML + CSS)
- 📝 Логирование всех операций
- ⚡ Быстрый и легкий (bash + curl + jq)

---

## 📦 Установка

### 1. Установка зависимостей

```bash
sudo apt update
sudo apt install -y nginx jq curl cron
```

### 2. Настройка прав доступа

```bash
# Дать права на запись в директорию nginx
sudo chown -R $USER:$USER /var/www/html

# Запустить nginx
sudo nginx
```

### 3. Настройка cron

Откройте crontab:
```bash
crontab -e
```

Добавьте в начало файла:
```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Добавьте задачу (обновление каждую минуту):
```cron
* * * * * /путь/к/скрипту/weather.sh "Perm" >> /var/log/weather.log 2>&1
```

Замените:
- `/путь/к/скрипту` на актуальный путь (например, `/workspaces/EPOS/lab1`)
- `"Perm"` на ваш город (можно использовать русские названия: `"Москва"`, `"Санкт-Петербург"`)

---

## 🚀 Использование

### Ручной запуск

```bash
chmod +x weather.sh
./weather.sh "Perm"
```

### Просмотр результата

1. Откройте браузер: `http://localhost/`
2. Или через терминал:
   ```bash
   curl http://localhost/
   ```

### Просмотр логов

```bash
# В реальном времени
tail -f /var/log/weather.log

# Последние 20 строк
tail -n 20 /var/log/weather.log
```

---

## 📁 Структура проекта

```
lab1/
├── weather.sh              # Основной bash-скрипт
├── README.md               # Документация
└── (другие файлы проекта)

/var/log/
└── weather.log             # Лог выполнения скрипта

/var/www/html/
└── index.html              # Генерируемая веб-страница (обновляется автоматически)
```

---

## 🔧 Как это работает

```mermaid
graph LR
    A[Cron<br/>каждую минуту] --> B[weather.sh]
    B --> C[curl к wttr.in API]
    C --> D[jq парсит JSON]
    D --> E[Генерация HTML]
    E --> F[/var/www/html/index.html]
    F --> G[nginx раздает<br/>http://localhost/]
```

### Компоненты системы

| Компонент | Назначение |
|-----------|------------|
| **wttr.in** | API погоды (JSON формат) |
| **curl** | HTTP-запросы к API |
| **jq** | Парсинг JSON |
| **bash** | Основная логика скрипта |
| **cron** | Планировщик задач (запуск каждую минуту) |
| **nginx** | Веб-сервер для отображения результата |

---

## 📊 Примеры использования

### Разные города

```bash
./weather.sh "London"      # Лондон
./weather.sh "Пермь"      # Пермь (кириллица)
```

### Проверка работы API

```bash
# Тестовый запрос к wttr.in
curl -s "https://wttr.in/Moscow?format=j1" | jq '.current_condition[0] | {temp_C, humidity, weatherDesc}'
```

Пример вывода:
```json
{
  "temp_C": "12",
  "humidity": "77",
  "weatherDesc": [{"value": "Partly cloudy"}]
}
```

---

## ⚠️ Troubleshooting

### Ошибка: Permission denied

**Проблема:**
```
./weather.sh: line 47: /var/www/html/index.html: Permission denied
```

**Решение:**
```bash
sudo chown -R $USER:$USER /var/www/html
```

### Cron не работает

**Проблема:** Скрипт запускается вручную, но cron молчит.

**Решение:**
1. Убедитесь, что cron запущен:
   ```bash
   sudo service cron status
   sudo service cron start
   ```

2. Проверьте логи cron:
   ```bash
   sudo grep CRON /var/log/syslog | tail -10
   ```

3. Уберите `sudo` из crontab и добавьте `PATH`:
   ```cron
   SHELL=/bin/bash
   PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
   * * * * * /путь/к/weather.sh "Perm" >> /var/log/weather.log 2>&1
   ```

### nginx не запускается

**Проблема:**
```
open() "/run/nginx.pid" failed (13: Permission denied)
```

**Решение:**
```bash
sudo nginx           # Запуск
sudo nginx -s reload # Перезагрузка
sudo nginx -t        # Проверка конфига
```

### Данные не обновляются

**Проверка:**
```bash
# 1. Последнее обновление в логе
tail -5 /var/log/weather.log

# 2. Содержимое index.html
cat /var/www/html/index.html | grep -A2 "temp"

# 3. Доступность API
curl -s "https://wttr.in/Moscow?format=j1" | jq '.current_condition[0].temp_C'
```

---

## 📚 API wttr.in

### Основные параметры

| Параметр | Описание |
|----------|----------|
| `?format=j1` | Полный JSON с текущей погодой и прогнозом |
| `?format=j2` | Сокращенный JSON (без почасового прогноза) |
| `?lang=ru` | Русский язык описаний |
| `?format=3` | Краткий текстовый формат |

### Примеры запросов

```bash
# Текущая погода (коротко)
curl wttr.in/Moscow

# JSON с полной информацией
curl wttr.in/Moscow?format=j1

# Только температура
curl wttr.in/Moscow?format=%t

# Прогноз на 3 дня
curl wttr.in/Moscow+3
```

📖 Полная документация: [github.com/chubin/wttr.in](https://github.com/chubin/wttr.in)

---

## 🛠️ Требования

- **ОС:** Linux (Ubuntu/Debian) или WSL
- **Пакеты:** `bash`, `curl`, `jq`, `nginx`, `cron`
- **Интернет:** Для доступа к API wttr.in

---