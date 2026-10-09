from pathlib import Path
import json,hashlib,shutil,urllib.request,zipfile,html,difflib
from build_sources import HERE,ROOT,HALLS,OLD,put
from write_lessons import LESSONS
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):put(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
BASE='http://localhost:3003'
REL=HERE.relative_to(ROOT).as_posix()
def api(route,body=None):
    request=urllib.request.Request(BASE+'/api/'+route,data=None if body is None else json.dumps(body).encode(),headers={'Origin':BASE,'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=90) as response:return json.load(response)

SUMMARIES={
'Point_Triangle_Context':'Bring the original saved Trace positions through Grid. Choose three entries, reuse PointBody as temporary handles, and connect them with one ordered triangular face. Move a corner, reverse the front, and collapse the triangle to see why a guard is needed. The archive stays intact. Carry positions and a face recipe into the first enclosure.',
'Primitives_Polythedra':'Reload the same three selected Trace positions and add an apex behind their plane. Store four positions once and address them with four face-index triples. Move the shared apex and see three faces change together; distinguish a closed visible surface from a collider. Carry the position/connectivity separation and FaceBody into Cube.',
'Point_Animatedcube':'Build CubeBody from eight shared corners and twelve triangles using the previous face renderer. Compare two independent instances with different front-face diagonals. Deform a corner, then move the whole node, distinguishing a construction edit from a placement. Keep the reusable cube for later composition, Transformation and Arrays.',
'Primitives_Ignorance':'Generate an octahedron position list with a named function: positive and negative multiples of three axes. Supply the face recipe and render two independent returned lists at different radii. Call it again, modify only one result and explain the broken symmetry. Carry parameters, typed return values and the distinction between a rule and its output.',
'Primitives_Godot':'Return to PointBody and expose its actual SphereMesh as a member. Extend the class so held time decreases rings and radial segments, release pauses, re-grab continues and reset restores. Compare independent spheres and rings-only versus segments-only variants. Keep radius, visual identity and spherical collision fixed; stop at one ring and four segments. Carry controllable construction into Columns and later abilities.',
'Primitives_Columns':'Use a radius profile and two loops to generate stacked ring positions. Compare the same profile and height at 4, 6, 8, 12 and 16 sides with a supplied circle sampler and surface stitcher. Then change silhouette and height separately. Carry independent construction parameters and the profile/placement distinction into borrowed letter outlines.',
'Primitives_Profiles':'Borrow the existing glyph sweep and its declared font to carry an O through five parallel placements. Separate the supplied outline, including its hole, from width, depth and sideways travel. Reverse the travel and try C while preserving the source. This produces a visible hollow mesh with a sill, not an assumed walk-through collider; keep font triangulation and arbitrary curved-path frames supplied or deferred.',
'Primitives_Portals':'Reuse circle samples and LineSkin to measure a closed polygon. Sum every neighbour edge including the last-to-first edge, compare with the finite TAU-based circumference reference, and increase sides until the stated metre tolerance is met or the sample budget is spent. Test tighter tolerances and an unattainable request. Carry an honest stopping criterion rather than a promise to reach infinity.',
'Primitives_Melencolia':'Compose with two instances of the learned CubeBody and the familiar pickable PointBody. Change their placements without changing construction data; make a second arrangement and reconstruct it from saved script values. Use known constructors, arrays and a loop, leaving scale and rotation to Transformation. The reflective text carries the wider question of what making geometry is meant to give us.'}
IDS=['triangle','polyhedra','cube','generator','godot-sphere','columns','profiles','limits','composition']

def main():
    verified=read(HERE/'verification.json');assert verified['passed']
    for path,h in verified['inputs'].items():assert sha(ROOT/path)==h,path
    # All mutations below are documentation, lesson records, and generated previews.
    preservation={}
    for hall in HALLS:
        for name in ['final.md','map_data.json']:
            p=ROOT/'commons/maps'/hall/name
            preservation[f'{hall}/{name}']=sha(p)==sha(HERE/'before'/hall/name)
    save(HERE/'preservation.json',preservation)
    assert all(preservation.values()),preservation

    revisions_path=ROOT/'doc/book/course/execution-plan/authorized-revisions.json'
    revisions=read(revisions_path);protected=read(revisions_path.with_name('protected-sources.json'))
    cards_path=ROOT/'doc/book/course/hall-cards/lineage-opening.json';cards=read(cards_path)
    stories_path=ROOT/'doc/book/course/storyboards/opening.json';stories=read(stories_path)
    for hall in HALLS:
        title,subjects,*_=LESSONS[hall]
        report=read(HERE/hall/'report-runtime.json')
        current=api('tutorial-cards')
        api('tutorial-cards',{'revision':current['revision'],'map':hall,'subjects':subjects,'focus':SUMMARIES[hall]})
        row=next((r for r in cards['halls'] if r['map']==hall),None)
        if row is not None:row.update(subjects=subjects,focus=SUMMARIES[hall],status='aligned',review='Complete printed program and helpers; native checks and fault control pass. Human learning and physical headset use remain untested.',revision_report=REL+'/index.html',tutorial_sha256_after=sha(ROOT/'commons/maps'/hall/'tutorial.md'))
        for sequence in stories:
            for row in sequence['halls']:
                if row['id']==hall:row.update(storyboard=SUMMARIES[hall],storyboard_short='TEACH '+ '; '.join(subjects)+'. KEEP museum host; printed owned geometry; declare supplied helpers. TEST native + variant + deliberate fault. CARRY '+SUMMARIES[hall].split('. ')[-1],learns=subjects)
        current=api('tutorial-plan')
        lesson=next(r for r in current['plan']['lessons'] if r['id']==hall)
        lesson.update(summary=SUMMARIES[hall],change=SUMMARIES[hall],next='Read the completed tutorial alongside final.md; review the transfer exercise. Continue in live spine order.',notes='Completed 6 October: '+REL+'/index.html . '+str(len(report['checks']))+' native assertions pass on the exact printed code. Full helper listings and source-bound Ghost Student records. Temporary museum placements only; no permanent map edit. The plan remains editable and author acceptance is unchanged.')
        lesson['given']=LESSONS[hall][3]+' Full local support is printed; existing Endless Museum player, camera, lighting and XR Tools remain the host.'
        api('tutorial-plan',{'kind':'lesson','revision':current['revision'],'record':lesson})
        path=f'commons/maps/{hall}/tutorial.md'
        revisions[path]={'date':'2026-10-06','before':protected[path],'after':sha(ROOT/path),'reason':'Author requested the remaining Primitives tutorials with consistent lineage. Complete museum-hosted learner examples, all helpers printed, native assertion and fault tests; final.md and runtime unchanged.'}
        diff=''.join(difflib.unified_diff((HERE/'before'/hall/'tutorial.md').read_text(encoding='utf-8-sig').splitlines(True),(ROOT/path).read_text(encoding='utf-8').splitlines(True),fromfile='before/tutorial.md',tofile='after/tutorial.md'))
        put(HERE/hall/'tutorial.diff',diff)
        with zipfile.ZipFile(HERE/hall/'lesson-files.zip','w',zipfile.ZIP_DEFLATED) as z:
            for p in (HERE/hall).iterdir():
                if p.suffix in ['.gd','.ttf','.txt']:z.write(p,p.name)
    save(revisions_path,revisions);save(cards_path,cards);save(stories_path,stories)
    publish_ghost(verified)
    make_report(verified)
    print('Published nine tutorials, plans, cards, source-bound states and reading report.')

def publish_ghost(verified):
    ghost=ROOT.parent/'ada_encyclopedia/ghost-student'
    manifest=read(ghost/'manifest.json')
    entries={r['id']:r for r in manifest['files']}
    # Keep original five states and their historical files byte-for-byte.
    manifest['states']=[s for s in manifest['states'] if not s['id'].startswith('primitives-')]
    previous=manifest['states'][-1]
    for number,(hall,tail) in enumerate(zip(HALLS,IDS),6):
        sid='primitives-'+tail;destination=ghost/'states'/f'{number:03d}-{sid}'
        destination.mkdir(parents=True,exist_ok=True)
        current=HERE/hall
        source=(current/'lesson.gd').read_text();incoming=(ghost/entries[previous['code']]['path']).read_text()
        operations=[{'id':'next-museum-study','kind':'replace','before':incoming,'after':source}]
        assert incoming.replace(operations[0]['before'],operations[0]['after'],1)==source
        pins={**read(current/'report-runtime.json')['inputs']}
        for p in [HERE/'verify.gd',HERE/'run_checks.py',*list((OLD/'trace').glob('*.gd')),*list((current).glob('*.ttf')),*list((current).glob('*.txt'))]:pins[p.relative_to(ROOT).as_posix()]=sha(p)
        helpers=[p for p in current.glob('*.gd') if p.name!='lesson.gd']
        contract={'incoming':{'sha256':hashlib.sha256(incoming.encode()).hexdigest()},'operations':operations,'given_files':[{'path':p.name,'sha256':sha(p)} for p in helpers],'sources':[{'path':p,'sha256':h} for p,h in pins.items()],'checks':[{'id':c['id'],'kind':'native'} for c in read(current/'report-runtime.json')['checks']],'evidence_inputs':list(pins)}
        save(current/'contract.json',contract)
        save(current/'next-input.json',{'incoming':{'sha256':sha(current/'lesson.gd')},'carry':SUMMARIES[hall]})
        report=read(current/'report-runtime.json')
        negative=report['negative_control']
        report.update(inputs=pins,dependencies=verified['dependencies'],learner_source_sha256=sha(current/'lesson.gd'),incoming_sha256=contract['incoming']['sha256'],negative_control={'name':'declared-fault','expected_failure_detected':True,'expected_failure_ids':[negative['required_failure']],'normal_contract_result':negative['result']})
        report['negative_controls']=[report['negative_control']]
        if report.get('resource_sharing_fault'):
            report['negative_controls'].append({'name':'shared-mesh','expected_failure_detected':True,'expected_failure_ids':['resolution/neighbour_independent'],'normal_contract_result':report['resource_sharing_fault']})
        # An additional publication envelope preserves the raw native report verbatim.
        save(current/'ghost-report.json',report)
        file_ids={}
        for p in [current/'lesson.gd',*helpers,current/'tutorial.md',current/'contract.json',current/'next-input.json',current/'ghost-report.json']:
            target=destination/p.name;shutil.copyfile(p,target)
            fid=sid+'-'+p.stem.replace('_','-');file_ids[p.name]=fid
            entries[fid]={'id':fid,'path':target.relative_to(ghost).as_posix(),'label':p.name,'language':{'.gd':'gdscript','.json':'json','.md':'markdown'}[p.suffix],'sha256':sha(target)}
        # Binary assets are bundled, with native source pins; not presented as text code dependencies.
        for p in list(current.glob('*.ttf'))+list(current.glob('*.txt')):shutil.copyfile(p,destination/p.name)
        state={'id':sid,'map':hall,'title':LESSONS[hall][0],'status':'verified','predecessor':previous['id'],'brief':{'bring':'Previously earned classes, data and operations; see tutorial for the exact return.','make':SUMMARIES[hall],'given':'Existing Endless Museum host and every printed companion file.','build':SUMMARIES[hall],'check':'Native assertions, a transfer variant and deliberate faults.','later':'Continue in live spine order; retain the object family.'},'subjects':LESSONS[hall][1],'carry':SUMMARIES[hall].split('. ')[-1],'nextStatus':'Complete tested lesson; author can still revise its focus.','provenance':'New study in the next museum hall. The main program is explicitly replaced, while named helper classes and/or saved data return. This is a cumulative code corpus, not a claim that a single live node persists through all rooms. Exact printed source executed in native Godot; synthetic input, not a human submission.','code':file_ids['lesson.gd'],'incomingSha256':contract['incoming']['sha256'],'outgoingSha256':sha(current/'lesson.gd'),'changes':operations,'givenFiles':{p.name:file_ids[p.name] for p in helpers},'files':list(file_ids.values()),'evidence':{'report':file_ids['ghost-report.json'],'contract':file_ids['contract.json'],'expected':file_ids['lesson.gd'],'nextInput':file_ids['next-input.json'],'tutorial':file_ids['tutorial.md'],'negativeControl':'The same native assertions reject deliberate faults.','negativeControls':[n['name'] for n in report['negative_controls']]}}
        manifest['states'].append(state);previous=state
    manifest['files']=list(entries.values())
    manifest['planned']=[r for r in manifest.get('planned',[]) if r.get('map') not in HALLS]
    manifest['summary']='Fourteen tested learner states: point, pickup, lines, saved trace, Grid, and nine Primitives continuations through Melencolia. Named constructions return across museum studies; main-program replacements and supplied helpers are explicit.'
    save(ghost/'manifest.json',manifest)

def make_report(verified):
    import markdown
    css='''body{margin:0;background:#f2efe9;color:#242322;font:18px/1.65 Georgia,serif}header,main{max-width:1160px;margin:auto;padding:48px 34px}h1{font-size:48px;line-height:1.1}h2{line-height:1.2}a{color:#9c365f}nav{display:flex;gap:15px;flex-wrap:wrap}article{border-top:1px solid #cbc4ba;padding:36px 0}img{width:100%;height:auto;border-radius:6px}small,.meta{font:14px/1.6 system-ui,sans-serif;color:#67615c}.subjects{display:flex;flex-wrap:wrap;gap:8px}.subjects span{background:#e9d8df;padding:4px 10px;border-radius:4px;font:14px system-ui}pre{background:#20272c;color:#eae6de;padding:22px;overflow:auto;font:14px/1.6 Consolas,monospace}code{font-family:Consolas,monospace}.page{max-width:880px;margin:auto}figure{margin:30px 0}summary{cursor:pointer}@media(max-width:600px){h1{font-size:34px}header,main{padding:24px 18px}}'''
    intro='<p class="meta">ENDLESS MUSEUM · PRIMITIVES · 6 OCTOBER 2026</p><h1>What the next object remembers</h1><p>Nine completed tutorials, continuing from the saved Trace → Grid handoff. Each lesson names what returns, adds a bounded capability, prints its program and dependencies, and asks for an independent variation.</p>'
    intro+=f'<p><strong>{sum(r["assertions"] for r in verified["halls"])} native assertions pass; 10 deliberate faults rejected.</strong> Museum captures show temporary learner studies in the existing halls. Physical headset comfort and human understanding still need a reader’s test.</p>'
    intro+='<nav><a href="../2026-10-05-primitives-facing-pages/index.html#map=Point_Triangle_Context">Tutorial left · reflection right</a><a href="http://localhost:3003/tutorial-plan?view=summaries&map=Point_Triangle_Context">Editable paragraph plan</a><a href="http://localhost:3003/ghost-student?state=primitives-triangle">Ghost Student code states</a><a href="verification.json">Native evidence</a></nav>'
    sections=''
    for i,hall in enumerate(HALLS):
        title,subjects,*_=LESSONS[hall]
        photo='held-resolution' if hall=='Primitives_Godot' else ('learner-close' if hall in ['Primitives_Polythedra','Primitives_Ignorance','Primitives_Columns','Primitives_Portals','Primitives_Melencolia'] else 'learner-study')
        image_path=f'{hall}/museum/{photo}.png'
        sections+=f'<article id="{hall}"><p class="meta">{i+7:02d} / 15 · {hall}</p><h2>{html.escape(title)}</h2><div class="subjects">'+''.join('<span>'+html.escape(s)+'</span>' for s in subjects)+'</div><p>'+html.escape(SUMMARIES[hall])+'</p>'
        if hall in ['Primitives_Polythedra','Primitives_Melencolia']:
            sections+=f'<p class="meta">The program passed its native and hall-mounting checks. The temporary capture overlaps existing displays, so it is excluded from the illustrated review. <a href="{hall}/museum/report.json">Integration record</a>.</p>'
        elif (HERE/image_path).exists():sections+=f'<figure><img src="{image_path}" alt="Temporary learner study in the {hall} museum hall" loading="lazy"><figcaption class="meta">Exact lesson program inside the actual museum. Temporary placement; synthetic input for recorded/held examples.</figcaption></figure>'
        sections+=f'<nav><a href="{hall}.html">Read the complete tutorial</a><a href="{hall}/lesson-files.zip">Download code</a><a href="{hall}/tutorial.diff">Before → after text</a><a href="{hall}/report-runtime.json">Assertions</a></nav></article>'
        lesson=(ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf-8')
        before=HALLS[max(0,i-1)];after=HALLS[min(len(HALLS)-1,i+1)]
        page=f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)}</title><style>{css}</style><main class="page"><nav><a href="index.html#{hall}">Route</a><a href="{before}.html">Previous</a><a href="{after}.html">Next</a><a href="{hall}/lesson-files.zip">Code files</a></nav>'+markdown.markdown(lesson,extensions=['fenced_code','tables'])+'</main></html>'
        put(HERE/(hall+'.html'),page)
    footer='<article><h2>What is and is not verified</h2><p>Tests execute code extracted and byte-compared with tutorial.md. The native run uses the actual prior Trace recorder for synthetic input and unmodified XR Tools for pickup. Fault tests break winding, closure, parameter ownership, timing or placement. Real-hall probes check mounting and captures; they do not certify the whole museum, whose logs retain unrelated legacy material and portal warnings.</p><p>The reflective final.md files and nine map_data.json files match their before snapshots. The teaching route remains editable. New study roots are explicit; class reuse and saved-data continuity are distinguished from moving a single runtime object across every hall.</p></article>'
    footer+='<p class="meta">Separate repository issue: the global course validator reports an unrecorded Triangle map_data.json revision that already existed before this pass. That map still matches our before snapshot. The nine lesson checks do not clear this unrelated baseline discrepancy.</p>'
    put(HERE/'index.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Primitives — tutorial lineage</title><style>'+css+'</style><header>'+intro+'</header><main>'+sections+footer+'</main></html>')

if __name__=='__main__':main()
