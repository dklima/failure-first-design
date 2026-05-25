# Health Check Endpoints (Flask)
#
# Three levels of health checks:
# - /health/live   -> Is the process running? (Kubernetes liveness)
# - /health/ready  -> Ready to receive traffic? (Kubernetes readiness)
# - /health/full   -> All dependencies working? (debugging)
#
# CRITICAL: Never put external dependency checks in liveness probe.
# If your /health/live checks the database and the DB gets slow:
# 1. Liveness fails
# 2. Kubernetes kills the pod
# 3. Kubernetes starts new pod
# 4. New pod tries to connect to (already overloaded) database
# 5. Liveness fails again
# 6. Infinite restart loop
#
# Rule: /health/live should be DUMB - returns 200 if binary is running. Period.
#       /health/ready checks dependencies to REMOVE TRAFFIC, without killing the process.

import time
from datetime import datetime, timezone

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__, url_prefix="/health")


def _run_check(name: str, probe) -> dict:
    start = time.monotonic()
    try:
        probe()
        elapsed = round((time.monotonic() - start) * 1000, 2)
        return {"status": "healthy", "duration_ms": elapsed}
    except Exception as e:
        elapsed = round((time.monotonic() - start) * 1000, 2)
        return {"status": "unhealthy", "duration_ms": elapsed, "error": str(e)}


@health_bp.route("/live")
def live():
    return jsonify({"status": "alive"}), 200


@health_bp.route("/ready")
def ready():
    # Import your app's db and redis here, or wire them via app context
    from flask import current_app

    checks = {}

    db = current_app.extensions.get("sqlalchemy")
    if db:
        checks["database"] = _run_check("database", lambda: db.session.execute("SELECT 1"))

    redis_client = current_app.extensions.get("redis")
    if redis_client:
        checks["redis"] = _run_check("redis", lambda: redis_client.ping())

    all_healthy = all(c["status"] == "healthy" for c in checks.values())
    status_code = 200 if all_healthy else 503

    return jsonify({
        "status": "healthy" if all_healthy else "unhealthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "checks": checks,
    }), status_code


# Usage:
# from health_controller import health_bp
# app.register_blueprint(health_bp)
