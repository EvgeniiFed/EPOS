# 🔍 Ansible NMAP Scanner — Лабораторная работа №3

> Автоматизация сканирования сети с помощью **NMAP** через Ansible с использованием **переменных**, **циклов** и **обработки результатов**.

## 🎯 Цель работы

- ✅ Научиться работать с **переменными Ansible** (`vars`, `group_vars`, `set_fact`)
- ✅ Использовать **циклы** (`loop`, `loop_control`) для обработки списков
- ✅ Парсить файлы и преобразовывать данные через **Jinja2-фильтры**
- ✅ Собирать и обрабатывать вывод команд через `register`
- ✅ Организовать вывод результатов через `debug` и сохранение в файлы

---

## 📁 Структура проекта

```
ansible-nmap-scanner/
├── ansible.cfg                 # Конфигурация Ansible
├── inventory/
│   └── hosts.yaml              # Инвентарь
├── group_vars/
│   └── all.yaml               # Глобальные переменные
├── playbooks/
│   └── nmap_scan.yaml         # Основной плейбук
├── targets/
│   └── targets.txt           # Список целей для сканирования
├── README.md                 # Этот файл
└── .gitignore                # Исключения для git
```

---

## ⚙️ Требования

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| **Ansible** | ≥ 2.9 | Установлен на контроллере |
| **Python** | ≥ 3.6 | На целевых хостах |
| **SSH** | — | Доступ к хостам с ключом/паролем |
| **sudo** | — | Права для установки пакетов |
| **nmap** | — | Устанавливается автоматически |

### Проверка окружения

```bash
# Версия Ansible
ansible --version

# Проверка подключения к хостам
ansible web -i inventory/hosts.yaml -m ping

# Сбор фактов (опционально)
ansible web1 -i inventory/hosts.yaml -m setup | head -30
```

---

## 🚀 Быстрый старт

### 1️⃣ Клонировать репозиторий

```bash
git clone <repo-url>
cd lab3
```

### 2️⃣ Проверить инвентарь

Файл `inventory/hosts.yaml` уже настроен под ваши хосты:

```yaml
all:
  children:
    web:
      hosts:
        web1:
          ansible_host: 192.168.255.201
          ansible_user: ubuntu
        web2:
          ansible_host: 192.168.255.202
          ansible_user: ubuntu
      vars:
        ansible_python_interpreter: /usr/bin/python3
```

### 3️⃣ Настроить цели для сканирования

Отредактируйте `targets/targets.txt`:

```txt
# 🎯 Цели для сканирования (порт 80)
192.168.255.1        # шлюз
192.168.255.201      # web1
example.com          # тестовый домен
# 10.0.0.1           # закомментировано — не сканируется
```

### 4️⃣ Запустить плейбук

```bash
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml
```

### 5️⃣ Дополнительные опции запуска

```bash
# Подробный вывод (отладка)
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml -vvv

# Запустить только задачи сканирования (пропустить установку)
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml --tags "scan"

# Сканировать другой порт (переопределение переменной)
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml -e "nmap_port=443"

# Запустить только на web1
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml --limit web1

# Симуляция без реальных изменений (dry-run)
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml --check
```

---

## 📊 Пример выполнения плейбука

