import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "0.0.0")


@app.route("/")
def index():
    return jsonify(message="Hello from Jenkins CI/CD demo!", version=APP_VERSION)


@app.route("/health")
def health():
    return jsonify(status="ok")


def add(a: int, b: int) -> int:
    """Простая функция для юнит-тестов."""
    return a + b


def divide(a: int, b: int) -> float:
    if b == 0:
        raise ValueError("Деление на ноль недопустимо")
    return a / b


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
