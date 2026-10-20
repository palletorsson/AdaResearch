"""Publish current CA sources, native hall evidence and a fresh student's record."""
from pathlib import Path
from html import escape
from urllib.parse import urlsplit, unquote
import argparse, hashlib, json, re, shutil, zipfile, difflib
import markdown
from bs4 import BeautifulSoup

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-ca-current-pass'
ORDER=json.loads((O/'packet/order.json').read_text())
SHOTS=['ring','neighbours','walking-history','address-lit','depleted','exchange','floor-and-pyramid','fractional-first-step']
CHANGES=[
 'Connect the retained Shader field to a small Boolean row. Declare the empty PointStudy host, separate lesson folders and code continuity.',
 'Separate the compact seed’s 11 → 14 → 5 neighbour counts from the installed specimen’s 11 → 7 → 5. Both follow active → fading → empty.',
 'Keep the return to Rule 30 purposeful: history and its receivers are the new subject. Shorten the reflective repetition of the rule.',
 'Make the progression from state to consequence explicit. The same zero may remove a tile, darken a patch or switch off a lamp.',
 'Read proximity first, then update order. Preserve the open route experiment and the difference between hand input and a visitor’s walk.',
 'Explain why this returns to Gray–Scott after Shaders: isolate exchange in matched fields. Identify the different stencil, size and rates.',
 'Name the return to the row as a comparison of procedures. Recursion remains a supplied recipe here, with its fuller study in Fractals.',
 'Separate prescribed predictions from learner choice. Keep storage, difference count, peak and displayed gain distinct; widening alone does not establish chaos.'
]
SUMMARIES=[
 'Carry the small pickable point as a reader of three ordered Boolean states. Build one row from eight answers, write all next values from the same old row, wrap the ends and keep copied history. Moving the reader chooses an address; its trigger advances time. Test another seed without changing the rule.',
 'Carry the point as STEP while one address gains empty, active and fading states. Build a small finite volume, count only active cells in its 26-neighbour surroundings and follow a fading state that cannot immediately restart. Compare the transition with the larger museum specimen while keeping their different seeds explicit.',
 'Return to a simpler row and keep independent generations. Map the same record to a horizontal deck and an upright screen; use the point to read earlier rows without undoing later ones. Change a receiver while preserving the record and distinguish a drawn gap from missing physical support.',
 'Use a two-dimensional present and Life’s eight-neighbour birth/survival rule. Follow a glider through fixed addresses, then connect one address to a lamp. Disconnect that output without changing the cells. The carried point steps the field; it does not plant or drag the pattern.',
 'Let the held point’s local position enter the rule. Nearby tiles lose a fractional state; sufficiently healthy neighbours permit recovery. Separate the threshold for helping from the threshold for support. After using the input, compare simultaneous updates with an ordered scan and return to the installed walkable bridge.',
 'Store U/V in a small model class and plant the same patch into two fields. Hold the local reaction fixed while one field lacks neighbour exchange. Predict a receiving address before stepping, change the view without changing state, and relate this smaller CPU comparison to the preceding Shader field.',
 'Compare a Rule 90 history with a supplied recursive cube placement. Change the row’s seed while the cubes remain fixed; investigate resemblance without treating it as identical construction. The point inspects and steps again. The fixed recipe prepares a question for Fractals rather than adding a second required algorithm lesson.',
 'Copy a beginning, change one address, and keep both update procedures and their forcing matched. Follow the difference through integer or fractional storage, measurements and selected sections. Use the point to inspect a slice. Finish with a chosen variation or optional recorded intervention that connects an earlier tool to a new question.'
]

def read(p): return p.read_text(encoding='utf-8-sig')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
def dump(p,x):write(p,json.dumps(x,ensure_ascii=False,indent=2)+'\n')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])

