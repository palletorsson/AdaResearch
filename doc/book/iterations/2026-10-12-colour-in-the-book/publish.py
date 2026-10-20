"""Promote tested Colour manuscripts and publish paired readings; preserve current reflections."""
from prepare import HERE, ROOT, HALLS, put, sha
import ast, difflib, html, json, re, shutil, sys, zipfile
import markdown
sys.path.insert(0,str(ROOT/'tools'))
import project_memory

# Reuse the preceding sequence's quiet reading layout without executing its publisher.
tree=ast.parse((HERE.parent/'2026-10-12-arrays-in-the-book/publish.py').read_text(encoding='utf-8'))
CSS=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='CSS' for t in n.targets))

def render(text):
    return markdown.markdown(text.replace('/book-images/','/book-review/doc/book/'),extensions=['fenced_code','tables','footnotes'])

def page(title,body,depth=0):
    p='../'*depth
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / COLOUR</b><a href="{p}index.html">Sequence</a><a href="{p}all.html">Tutorials</a><a href="{p}final.html">Reflections</a><a href="{p}colour-review.zip">Review ZIP</a></header><main>{body}</main></body></html>'

def main():
    evidence=json.loads((HERE/'sequence-verification.json').read_text())
    assert evidence['passed'] and evidence['halls']==8
    for n,digest in evidence['inputs'].items(): assert sha(ROOT/n)==digest,n
    before=json.loads((HERE/'before-sources.json').read_text())
    targets=[f'commons/maps/{h}/tutorial.md' for h in HALLS]
    if not (HERE/'promotion.json').exists():
        for n,digest in before.items(): assert sha(ROOT/n)==digest,'Concurrent edit: '+n
        for h in HALLS: shutil.copyfile(HERE/h/'tutorial.md',ROOT/'commons/maps'/h/'tutorial.md')
        put(HERE/'promotion.json',json.dumps({'date':'2026-10-12','authorization':'Continue one sequence at a time after Transformation and Arrays.','tutorials':{n:{'before':before[n],'after':sha(ROOT/n)} for n in targets},'basis':'Reviewed 6 October complete Colour drafts, with the current reflections preserved.','student_changes':evidence['changed_student_files'],'runtime_changed':False,'final_changed':False},indent=2)+'\n')
    protected={n:d for n,d in before.items() if n not in targets and not n.startswith('doc/book/course/execution-plan/')}
    for n,d in protected.items(): assert sha(ROOT/n)==d,n
    put(HERE/'preserved.json',json.dumps(protected,indent=2)+'\n')
    lineage=json.loads((HERE/'lineage.json').read_text())
    scopes={s['id']:s for s in project_memory.model(ROOT)['scopes']}
    body=f'''<h1>Colour: where is the value kept?</h1><p class="deck">The familiar body acquires colour. A light changes what reaches it. A position chooses a value; a palette orders it; a surface keeps the mark.</p><p class="route">Material → illumination → RGB choice → ordered bands → HSV field → stored cell → accumulated paint → layered view</p><p>12 October 2026 · Eight canonical tutorials, {evidence['printed_files']} complete printed files. {evidence['native_assertions']} fresh native assertions, {evidence['render_assertions']} rendering checks, {evidence['faults_rejected']} deliberate faults detected. {evidence['configurations_including_baselines']} configurations including baselines.</p><div class="links"><a href="Color_Context_Placed/parallel.html">Start paired reading →</a><a href="ALL_TUTORIALS.md">Whole tutorial file</a><a href="ALL_FINAL.md">Whole reflective file</a><a href="SUMMARIES.md">Eight short summaries</a><a href="sequence-verification.json">Test evidence</a></div><p>These are the existing reviewed Colour drafts brought into the book. The return from Arrays is explicit; all eight lesson programs keep their reviewed operations. Grid and Walls gain supplied pointer controls, and Nails now prints both inherited classes. Each study belongs in the prepared Endless Museum. The current reflective texts remain beside them.</p>'''
    readings={'tutorial':[],'final':[]};manifest={'date':'2026-10-12','halls':[]}
    summary='# Colour — eight lessons in sequence\n\n12 October 2026. Current canonical tutorials; revisable teaching decisions.\n\n'
    for i,item in enumerate(lineage):
        h=item['id']; t=(HERE/h/'tutorial.md').read_text(encoding='utf-8');f=(HERE/h/'final.md').read_text(encoding='utf-8')
        assert sha(HERE/h/'tutorial.md')==sha(ROOT/'commons/maps'/h/'tutorial.md')
        assert sha(HERE/h/'final.md')==sha(ROOT/'commons/maps'/h/'final.md')
        image=scopes['map:'+h].get('image');photo=''
        if image and (ROOT/image['path']).is_file():
            photo=f'<figure><img loading="lazy" src="/book-review/{image["path"]}" alt="{html.escape(image["label"])}"><figcaption>{html.escape(image["label"])} · {image["date"]}. Earlier museum capture; not a new installation of the learner study.</figcaption></figure>'
        old=(HERE/'before/commons/maps'/h/'tutorial.md').read_text(encoding='utf-8-sig')
        diff=''.join(difflib.unified_diff(old.splitlines(True),t.splitlines(True),fromfile='Before/'+h,tofile='Current/'+h))
        put(HERE/h/'tutorial.diff',diff)
        prev=f'<a href="../{HALLS[i-1]}/parallel.html">← Previous hall</a>' if i else '<a href="../index.html">← Overview</a>'
        nxt=f'<a href="../{HALLS[i+1]}/parallel.html">Next hall →</a>' if i<7 else '<a href="../index.html#tiling">Into Tiling →</a>'
        nav=f'<nav class="nav">{prev}<span>{i+1} / 8</span>{nxt}</nav>'
        spread=f'<p class="label">{h}</p><p>{html.escape(item["summary"])}</p><details><summary>Inside this hall — earlier museum image</summary>{photo}</details>{nav}<div class="spread"><section><p class="label">Left page / tutorial</p>{render(t)}</section><section><p class="label">Right page / reflection</p>{render(f)}</section></div><details><summary>Before / after tutorial</summary><pre class="changes">{html.escape(diff)}</pre></details>{nav}'
        put(HERE/h/'parallel.html',page(item['title'],spread,1))
        body+=f'<article id="{h}"><p class="label">{i+1:02d} / {h}</p><h2>{html.escape(item["title"])}</h2><p>{html.escape(item["summary"])}</p><p><b>Changed:</b> {html.escape(item["change_note"])}</p><p class="muted">Alongside it: {html.escape(item["reflection"])}</p><div class="links"><a href="{h}/parallel.html">Tutorial + reflection</a><a href="{h}/tutorial.diff">Exact changes</a><a href="{h}/lesson.gd">Learner program</a></div><details><summary>Earlier view inside the museum</summary>{photo}</details></article>'
        summary+=f'## {h} — {item["title"]}\n\n{item["summary"]}\n\n**Short AI:** {item["short"]}\n\n**Carry:** {item["carry"]}\n\n**Next:** {item["next"]}\n\n'
        for k,text in [('tutorial',t),('final',f)]: readings[k].append((h,text))
        manifest['halls'].append({'id':h,'tutorial_sha256':sha(HERE/h/'tutorial.md'),'final_sha256':sha(HERE/h/'final.md'),'image':image})
    body+='''<article id="tiling"><h2>What reaches the next room</h2><p>Arrays supplied addresses, independent instances and a reader moving through a record. Colour adds a distinction between the value, its destination and the state retained there. The returning PointBody, unchanged Palette class and explicit recorded colour values make those connections concrete.</p><p>Tiling begins at Pattern_Disco: keep a familiar arrangement and change its palette independently. The current final text already makes that invitation. This pass preserves the Tiling sequence and its existing work.</p></article><article><h2>What still needs a reader</h2><p>Paint remains the densest lesson. Its first completion point is a manual mark with an explained path from action to surface; automation is optional. Rainbow gives a quieter optional making stop. The larger museum encounters remain available without becoming compulsory reconstructions.</p><p>Native checks execute the printed sources, including inherited classes, exercise variants, synthetic XR pickup, pointer presses, ray occlusion and persistent collision. GPU checks compare selected rendered states. The assertions are teacher-authored: they do not establish independent understanding, physical headset comfort or installation of these study nodes in the live halls. Current final.md texts and museum runtime are preserved.</p></article>'''
    if evidence['import_diagnostics']:body+='<p class="muted">The imported addon produced Unicode diagnostics during editor import; lesson runtime and assertion results are recorded separately in the evidence.</p>'
    put(HERE/'index.html',page('Colour in the book',body));put(HERE/'SUMMARIES.md',summary);put(HERE/'manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    for kind,title,name in [('tutorial','Colour — complete tutorials','all.html'),('final','Colour — current reflections','final.html')]:
        md='# '+title+'\n\n12 October 2026.\n';content=f'<div class="reading"><h1>{title}</h1>'
        for h,text in readings[kind]:
            md+='\n---\n\n<!-- hall:'+h+' -->\n\n'+text+'\n'
            content+=f'<article id="{h}"><p class="label">{h}</p>{render(text)}</article>'
        put(HERE/('ALL_TUTORIALS.md' if kind=='tutorial' else 'ALL_FINAL.md'),md);put(HERE/name,page(title,content+'</div>'))
    with zipfile.ZipFile(HERE/'colour-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in HERE.rglob('*'):
            if not p.is_file() or any(x in p.relative_to(HERE).parts for x in ['before','__pycache__','variants','logs']):continue
            if p.suffix in ['.md','.gd','.py','.json','.diff','.godot']: z.write(p,p.relative_to(HERE))
    print('Published eight canonical Colour tutorials, paired pages, complete readings, diffs and review ZIP.')

if __name__=='__main__':main()
