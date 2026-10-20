"""Publish completed native labyrinth tests and their real museum images."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT=ROOT/'doc/book/iterations/2026-10-12-labyrinth-the-point-remembers'

def main():
    reports={}
    for tag in ['labyrinth-mobile','labyrinth-gl','forest-labyrinth-regression']:
        report=json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
        assert report['passed'] and any(c['name']=='corner probe completed' and c['passed'] for c in report['checks']),tag
        assert not any(e.lower() in log.lower() for e in ['SCRIPT ERROR:','SHADER ERROR:','shader compilation failed']),tag
        reports[tag]=report
    OUT.mkdir(parents=True,exist_ok=True)
    for tag in reports:
        target=OUT/'evidence'/tag;target.mkdir(parents=True,exist_ok=True)
        for name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(RUN/tag/name,target/name)
    pictures=[('room-a','Room A: leave a mark','Choose a passage. A gold seal keeps the shortcut closed until your held point reaches it.'),
              ('marker-returned','The circuit returns you to your point','The actual hand placed this same live sphere on the podium before the walk. The complete A–B–C–D–A circuit leaves it here.'),
              ('shortcut','A new connection stays open','Bring the held point to the gold seal. Both ends of the A–C shortcut open; your action changes the available route.'),
              ('room-c','Reach C another way','The shortcut reaches the rose-ring room directly. You can return through it or take the longer circuit.')]
    for name,_,_ in pictures:shutil.copy2(RUN/'labyrinth-mobile'/f'{name}.png',OUT/f'{name}.png')
    paths=list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*.gd'))+[ROOT/'tools/probes/labyrinth.gd',Path(__file__)]
    (OUT/'manifest.json').write_text(json.dumps({'runs':{k:len(v['checks']) for k,v in reports.items()},'scope':'Native desktop walker/hand checks. Finite loop and persistent session shortcut. Physical headset acceptance open.','sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf-8')
    cards=''.join(f'<section><h2>{title}</h2><p>{caption}</p><img src="{name}.png" alt="{title}" loading="lazy"></section>' for name,title,caption in pictures)
    counts=' · '.join(f'{k}: {len(v["checks"])}/{len(v["checks"])}' for k,v in reports.items())
    page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Labyrinth · the point remembers</title>
<style>body{{background:#171d26;color:#e9e2d5;font:18px/1.6 system-ui;margin:auto;padding:40px;max-width:1280px}}h1{{font-size:clamp(38px,6vw,75px);line-height:1.1}}a{{color:#85d1dc}}img{{width:100%;border-radius:8px}}section{{margin:55px 0}}p{{max-width:900px}}.receipt{{background:#23352e;padding:20px}}small{{color:#f2be64}}svg{{max-width:600px;width:100%;background:#222a35;border-radius:8px}}</style>
<small>ENDLESS MUSEUM · 12 OCTOBER 2026 · INSTALLED</small><h1>Leave a point.<br>Find your way back.</h1><p>Four rooms form a circuit. Leave the same point in A, pass through B, C and D, and return to your marker. A shortcut can change the route without changing the rooms.</p><p><strong>Find it:</strong> reload NonEuclidean_Spaces, enter Seven Spaces and then Blue. The rear-right gold doorway says LABYRINTH / LEAVE A MARK. Room A has a sealed shortcut on the left. Bring your held point to its gold seal to open the direct passage to C. The entrance doorway returns to Blue.</p><p class="receipt">{counts}</p>
<section><h2>The connections</h2><svg viewBox="0 0 400 300" role="img" aria-label="A B C D form a circuit; a shortcut connects A and C"><path d="M80 70H320V230H80Z" fill="none" stroke="#70cddd" stroke-width="5"/><path d="M80 70L320 230" stroke="#f2be64" stroke-width="4" stroke-dasharray="8 5"/><g fill="#171d26" stroke="#e9e2d5" stroke-width="2"><circle cx="80" cy="70" r="26"/><circle cx="320" cy="70" r="26"/><circle cx="320" cy="230" r="26"/><circle cx="80" cy="230" r="26"/></g><g fill="#e9e2d5" font-family="system-ui" font-size="25" text-anchor="middle"><text x="80" y="79">A</text><text x="320" y="79">B</text><text x="320" y="239">C</text><text x="80" y="239">D</text></g></svg><p>This diagram shows connectivity. The portal renderer places the physical sectors separately. Every connection works in both directions.</p></section>{cards}
<section><h2>Three different returns</h2><p>Around the Corner keeps creating another numbered room. The repeating gallery returns the same architectural pattern at an edge. This finite labyrinth returns you to a room containing the object you left there. A landmark and a stored object let you test whether a place is familiar or actually the same.</p><p>The point becomes an instrument of orientation and an opener of a connection. The loop has four rooms and one shortcut. Its state persists during the running museum session; it does not add a new save format.</p><h2>Verification</h2><p>The native museum hand placed the original point on A’s podium. The collision body walked the four-room circuit and found the same instance at its retained position. Checks verify physical barriers at both shortcut ends, hand opening, forward and reverse shortcut travel, supported arrivals, unchanged point identity and return to Blue. Both desktop renderers pass; the column forest passes regression. Physical headset acceptance remains open.</p><p><a href="manifest.json">Evidence</a> · <a href="../2026-10-12-column-forest-a-profile-branches/index.html">Column forest</a> · <a href="../2026-10-12-repeating-gallery-the-same-point/index.html">Repeating gallery</a> · <a href="../2026-10-11-around-the-corner/index.html">Around the Corner</a></p></section></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8');print(OUT/'index.html')

if __name__=='__main__':main()
