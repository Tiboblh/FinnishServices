from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent

DATABASE_PATH = BASE_DIR / "data.db"


HOST = "0.0.0.0"
PORT = 9142
DEBUG = True