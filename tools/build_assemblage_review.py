from pathlib import Path
import hashlib,json,re,shutil
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';E=R/'doc/space/assemblage-2026-09-14';RUN=R/'ada_run/assemblage-review-2026-09-14';M='Assemblage_Same_Desire'
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
r=json.loads((RUN/'run.json').read_text());assert r['exit']==0 and not r['failures'] and r['sources_unchanged'] and r['original_hand_unchanged']
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in r['source_sha256'].items())
assets=[]
for name in ['entrance','alphabets','blocks','biased','controls','floor','atlas','origin']:
 p=O/f'assemblage-{name}.png';shutil.copyfile(RUN/M/f'{name}.png',p);assets.append(p.name)
for kind in ['final','technical','critical','tutorial']:
 for previous in [False,True]:
  if previous and not (E/'before'/f'commons/maps/{M}/{kind}.md').exists():continue
  p=O/f'assemblage-{"previous-" if previous else ""}{kind}.md';shutil.copyfile((E/'before' if previous else R)/f'commons/maps/{M}/{kind}.md',p);assets.append(p.name)
dump(O/'assemblage-verification.json',r);assets.append('assemblage-verification.json')
css=re.search(r'<style>(.*?)</style>',(O/'recursion-encounter.html').read_text(),re.S).group(1)
book=markdown.markdown((R/f'commons/maps/{M}/final.md').read_text(),extensions=['fenced_code'])
page=(R/'ada_run/assemblage-page.html').read_text()

(O/'assemblage-same-desire.html').write_bytes(page.replace('__CSS__',css).replace('__BOOK__',book).replace('__CHECKS__',str(r['checks'])).encode());assets.append('assemblage-same-desire.html')
method=markdown.markdown((O/'spine-iteration.md').read_text(),extensions=['tables','toc'])
(O/'spine-iteration.html').write_bytes(('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>First traverse. Then return. · Ada Research</title><style>'+css+'table{width:100%;border-collapse:collapse;font-size:.9rem}td,th{border-bottom:1px solid #425050;padding:.6rem;text-align:left;vertical-align:top}@media(max-width:650px){table{display:block;overflow-x:auto}}</style></head><body><main><nav><a href="assemblage-same-desire.html">Assemblage</a><a href="lsystems-living.html">Living</a><a href="/museum-progress">Museum progress</a></nav><article class="manuscript">'+method+'</article></main></body></html>').encode())
assets+=['spine-iteration.html','spine-iteration.md']
for src,dst in [(RUN/'run.json',E/'receipt.json'),(RUN/M/'probe_ca_edge_live.json',E/'runtime-report.json'),(RUN/M/'engine.log',E/'engine.log')]:shutil.copyfile(src,dst)
targets=['possible-bodies/'+a for a in assets];dump(E/'publish-targets.json',targets);dump(E/'publish-hashes.json',{a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in targets})
print(f'Built Assemblage review: {len(targets)} assets; {r["checks"]} runtime checks.')
