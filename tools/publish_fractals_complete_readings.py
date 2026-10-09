"""Collect the current seven-hall texts verbatim and include the editorial revision."""
from pathlib import Path
from urllib.parse import urlsplit, unquote
from html import escape
import hashlib, json, re, shutil, zipfile
import markdown
from bs4 import BeautifulSoup

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-08-fractals-complete-readings'
SEQ=R/'commons/maps/sequences/fractals.json'
REVISION=R/'doc/book/iterations/2026-10-08-fractals-a-question-of-your-own'
order=json.loads(SEQ.read_text(encoding='utf-8-sig'))['sequences']['fractals']['maps']
assert len(order)==7
for d in ['sources','student-files','assets','evidence']:(O/d).mkdir(parents=True,exist_ok=True)
def read(p):return p.read_text(encoding='utf-8-sig')
def write(p,s):p.write_text(s,encoding='utf-8',newline='\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,obj):write(p,json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
shutil.copy2(SEQ,O/'sources/fractals.json')
labels=['Recursion','Recursive Trees','Cantor Set','Koch / Sierpinski','Menger Sponge','Golden Spiral','Synthesis']
operations=['A self-call receives a smaller size and a remaining budget.','Two calls inherit a parent transform; turn one fork and its descendants follow.','Replace an interval with two survivors; separate current, next and history.','Replace each segment with a detour; distinguish a path address from travelled distance.','Select cells in three dimensions; inspect an address and try the resulting passage.','Append the previous pair’s sum; read one record through two height functions.','Copy and compare recipes; optionally compose one earlier influence with a chosen construction, then prepare a symbolic rewrite.']
questions=['Where does more detail stop producing another usable distinction?','What travels from a local edit to a canopy, and what does a drawing leave out?','How can more pieces leave less material, and when is a gap a passage?','What changes when the boundary grows or the discarded parts become the subject?','When does a geometrical connection become a route for this body?','Which choices turn numbers into convincing forms?','Which difference is worth keeping, and how does an encounter revise its description?']
receipts={
 'Fractal_Recursion':'2026-10-08-fractal-fork-in-the-hand',
 'Fractal_RecursiveTrees':'2026-10-08-fractal-fork-in-the-hand',
 'Fractal_CantorSet':'2026-10-08-cantor-a-cut-in-the-hand',
 'Fractal_KochSierpinski':'2026-10-08-koch-the-distance-between',
 'Fractal_MengerSponge':'2026-10-08-menger-a-cell-and-a-room',
 'Fractal_GoldenSpiral':'2026-10-08-golden-two-values-two-views',
 'Fractal_Synthesis':'2026-10-08-synthesis-a-rule-kept',
}
sources=[];halls=[];assets=[];printed=[];texts={};archive_evidence=[]
def outside_code(text,fn):
    chunks=re.split(r'(```[^\n]*\n.*?```)',text,flags=re.S)
    return ''.join(part if i%2 else fn(part) for i,part in enumerate(chunks))
def prepare(text,hall,source):
    def fix(part):
        part=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+hall+'-'+m[1]+']',part)
        def image_link(m):
            url=m[2];path=urlsplit(url).path
            if urlsplit(url).scheme:return m[0]
            if path.startswith('/book-review/'):
                original=R/unquote(path[len('/book-review/'):])
            else:original=(source.parent/unquote(path)).resolve()
            assert original.is_file(),(source,url)
            dest=O/'assets'/hall/original.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(original,dest)
            record={'source':original.relative_to(R).as_posix(),'file':dest.relative_to(O).as_posix(),'sha256':sha(dest)}
            if record not in assets:assets.append(record)
            return '!['+m[1]+']('+dest.relative_to(O).as_posix()+')'
        return re.sub(r'!\[([^\]]*)\]\(([^)]+)\)',image_link,part)
    return outside_code(text,fix)
