from pathlib import Path
import re,json,hashlib,difflib,shutil,zipfile
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
STUDY=ROOT/'doc/book/studies/point-one'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
old=read(OUT/'before/commons/maps/Point_One/final.md')
new=read(ROOT/'commons/maps/Point_One/final.md')
tutorial=read(ROOT/'commons/maps/Point_One/tutorial.md')
changes=json.loads(read(OUT/'changes.json'))
restored=new
for edit in reversed(changes):
    assert restored.count(edit['after'])==1,edit['label']
    restored=restored.replace(edit['after'],edit['before'],1)
assert restored==old
assert re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new)
blocks=lambda s:re.findall(r'```gdscript\n(.*?)```',s,re.S)
assert len(blocks(new))==1 and len(blocks(new)[0].strip().splitlines())==1
assert blocks(new)[0]==blocks(old)[0]
assert all(block.strip() in tutorial for block in blocks(old)[1:])
for name,fingerprint in json.loads(read(OUT/'baseline.json')).items():assert sha(ROOT/name)==fingerprint,name
cat=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
before=json.loads(read(OUT/'before/commons/data/museum_core_encounters.json'))
for key in ['text_sha256','local_review']:before['rooms']['Point_One'][key]=cat['rooms']['Point_One'][key]
assert before==cat
assert cat['rooms']['Point_One']['text_sha256']==sha(ROOT/'commons/maps/Point_One/final.md')
manifest=json.loads(read(ROOT/'doc/book/captures/primitives/primitives-book.manifest.json'))
assert all(sha(ROOT/m['path'])==m['sha256'] for m in manifest['maps'])
assert sha(ROOT/'doc/book/captures/primitives/primitives-book.md')==manifest['output_sha256']
for f in ['primitives-book.md','primitives-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/primitives'/f,OUT/f)
for name in ['final','tutorial','intent','technical']:
    previous=read(OUT/f'before/commons/maps/Point_One/{name}.md')
    current=read(ROOT/f'commons/maps/Point_One/{name}.md')
    (OUT/f'Point_One.{name}.md').write_bytes(current.encode('utf-8'))
    (OUT/f'Point_One.{name}.diff').write_bytes(''.join(difflib.unified_diff(previous.splitlines(True),current.splitlines(True),fromfile='before/'+name+'.md',tofile='current/'+name+'.md')).encode('utf-8'))
(OUT/'study').mkdir(exist_ok=True)
study_files=[p for p in STUDY.iterdir() if p.is_file() and p.name!='.gitignore']
for p in study_files:shutil.copy2(p,OUT/'study'/p.name)
with zipfile.ZipFile(OUT/'point-one-study.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
    for p in study_files:z.write(p,'point-one/'+p.name)
prior=ROOT/'doc/book/iterations/2026-09-29-point-one-building-a-point'
shutil.copy2(prior/'native-verification.json',OUT/'study-native-evidence.json')
css=re.search(r'<style>(.*?)</style>',read(prior/'index.html'),re.S).group(1)
css+='\nheader{margin-bottom:3rem}.turn-page{margin:4rem auto;padding-top:2rem;border-top:1px solid #cdcfc3;max-width:740px}.turn-page a{font-size:1.1rem}.editorial{margin:4rem auto;max-width:740px}.reading{margin-bottom:2rem}'
def render(s,prefix):
    soup=BeautifulSoup(markdown.markdown(s,extensions=['extra']),'html.parser')
    for t in soup.find_all(id=True):t['id']=prefix+'-'+t['id']
    for a in soup.find_all('a',href=True):
        if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
    return str(soup)
def page(title,body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{css}</style></head><body><main>{body}</main></body></html>'
comparisons=''
for i,c in enumerate(changes):
    c={**c,'before':re.sub(r'^\[\^[^\]]+\]: ', '', c['before']), 'after':re.sub(r'^\[\^[^\]]+\]: ', '', c['after'])}
    comparisons+=f'<details><summary>{c["label"]}</summary><div class="comparison"><div><p class="eyebrow">Before</p>{render(c["before"],"old"+str(i))}</div><div><p class="eyebrow">Now</p>{render(c["after"],"new"+str(i))}</div></div></details>'
reading=page('Point One | Read the encounter',f"""
<header><p class="eyebrow">Point One · 29 September 2026</p><p>Read the encounter. The making passage follows on a separate page.</p><nav><a href="#reading">Reading</a><a href="making.html">Making</a><a href="#changes">Compare</a></nav></header>
<article class="reading" id="reading">{render(new,'reading')}</article>
<div class="turn-page"><a href="making.html">Continue to making →</a><p>Build the visible and solid points from the encounter.</p><p><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment on the current chapter</a></p></div>
<section class="editorial" id="changes"><details><summary>What changed in this reading?</summary>{render(read(OUT/'DECISIONS.md'),'decisions')}{comparisons}<p><a href="Point_One.final.diff">Exact chapter diff</a> · <a href="Point_One.tutorial.diff">Tutorial diff</a> · <a href="primitives-book.md">Current Primitives capture</a></p></details></section>
""")
making=page('Point One | Make the difference',f"""
<header><p class="eyebrow">Point One · Making passage</p><nav><a href="index.html#reading">← Return to the encounter</a><a href="point-one-study.zip">Download the Godot study</a></nav></header>
<article class="reading" id="making">{render(tutorial.replace('../../../doc/book/studies/point-one/README.md','study/README.md'),'making')}</article>
<div class="turn-page"><p><a href="study/position.gd">Complete position script</a> · <a href="study/visible.gd">Visible script</a> · <a href="study/solid.gd">Solid script</a></p><p><a href="index.html#reading">Return to the encounter →</a></p><p class="meta">The executable study is unchanged from the preceding construction test. <a href="study-native-evidence.json">Native Godot evidence</a>.</p></div>
""")
for filename,s in [('index.html',reading),('making.html',making)]:
    soup=BeautifulSoup(s,'html.parser');ids=[x['id'] for x in soup.find_all(id=True)]
    assert len(ids)==len(set(ids))
    missing=[a['href'] for a in soup.find_all('a',href=True) if a['href'].startswith('#') and a['href'][1:] not in ids]
    assert not missing, (filename,missing)
    (OUT/filename).write_bytes(s.encode('utf-8'))
soup=BeautifulSoup(reading,'html.parser')
assert len(soup.select('#reading pre code'))==1
assert not re.search(r'\[\^[^\]]+\]',soup.select_one('#reading').get_text())
def prose_count(s):
    s=re.sub(r'```.*?```','',s,flags=re.S)
    s=re.sub(r'^\[\^.*$','',s,flags=re.M)
    s=re.sub(r'<!--.*?-->','',s)
    return len(s.split())
report={'passed':True,'before_code_blocks':len(blocks(old)),'after_code_blocks':len(blocks(new)),'before_prose_words':prose_count(old),'after_prose_words':prose_count(new),'removed_code_preserved_in_tutorial':True,'untouched_prose_exact':True,'encounter_anchors_preserved':True,'study_and_production_code_unchanged':True,'capture_current':True,'links_and_footnotes_checked':True,'scope':'Writing and publication. Existing native study evidence reused because executable code is unchanged; no new runtime or learner test.'}
(OUT/'verification.json').write_bytes((json.dumps(report,indent=2)+'\n').encode('utf-8'))
print(json.dumps(report))
