from pathlib import Path
import hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
def put(p,t):
 p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text(t,encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
