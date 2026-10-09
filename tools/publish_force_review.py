"""Assemble the local review gallery from source inventory and actual runtime evidence."""
from pathlib import Path
import json, shutil, hashlib, html
from build_force_trials import ROOT, OUT, PUBLIC, TRIALS

def main():
    data=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
    trials=json.loads((OUT/'trials.json').read_text(encoding='utf-8'))
    by_kind={x['kind']:x for x in trials}
    run=ROOT/'ada_run/encounter_pilot/Force_Review_01_Mass'
    evidence=run if (run/'report.json').exists() else OUT
    report=json.loads((evidence/('report.json' if evidence==run else 'runtime-checks.json')).read_text(encoding='utf-8'))
    assert report['passed'], 'Do not publish passing evidence for a failed run'
    engine=evidence/('stdout.log' if evidence==run else 'engine.log')
    assert 'SCRIPT ERROR' not in engine.read_text(encoding='utf-8',errors='replace')
    for item in data:
        current_maps=[]
        candidates=set([item['token']]+item.get('aliases',[]))
        sequence=json.loads((ROOT/'commons/maps/sequences/forces.json').read_text(encoding='utf8'))['sequences']['forces']['maps']
        for m in sequence:
            layout=json.loads((ROOT/f'commons/maps/{m}/map_data.json').read_text(encoding='utf-8-sig'))
            tokens={str(v).split('#')[0].split(':')[0] for row in layout['layers']['interactables'] for v in row if v}
            if tokens & candidates:current_maps.append(m)
        item.setdefault('previous_halls',item.get('halls',[]))
        item['halls']=current_maps
        scene_text=(ROOT/item['scene'].removeprefix('res://')).read_text(encoding='utf-8')
        item['stub']=scene_text.count('[node ')==1 and '[ext_resource' not in scene_text and '[sub_resource' not in scene_text
        if item['stub']:
            item['preview']=None
            item['preview_note']='EMPTY SCENE: the registry describes an idea, but this scene has no script or geometry. Not a working artifact.'
            item['description']='Registry proposal (not implemented): '+item['description'].removeprefix('Registry proposal (not implemented): ')
        if item['new']:
            kind=item['token'].removeprefix('force_trial_');t=by_kind[kind]
            for state in ['before','after']:
                dest=OUT/'images'/f'{kind}-{state}.png';shutil.copy2(run/dest.name,dest)
                item[state]='images/'+dest.name
            item['preview']=item['before'];item['preview_note']='New Godot 4.6 capture inside the museum review bay. These same scenes populate the ten-room route.'
            item.update(learn=t['learn'],action=t['action'],idea=t['idea'],map=t['map'])
        elif not item['preview'] and not item['stub']:
            source=PUBLIC/'artifact-gallery/captures'/item['token']/'front.png'
            if item['token']=='force_capability_lab':source=ROOT/'doc/book/iterations/2026-10-07-forces-capability-court/images/court-entry.png'
            if source.exists():
                dest=OUT/'images'/(item['token']+'.png');shutil.copy2(source,dest)
                item['preview']='images/'+dest.name;item['preview_note']='Existing museum court capture.' if item['token']=='force_capability_lab' else 'Godot artifact catalog capture from this pass. Appearance only; interaction not retested.'
        text=(item['token']+' '+item['title']+' '+' '.join(item.get('tags',[]))).lower()
        item['topic']=next((label for words,label in [(['spring','pendul','harmonic','oscill'],'Springs & oscillation'),(['gravity','orbit','attract','threebod','vortex'],'Fields & attraction'),(['catapult','launch','mortar','throw','ball_drop','bowling'],'Launch & impulse'),(['drag','friction','roll','wedge','slide','wind'],'Contact & resistance'),(['leg','critter','dog','turret','arena','foe','head_crab','mushroom'],'Creatures & targeting'),(['vector','dot','cross','projection','coordinate','adder','magnitude','normaliz'],'Vector operations'),(['hinge','support','lever','torque','mobile','joint'],'Joints & support')] if any(w in text for w in words)),'Motion & consequences')
    report['scope']='Ten production scenes in the real museum; supplied control events, engine physics and reset assertions. Every trial photographed in the same review bay for comparison. Headset ergonomics, Quest performance and all older artifact interactions remain untested in this pass.'
    (OUT/'runtime-checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    if engine!=OUT/'engine.log':shutil.copy2(engine,OUT/'engine.log')
    paths=list((ROOT/'commons/artifacts/force_trials').glob('*.gd'))+list((ROOT/'commons/artifacts/force_trials').glob('*.tscn'))+list((ROOT/'commons/artifacts/force_trials').glob('*.json'))+list((ROOT/'commons/maps').glob('Force_Review_*/map_data.json'))
    paths += [ROOT/p for p in ['tools/probes/force_trials.gd','tools/probes/force_trial_route.gd','commons/scenes/force_trials_museum.gd','commons/scenes/force_trials_museum.tscn','commons/artifacts/registry/force_trials.json','commons/maps/sequences/forces_review.json','commons/data/map_authored.json']]
    sources={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    (OUT/'source-hashes.json').write_text(json.dumps(sources,indent=2),encoding='utf-8')
    data.sort(key=lambda x:(not x['new'],x.get('map','') if x['new'] else ('0' if x['halls'] else '1')+x['title'].lower()))
    (OUT/'catalog.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    template=(Path(__file__).parent/'force_review.html').read_text(encoding='utf-8')
    static=[]
    for a in data:
        esc=html.escape
        photo=f'<img loading="lazy" src="{esc(a["preview"])}" alt="{esc(a["title"])}">' if a['preview'] else '<span>EMPTY SCENE — needs building</span>'
        static.append(f'<article class="card"><a class="photo" href="http://localhost:3003/research/forces-review/index.html#{esc(a["token"])}">{photo}</a><div class="body"><span class="pill">{esc(a["topic"])}</span><h2>{esc(a["title"])}</h2><p>{esc(a["description"][:300])}</p><p class="meta">{esc(a["preview_note"])}</p></div></article>')
    result=template.replace('__STATIC_CARDS__',''.join(static)).replace('__OLD_COUNT__',str(sum(not x['new'] for x in data))).replace('__CATALOG__',json.dumps(data,ensure_ascii=False).replace('</','<\\/')).replace('__CHECKS__',str(len(report['checks'])))
    (OUT/'index.html').write_text(result,encoding='utf-8')
    # Book-review deliberately disallows scripts. The interactive app lives in
    # the encyclopedia's public research area; shared images stay in the report.
    public_ui=PUBLIC/'research/forces-review'
    public_ui.mkdir(parents=True,exist_ok=True)
    base='/book-review/doc/book/iterations/2026-10-07-forces-ten-more/'
    (public_ui/'index.html').write_text(result.replace('<meta charset="utf-8">','<meta charset="utf-8"><base href="'+base+'">').replace('href="#visit"','href="/research/forces-review/index.html#visit"'),encoding='utf-8')
    print(json.dumps({'new':sum(x['new'] for x in data),'existing':sum(not x['new'] for x in data),'images':sum(bool(x['preview']) for x in data),'checks':len(report['checks'])}))

if __name__=='__main__':main()
