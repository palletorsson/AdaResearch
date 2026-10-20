"""Package the editorial pass, exact lesson files and fresh native evidence."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import difflib
import hashlib
import html
import json
import re
import shutil
import zipfile
import markdown
from publish_randomness_revision import STYLE

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-review-ready'
NAV='<a href="index.html">Changes</a><a href="reviewer.html">Review brief</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="parallel.html">Facing pages</a><a href="randomness-review.zip">Review ZIP</a>'
EXTRA='''
main{max-width:1120px}section.lesson{border-top:2px solid #c8bab2;margin-top:4em;padding-top:2em}
.contents{columns:2;column-gap:35px}.contents li{break-inside:avoid}.number,.track{font:13px/1.6 system-ui;letter-spacing:.04em;color:#765063}
.spread{display:grid;grid-template-columns:1fr 1fr;gap:45px}.spread article{min-width:0}.spread h1{font-size:34px}
.footnote{border-top:1px solid #bdb3aa;margin-top:2em;font:14px/1.65 system-ui;color:#504a48}
details{margin:1.5em 0;border:1px solid #ccc0b7;padding:14px}summary{font:15px/1.5 system-ui}
button{font:14px system-ui;background:#eee6de;border:1px solid #ac9a94;padding:10px 14px;color:#34262e;cursor:pointer}
pre{tab-size:4}td,th{vertical-align:top}article>p{max-width:760px}
@media(max-width:950px){.spread{grid-template-columns:1fr}.contents{columns:1}}
@media print{button,.contents{display:none}section.lesson{break-before:page}.footnote{font-size:9pt}}
'''


def md(text):return markdown.markdown(text,extensions=['extra'])


def page(title,body,wide=False,toggle=False,expanded=False):
    stem='parallel' if wide else 'tutorial'
    reading_link=''
    if toggle:
        target=stem+('.html' if expanded else '-expanded.html')
        label='Return to the focused reading' if expanded else 'Open complete code and second readings / print view'
        reading_link=f'<p><a href="{target}">{label}</a></p>'
    if expanded:
        body=body.replace('<details>','<details open>')
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}{EXTRA}'+('main{max-width:1700px}' if wide else '')+'</style><main><nav>'+NAV+'</nav>'+reading_link+body+'</main></html>'


def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def portable(text):
    def copy(match):
        src=ROOT.parent/'ada_encyclopedia/public'/match[1].lstrip('/')
        dest=OUT/'images'/src.name
        assert src.exists(),src
        dest.parent.mkdir(exist_ok=True);shutil.copy2(src,dest)
        return ']('+dest.relative_to(OUT).as_posix()+')'
    return re.sub(r'\]\((/book-images/[^)]+)\)',copy,text)


def fragment(text,scope):
    rendered=md(text)
    return re.sub(r'(id="|href="#)(fn[^" ]+)',lambda m:m[1]+scope+'-'+m[2],rendered)


class Links(HTMLParser):
    def __init__(self):super().__init__();self.refs=[];self.ids=[];self.detail_depth=0
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.append(a['id'])
        for key in ['href','src']:
            if key in a:self.refs.append(a[key])
        if tag=='details':self.detail_depth+=1
    def handle_endtag(self,tag):
        if tag=='details':self.detail_depth-=1;assert self.detail_depth>=0


def main():
    maps=json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf-8-sig'))['sequences']['randomness']['maps']
    tests=json.loads((OUT/'tests.json').read_text(encoding='utf-8'))
    assert len(tests['results'])==14 and tests['all_passed'] and tests['total_checks']==420
    texts={};stats=[];diffs=[];changed=[]
    for m in maps:
        texts[m]={}
        counts={}
        for track in ['tutorial','final']:
            source=ROOT/'commons/maps'/m/(track+'.md')
            current=source.read_text(encoding='utf-8-sig')
            before=(OUT/'before'/m/(track+'.md')).read_text(encoding='utf-8-sig')
            texts[m][track]=portable(current)
            assert re.findall(r'<!-- @.*?-->',before)==re.findall(r'<!-- @.*?-->',current),(m,track)
            assert re.findall(r'```gdscript\s*\n(.*?)```',before,re.S)==re.findall(r'```gdscript\s*\n(.*?)```',current,re.S),(m,track)
            def words(s):return len(re.sub(r'```.*?```','',s,flags=re.S).split())
            counts[track]={'before':words(before),'after':words(current)}
            if current.rstrip()!=before.rstrip():
                changed.append(source.relative_to(ROOT).as_posix())
                diff=''.join(difflib.unified_diff(before.splitlines(True),current.splitlines(True),fromfile=f'before/{m}/{track}.md',tofile=f'after/{m}/{track}.md'))
                dest=OUT/'changes'/m/(track+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(diff,encoding='utf-8')
                diffs.append('<details><summary>'+html.escape(m+' / '+track+'.md')+'</summary><pre>'+html.escape(diff)+'</pre></details>')
            counts[track]['sha256']=sha(source)
        stats.append({'map':m,**counts})
        blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts[m]['tutorial'],re.S))
        result=next(r for r in tests['results'] if r['map']==m)
        for name,code in blocks.items():
            path=OUT/'learner'/m/name
            assert path.read_text(encoding='utf-8')==code+'\n'
            assert sha(path)==result['printed_sha256'][name]
        rendered=fragment(texts[m]['tutorial'],m)
        printed=re.findall(r'```gdscript\s*\n(.*?)```',texts[m]['tutorial'],re.S)
        visible=[html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',rendered,re.S)]
        assert len(printed)==len(visible) and all(a.rstrip().expandtabs(4)==b.rstrip() for a,b in zip(printed,visible)),m
    intro='Fourteen halls inside Endless Museum. This chapter follows Wavefunctions and leads to Noise Types. The existing museum supplies the player and environment. Biome Cage remains an unnumbered encounter after Mushrooms; the closing Biome Ladder is deferred.'
    contents='<ol class="contents">'+''.join(f'<li><a href="#{m}">{html.escape(m.replace("_"," "))}</a></li>' for m in maps)+'</ol>'
    for track in ['tutorial','final']:
        title='Randomness — '+('complete tutorial' if track=='tutorial' else 'complete reflection')
        preface='# '+title+'\n\n'+intro+'\n\nRead REVIEWER.md for prerequisites, scope and evidence. This is one chapter of a longer course.\n\n'
        full=preface;body=md(preface)+f'<p><a href="{track}.md">Complete Markdown</a></p>'+contents
        for i,m in enumerate(maps,1):
            text=texts[m][track]
            full+=f'\n\n---\n\n## {i:02d} · {m}\n\n'+text
            body+=f'<section class="lesson" id="{m}"><p class="number">{i:02d} / 14 · {html.escape(m.replace("_"," "))}</p>'+fragment(text,m)+'</section>'
        (OUT/(track+'.md')).write_text(full,encoding='utf-8')
        (OUT/(track+'.html')).write_text(page(title,body,toggle=track=='tutorial'),encoding='utf-8')
        if track=='tutorial':
            (OUT/'tutorial-expanded.html').write_text(page(title,body,toggle=True,expanded=True),encoding='utf-8')
    body='<h1>Randomness — facing pages</h1><p>'+intro+'</p>'+contents
    for i,m in enumerate(maps,1):
        body+=f'<section class="lesson" id="{m}"><h2>{i:02d} · {html.escape(m.replace("_"," "))}</h2><div class="spread">'
        for track,label in [('tutorial','Tutorial · left'),('final','Reflection · right')]:
            body+='<article><p class="track">'+label+'</p>'+fragment(texts[m][track],m+'-'+track)+'</article>'
        body+='</div></section>'
    (OUT/'parallel.html').write_text(page('Randomness — facing pages',body,wide=True,toggle=True),encoding='utf-8')
    (OUT/'parallel-expanded.html').write_text(page('Randomness — facing pages',body,wide=True,toggle=True,expanded=True),encoding='utf-8')
    table='\n\n## Reading length\n\nApproximate word counts, including notes; tutorial counts exclude code.\n\n| Hall | Tutorial before → after | Reflection before → after |\n|---|---:|---:|\n'
    for r in stats:
        table+=f'|{r["map"].replace("_"," ")}|{r["tutorial"]["before"]} → {r["tutorial"]["after"]}|{r["final"]["before"]} → {r["final"]["after"]}|\n'
    report=(OUT/'REPORT.md').read_text(encoding='utf-8')
    (OUT/'index.html').write_text(page('Randomness — tightened for review',md(report+table)+'<p><a href="changes.html">Inspect the before/after text changes</a> · <a href="verification.json">Verification record</a></p>'),encoding='utf-8')
    (OUT/'reviewer.html').write_text(page('Randomness — external review brief',md((OUT/'REVIEWER.md').read_text(encoding='utf-8'))),encoding='utf-8')
    (OUT/'changes.html').write_text(page('Randomness — text changes','<h1>Text changes</h1><p>Complete GDScript blocks match the before snapshot. Changes below are prose and presentation.</p>'+''.join(diffs)),encoding='utf-8')
    tools=OUT/'tools';tools.mkdir(exist_ok=True)
    for name in ['tighten_randomness_reading.py','check_randomness_review.py','publish_randomness_review_ready.py']:
        shutil.copy2(ROOT/'tools'/name,tools/name)
    for r in tests['results']:
        dest=tools/'probes'/Path(r['probe']).name;dest.parent.mkdir(exist_ok=True);shutil.copy2(ROOT/r['probe'],dest)
    (OUT/'README.md').write_text('Start with REVIEWER.md, then tutorial.md and final.md, or their HTML versions. parallel.html places both tracks together. learner/ contains complete extracted scripts by hall. tests.json and tests/ record fresh native baseline runs. before/ and changes/ preserve this editorial pass. images/ contains previously captured museum figures, not new captures. This is a review packet, not a standalone Godot project; the prepared Endless Museum and XR Tools are required to execute the lessons. The copied tools show how this packet was made; they run from the repository tools directory.\n',encoding='utf-8')
    # Ensure the ZIP is self-contained for reading, including footnote anchors.
    checked=0
    for path in OUT.glob('*.html'):
        p=Links();p.feed(path.read_text(encoding='utf-8'))
        assert p.detail_depth==0 and len(p.ids)==len(set(p.ids)),path
        for ref in p.refs:
            u=urlsplit(ref)
            if u.scheme:continue
            if not u.path:assert not u.fragment or unquote(u.fragment) in p.ids,(path,ref)
            else:assert (OUT/unquote(u.path)).exists() or u.path in ('randomness-review.zip','verification.json'),(path,ref)
            checked+=1
    verification={'date':'2026-10-09','teaching_halls':14,'museum_spaces':15,'fresh_baseline_programs':14,'native_assertions_passed':420,'all_printed_gdscript_unchanged':True,'extracted_files_match_native_test_hashes':True,'rendered_code_parity':True,'artifact_markers_and_images_preserved':True,'local_targets_checked':checked,'changed_sources':changed,'reading_lengths':stats,'headset_tested':False,'independent_student_tested':False,'native_images':'Existing figures retained; no new capture pass.','scope':'Editorial pacing pass plus fresh existing native baseline assertions. Prior mutation and variation tests remain dated evidence.'}
    browser_record=OUT/'browser-qa.json'
    if browser_record.exists():
        verification['browser_review']=json.loads(browser_record.read_text(encoding='utf-8'))
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    archive=OUT/'randomness-review.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for path in OUT.rglob('*'):
            if not path.is_file() or path==archive or path.suffix=='.uid' or '__pycache__' in path.parts:continue
            rel=path.relative_to(OUT).as_posix()
            if path.suffix in ['.md','.html']:
                text=re.sub(r'<a href="randomness-review.zip">[^<]*</a>','Review packet',path.read_text(encoding='utf-8')).replace('[Download review ZIP](randomness-review.zip)','Review packet: this folder')
                z.writestr(rel,text)
            else:z.write(path,rel)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        names=set(z.namelist())
        for name in names:
            if not name.endswith('.html'):continue
            p=Links();p.feed(z.read(name).decode('utf-8'))
            for ref in p.refs:
                u=urlsplit(ref)
                if u.scheme or not u.path:continue
                assert (Path(name).parent/unquote(u.path)).as_posix() in names,(name,ref)
    print(json.dumps({'local_targets':checked,'zip_megabytes':round(archive.stat().st_size/1e6,2),'zip_crc_and_links':'pass','files_changed':len(changed),'native_checks':420}))


if __name__=='__main__':main()
