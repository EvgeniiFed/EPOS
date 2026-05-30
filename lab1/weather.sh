#!/bin/bash
# weather.sh - Получение температуры и влажности с wttr.in
# Использование: ./weather.sh "Название города (по умолчанию - Perm)"

set -euo pipefail

# Конфигурация
CITY="${1:-Perm}"
OUTPUT_FILE="/var/www/html/index.html"
WTTR_URL="https://wttr.in/${CITY}?format=j1&lang=ru"
TIMEOUT=30

# Логирование
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

main() {
    log "Запрос погоды для города: ${CITY}"
    
    # Получение JSON с wttr.in [[1]][[8]]
    local json_data
    if ! json_data=$(curl -s --max-time "${TIMEOUT}" -A "curl" "${WTTR_URL}"); then
        log "ERROR: Не удалось получить данные с wttr.in"
        create_error_page "Ошибка загрузки данных"
        exit 1
    fi
    
    # Парсинг JSON с помощью jq [[18]][[19]]
    local temp_c humidity weather_desc observation_time
    
    # Извлечение данных из current_condition[0] [[4]]
    temp_c=$(echo "${json_data}" | jq -r '.current_condition[0].temp_C // "N/A"')
    humidity=$(echo "${json_data}" | jq -r '.current_condition[0].humidity // "N/A"')
    weather_desc=$(echo "${json_data}" | jq -r '.current_condition[0].weatherDesc[0].value // "N/A"')
    observation_time=$(echo "${json_data}" | jq -r '.current_condition[0].observation_time // "N/A"')
    
    # Генерация HTML-страницы
    generate_html "${CITY}" "${temp_c}" "${humidity}" "${weather_desc}" "${observation_time}"
    
    log "Данные успешно обновлены: ${temp_c}°C, влажность ${humidity}%"
}

generate_html() {
    local city="$1" temp="$2" humidity="$3" weather="$4" time="$5"
    
    cat > "${OUTPUT_FILE}" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Погода в ${city}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .weather-card {
            background: white;
            border-radius: 16px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
        }
        .city { font-size: 2em; margin-bottom: 10px; color: #2c3e50; }
        .weather { font-size: 1.3em; color: #7f8c8d; margin: 15px 0; }
        .temp { 
            font-size: 4em; 
            font-weight: bold; 
            color: #e74c3c;
            margin: 20px 0;
        }
        .humidity {
            font-size: 1.5em;
            color: #3498db;
            margin: 10px 0;
        }
        .updated {
            margin-top: 25px;
            padding-top: 15px;
            border-top: 1px solid #ecf0f1;
            font-size: 0.9em;
            color: #95a5a6;
        }
        .error { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="weather-card">
        <div class="city">${city}</div>
        <div class="weather">${weather}</div>
        <div class="temp">${temp}°C</div>
        <div class="humidity">Влажность: ${humidity}%</div>
        <div class="updated">
            Обновлено: $(date '+%d.%m.%Y %H:%M')<br>
            <small>Данные: wttr.in</small>
        </div>
    </div>
</body>
</html>
EOF
}

create_error_page() {
    local message="$1"
    cat > "${OUTPUT_FILE}" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Ошибка</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; background: #ecf0f1; }
        .error { background: white; padding: 30px; border-radius: 10px; display: inline-block; }
        h1 { color: #e74c3c; }
    </style>
</head>
<body>
    <div class="error">
        <h1>Ошибка</h1>
        <p>${message}</p>
        <p><small>Повторная попытка через 1 минуту...</small></p>
    </div>
</body>
</html>
EOF
}

main "$@"
