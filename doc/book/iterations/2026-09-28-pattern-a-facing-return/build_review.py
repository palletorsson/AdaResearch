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
old=read(HERE/'before/commons/maps/Tutorial_Pattern/final.md');new=read(ROOT/'commons/maps/Tutorial_Pattern/final.md')
check('Artifact and closing anchors retained',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Three exact source excerpts retained',len(re.findall(r'```.*?```',new,re.S))==3 and re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',new,re.S))
check('Critical interruption paragraph retained',next(p for p in old.split('\n\n') if p.startswith('A repeating system can')) in new)
check('Both observations precede implementation',new.index('Now press FLIP X')<new.index('```glsl'))
check('Current chapter snapshot matches',read(HERE/'Tutorial_Pattern.current.md')==new)
manifest=js(HERE/'encounter-sources.json')
check('Production source hashes current',all(sha(ROOT/f)==v for f,v in manifest['sources'].items()))
check('Artifact shader scene and map unchanged',all((ROOT/f).read_bytes()==(HERE/'before'/f).read_bytes() for f in manifest['sources']))
check('Critical and technical companions preserved',all((ROOT/'commons/maps/Tutorial_Pattern'/n).read_bytes()==(HERE/'before/commons/maps/Tutorial_Pattern'/n).read_bytes() for n in ['critical.md','technical.md']))
report=js(HERE/'report.json');check('40 native checks pass',report['passed'] and not report['failures'] and len(report['checks'])==40)
check('Rendered rule switch changes only the measured floor',report['observations']['floor_changed_bytes']>10000 and report['observations']['reference_rule_switch_changed_bytes']==0)
log=read(HERE/'stdout.log');check('No script or shader errors','SCRIPT ERROR' not in log and 'SHADER ERROR' not in log)
core=js(ROOT/'commons/data/museum_core_encounters.json');previous=js(HERE/'before/commons/data/museum_core_encounters.json');entry=core['rooms']['Tutorial_Pattern']
check('Catalogue manuscript and map hashes current',entry['text_sha256']==sha(ROOT/'commons/maps/Tutorial_Pattern/final.md') and entry['map_sha256']==sha(ROOT/'commons/maps/Tutorial_Pattern/map_data.json'))
for k in ['text_sha256','map_sha256','local_review']:previous['rooms']['Tutorial_Pattern'][k]=entry[k]
check('Only current chapter references and stale map hash changed in catalogue',core==previous)
capture=js(ROOT/'doc/book/captures/tiling/tiling-book.manifest.json')
check('All eight Patterns chapters current',len(capture['maps'])==8 and all(sha(ROOT/x['path'])==x['sha256'] for x in capture['maps']))
check('Capture output hash current',sha(ROOT/'doc/book/captures/tiling/tiling-book.md')==capture['output_sha256'])
for n in ['tiling-book.md','tiling-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/tiling'/n,HERE/n)
photos=['source-pair','floor-pair','interruption-pair','two-fixed-fields','source-with-one-new-cell']
for n in photos:
 with Image.open(HERE/(n+'.png')) as im:im.verify()
check('Native figures readable',True)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-foundry-a-mark-in-the-room/index.html'),re.S).group(1)
rows=''.join('<tr><td>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in js(HERE/'changes.json'))
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pattern — a mark faces back</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TUTORIAL_PATTERN · 28 SEPTEMBER 2026</p><h1>The mark faces back.</h1><p>The floor can change its arrangement without changing a painted cell. Flipping the source changes the fields that read it.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">Inside the museum</a><a href="#changes">Before and after</a><a href="#decisions">Decisions and evidence</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Tutorial_Pattern&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="museum"><h2>Same cells, another relation</h2><figure><a href="floor-pair.png"><img src="floor-pair.png" alt="The actual museum floor in P1, then PM, while its source remains unchanged."></a><figcaption>The floor's rule changes. All sixteen painted cells keep their values.</figcaption></figure><figure><a href="source-pair.png"><img src="source-pair.png" loading="lazy" alt="Both reference fields change after flipping their shared source."></a><figcaption>Here the source changes. P1 and PM remain the rules of the two panels. These are crops from the same standing camera.</figcaption></figure><figure><a href="interruption-pair.png"><img src="interruption-pair.png" loading="lazy" alt="An added green cell repeats through both reference fields."></a><figcaption>A solitary source mark acquires a schedule. The fields receive its repetitions.</figcaption></figure><div class="pair"><figure><a href="two-fixed-fields.png"><img src="two-fixed-fields.png" loading="lazy" alt="Full native view of the editor and two framed panels in their museum bay."></a><figcaption>The full interior view. The existing bay and artifact remain unchanged.</figcaption></figure><figure><a href="source-with-one-new-cell.png"><img src="source-with-one-new-cell.png" loading="lazy" alt="Close view of the sixteen-cell source after adding a green cell."></a><figcaption>The small source where the second kind of change is made.</figcaption></figure></div></section>
<section id="changes"><h2>A light reading pass</h2><p>Try both reversals before the code explains them. Keep the interruption argument and its pleasure. Recall the earlier turn that symmetry can conceal.</p><p><a href="Tutorial_Pattern.diff">Exact manuscript diff</a> · <a href="before/commons/maps/Tutorial_Pattern/final.md">Complete previous chapter</a> · <a href="Tutorial_Pattern.current.md">Current chapter</a></p><table><thead><tr><th>Before</th><th>Current</th></tr></thead><tbody>{rows}</tbody></table></section>
<section id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="report.json">40 native checks</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="encounter-sources.json">Unchanged source hashes</a> · <a href="tiling-book.md">Complete Patterns capture</a></p><p>Next: <a href="/compose/sources?map=Array_Patterns&amp;doc=final">Array_Patterns</a>.</p></section></main></body></html>'''
soup=BeautifulSoup(page,'html.parser');ids=[x['id'] for x in soup.find_all(id=True)]
check('Unique review IDs',len(ids)==len(set(ids)))
check('Review section anchors resolve',all(x['href'][1:] in ids for x in soup.find_all('a',href=True) if x['href'].startswith('#')))
check('All review photographs resolve',all((ROOT/x['src'].removeprefix('/book-review/')).is_file() if x['src'].startswith('/book-review/') else (HERE/x['src']).is_file() for x in soup.find_all('img',src=True)))
(HERE/'index.html').write_bytes(page.encode('utf-8'));(HERE/'checks.json').write_bytes(json.dumps({'passed':True,'checks':checks},indent=2).encode())
served=[]
for n in ['index.html','source-pair.png','floor-pair.png','interruption-pair.png','two-fixed-fields.png','source-with-one-new-cell.png','report.json','Tutorial_Pattern.diff','tiling-book.md','Tutorial_Pattern.current.md']:
 matches=urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/'+n,timeout=10).read()==(HERE/n).read_bytes();assert matches,n;served.append({'file':n,'matches':matches})
(HERE/'http-checks.json').write_bytes(json.dumps({'passed':True,'files':served},indent=2).encode())
print(f'{len(checks)} publication checks, {len(served)} served files; native 40/40.')
