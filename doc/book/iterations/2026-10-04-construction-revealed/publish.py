from pathlib import Path
import json
from PIL import Image

out = Path(__file__).resolve().parent
report = json.loads((out / 'report.json').read_text(encoding='utf-8'))
assert report['passed'], report['failures']
paths = sorted((out / 'frames').glob('*.png'))
assert len(paths) == 120
images = [Image.open(path).convert('RGB') for path in paths]
images[0].save(out / 'animation.webp', save_all=True, append_images=images[1:],
    duration=[1300 if i % 20 == 19 else 180 for i in range(120)], loop=0, quality=85, method=5)
print('Published actual Godot frames:', len(paths), 'Runtime checks:', len(report['checks']))