for index,hall in enumerate(order):
    row={'id':hall,'label':labels[index],'number':index+1,'operation':operations[index],'question':questions[index],'tracks':{}}
    for track in ['tutorial','final']:
        p=R/'commons/maps'/hall/(track+'.md');dest=O/'sources'/hall/p.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        sources.append({'path':p.relative_to(R).as_posix(),'copy':dest.relative_to(O).as_posix(),'sha256':sha(p)})
        raw=read(p);prepared=prepare(raw,hall,p);texts[(hall,track)]=prepared
        prose=re.sub(r'```.*?```','',raw,flags=re.S);prose=re.sub(r'<!--.*?-->','',prose,flags=re.S)
        fences=re.findall(r'```[^\n]*\n(.*?)```',raw,re.S)
        row['tracks'][track]={'title':raw.splitlines()[0].lstrip('# '),'prose_words_approx':len(prose.split()),'fenced_blocks':len(fences),'fenced_lines':sum(len(s.rstrip().splitlines()) for s in fences)}
        if track=='tutorial':
            for name,body in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S):
                learner=R/'doc/book/studies/fractals-through-the-hands'/hall/name
                assert learner.exists() and read(learner).rstrip()==body.rstrip(),(hall,name)
                target=O/'student-files'/hall/name;target.parent.mkdir(parents=True,exist_ok=True);write(target,body+'\n')
                printed.append({'hall':hall,'file':name,'sha256':sha(target),'lines':len(body.splitlines()),'study_source':learner.relative_to(R).as_posix()})
    receipt=R/'doc/book/iterations'/receipts[hall]/'evidence.json'
    if receipt.name and receipt.exists():
        target=O/'evidence'/f'{receipts[hall]}.json';shutil.copy2(receipt,target)
        data=json.loads(read(receipt));p=R/'commons/maps'/hall/'tutorial.md';old=data.get('source_sha256',{}).get(p.relative_to(R).as_posix())
        archive_evidence.append({'hall':hall,'receipt':target.relative_to(O).as_posix(),'earlier_check_count':data.get('checks'),'tutorial_hash_matches_receipt':sha(p)==old if old else None,'status':'Previously recorded run; not rerun for this compilation. Counts may cover multiple halls and must not be summed blindly.'})
    halls.append(row)
