"""Build the local review only from passing, source-current runtime evidence."""
from pathlib import Path
import hashlib,json,re,shutil
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';E=R/'doc/space/space-colonization-2026-09-14';RUN=R/'ada_run/colonization-review-2026-09-14';M='PG_Space_Colonization'
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
r=json.loads((RUN/'run.json').read_text());assert r['exit']==0 and not r['failures'] and r['sources_unchanged'] and r['original_hand_unchanged']
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in r['source_sha256'].items())
assets=[]
for name in ['entrance','decision','policies','canopy','controls','platforms','ramp']:
 p=O/f'colonization-{name}.png';shutil.copyfile(RUN/M/f'{name}.png',p);assets.append(p.name)
for kind in ['final','technical','critical','tutorial']:
 for previous in [False,True]:
  p=O/f'colonization-{"previous-" if previous else ""}{kind}.md';shutil.copyfile((E/'before' if previous else R)/f'commons/maps/{M}/{kind}.md',p);assets.append(p.name)
dump(O/'colonization-verification.json',r);assets.append('colonization-verification.json')
css=re.search(r'<style>(.*?)</style>',(O/'recursion-encounter.html').read_text(),re.S).group(1)
book=markdown.markdown((R/f'commons/maps/{M}/final.md').read_text(),extensions=['fenced_code'])
page=(R/'ada_run/colonization-page.html').read_text()
(O/'space-colonization.html').write_bytes(page.replace('__CSS__',css).replace('__BOOK__',book).replace('__CHECKS__',str(r['checks'])).encode());assets.append('space-colonization.html')
for src,dst in [(RUN/'run.json',E/'receipt.json'),(RUN/M/'probe_ca_edge_live.json',E/'runtime-report.json'),(RUN/M/'engine.log',E/'engine.log')]:shutil.copyfile(src,dst)
targets=['possible-bodies/'+a for a in assets]
# The progress pages are built separately before this manifest is assembled.
targets+=['possible-bodies/'+a for a in ['pg-learning-arc.html','pg-learning-arc.md','spine-iteration.html','spine-iteration.md']]
dump(E/'publish-targets.json',targets);dump(E/'publish-hashes.json',{a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in targets})
print(f'Built Space Colonization review: {len(targets)} assets; {r["checks"]} runtime checks.')
