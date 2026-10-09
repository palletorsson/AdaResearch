from pathlib import Path
import json,hashlib,re,difflib,urllib.request
from PIL import Image
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3];checks=[]
def check(name,value):
 checks.append({'name':name,'passed':bool(value)})
 print(('PASS ' if value else 'FAIL ')+name)
base=json.loads((OUT/'baseline-hashes.json').read_text());after=json.loads((OUT/'after-hashes.json').read_text());r=json.loads((OUT/'report.json').read_text())
check('Godot probe passes all focused checks',r['passed'] and all(c['passed'] for c in r['checks']))
for relative in ['commons/context/discofloor/StandaloneDiscoFloor.gd','commons/context/discofloor/DiscoSequencerBridge.gd','commons/maps/Tutorial_Disco/map_data.json','commons/maps/sequences/array_tutorial.json']:
 check('preserved '+relative,hashlib.sha256((ROOT/relative).read_bytes()).hexdigest()==base[relative])
check('published current-source snapshots match',all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in after.items()))
check('tested runtime source hashes match',all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in r['observations'].items() if p.startswith('commons/')))
old=(OUT/'Tutorial_Disco.before.md').read_text(encoding='utf-8');new=(OUT/'Tutorial_Disco.after.md').read_text(encoding='utf-8')
check('reading matches canonical final.md',new==(ROOT/'commons/maps/Tutorial_Disco/final.md').read_text(encoding='utf-8'))
added=new[new.index('Change PATTERN once more'):new.index('The console controls this visual clock.')]
check('all prior manuscript prose remains',new.replace(added,'')==old)
check('all artifact anchors retained',re.findall(r'<!--.*?-->',new)==re.findall(r'<!--.*?-->',old))
check('exact manuscript diff reconstructs current comparison',(OUT/'Tutorial_Disco.diff').read_text(encoding='utf-8')==''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/commons/maps/Tutorial_Disco/final.md',tofile='commons/maps/Tutorial_Disco/final.md')))
core=json.loads((ROOT/'commons/data/museum_core_encounters.json').read_text());prior=json.loads((OUT/'before/commons/data/museum_core_encounters.json').read_text())
check('other halls metadata remains unchanged',all(v==core[k] for k,v in prior.items() if k!='rooms') and all(v==core['rooms'][k] for k,v in prior['rooms'].items() if k!='Tutorial_Disco'))
check('primary encounters remain',core['rooms']['Tutorial_Disco']['primary_tokens']==prior['rooms']['Tutorial_Disco']['primary_tokens'])
check('current chapter hash recorded',core['rooms']['Tutorial_Disco']['text_sha256']==hashlib.sha256((ROOT/'commons/maps/Tutorial_Disco/final.md').read_bytes()).hexdigest())
check('96 complete native motion frames',all((OUT/f'motion-{i:03}.png').is_file() and Image.open(OUT/f'motion-{i:03}.png').size==(768,512) for i in range(96)))
page=(OUT/'index.html').read_text(encoding='utf-8');check('shared book figure appears in both views','triangle-combinations.png' in new and 'triangle-combinations.png' in page)
baseurl='http://localhost:3003/book-review/doc/book/iterations/2026-09-23-disco-super-triangle/'
for name in ['index.html','triangle-combinations.png','motion-000.png','motion-031.png','motion-095.png','report.json','Tutorial_Disco.diff']:
 try:
  with urllib.request.urlopen(baseurl+name,timeout=10) as response:check('served '+name,response.status==200 and response.read()==(OUT/name).read_bytes())
 except Exception as e:check('served '+name,False);print(str(e))
script=(OUT/'motion-viewer.js').read_text(encoding='utf-8');check('embedded script matches checked viewer',script in page)
result={'passed':all(c['passed'] for c in checks),'checks':checks,'runtime_checks':len(r['checks']),'scope':'Preservation, current source hashes, publication assets; native scene rendering and supplied input are documented separately.'}
(OUT/'verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print('PUBLICATION',sum(c['passed'] for c in checks),'/',len(checks));raise SystemExit(0 if result['passed'] else 1)
