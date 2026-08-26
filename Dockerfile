FROM python:3.12-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# Версия сборки прокидывается снаружи (из Jenkins) и "запекается" в образ.
ARG APP_VERSION=0.0.0
ENV APP_VERSION=${APP_VERSION}

EXPOSE 5000

CMD ["python", "app.py"]
