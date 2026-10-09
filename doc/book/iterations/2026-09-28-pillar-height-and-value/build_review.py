from pathlib import Path
import difflib, hashlib, json, re, shutil
import markdown
from bs4 import BeautifulSoup
from PIL import Image
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=["extra"])
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise ValueError(name)
rel="commons/maps/Color_Pillar/final.md"
old=read(HERE/"before"/rel);new=read(ROOT/rel)
source=read(ROOT/"algorithms/color/pillarcolorcollection/pillarcolorcollection.gd")
check("Chapter's HSV code appears in current implementation",re.search(r"```gdscript\n(.*?)\n```",new,re.S).group(1)=="\n".join(x.lstrip('\t') for x in re.search(r"```gdscript\n(.*?)\n```",new,re.S).group(1).splitlines()) and all(line in source for line in re.search(r"```gdscript\n(.*?)\n```",new,re.S).group(1).splitlines()))
check("Both existing encounter anchors preserved",re.findall(r'<!-- @[^>]*-->',old)==re.findall(r'<!-- @[^>]*-->',new))
check("Named collection preserved with one carrying distinction",old[old.index('<!-- @color_sets_overview -->'):].strip()==new[new.index('<!-- @color_sets_overview -->'):new.index('[^value]:')].replace(' This one keeps its colour as you move it.','').strip())
report=json.loads(read(HERE/'report.json'))
check("61 current native checks pass",report['passed'] and len(report['checks'])==61 and not report['failures'])
log=read(HERE/'stdout.log')
check("No script or shader errors",'SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
manifest=json.loads(read(HERE/'source_manifest.json'))
for file in ['commons/maps/Color_Pillar/map_data.json','commons/scenes/endless_museum.gd','algorithms/color/pillarcolorcollection/pillarcolorcollection.gd',HERE.relative_to(ROOT).as_posix()+'/probe.gd','tools/run_encounter_probe.py']:
 check('Tested source current: '+file,manifest['sources'][file]==sha(ROOT/file))
check("Hall geometry and placement unchanged",sha(ROOT/'commons/maps/Color_Pillar/map_data.json')=='02d6e14dca7e1be71b2d60f42e5de8e4addc84e8db312b908ddb04966af49d16')
files=['algorithms/color/pillarcolorcollection/'+name for name in ['pillarcolorcollection.gd','pillarcolorcollection.tscn','hsv_field.gdshader','field_sampler.gd','field_sampler.tscn']]
files+=['commons/maps/Color_Pillar/'+name for name in ['map_data.json','final.md','tutorial.md','technical.md','critical.md','intent.md','field_notes.md']]
files+=['commons/primitives/pillar/pillar.tscn','commons/primitives/panels/DigitalPaper/grab_paper.tscn','commons/primitives/cubes/grab_cube_grid_snap.gd','algorithms/color/grabcolor/color_sets_overview.gd','commons/artifacts/registry/color.json']
(HERE/'encounter-sources.json').write_text(json.dumps({"scope":"Sources of the native field and current manuscript at publication. New sampler and shader included explicitly.","sources":{f:sha(ROOT/f) for f in files}},indent=2),encoding='utf-8')
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))['rooms']['Color_Pillar']
check('Catalogue points to current chapter and review',core['text_sha256']==sha(ROOT/rel) and core['local_review']==HERE.relative_to(ROOT).as_posix()+'/index.html')
m=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current Colour chapter sources',len(m['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in m['maps']))
check('Capture content matches its manifest',sha(ROOT/'doc/book/captures/color/color-book.md')==m['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
shutil.copy2(ROOT/'doc/book/iterations/2026-09-28-pillar-room-between/within-the-field.png',HERE/'before-field.png')
for name in ['before-field','value-columns','grey-reference','within-the-field','sampler-0','sampler-50','sampler-100']:
 with Image.open(HERE/(name+'.png')) as im:im.verify()
check('All published native images readable',True)
(HERE/'Color_Pillar.current.md').write_text(new,encoding='utf-8')
(HERE/'Color_Pillar.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Pillar/final.md',tofile='current/Color_Pillar/final.md')),encoding='utf-8')
paragraphs=lambda s:s.split('\n\n')
pick=lambda s,prefix:next(p for p in paragraphs(s) if p.startswith(prefix))
pairs=[('The unused direction',pick(old,'Value stays'),pick(new,'Look up a pillar.')),
       ('What you can carry',pick(old,'Take a swatch'),pick(new,'Pick up the small sampling card.')+'\n\n'+pick(new,'Read the two lines')),
       ('A difference the colour cannot show',pick(old,'Five columns'),pick(new,'Lower it again.')+'\n\n'+pick(new,'Five columns'))]
