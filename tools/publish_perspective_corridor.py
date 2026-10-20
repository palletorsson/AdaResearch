"""Publish tested native views of the Borromini-inspired museum corridor."""
from pathlib import Path
import json
import shutil
import hashlib

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT=ROOT/'doc/book/iterations/2026-10-12-perspective-the-sphere-keeps-its-size'

def main():
    reports={}
    for tag in ['perspective-mobile','perspective-gl','corner-perspective-regression']:
        report=json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
        assert report['passed'] and any(c['name']=='corner probe completed' and c['passed'] for c in report['checks']),tag
        assert not any(e.lower() in log.lower() for e in ['SCRIPT ERROR:','SHADER ERROR:','shader compilation failed']),tag
        reports[tag]=report
    OUT.mkdir(parents=True,exist_ok=True)
    for tag in reports:
        target=OUT/'evidence'/tag;target.mkdir(parents=True,exist_ok=True)
        for name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(RUN/tag/name,target/name)
    pictures=[('front','From the marked viewpoint','Diminishing columns and converging surfaces suggest a passage longer than its eight physical metres.'),
              ('side','Walk beside the enclosure','Both sides now have full-height converging walls. The marked outside path reveals the taper; the carried point keeps its radius.'),
              ('above','The construction from above','The surrounding gallery stays full-size. Its side walk remains level while the colonnade floor rises.')]
    for name,_,_ in pictures:shutil.copy2(RUN/'perspective-mobile'/f'{"room-above" if name=="above" else name}.png',OUT/f'{name}.png')
    paths=list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*.gd'))+[ROOT/'tools/probes/perspective_corridor.gd',Path(__file__)]
    (OUT/'manifest.json').write_text(json.dumps({'runs':{k:len(v['checks']) for k,v in reports.items()},'scope':'Native desktop museum tests. Physical headset acceptance open.','sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf-8')
    cards=''.join(f'<section><h2>{title}</h2><p>{caption}</p><img src="{name}.png" alt="{title}" loading="lazy"></section>' for name,title,caption in pictures)
    counts=' · '.join(f'{k}: {len(v["checks"])}/{len(v["checks"])}' for k,v in reports.items())
    page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Perspective · the sphere keeps its size</title>
<style>body{{background:#171d26;color:#e9e2d5;font:18px/1.6 system-ui;margin:auto;padding:40px;max-width:1280px}}h1{{font-size:clamp(38px,6vw,75px);line-height:1.1}}a{{color:#85d1dc}}img{{width:100%;border-radius:8px}}section{{margin:55px 0}}p{{max-width:900px}}.receipt{{background:#23352e;padding:20px}}small{{color:#f2be64}}</style>
<small>ENDLESS MUSEUM · 12 OCTOBER 2026 · INSTALLED</small><h1>The sphere<br>keeps its size.</h1><p>A Borromini-inspired colonnade sits beside our linked spaces. Stand on the gold disk and look down its axis, then carry the same point along the side path. The apparent depth and the measured construction come apart.</p>
<p><strong>Find it:</strong> reload NonEuclidean_Spaces, enter Seven Spaces, and pass to the left of the Rose/Blue pavilion. The gold doorway says PERSPECTIVE / BORROMINI. Return through the same doorway. The existing Around the Corner passage remains on the right.</p>
<p class="receipt">{counts}</p>{cards}<section><h2>What changes?</h2><p>The floor rises 0.6 metres over an eight-metre passage. The interior width tapers from 3 metres to 0.84 metres, and its clear height from 3.4 metres to 1.3 metres. Columns diminish. Full-height walls on both converging sides enclose the axial view. The outside walkway and overhead survey reveal the tapered construction. A small fixed sphere at the far end participates in the illusion; your original PointBody keeps its 0.085-metre radius.</p><p>This is a geometric study inspired by <a href="https://galleriaspada.cultura.gov.it/visita/la-prospettiva/">Borromini’s Palazzo Spada perspective</a>, rather than a surveyed replica. Distances and collision geometry remain ordinary. The linked-space door changes your room; the colonnade changes your judgment of its depth.</p><p>The tests use the real museum walker and hand: entering, walking alongside the full construction, carrying the same sphere, and returning. Both desktop renderers pass, and the complete corner-walk regression passes. Physical headset acceptance remains open.</p><p><a href="manifest.json">Evidence manifest</a> · <a href="../2026-10-11-around-the-corner/index.html">Around the Corner</a></p></section></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    print(OUT/'index.html')

if __name__=='__main__':main()
