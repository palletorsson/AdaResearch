"""Pair saved museum photographs with proposed teaching comparisons."""
from pathlib import Path
from html import escape as e
import hashlib
import json
import os
import re
import shutil
from urllib.parse import urljoin

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ROUTE_DIR=HERE.parent/'2026-10-04-museum-tutorial-storyboards'
PLAN_DIR=HERE.parent/'2026-10-04-foundations-before-randomness'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p): return Path(os.path.relpath(p,HERE)).as_posix()

def main():
    plan=read(PLAN_DIR/'plan.json'); route=read(ROUTE_DIR/'route.json')
    halls={h['id']:h for h in route['halls']}
    suggestions={}
    for name in ['primitives-visual-plan.json','motion-array-visual-plan.json','colour-visual-plan.json']:
        data=read(HERE/name)
        items=data if isinstance(data,list) else data.get('maps',data.get('halls',[]))
        for h in items: suggestions[h.get('map',h.get('id'))]=h
    requested=[h['map'] for s in plan['sequences'] for h in s['halls']]
    assert set(requested)==set(suggestions), (set(requested)-set(suggestions),set(suggestions)-set(requested))

    copied_sources={}
    def image_info(hid):
        item=suggestions[hid]
        pictures=item.get('pictures',[])
        if pictures:
            p=ROOT/pictures[0]['path'];caption=pictures[0]['caption']
        elif item.get('image'):
            image_path=item['image']
            p=(ROOT/image_path if image_path.startswith(('doc/','ada_run/')) else HERE/image_path).resolve()
            caption=item.get('image_caption',item.get('image_kind','Saved museum capture')+' · '+item.get('image_reason',''))
        else:
            p=(ROUTE_DIR/halls[hid]['images'][-1]['src']).resolve();caption='Saved museum capture · '+halls[hid]['images'][-1].get('date','')
        assert p.is_file(),p
        if not p.relative_to(ROOT).as_posix().startswith(('doc/book/iterations/','doc/book/figures/')):
            destination=HERE/'captures'/f'{hid}{p.suffix}'
            destination.parent.mkdir(exist_ok=True)
            shutil.copyfile(p,destination)
            copied_sources[destination.relative_to(ROOT).as_posix()]=p.relative_to(ROOT).as_posix()
            p=destination
        return rel(p),caption

    svg=lambda id,label:f'<svg id="{id}" viewBox="0 0 500 290" role="img" aria-label="{e(label)}"></svg>'
    controls={
      'point':svg('point-svg','A point moves up a labelled local Y axis')+'<label>Local height <output id="height-value"></output><input id="height" type="range" min="0" max="3" step="0.1" value="1.2"></label><label class="checkbox"><input id="wrong-frame" type="checkbox"> Show a coordinate-frame mistake</label><p class="status" id="point-status" role="status"></p>',
      'trace':svg('trace-svg','Candidate positions, accepted list entries and joined segments')+'<div class="buttons"><button id="next-sample">Read next candidate</button><button id="join-next">Join next pair</button><button id="trace-reset">Reset trace</button></div><p class="status" id="trace-status" role="status"></p>',
      'state':svg('state-svg','A timed cube and two different responses to proximity')+'<div class="buttons"><button id="frame-step">Advance frame (+0.5 s)</button><button id="proximity-toggle">Approach</button><button id="state-reset">Restart study</button></div><p class="status" id="state-status" role="status"></p>',
      'function':svg('function-svg','Two generated columns, one fixed and one with editable inputs')+'<div class="inputs"><label>Radial count <select id="sides"><option>4</option><option>6</option><option selected>8</option><option>12</option><option>16</option></select></label><label>Height <output id="column-height-value"></output><input id="column-height" type="range" min="1" max="3" step="0.1" value="2"></label></div><p class="status" id="function-status" role="status"></p>',
      'array':'<div id="grid-cells" class="grid-cells" aria-label="Four by four occupancy record"></div><div class="buttons"><button id="grid-write">Toggle selected value</button><button id="grid-rule">Apply checker rule</button><button id="grid-reset">Reset array</button></div><p class="status" id="grid-status" role="status"></p>',
      'class':svg('palette-svg','Independent palette state or two references to shared palette state')+'<div class="buttons"><button id="palette-a">Advance A</button><button id="palette-b">Advance B</button><button id="palette-reset">Reset palettes</button></div><label class="checkbox"><input id="shared-palette" type="checkbox"> Compare two references to one instance (resets)</label><p class="status" id="palette-status" role="status"></p>'
    }
    demos=[
      dict(id='point',map='Point_Coordinates',title='A value places a body.',idea='Variables · values · coordinates · diagnosis',gesture='In the hall: move the held point along one named direction. In the sketch: change Y while radius, X and Z stay fixed.',learn='See the difference between the value, its reference frame and the object receiving it.',limit='The sketch supplies the visible sphere. The sphere is a representation of a point; a position value alone does not draw anything.'),
      dict(id='trace',map='Point_Trace',title='A movement becomes a record.',idea='Conditions · arrays · loops',gesture='Stop the pen; move it a little; move it farther. Then read and join the retained neighbours one pair at a time.',learn='The condition decides whether to keep a position. The list retains it. A later loop draws relations between entries.',limit='This reduced candidate sequence is an explanatory model. The museum pen also shapes samples; the diagram is not a replay of a captured stroke.'),
      dict(id='state',map='Trans_Body',title='A response can remember.',idea='Execution · events · retained state',gesture='Approach, then leave. Compare a response that follows current distance with a change that remains. Step the clock separately.',learn='Repeated execution, current input and stored history produce different outcomes.',limit='Two schematic gates make the comparison legible; the museum has distinct responsive and retained-change works. One image does not prove the update logic.'),
      dict(id='function',map='Primitives_Columns',title='One rule makes a family.',idea='Functions · inputs · returned data',gesture='Keep one column fixed. Change only the other column’s height or radial count. Walk around the museum forms to compare their facets.',learn='The same operation can return different position lists when its inputs change. The unchanged reference makes that change inspectable.',limit='This diagram uses a straight two-ring profile and a supplied surface builder. The museum columns have richer profiles; their different shapes are not caused by resolution alone.'),
      dict(id='array',map='Array',title='An address survives an absence.',idea='Indexed reads · writes · traversal',gesture='Select a slot, change its occupancy, look elsewhere, then return. Run a rule over the whole array and compare its reach.',learn='Selection reads an address; assignment changes a value. An empty slot retains its index.',limit='The diagram is a small displayed occupancy record. It does not claim that the museum floor stores colours or occupancy in exactly this form.'),
      dict(id='class',map='Color_Grid_Pallet',title='The same methods, separate lives.',idea='Classes · objects · references',gesture='Advance palette A while B keeps its index. Then compare two references to one Palette and explicitly refresh both receivers.',learn='Independent instances share a definition, not their changing state. Two references can instead lead to the same object.',limit='Palette is a proposed learner class. The museum already has colour records and receivers; this class and its student binding are not installed. Both browser previews explicitly read after every action.')
    ]
    # Choose an actual view of the expanded column hall, rather than an older crowded room.
    explicit={'function':('../2026-10-04-primitives-expanded/Primitives_Columns/inside.png','Native Endless Museum capture · 4 October 2026'),'point':('../2026-10-04-museum-tutorial-storyboards/images/Point_Coordinates-1.webp','Saved museum capture · 3 October 2026')}
    sections=[]; all_pictures=[]
    for i,d in enumerate(demos,1):
        src,caption=explicit.get(d['id'],image_info(d['map']))
        assert (HERE/src).resolve().is_file()
        all_pictures.append((HERE/src).resolve())
        sections.append(f'''<section class="study" id="{d['id']}"><header><span class="number">0{i} / {e(d['idea'])}</span><h2>{e(d['title'])}</h2></header><div class="pair"><figure><a href="{e(src,quote=True)}"><img src="{e(src,quote=True)}" alt="{e(caption+' — '+d['map'],quote=True)}" loading="{'eager' if i==1 else 'lazy'}"></a><figcaption><b>Museum image</b> {e(caption)}</figcaption></figure><div class="sketch"><p class="sketch-label">Interactive teaching sketch · proposed comparison</p>{controls[d['id']]}</div></div><div class="reading"><p><b>Do / compare</b> {e(d['gesture'])}</p><p><b>What becomes legible</b> {e(d['learn'])}</p><details><summary>What this representation leaves out</summary><p>{e(d['limit'])}</p></details></div></section>''')

    sequence_sections=[]
    normalized=[]
    for seq in plan['sequences']:
        cards=[]
        for h in seq['halls']:
            hid=h['map'];v=suggestions[hid];src,caption=image_info(hid);all_pictures.append((HERE/src).resolve())
            action=v.get('action',v.get('student_action',h['check']));consequence=v.get('consequence',v.get('visible_consequence',h['practice']))
            contrast=v.get('contrast',v.get('useful_contrast','Predict the change, make it, then compare the result.'))
            proposal=v.get('proposed_highlight',v.get('diagram_proposal',v.get('proposal','')))
            limit=v.get('pitfall',v.get('picture_limit',v.get('image_cannot_prove','A saved photograph does not by itself verify the algorithm or learner control.')))
            concept=v.get('concept',' · '.join(v.get('concepts',[])) or h['introduce'])
            normalized.append(dict(map=hid,sequence=seq['id'],concept=concept,image=src,caption=caption,action=action,consequence=consequence,contrast=contrast,proposal=proposal,limit=limit))
            cards.append(f'''<article class="hall-card" id="hall-{hid}"><figure><a href="{e(src,quote=True)}"><img src="{e(src,quote=True)}" alt="{e(caption,quote=True)}" loading="lazy"></a><figcaption>{e(caption)}</figcaption></figure><div class="hall-body"><p class="number">{e(hid)}</p><h3>{e(concept)}</h3><p><b>Action</b> {e(action)}</p><p><b>Visible consequence</b> {e(consequence)}</p><p><b>Compare</b> {e(contrast)}</p><details><summary>Proposed aid and evidence limit</summary><p>{e(proposal)}</p><p>{e(limit)}</p></details></div></article>''')
        sequence_sections.append(f'<details class="atlas-sequence" id="atlas-{seq["id"]}"><summary>{e(seq["title"])} <span>{len(cards)} halls</span></summary><div class="hall-grid">{"".join(cards)}</div></details>')
    coverage=[('Execution and calls','state'),('Variables, assignment and basic types','point'),('Arithmetic, expressions and returned values','point'),('Comparisons and conditions','trace'),('Lists and indexed data','array'),('Loops and accumulation','trace'),('Functions: parameters, locals and return','function'),('Scope and retained state','state'),('Objects, properties and references','class'),('An authored class with state and methods','class'),('Events and input','state'),('Observation and debugging','point')]
    assert {c[0] for c in coverage}=={c['subject'] for c in plan['coverage']}
    coverage_html=''.join(f'<a href="#{target}">{e(label)}</a>' for label,target in coverage)
    css='''
:root{--paper:#f4f2ec;--ink:#23372f;--muted:#657269;--line:#d3d9cf;--rose:#a44973;--card:#fffdf8}*{box-sizing:border-box}html{scroll-padding-top:22px}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.65 system-ui,sans-serif}main,nav,footer{max-width:1440px;margin:auto;padding:0 34px}nav{display:flex;gap:24px;flex-wrap:wrap;padding-top:17px;padding-bottom:17px;border-bottom:1px solid var(--line);font-size:12px}a{color:inherit;text-underline-offset:3px}button,input,select{font:inherit}button,select{background:#fffefa;border:1px solid #9aa89c;border-radius:3px;padding:8px 12px;color:var(--ink)}button{cursor:pointer}button:hover{background:#e6ece3}button:disabled{opacity:.42;cursor:default}a:focus-visible,button:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid var(--rose);outline-offset:3px}.hero{max-width:930px;padding:40px 0 28px}h1,h2,h3{font:400 56px/1.12 Georgia,serif;letter-spacing:-.025em;margin:12px 0 20px}h2{font-size:35px}h3{font-size:24px}p{margin:10px 0}.lead{font-size:20px}.number,.sketch-label{font-size:10px;letter-spacing:.09em;text-transform:uppercase;font-weight:700;color:var(--muted)}.coverage{display:flex;gap:8px;flex-wrap:wrap;margin:0 0 28px}.coverage a{font-size:11px;padding:4px 9px;border:1px solid var(--line);text-decoration:none}.study{padding:28px 0 34px;border-top:1px solid var(--line)}.pair{display:grid;grid-template-columns:1.1fr 1fr;gap:20px;align-items:start}.pair figure{background:#e3e5e0}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{padding:10px 13px;font-size:11px;line-height:1.45;color:var(--muted);background:#ebece6}figcaption b{font-size:9px;text-transform:uppercase;margin-right:7px}.sketch{background:var(--card);border:1px solid var(--line);padding:12px 20px 15px;min-width:0}.sketch-label{margin:0 0 5px;color:var(--rose)}svg{width:100%;height:auto;display:block}svg text{font:12px system-ui,sans-serif;fill:#384b43}.buttons{display:flex;gap:7px;flex-wrap:wrap;font-size:12px}.inputs{display:flex;gap:22px;align-items:center;flex-wrap:wrap}label{font-size:12px;display:block}input[type=range]{width:100%;display:block;margin:10px 0;accent-color:var(--rose)}input[type=checkbox]{accent-color:var(--rose)}output{float:right;margin-left:15px}.checkbox{display:flex;align-items:center;gap:7px;margin:10px 0}.status{font:12px/1.6 system-ui;background:#eef0e9;padding:10px 12px;min-height:58px}.reading{display:grid;grid-template-columns:1fr 1fr;gap:0 28px;margin-top:12px;font-size:14px}.reading b{display:block;font-size:10px;text-transform:uppercase;letter-spacing:.06em;color:var(--rose)}.reading details{grid-column:1/-1;font-size:12px;color:var(--muted)}summary{cursor:pointer}.grid-cells{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;max-width:312px;margin:16px auto}.cell{aspect-ratio:1;color:#334039;border:1px dashed #aeb8af;background:#f4f3ed;border-radius:0;font-size:11px}.cell.occupied{background:#35453e;border:1px solid #35453e;color:white}.cell.selected{outline:3px solid #ca628f;outline-offset:2px}.cell:hover{box-shadow:inset 0 0 0 3px #ca628f}.atlas{margin:40px 0}.atlas-sequence{margin-top:14px;border:1px solid var(--line);background:var(--card)}.atlas-sequence>summary{padding:18px 20px;font-size:18px}.atlas-sequence>summary span{float:right;font-size:12px;color:var(--muted)}.hall-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;padding:20px}.hall-card{border:1px solid var(--line);min-width:0}.hall-card img{height:240px;object-fit:contain;background:#e8e8e0}.hall-body{padding:18px}.hall-body p{font-size:12px}.hall-body b{color:var(--rose)}.hall-body h3{font-size:22px}.hall-body details{font-size:11px;color:var(--muted)}.closing{max-width:940px;padding:0 0 28px}.closing p{font-size:14px}footer{padding-top:20px;padding-bottom:28px;border-top:1px solid var(--line);font-size:11px;color:var(--muted)}.skip{position:absolute;top:-80px;background:white;padding:10px}.skip:focus{top:0}@media(max-width:1000px){.pair{grid-template-columns:1fr 1fr}.hall-grid{grid-template-columns:repeat(2,1fr)}h1{font-size:47px}}@media(max-width:730px){main,nav,footer{padding-left:18px;padding-right:18px}.pair,.reading,.hall-grid{grid-template-columns:1fr}h1{font-size:39px}h2{font-size:30px}.hero{padding-top:25px}.lead{font-size:17px}.hall-card img{height:auto}.sketch{padding:12px}.reading{gap:0}.hall-grid{padding:12px}}@media print{nav,button,input,select,.coverage{display:none}main,footer{padding:0}.hero{padding-top:0}h1{font-size:32pt}.study{break-inside:avoid}.pair{grid-template-columns:1fr 1fr}h2{font-size:22pt}.status{min-height:0}.hall-card{break-inside:avoid}}
'''
    html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Make the concept visible · Ada</title><style>{css}</style></head><body><a class="skip" href="#point">Skip to visual comparisons</a><nav><a href="/research-outline">Research outline</a><a href="/tutorial-cards">Tutorial hall cards</a><a href="../2026-10-04-foundations-before-randomness/index.html">Foundation plan</a><a href="#atlas">All 35 halls</a></nav><main><header class="hero"><p class="number">Ada / Visual teaching studies · 4 October 2026</p><h1>Let the change become visible.</h1><p class="lead">Six interactive comparisons and a picture plan for every hall in the first four sequences.</p><p>The photographs come from the Endless Museum. The diagrams let you try proposed teaching comparisons here in the browser. Their controls have not been installed in the museum.</p><p>Move → predict → compare → inspect the value → use it again. Keep the body and its consequence in the foreground; bring in the code when it explains what changed.</p></header><div class="coverage" aria-label="Find a programming concept">{coverage_html}</div>{''.join(sections)}<section class="atlas" id="atlas"><p class="number">Primitives → Transformation → Arrays → Colour</p><h2>A visible consequence in every hall</h2><p>Open a sequence. Each card pairs a saved museum image with a student action, a visible contrast and any proposed explanatory aid. Captures show an earlier recorded arrangement; they do not by themselves verify current behavior or learning.</p>{''.join(sequence_sections)}</section><section class="closing"><h2>Let the room keep its life.</h2><p>Not every idea needs a new exhibit or a permanent label. Use the existing object, a controlled contrast and an optional step-through view. A temporary highlight can reveal a loop or reference, then disappear so the student can compose with the result.</p><p>Pictures make relations inspectable; understanding still needs the student to predict an unfamiliar case and explain what happened. Scope, execution and reference ownership require the small code connection as well as the visible consequence.</p></section></main><footer>Saved museum captures + explicitly proposed browser sketches. Museum code, maps and full tutorials unchanged. <a href="visual-plan.json">All hall selections</a> · <a href="manifest.json">Image sources</a></footer><script src="demos.js"></script></body></html>'''
    # The book-review endpoint deliberately disallows scripts. Keep that viewer
    # read-only and publish this bounded, authored study as a normal static page.
    public=ROOT.parent/'ada_encyclopedia/public/research/foundation-visuals'
    public.mkdir(parents=True,exist_ok=True)
    base='/book-review/doc/book/iterations/2026-10-04-foundations-visible/'
    live=html.replace('<script src="demos.js"></script>','<script>'+ (HERE/'demos.js').read_text(encoding='utf-8')+'</script>')
    def absolute_link(match):
        kind,url=match.groups()
        return f'{kind}="{url if url.startswith(("/","#","https:")) else urljoin(base,url)}"'
    live=re.sub(r'(href|src)="([^"]+)"',absolute_link,live)
    (public/'index.html').write_text(live,encoding='utf-8')
    notice='<aside class="status"><a href="/research/foundation-visuals/index.html">Open the working interactive version</a>. This review viewer displays the saved photographs; its security policy disables scripts.</aside>'
    html=html.replace('<main>','<main>'+notice,1).replace('<script src="demos.js"></script>','')
    (HERE/'index.html').write_text(html,encoding='utf-8')
    (HERE/'visual-plan.json').write_text(json.dumps({'status':'proposed visual teaching plan','halls':normalized,'coverage':[{'concept':a,'demo':b} for a,b in coverage]},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    manifest={'scope':'six interactive browser sketches and 35 saved-capture hall cards','runtime_change':False,'learner_test':False,'copied_sources':copied_sources,'captures':[{'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(set(all_pictures))]}
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(f'Rendered 6 sketches, {len(normalized)} hall cards, 12 concept links and {len(set(all_pictures))} existing images.')

if __name__=='__main__':main()
