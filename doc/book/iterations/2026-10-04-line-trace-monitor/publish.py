"""Encode the actual Godot frames for review; no geometry is recreated here."""
from pathlib import Path
from PIL import Image
import json

OUT = Path(__file__).resolve().parent
paths = sorted((OUT / 'frames').glob('*.png'))
assert len(paths) == 99, len(paths)
report = json.loads((OUT / 'report.json').read_text(encoding='utf-8'))
assert report['passed'], report['failures']
images = [Image.open(path).convert('RGB') for path in paths]
durations = [2300 if i % 33 == 32 else 160 for i in range(99)]
images[0].save(OUT / 'animation.webp', save_all=True, append_images=images[1:],
               duration=durations, loop=0, quality=86, method=5)
print('Published 99 Godot-rendered frames; runtime checks:', len(report['checks']))
