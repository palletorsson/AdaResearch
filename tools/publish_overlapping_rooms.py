"""Publish only successful native overlapping-room runs, including regression."""
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT = ROOT / 'doc/book/iterations/2026-10-11-overlapping-rooms-the-same-point'


def main():
    reports = {}
    for tag in ['overlapping-rooms', 'overlapping-rooms-mobile', 'seven-spaces-overlap-regression']:
        report = json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log = (RUN/tag/'stdout.log').read_text(encoding='utf-8')
        end = 'probe reached every final assertion' if tag.startswith('seven-') else 'overlap probe completed'
        assert report['passed'] and any(c['name'] == end and c['passed'] for c in report['checks']), tag
        for error in ['SCRIPT ERROR:', 'SHADER ERROR:', 'shader compilation failed']:
            assert error.lower() not in log.lower(), (tag, error)
        reports[tag] = report
    OUT.mkdir(parents=True, exist_ok=True)
    for tag in reports:
        target = OUT / 'evidence' / tag
        target.mkdir(parents=True, exist_ok=True)
        for name in ['report.json', 'stdout.log', 'source_manifest.json']:
            shutil.copy2(RUN/tag/name, target/name)
    pictures = [
        ('two-doors', 'Two doors, one small pavilion', 'Both destination interiors are visible at once. Their 14 × 12 metre apparent footprints overlap behind this 6 × 3 metre shell.'),
        ('inside-1', 'Inside Rose', 'Round columns, suspended rings, and a podium for the point you carried here.'),
        ('inside-2', 'Inside Blue', 'The second door reveals a different full-size interior, in the same apparent part of the building.'),
        ('hand-through', 'Your hand arrives first', 'The black point remains visible beyond the doorway while your head is still outside. Its image is split at the aperture; its live object is unchanged.'),
        ('return-1', 'A view back to where you came from', 'The return doorway has its own stencil view and a physical crossing. Walk back; there is no travel button to press.'),
        ('pavilion-above', 'A small exterior', 'An overhead capture makes the exterior footprint legible. You can walk around this shell.'),
        ('pavilion-behind', 'Walk around the back', 'The opaque back has no doorway. Back-facing portal previews are culled.'),
    ]
    for name, _, _ in pictures:
        shutil.copy2(RUN/'overlapping-rooms-mobile'/f'{name}.png', OUT/f'{name}.png')
    sources = list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*')) + [
        ROOT/'tools/probes/overlapping_rooms.gd', ROOT/'tools/probes/noneuclidean_wing.gd',
        Path(__file__), ROOT/'commons/maps/NonEuclidean_Spaces/map_data.json',
        ROOT/'commons/artifacts/registry/alternative_geometries.json']
    manifest = {
        'published_utc': datetime.now(timezone.utc).isoformat(),
        'scope': 'Actual museum geometry, native renderer captures, author walker/desktop-hand tests. Physical headset acceptance remains open.',
        'runs': {k: {'checks': len(v['checks']), 'passed': v['passed'], 'observations': v['observations']} for k, v in reports.items()},
        'sources': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources if p.is_file() and p.suffix != '.uid'}
    }
    (OUT/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    shutil.copy2(ROOT/'commons/artifacts/noneuclidean_wing/README.md', OUT/'BUILD-NOTES.md')
    counts = ' · '.join(f'{v["observations"]["renderer"]}: {len(v["checks"])} / {len(v["checks"])}' for k, v in reports.items() if not k.startswith('seven-'))
    culling = reports['overlapping-rooms-mobile']['observations']['front_culling']
    cards = ''.join(f'<section id="{name}"><h2>{html.escape(title)}</h2><p>{html.escape(caption)}</p><a href="{name}.png"><img loading="lazy" src="{name}.png" alt="Native museum capture: {html.escape(title)}"></a></section>' for name, title, caption in pictures)
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Overlapping rooms · the same point</title>
<style>:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#131922;color:#e8e4db}*{box-sizing:border-box}body{max-width:1280px;margin:auto;padding:32px}header{padding:40px 0}h1{font-size:clamp(38px,6vw,76px);line-height:1.04;margin:18px 0}h2{font-size:30px}p,li{line-height:1.6;max-width:880px}small{color:#ed91b4}a{color:#88d2db}nav{display:flex;flex-wrap:wrap;gap:20px;padding:20px 0;border-block:1px solid #3b4350}section{margin:50px 0}img{display:block;width:100%;border-radius:8px;margin-top:24px}.receipt{padding:22px;background:#1d2c2b;border:1px solid #44665d;border-radius:8px}.details{padding:24px;background:#202733;border-radius:8px}code{overflow-wrap:anywhere}footer{margin:60px 0}</style>
<header><small>ENDLESS MUSEUM · 11 OCTOBER 2026 · INSTALLED</small><h1>Two rooms.<br>The same point.</h1><p>Enter the Non-Euclidean hall’s Seven Spaces doorway. The first chamber now contains a small pavilion with a rose door and a blue door. Each opens into a different full-size gallery. Carry the point through, leave it, return outside, and find it again.</p><p><strong>Try it:</strong> reload <code>NonEuclidean_Spaces</code>, or run <code>commons/artifacts/noneuclidean_wing/museum.tscn</code> with F6. Desktop: right-click to pick up/drop, wheel to adjust hold distance. VR: the museum’s existing grab controls. The next-chamber console is beside the left wall.</p><p class="receipt">COUNTS<br>Whole-wing regression: REGRESSION / REGRESSION checks.</p></header>
<nav><a href="#two-doors">The doors</a><a href="#inside-1">Rose</a><a href="#inside-2">Blue</a><a href="#hand-through">The point</a><a href="#culling">Portal culling</a><a href="BUILD-NOTES.md">Build notes</a><a href="manifest.json">Evidence</a></nav>
<main>CARDS<section id="culling" class="details"><h2>Portal occlusion culling</h2><p>The renderer draws the occupied room and one level of geometry visible through connected doorways. It rejects disconnected sectors, back-facing doors, doors outside the camera frustum, and meshes outside the eye-to-aperture cone. Stencil masks and depth tests then decide the visible pixels.</p><p>From the two-door capture: SUBMITTED of CANDIDATES preview meshes submitted across PORTALS visible doors. Looking away submits zero. These are visibility counts, not a frame-rate claim.</p><p>A foreground object can block a portal. Inside its view, a pedestal obscures the floor correctly. The carried point is split at the threshold so the hand may cross first. Only visual representations are duplicated; the live point and its state remain singular.</p></section></main>
<footer><h2>Tested, and still to test</h2><p>The actual museum walker crossed both doors in both directions. The museum’s native desktop hand picked up, carried, dropped and retrieved the same point. Tests also cover a release through the door before the head crosses, floor support, wall rejection, rapid crossing, visible-room selection and actual stencil/depth pixels. All six later chambers passed regression checks.</p><p>These are connected Euclidean rooms. The portals change their arrangement; they do not create intrinsic curvature. Views are one level deep, with simplified portal lighting and no recursive portal views. Mobile tests ran on a desktop GPU. Physical headset stereo, comfort and Quest performance remain to be checked.</p><p>The implementation uses <a href="https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html#stencil-modes">Godot 4.6 stencil rendering</a> with explicit sector/aperture culling. <a href="../2026-10-11-seven-spaces-in-the-museum/index.html">Earlier seven-chamber review</a>.</p></footer></html>'''
    replacements = {'COUNTS': counts, 'REGRESSION': str(len(reports['seven-spaces-overlap-regression']['checks'])), 'CARDS': cards, 'SUBMITTED': str(culling['submitted']), 'CANDIDATES': str(culling['candidates']), 'PORTALS': str(culling['portals'])}
    for old, new in replacements.items():
        page = page.replace(old, new)
    (OUT/'index.html').write_text(page, encoding='utf-8')
    print(OUT/'index.html')
    print(counts)


if __name__ == '__main__':
    main()
