```markdown
# Ansible + Nginx Deployment

Автоматическое развёртывание nginx с кастомной страницей через Ansible.

## Требования

- Контроллер: установлен Ansible 2.9+
- Целевые хосты: Ubuntu/Debian с доступом по SSH
- Права: возможность выполнения команд через `sudo`

## Быстрый старт

### 1. Клонировать репозиторий
```bash
git clone <repo-url>
cd lab2
```

### 2. Настроить инвентарь
Отредактируйте `inventory/hosts.ini`:
```ini
[webservers]
myserver ansible_host=192.168.255.201 ansible_user=ubuntu
```

### 3. Проверить подключение
```bash
ansible all -i inventory/hosts.ini -m ping
```

### 4. Запустить плейбук
```bash
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml
```

### 5. Проверить результат
```bash
curl http://<IP-сервера>/
```

## Дополнительные команды

```bash
# Запуск с выводом отладки
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml -vvv

# Запуск только определённых тегов
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --tags "deploy"

# Симуляция (dry-run)
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --check

# Обновить только index.html
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --tags "template"
```

## Структура

```
.
├── ansible.cfg           # Настройки Ansible
├── inventory/
│   └── hosts.ini        # Инвентарь хостов
├── playbooks/
│   └── nginx.yaml # Плейбук
├── templates/
│   └── index.html.j2    # Шаблон страницы
├── requirements.yaml     # Зависимости
└── README.md           # Документация
```

## Переменные

| Переменная | Значение по умолчанию | Описание |
|------------|----------------------|----------|
| `nginx_package` | `nginx` | Имя пакета nginx |
| `nginx_document_root` | `/var/www/html` | Корневая директория веб-сервера |
| `hello_message` | `Hello from Ansible` | Текст на странице |
| `index_file_name` | `index.html` | Имя индексного файла |

## Тестирование на localhost

Для тестирования без удалённых хостов:

1. Добавьте в `inventory/hosts.ini`:
```ini
[local]
localhost ansible_connection=local
```

2. Запустите с ограничением на группу:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --limit local
```

## Troubleshooting

### SSH-ключи
```bash
# Копирование ключа на целевой хост
ssh-copy-id user@target-host
```

### Проверка синтаксиса плейбука
```bash
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --syntax-check
```

### Предварительный запуск плейбука в режиме dry-run для отладки
```bash
ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml --dry-run
```

### Сбор фактов вручную
```bash
ansible all -i inventory/hosts.ini -m setup --limit web1
```

```

---

## Пример вывода после запуска

```bash
$ ansible-playbook -i inventory/hosts.ini playbooks/nginx.yaml

PLAY [Установка nginx и деплой индексной страницы] ************************************

TASK [Gathering Facts] ********************************************************
ok: [web1]

TASK [Установить nginx] *******************************************************
changed: [web1]

TASK [Запустить и включить сервис nginx] **************************************
changed: [web1]

TASK [Проверить, что сервис nginx отвечает] ***********************************
changed: [web1]

TASK [Разместить index.html] **************************************************
changed: [web1]

TASK [Проверить, что сервис nginx отвечает] ******************************************
ok: [web1]

TASK [Показать результат] *****************************************************
ok: [web1] => {
    "msg": "Nginx успешно развёрнут на web1. Ответ: <!DOCTYPE html><html>...Hello from Ansible..."
}

PLAY RECAP ********************************************************************
web1 : ok=7 changed=3 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

---

## Результат в браузере

При переходе на `http://<IP-сервера>/` пользователь увидит:

```
┌─────────────────────────────────┐
│  Hello from Ansible          │
│                                 │
│  Host: web1                     │
│  IP: 192.168.255.201               │
│  OS: Ubuntu 22.04               │
│                                 │
│  [Deployed with Ansible]        │
│  Deployed at: 2026-06-18T...   │
└─────────────────────────────────┘
```
