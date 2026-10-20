"""Publish actual Godot hall images; refresh only the installed hall's snapshots."""
from pathlib import Path
import json, hashlib, shutil, re
from html import escape
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-two-rooms-one-body'
RUN=R/'ada_run/encounter_pilot/Shader_05_Patterns/fuzzy-body'
KEY='shaders|shader 05 patterns'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def backup(p):
    q=O/'before'/p.relative_to(R)
    if not q.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
def main():
    receipt=read(RUN/'report.json');assert receipt['passed'],receipt['failures']
    log=(RUN/'engine.log').read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    for name in ['museum','validation','source']:(O/name).mkdir(parents=True,exist_ok=True)
    for p in RUN.glob('fuzzy-*.png'):shutil.copy2(p,O/'museum'/p.name)
    for name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,O/'validation'/name)
    for p in (R/'commons/artifacts/fuzzy_body').iterdir():
        if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'source'/p.name)
    sources=[*list((R/'commons/artifacts/fuzzy_body').glob('*.gd')),*list((R/'commons/artifacts/fuzzy_body').glob('*.tscn')),R/'commons/artifacts/registry/fuzzy_body.json',R/'commons/maps/Shader_05_Patterns/map_data.json',R/'tools/probes/fuzzy_body_museum.gd']
    write(O/'validation/source-hashes.json',{p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
    md=read(R/'commons/maps/Shader_05_Patterns/map_data.json')
    plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x.get('map')=='Shader_05_Patterns' and x.get('sequence')=='shaders')
    assert any(x['token'].split(':')[0]=='fuzzy_body' for x in plan['artifacts'])
    write(O/'validation/placement.json',{'map':'Shader_05_Patterns','sequence':'shaders','cell':[8,40],'rotation':180,'artifacts':plan['artifacts'],'source':'Actual map and museum plan; live instance verified by probe.'})
    row=read(RUN/'em_layout_walk.json')['halls'][KEY]
    for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
        p=R/rel
        if p.exists():backup(p);d=read(p);d['halls'][KEY]=row;write(p,d)
    p=R/'commons/data/long_museum.json';backup(p);d=read(p)
    segment=next(s for s in d['segments'] if s.get('name')=='Shader_05_Patterns')
    before_count=len(segment['artifacts'])
    segment['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0)} for a in plan['artifacts']]
    delta=len(segment['artifacts'])-before_count
    d['totals']['artifacts']+=delta
    next(c for c in d['chapters'] if c['sequence']=='shaders')['artifacts']+=delta
    p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    checks=len(receipt['checks']);route=receipt['observations']['fuzzy_route_samples']
    report=f'''# Two rooms claim one body

Installed in **Endless Museum → Shaders → Patterns**, on the left after the image gallery, beside the precision/time/feedback model. These pictures come from that Godot hall.

The existing black point becomes a small hand control for a larger sphere. Move it sideways and different parts of the sphere enter overlapping fields. One lifts, another folds; their shared membership activates a twist. The original sphere remains available.

![Competing rules in the real museum](museum/fuzzy-rules.png)

## Three views, one source

FIELDS reveals graded membership. RULES turns the memberships into a weighted blend of positions. CUT makes a definite selection: keep a triangle when BOTH at its source centroid meets the threshold. Its jagged open edge is visible evidence of sampling, not a smooth closed solid.

![The coloured source](museum/fuzzy-fields.png)
![A threshold selects part of the same sphere](museum/fuzzy-cut.png)

## What your hand changes

Grip the black point and move left or right. On desktop, right-click to carry and again to release; LEFT/CENTRE/RIGHT also place it. WIDTH changes the field transition, STRENGTH changes deformation, THRESHOLD changes the cut. The meters show values at the centre; the surface shows values across the body.

![Native dials and buttons](museum/fuzzy-console.png)

## A decision remains

Softening the boundary does not remove the choice. We chose the fields, the three transformations, how they combine and the threshold that selects a face. The comparison makes those choices available to inspection. This is a visual research encounter; the tutorial and reflective text have not been rewritten.

## Placement and tests

Map cell [8,40], rotation180. Six earlier artifacts retained; entrance and onward portal retained. The shaded frames indicate two influences rather than precise field boundaries. Deforming geometry has no collision; fixed plinth, controls and museum floor retain theirs.

**{checks}/{checks} native Godot checks passed**, including the earlier model installation, explicit membership arithmetic, zero-strength identity, retained source, monotonic threshold selection, empty selection, parameter extremes, pointer buttons, desktop carry, synthetic XRTools grip/dials/release. {route} new supported capsule samples cover access to the controls and both sides, alongside the earlier entrance/exit route checks. Physical headset comfort and Quest performance remain untested. Existing unrelated museum startup/resource warnings remain in the log.

![Arrangement from above](museum/fuzzy-above.png)

[Actual receipt](validation/report.json) · [Engine log](validation/engine.log) · [Source](source/fuzzy_body.gd) · [Usage and exact operations](source/README.md) · [Open the museum scene](source/museum.tscn)
'''
    (O/'REPORT.md').write_text(report,encoding='utf-8')
    import markdown
    options=[('rules','Rules'),('fields','Fields'),('cut','Cut .50'),('cut-high','Cut .68'),('left','Move left'),('right','Move right'),('narrow','Narrow field'),('wide','Wide field')]
    buttons=''.join(f'<button data-shot="{a}" aria-pressed="{str(i==0).lower()}">{b}</button>' for i,(a,b) in enumerate(options))
    viewer='<section class="viewer"><p class="eyebrow">Compare saved native Godot views — same camera and lighting</p><div class="buttons">'+buttons+'</div><img id="comparison" src="museum/fuzzy-rules.png" alt="Rules applied to the same sphere"><p id="view-label">Rules</p></section>'
    body=markdown.markdown(report,extensions=['extra'])
    body=body.replace('<h2>Three views, one source</h2>',viewer+'<h2>Three views, one source</h2>')
    css='*{box-sizing:border-box}body{margin:0;background:#edece4;color:#22343a;font:19px/1.65 Georgia,serif}main,header,footer{max-width:1240px;margin:auto;padding:28px 32px}header,footer,.eyebrow{font:13px/1.5 Arial;letter-spacing:.08em}header{border-bottom:1px solid #a4b3ad}h1{font-size:clamp(34px,6vw,68px);line-height:1.1}h2{font:28px Arial;margin-top:56px}p{max-width:960px}img{width:100%;display:block;margin:24px 0;border-radius:4px}a{color:#8d345e}button{font:15px Arial;cursor:pointer;border:1px solid #a6b2ad;border-radius:4px;background:#f7f5ec;padding:12px 18px;color:#24353a}button[aria-pressed=true]{background:#24353a;color:#f5eee2}.buttons{display:flex;flex-wrap:wrap;gap:8px}.viewer{margin:48px 0;padding:20px;background:#dddcd1}.viewer img{margin-bottom:8px}code{overflow-wrap:anywhere}#view-label{font:15px Arial}'
    js="document.querySelectorAll('[data-shot]').forEach(b=>b.addEventListener('click',()=>{document.querySelectorAll('[data-shot]').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));document.getElementById('comparison').src='museum/fuzzy-'+b.dataset.shot+'.png';document.getElementById('view-label').textContent=b.textContent;}));"
    (O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Two rooms claim one body</title><style>'+css+'</style></head><body><header>ENDLESS MUSEUM / INSTALLED IN GODOT / 9 OCTOBER 2026</header><main>'+body+'</main><footer>always another room</footer><script>'+js+'</script></body></html>',encoding='utf-8')
    for ref in re.findall(r'(?:src|href)="([^"]+)"',(O/'index.html').read_text('utf-8')):
        if not ref.startswith(('http','#')):assert (O/ref).is_file(),ref
    print(json.dumps({'checks':checks,'report':str(O/'index.html'),'route_samples':route}))
if __name__=='__main__':main()
