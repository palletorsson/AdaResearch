"""Copy the reviewed page and its Godot captures to the local encyclopedia."""
from pathlib import Path
import shutil
ROOT=Path(__file__).resolve().parents[3]
source=ROOT/'doc/research/possible-bodies'
target=Path('C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/research/possible-bodies')
assert target.is_dir()
shutil.copy2(source/'randomness-arrivals.html',target/'randomness-arrivals.html')
(target/'randomness-arrivals').mkdir(exist_ok=True)
for p in (source/'randomness-arrivals').glob('*.png'):shutil.copy2(p,target/'randomness-arrivals'/p.name)
print('Published /research/possible-bodies/randomness-arrivals.html')