```bash
$ ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml

PLAY [Сканирование сети через NMAP с использованием переменных и циклов] *******

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [Установка пакета NMAP] ***************************************************
ok: [web1]
ok: [web2]

TASK [Создание директории для результатов] *************************************
ok: [web1]
ok: [web2]

TASK [Копирование файла целей на удалённый хост] *******************************
changed: [web1]
changed: [web2]

TASK [Чтение и парсинг файла целей] ********************************************
ok: [web1]
ok: [web2]

TASK [Преобразование целей в список переменных] ********************************
ok: [web1]
ok: [web2]

TASK [Отображение найденных целей (отладка)] ***********************************
ok: [web1] => {
    "msg": "🎯 Найдено целей: 3 | Список: ['192.168.255.1', '192.168.255.201', 'example.com']"
}
ok: [web2] => {
    "msg": "🎯 Найдено целей: 3 | Список: ['192.168.255.1', '192.168.255.201', 'example.com']"
}

TASK [Сканирование каждой цели через NMAP (порт 80)] ***************************
changed: [web1] => (item=192.168.255.1)
changed: [web1] => (item=192.168.255.201)
changed: [web1] => (item=example.com)
changed: [web2] => (item=192.168.255.1)
changed: [web2] => (item=192.168.255.201)
changed: [web2] => (item=example.com)

TASK [Вывод сводки результатов сканирования] ***********************************
ok: [web1] => (item=192.168.255.1) => {
    "msg": "🔍 Цель: 192.168.255.1\n├─ Код возврата: 0\n├─ Статус порта: 🔴 ЗАКРЫТ\n└─ Время: 1717098234.56"
}
ok: [web1] => (item=192.168.255.201) => {
    "msg": "🔍 Цель: 192.168.255.201\n├─ Код возврата: 0\n├─ Статус порта: 🟢 ОТКРЫТ\n└─ Время: 1717098236.12"
}
ok: [web1] => (item=example.com) => {
    "msg": "🔍 Цель: example.com\n├─ Код возврата: 0\n├─ Статус порта: 🟢 ОТКРЫТ\n└─ Время: 1717098238.45"
}
ok: [web2] => (item=192.168.255.1) => { ... }
ok: [web2] => (item=192.168.255.201) => { ... }
ok: [web2] => (item=example.com) => { ... }

TASK [Сохранение детальных результатов в файл] *********************************
changed: [web1]
changed: [web2]

TASK [Вывод итогового отчёта] **************************************************
ok: [web1] => {
    "msg": "═══════════════════════════════════════\n📊 СКАНИРОВАНИЕ ЗАВЕРШЕНО НА ХОСТЕ: web1\n═══════════════════════════════════════\nЦелей: 3 | Успешно: 3 | Ошибок: 0\nЛог: /tmp/nmap_results/scan_web1_20260530T143000.log\n═══════════════════════════════════════"
}
ok: [web2] => {
    "msg": "═══════════════════════════════════════\n📊 СКАНИРОВАНИЕ ЗАВЕРШЕНО НА ХОСТЕ: web2\n═══════════════════════════════════════\nЦелей: 3 | Успешно: 2 | Ошибок: 1\nЛог: /tmp/nmap_results/scan_web2_20260530T143005.log\n═══════════════════════════════════════"
}

PLAY RECAP *********************************************************************
web1 : ok=11  changed=4  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
web2 : ok=11  changed=4  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

---

## 📑 Пример файла результатов

После выполнения плейбука результаты сохраняются в `/tmp/nmap_results/`:

```bash
$ cat /tmp/nmap_results/scan_web1_20260530T143000.log
```

```log
# NMAP Scan Report
# Host: web1
# Time: 20260530T143000
# Port: 80

