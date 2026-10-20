"""Publish the current Russell pair and author reconstruction receipt."""
from pathlib import Path
import hashlib
import json
import markdown
import sys

ROOT=Path(__file__).resolve().parents[1]
GODEL='--godel' in sys.argv
ESCHER='--escher' in sys.argv
BROUWER='--brouwer' in sys.argv
HALL='Brouwer_Intuitionism' if BROUWER else ('Escher_Impossible' if ESCHER else ('Godel_Incompleteness' if GODEL else 'Russell_Paradox'))
OUT=ROOT/'doc/book/iterations'/('2026-10-12-brouwer-a-choice-needs-a-witness' if BROUWER else ('2026-10-12-escher-the-route-must-return' if ESCHER else ('2026-10-12-godel-checking-is-not-searching' if GODEL else '2026-10-12-russell-the-point-tests-a-rule')))
SOURCE=ROOT/'commons/maps'/HALL
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    result=json.loads((ROOT/'doc/book/iterations/2026-10-11-foundations-reconstruction/ghost-results.json').read_text())
    assert result['passed']
    articles=[]
    for name in ['tutorial','final']:
        text=(SOURCE/f'{name}.md').read_text(encoding='utf-8')
        (OUT/f'{name}.md').write_text(text,encoding='utf-8')
        articles.append('<article>'+markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])+'</article>')
    (OUT/'receipt.json').write_text(json.dumps({'scope':'Author-operated extraction and Godot reconstruction rerun; not a new blind ghost student. 76 checks cover the six later Foundations lessons together, not Russell alone. Existing audio UID warning remains.', 'checks':len(result['checks']),'passed':result['passed'],'sources':{name:hashlib.sha256((SOURCE/name).read_bytes()).hexdigest() for name in ['tutorial.md','final.md']}},indent=2),encoding='utf-8')
    image=f'../2026-10-11-foundations-reconstruction/images/{HALL}.png'
    assert (OUT/image).exists()
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Russell — the point tests a rule</title><style>body{margin:0;padding:30px;background:#eeeae1;color:#202a34;font:18px/1.6 system-ui}header{max-width:1100px;margin:auto}h1{line-height:1.15}a{color:#286078}img{width:100%}.pair{display:grid;grid-template-columns:1fr 1fr;gap:25px}article{min-width:0;background:white;padding:28px}pre{overflow:auto;background:#192632;color:#eee;padding:20px;font-size:14px}article h1{font-size:34px}@media(max-width:900px){.pair{display:block}}</style><header><h1>The point tests a rule.</h1><p>Russell’s existing hall: carry the familiar sphere between OUT and IN. Both answers fail the unrestricted demand. Then change the domain and inspect why the restricted construction succeeds.</p><p><a href="tutorial.md">Tutorial file</a> · <a href="final.md">Reflective file</a> · <a href="receipt.json">Rerun receipt</a></p><p>76/76 checks passed across the six later Foundations lessons in an author-operated reconstruction rerun. This is not a fresh blind student run. Physical headset testing remains open; an existing audio UID warning remains in the log.</p><details><summary>Existing native museum capture</summary><img src="'''+image+'''" alt="Russell working copy inside the actual museum"><p>Earlier native capture; this text-only clarification did not change the runtime scene.</p></details><p>Tutorial left · Reflection right</p></header><div class="pair">'''+''.join(articles)+'</div></html>'
    if GODEL:
        page=page.replace('Russell — the point tests a rule','Gödel — checking is not searching').replace('The point tests a rule.','Checking is not searching.').replace('Russell’s existing hall: carry the familiar sphere between OUT and IN. Both answers fail the unrestricted demand. Then change the domain and inspect why the restricted construction succeeds.','Continue from Russell in Gödel’s existing hall. The same point marks a candidate index. Generate a derivation, check every step, increase the budget and damage a copy. A bounded miss does not establish unprovability.').replace('Russell working copy','Gödel working copy').replace('not Russell alone','not Gödel alone')
    if ESCHER:
        page=page.replace('Russell — the point tests a rule','Escher — the route must return').replace('The point tests a rule.','The route must return.').replace('Russell’s existing hall: carry the familiar sphere between OUT and IN. Both answers fail the unrestricted demand. Then change the domain and inspect why the restricted construction succeeds.','Continue from Gödel in Escher’s existing hall. The same point follows four cube centres. Measure each height change, close the circuit, then open and tilt it. Separate apparent connection from measured closure.').replace('Russell working copy','Escher working copy').replace('not Russell alone','not Escher alone')
    if BROUWER:
        page=page.replace('Russell — the point tests a rule','Brouwer — a choice needs a witness').replace('The point tests a rule.','A choice needs a witness.').replace('Russell’s existing hall: carry the familiar sphere between OUT and IN. Both answers fail the unrestricted demand. Then change the domain and inspect why the restricted construction succeeds.','Continue from Escher in Brouwer’s existing hall. Choose each next bit, identify a witness in the stored prefix, and construct a finite diagonal. Waiting supplies no next term; inspecting a finite record does not settle every continuation.').replace('Russell working copy','Brouwer working copy').replace('not Russell alone','not Brouwer alone')
    (OUT/'index.html').write_text(page,encoding='utf-8')
    print(OUT/'index.html')
if __name__=='__main__':main()
