from pathlib import Path
import difflib,hashlib,html,json,re,shutil,zipfile
import markdown
from bs4 import BeautifulSoup

ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
STUDY=ROOT/'doc/book/studies/point-one'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,condition):
    checks.append({'name':name,'passed':bool(condition)})
    if not condition:raise AssertionError(name)
old=read(OUT/'before/commons/maps/Point_One/final.md')
new=read(ROOT/'commons/maps/Point_One/final.md')
changes=json.loads(read(OUT/'changes.json'))
restored=new
for change in reversed(changes):
    check('Revised passage occurs once',restored.count(change['after'])==1)
    restored=restored.replace(change['after'],change['before'],1)
restored=re.sub(r'^\[\^point-one-code\]:.*?\n\n','',restored,flags=re.M)
check('All other chapter text preserved',restored==old)
check('Encounter anchors preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
code=re.findall(r'```gdscript\n(.*?)```',new,re.S)
check('Six code passages',len(code)==6)
for i,filename in enumerate(['position.gd','visible.gd','solid.gd']):
    full='extends Node3D\n\nfunc _ready() -> void:\n'
    full+='\n'.join('    '+line if line else '' for line in '\n\n'.join(x.rstrip() for x in code[:i+1]).splitlines())+'\n'
    check('Assembled chapter equals '+filename,read(STUDY/filename)==full)
refs=re.findall(r'\[\^([^\]]+)\](?!:)',new)
defs=re.findall(r'^\[\^([^\]]+)\]:',new,re.M)
check('All footnotes defined once',set(refs)==set(defs) and len(defs)==len(set(defs)))
for name,fingerprint in json.loads(read(OUT/'baseline.json')).items():
    check('Production unchanged: '+name,sha(ROOT/name)==fingerprint)
native=json.loads(read(OUT/'native-verification.json'))
check('Native engine evidence passed',native['passed'] and all(c['passed'] for c in native['checks']))
cat=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
before=json.loads(read(OUT/'before/commons/data/museum_core_encounters.json'))
for k in ['text_sha256','local_review']:before['rooms']['Point_One'][k]=cat['rooms']['Point_One'][k]
check('Only requested catalogue fields changed',before==cat)
check('Catalogue follows final.md',cat['rooms']['Point_One']['text_sha256']==sha(ROOT/'commons/maps/Point_One/final.md'))
manifest=json.loads(read(ROOT/'doc/book/captures/primitives/primitives-book.manifest.json'))
check('Capture source fingerprints match',all(sha(ROOT/m['path'])==m['sha256'] for m in manifest['maps']))
check('Capture matches manifest',sha(ROOT/'doc/book/captures/primitives/primitives-book.md')==manifest['output_sha256'])
for f in ['primitives-book.md','primitives-book.manifest.json']:
    shutil.copy2(ROOT/'doc/book/captures/primitives'/f,OUT/f)
for filename in ['final','tutorial','technical','intent']:
    current=read(ROOT/f'commons/maps/Point_One/{filename}.md')
    previous=read(OUT/f'before/commons/maps/Point_One/{filename}.md')
    (OUT/f'Point_One.{filename}.md').write_bytes(current.encode('utf-8'))
    difference=''.join(difflib.unified_diff(previous.splitlines(True),current.splitlines(True),fromfile='before/'+filename+'.md',tofile='current/'+filename+'.md'))
    (OUT/f'Point_One.{filename}.diff').write_bytes(difference.encode('utf-8'))

files=[p for p in STUDY.iterdir() if p.is_file() and p.name!='.gitignore']
(OUT/'study').mkdir(exist_ok=True)
for p in files:shutil.copy2(p,OUT/'study'/p.name)
with zipfile.ZipFile(OUT/'point-one-study.zip','w',compression=zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,'point-one/'+p.name)
def render(text,prefix):
    soup=BeautifulSoup(markdown.markdown(text,extensions=['extra']),'html.parser')
    for node in soup.find_all(id=True):node['id']=prefix+'-'+node['id']
    for a in soup.find_all('a',href=True):
        if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
    return str(soup)
prior=read(ROOT/'doc/book/iterations/2026-09-29-point-one-code-in-the-encounter/index.html')
css=re.search(r'<style>(.*?)</style>',prior,re.S).group(1)
names=['The unseen point','Give it a surface','Give it resistance','Borrow the held body','What an address leaves out']
comparisons=''
for i,edit in enumerate(changes):
    comparisons+=f'<details><summary>{names[i]}</summary><div class="comparison"><div><p class="eyebrow">Before</p>{render(edit["before"],"old-"+str(i))}</div><div><p class="eyebrow">Now</p>{render(edit["after"],"new-"+str(i))}</div></div></details>'
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One | Building a point</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">Point One / 29 September 2026</p><h1>A point before its surface.</h1><p>Keep a position. Give it a visible body. Add a boundary. The prose and the code follow the same encounter.</p><nav><a href="#reading">Read</a><a href="#changes">Compare</a><a href="#making">Try the code</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">Current final.md</p>{render(new,'reading')}</article>
<section id="changes">{render(read(OUT/'DECISIONS.md'),'decisions')}{comparisons}<p><a href="Point_One.final.diff">Exact chapter diff</a> · <a href="Point_One.tutorial.diff">Tutorial diff</a> · <a href="primitives-book.md">Updated Primitives capture</a></p></section>
<section class="reading" id="making"><h2>Try the three constructions.</h2><p><a href="point-one-study.zip">Download the Godot study</a>. Import its project.godot in Godot 4.6. The camera, lights and labels are already there; the scripts contain the cumulative code from the chapter.</p><p>This study has a fixed camera. It covers position, appearance and fixed collision. The museum supplies walking and pickup for the encounter.</p><p><a href="study/position.gd">Position</a> · <a href="study/visible.gd">Visible</a> · <a href="study/solid.gd">Solid</a></p><details><summary>Open the complete coding tutorial</summary>{render(read(OUT/'study/TUTORIAL.md').replace('(README.md)','(study/README.md)'),'tutorial')}</details></section>
<footer><p><a href="native-verification.json">Native Godot checks</a> · <a href="verification.json">Publication checks</a> · <a href="Point_One.final.md">Chapter Markdown</a></p><p>The earlier reading experiments keep their original snapshots. This page contains the current revision.</p></footer>
</main></body></html>"""
soup=BeautifulSoup(page,'html.parser')
ids=[t['id'] for t in soup.find_all(id=True)]
check('HTML anchors resolve and are unique',len(ids)==len(set(ids)) and all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#')))
check('All chapter code rendered',len(soup.select('#reading pre code'))==6)
check('No raw footnote marks',not re.search(r'\[\^[^\]]+\]',soup.select_one('#reading').get_text()))
(OUT/'index.html').write_bytes(page.encode('utf-8'))
(OUT/'verification.json').write_bytes((json.dumps({'passed':True,'checks':checks,'scope':'Text scope, cumulative code, production fingerprints, publication. Native physics evidence is separate.'},indent=2)+'\n').encode('utf-8'))
print(f'{len(checks)} publication checks passed.')
