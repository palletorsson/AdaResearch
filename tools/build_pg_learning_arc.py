"""Render the agreed pedagogical arc; gameplay mutations are handled separately."""
from pathlib import Path
import hashlib,json,re
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';E=R/'doc/space/pg-learning-arc-2026-09-14'
E.mkdir(parents=True,exist_ok=True)
css=re.search(r'<style>(.*?)</style>',(O/'recursion-encounter.html').read_text(),re.S).group(1)
body=markdown.markdown((O/'pg-learning-arc.md').read_text(),extensions=['tables'])
style='table{width:100%;border-collapse:collapse;font-size:.88rem}td,th{padding:.7rem;border-bottom:1px solid #425050;text-align:left;vertical-align:top}th{color:#a9dacb}td:first-child{min-width:125px}h2{margin-top:2.5rem}@media(max-width:900px){table{display:block;overflow-x:auto}}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Procedural generation · Learning arc · Ada Research</title><style>'+css+style+'</style></head><body><main><nav><a href="genetic-evolution.html">Genetic Evolution</a><a href="pg-floor-audit.html">Floor audit</a><a href="spine-iteration.html">First traverse, then return</a></nav><article class="manuscript">'+body+'</article></main></body></html>'
(O/'pg-learning-arc.html').write_bytes(page.encode())
assets=['possible-bodies/pg-learning-arc.md','possible-bodies/pg-learning-arc.html']
for name,data in [('publish-targets.json',assets),('publish-hashes.json',{a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in assets})]:
 (E/name).write_bytes((json.dumps(data,indent=2)+'\n').encode())
print('Built the two learning-arc assets from the current agreed progress.')
