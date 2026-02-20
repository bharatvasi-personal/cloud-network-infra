from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({
        "status": "healthy",
        "hostname": socket.gethostname(),
        "environment": os.getenv("ENV", "production"),
        "version": "1.0.0"
    })

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/metrics")
def metrics():
    # Prometheus-style basic metrics endpoint
    return (
        "# HELP app_requests_total Total requests\n"
        "# TYPE app_requests_total counter\n"
        "app_requests_total 1\n"
    ), 200, {"Content-Type": "text/plain"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

**`app/requirements.txt`**
```
flask==3.0.0
gunicorn==21.2.0
