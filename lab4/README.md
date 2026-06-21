# 🌐 Ansible Roles: Nginx Vhost Deployment — Лабораторная работа №4

> Автоматизация развёртывания виртуальных хостов nginx с использованием **Ansible Roles**, **циклов** и **Jinja2-шаблонов**.

---

## 📋 Содержание

- [🎯 Цель работы](#-цель-работы)
- [📁 Структура репозитория](#-структура-репозитория)
- [⚙️ Требования](#-требования)
- [🚀 Быстрый старт](#-быстрый-старт)
- [📊 Пример выполнения плейбука](#-пример-выполнения-плейбука)
- [📄 Примеры сгенерированных файлов](#-примеры-сгенерированных-файлов)
- [🔧 Переменные и кастомизация](#-переменные-и-кастомизация)
- [🧩 Архитектура роли](#-архитектура-роли)
- [✅ Проверка результатов](#-проверка-результатов)
- [Возможные ошибки и решения](#-возможные-ошибки-и-решения)
---

## 🎯 Цель работы

- ✅ Изучить стандартную структуру **Ansible Roles**
- ✅ Научиться использовать **Jinja2-шаблоны** для генерации конфигураций и контента
- ✅ Организовать **циклическое развёртывание** нескольких vhost через переменную уровня плей
- ✅ Применить **handlers** для идемпотентной перезагрузки сервиса
- ✅ Разделить логику: универсальная роль ↔ конкретный плейбук с данными

---

## 📁 Структура репозитория

```
lab4/
├── ansible.cfg                     # Настройки Ansible
├── inventory/
│   └── hosts.yml                  # Инвентарь (web1, web2)
├── playbooks/
│   └── vhosts.yml                 # Родительский плейбук с циклом
├── roles/
│   └── vhost/
│       ├── defaults/main.yml      # Переменные по умолчанию
│       ├── vars/main.yml          # Внутренние переменные роли
│       ├── tasks/main.yml         # Основные задачи
│       ├── handlers/main.yml      # Обработчики (reload nginx)
│       ├── templates/
│           ├── vhost.conf.j2      # Шаблон конфига nginx
│           └── index.html.j2      # Шаблон веб-страницы
│       
├── README.md                      
└── .gitignore
```

---

## ⚙️ Требования

| Компонент | Версия / Статус | Примечание |
|-----------|----------------|------------|
| **Ansible** | ≥ 2.9 | Установлен на контроллере |
| **Python** | ≥ 3.6 | На целевых хостах |
| **nginx** | — | Устанавливается ролью автоматически |
| **SSH + sudo** | ✅ | Доступ к хостам с правами суперпользователя |
| **ОС хостов** | Ubuntu/Debian | Стандартные пути `/etc/nginx/sites-*` |

### Проверка окружения
```bash
ansible --version
ansible web -i inventory/hosts.yml -m ping
```

---

## 🚀 Быстрый старт

### 1️⃣ Клонировать репозиторий
```bash
git clone <repo-url>
cd lab4
```

### 2️⃣ Инвентарь `inventory/hosts.yml`
```yaml
---
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

### 3️⃣ Запустить развёртывание
```bash
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml
```

### 4️⃣ Дополнительные опции
```bash
# Подробный вывод + показать изменения файлов
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml -v --diff

# Запустить только на web1
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml --limit web1

# Переопределить список vhost при запуске
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml \
  -e 'vhosts_list=[{"name":"shop","domain":"shop.local"}]'

# Dry-run (проверка без реальных изменений)
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml --check
```

---

## 📊 Пример выполнения плейбука

```bash
$ ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml

PLAY [Развёртывание виртуальных хостов nginx через роль] ***********************

TASK [Gathering Facts] *********************************************************
ok: [web1]
ok: [web2]

TASK [nginx_vhost : Установка пакета nginx] ************************************
ok: [web1]

TASK [nginx_vhost : Отключить дефолтный сайт nginx] ****************************
changed: [web1]

TASK [nginx_vhost : Создать директории для vhost и конфигураций] ***************
changed: [web1] => (item=/etc/nginx/sites-available)
changed: [web1] => (item=/etc/nginx/sites-enabled)
changed: [web1] => (item=/var/www/site1)
changed: [web1] => (item=/var/www/blog)

TASK [nginx_vhost : Развернуть индексную страницу] *****************************
changed: [web1] => (item={'name': 'site1', 'domain': 'site1.local'})
changed: [web1] => (item={'name': 'blog', 'domain': 'blog.local'})

TASK [nginx_vhost : Развернуть конфигурацию виртуального хоста] ****************
changed: [web1] => (item={'name': 'site1', 'domain': 'site1.local'})
changed: [web1] => (item={'name': 'blog', 'domain': 'blog.local'})

TASK [nginx_vhost : Активировать vhost (создать symlink в sites-enabled)] ******
changed: [web1] => (item={'name': 'site1', 'domain': 'site1.local'})
changed: [web1] => (item={'name': 'blog', 'domain': 'blog.local'})

TASK [nginx_vhost : Проверка синтаксиса конфигурации nginx] ********************
ok: [web1]

RUNNING HANDLER [nginx_vhost : Перезагрузить nginx] ****************************
changed: [web1]

TASK [nginx_vhost : Вывод информации о развернутом vhost] **********************
ok: [web1] => (item={'name': 'site1', 'domain': 'site1.local'}) => {
    "msg": "vhost 'site1' активен: http://site1.local → /var/www/site1"
}
ok: [web1] => (item={'name': 'blog', 'domain': 'blog.local'}) => {
    "msg": "vhost 'blog' активен: http://blog.local → /var/www/blog"
}

PLAY RECAP *********************************************************************
web1 : ok=9  changed=7  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
web2 : ok=9  changed=7  unreachable=0  failed=0  skipped=0  rescued=0  ignored=0
```

---

## 📄 Примеры сгенерированных файлов

### 🔹 Конфиг `/etc/nginx/sites-available/site1.conf`
```nginx
# Ansible managed
# Vhost: site1 | Domain: site1.local

server {
    listen 80;
    listen [::]:80;

    server_name {{ vhost.domain }} www.{{ vhost.domain }};

    root {{ nginx_root }}/{{ vhost.name }};
    index index.html index.htm;

    access_log {{ nginx_log_dir }}/{{ vhost.name }}_access.log;
    error_log {{ nginx_log_dir }}/{{ vhost.name }}_error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    {% if vhost.proxy_pass is defined %}
    location /api/ {
        proxy_pass {{ vhost.proxy_pass }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    {% endif %}

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### 🔹 Страница `/var/www/site1/index.html` (фрагмент)
```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <title>Site1 | site1.local</title>
    <!-- стили -->
</head>
<body>
    <div class="card">
        <h1>{{ vhost.name | title }}</h1>
        <p class="domain">{{ vhost.domain }}</p>
        
        <div class="meta">
            <p><strong>Host:</strong> {{ inventory_hostname }}</p>
            <p><strong>Root:</strong> {{ nginx_root }}/{{ vhost.name }}</p>
            {% if vhost.description | default(false) %}
            <p><strong>Описание:</strong> {{ vhost.description }}</p>
            {% endif %}
        </div>
        
        <span class="badge">Deployed with Ansible Role</span>
        <p class="timestamp">Created: {{ ansible_date_time.date }} {{ ansible_date_time.time }}</p>
    </div>
</body>
</html>
```

---

## 🔧 Переменные и кастомизация

### 📦 Переменные плейбука (`playbooks/vhosts.yml`)
```yaml
vars:
  vhosts_list:
    - name: site1
      domain: site1.local
      description: "Основной сайт"
    - name: blog
      domain: blog.local
      description: "Блог компании"
      proxy_pass: "http://127.0.0.1:3000"  # активирует location /api/
```

### ⚙️ Переменные по умолчанию (`roles/vhost/defaults/main.yml`)
| Переменная | Значение | Описание |
|------------|----------|----------|
| `nginx_package` | `nginx` | Имя пакета |
| `nginx_sites_available` | `/etc/nginx/sites-available` | Каталог конфигов |
| `nginx_sites_enabled` | `/etc/nginx/sites-enabled` | Каталог активных сайтов |
| `nginx_root` | `/var/www` | Корневая директория |
| `nginx_owner` / `nginx_group` | `www-data` | Владелец файлов |
| `vhost_enable` | `true` | Создавать symlink в sites-enabled |

### 🔄 Переопределение при запуске
```bash
# Изменить корень и добавить один vhost
ansible-playbook -i inventory/hosts.yml playbooks/vhosts.yml \
  -e "nginx_root=/srv/www" \
  -e 'vhosts_list=[{"name":"api","domain":"api.local"}]'
```

---

## 🧩 Архитектура роли

| Директория | Назначение |
|------------|------------|
| `defaults/main.yml` | Переменные с наименьшим приоритетом. Безопасно переопределять из плейбука или CLI |
| `vars/main.yml` | Внутренние переменные роли. Высокий приоритет, не предназначены для внешнего изменения |
| `tasks/main.yml` | Пошаговая логика: установка → создание dirs → шаблоны → symlink → проверка синтаксиса |
| `handlers/main.yml` | Реагирует на `notify: Перезагрузить nginx`. Запускается только при `changed` |
| `templates/*.j2` | Jinja2-шаблоны. Рендерятся с подстановкой переменных `vhost.*` и `ansible_*` фактов |

**Ключевой механизм цикла в плейбуке:**
```yaml
- include_role:
    name: nginx_vhost
  loop: "{{ vhosts_list }}"
  loop_control:
    loop_var: vhost          # Переменная доступна внутри роли как vhost.name, vhost.domain и т.д.
    label: "{{ vhost.name }}"
```

---

## ✅ Проверка результатов

```bash
# 1. Проверить синтаксис nginx на хосте
ansible web1 -m command -a "nginx -t" -b

# 2. Убедиться, что symlink создан
ansible web1 -m shell -a "ls -l /etc/nginx/sites-enabled/" -b

# 3. Проверить содержимое root-директории
ansible web1 -m shell -a "ls -la /var/www/site1/" -b

# 4. Тестовый запрос (если domain резолвится или через Host header)
curl -H "Host: site1.local" http://192.168.255.201/
```

---

## Возможные ошибки и решения

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `bind() to 0.0.0.0:80 failed` | Порт 80 занят другим сервисом или дефолтным сайтом | Задача `Отключить дефолтный сайт` решает проблему. Либо смените `listen 8080;` в шаблоне |
| `nginx: [emerg] unknown directive` | Ошибка в шаблоне `vhost.conf.j2` | Запустите с `--check --diff`, проверьте синтаксис Jinja2 (`{% if %}`, кавычки, отступы) |
| `Permission denied` при создании dirs | Нет прав у пользователя или неверный owner | Убедитесь, что `become: true` в плейбуке, и `owner: "{{ nginx_owner }}"` указан в task `file` |
| Роль выполняется медленно | Цикл по большому списку + таймауты | Используйте `forks: 10` в `ansible.cfg` или уменьшите `vhosts_list` для теста |
