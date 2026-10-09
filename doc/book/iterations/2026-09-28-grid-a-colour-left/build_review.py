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
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 if not ok:raise ValueError(name)
rel='commons/maps/Color_Grid_Pallet/final.md';old=read(HERE/'before'/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/'changes.json'));expected=old
for c in changes:expected=expected.replace(c['before'],c['after'])
check('Only recorded chapter changes',expected.rstrip()+'\n'==new)
check('Both code excerpts retained',re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',new,re.S))
check('Artifact anchors and Paint handoff retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new) and old[old.index('Ahead, a coloured ball'):].strip()==new[new.index('Ahead, a coloured ball'):].strip())
base=json.loads(read(HERE/'baseline.json'))
unchanged=['commons/maps/Color_Grid_Pallet/map_data.json','algorithms/color/gridcolorizer/address_lesson.gd','algorithms/color/gridcolorizer/gridcolorizer.gd','commons/grid/mutators/grid_color_mutator.gd','commons/ui/control_panel.gd']
check('Production hall and artifact unchanged',all(sha(ROOT/f)==base[f] for f in unchanged))
report=json.loads(read(HERE/'report.json'))
check('36 native checks pass',report['passed'] and not report['failures'] and len(report['checks'])==36)
log=read(HERE/'stdout.log');check('No script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
native=json.loads(read(HERE/'source_manifest.json'))
for f in ['commons/maps/Color_Grid_Pallet/map_data.json','commons/scenes/endless_museum.gd',HERE.relative_to(ROOT).as_posix()+'/probe.gd']:
 check('Native source current: '+f,sha(ROOT/f)==native['sources'][f])
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));e=core['rooms']['Color_Grid_Pallet']
check('Catalogue chapter current',e['text_sha256']==sha(ROOT/rel))
for key in ['text_sha256','local_review']:before['rooms']['Color_Grid_Pallet'][key]=e[key]
check('Only this chapter catalogue reference changed',core==before)
files=unchanged+['commons/maps/Color_Grid_Pallet/'+name for name in ['final.md','tutorial.md','critical.md','intent.md','field_notes.md']]+['doc/reports/interfaces-2026-09-20/shannon-pilot/before/.gdignore']
files += ['doc/reports/interfaces-2026-09-20/compact-pilot/before/.gdignore', 'doc/reports/interfaces-2026-09-20/console-finish/before/.gdignore', 'doc/reports/interfaces-2026-09-20/console-pilot/before/.gdignore']
(HERE/'encounter-sources.json').write_bytes(json.dumps({'sources':{f:sha(ROOT/f) for f in files}},indent=2).encode('utf-8'))
m=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current chapter sources',len(m['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in m['maps']))
check('Colour capture hash matches',sha(ROOT/'doc/book/captures/color/color-book.md')==m['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
for name in ['console-and-floor','standing-on-colour','an-address-keeps-colour']:
 with Image.open(HERE/(name+'.png')) as im:im.verify()
check('Museum images readable',True)
(HERE/'Color_Grid_Pallet.current.md').write_bytes(new.encode('utf-8'))
(HERE/'Color_Grid_Pallet.diff').write_bytes(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Grid_Pallet/final.md',tofile='current/Color_Grid_Pallet/final.md')).encode('utf-8'))
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-pillar-colour-ceiling/index.html'),re.S).group(1)
rows=''.join('<tr><td>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes if not c['before'].startswith('!['))
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Grid — A colour left behind</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_GRID_PALLET · 28 SEPTEMBER 2026</p><h1>A colour left behind.</h1><p>The outline moves. Your colour waits at the place you chose.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the museum</a><a href="#changes">Text changes</a><a href="#decisions">Evidence</a></nav></header>
<section id="museum"><figure><img src="console-and-floor.png" alt="A five-button console and its colour swatch face the coloured floor inside the museum."><figcaption>Current native museum view: choose a square, write its colour, leave it behind.</figcaption></figure><figure><img src="standing-on-colour.png" loading="lazy" alt="Looking down from the visitor's reached position onto the pink square with a white outline."><figcaption>The ordinary controller has walked onto the edited square. Its colour changed; it still carries the visitor.</figcaption></figure></section>
<article id="reading" class="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Grid_Pallet&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Room for the return</h2><p><a href="Color_Grid_Pallet.diff">Exact text difference</a> · <a href="Color_Grid_Pallet.current.md">Current Markdown</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">Native report</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="color-book.md">Full Colour capture</a></p></section></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[n['id'] for n in soup.find_all(id=True)]
check('Unique rendered IDs',len(ids)==len(set(ids)))
check('Internal links resolve',all(n['href'][1:] in ids for n in soup.find_all('a',href=True) if n['href'].startswith('#')))
(HERE/'index.html').write_bytes(page.encode('utf-8'))
(HERE/'checks.json').write_bytes(json.dumps({'passed':True,'checks':checks},indent=2).encode('utf-8'))
print(f'{len(checks)} publication checks passed; {len(old.split())} to {len(new.split())} words.')
