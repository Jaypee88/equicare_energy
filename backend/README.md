# EquiCare Energy API

FastAPI backend for site accounts, shared-energy rooms, meter readings, allocations, audit history and critical-service autonomy calculations.

## Local Windows setup (PowerShell)

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:EQUICARE_SECRET_KEY = "replace-with-a-long-random-secret"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open `http://127.0.0.1:8000/docs` for interactive API documentation.

## Tests

```powershell
pip install -r requirements.txt
$env:DATABASE_URL = "sqlite:///./test_equicare.db"
pytest -q
```

## Configuration

- `DATABASE_URL`: SQLite by default; PostgreSQL-compatible SQLAlchemy URL in deployment.
- `EQUICARE_SECRET_KEY`: required strong random secret for production.
- The first account registration currently receives the administrator role. Add invite-only registration and role assignment before public deployment.

This API stores meter source types separately. It cannot determine room-level consumption from a central site meter. Autonomy outputs are advisory and do not issue load-switching commands.