CSS='''*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#1a3034;font:18px/1.65 Georgia,serif}main{max-width:1500px;margin:auto;padding:34px}h1{font-size:clamp(34px,5vw,60px);line-height:1.1}h2,h3{line-height:1.25}nav,.meta,figcaption,table,summary{font:14px/1.5 system-ui}nav{display:flex;flex-wrap:wrap;gap:12px 24px;margin:18px 0}a{color:#1c655e}article{min-width:0;padding:26px;background:#faf8f1}article h1{font-size:34px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start}.reading{max-width:920px;margin:auto}img{display:block;width:100%;height:auto}figure{margin:24px 0}figcaption{padding-top:8px}pre{overflow:auto;max-width:100%;background:#183238;color:#fff;padding:20px;font:13px/1.55 Consolas,monospace;tab-size:4}code{overflow-wrap:anywhere;font-size:.85em}pre code{font-size:inherit;overflow-wrap:normal}table{width:100%;border-collapse:collapse}td,th{padding:12px;border-bottom:1px solid #bbc4bf;text-align:left;vertical-align:top}section{margin:40px 0}.card{background:#faf8f1;padding:26px;margin:30px 0}.note{background:#dbe8df;padding:22px;border-left:5px solid #437063}.chips{display:flex;flex-wrap:wrap;gap:8px}.chips a{padding:7px 12px;border:1px solid #a0b6ad;text-decoration:none}details{margin:18px 0}footer{padding:30px;font:13px/1.5 system-ui;border-top:1px solid #b9c4bd}.footnote{font-size:.88em}@media(max-width:900px){.pair{display:block}main{padding:16px}article{padding:16px}article+article{margin-top:25px}}@media print{nav{display:none}pre{white-space:pre-wrap}article{break-inside:auto}}'''

def page(title,body):
    nav='<nav><a href="index.html">Sequence report</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Full reflection</a><a href="student.html">Ghost student</a><a href="changes.html">Changes</a><a href="cellular-automata-review.zip">Review ZIP</a></nav>'
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><style>'+CSS+'</style></head><body><main>'+nav+body+'</main><footer>Endless Museum · 10 October 2026 · Native desktop evidence and AI reconstruction; physical headset and human learning remain untested.</footer></body></html>'

def prepare(raw,hall):
    parts=re.split(r'(```.*?```)',raw,flags=re.S)
    def fix(m):
        local=m[2]
        if not local.startswith('images/'): return m.group()
        p=R/'commons/maps'/hall/local;dest=O/'assets'/hall/p.name
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        return '!['+m[1]+']('+dest.relative_to(O).as_posix()+')'
    return ''.join(p if i%2 else re.sub(r'!\[([^\]]*)\]\(([^)]+)\)',fix,p) for i,p in enumerate(parts))

def render(raw,prefix):
    soup=BeautifulSoup(md(raw),'html.parser')
    code=re.findall(r'```[^\n]*\n(.*?)\n```',raw,re.S)
    tags=soup.select('pre > code');assert len(code)==len(tags)
    for tag,s in zip(tags,code):tag.string=s+'\n'
    for tag in soup.find_all(id=True):tag['id']=prefix+'-'+tag['id']
    for tag in soup.find_all('a',href=True):
        if tag['href'].startswith('#'):tag['href']='#'+prefix+'-'+tag['href'][1:]
    return str(soup)

