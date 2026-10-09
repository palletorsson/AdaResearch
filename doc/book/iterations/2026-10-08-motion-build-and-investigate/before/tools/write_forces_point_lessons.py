"""One authored Forces revision. --write installs prose/code; default renders saved tutorials."""
from pathlib import Path
import json, html, shutil, sys, re
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-forces-one-body-through-the-halls'
CODE=ROOT/'doc/book/studies/forces-point-lineage'
BEFORE=OUT/'before/commons/maps'

# Authored prose is kept separately so edits remain inspectable without touching code.
ROWS=json.loads((ROOT/'doc/book/course/forces-lesson-prose.json').read_text(encoding='utf8'))

def fence(path):return '\n```gdscript\n'+path.read_text(encoding='utf8').rstrip()+'\n```\n'
def make_tutorial(row,index):
    shared='../../../doc/book/course/forces-shared-code.md'
    s=f"# {row['title']}\n\n**Learning elements**\n\n"+'\n'.join('- '+x for x in row['subjects'])+'\n\n'+row['encounter']+'\n\n## Make the small study\n\n'+row['learn']+'\n\n'
    s+='**The hall adds:** '+row['scope']+'\n\n'
    s+=f"Save `{row['file']}` beside your shared files and use it on `PointStudy`. [Setup and complete shared code]({shared}).\n\n"
    if index==10:
        s+='Work inside the existing capability court, whose movement adapter is required for flight. Save `thrust_point.gd` beside the other files.\n\n### thrust_point.gd\n\n<!-- student-code:thrust_point.gd -->\n'+fence(CODE/'thrust_point.gd')+'\n'
    s+=f"## Complete code — {row['file']}\n\n<!-- student-code:{row['file']} -->\n"+fence(CODE/row['file'])+'\n## Read the change\n\n'+row['explain']+'\n\n## Change one thing\n\n'+row['tryit']+'\n\n'
    if row.get('explore'):
        s+='## Return to the hall\n\n'+row['explore']+'\n\n'
    s+='## Model notes\n\n'+row['note']+'\n\n## Into the next room\n\n'+row['onward']+'\n\n[Reflective text](final.md).\n'
    return s

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    plan=json.loads((ROOT/'commons/artifacts/force_halls/curation.json').read_text(encoding='utf8'))
    if '--write' in sys.argv:
        for i,row in enumerate(ROWS):
            (ROOT/'commons/maps'/row['map']/'tutorial.md').write_text(make_tutorial(row,i),encoding='utf8')
            contract=next(r for r in plan['halls'] if r['map']==row['map'])
            contract['lesson']=row['learn'];contract['carry']=row['onward'];contract['independent_check']=row['tryit']
            (ROOT/'commons/maps'/row['map']/'FORCES_LESSON.md').write_text(f"# {row['title']}\n\nPrimary: `{contract['tutorial_artifact']}`.\n\n"+row['learn']+'\n\nCarry: '+row['onward']+'\n\nCheck: '+row['tryit']+'\n',encoding='utf8')
        plan['date']='2026-10-08'
        (ROOT/'commons/artifacts/force_halls/curation.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        common=(ROOT/'doc/book/course/forces-study-opening.md').read_text(encoding='utf8')+'\n\n'
        for f,desc in [('point_body.gd','Unchanged from Lines: a visible sphere, matching collision boundary and XR pickup.'),('free_point.gd','A new subclass: physical release, explicit damping and gravity settings. Each lesson chooses whether to enable gravity or freeze its marker.'),('study.gd','Supplied display furniture. Buttons emit the named action once per press. The thin cylinder is a drawing of a relation, without a collider.')]:
            common+='## '+f+'\n\n'+desc+'\n\n'+fence(CODE/f)+'\n'
        common+='## Existing receiver for the last hall\n\n`commons/artifacts/force_capability_lab/force_capability_lab.gd` sums `acceleration()` from `ada_thrust_points` whose `receiver()` matches the player. `commons/artifacts/force_field_zone/field_carry_provider.gd` performs the XRTools movement handoff. These supplied museum components own collisions and gravity. Rebuilding the player is not part of this lesson. The continuation introduces the point’s action and its receiver contract.\n'
        (ROOT/'doc/book/course/forces-shared-code.md').write_text(common,encoding='utf8')
        (CODE/'README.md').write_text('# Forces: the same point gains responses\n\nEleven complete lesson scripts for PointStudy inside the existing Endless Museum. Open the corresponding commons/maps/MAP/tutorial.md for the learning sequence. Shared code: doc/book/course/forces-shared-code.md. The last study requires the existing capability court receiver; all require Godot XR Tools and the museum push button.\n\nRun `tools/probes/forces_lesson_chain.gd` in the project with Godot 4.6, headless, XR off. The probe loads these exact files. `tools/write_forces_point_lessons.py` checks that the displayed tutorial fences still match them.\n',encoding='utf8')
    # Byte-for-byte code parity: the actual tested continuation is what the student reads.
    parity=[]
    for row in ROWS:
        s=(ROOT/'commons/maps'/row['map']/'tutorial.md').read_text(encoding='utf8')
        for name,code in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',s,re.S):
            parity.append({'map':row['map'],'file':name,'passed':code.strip()==(CODE/name).read_text(encoding='utf8').strip()})
    (OUT/'code-parity.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    assert len(parity)==12 and all(p['passed'] for p in parity)
    (OUT/'lesson-decisions.json').write_text(json.dumps(ROWS,ensure_ascii=False,indent=2),encoding='utf8')
    for name in ['forces_lesson_chain.json','forces_lesson_chain.log']:
        p=ROOT/'ada_run'/name
        if p.exists():shutil.copy2(p,OUT/name)
    css='body{margin:0;background:#eae7df;color:#19191e;font:18px/1.65 Georgia,serif}main{max-width:1080px;margin:auto;padding:40px}h1{font-size:2.7rem;line-height:1.1}h2{margin-top:2em}nav{font:14px system-ui;display:flex;flex-wrap:wrap;gap:12px}a{color:#763d59}article{background:#fffdf8;padding:32px;margin:24px 0;border-top:4px solid #26252b}pre{background:#20232b;color:#f5ede3;padding:20px;overflow:auto;font:14px/1.5 Consolas,monospace}code{font-family:Consolas,monospace}img{width:100%;height:auto}blockquote{border-left:3px solid #a8798e;margin-left:0;padding-left:20px}.two{display:grid;grid-template-columns:1fr 1fr;gap:20px}.meta{font:14px/1.5 system-ui}.badge{background:#ede4e8;padding:10px}@media(max-width:800px){.two{grid-template-columns:1fr}main{padding:16px}}'
    def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+html.escape(title)+'</title><style>'+css+'</style><main><nav><a href="index.html">Review</a><a href="tutorials.html">All eleven tutorials</a><a href="shared.html">Shared code</a><a href="final.html">Existing reflections</a></nav>'+body+'</main></html>'
    common=(ROOT/'doc/book/course/forces-shared-code.md').read_text(encoding='utf8')
    (OUT/'forces-shared-code.md').write_text(common,encoding='utf8')
    (OUT/'shared.html').write_text(page('Shared code',md(common).replace('href="forces-shared-code.md"','href="shared.html"')),encoding='utf8')
    tutorial=[];final=[];summary=[];cards=[]
    current=None
    p=OUT/'forces_lesson_chain.json'
    if p.exists():current=json.loads(p.read_text(encoding='utf8'))
    for i,row in enumerate(ROWS):
        m=row['map'];src=ROOT/'commons/maps'/m
        for dest,name,collection in [('tutorial','tutorial.md',tutorial),('final','final.md',final)]:
            text=(src/name).read_text(encoding='utf8')
            # Resolve museum/book image URLs to local files in this offline review.
            text=re.sub(r'\]\(/book-review/([^\)]+)\)',lambda x:']('+ (ROOT/x.group(1)).as_uri()+')',text)
            rendered=md(text)
            def resolve_link(match):
                url=html.unescape(match.group(1))
                if url=='final.md':return 'href="final.html#'+m+'"'
                if url.endswith('forces-shared-code.md'):return 'href="shared.html"'
                if not url.startswith(('http:','https:','file:','#','/')):
                    target=(src/url).resolve()
                    if target.exists():return 'href="'+target.as_uri()+'"'
                return match.group(0)
            rendered=re.sub(r'href="([^"]+)"',resolve_link,rendered)
            collection.append(f'<article id="{m}"><p class="meta">{i+1:02} / {m}</p>{rendered}</article>')
            if dest=='tutorial':(OUT/(m+'.html')).write_text(page(row['title'],rendered),encoding='utf8')
        summary.append(f"## {i+1}. {m} — {row['title']}\n\n"+row['encounter']+' '+row['learn']+' '+row['onward']+'\n')
        image=OUT/'museum'/m/'primary.png'
        visual=f'<img src="museum/{m}/primary.png" alt="Actual Endless Museum view of {html.escape(row["title"])}">' if image.exists() else '<p class="meta">Museum capture pending.</p>'
        extra=OUT/'museum'/m/'expanded.png'
        if extra.exists():visual+=f'<details><summary>Open the full experiment</summary><img src="museum/{m}/expanded.png"></details>'
        student=OUT/'museum'/m/'student.png'
        if student.exists():visual+=f'<details><summary>The exact student code running in this museum hall</summary><p class="meta">Temporary probe instance of PointStudy, beside the existing exhibit. This extra copy is not installed permanently.</p><img src="museum/{m}/student.png"></details>'
        old=(BEFORE/m/'tutorial.md').read_text(encoding='utf8')
        before_title=old.splitlines()[0].lstrip('# ')
        cards.append(f'<article id="{m}"><p class="meta">{i+1:02} / {m}</p><h2>{html.escape(row["title"])}</h2>{visual}<p>{html.escape(row["encounter"])}</p><div class="two"><div><h3>Before</h3><p>{html.escape(before_title)}</p><a href="before/commons/maps/{m}/tutorial.md">Full earlier tutorial</a></div><div><h3>After</h3><p>{html.escape(row["learn"])}</p><a href="{m}.html">Read the tested continuation</a><p class="meta"><a href="before-editorial/commons/maps/{m}/tutorial.md">Prose before this reading pass</a></p></div></div><p class="badge"><strong>Writing decision:</strong> {html.escape(row["keep"])}</p><blockquote>{html.escape(row["retained"])}</blockquote><p class="meta">The quoted line is retained as editorial evidence; final.md has not been rewritten in this pass. Some older exhibit-specific instructions in those reflections still need alignment.</p></article>')
    opening=(ROOT/'doc/book/course/forces-study-opening.md').read_text(encoding='utf8')
    (OUT/'tutorials.html').write_text(page('Forces — eleven tutorials',md(opening).replace('href="forces-shared-code.md"','href="shared.html"')+''.join(tutorial)),encoding='utf8')
    (OUT/'final.html').write_text(page('Forces — existing reflections','<h1>Existing reflective sequence</h1><p>Preserved for editorial comparison. Several passages name earlier interfaces; this is not a claim that every described artifact is currently placed.</p>'+''.join(final)),encoding='utf8')
    (OUT/'summaries.md').write_text('# Forces — eleven lesson summaries\n\n'+ '\n'.join(summary),encoding='utf8')
    readings=[]
    for row in ROWS:
        text=(ROOT/'commons/maps'/row['map']/'tutorial.md').read_text(encoding='utf8')
        text=text.replace('../../../doc/book/course/forces-shared-code.md','forces-shared-code.md').replace('](final.md)','](final.html#'+row['map']+')')
        readings.append(text)
    (OUT/'tutorials.md').write_text(opening+'\n\n---\n\n'+'\n\n---\n\n'.join(readings),encoding='utf8')
    nav='<nav>'+''.join(f'<a href="#{r["map"]}">{i+1}. {html.escape(r["title"])}</a>' for i,r in enumerate(ROWS))+'</nav>'
    result=f"{sum(c['passed'] for c in current['checks'])}/{len(current['checks'])} Godot checks" if current else 'Godot checks pending'
    header='<h1>One body gains responses</h1><p class="badge">Reading revision · 8 October: one shared opening, shorter instructions, stepwise explanations and optional returns to the full experiments. The tested learner code and museum behaviour are unchanged.</p><p>Eleven existing Forces halls. One focused reconstruction in each; the familiar point returns wherever its shape remains useful. The cube returns for contact support. The player becomes the final receiver.</p><p>Good writing can steer the plan. Phase rods remain primary in Choreography because the existing text makes prescribed motion distinct from a spring. The conveyor stays beside them as a physical consequence.</p><p class="badge">'+result+' from the existing runtime verification; 12 displayed-code blocks match the tested files. Jolt integration and simulated XRTools input; physical headset testing belongs to your visit.</p><p><a href="summaries.md">One file: all lesson summaries</a> · <a href="tutorials.md">Complete tutorials as Markdown</a> · <a href="forces_lesson_chain.json">Assertions</a> · <a href="capture-status.json">Museum capture checks</a> · <a href="editorial-checks.json">Reading revision checks</a></p><p>Before/after below refers to the tutorial revision. Images are new renders inside the actual museum. Expanded views show the optional full experiment. Existing final.md files are preserved; old control descriptions in them remain a separate editorial pass.</p>'
    (OUT/'index.html').write_text(page('Forces — one body through the halls',header+nav+''.join(cards)),encoding='utf8')
    print('Rendered eleven tutorials; code parity:',len(parity),'/',len(parity))

if __name__=='__main__':main()