assert len(printed)==16
totals={track:{key:sum(h['tracks'][track][key] for h in halls) for key in ['prose_words_approx','fenced_blocks','fenced_lines']} for track in ['tutorial','final']}
css='''*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:85px}body{margin:0;color:#242129;background:#f5f1ea;font:18px/1.65 Georgia,serif}header{position:sticky;top:0;background:#f5f1eaf5;border-bottom:1px solid #d6c9c6;z-index:4;padding:12px 4vw;font:14px/1.5 system-ui}nav{display:flex;gap:12px 24px;flex-wrap:wrap}a{color:#793b53;text-underline-offset:3px}main{max-width:1000px;margin:3rem auto;padding:0 28px}h1,h2,h3,h4{line-height:1.13;font-weight:normal;letter-spacing:-.025em}h1{font-size:clamp(2.5rem,6vw,4.8rem)}h2{font-size:2.2rem;margin-top:2.5rem}h3{font-size:1.45rem;margin-top:2rem}.eyebrow,.meta,.chapter-number{font:12px/1.6 system-ui;text-transform:uppercase;letter-spacing:.13em;color:#7b5e65}.lead{font-size:1.3rem}.chapter{border-top:2px solid #c29ca7;margin-top:5rem;padding-top:2rem}.toc{columns:2;column-gap:3rem}.toc li{break-inside:avoid;margin:10px 0}.downloads{display:flex;gap:14px;flex-wrap:wrap;margin:2rem 0}.downloads a{padding:12px 20px;background:#29242c;color:#fff;text-decoration:none;border-radius:3px}pre{font:13px/1.6 Consolas,monospace;overflow:auto;background:#242129;color:#eee9e1;padding:22px;border-radius:4px;tab-size:4}code{font: .86em Consolas,monospace}pre code{font-size:inherit}blockquote{margin:2rem 0;padding:0 1.5rem;border-left:3px solid #bf93a4;font-size:1.18rem}img{max-width:100%;height:auto}table{border-collapse:collapse;width:100%;font-size:.95rem}td,th{text-align:left;vertical-align:top;border-bottom:1px solid #d6c9c6;padding:12px}.paired{max-width:1600px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:50px}.pair article{min-width:0}.pair h2{font-size:1.8rem}.note{background:#ece3de;padding:18px 24px;border-left:3px solid #b4869b}.footnote{font-size:.9rem}.chapter-nav{font:13px system-ui;display:flex;gap:25px;justify-content:space-between;padding:20px 0}footer{max-width:1000px;margin:4rem auto;padding:20px 28px;color:#74676b;font:13px/1.6 system-ui}@media(max-width:850px){.pair{display:block}.pair article+article{border-top:1px solid #bbb;margin-top:3rem;padding-top:2rem}.toc{columns:1}}@media print{header,.downloads,.chapter-nav{display:none}body{background:white;font-size:11pt;line-height:1.5}main{max-width:none;margin:0;padding:0}.chapter{break-before:page;margin:0;border:0}h1{font-size:32pt}h2{font-size:24pt}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:8pt;background:#f3f3f3;color:#111;padding:10px}img{max-height:18cm;object-fit:contain}.pair{display:block}.pair article{break-before:page}a{color:inherit}}'''
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><link rel="stylesheet" href="reading.css"></head><body><header><nav><a href="index.html">Sequence review</a><a href="tutorial.html">Complete tutorial</a><a href="final.html">Complete reflection</a><a href="parallel.html">Side by side</a><a href="fractals-complete-readings.zip">Download everything</a></nav></header>'+body+'<footer>8 October 2026 · Current canonical texts in museum spine order. Full code retained. Original manuscripts preserved in sources/. This compilation adds no new runtime or headset certification.</footer></body></html>'
write(O/'reading.css',css)
def render(text,prefix):
    soup=BeautifulSoup(markdown.markdown(text,extensions=['fenced_code','tables','footnotes']),'html.parser')
    # Markdown expands tabs before rendering; restore exact source whitespace
    # so copying a complete block from the reading yields the tested file.
    bodies=re.findall(r'```[^\n]*\n(.*?)\n```',text,re.S)
    rendered=soup.select('pre > code');assert len(rendered)==len(bodies)
    for tag,body in zip(rendered,bodies):tag.string=body+'\n'
    for tag in soup.find_all(re.compile('^h[1-5]$')):tag.name='h'+str(int(tag.name[1])+1)
    for tag in soup.find_all(id=True):tag['id']=prefix+'-'+tag['id']
    for a in soup.find_all('a',href=True):
        if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
    return str(soup)
def toc(track):return '<ol class="toc">'+''.join(f'<li><a href="{track}.html#{h["id"]}">{escape(h["label"])} — {escape(h["tracks"][track]["title"])}</a></li>' for h in halls)+'</ol>'
for track in ['tutorial','final']:
    title='Fractals — complete '+('tutorial' if track=='tutorial' else 'reflective sequence')
    body='<main><p class="eyebrow">Endless Museum · seven halls · '+track+'.md</p><h1>'+title+'</h1><p>All seven current texts, in the active spine order. No passages or code blocks abridged.</p>'+toc(track)+f'<p><a href="fractals-{track}.md">Download this reading as Markdown</a></p>'
    combined=['# '+title+'\n\n8 October 2026. All seven current canonical manuscripts in spine order. Full code retained; source snapshots are included.\n\n']
    for i,h in enumerate(halls):
        hall=h['id'];text=texts[(hall,track)]
        body+=f'<section class="chapter" id="{hall}"><p class="chapter-number">{i+1:02d} / 07 · {escape(h["label"])}</p>'+render(text,hall+'-'+track)
        body+='<div class="chapter-nav">'+(f'<a href="#{order[i-1]}">← Previous hall</a>' if i else '<span></span>')+(f'<a href="#{order[i+1]}">Next hall →</a>' if i<6 else '<a href="index.html">Sequence review</a>')+'</div></section>'
        shifted=outside_code(text,lambda s:re.sub(r'^(#{1,5}) ',r'#\1 ',s,flags=re.M))
        combined.append('\n\n---\n\n<a id="'+hall+'"></a>\n\n**'+str(i+1).zfill(2)+' / 07 · '+h['label']+'**\n\n'+shifted.rstrip()+'\n')
    write(O/f'{track}.html',page(title,body+'</main>'))
    write(O/f'fractals-{track}.md',''.join(combined))
