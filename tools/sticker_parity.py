"""sticker_parity.py - do the browser and the game draw the same sticker? (2026-11-13)

Every sticker is stored once, as SVG derived from its model (commons/data/stickers/designs.json). The web draws that
string with the browser's SVG engine (the /stickers SVG views as <img> or inline, the three.js view as a canvas
texture); the game draws it with ThorVG (Image.load_svg_from_string). This lays every design out on one grid twice -
once in headless Chrome, once in headless Godot (tools/probes/sticker_parity.gd), each rasterised to 120 px on its
long side in a 128 px cell - and compares the cells: the coverage (alpha over one half) as intersection over union, and
the colour where both cover.

  python tools/sticker_parity.py [--designs=<json>] [--keep]        exit code = designs that disagree

A NEGATIVE CONTROL runs first: one design is drawn by Godot with its colours swapped and its art shifted, and the
check must call it different. If the control passes, the check is blind and the run fails.
Output: ada_run/stickers/parity/{chrome.png, godot.png, report.json}.
"""
import base64
import json
import os
import subprocess
import sys
import urllib.parse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'ada_run' / 'stickers' / 'parity'
CHROME = r'C:/Program Files/Google/Chrome/Application/chrome.exe'
GODOT = r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
CELL, LONG, COLS = 128, 120, 10
IOU_MIN, COLOUR_MAX = 0.95, 0.07          # a design disagrees below this coverage overlap or above this mean colour gap


def size_of(svg):
    w = float(svg.split('width="', 1)[1].split('"', 1)[0])
    h = float(svg.split('height="', 1)[1].split('"', 1)[0])
    return w, h


