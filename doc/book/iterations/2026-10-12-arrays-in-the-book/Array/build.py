from pathlib import Path
import hashlib
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
def put(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
