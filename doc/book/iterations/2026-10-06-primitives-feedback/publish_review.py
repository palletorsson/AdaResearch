"""Publish the authorised prose review without altering learner or museum code."""
from pathlib import Path
import json, hashlib, shutil, sys, re, difflib, html

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PREVIOUS=HERE.parent/'2026-10-06-primitives-tutorial-lineage'
GRID=HERE.parent/'2026-10-06-trace-saved-to-grid'
GHOST=ROOT.parent/'ada_encyclopedia/ghost-student'
REL=HERE.relative_to(ROOT).as_posix()
sys.path.insert(0,str(PREVIOUS))
import publish as previous

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def put(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(s,encoding='utf-8',newline='\n')
def save(p,v):put(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')

CHANGES={
'Point_Line_Grid':('One record, different representations','Names the distinction between sampled source, visible sculpture and rounded addresses. The reflective passage keeps both partial accounts available for another use.'),
'Point_Triangle_Context':('Choose the connections','Makes index-based connectivity explicit while acknowledging that Lines already connected positions. The reflection places responsibility in choosing which corners belong together.'),
'Primitives_Ignorance':('Choose a rule, inspect its result','Compares an authored list with a function returning positions. The reflection keeps individual differences available to inspection; a rule does not require ignorance of its results.'),
'Primitives_Godot':('Resolution is the main lesson','Rings and radial segments become the dominant focus. Pickup, held-time stepping and reset remain fully printed supporting mechanics. Compare one parameter at a time.'),
'Primitives_Profiles':('A section carried along a route','Returns to the ring sections from Columns before substituting a letter outline. Start with sideways travel; font extraction and general curved-path frames remain supplied or deferred. Clarifies the C-shaped section.'),
'Primitives_Portals':('A finite stopping rule','Makes the supplied circle sampler explicit so the explanation can concentrate on tolerance and work budget. The existing reflective text already carries the question of a limit.'),
'Primitives_Melencolia':('Composition and independent transfer','Adds a small independent arrangement using learned generators, copies, faces and sphere resolution. The reflection makes clear that construction does not choose where an object belongs.')}

def main():
    integrity=read(HERE/'prose-integrity.json')
    for hall,row in integrity.items():
        p=ROOT/f'commons/maps/{hall}/tutorial.md'
        assert sha(p)==row['tutorial_sha256']
        old=(HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8')
        pattern=r'```(?:gdscript|glsl|python)\n(.*?)^```'
        assert re.findall(pattern,old,re.M|re.S)==re.findall(pattern,p.read_text(encoding='utf-8'),re.M|re.S)
        mp=ROOT/f'commons/maps/{hall}/map_data.json'
        assert sha(mp)==sha(HERE/'before'/mp.relative_to(ROOT))
    verified=read(PREVIOUS/'verification.json');assert verified['passed']
    for p,h in verified['inputs'].items():assert sha(ROOT/p)==h,p

    # New immutable evidence for the revised Grid prose; preserve the prior archive.
    manifest=read(GHOST/'manifest.json');entries={f['id']:f for f in manifest['files']}
    trace_checks={}
    for part,state_id,folder in [('trace','point-trace','004-point-trace'),('grid','point-grid','005-point-grid')]:
        report=read(GRID/part/'report-runtime.json');assert report['passed']
        for p,h in {**report['inputs'],**report['dependencies']}.items():assert sha(ROOT/p)==h,p
        trace_checks[part]=len(report['checks'])
        evidence={}
        paths=[p for p in (GRID/part).rglob('*') if p.is_file() and p.suffix in ['.gd','.md','.json']]
        paths += [GRID/n for n in ['build.py','run_checks.py','verify_trace.gd','verify_handoff.gd']]
        for source in paths:
            relative=source.relative_to(GRID/part) if source.is_relative_to(GRID/part) else Path('support')/source.name
            target=GHOST/'evidence'/HERE.name/part/relative
            target.parent.mkdir(parents=True,exist_ok=True)
            if target.exists():assert target.read_bytes()==source.read_bytes(),str(target)
            else:shutil.copyfile(source,target)
            key=relative.with_suffix('').as_posix().replace('/','-').replace('_','-')
            fid='feedback-'+part+'-'+key
            entries[fid]={'id':fid,'path':target.relative_to(GHOST).as_posix(),'label':'evidence/'+relative.as_posix(),'language':{'.gd':'gdscript','.md':'markdown','.json':'json','.py':'python'}[source.suffix],'sha256':sha(target)}
            evidence[key]=fid
        state=next(s for s in manifest['states'] if s['id']==state_id)
        state['evidence'].update(report=evidence['report-runtime'],contract=evidence['contract'],expected=evidence['expected'],nextInput=evidence['next-input'],tutorial=evidence['tutorial'])
        state['files']=[f for f in state['files'] if not f.startswith(('saved-'+part+'-','feedback-'+part+'-'))]+list(evidence.values())
        shutil.copyfile(GRID/part/'tutorial.md',GHOST/'states'/folder/'tutorial.md')
        if part=='grid':
            state['subjects'].insert(2,'One record, different representations') if 'One record, different representations' not in state['subjects'] else None
            state['brief']['build']='Load the actual saved Trace sculpture. Retain its sampled source and derive rounded XYZ addresses for an independently owned green copy. Compare representations without overwriting the source.'
        brief_path=GHOST/'states'/folder/'brief.json'
        save(brief_path,{k:state[k] for k in ['map','status','predecessor','provenance','brief','carry','nextStatus']})
        entries[state_id+'-brief']['sha256']=sha(brief_path)
    manifest['files']=list(entries.values());save(GHOST/'manifest.json',manifest)
    previous.publish_ghost(verified)

    summaries=read(HERE/'summaries.json')
    summaries['Point_Line_Grid']='Meet the drawing saved in Trace as a sculpture in Grid. One sampled record supports several representations: an ordered array, visible segments and rounded XYZ addresses. Keep the pink source intact while changing an independent green copy. Predict an address, compare pitches and flatten only the copy. Carry the preserved source into Triangle.'
    cards_path=ROOT/'doc/book/course/hall-cards/lineage-opening.json';cards=read(cards_path)
    stories_path=ROOT/'doc/book/course/storyboards/opening.json';stories=read(stories_path)
    revisions_path=ROOT/'doc/book/course/execution-plan/authorized-revisions.json';revisions=read(revisions_path)
    protected=read(revisions_path.with_name('protected-sources.json'))
    subjects={}
    for hall in CHANGES:
        p=ROOT/f'commons/maps/{hall}/tutorial.md'
        subjects[hall]=previous.LESSONS[hall][1] if hall in previous.LESSONS else re.findall(r'^- (.+)$',p.read_text(encoding='utf-8').split('##',1)[0],re.M)
        assert subjects[hall],hall
        current=previous.api('tutorial-cards')
        previous.api('tutorial-cards',{'revision':current['revision'],'map':hall,'subjects':subjects[hall],'focus':summaries[hall]})
        row=next(r for r in cards['halls'] if r['map']==hall)
        row.update(subjects=subjects[hall],focus=summaries[hall],revision_report=REL+'/index.html',tutorial_sha256_after=sha(p),review='Feedback refinement: sharper learning focus; printed executable source unchanged and native evidence refreshed. Independent learning still requires a reader.',status='aligned')
        for seq in stories:
            for row in seq['halls']:
                if row['id']==hall:row.update(storyboard=summaries[hall],storyboard_short='TEACH '+ '; '.join(subjects[hall])+'. '+summaries[hall],learns=subjects[hall],review_note='6 October feedback refinement. See '+REL+'/index.html')
        current=previous.api('tutorial-plan')
        lesson=next(r for r in current['plan']['lessons'] if r['id']==hall)
        note=' Prose feedback applied: '+REL+'/index.html. Printed code unchanged; native evidence refreshed. Capstone is an independent task, not an additional verified solution.'
        lesson.update(summary=summaries[hall],change=summaries[hall],notes=lesson.get('notes','').replace(note,'')+note)
        if hall in previous.LESSONS:lesson['given']=previous.LESSONS[hall][3]+' The existing Endless Museum remains the host; all local helpers are printed.'
        previous.api('tutorial-plan',{'kind':'lesson','revision':current['revision'],'record':lesson})
        for name in ['tutorial.md','final.md']:
            source=ROOT/f'commons/maps/{hall}/{name}';before=HERE/'before'/source.relative_to(ROOT)
            if sha(source)==sha(before):continue
            rel=source.relative_to(ROOT).as_posix()
            revisions[rel]={'date':'2026-10-06','before':revisions.get(rel,{}).get('before',protected.get(rel,sha(before))),'after':sha(source),'reason':'Author requested relevant feedback in tutorial.md and final.md. Bounded prose clarification; executable learner code and museum runtime unchanged. Native tutorial checks refreshed.'}
            put(HERE/hall/(name+'.diff'),''.join(difflib.unified_diff(before.read_text(encoding='utf-8').splitlines(True),source.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name)))
    save(cards_path,cards);save(stories_path,stories);save(revisions_path,revisions)
    save(PREVIOUS/'subjects.json',{hall:previous.LESSONS[hall][1] for hall in previous.HALLS})
    fs_path=ROOT/'doc/book/course/hall-cards/final-summaries-opening.json';fs=read(fs_path)
    reflective={
    'Point_Line_Grid':'The trace arrives as a sculpture. Different displayed versions retain partial accounts of the hand’s movement; keeping the source allows another use without erasing it.',
    'Point_Triangle_Context':'Three chosen corners become a boundary and a visible face through different instructions. Connectivity is a decision about belonging and order, while seeing a surface does not yet make it solid.',
    'Primitives_Ignorance':'Ordered solids and a family of cylinders make the desire for geometry tangible. Choosing a rule changes how we make and know the positions, while particular surfaces and differences remain available to inspection.',
    'Primitives_Melencolia':'An arrangement of tools and forms holds geometry beside the unfinished work of making. Knowing how to construct a cube does not choose its place or tell us what the arrangement should mean.'}
    for row in fs['summaries']:
        if row['map'] in reflective:row.update(summary=reflective[row['map']],source_sha256=sha(ROOT/f'commons/maps/{row["map"]}/final.md'))
    save(fs_path,fs)
    save(HERE/'verification.json',{'passed':True,'printed_code_unchanged':True,'maps_unchanged':True,'trace_assertions':trace_checks['trace'],'grid_assertions':trace_checks['grid'],'shared_trace_grid_producer_assertions':10,'later_primitives_assertions':sum(r['assertions'] for r in verified['halls']),'deliberate_faults_rejected':14,'scope':'Refreshed native tests on exact printed source. Assertion counts include repeated checks. No new museum rendering or headset test; independent closing task and human understanding not verified.'})
    make_report()
    print('Published seven tutorial refinements, four reflective revisions, current plans/cards and fourteen source-bound learner states.')

def make_report():
    e=html.escape
    blocks=[]
    for hall,(title,description) in CHANGES.items():
        nav=f'<a href="../2026-10-05-primitives-facing-pages/{hall}.html">Tutorial left · reflection right</a> · <a href="{hall}/tutorial.md.diff">Tutorial changes</a>'
        if (HERE/hall/'final.md.diff').exists():nav+=f' · <a href="{hall}/final.md.diff">Reflective changes</a>'
        blocks.append(f'<article id="{hall}"><small>{e(hall)}</small><h2>{e(title)}</h2><p>{e(description)}</p><p class="links">{nav}</p></article>')
    body='''<header><small>ENDLESS MUSEUM · PRIMITIVES · 6 OCTOBER 2026</small><h1>Keep the lineage. Sharpen the lesson.</h1><p>The feedback identifies the chapter’s strongest connection: an object becomes a relation, a retained record, an indexed construction, a generating rule and finally an authored arrangement. The hall order stays as it is.</p><p>Seven tutorials and four reflective texts are refined. Complete learner programs remain unchanged.</p><nav><a href="../2026-10-05-primitives-facing-pages/index.html">Read the chapter in parallel</a> · <a href="http://localhost:3003/tutorial-plan?view=summaries&map=Point_Line_Grid">Editable lesson summaries</a> · <a href="http://localhost:3003/ghost-student?state=point-grid">Tested learner states</a></nav></header>'''
    body+='<main>'+''.join(blocks)+'''<article><h2>Where the feedback needed qualification</h2><p>The saved trace is a finite sample, not a complete continuous movement. Lines already teaches relations; Triangle adds an ordered face recipe. A generating rule can reduce manual work without making its output unknowable. The closing exercise asks for an arrangement using known constructions; an inhabitable structure would introduce unlearned collision work.</p><p>Godot, Profiles and Portals already had useful reflective passages, so the changes there stay in the tutorial. Tetrahedron, Cube and Columns already carry the proposed progression and need no extra explanation.</p></article><article><h2>What was checked</h2><p>All printed executable blocks are unchanged. Native Godot tests pass: Trace 134 checks and Grid 53 (including 10 shared producer checks), plus 122 across the nine later Primitives lessons. Fourteen deliberate faults are rejected. These counts include repeated assertions across lessons.</p><p>The current code and evidence are published together. This pass did not rerender the museum or test a headset. The new independent composition task has no supplied solution; execution checks alone cannot establish learner understanding.</p><p><a href="verification.json">Verification scope</a> · <a href="prose-integrity.json">Printed-code preservation</a></p></article></main>'''
    body=body.replace('</main>','<p class="links">The wider plan audit still flags an existing Point_Triangle_Context/map_data.json mismatch against its older protected baseline. That map file is unchanged in this pass. <a href="publication-check.json">Publication checks and separate audit issue</a>.</p></main>')
    css='body{margin:0;background:#f2efe9;color:#242322;font:19px/1.65 Georgia,serif}header,main{max-width:1000px;margin:auto;padding:40px 32px}h1{font-size:48px;line-height:1.1}h2{font-size:29px;line-height:1.2}small,nav,.links{font:14px/1.6 system-ui,sans-serif}small{letter-spacing:.08em;color:#6b635e}a{color:#993555}article{border-top:1px solid #cec6bc;padding:28px 0}p{max-width:850px}@media(max-width:600px){header,main{padding:25px 20px}h1{font-size:35px}}'
    put(HERE/'index.html','<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — feedback applied</title><style>'+css+'</style>'+body+'</html>')

if __name__=='__main__':main()
