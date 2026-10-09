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
rel='commons/maps/Color_Paint/final.md';old=read(HERE/'before'/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/'changes.json'));expected=old
for c in changes:expected=expected.replace(c['before'],c['after'])
check('Only recorded manuscript changes',expected==new)
check('Albers encounter and source notes retained',old[old.index('<!-- @albers_wall_gallery -->'):]==new[new.index('<!-- @albers_wall_gallery -->'):])
check('Artifact anchors retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
report=json.loads(read(HERE/'report.json'))
check('55 native checks pass',report['passed'] and not report['failures'] and len(report['checks'])==55)
log=read(HERE/'stdout.log');check('No script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
native=json.loads(read(HERE/'source_manifest.json'))
for f in ['commons/maps/Color_Paint/map_data.json','commons/scenes/endless_museum.gd',HERE.relative_to(ROOT).as_posix()+'/probe.gd']:
 check('Native source current: '+f,sha(ROOT/f)==native['sources'][f])
before_map=json.loads(read(HERE/'before/commons/maps/Color_Paint/map_data.json'));after_map=json.loads(read(ROOT/'commons/maps/Color_Paint/map_data.json'))
check('Hall structure and utilities preserved',before_map['layers']['structure']==after_map['layers']['structure'] and before_map['layers']['utilities']==after_map['layers']['utilities'])
a=str(before_map['layers']['interactables']).replace('#automated:true','#automated:true#tools:spray')
check('Only spray token changes artifact placement',a==str(after_map['layers']['interactables']))
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))
for hall in ['Color_Paint','Color_Grid_Pallet']:
 e=core['rooms'][hall];check('Catalogue chapter current: '+hall,e['text_sha256']==sha(ROOT/'commons/maps'/hall/'final.md'))
 for key in ['text_sha256','local_review']:before['rooms'][hall][key]=e[key]
check('Only the two chapter references changed in catalogue',core==before)
m=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current chapter sources',len(m['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in m['maps']))
check('Colour capture hash matches',sha(ROOT/'doc/book/captures/color/color-book.md')==m['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
for name in ['studio','can-tray','shared-canvas','far-spray','at-the-tray','before-balls']:
 with Image.open(HERE/(name+'.png')) as im:im.verify()
check('All published museum images readable',True)
files=['commons/context/drawingboard/'+f for f in ['spray_can.gd','ball_spawner.gd','ball_painting_automation.gd','paper_draw_surface.gd','brush_layer.gd','ball_painting_demo_v2.tscn','wet_paint_canvas.tscn']]+['algorithms/color/drawing/'+f for f in ['spray_stamp.gdshader','wet_paint_simulation.gdshader']]+['commons/maps/Color_Paint/'+f for f in ['map_data.json','final.md','tutorial.md','technical.md','critical.md','intent.md','summary.md','artifacts.md','field_notes.md']]
(HERE/'encounter-sources.json').write_bytes(json.dumps({'sources':{f:sha(ROOT/f) for f in files}},indent=2).encode('utf-8'))
for hall in ['Color_Paint','Color_Grid_Pallet']:
 prior=read(HERE/'before/commons/maps'/hall/'final.md');current=read(ROOT/'commons/maps'/hall/'final.md')
 (HERE/(hall+'.current.md')).write_bytes(current.encode('utf-8'))
 (HERE/(hall+'.diff')).write_bytes(''.join(difflib.unified_diff(prior.splitlines(True),current.splitlines(True),fromfile='before/'+hall+'/final.md',tofile='current/'+hall+'/final.md')).encode('utf-8'))
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-grid-a-colour-left/index.html'),re.S).group(1)
rows=''.join('<tr><td>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes if not c['before'].startswith('!['))
grid=read(ROOT/'commons/maps/Color_Grid_Pallet/final.md');handoff=grid[grid.index('Ahead,'):]
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Paint — A colour from the nozzle</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_PAINT · 28 SEPTEMBER 2026</p><h1>A colour from the nozzle.</h1><p>Closer, denser. Farther, softer. Stay still and leave more behind.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the chapter</a><a href="#changes">Text changes</a><a href="#decisions">Evidence</a></nav></header>
<section id="museum"><figure><img src="can-tray.png" alt="Two rows of coloured spray cans with silver rims and nozzle buttons on the museum tray."><figcaption>Thirty grabbable colours. Right-click to carry on desktop; hold the left mouse button to spray. In VR, grab and hold the trigger.</figcaption></figure><div class="pair"><figure><img src="before-balls.png" loading="lazy" alt="The earlier ball painting installation inside the museum."><figcaption>The previous pigment balls, captured 23 September.</figcaption></figure><figure><img src="studio.png" loading="lazy" alt="The same studio with spray cans on the tray and an automatic can facing the canvas."><figcaption>The spray studio, captured 28 September. The hall and Albers studies remain.</figcaption></figure></div><figure><img src="far-spray.png" loading="lazy" alt="A small concentrated mark and a larger soft mark on the canvas behind the cans."><figcaption>Native rendered deposits at 0.4 m and 1.2 m nozzle distance: roughly 6.1 cm and 15.9 cm footprint radii. The farther deposit spreads the pigment more thinly.</figcaption></figure></section>
<article id="reading" class="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Paint&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="handoff"><h2>The arrival from Grid</h2>{render(handoff)}<p><a href="Color_Grid_Pallet.diff">One-sentence Grid handoff change</a></p></section>
<section id="changes"><h2>The gesture changes the text</h2><p><a href="Color_Paint.diff">Exact text difference</a> · <a href="Color_Paint.current.md">Current Markdown</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">Native report</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Source hashes</a> · <a href="color-book.md">Full Colour capture</a></p></section></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[n['id'] for n in soup.find_all(id=True)]
check('Unique rendered IDs',len(ids)==len(set(ids)))
check('Internal links resolve',all(n['href'][1:] in ids for n in soup.find_all('a',href=True) if n['href'].startswith('#')))
check('Source footnote rendered',soup.select_one('.footnote-backref') is not None)
(HERE/'index.html').write_bytes(page.encode('utf-8'))
(HERE/'checks.json').write_bytes(json.dumps({'passed':True,'checks':checks},indent=2).encode('utf-8'))
print(f'{len(checks)} publication checks passed. Native checks: {len(report["checks"])}.')