---
Target: 192.168.255.1
RC: 0
Output:
  Starting Nmap 7.80 ( https://nmap.org )
  Nmap scan report for 192.168.255.1
  Host is up (0.0012s latency).
  
  PORT   STATE SERVICE
  80/tcp closed http
  
  Nmap done: 1 IP address (1 host up) scanned in 0.15 seconds

---
Target: 192.168.255.201
RC: 0
Output:
  Starting Nmap 7.80 ( https://nmap.org )
  Nmap scan report for 192.168.255.201
  Host is up (0.00010s latency).
  
  PORT   STATE SERVICE
  80/tcp open  http
  
  Nmap done: 1 IP address (1 host up) scanned in 0.12 seconds

---
Target: example.com
RC: 0
Output:
  Starting Nmap 7.80 ( https://nmap.org )
  Nmap scan report for example.com (93.184.216.34)
  Host is up (0.045s latency).
  
  PORT   STATE SERVICE
  80/tcp open  http
  
  Nmap done: 1 IP address (1 host up) scanned in 1.23 seconds
```

---

## 🔧 Переменные и настройка

### Глобальные переменные (`group_vars/all.yml`)

```yaml
---
targets_file: "/tmp/targets.txt"          # Путь к файлу целей на удалённом хосте
results_directory: "/tmp/nmap_results"    # Куда сохранять логи
nmap_port: "80"                           # Порт для сканирования
nmap_timing: "-T4"                        # Агрессивность: -T0 (медленно) ... -T5 (быстро)
nmap_options: "-Pn"                       # Дополнительные флаги nmap
nmap_timeout: 15                          # Таймаут на хост (сек)
scan_delay: 1                             # Задержка между итерациями цикла
verbose_output: true                      # Показывать детальный вывод
```

### Переопределение переменных при запуске

```bash
# Сканировать порт 443 вместо 80
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml -e "nmap_port=443"

# Использовать более агрессивное сканирование
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml -e "nmap_timing=-T5"

# Отключить подробный вывод
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml -e "verbose_output=false"

# Комбинировать несколько переменных
ansible-playbook -i inventory/hosts.yaml playbooks/nmap_scan.yaml \
  -e "nmap_port=22 nmap_timeout=10 scan_delay=2"
```

### Теги для выборочного запуска

| Тег | Описание | Пример |
|-----|----------|--------|
| `install` | Только установка nmap | `--tags install` |
| `setup` | Подготовка директорий и файлов | `--tags setup` |
| `parse` | Парсинг файла целей | `--tags parse` |
| `scan` | Только сканирование | `--tags scan` |
| `output` | Вывод результатов | `--tags output` |
| `save` | Сохранение в файл | `--tags save` |

---

## Возможные ошибки и решения

### ❌ Хост недоступен по SSH

```
fatal: [web1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```

**Решение:**
```bash
# Проверить доступность
ping 192.168.255.201

# Проверить SSH-ключ
ssh ubuntu@192.168.255.201

# Скопировать ключ, если нужно
ssh-copy-id ubuntu@192.168.255.201
```

### ❌ NMAP не устанавливается

```
fatal: [web1]: FAILED! => {"msg": "No package matching 'nmap' is available"}
```

**Решение:**
```bash
# Обновить репозитории вручную
ansible web -m apt -a "update_cache=yes" -b

# Проверить, что хост в сети Debian/Ubuntu
ansible web -m setup -a "filter=ansible_os_family"
```

### ❌ Файл целей не найден

```
fatal: [web1]: FAILED! => {"msg": "Could not find or access '/tmp/targets.txt'"}
```

**Решение:**
- Убедитесь, что задача `Копирование файла целей` выполняется до парсинга
- Проверьте права на запись в `/tmp/`

### ❌ Сканирование блокируется фаерволом

Если все хосты показывают `filtered` или таймаут:

```yaml
# В group_vars/all.yaml добавьте:
nmap_options: "-Pn -sT"  # Не пинговать, использовать TCP connect вместо SYN
nmap_timeout: 30          # Увеличить таймаут
```

---

## Использованные технологии

### Ansible-модули
| Модуль | Назначение |
|--------|------------|
| `package` | Установка пакетов (apt/yum) |
| `file` | Создание директорий, управление правами |
| `copy` | Копирование файлов/контента на хост |
| `slurp` | Чтение файлов с кодировкой base64 |
| `set_fact` | Динамическое создание переменных |
| `command` | Выполнение команд (nmap) |
| `debug` | Вывод отладочной информации |

### Jinja2-фильтры для парсинга
```jinja
{{ targets_raw.content | b64decode | split('\n') | map('trim') | select('match', '^(?!#|^$)') | list }}
```
- `b64decode` — декодирование вывода `slurp`
- `split('\n')` — разбивка на строки
- `map('trim')` — удаление пробелов
- `select('match', '^(?!#|^$)')` — фильтрация комментариев и пустых строк
- `list` — преобразование в список для цикла

### Циклы Ansible
```yaml
loop: "{{ target_list }}"
loop_control:
  label: "{{ item }}"
  pause: 1
```

### Регистрация и обработка результатов
```yaml
register: scan_results  # Сохранение вывода команды
```
Доступ к результатам:
- `scan_results.results` — список результатов по каждой итерации
- `item.item` — текущая цель в цикле
- `item.stdout` / `item.stderr` — вывод команды
- `item.rc` — код возврата (0 = успех)
