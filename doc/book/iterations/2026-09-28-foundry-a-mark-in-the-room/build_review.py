from pathlib import Path
import hashlib,json,re,shutil,urllib.request
import markdown
from PIL import Image
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['extra'])
js=lambda p:json.loads(read(p))
checks=[]
def check(name,passed):
 checks.append({'name':name,'passed':bool(passed)})
 if not passed:raise ValueError(name)
old=read(HERE/'before/commons/maps/Pattern_Foundry/final.md');new=read(ROOT/'commons/maps/Pattern_Foundry/final.md')
check('Four artifact anchors and closing anchor retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Exact source excerpt retained',re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',new,re.S))
check('Closing exception argument retained',old.split('<!-- @ -->')[1]==new.split('<!-- @ -->')[1])
check('Current chapter snapshot matches',read(HERE/'Pattern_Foundry.current.md')==new)
manifest=js(HERE/'encounter-sources.json')
check('Native artifact source hashes current',all(sha(ROOT/f)==v for f,v in manifest['sources'].items()))
changed=['commons/artifacts/regularity/pattern_architecture.gd','commons/primitives/arrays/curved_pattern_room.gd']
check('Only two recorded production source fixes',sorted(manifest['changed'])==sorted(changed))
check('Map and other baseline artifact sources unchanged',all((ROOT/f).read_bytes()==(HERE/'before'/f).read_bytes() for f in manifest['sources'] if f not in changed and (HERE/'before'/f).exists()))
check('Frozen after sources match',all((ROOT/f).read_bytes()==(HERE/'after'/f).read_bytes() for f in manifest['sources']))
report=js(HERE/'report.json');check('39 focused native checks pass',report['passed'] and not report['failures'] and len(report['checks'])==39)
check('Visible source change and visible held image measured',report['observations']['visible_floor_changed_bytes']>10000 and report['observations']['held_floor_changed_bytes']==0)
check('Architectural print stays at physical floor height',abs(report['observations']['hall_floor_skin_height']-0.026)<0.001)
log=read(HERE/'stdout.log');check('No script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
core=js(ROOT/'commons/data/museum_core_encounters.json');previous=js(HERE/'before/commons/data/museum_core_encounters.json');entry=core['rooms']['Pattern_Foundry']
check('Catalogue manuscript and map hashes current',entry['text_sha256']==sha(ROOT/'commons/maps/Pattern_Foundry/final.md') and entry['map_sha256']==sha(ROOT/'commons/maps/Pattern_Foundry/map_data.json'))
for k in ['text_sha256','local_review']:previous['rooms']['Pattern_Foundry'][k]=entry[k]
check('Only Foundry chapter reference changed in catalogue',core==previous)
capture=js(ROOT/'doc/book/captures/tiling/tiling-book.manifest.json')
check('All eight Patterns chapters current',len(capture['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in capture['maps']))
check('Capture output hash current',sha(ROOT/'doc/book/captures/tiling/tiling-book.md')==capture['output_sha256'])
for n in ['tiling-book.md','tiling-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/tiling'/n,HERE/n)
photos=['room-pair','floor-repair','sample-pair','floor-pair']
for n in photos:
 with Image.open(HERE/(n+'.png')) as im:im.verify()
check('Native paired figures readable',True)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-disco-colour-in-step/index.html'),re.S).group(1)
rows=''.join('<tr><td>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in js(HERE/'changes.json'))
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Foundry — a mark in the room</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">PATTERN_FOUNDRY · 28 SEPTEMBER 2026</p><h1>A mark can reach around you.</h1><p>Follow one source edit into its copies. Then let the floor keep an earlier image while the wall changes.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the museum</a><a href="#changes">Before and after</a><a href="#decisions">Decisions and evidence</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Pattern_Foundry&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="museum"><h2>The room keeps two moments</h2><figure><a href="room-pair.png"><img src="room-pair.png" alt="The same standing view inside the curved room: black and white floor beneath a wall that changes to red."></a><figcaption>The room begins with both surfaces following the studio. After holding ROOM FLOOR, another edit reaches the wall while the ground stays as it was.</figcaption></figure><figure><a href="sample-pair.png"><img src="sample-pair.png" loading="lazy" alt="A flat sample and a bent sample share a mark; after holding the curve only the flat one follows the next source edit."></a><figcaption>The smaller comparison remains: equal sheet dimensions and colour addresses, different shapes and independently held images.</figcaption></figure><h2>Restoring the floor the text asks you to see</h2><figure><a href="floor-repair.png"><img src="floor-repair.png" loading="lazy" alt="Before the repair the hall-wide carpet image covers the room floor; after the repair the studio's print becomes visible underfoot."></a><figcaption>The first photograph exposed a real defect. The room's floor texture updated underneath another print. Correcting the architecture's height and the local drawing order makes that encounter visible.</figcaption></figure><figure><a href="floor-pair.png"><img src="floor-pair.png" loading="lazy" alt="The actual ground before and after painting one studio source cell."></a><figcaption>A closer downward view from standing height verifies the source change reaches visible ground. The next edit leaves this ground unchanged when its receiver is held.</figcaption></figure></section>
<section id="changes"><h2>What changed in the writing</h2><p>The first visit follows a single decision. Detailed controls move into the return visit, while the room's initial live connection is made explicit. The argument about retaining one difference stays.</p><p><a href="Pattern_Foundry.diff">Exact manuscript diff</a> · <a href="before/commons/maps/Pattern_Foundry/final.md">Complete previous chapter</a> · <a href="Pattern_Foundry.current.md">Current chapter</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">39 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Recorded source hashes</a> · <a href="pattern_architecture.diff">Hall-print repair</a> · <a href="curved_pattern_room.diff">Local-floor repair</a> · <a href="tiling-book.md">Complete Patterns capture</a></p><p>Next: <a href="/compose/sources?map=Tutorial_Pattern&amp;doc=final">Tutorial_Pattern</a>.</p></section></main></body></html>'''
soup=BeautifulSoup(page,'html.parser');ids=[x['id'] for x in soup.find_all(id=True)]
check('Unique review IDs',len(ids)==len(set(ids)))
check('Review section anchors resolve',all(x['href'][1:] in ids for x in soup.find_all('a',href=True) if x['href'].startswith('#')))
check('All review photographs resolve',all((ROOT/x['src'].removeprefix('/book-review/')).is_file() if x['src'].startswith('/book-review/') else (HERE/x['src']).is_file() for x in soup.find_all('img',src=True)))
(HERE/'index.html').write_bytes(page.encode('utf-8'));(HERE/'checks.json').write_bytes(json.dumps({'passed':True,'checks':checks},indent=2).encode())
served=[]
for n in ['index.html','room-pair.png','sample-pair.png','floor-repair.png','floor-pair.png','report.json','Pattern_Foundry.diff','pattern_architecture.diff','curved_pattern_room.diff','tiling-book.md','Pattern_Foundry.current.md']:
 matches=urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/'+n,timeout=10).read()==(HERE/n).read_bytes();assert matches,n;served.append({'file':n,'matches':matches})
(HERE/'http-checks.json').write_bytes(json.dumps({'passed':True,'files':served},indent=2).encode())
print(f'{len(checks)} publication checks, {len(served)} served files; native 39/39.')
