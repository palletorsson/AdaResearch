from pathlib import Path
import difflib,hashlib,html,json,re,shutil
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
path='commons/maps/Point_One/final.md'
old=read(OUT/'before'/path);new=read(ROOT/path)
changes=json.loads(read(OUT/'changes.json'));checks=[]
def check(label,ok):
 checks.append({'name':label,'passed':bool(ok)})
 if not ok:raise ValueError(label)
restored=new
for edit in changes:
 check('New passage present exactly once',restored.count(edit['after'])==1)
 restored=restored.replace(edit['after'],edit['before'],1)
check('All prose outside three approved passages exact',restored==old)
check('Encounter anchors preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
blocks=lambda s:re.findall(r'```gdscript\n(.*?)```',s,re.S)
check('Earlier code blocks preserved',all(code in blocks(new) for code in blocks(old)))
shape_source=read(ROOT/'commons/primitives/point/point_condition.gd')
check('Mesh and collision snippets exact source statements',all(line.strip() in shape_source for i in [0,1] for line in blocks(changes[i]['after'])[0].splitlines()))
frame_source=read(ROOT/'algorithms/vectors/00_coordinates/CoordinateSystem3M.gd')
check('Reduced coordinate example matches actual operations','var lp: Vector3 = to_local(pt.global_position)' in frame_source and 'var world_p: Vector3 = pt.global_position' in frame_source)
for f,h in json.loads(read(OUT/'baseline.json')).items():check('Unchanged '+f,sha(ROOT/f)==h)
check('Footnotes preserved',re.findall(r'^\[\^.+$',new,re.M)==re.findall(r'^\[\^.+$',old,re.M))
refs=re.findall(r'\[\^([^\]]+)\](?!:)',new);defs=re.findall(r'^\[\^([^\]]+)\]:',new,re.M)
check('Footnotes complete and unique',set(refs)==set(defs) and len(defs)==len(set(defs)))
c=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));b=json.loads(read(OUT/'before/commons/data/museum_core_encounters.json'))
for key in ['text_sha256','local_review']:b['rooms']['Point_One'][key]=c['rooms']['Point_One'][key]
check('Only Point One text fingerprint and review changed in catalogue',b==c)
check('Catalogue fingerprint current',c['rooms']['Point_One']['text_sha256']==sha(ROOT/path))
manifest=json.loads(read(ROOT/'doc/book/captures/primitives/primitives-book.manifest.json'))
check('Primitives capture matches its current source texts',all(sha(ROOT/m['path'])==m['sha256'] for m in manifest['maps']))
check('Capture file matches manifest',sha(ROOT/'doc/book/captures/primitives/primitives-book.md')==manifest['output_sha256'])
for f in ['primitives-book.md','primitives-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/primitives'/f,OUT/f)
(OUT/'Point_One.current.md').write_text(new,encoding='utf-8')
(OUT/'Point_One.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+path,tofile='current/'+path)),encoding='utf-8')
def render(s,prefix):
 soup=BeautifulSoup(markdown.markdown(s,extensions=['extra']),'html.parser')
 for t in soup.find_all(id=True):t['id']=prefix+'-'+t['id']
 for a in soup.find_all('a',href=True):
  if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
 return str(soup)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-preface-arriving-in-change/index.html'),re.S).group(1)
css+='\n.reading pre{font-size:14px;border-left:2px solid #859a8b;background:#ecede5;line-height:1.65}.reading pre code{font:inherit}.reading pre{white-space:pre-wrap;overflow-wrap:anywhere}.comparisons{margin-top:35px}.comparison pre{font-size:12px}'
comparisons=''
for i,edit in enumerate(changes,1):
 comparisons+=f'<details><summary>{["A visible sphere","A separate collision shape","Two addresses"][i-1]}</summary><div class="comparison"><div><p class="eyebrow">Before</p>{render(edit["before"],"old-"+str(i))}</div><div><p class="eyebrow">Current</p>{render(edit["after"],"new-"+str(i))}</div></div></details>'
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point One | Code inside the encounter</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">Point One / 29 September 2026</p><h1>Code inside the encounter.</h1><p>Seven added code lines open three decisions: a visible shape, a separate boundary, and two ways to address the same body.</p><nav><a href="#reading">Read the revised chapter</a><a href="#changes">The three changes</a><a href="/compose/sources?map=Point_One&amp;doc=final">Read and comment</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">Current canonical final.md</p>{render(new,'reading')}</article>
<section id="changes">{render(read(OUT/'DECISIONS.md'),'decisions')}<div class="comparisons">{comparisons}</div><p class="meta"><a href="Point_One.diff">Exact chapter difference</a> / <a href="Point_One.current.md">Current Markdown</a> / <a href="primitives-book.md">Updated Primitives capture</a> / <a href="verification.json">Publication checks</a></p><details><summary>Full earlier chapter</summary>{render(old,'before')}</details></section>
<footer><p>The <a href="/book-review/doc/book/iterations/2026-09-29-point-one-facing-pages/index.html">original facing-page test</a> keeps its earlier snapshots for comparison. The tutorial has not been rewritten in this pass.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[x['id'] for x in soup.find_all(id=True)]
check('Reading anchors unique and complete',len(ids)==len(set(ids)) and all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#')))
check('Six code passages rendered in current reading',len(soup.select('#reading pre code'))==6)
check('No raw footnote references in rendered reading',not re.search(r'\[\^[^\]]+\]',soup.select_one('#reading').get_text()))
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps({'passed':True,'checks':checks,'before_code_lines':sum(len(b.splitlines()) for b in blocks(old)),'after_code_lines':sum(len(b.splitlines()) for b in blocks(new)),'scope':'Manuscript preservation, source comparisons and publication. No new runtime or learner test.'},indent=2)+'\n',encoding='utf-8')
print(str(len(checks))+' publication checks passed.')