pair='<main class="paired"><p class="eyebrow">Two complete tracks</p><h1>Make it. Read what it changes.</h1><p>Tutorial on the left; reflective final.md on the right. Each pair begins at the same hall; paragraph lengths are left intact.</p>'+toc('tutorial').replace('tutorial.html#','#')
for h in halls:
    hall=h['id'];pair+=f'<section class="chapter" id="{hall}"><p class="chapter-number">{h["number"]:02d} / 07 · {escape(h["label"])}</p><div class="pair"><article><p class="eyebrow">Tutorial · reconstruct</p>'+render(texts[(hall,'tutorial')],hall+'-tutorial')+'</article><article><p class="eyebrow">Final · reflect</p>'+render(texts[(hall,'final')],hall+'-final')+'</article></div></section>'
write(O/'parallel.html',page('Fractals — parallel readings',pair+'</main>'))
assessment='''# How the Fractals sequence reads

The sequence now has a coherent movement: make a repeatable operation, change its inheritance, inspect its consequences at another scale, then keep a version you can reconstruct. The familiar sphere and line give the learner continuity, while their role changes. What grows is the ability to describe and modify a construction.

The strongest stretch is Cantor → Koch/Sierpinski → Menger. The same current/next pattern produces less length, more boundary and a porous volume. Its critical question also develops: a missing interval becomes an opening, then a possible route for a particular body. The transition from a handheld model to a place one can enter makes the technical and reflective tracks depend on the same encounter.

Golden Spiral is a deliberate change of pace. Its addition is simpler than the Menger selection, but its distinction is essential: numerical recurrence, geometric construction and display mapping are separate decisions. I would keep it here as a pause before Synthesis, with the existing title “A number needs a mapping” making that purpose clear. It should not have to prove that every numerical recurrence is a fractal.

The tutorials supply complete code, declared dependencies, predictions and variations. The reflections extend what the learner has made into questions of access, recognition, omission and judgment. They sometimes still duplicate the tutorial’s explanations and controls. The distinction between the tracks holds, but their rhythms could differ more.

## What this revision changes

1. **Synthesis now invites an authored composition.** The required recipe lesson remains complete. An optional task asks for one chosen connection between a Fractals construction and an earlier operation. Keep the original, declare an invariant, predict, run, inspect and revise. The tree/noise example in the review notes is one tested response, not the required answer.
2. **The reflective ending reaches its question sooner.** The interval/tree recap is shorter and three repeated source excerpts are removed. The table's local exercise is distinguished from the larger research practice of moving between description, code and bodily encounter.
3. **Menger stays with the attempted passage.** Collision dimensions and occupied-room controls remain in a note. The main text follows hole, passage and body.
4. **Koch's additional studies are explicit detours.** Box-counting and the inherited pyramid can be explored without becoming required stops in the line-to-boundary-to-volume progression.

The seven-hall order still holds. Reconstruct → predict → compose adds responsibility without requiring every lesson to become a hybrid simulation. The full helpers still repeat in the collected tutorial because each study must be complete. A future book layout may distinguish carried files more economically. Passing code checks cannot settle how the prose teaches.

The next useful test is an independent learner choosing and explaining a composition. The writing agent's feasibility example does not substitute for that encounter. An unexpected shape and a precisely anticipated shape can both be worth pursuing.

## What this package establishes

The fourteen revised canonical manuscripts are copied in full. All sixteen marked learner code blocks match their existing study files, and the combined tutorial retains those exact blocks. Included images, footnotes, chapter links and local assets are checked. Editorial before/after texts and the separate optional composition example are in review-notes/.

For this revision, the exact required Synthesis code passed 46 fresh native assertions; the optional tree/noise feasibility response passed 21. Both runs exited successfully without script errors. The latter was authored by the writing agent, not an independent student. Earlier whole-hall receipts remain historical evidence with tutorial-hash comparisons; their counts overlap and are not added into a new whole-sequence score. Headset comfort, performance and learning remain separate questions. The previously recorded Grammar Lab onward-exit obstruction was not reassessed in this editorial pass.
'''
write(O/'ASSESSMENT.md',assessment)
review=render(assessment,'assessment')
rows=''.join('<tr><td><a href="parallel.html#'+h['id']+'">'+str(h['number']).zfill(2)+' · '+escape(h['label'])+'</a></td><td>'+escape(h['operation'])+'</td><td>'+escape(h['question'])+'</td></tr>' for h in halls)
stats=f'<p class="meta">Tutorial: approximately {totals["tutorial"]["prose_words_approx"]:,} prose words + {totals["tutorial"]["fenced_lines"]:,} printed code lines · Reflection: approximately {totals["final"]["prose_words_approx"]:,} prose words</p>'
index='<main><p class="eyebrow">Endless Museum · complete Fractals sequence</p><h1>Rules, scale<br>and room to move.</h1><p class="lead">Seven halls. Two complete readings. The same work followed through making and reflection.</p><div class="downloads"><a href="tutorial.html">Read the full tutorial</a><a href="final.html">Read the full final text</a><a href="fractals-complete-readings.zip">Download the review package</a></div>'+stats+'<p><a href="parallel.html">Read the tracks side by side</a> · <a href="fractals-tutorial.md">Tutorial Markdown</a> · <a href="fractals-final.md">Final Markdown</a></p><p class="note"><a href="review-notes/index.html">Editorial revision: a question of your own</a> — optional composition task, lighter reflection, before/after texts and fresh focused checks.</p><h2>The progression</h2><table><thead><tr><th>Hall</th><th>What the learner can do</th><th>What the encounter asks</th></tr></thead><tbody>'+rows+'</tbody></table>'+review+'<p><a href="manifest.json">Source and code hashes</a> · <a href="ASSESSMENT.md">Download this assessment</a></p></main>'
write(O/'index.html',page('Fractals — complete readings and assessment',index))
readme='''# Fractals — complete readings

Open index.html. The seven halls follow the current museum spine.

- tutorial.html and fractals-tutorial.md contain the complete tutorial sequence, including all printed code.
- final.html and fractals-final.md contain the complete reflective sequence.
- parallel.html places tutorial left and reflection right, hall by hall.
- sources/ preserves the fourteen canonical source manuscripts byte for byte, plus the sequence JSON. Raw source image paths are unchanged; use the compiled readings for portable images.
- student-files/ contains the sixteen exact printed files in separate hall folders. Use them in the prepared Endless Museum workspace with installed XRTools, existing camera, lighting and player. This ZIP is not a standalone Godot project. Follow each lesson’s attachment and orientation instructions.
- ASSESSMENT.md is editorial judgment, separate from the manuscripts. This compiler reads the revised canonical texts without modifying them.
- review-notes/ records the editorial changes with before versions and diffs. Its composition-example/ holds one optional noise/tree response and instructions for running it in the museum workspace. This is a feasibility example, not a required answer or independent student submission.
- review-notes/tests/ contains fresh 46-check required Synthesis and 21-check composition runs. evidence/ contains earlier receipts; those whole-hall runs were not repeated. Counts overlap and must not be added into a whole-sequence score. manifest.json records hash comparisons and the scope of fresh evidence.

Namespaced footnotes and local image links allow the two combined readings to work without localhost. Code blocks remain unchanged. Existing external source links require internet access.
'''
write(O/'README.md',readme)
assert (REVISION/'evidence.json').is_file(), 'Publish the editorial revision first'
shutil.copytree(REVISION,O/'review-notes',dirs_exist_ok=True)
revision_evidence=json.loads(read(REVISION/'evidence.json'))
for name,digest in revision_evidence['source_sha256'].items():assert sha(R/name)==digest
# Confirm assembly did not alter any printed code, and each archive source remains current.
combined_blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',read(O/'fractals-tutorial.md'),re.S)
assert len(combined_blocks)==len(printed)
for (name,body),entry in zip(combined_blocks,printed):assert name==entry['file'] and body+'\n'==read(O/'student-files'/entry['hall']/name)
rendered_blocks=BeautifulSoup(read(O/'tutorial.html'),'html.parser').select('pre > code')
assert len(rendered_blocks)==len(printed)
for rendered,(_,body) in zip(rendered_blocks,combined_blocks):assert rendered.get_text().rstrip()==body.rstrip()
for source in sources:assert sha(R/source['path'])==source['sha256']==sha(O/source['copy'])
manifest={'date':'2026-10-08','sequence':'fractals','order':order,'source_sequence_sha256':sha(SEQ),'halls':halls,'sources':sources,'student_files':printed,'assets':assets,'totals':totals,'earlier_evidence':archive_evidence,'canonical_sources_modified_by_compiler':False,'runtime_tests_rerun_by_compiler':False,'revision_evidence':revision_evidence,'fresh_runtime_scope':'Required Synthesis:46; one writing-agent tree/noise response:21. See review-notes/tests. No whole-sequence or headset rerun.'}
dump(O/'manifest.json',manifest)
# Create archive before checking links, since pages link to the archive itself.
archive=O/'fractals-complete-readings.zip'
def pack():
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(O.rglob('*')):
            if p.is_file() and p!=archive and '__pycache__' not in p.parts:z.write(p,p.relative_to(O).as_posix())
