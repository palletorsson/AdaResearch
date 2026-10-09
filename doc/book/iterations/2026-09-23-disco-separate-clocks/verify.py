from pathlib import Path
import json,re,hashlib,urllib.request
from PIL import Image
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3];checks=[]
def check(name,passed):checks.append({'name':name,'passed':bool(passed)})
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=(OUT/'Tutorial_Disco.before.md').read_text(encoding='utf-8');after=(OUT/'Tutorial_Disco.after.md').read_text(encoding='utf-8');final=ROOT/'commons/maps/Tutorial_Disco/final.md'
check('Canonical chapter equals published reading',after==final.read_text(encoding='utf-8'))
check('Code and artifact anchors preserved',re.findall(r'```.*?```',before,re.S)==re.findall(r'```.*?```',after,re.S) and re.findall(r'<!--.*?-->',before)==re.findall(r'<!--.*?-->',after))
check('Closing question and Color handoff preserved',after.strip().split('\n\n')[-3:]==before.strip().split('\n\n')[-3:])
image_block=next(p for p in after.split('\n\n') if p.startswith('![The same checker'));caption_block=next(p for p in after.split('\n\n') if p.startswith('*One step apart'))
restored=after.replace(image_block+'\n\n'+caption_block+'\n\n','').replace('You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again. Stand still and let the pattern move beneath you. Then stop one of its clocks.','You have seen slots hold values and a motif repeat across floors and walls. Here the floor is black and white again, but its arrangement moves. Begin by stopping one of its clocks.')
check('Only opening and shared figure change the chapter',restored==before)
base=json.loads((OUT/'baseline-hashes.json').read_text())
for rel,h in base.items():
 if rel.endswith(('final.md','intent.md','technical.md','critical.md','museum_core_encounters.json')):continue
 check('Production input preserved: '+rel,sha(ROOT/rel)==h)
for name in ['critical.md','technical.md']:
 rel='commons/maps/Tutorial_Disco/'+name;check('Full prior proposal retained: '+name,sha(OUT/'before'/rel)==base[rel])
core=json.loads((ROOT/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8'));old=json.loads((OUT/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8'));room=core['rooms']['Tutorial_Disco'];check('Core hashes current',room['text_sha256']==sha(final) and room['map_sha256']==sha(ROOT/'commons/maps/Tutorial_Disco/map_data.json'));check('Existing primary selection preserved',room['primary_tokens']==old['rooms']['Tutorial_Disco']['primary_tokens']);core['rooms'].pop('Tutorial_Disco');old['rooms'].pop('Tutorial_Disco');check('Other hall records unchanged',core==old)
report=json.loads((OUT/'report.json').read_text());check('All 51 focused runtime checks pass',report['passed'] and len(report['checks'])==51 and all(c['passed'] for c in report['checks']) and not report['failures'])
check('Captured production scripts still current',all(sha(ROOT/k)==v for k,v in report['observations'].items() if k.endswith('.gd')))
check('Earlier instrument and score verifier sources unchanged',all(json.loads((OUT/'prior-evidence-comparison.json').read_text()).values()))
check('No GDScript failure in final capture log','SCRIPT ERROR' not in (OUT/'stdout.log').read_text(encoding='utf-8',errors='replace'))
for p in OUT.glob('*.png'):
 with Image.open(p) as im:im.verify()
check('All source and composed PNGs decode',True)
check('All twelve native row states are present',all((OUT/f'rows-{i:02}.png').exists() for i in range(12)))
page=(OUT/'index.html').read_text(encoding='utf-8');check('Viewer has play/pause and disclosed interval',all(s in page for s in ['id="row-play"','stopRows()','}, 750)','0.75 seconds']))
check('Unsupported GIF link removed','rows-in-time.gif' not in page)
baseurl='http://localhost:3003/book-review/doc/book/iterations/2026-09-23-disco-separate-clocks/'
for name in ['index.html','fixed-addresses-changing-values.png','Tutorial_Disco.diff']:
 with urllib.request.urlopen(baseurl+name,timeout=15) as r:check('HTTP bytes: '+name,r.status==200 and r.read()==(OUT/name).read_bytes())
rows_ok=True
for i in range(12):
 name=f'rows-{i:02}.png'
 with urllib.request.urlopen(baseurl+name,timeout=15) as r:rows_ok=rows_ok and r.status==200 and r.read()==(OUT/name).read_bytes()
check('All twelve viewer frames are served correctly',rows_ok)
check('Review links to reading, changes, evidence and current source',all(s in page for s in ['id="reading"','id="comparison"','id="evidence"','/compose/sources?map=Tutorial_Disco']))
verification={'passed':all(c['passed'] for c in checks),'checks':checks,'scope':'Bounded manuscript diff, preserved production and proposals, source/evidence correspondence, image decoding and HTTP routes. Native/composed images visually inspected; viewer JavaScript syntax checked separately with node --check. Browser click check unavailable: browser tool kernel failed its Windows sandbox setup; interactive UI acceptance is not claimed.'}
(OUT/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8');(OUT/'publication-sources.json').write_text(json.dumps({p:sha(ROOT/p) for p in [*base.keys(),'tools/probes/disco_separate_clocks.gd']},indent=2),encoding='utf-8')
print(len(checks),'checks; all passed:',verification['passed']);print([c['name'] for c in checks if not c['passed']]);assert verification['passed']
