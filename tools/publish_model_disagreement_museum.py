"""Publish native museum evidence and refresh only this hall's route snapshot."""
from pathlib import Path
import hashlib,json,re,shutil
import markdown
from museum_placement_status import inspect
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-glitch-inside-the-museum'
RUN=R/'ada_run/encounter_pilot/Shader_05_Patterns/model-disagreement'
KEY='shaders|shader 05 patterns'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def backup(p):
    dest=O/'before'/p.relative_to(R)
    if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
def write(p,d,compact=False):p.write_text(json.dumps(d,ensure_ascii=False,**({'separators':(',',':')} if compact else {'indent':2}))+'\n',encoding='utf-8')
def main():
    receipt=read(RUN/'report.json');assert receipt['passed'] and not receipt['failures']
    log=(RUN/'engine.log').read_text(encoding='utf-8',errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log and 'blocked authored entry' not in log
    row=read(RUN/'em_layout_walk.json')['halls'][KEY]
    # Retain other concurrently updated halls. This measured row alone is new.
    for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
        p=R/rel
        if p.exists():backup(p);d=read(p);d['halls'][KEY]=row;write(p,d)
    p=R/'commons/data/long_museum.json';backup(p);d=read(p)
    s=next(s for s in d['segments'] if s.get('name')=='Shader_05_Patterns')
    old_end=s['z1'];delta=row['span']-row['vestibule']-s['h'];old_count=len(s['artifacts'])
    md=read(R/'commons/maps/Shader_05_Patterns/map_data.json')
    plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x.get('map')=='Shader_05_Patterns')
    s.update(w=row['w'],h=row['span']-row['vestibule'],z1=s['z1']+delta,x0=-(row['w']//2),layout='engine',map_h=62,passage=row['passage'],porch=row['porch'],court=row['court'],structure=md['layers']['structure'],tile=plan['tile'],tile_w=row['w'],tile_h=row['h'],raw_w=37,raw_h=62,tile_source='map verified in Godot')
    s['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0)} for a in plan['artifacts']]
    difference=len(s['artifacts'])-old_count
    for other in d['segments']:
        if other is not s and other['z0']>=old_end:other['z0']+=delta;other['z1']+=delta
    for c in d['chapters']:
        if c['sequence']=='shaders':c['z1']+=delta;c['artifacts']+=difference;c['walked_metres']+=delta*d['unit_m']
        elif c['z0']>=old_end:c['z0']+=delta;c['z1']+=delta
    d['totals']['cells_z']+=delta;d['totals']['artifacts']+=difference
    for k in ['metres','built_metres','walked_metres']:d['totals'][k]+=delta*d['unit_m']
    d.setdefault('_local_updates',{})['Shader_05_Patterns']={'date':'2026-10-09','evidence':str(RUN.relative_to(R)/'em_layout_walk.json'),'note':'This hall measured in Godot. Other hall geometry retained; later strip offsets shifted, not recaptured.'}
    write(p,d,True)
    for folder in ['museum','validation','source']:(O/folder).mkdir(parents=True,exist_ok=True)
    for p in RUN.glob('*.png'):shutil.copy2(p,O/'museum'/p.name)
    for name in ['report.json','engine.log','source_manifest.json']:
        shutil.copy2(RUN/name,O/'validation'/name)
    artifact=R/'commons/artifacts/model_disagreement'
    for p in artifact.iterdir():
        if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'source'/p.name)
    placement=inspect('model_disagreement','model_disagreement.json');assert placement['main_route']
    write(O/'validation/placement.json',placement)
    sources=[*artifact.glob('*.gd'),*artifact.glob('*.tscn'),R/'commons/artifacts/registry/model_disagreement.json',R/'commons/maps/Shader_05_Patterns/map_data.json',R/'tools/probes/model_disagreement_museum.gd']
    write(O/'validation/source-hashes.json',{p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
    report=(O/'REPORT.md').read_text(encoding='utf-8').replace('{{CHECKS}}',str(len(receipt['checks']))).replace('{{SAMPLES}}',str(receipt['observations']['route_samples']))
    css='body{margin:0;background:#edece4;color:#28363a;font:19px/1.65 Georgia,serif}main,header,footer{max-width:1200px;margin:auto;padding:30px 36px}header,footer{font:14px Arial;border-bottom:1px solid #aeb9b3}h1{font-size:clamp(36px,6vw,68px);line-height:1.1}h2{font:26px Arial;margin-top:56px}img{width:100%;display:block;margin:24px 0}a{color:#924268}p,li{max-width:900px}code{font:16px Consolas;overflow-wrap:anywhere}table{border-collapse:collapse;width:100%;font:16px/1.5 Arial}td,th{padding:14px;border-bottom:1px solid #b5bbb4;text-align:left}blockquote{margin:0;padding:15px 25px;border-left:4px solid #924268;background:#deded0}'
    (O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Glitch inside the Endless Museum</title><style>'+css+'</style></head><body><header>ENDLESS MUSEUM / INSTALLED IN GODOT / 9 OCTOBER 2026</header><main>'+markdown.markdown(report,extensions=['extra'])+'</main><footer>always another room</footer></body></html>',encoding='utf-8')
    # Mark the earlier research and export viewer as historical/complementary.
    old=R/'doc/book/iterations/2026-10-09-when-parts-stop-agreeing/index.html'
    banner='<aside id="installation-update" style="padding:22px;background:#e2dfca"><strong>NOW INSTALLED IN GODOT:</strong> Endless Museum → Shaders → Patterns. <a href="../2026-10-09-glitch-inside-the-museum/index.html">See the actual hall, controls and tests.</a> The study below records the earlier standalone stage.</aside>'
    t=old.read_text('utf-8')
    if 'id="installation-update"' not in t:old.write_text(t.replace('<main>','<main>'+banner,1),encoding='utf-8')
    template=R/'tools/model_disagreement_viewer.html';t=template.read_text('utf-8')
    t=t.replace('<strong>PREVIEW ONLY</strong><br>Not placed on the museum route.','<strong>INSTALLED IN GODOT</strong><br>Endless Museum → Shaders → Patterns.<br>This page only shows saved model exports.')
    t=t.replace('Read the placement and test scope →','See the actual museum installation →')
    t=t.replace('/book-review/doc/book/iterations/2026-10-09-when-parts-stop-agreeing/index.html','/book-review/doc/book/iterations/2026-10-09-glitch-inside-the-museum/index.html')
    template.write_text(t,encoding='utf-8');shutil.copy2(template,R.parent/'ada_encyclopedia/public/research/model-disagreement/index.html')
    print(json.dumps({'checks':len(receipt['checks']),'placement':placement['status'],'report':str(O/'index.html')}))
if __name__=='__main__':main()