pack()
links=0;chapters=0
for p in O.rglob('*.html'):
    soup=BeautifulSoup(read(p),'html.parser');ids=[x['id'] for x in soup.find_all(id=True)];assert len(ids)==len(set(ids)),p
    for tag in soup.find_all(['a','img','link']):
        url=tag.get('href') or tag.get('src')
        if not url:continue
        parts=urlsplit(url)
        if parts.scheme or parts.netloc:continue
        dest=(p.parent/unquote(parts.path)).resolve() if parts.path else p
        assert dest.is_relative_to(O) and dest.is_file(),(p,url)
        if parts.fragment and dest.suffix=='.html':
            target=BeautifulSoup(read(dest),'html.parser');assert target.find(id=unquote(parts.fragment)),(p,url)
        links+=1
    if p.name in ['tutorial.html','final.html','parallel.html']:
        assert all(soup.find(id=hall) for hall in order);chapters+=7
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    for src in sources:assert hashlib.sha256(z.read(src['copy'])).hexdigest()==src['sha256']
dump(O/'validation.json',{'canonical_manuscripts_match_snapshots':14,'printed_code_files_match':len(printed),'combined_code_blocks_match':len(combined_blocks),'rendered_code_blocks_match':len(rendered_blocks),'chapter_sections':chapters,'relative_links_and_anchors':links,'assets':len(assets),'duplicate_html_ids':0,'zip_integrity':'passed','runtime_tests_rerun_by_compiler':False,'fresh_native_checks':revision_evidence['tests']})
pack()
print(json.dumps({'output':str(O),'totals':totals,'files':len(sources),'printed':len(printed),'assets':len(assets),'links':links,'zip_MB':round(archive.stat().st_size/1024**2,2)},indent=2))
