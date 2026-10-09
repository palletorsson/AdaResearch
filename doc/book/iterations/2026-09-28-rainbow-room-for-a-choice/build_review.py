from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from bs4 import BeautifulSoup
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['extra'])
checks=[]
def check(label,ok):
 checks.append({'name':label,'passed':bool(ok)})
 if not ok:raise ValueError(label)
rel='commons/maps/Color_Rainbow/final.md';old=read(HERE/'before'/rel);new=read(ROOT/rel);changes=json.loads(read(HERE/'changes.json'))
expected=old
for c in changes:expected=expected.replace(c['before'],c['after'])
check('Only the four recorded passage changes',expected==new)
check('Code and encounter anchors preserved',re.findall(r'```.*?```|<!--.*?-->',old,re.S)==re.findall(r'```.*?```|<!--.*?-->',new,re.S))
check('Opening welcome preserved',old[:old.index('The option called')]==new[:new.index('Look for the seams')])
check('Celebration ending and Pillar handoff preserved',old[old.index('Before leaving, choose'):]==new[new.index('Before leaving, choose'):])
images=re.findall(r'!\[[^\]]*\]\(([^\n]+)\)',new)
check('Native four-arrangement figure preserved',images==re.findall(r'!\[[^\]]*\]\(([^\n]+)\)',old))
for path in images:
 with Image.open(ROOT/path.removeprefix('/book-review/')) as im:im.verify()
check('Native figure readable',True)
changed={rel,'commons/maps/Color_Rainbow/tutorial.md','commons/maps/Color_Rainbow/field_notes.md','commons/data/museum_core_encounters.json'}
for name,digest in json.loads(read(HERE/'baseline.json')).items():
 if name not in changed:check('Preserved '+name,sha(ROOT/name)==digest)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));e=core['rooms']['Color_Rainbow']
check('Current catalogue text hash',e['text_sha256']==sha(ROOT/rel))
for k in ['text_sha256','local_review']:before['rooms']['Color_Rainbow'][k]=e[k]
check('Only Rainbow hash and review changed in catalogue',core==before)
manifest=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current Colour chapter sources',len(manifest['maps'])==8 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture hash matches',sha(ROOT/'doc/book/captures/color/color-book.md')==manifest['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
(HERE/'Color_Rainbow.current.md').write_text(new,encoding='utf-8')
(HERE/'Color_Rainbow.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Rainbow/final.md',tofile='current/Color_Rainbow/final.md')),encoding='utf-8')
rows=''.join('<tr><td><h3>'+c['label']+'</h3>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-nails-the-next-choice/index.html'),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rainbow — Room for a choice</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_RAINBOW · 28 SEPTEMBER 2026 · WELCOME AND ARRANGEMENT</p><h1>Room for a choice.</h1><p>The celebration is already happening. A colour chosen in the salon can meet other company here.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Compare passages</a><a href="#museum">Inside the room</a><a href="#decisions">Decisions and evidence</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Rainbow&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Observation, then the rule</h2><p>Look for the seams before the code. Find a chosen colour among the room's colours. Follow the button back to its first choice.</p><p>{len(old.split())} → {len(new.split())} words, including code and caption. <a href="Color_Rainbow.diff">Exact text difference</a> · <a href="Color_Rainbow.current.md">Current Markdown</a></p><table class="passages"><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="museum"><h2>The welcome remains.</h2><figure><img src="/book-review/doc/book/iterations/2026-09-23-rainbow-room-for-another/celebration.png" alt="Confetti in the museum's Rainbow hall, with the level path and optional steps beneath the arch."><figcaption>Existing Godot museum capture, 23 September 2026. This writing pass preserves the celebration; it does not claim a new runtime test.</figcaption></figure></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="source-comparison.json">Source comparison</a> · <a href="/book-review/doc/book/iterations/2026-09-23-rainbow-room-for-another/report.json">23 September native evidence</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.md">Colour capture</a> · <a href="color-book.manifest.json">Capture source record</a></p></section>
<footer><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-nails-colour-and-permission/index.html#reading">Nails — Colour and permission</a>. Next: <a href="/compose/sources?map=Color_Pillar&amp;doc=final">The colour between the pillars</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[t['id'] for t in soup.find_all(id=True)]
check('Rendered IDs unique',len(ids)==len(set(ids)))
check('Internal links resolve',all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#')))
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'scope':'Publication, source preservation and refreshed Colour capture. Existing native evidence reused with its date; no new runtime or headset test.'},indent=2)+'\n',encoding='utf-8')
print(str(len(checks))+' publication checks passed; '+str(len(old.split()))+' -> '+str(len(new.split()))+' words.')