rows=''.join('<tr><td><h3>'+title+'</h3>'+render(a)+'</td><td>'+render(b)+'</td></tr>' for title,a,b in pairs)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-pillar-room-between/index.html'),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pillar — Height becomes value</title><style>{css}
figure img{{width:100%;height:auto}} .pair,.triple{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}} .triple{{grid-template-columns:repeat(3,minmax(0,1fr))}} .pair figure,.triple figure{{margin:0}} td{{vertical-align:top}} @media(max-width:760px){{.pair,.triple{{grid-template-columns:1fr}}}}</style></head><body><main>
<header><p class="eyebrow">COLOR_PILLAR · 28 SEPTEMBER 2026 · HUE, SATURATION, VALUE</p><h1>Height becomes value.</h1><p>Across the floor, the colour changes. Look up, and the same colour comes out of black.</p><nav><a href="#museum">Inside the museum</a><a href="#reading">Read the chapter</a><a href="#changes">Compare passages</a><a href="#decisions">Decisions and evidence</a></nav></header>
<section id="museum"><figure><img src="value-columns.png" alt="Tall columns rise from black to pale colours, with a movable sampler among them."><figcaption>Native Godot museum capture, 28 September. Hue across, saturation along, value up. The floor holds a bright reference slice.</figcaption></figure>
<h2>One colour, two descriptions.</h2><div class="triple"><figure><img src="sampler-0.png" alt="The sampling card is black at HSV value zero."><figcaption>V = 0. The card retains its hue and saturation address; RGB is zero.</figcaption></figure><figure><img src="sampler-50.png" alt="At half value the card shows HSV and RGB for a brown colour."><figcaption>V = 0.5. The same hue and saturation, with half the RGB channel values.</figcaption></figure><figure><img src="sampler-100.png" alt="At full value the card shows a pale warm colour."><figcaption>V = 1. Bright colour. Saturation still exceeds zero, so it does not become white.</figcaption></figure></div>
<p>The card's short lift represents the columns' full height. The marker and FIELD Y show that mapping. These captures use a supplied grabber through the production pickup API; they do not establish headset reach.</p>
<figure><img src="grey-reference.png" loading="lazy" alt="A grey-to-white column stands beside the coloured samples."><figcaption>The separate reference has saturation zero. Here, raising value does reach white.</figcaption></figure>
<h2>The same walk, another direction.</h2><div class="pair"><figure><img src="before-field.png" loading="lazy" alt="The earlier uniformly coloured columns seen from the walking route."><figcaption>Before — native museum view, 23 September. Value is fixed in each column.</figcaption></figure><figure><img src="within-the-field.png" loading="lazy" alt="The current columns darken toward their bases, seen from the same walking route."><figcaption>Current — native museum view, 28 September. Value varies vertically; the room between the samples remains.</figcaption></figure></div></section>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Pillar&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>How the encounter changes the writing</h2><p>{len(old.split())} → {len(new.split())} words including code, caption and source note. <a href="Color_Pillar.diff">Exact text difference</a> · <a href="Color_Pillar.current.md">Current Markdown</a></p><table><thead><tr><th>Before</th><th>Current passages</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p>61/61 focused native checks pass. No script or shader errors. The log retains an unrelated pre-existing resource UID warning.</p><p><a href="report.json">Native report</a> · <a href="encounter-sources.json">Current sources</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.md">Current full Colour capture</a></p></section>
<footer><p>Next: <a href="/compose/sources?map=Color_Grid_Pallet&amp;doc=final">Color_Grid_Pallet — a colour kept at an address</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[n['id'] for n in soup.find_all(id=True)]
check('Rendered IDs unique',len(ids)==len(set(ids)))
check('Internal links resolve',all(n['href'][1:] in ids for n in soup.find_all('a',href=True) if n['href'].startswith('#')))
check('Footnote and backlink rendered',soup.select_one('.footnote') is not None and soup.select_one('.footnote-backref') is not None)
check('No unresolved local chapter images',all((ROOT/'doc/book/iterations/2026-09-28-pillar-height-and-value'/Path(n['src']).name).exists() for n in soup.find_all('img')))
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'scope':'Publication, source correspondence and current native evidence. No headset or calibrated display claim.','checks':checks},indent=2),encoding='utf-8')
print(f'{len(checks)} publication checks passed. {len(old.split())} -> {len(new.split())} words.')
