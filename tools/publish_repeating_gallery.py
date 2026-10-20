"""Publish native repeating-gallery captures after completed passing probes."""
from pathlib import Path
import json
import shutil
import hashlib

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT=ROOT/'doc/book/iterations/2026-10-12-repeating-gallery-the-same-point'

def main():
    reports={}
    for tag in ['repeating-mobile','repeating-gl','overlap-repeating-regression','perspective-repeating-regression']:
        report=json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
        end='overlap probe completed' if tag.startswith('overlap-') else 'corner probe completed'
        assert report['passed'] and any(c['name']==end and c['passed'] for c in report['checks']),tag
        assert not any(e.lower() in log.lower() for e in ['SCRIPT ERROR:','SHADER ERROR:','shader compilation failed']),tag
        reports[tag]=report
    OUT.mkdir(parents=True,exist_ok=True)
    for tag in reports:
        target=OUT/'evidence'/tag;target.mkdir(parents=True,exist_ok=True)
        for name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(RUN/tag/name,target/name)
    pictures=[('inside','A gallery beyond its edges','Pale columns, gold rings and cyan thresholds continue into neighbouring views. Carry the original point across a gold edge.'),
              ('across-edge','Keep walking','Your heading and hand offset survive the boundary. The counter records the crossings.'),
              ('room-above','One tile, repeated views','The physical tile is surrounded by eight batched visual neighbours. The visible patch stays finite as walking continues.')]
    for name,_,_ in pictures:shutil.copy2(RUN/'repeating-mobile'/f'{name}.png',OUT/f'{name}.png')
    paths=list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*.gd'))+[ROOT/'tools/probes/repeating_gallery.gd',Path(__file__)]
    (OUT/'manifest.json').write_text(json.dumps({'runs':{k:len(v['checks']) for k,v in reports.items()},'scope':'Native desktop walker/hand checks. Physical headset acceptance open.','sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf-8')
    cards=''.join(f'<section><h2>{title}</h2><p>{caption}</p><img src="{name}.png" alt="{title}" loading="lazy"></section>' for name,title,caption in pictures)
    counts=' · '.join(f'{k}: {len(v["checks"])}/{len(v["checks"])}' for k,v in reports.items())
    page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Repeating gallery · the same point</title>
<style>body{{background:#171d26;color:#e9e2d5;font:18px/1.6 system-ui;margin:auto;padding:40px;max-width:1280px}}h1{{font-size:clamp(38px,6vw,75px);line-height:1.1}}a{{color:#85d1dc}}img{{width:100%;border-radius:8px}}section{{margin:55px 0}}p{{max-width:900px}}.receipt{{background:#23352e;padding:20px}}small{{color:#70cddd}}</style>
<small>ENDLESS MUSEUM · 12 OCTOBER 2026 · INSTALLED</small><h1>Keep walking.<br>The gallery returns.</h1><p>Cross the gold edge and continue in the same direction. The architectural pattern returns around you. Carry the point, leave it, walk a lap and find the same object again.</p><p><strong>Find it:</strong> reload NonEuclidean_Spaces, enter Seven Spaces and then the Rose gallery. Its rear-left cyan doorway says REPEATING GALLERY / MANIFOLD. Inside, use the four tall cyan thresholds for laps. The smaller doorway off the central path returns to Rose.</p><p class="receipt">{counts}</p>{cards}
<section><h2>What repeats?</h2><p>A 7.68-metre flat tile wraps in X and Z. One physical tile supports the walker; eight batched visual copies extend its surroundings. Crossing an edge translates the player and held point by one period while retaining their direction and relative offset. A point left behind stays in the physical tile. Its neighbouring visual echoes have no independent physics or behaviour.</p><p>The visible architecture is a fixed three-by-three neighbourhood. Walking can continue through repeated laps without growing the node count. Gravity remains upright. This encounter studies periodic connections; the later hyperbolic exhibits use different metrics.</p><p><a href="https://manifold.garden/presskit/">Manifold Garden’s official description</a> connects repeated architecture with gravity changes and return through falling. Our encounter develops its repetition as one clear spatial action. Gravity inversion is a separate future encounter.</p><h2>Verification</h2><p>The native museum collision body crossed all four boundaries. Checks retained the same point, hand offset, heading and floor support; a dropped point survived a complete lap. The walker returned through the same doorway to Rose. Both desktop renderers pass, and the previous overlapping galleries and perspective corridor pass regression. Physical headset stereo, comfort and Quest performance remain open.</p><p><a href="manifest.json">Evidence manifest</a> · <a href="../2026-10-12-perspective-the-sphere-keeps-its-size/index.html">Perspective corridor</a> · <a href="../2026-10-11-around-the-corner/index.html">Around the Corner</a></p></section></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    print(OUT/'index.html')

if __name__=='__main__':main()
