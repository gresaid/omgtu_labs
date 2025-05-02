# temp stage
FROM python:3.12.2-slim as builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Установка зависимостей для сборки
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Обновление pip до последней версии и создание wheel-файлов
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# final stage
FROM python:3.12.2-slim

WORKDIR /app

# Копирование wheel-файлов и requirements.txt из предыдущей стадии
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Установка зависимостей
RUN pip install --no-cache-dir /wheels/*

# Копирование всего проекта из корневой директории
COPY ./ .

# Команда для запуска приложения
CMD ["python", "main.py"]
