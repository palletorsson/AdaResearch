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
rel='commons/maps/Color_Pillar/final.md';old=read(HERE/'before'/rel);new=read(ROOT/rel)
expected=old;changes=json.loads(read(HERE/'changes.json'))
for c in changes:expected=expected.replace(c['before'],c['after'])
check('Only the recorded text/figure changes',expected==new)
check('Code, footnote and named collection preserved',old[old.index('<!-- @color_sets_overview -->'):]==new[new.index('<!-- @color_sets_overview -->'):] and re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',new,re.S))
check('Hall geometry and placement unchanged',sha(HERE/'before/commons/maps/Color_Pillar/map_data.json')==sha(ROOT/'commons/maps/Color_Pillar/map_data.json'))
report=json.loads(read(HERE/'report.json'));check('68 native checks pass',report['passed'] and not report['failures'] and len(report['checks'])==68)
log=read(HERE/'stdout.log');check('No script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
m=json.loads(read(HERE/'source_manifest.json'))
for f in ['commons/maps/Color_Pillar/map_data.json','commons/scenes/endless_museum.gd','algorithms/color/pillarcolorcollection/pillarcolorcollection.gd',HERE.relative_to(ROOT).as_posix()+'/probe.gd']:
 check('Native source current: '+f,sha(ROOT/f)==m['sources'][f])
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));e=core['rooms']['Color_Pillar']
check('Catalogue chapter current',e['text_sha256']==sha(ROOT/rel))
for key in ['text_sha256','local_review']:before['rooms']['Color_Pillar'][key]=e[key]
check('Only this chapter catalogue reference changed',core==before)
files=['algorithms/color/pillarcolorcollection/'+name for name in ['pillarcolorcollection.gd','pillarcolorcollection.tscn','hsv_field.gdshader','field_sampler.gd','field_sampler.tscn']]+['commons/maps/Color_Pillar/'+name for name in ['map_data.json','final.md','tutorial.md','technical.md','critical.md','intent.md','field_notes.md']]
(HERE/'encounter-sources.json').write_bytes(json.dumps({'sources':{f:sha(ROOT/f) for f in files}},indent=2).encode('utf-8'))
m=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current chapter sources',len(m['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in m['maps']))
check('Colour capture hash matches',sha(ROOT/'doc/book/captures/color/color-book.md')==m['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
shutil.copy2(ROOT/'doc/book/iterations/2026-09-28-pillar-height-and-value/value-columns.png',HERE/'before.png')
for name in ['before','value-columns','ceiling-and-column','under-the-palette','within-the-field']:
 with Image.open(HERE/(name+'.png')) as im:im.verify()
check('Native images readable',True)
(HERE/'Color_Pillar.current.md').write_bytes(new.encode('utf-8'))
(HERE/'Color_Pillar.diff').write_bytes(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Pillar/final.md',tofile='current/Color_Pillar/final.md')).encode('utf-8'))
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-pillar-height-and-value/index.html'),re.S).group(1)
rows=''.join('<tr><td>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes if not c['before'].startswith('!['))
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pillar — Colour becomes the ceiling</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_PILLAR · 28 SEPTEMBER 2026</p><h1>Colour becomes the ceiling.</h1><p>The palette meets the pillar tops. Dark ground leaves room beneath it.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#decisions">Evidence</a></nav></header>
<section id="museum"><figure><img src="ceiling-and-column.png" alt="A colour ceiling meets tall gradient pillars rising from near-black ground."><figcaption>Native museum view. The ceiling sits at 4.6 m and value 1; each pillar meets its colour at the top.</figcaption></figure>
<div class="pair"><figure><img src="before.png" loading="lazy" alt="The previous bright floor and open space above the pillars."><figcaption>Before: the bright field lies underfoot.</figcaption></figure><figure><img src="value-columns.png" loading="lazy" alt="The same viewpoint with a dark floor and the palette overhead."><figcaption>Now: the field becomes a ceiling, with dark ground beneath it.</figcaption></figure></div>
<figure><img src="within-the-field.png" loading="lazy" alt="An interior view walking between pillars under the continuous coloured ceiling."><figcaption>From the ordinary walker's reached position. The colour continues overhead where the gaps leave room for a body.</figcaption></figure></section>
<article id="reading" class="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Pillar&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>From a floor sample to a roof</h2><p><a href="Color_Pillar.diff">Exact text difference</a> · <a href="Color_Pillar.current.md">Current Markdown</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">68-check native report</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="color-book.md">Full Colour capture</a></p></section></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[n['id'] for n in soup.find_all(id=True)]
check('Unique rendered IDs',len(ids)==len(set(ids)))
check('Internal links resolve',all(n['href'][1:] in ids for n in soup.find_all('a',href=True) if n['href'].startswith('#')))
check('Footnote backlink present',soup.select_one('.footnote-backref') is not None)
(HERE/'index.html').write_bytes(page.encode('utf-8'))
(HERE/'checks.json').write_bytes(json.dumps({'passed':True,'checks':checks},indent=2).encode('utf-8'))
print(f'{len(checks)} publication checks passed; {len(old.split())} to {len(new.split())} words.')
