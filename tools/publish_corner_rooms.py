"""Publish native corner-walk evidence only after all relevant probes pass."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT = ROOT / 'doc/book/iterations/2026-10-11-around-the-corner'
TAGS = {'corner-rooms-mobile': 'corner probe completed',
        'corner-rooms-gl': 'corner probe completed',
        'overlap-corners-regression': 'overlap probe completed',
        'wing-corners-regression': 'probe reached every final assertion'}


def main():
    reports = {}
    for tag, end in TAGS.items():
        report = json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log = (RUN/tag/'stdout.log').read_text(encoding='utf-8')
        assert report['passed'] and any(c['name'] == end and c['passed'] for c in report['checks']), tag
        for error in ['SCRIPT ERROR:', 'SHADER ERROR:', 'shader compilation failed']:
            assert error.lower() not in log.lower(), (tag, error)
        reports[tag] = report
    OUT.mkdir(parents=True, exist_ok=True)
    for tag in reports:
        target = OUT/'evidence'/tag
        target.mkdir(parents=True, exist_ok=True)
        for name in ['report.json', 'stdout.log', 'source_manifest.json']:
            shutil.copy2(RUN/tag/name, target/name)
    pictures = [
        ('entrance', 'Follow the gold line', 'The new entrance is in the first Seven Spaces chamber, to the right of the overlapping-room pavilion.'),
        ('room-1-entry', 'The next door is hidden', 'Room 0001. The inner block prevents you seeing its next threshold from the entrance.'),
        ('corner-1', 'Turn, and another room opens', 'The gold doorway reveals the pink room. Walk through with the same point; the camera keeps its orientation.'),
        ('carried-point', 'The same point travels', 'The museum hand carries the original black point along the floor line. No replacement point is created for the next room.'),
        ('room-2-entry', 'A different room, a familiar action', 'Room 0002 has another colour and another ring. Its corner again withholds the next doorway.'),
        ('corner-5', 'Four turns have not returned you', 'A repeated colour does not mean a repeated address. The sequence keeps extending beyond Room 0005.'),
        ('room-above', 'The corner from above', 'One ordinary room contains a solid inner block and two perpendicular doorways. The connections make the impossible larger arrangement.'),
        ('point-returned', 'You can go back', 'The return doorway leads to the original museum chamber. The live point survives the journey.')]
    for name, _, _ in pictures:
        shutil.copy2(RUN/'corner-rooms-mobile'/f'{name}.png', OUT/f'{name}.png')
    sources = list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*')) + [
        ROOT/'tools/probes/corner_rooms.gd', ROOT/'tools/probes/overlapping_rooms.gd',
        ROOT/'tools/probes/noneuclidean_wing.gd', Path(__file__)]
    receipt = {
        'published_utc': datetime.now(timezone.utc).isoformat(),
        'scope': 'Installed museum space. Actual desktop collision-body and hand checks, native renderer images. Physical headset acceptance open.',
        'runs': {tag: {'checks': len(r['checks']), 'passed': r['passed'], 'observations': r['observations']} for tag, r in reports.items()},
        'sources': {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources if p.is_file() and p.suffix != '.uid'}}
    (OUT/'manifest.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    shutil.copy2(ROOT/'commons/artifacts/noneuclidean_wing/README.md', OUT/'BUILD-NOTES.md')
    totals = ' · '.join(f'{html.escape(tag)}: {len(r["checks"])} / {len(r["checks"])}' for tag, r in reports.items())
    cards = ''.join(f'<section id="{name}"><h2>{html.escape(title)}</h2><p>{html.escape(text)}</p><a href="{name}.png"><img src="{name}.png" loading="lazy" alt="Native museum capture: {html.escape(title)}"></a></section>' for name, title, text in pictures)
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Around the corner · Endless Museum</title>
<style>:root{color-scheme:dark;background:#161b24;color:#e9e2d5;font-family:system-ui,sans-serif}*{box-sizing:border-box}body{max-width:1280px;padding:32px;margin:auto}header{padding:40px 0}h1{font-size:clamp(40px,7vw,88px);line-height:1.02;margin:20px 0}h2{font-size:30px}p,li{max-width:880px;line-height:1.65}a{color:#8cd4de}small{color:#f2be64}nav{display:flex;gap:24px;flex-wrap:wrap;border-block:1px solid #48505b;padding:20px 0}section{margin:56px 0}img{display:block;width:100%;border-radius:8px;margin-top:24px}.receipt{padding:20px;background:#23312f;border:1px solid #4a6b5e;line-height:1.7}.note{background:#222936;padding:24px;border-radius:8px}code{overflow-wrap:anywhere}</style>
<header><small>ENDLESS MUSEUM · 11 OCTOBER 2026 · INSTALLED</small><h1>Always another<br>corner.</h1><p>Walk into a room. Go around the solid block. A doorway reveals another room. Turn right again. Four turns restore your heading, but the room number keeps changing.</p><p><strong>Try it:</strong> reload <code>NonEuclidean_Spaces</code> and enter Seven Spaces. Follow the gold floor line to the right of the Rose/Blue pavilion. The door says <strong>AROUND THE CORNER</strong>. Carry the point with the museum’s existing grab controls. Walk back through the doors to return.</p><p>F6 launcher: <code>commons/artifacts/noneuclidean_wing/museum.tscn</code>.</p><p class="receipt">TOTALS</p></header>
<nav><a href="#room-1-entry">Before the turn</a><a href="#corner-1">After the turn</a><a href="#room-above">Above</a><a href="#how">How it works</a><a href="BUILD-NOTES.md">Build notes</a><a href="manifest.json">Test evidence</a></nav>
<main>CARDS<section id="how" class="note"><h2>A growing walk, a small working set</h2><p>The next room is built ahead of you, behind the solid corner. At most five corner rooms stay loaded: the first, current, previous, next, and any room containing your dropped point. Distant empty rooms are rebuilt from their number when you return. There is no authored final room.</p><p>The same PointBody stays alive throughout. Its room is retained if you leave it behind. This persistence lasts for the running museum session. It does not add a new save format or promise persistence for arbitrary extra objects.</p><p>Only the occupied room and visible doorway previews are rendered. The existing portal stencil and aperture culling are reused. Views are one level deep and portal lighting is simplified.</p><h2>What the test actually did</h2><p>The real museum collision body walked twelve consecutive corners. Further checks reached Room 0019, left and recovered the same point, regenerated previous rooms, verified reverse passages, and kept the resident-room maximum at five. Both native desktop renderers passed. The previous overlapping rooms and seven-space wing also passed their regression checks.</p><p>Headset stereo, room-scale movement and Quest performance still need a physical device test. This report shows real engine captures, not concept images. The canonical tutorial and reflective text remain at their reviewed versions.</p><h2>The Duke Nukem memory</h2><p>The comparison is useful: the Build engine behind Duke Nukem 3D organised visibility through sectors. <a href="https://advsys.net/ken/build.htm">Ken Silverman’s history</a> records that sector design and later room-over-room demonstrations. This new encounter uses Godot portal connections and on-demand rooms; it does not reproduce a particular Duke level.</p><p>The room you stand in has ordinary Euclidean distances. The surprise lies in how rooms connect: local certainty, an impossible overall floor plan. This is distinct from the curved metrics in the later hyperbolic chambers.</p></section></main>
<footer><p><a href="../2026-10-11-overlapping-rooms-the-same-point/index.html">The two overlapping rooms</a> · <a href="../2026-10-11-seven-spaces-in-the-museum/index.html">Seven Spaces</a></p></footer></html>'''
    (OUT/'index.html').write_text(page.replace('TOTALS', totals).replace('CARDS', cards), encoding='utf-8')
    print(OUT/'index.html')


if __name__ == '__main__':
    main()