def validate_student(student,code_manifest):
    base=O/'student'
    runs=student['runs']
    assert set(runs)=={h+'/'+v for h in ORDER for v in ['original','variation']}
    pre=json.loads(read(base/'source_hashes_before_run.json'))
    predictions=json.loads(read(base/'pre_run_manifest.json'))
    assert sha(base/'PREDICTIONS.md')==predictions['predictions_sha256']
    originals={(x['hall'],x['name']):x['sha256'] for x in code_manifest}
    summaries=[]
    for h in ORDER:
        counts={}
        for v in ['original','variation']:
            latest=runs[h+'/'+v]['latest']
            assert latest['effective_exit_code']==0 and latest['engine_exit_code']==0,(h,v)
            assert not latest['timeout'] and not latest['errors'],(h,v)
            receipt=Path(latest['checks_file'])
            assert receipt.resolve().is_relative_to(base.resolve())
            checks=json.loads(read(receipt))
            assert checks==latest['checks'] and checks['passed']
            assert checks['hall']==h and checks['variant']==v
            assert checks['checks'] and all(c['passed'] for c in checks['checks'])
            command=json.loads(read(receipt.parent/'command.json'))
            assert '--headless' not in command and 'gl_compatibility' in command
            assert Path(latest['latest_log']).stat().st_size>0
            assert any(receipt.parent.glob('*.png')),(h,v,'missing render')
            for name,digest in pre[h][v].items():
                assert sha(base/h/v/name)==digest==latest['source_hashes'][name],(h,v,name)
                if v=='original': assert digest==originals[h,name],(h,name,'printed mismatch')
            counts[v]=len(checks['checks'])
        assert pre[h]['original']!=pre[h]['variation'],h
        summaries.append({'hall':h,**counts})
    return {'passed':True,'originals':8,'independent_variations':8,
            'assertions':sum(r['original']+r['variation'] for r in summaries),
            'per_hall':summaries,'predictions_unchanged':True,'printed_source_parity':True}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--draft',action='store_true');args=parser.parse_args()
    museum=json.loads(read(O/'museum-runs.json'));assert len(museum)==8 and all(x['passed'] for x in museum)
    checks=sum(x['checks'] for x in museum)
    diagnostics={h:sorted(set(re.findall(r'^ERROR:.*$',read(O/'museum'/h/'engine.log'),re.M))) for h in ORDER}
    dump(O/'museum-diagnostics.json',{'engine_error_free':not any(diagnostics.values()),'messages':diagnostics,
        'scope':'Assertions passed; these logged project integration diagnostics remain unresolved by the text pass.'})
    student_file=O/'student/results.json'
    if not args.draft: assert student_file.exists() and (O/'student/REPORT.md').exists()
    student=json.loads(read(student_file)) if student_file.exists() and (O/'student/REPORT.md').exists() else None
    write(O/'reading.css',CSS)
    texts={}; rows=[];code_manifest=[];sources={}
    for i,h in enumerate(ORDER):
        for t in ['tutorial','final']:
            src=R/'commons/maps'/h/(t+'.md');dst=O/'sources'/h/src.name
            dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
            raw=read(src);texts[h,t]=prepare(raw,h);sources[f'{h}/{t}.md']=sha(src)
            old=read(O/'before'/h/src.name)
            write(O/'diffs'/h/(t+'.diff'),''.join(difflib.unified_diff(old.splitlines(True),raw.splitlines(True),fromfile='before/'+h+'/'+t+'.md',tofile='current/'+h+'/'+t+'.md')))
            original_blocks=re.findall(r'```gdscript\n(.*?)\n```',old,re.S)
            current_blocks=re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S)
            if t=='tutorial':
                assert [b for _,b in current_blocks]==original_blocks,h
                for name,code in current_blocks:
                    dest=O/'student-files'/h/name;write(dest,code+'\n')
                    assert read(R/'doc/book/studies/cellular-automata-through-the-hands'/h/name)==code+'\n'
                    code_manifest.append({'hall':h,'name':name,'sha256':sha(dest),'path':dest.relative_to(O).as_posix()})
            else: assert not original_blocks and not current_blocks
        title=read(R/'commons/maps'/h/'tutorial.md').splitlines()[0].lstrip('# ')
        rows.append({'hall':h,'title':title,'summary':SUMMARIES[i],'change':CHANGES[i],'museum_checks':museum[i]['checks']})
    assert len(code_manifest)==19
    assert len({x['sha256'] for x in code_manifest if x['name']=='point_body.gd'})==1
    dump(O/'editorial-checks.json',[{'hall':key.split('/')[0],'track':key.split('/')[1][:-3],
                                  'sha256':digest,'printed_code_unchanged':True}
                                 for key,digest in sources.items()])
    student_validation=validate_student(student,code_manifest) if student else None
    if student_validation:dump(O/'student-verification.json',student_validation)
    dump(O/'printed-files.json',code_manifest);dump(O/'sources/halls.json',rows)
    shutil.copy2(R/'commons/maps/sequences/cellularautomata.json',O/'sources/cellularautomata.json')
    before_seq=json.loads(read(O/'before/cellularautomata.json'))['sequences']['cellularautomata']
    after_seq=json.loads(read(O/'sources/cellularautomata.json'))['sequences']['cellularautomata']
    for key in ['maps','prerequisites','unlocks','unlock_requirements','deferred_maps']:
        assert before_seq.get(key)==after_seq.get(key),key
    toc='<div class="chips">'+''.join('<a href="'+h+'.html">'+str(i+1)+'. '+escape(rows[i]['title'])+'</a>' for i,h in enumerate(ORDER))+'</div>'
    for i,h in enumerate(ORDER):
        navigation='<nav>'+('<a href="'+ORDER[i-1]+'.html">← Previous hall</a>' if i else '<a href="index.html">← Report</a>')+('<a href="'+ORDER[i+1]+'.html">Next hall →</a>' if i<7 else '<a href="student.html">Ghost assessment →</a>')+'</nav>'
        body='<p class="meta">'+str(i+1)+' / 8 · '+h+'</p>'+toc+navigation+'<div class="pair"><article><p class="meta">TUTORIAL · BUILD AND INVESTIGATE</p>'+render(texts[h,'tutorial'],h+'-t')+'</article><article><p class="meta">FINAL · REFLECTIVE ENCOUNTER</p>'+render(texts[h,'final'],h+'-f')+'</article></div>'+navigation
        write(O/(h+'.html'),page(rows[i]['title'],body))
        if i==0:write(O/'parallel.html',page(rows[i]['title'],body))
    for t in ['tutorial','final']:
        combined='# Cellular Automata — '+('complete tutorial' if t=='tutorial' else 'complete reflective sequence')+'\n\n'+('\n\n---\n\n'.join(texts[h,t] for h in ORDER))
        write(O/(t+'.md'),combined)
        write(O/(t+'.html'),page('Cellular Automata — '+t,'<div class="reading">'+render(combined,t)+'</div>'))
    report='''# What a neighbour can change

The eight-hall progression holds. This pass makes its returning operations easier to follow: a row becomes a volume, a past becomes a structure, a moving pattern keeps fixed addresses, and the visitor becomes an input. Later halls isolate exchange, compare ways of making and measure what one difference retains.

Both canonical text tracks have been revised. Each tutorial names the functions that carry its new idea, retains complete code and ends with a choice whose answer is not supplied. The reflective passages spend less time repeating implementation and make the return from Shaders explicit. Nineteen printed files remain byte-equivalent to the prior programs, including one unchanged PointBody across all eight lessons.

The compact volume and the installed specimen use different seeds. Their active-neighbour counts are now explicitly distinguished. Guided edits are called guided; the learner then chooses another case. Reaction–diffusion returns to isolate exchange, using a different stencil, grid and rates from the Shader field. It is not a promise of matching pictures.

The historical map IDs remain for compatibility. The sequence’s displayed titles and learning objectives now describe the actual lessons. The old completion-time estimate was unmeasured and has been replaced by a self-paced description. Route order, museum geometry, artifacts and algorithms are unchanged.

## Eight stops

| Hall | New work and carried capacity | Change in this pass |
| --- | --- | --- |
'''
    for row in rows:report+='| '+row['title']+' (`'+row['hall']+'`) | '+row['summary']+' | '+row['change']+' |\n'
    report+='\n## Evidence\n\n'+str(checks)+' checks passed in eight fresh native museum runs. These reuse the established encounter probes against today’s halls, with isolated save/output files, Compatibility rendering, synthetic XR controller poses and sampled physical routes. Screenshots below are fresh captures from those runs. They are not a new physical headset trial.\n\n'
    if any(diagnostics.values()):
        report+='The museum logs are not error-free: all eight report an unresolved default audio-bus UID; the proximity hall also logs two unset viewport textures from the separate catalyst prompter. The CA assertions still pass. These project integration diagnostics are preserved in [museum-diagnostics.json](museum-diagnostics.json); their wider audio/catalyst effects were not repaired or certified by this manuscript pass. The isolated student runtime has neither error.\n\n'
    if student:
        report+='A fresh-context ghost student reconstructed all eight exact lessons and chose eight source variations. All sixteen latest rendered runs passed '+str(student_validation['assertions'])+' assertions, including repeated per-cell and receiver checks. Printed sources match the canonical text; the original predictions remain unchanged. The student’s reading, variations, preserved harness failures and final outcomes are in [the student report](student.html). This is independent AI reconstruction evidence, separate from the museum regressions.\n\nAfter that review, the first tutorial now names the two XRTools autoloads already supplied by the museum. This setup clarification changes no code. The original student packet remains frozen.\n\n'
    else:report+='Fresh-context student reconstruction is in progress. No student pass is claimed in this draft.\n\n'
    report+='''## Where attention is still needed

The move to a three-dimensional address in hall two is the first increase in load. Follow one cell before surveying the whole volume. The proximity hall has two passes: use the input, then compare update schedules. Neighbour exchange returns to familiar U/V state with changed numerical conditions; compare within that experiment. Recursion in hall seven is supplied and revisited in Fractals. In the final hall, read the measurements before interpreting a brighter picture.

The code examples are complete small reconstructions inside the established museum project. Their parameters sometimes use desktop keys; the installed exhibits have the broader VR interfaces. Reusing the point means code and visual continuity, not automatic transport of a live object or state between halls.

## Review this chapter

Read tutorial.md for the complete constructions and final.md for the reflective walk. The facing pages keep tutorial on the left. Follow one invariant through the chapter: addresses stay, while states, inputs and receivers change. Challenge any unsupported assumption, unclear coordinate conversion or claim that confuses the miniature with the installed work. Do not evaluate this as a first programming lesson or a standalone project with no Day Zero dependencies.
'''
    write(O/'REPORT.md',report)
    gallery=''
    for i,h in enumerate(ORDER):
        folder=O/'museum'/h;shot=folder/(SHOTS[i]+'.png');assert shot.exists()
        gallery+='<section class="card"><h2>'+str(i+1)+'. '+escape(rows[i]['title'])+'</h2><p>'+escape(SUMMARIES[i])+'</p><figure><img loading="lazy" src="'+shot.relative_to(O).as_posix()+'" alt="'+escape(rows[i]['title'])+' in the current museum"><figcaption>Fresh native museum capture · '+str(museum[i]['checks'])+' passing checks. <a href="museum/'+h+'/report.json">Receipt</a> · <a href="'+h+'.html">Read both texts</a></figcaption></figure>'
        overhead=folder/'overhead.png'
        if overhead.exists():gallery+='<details><summary>View this hall from above</summary><img loading="lazy" src="'+overhead.relative_to(O).as_posix()+'" alt="Hall layout from above"></details>'
        gallery+='</section>'
    write(O/'index.html',page('Cellular Automata — current review',toc+md(report)+gallery))
    changes='<h1>Before and after</h1><p>The before snapshot is the text at the start of this pass. All printed code remains identical.</p>'
    for i,h in enumerate(ORDER):
        changes+='<section><h2>'+escape(rows[i]['title'])+'</h2><p>'+escape(CHANGES[i])+'</p>'
        for t in ['tutorial','final']:
            changes+='<details><summary>'+t+'.md — exact textual diff</summary><pre>'+escape(read(O/'diffs'/h/(t+'.diff')))+'</pre></details>'
        changes+='</section>'
    write(O/'changes.html',page('CA — text changes',changes))
    sreport=read(O/'student/REPORT.md') if student else '# Ghost student\n\nReconstruction is in progress.'
    student_html=BeautifulSoup(md(sreport),'html.parser')
    for tag in student_html.find_all(['a','img']):
        attr='href' if tag.name=='a' else 'src'
        url=tag.get(attr,'');parts=urlsplit(url)
        if url and not parts.scheme and not parts.netloc and parts.path:tag[attr]='student/'+url
    student_gallery=''
    if student:
        student_gallery='<h2>Reconstructed studies</h2><p>Neutral rendered test hosts, separate from the installed museum captures. Each pair runs the printed original and a source variation chosen by the student.</p>'
        for i,h in enumerate(ORDER):
            student_gallery+='<section><h3>'+escape(rows[i]['title'])+'</h3><div class="pair">'
            for v in ['original','variation']:
                run=student['runs'][h+'/'+v]['latest']
                shot=Path(run['checks_file']).parent/'screenshot.png'
                student_gallery+='<figure><img loading="lazy" src="'+shot.relative_to(O).as_posix()+'" alt="'+escape(h+' '+v)+'"><figcaption>'+v.capitalize()+' · '+str(len(run['checks']['checks']))+' checks</figcaption></figure>'
            student_gallery+='</div><p><a href="student/'+h+'/prediction.md">Prediction</a> · <a href="student/'+h+'/source_variation.diff">Source variation</a></p></section>'
    write(O/'student.html',page('CA — ghost student','<div class="reading">'+str(student_html)+'</div>'+student_gallery+'<p><a href="student/results.json">Machine-readable student evidence</a></p>' if student else md(sreport)))
    write(O/'README.md','# Cellular Automata review\n\nOpen index.html, or read tutorial.md and final.md separately. Eight current canonical halls, complete printed code in student-files/, exact manuscript copies in sources/, first baseline in before/, fresh museum receipts in museum/, independent AI reconstruction in student/. Godot 4.6 and the declared AdaResearch museum/XRTools project are required to run the study files; this ZIP is a review packet, not a standalone Godot project.\n')
    refs=0
    for p in O.glob('*.html'):
        soup=BeautifulSoup(read(p),'html.parser')
        for tag in soup.find_all(['a','img','link']):
            u=tag.get('href') or tag.get('src')
            if not u:continue
            parts=urlsplit(u)
            if parts.scheme or parts.netloc or not parts.path or parts.path=='cellular-automata-review.zip':continue
            target=(p.parent/unquote(parts.path)).resolve()
            assert target.exists(),(p,u)
            refs+=1
    validation={'canonical_sha256':sources,'printed_files':len(code_manifest),'printed_code_unchanged':True,'unchanged_point_body':True,'route_and_prerequisite_ids_unchanged':True,'fresh_museum_assertions':checks,'museum_passed':True,'museum_engine_error_free':not any(diagnostics.values()),'student_result_present':bool(student),'student_validation':student_validation,'html_local_targets_checked':refs,'draft':args.draft}
    dump(O/'publication-checks.json',validation)
    if not args.draft:
        # Include evidence and sources, excluding engine import caches and runner-produced save state.
        archive=O/'cellular-automata-review.zip'
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
            for p in O.rglob('*'):
                if not p.is_file() or p==archive or p.suffix in ['.import','.uid','.pyc'] or '__pycache__' in p.parts or '.godot' in p.parts:continue
                z.write(p,p.relative_to(O).as_posix())
        with zipfile.ZipFile(archive) as z:assert z.testzip() is None
        print(json.dumps({'zip_mb':round(archive.stat().st_size/1024**2,2),'validation':validation}))
    else:print(json.dumps(validation))

if __name__=='__main__':main()
