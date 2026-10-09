"""Keep the author's entrance layout; record the state before this pass."""
from pathlib import Path
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
for relative in [
    'commons/primitives/point/point_condition.gd',
    'commons/maps/Point_Lines/map_data.json',
    'commons/maps/Point_Lines/final.md',
    'commons/maps/Point_Coordinates/final.md',
    'commons/maps/Point_Coordinates/technical.md',
]:
    target = OUT / 'before' / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        shutil.copy2(ROOT / relative, target)
print('Before snapshots saved; authored map preserved.')
