import os
from pathlib import Path
from dotenv import load_dotenv

# Project root = folder that contains src/
PROJECT_ROOT = Path(__file__).resolve().parents[1]

# Load .env from project root
ENV_PATH = PROJECT_ROOT / ".env"
load_dotenv(dotenv_path=ENV_PATH, override=True)

MYSQL_HOST = os.getenv("MYSQL_HOST") or "127.0.0.1"
MYSQL_PORT = int(os.getenv("MYSQL_PORT") or 3306)
MYSQL_USER = os.getenv("MYSQL_USER") or "root"
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE")

if not MYSQL_PASSWORD:
    raise ValueError("MYSQL_PASSWORD missing in .env")

OUTPUTS_DIR = PROJECT_ROOT / "outputs"