def chrome_sheet(designs, png):
    rows = max(1, -(-len(designs) // COLS))
    cells = []
    for i, d in enumerate(designs):
        w, h = size_of(d['svg'])
        k = LONG / max(w, h)
        # the same integer size and offset Godot gets (ThorVG rounds the raster size; Image.blit_rect at an int offset)
        iw, ih = max(1, round(w * k)), max(1, round(h * k))
        x = (i % COLS) * CELL + (CELL - iw) // 2
        y = (i // COLS) * CELL + (CELL - ih) // 2
        url = 'data:image/svg+xml;base64,' + base64.b64encode(d['svg'].encode('utf-8')).decode('ascii')
        cells.append(f'<img src="{url}" style="position:absolute;left:{x}px;top:{y}px;width:{iw}px;height:{ih}px">')
    page = OUT / 'chrome_sheet.html'
    page.write_text('<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:transparent}'
                    'img{display:block}</style></head><body>' + ''.join(cells) + '</body></html>', encoding='utf-8')
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--default-background-color=00000000', f'--window-size={COLS * CELL},{rows * CELL}',
                    f'--screenshot={png}', page.as_uri()], check=True, capture_output=True, timeout=120)


def godot_sheet(designs_path, png):
    subprocess.run([sys.executable, str(ROOT / 'tools' / 'godot_watchdog.py'), f'--expect={png}', '--grace=90', '--stall=60', '--',
                    GODOT, '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--script', 'res://tools/probes/sticker_parity.gd', '--',
                    f'--designs={designs_path}', f'--out={png}'], check=False, capture_output=True, timeout=300)


def compare(a, b, n):
    out = []
    for i in range(n):
        box = ((i % COLS) * CELL, (i // COLS) * CELL, (i % COLS + 1) * CELL, (i // COLS + 1) * CELL)
        ca, cb = a.crop(box).load(), b.crop(box).load()
        inter = union = 0
        gap = 0.0
        both = 0
        for y in range(CELL):
            for x in range(CELL):
                pa, pb = ca[x, y], cb[x, y]
                ina, inb = pa[3] > 127, pb[3] > 127
                if ina or inb:
                    union += 1
                if ina and inb:
                    inter += 1
                    both += 1
                    gap += (abs(pa[0] - pb[0]) + abs(pa[1] - pb[1]) + abs(pa[2] - pb[2])) / (3 * 255)
        out.append({'iou': round(inter / union, 4) if union else 1.0, 'colour_gap': round(gap / both, 4) if both else 0.0, 'pixels': union})
    return out


def main():
    designs_path = Path(next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--designs=')), ROOT / 'commons' / 'data' / 'stickers' / 'designs.json'))
    OUT.mkdir(parents=True, exist_ok=True)
    designs = json.loads(designs_path.read_text(encoding='utf-8'))['designs']
    chrome_png, godot_png = OUT / 'chrome.png', OUT / 'godot.png'
    for p in (chrome_png, godot_png):
        if p.exists():
            p.unlink()
    chrome_sheet(designs, chrome_png)
    godot_sheet(designs_path, godot_png)
    if not chrome_png.exists() or not godot_png.exists():
        print('a sheet is missing:', chrome_png.exists(), godot_png.exists())
        return 99
    a, b = Image.open(chrome_png).convert('RGBA'), Image.open(godot_png).convert('RGBA')
    if a.size != b.size:
        print('sheet sizes differ:', a.size, b.size)
        return 98
    rows = compare(a, b, len(designs))

    # negative control: the first design with a filled layer, colours swapped and art shifted, drawn by Godot
    control = next(d for d in designs if 'fill="#' in d['svg'] and 'fill="#ffffff"' not in d['svg'][:400]) if designs else None
    bite = None
    if control:
        bad = json.loads(json.dumps(control))
        svg = bad['svg']
        colours = sorted(set(c for c in __import__('re').findall(r'#[0-9a-f]{6}', svg)))
        for c in colours:
            svg = svg.replace(c, '#' + ''.join('%02x' % (255 - int(c[k:k + 2], 16)) for k in (1, 3, 5)))
        bad['svg'] = svg.replace('<g ', '<g transform="translate(9 6)" ', 1)
        neg_path = OUT / 'negative_designs.json'
        neg_path.write_text(json.dumps({'designs': [bad]}), encoding='utf-8')
        neg_png = OUT / 'negative_godot.png'
        if neg_png.exists():
            neg_png.unlink()
        godot_sheet(neg_path, neg_png)
        if neg_png.exists():
            cell = a.crop((0, 0, COLS * CELL, CELL))
            i0 = designs.index(control)
            src = a.crop(((i0 % COLS) * CELL, (i0 // COLS) * CELL, (i0 % COLS + 1) * CELL, (i0 // COLS + 1) * CELL))
            mixed = Image.new('RGBA', (COLS * CELL, CELL))
            mixed.paste(src, (0, 0))
            bite = compare(mixed, Image.open(neg_png).convert('RGBA').crop((0, 0, COLS * CELL, CELL)), 1)[0]
    blind = bite is None or (bite['iou'] >= IOU_MIN and bite['colour_gap'] <= COLOUR_MAX)

    bad = []
    for d, r in zip(designs, rows):
        r['id'] = d['id']
        if r['iou'] < IOU_MIN or r['colour_gap'] > COLOUR_MAX:
            bad.append(r)
    report = {'designs': len(designs), 'disagree': bad, 'negative_control': bite, 'control_bites': not blind,
              'worst_iou': min(rows, key=lambda r: r['iou']), 'worst_colour': max(rows, key=lambda r: r['colour_gap']),
              'thresholds': {'iou_min': IOU_MIN, 'colour_gap_max': COLOUR_MAX}}
    (OUT / 'report.json').write_text(json.dumps({**report, 'rows': rows}, indent=1), encoding='utf-8')
    print('%d designs; %d disagree; worst coverage %s (%s); worst colour gap %s (%s); negative control %s -> %s' % (
        len(designs), len(bad), report['worst_iou']['iou'], report['worst_iou']['id'], report['worst_colour']['colour_gap'],
        report['worst_colour']['id'], bite, 'BITES' if not blind else 'BLIND (the check cannot fail)'))
    for r in bad:
        print('   DISAGREE %-28s coverage %.3f  colour gap %.3f' % (r['id'], r['iou'], r['colour_gap']))
    return len(bad) + (100 if blind else 0)


if __name__ == '__main__':
    sys.exit(main())
