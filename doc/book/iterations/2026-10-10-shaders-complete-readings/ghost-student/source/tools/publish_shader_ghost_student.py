"""Publish the fresh-context student's evidence separately from author regressions."""
from pathlib import Path
import hashlib, json, re, shutil, html, difflib
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import markdown
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaders-ghost-student'
STUDENT=OUT/'student'
HALLS=[
 ('shaping','Shader_01_Shaping','Shaping','start'),
 ('patterns','Shader_05_Patterns','Patterns','start'),
 ('materials','Shader_11_QueerRubber','Materials','height'),
 ('water','Shader_09_FBM','Water','quarter-phase'),
 ('pink','Shader_12_PinkExtravaganza','Pink','composed'),
 ('field','Shader_10_ReactionDiffusion','State','boundary-after-step'),
]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def md(s): return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def main():
    assert (STUDENT/'REPORT.md').exists() and (STUDENT/'results.json').exists()
    runs=json.loads((STUDENT/'runs.json').read_text())
    rows=[];checks=0
    for lesson,map_name,title,shot in HALLS:
        text=(ROOT/'commons/maps'/map_name/'tutorial.md').read_text(encoding='utf8')
        blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',text,re.S))
        for filename,code in blocks.items():
            assert (STUDENT/lesson/'original'/filename).read_text(encoding='utf8')==code+'\n',(lesson,filename)
        versions=[]
        for mode in ['original','variation']:
            run=[r for r in runs if r['lesson']==lesson and r['mode']==mode][-1]
            assert run['exit_code']==0 and run['observations'],run
            log=(STUDENT/run['log'].replace('\\','/')).read_text(encoding='utf8')
            assert not any(s in log for s in ['SCRIPT ERROR:','SHADER ERROR:','Parse Error:']),run
            assertions=[o for batch in run['observations'] for o in batch['observations'] if 'check' in o]
            assert assertions and all(o['passed'] for o in assertions),run
            assert all(batch['errors']==0 for batch in run['observations']),run
            checks+=len(assertions)
            versions.append({'mode':mode,'assertions':len(assertions),'log':run['log'].replace('\\','/'),'log_sha256':sha(STUDENT/run['log'].replace('\\','/'))})
        changed=[name for name in blocks if (STUDENT/lesson/'original'/name).read_bytes()!=(STUDENT/lesson/'variation'/name).read_bytes()]
        assert changed,lesson
        predictions=(STUDENT/lesson/'PREDICTION.md').read_text(encoding='utf8')
        rows.append({'lesson':lesson,'map':map_name,'title':title,'runs':versions,'prediction':predictions.strip(),'variation_changes':changed,'files':{name:sha(STUDENT/lesson/'original'/name) for name in blocks}})
    launcher=json.loads((OUT/'launcher-check.json').read_text());assert launcher['passed']
    museum=json.loads((OUT/'museum/report.json').read_text());assert museum['passed']
    sequence=ROOT/'commons/maps/sequences/shaders.json'
    sequences=json.loads(sequence.read_text(encoding='utf8'));current=sequences['sequences']['shaders']
    current['learning_objectives_status']=f'Six focused drafts reconstructed in order by a fresh-context AI ghost student: six printed programs, six independent variations, {checks} new GPU assertions. Printed lesson code unchanged. Supplied Shaping launcher repaired and separately checked. Physical headset, human learning and automatic cross-hall persistence remain untested.'
    history={'date':'2026-10-10','scope':'Whole shader ghost student','decision':'Keep six-hall order and required code. Clarify guided versus independent variation in Materials and Shaping placement; repair supplied Shaping entry against saved travel.','guide':'doc/book/iterations/2026-10-10-shaders-ghost-student/index.html','status':f'{checks} fresh student assertions; 42 supplied-launcher configuration checks; 5 native Shaping entry checks. Synthetic AI evidence, not a human/headset trial.'}
    current['local_review_history']=[h for h in current['local_review_history'] if h.get('scope')!='Whole shader ghost student']+[history]
    sequence.write_text(json.dumps(sequences,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    total={'date':'2026-10-10','passed':True,'halls':rows,'fresh_student_assertions':checks,'independent_variations':6,'original_programs':6,'launcher_config_assertions':len(launcher['checks']),'fresh_museum_launcher_assertions':len(museum['checks']),'student_report_sha256':sha(STUDENT/'REPORT.md'),'input_hashes':{p.name:sha(p) for p in (OUT/'packet').glob('*.md')},'scope':'Fresh-context AI student, sequential six-hall reading and independently written GPU probes/variations. Prepared project dependencies, isolated rendered host, synthetic movement. Parent support regressions listed separately. Not a human learner, headset test or proof of learning.'}
    total['current_text_hashes']={name:{track:sha(ROOT/'commons/maps'/name/(track+'.md')) for track in ['tutorial','final']} for _,name,_,_ in HALLS}
    (OUT/'validation.json').write_text(json.dumps(total,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    css='*{box-sizing:border-box}body{margin:0;background:#ede9df;color:#243333;font:18px/1.65 Georgia,serif}main{max-width:1240px;margin:auto;padding:34px}h1{font-size:clamp(36px,5vw,62px);line-height:1.1}h2{line-height:1.2}nav,.meta,figcaption,table{font:14px/1.5 system-ui}nav{display:flex;gap:20px;flex-wrap:wrap;margin-bottom:30px}a{color:#24695e}.note{background:#dce9df;padding:24px;border-left:5px solid #416c5d}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}img{display:block;width:100%}figure{margin:14px 0}figcaption{padding-top:8px}.card{background:#faf8f1;padding:25px;margin:30px 0}code{font-size:.85em}pre{overflow:auto;background:#173437;color:#fff;padding:20px}td,th{padding:12px;text-align:left;border-bottom:1px solid #b6bbb1}table{width:100%;border-collapse:collapse}section{margin-top:40px}@media(max-width:800px){.pair{display:block}main{padding:18px}}'
    nav='<nav><a href="index.html">Evidence</a><a href="student.html">Student reading</a><a href="fixes.html">Repairs</a><a href="validation.json">Results</a><a href="http://localhost:3003/book-review/doc/book/iterations/2026-10-10-shaders-complete-readings/parallel.html">Revised facing pages</a></nav>'
    def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style><main>'+nav+body+'</main></html>'
    student_reading=(STUDENT/'REPORT.md').read_text(encoding='utf8')
    for lesson,_,_,_ in HALLS:student_reading=student_reading.replace(']('+lesson+'/','](student/'+lesson+'/')
    (OUT/'student.html').write_text(page('Shaders / ghost student reading',md(student_reading)),encoding='utf8')
    fixes=(OUT/'FIXES.md').read_text(encoding='utf8')
    diffs=[]
    for original in (OUT/'before').rglob('*'):
        if not original.is_file():continue
        rel=original.relative_to(OUT/'before');current=ROOT/rel
        if current.exists():
            diff=''.join(difflib.unified_diff(original.read_text(encoding='utf8').splitlines(True),current.read_text(encoding='utf8').splitlines(True),fromfile=str(rel)+' before',tofile=str(rel)+' after'))
            if diff:diffs.append('<h2>'+html.escape(str(rel))+'</h2><pre>'+html.escape(diff)+'</pre>')
            target=OUT/'current'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(current,target)
    (OUT/'fixes.html').write_text(page('Shaders / repairs after the student',md(fixes)+''.join(diffs)),encoding='utf8')
    cards=[]
    for row,(_,_,_,shot) in zip(rows,HALLS):
        lesson=row['lesson'];pics=[]
        for mode in ['original','variation']:
            p=STUDENT/lesson/(mode+'-'+shot+'.png')
            if not p.exists():
                candidates=sorted((STUDENT/lesson).glob(mode+'-*.png'));assert candidates,(lesson,mode);p=candidates[0]
            relative=p.relative_to(OUT).as_posix()
            pics.append('<figure><a href="'+relative+'"><img loading="lazy" src="'+relative+'" alt="'+html.escape(row['title']+' '+mode+' GPU probe')+'"></a><figcaption>'+mode.title()+' · isolated GPU test view</figcaption></figure>')
        cards.append('<section class="card"><h2>'+html.escape(row['title'])+'</h2>'+md(row['prediction'])+'<div class="pair">'+''.join(pics)+'</div><p>'+str(sum(r['assertions'] for r in row['runs']))+' fresh assertions across original and independent variation.</p></section>')
    body='<p class="meta">ENDLESS MUSEUM / SIX SHADER LESSONS / 10 OCTOBER 2026</p><h1>Can the next reader rebuild it?</h1><div class="note">All six original programs and six independent variations pass '+str(checks)+' fresh student assertions. Separate author checks: '+str(len(launcher['checks']))+' launcher settings checks and '+str(len(museum['checks']))+' checks in the actual Shaping museum hall.</div><p>The student received a frozen copy of the preface, complete tutorial and companion reflections. It did not receive the earlier tests or solutions. Each new variation had a prediction before execution. The first failed attempts remain in the logs; harness errors are distinguished from manuscript defects.</p><p>This is an AI reconstruction with synthetic controls and isolated GPU views. The images below are measured shader studies; the museum capture near the end verifies the repaired supplied launcher. Physical headset input and human understanding remain untested.</p><p><a href="student.html">Read the student’s full assessment →</a> · <a href="fixes.html">See what was fixed →</a></p>'+''.join(cards)+'<h2>Opening the actual museum</h2><figure><img loading="lazy" src="museum/shaping-after-launch-fix.png" alt="Repaired Shaping launcher study in the actual Endless Museum"><figcaption>Actual Shaping hall after a saved-travel fixture requested a different chapter. Native Godot capture; supplied launcher regression, separate from the independent student.</figcaption></figure>'
    (OUT/'index.html').write_text(page('Shaders / ghost student',body),encoding='utf8')
    (OUT/'README.md').write_text('# Shader ghost student\n\nRead index.html, student/REPORT.md and FIXES.md. packet/ retains the exact student input. student/ contains extracted originals, independent variations, predictions, probes, logs and captures. run.py accepts each lesson or all, then original/variation. Requires the existing AdaResearch_46 Godot project and named support dependencies. Parent launcher checks are separate. validation.json verifies the latest runs, current canonical code equality and six distinct variations. This is AI/synthetic evidence, not a human or headset trial.\n',encoding='utf8')
    source=OUT/'source/tools';source.mkdir(parents=True,exist_ok=True)
    shutil.copy2(Path(__file__),source/Path(__file__).name)
    class LinkCheck(HTMLParser):
        def __init__(self):super().__init__();self.links=[];self.ids=[]
        def handle_starttag(self,tag,attrs):
            self.links.extend(v for k,v in attrs if k in ('src','href'))
            self.ids.extend(v for k,v in attrs if k=='id')
    for p in OUT.glob('*.html'):
        parser=LinkCheck();parser.feed(p.read_text(encoding='utf8'))
        assert len(parser.ids)==len(set(parser.ids)),p
        for link in parser.links:
            u=urlsplit(link)
            if u.scheme or u.path.startswith('/'):continue
            if u.path:assert (p.parent/unquote(u.path)).exists(),(p,link)
            elif u.fragment:assert unquote(u.fragment) in parser.ids,(p,link)
    print(json.dumps({'student_assertions':checks,'halls':6,'variations':6,'output':str(OUT)}))
if __name__=='__main__':main()
