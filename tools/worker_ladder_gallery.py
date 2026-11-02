"""The worker ladder bench, published: one seed of the worker being at a series of stages, side by side.

Runs commons/testing/probe_worker_ladder.tscn under the watchdog (checks + a tile per stage), composes the row
from the tiles, and publishes the gallery /worker-ladder in the encyclopedia (public/worker-ladder/manifest.json in
the convention of /biome-ladder). Exit 1 when a check fails or the bench does not report.

  python tools/worker_ladder_gallery.py [--seed=7] [--stages=Point_One,Point_Lines,...] [--no-publish]
"""
from pathlib import Path
import json, os, shutil, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ada_run/worker_ladder'
SITE = ROOT.parent / 'ada_encyclopedia'
GODOT = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')


def arg(name, default):
    return next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--' + name + '=')), default)


def main():
    sys.stdout.reconfigure(encoding='utf8')
    seed = arg('seed', '7')
    stages = arg('stages', '')
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    cmd = [sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(OUT), '--grace=200', '--stall=60', '--',
           GODOT, '--path', str(ROOT), '--xr-mode', 'off', '--resolution', '960x960', '--log-file', str(OUT / 'godot.log'),
           'res://commons/testing/probe_worker_ladder.tscn', '--', '--out=' + OUT.as_posix(), '--seed=' + seed,
           *(['--stages=' + stages] if stages else [])]
    result = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding='utf8', errors='replace')
    report = OUT / 'checks.json'
    if not report.exists():
        print(result.stdout[-2000:], result.stderr[-2000:])
        sys.exit('the bench did not report')
    checks = json.loads(report.read_text(encoding='utf8'))
    for c in checks['checks']:
        print('PASS' if c['passed'] else 'FAIL', c['name'])
    tiles = sorted(OUT.glob('[0-9][0-9]_*.png'))
    row = compose_row(tiles, OUT / 'row.png')
    print('row:', row)
    if '--no-publish' not in sys.argv:
        publish(checks, tiles, row, seed)
    sys.exit(0 if checks['passed'] else 1)


def compose_row(tiles, path):
    from PIL import Image, ImageDraw
    ims = [Image.open(t).convert('RGB') for t in tiles]
    w = 360
    ims = [i.resize((w, w)) for i in ims]
    cols = 5
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new('RGB', (w * cols, (w + 26) * rows), (233, 230, 223))
    d = ImageDraw.Draw(sheet)
    for k, (t, im) in enumerate(zip(tiles, ims)):
        x, y = (k % cols) * w, (k // cols) * (w + 26)
        sheet.paste(im, (x, y + 26))
        d.text((x + 8, y + 7), t.stem.replace('_', ' ', 1), fill=(40, 40, 40))
    sheet.save(path)
    return path


def publish(checks, tiles, row, seed):
    dest = SITE / 'public/worker-ladder'
    if not SITE.exists():
        print('no encyclopedia checkout at', SITE)
        return
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    entries = []
    shutil.copy(row, dest / 'row.png')
    entries.append({'id': 'row', 'image': '/worker-ladder/row.png', 'config': '/worker-ladder/row.json',
                    'strip': 'the row', 'order': 0, 'notes': 'seed %s, every stage side by side' % seed})
    (dest / 'row.json').write_text(json.dumps({'seed': seed, 'stages': checks['stages'], 'checks': checks['checks']}, indent=2), encoding='utf8')
    for i, t in enumerate(tiles):
        shutil.copy(t, dest / t.name)
        shutil.copy(t.with_suffix('.json'), dest / t.with_suffix('.json').name)
        meta = json.loads(t.with_suffix('.json').read_text(encoding='utf8'))
        entries.append({'id': t.stem, 'image': '/worker-ladder/' + t.name, 'config': '/worker-ladder/' + t.stem + '.json',
                        'strip': 'the ladder - one seed, a body per stage', 'order': i + 1,
                        'notes': '%d. %s - %d parts: %s' % (i, meta['stage'], len(meta['parts']), ', '.join(meta['parts']))})
    manifest = {'version': 1, 'schema_version': 1,
                'description': "The Void's worker as one being at many stages (the playground plan's worker ladder). Like the biome ladder, the stage's words decide which parts stand and the seed decides the body plan: the heart alone at Point One - the biome's black seed point - then rods to four feet, a face, the carapace and solid legs, knees, joints and an ornament; hinges, golden segments and a carried cube at Transformation; hue, lamp, band and painted feet at Colour; planted feet, springs and a push bar at Forces; a gait, a sampled plan, a rule-30 skin, recursive toes, antennae and a sapling grown by rewriting, and eyes, by L-systems; a soft belly, a fused skin and the head crab's graphite and brass at the end of the walk.",
                'generated': time.strftime('%Y-%m-%dT%H:%M:%S'), 'tool': 'tools/worker_ladder_gallery.py', 'entries': entries}
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=1, ensure_ascii=False), encoding='utf8')
    page = SITE / 'src/app/worker-ladder/page.tsx'
    if not page.exists():
        page.parent.mkdir(parents=True, exist_ok=True)
        page.write_text('''"use client";

import { GalleryView } from "@/components/gallery/GalleryView";

export default function WorkerLadderPage() {
  return (
    <GalleryView
      gallery="worker-ladder"
      title="Worker being - one being, a body per stage"
      blurb="The worker of the Void as one being at many stages of the spine, beside the biome ladder it lives in. The stage's words gate every part, exactly as they gate the biome object's layers, and the seed fixes the body plan, so the same being stands in every tile and only what the walk allows has been added: the heart alone at Point One, rods, a carapace and solid legs through the primitives, hinges and a carried cube at Transformation, colour, then planted feet and springs at Forces, antennae and a sapling by L-systems, and the head crab's made finish at the end. Built by tools/worker_ladder_gallery.py from commons/artifacts/worker_being. Click a tile for its token."
      groupBy="strip"
      imageFit="contain"
    />
  );
}
''', encoding='utf8')
        print('wrote', page)
    print('published', len(entries), 'entries to', dest)


if __name__ == '__main__':
    main()
