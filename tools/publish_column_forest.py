"""Publish completed native column-forest probes and museum captures."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
RUN=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces'
OUT=ROOT/'doc/book/iterations/2026-10-12-column-forest-a-profile-branches'

def main():
    reports={}
    for tag in ['forest-mobile','forest-gl','wing-forest-regression','repeating-forest-regression']:
        report=json.loads((RUN/tag/'report.json').read_text(encoding='utf-8'))
        log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
        end='probe reached every final assertion' if tag.startswith('wing-') else 'corner probe completed'
        assert report['passed'] and any(c['name']==end and c['passed'] for c in report['checks']),tag
        assert not any(e.lower() in log.lower() for e in ['SCRIPT ERROR:','SHADER ERROR:','shader compilation failed']),tag
        reports[tag]=report
    OUT.mkdir(parents=True,exist_ok=True)
    for tag in reports:
        target=OUT/'evidence'/tag;target.mkdir(parents=True,exist_ok=True)
        for name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(RUN/tag/name,target/name)
    pictures=[('inside','Walk into a forest of columns','Eight twisting shafts branch towards a vaulted lattice, with a clear nave through the centre.'),
              ('study','The rule within reach','Carry the same point sideways to open or close the four branches of the small front study.'),
              ('branches','Look up at the connections','Forks join the sampled vault ribs. The point trigger highlights the front study’s branch geometry.'),
              ('room-above','The room from above','Two rows of columns frame the nave. The hand study sits to the side of the approach.')]
    for name,_,_ in pictures:shutil.copy2(RUN/'forest-mobile'/f'{name}.png',OUT/f'{name}.png')
    paths=list((ROOT/'commons/artifacts/noneuclidean_wing').glob('*.gd'))+[ROOT/'tools/probes/column_forest.gd',Path(__file__)]
    (OUT/'manifest.json').write_text(json.dumps({'runs':{k:len(v['checks']) for k,v in reports.items()},'scope':'Native desktop museum walker/point/action checks. Physical headset acceptance open.','sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf-8')
    cards=''.join(f'<section><h2>{title}</h2><p>{caption}</p><img src="{name}.png" alt="{title}" loading="lazy"></section>' for name,title,caption in pictures)
    counts=' · '.join(f'{k}: {len(v["checks"])}/{len(v["checks"])}' for k,v in reports.items())
    page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Column forest · a profile branches</title>
<style>body{{background:#171d26;color:#e9e2d5;font:18px/1.6 system-ui;margin:auto;padding:40px;max-width:1280px}}h1{{font-size:clamp(38px,6vw,75px);line-height:1.1}}a{{color:#85d1dc}}img{{width:100%;border-radius:8px}}section{{margin:55px 0}}p{{max-width:900px}}.receipt{{background:#23352e;padding:20px}}small{{color:#f2be64}}</style>
<small>ENDLESS MUSEUM · 12 OCTOBER 2026 · INSTALLED</small><h1>A profile rises.<br>A column branches.</h1><p>The same geometric operations become a room around you. A six-sided profile twists as it rises; its shaft branches towards the canopy. Carry the original point to change the small study near the entrance.</p><p><strong>Find it:</strong> reload NonEuclidean_Spaces, enter Seven Spaces and then Blue. Its rear-left gold doorway says COLUMN FOREST / GAUDI. Inside, hold the point and move it sideways. Desktop: carry the point and turn your view sideways. Its trigger highlights the study’s construction. Return through the doorway to Blue.</p><p class="receipt">{counts}</p>{cards}
<section><h2>What the encounter teaches</h2><p>Profile → rotation along height → branching → canopy. The room returns to our primitives, transformations and branching rules. The small study changes branch opening from 18 to 55 degrees using the held point’s displacement across the room. Its mesh instances persist; the hand changes their transforms. The point’s live identity remains unchanged.</p><p>The <a href="https://sagradafamilia.org/documents/20142/1000561/Booklet_04.pdf/5eb8514a-7bd2-77d0-15dc-9c9c0315cf23">Sagrada Família’s official architecture booklet</a> connects Gaudí’s geometric constructions, branching columns, structural decisions and symbolism. This museum forest is an interpretation of that relationship. Its single twisted polygonal shafts do not reconstruct Gaudí’s double-twist columns. Its canopy is a sampled geometric lattice, without a structural load solver.</p><p>Walk under the branches, then return to the small rule you can change. What makes a column feel like a tree—and what makes that resemblance become architectural authority?</p><h2>Verification</h2><p>The native museum walker enters and returns, walks the clear nave, and carries the same PointBody. Its actual action signal toggles the guides. Tests check branch movement, object identity, bounded node count and dynamic doorway previews. Both desktop renderers pass; the original seven spaces and repeating gallery pass regression. Physical headset stereo, comfort and Quest performance remain open.</p><p><a href="manifest.json">Evidence</a> · <a href="../2026-10-12-repeating-gallery-the-same-point/index.html">Repeating gallery</a> · <a href="../2026-10-12-perspective-the-sphere-keeps-its-size/index.html">Perspective corridor</a></p></section></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8');print(OUT/'index.html')

if __name__=='__main__':main()
