from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name
changed={'commons/maps/Color_Nails/final.md','commons/maps/Color_Nails/tutorial.md','commons/maps/Color_Nails/field_notes.md','commons/data/museum_core_encounters.json'}
for name,digest in json.loads(read(HERE/'baseline.json')).items():
 if name not in changed:check('Preserved '+name,sha(ROOT/name)==digest)
rel=Path('commons/maps/Color_Nails/final.md');old=read(HERE/'before'/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/'changes.json'))
figure=re.search(r'!\[[^\]]*\]\([^\n]+\)',old).group(0)
expected=old
for change in changes:expected=expected.replace(change['before'],change['after'])
check('Only the two recorded passage changes',expected==new)
check('Code preserved exactly',re.findall(r'```gdscript.*?```',old,re.S)==re.findall(r'```gdscript.*?```',new,re.S))
check('Encounter anchors preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Finger-length question and Rainbow handoff preserved',old[old.index('You have chosen their colour.'):]==new[new.index('You have chosen their colour.'):])
check('Existing figure unchanged',re.findall(r'!\[[^\]]*\]\([^\n]+\)',old)==re.findall(r'!\[[^\]]*\]\([^\n]+\)',new))
image_path=re.search(r'\]\(([^)]+)\)',figure).group(1)
with Image.open(ROOT/image_path.removeprefix('/book-review/')) as im:im.verify()
check('Native figure readable',True)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));entry=core['rooms']['Color_Nails']
check('Catalogue text hash current',entry['text_sha256']==sha(ROOT/rel))
for key in ['text_sha256','local_review']:before['rooms']['Color_Nails'][key]=entry[key]
check('Only this chapter hash and review changed in catalogue',core==before)
manifest=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current chapter sources',len(manifest['maps'])==8 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Current capture hash',sha(ROOT/'doc/book/captures/color/color-book.md')==manifest['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
(HERE/'Color_Nails.current.md').write_text(new,encoding='utf-8')
(HERE/'Color_Nails.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Nails/final.md',tofile='current/Color_Nails/final.md')),encoding='utf-8')
rows=''.join('<tr><td><h3>'+c['label']+'</h3>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-colour-another-order/index.html'),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The next choice — Nails</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_NAILS · 28 SEPTEMBER 2026 · CHOOSING AND WEARING</p><h1>The next choice.</h1><p>The hand making the next choice is already wearing the last one.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Compare two passages</a><a href="#decisions">Decisions and evidence</a><a href="color-book.md">Full Colour capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Nails&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Two small changes in a working encounter</h2><p>Keep the chosen nail colour while changing the skin; return to the control with the hand now wearing a choice. The salon, its scale contrast and its manicure ritual remain.</p><p>{len(old.split())} → {len(new.split())} words, including code and caption. <a href="Color_Nails.diff">Exact text diff</a> · <a href="Color_Nails.current.md">Current Markdown</a></p><table class="passages"><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="source-comparison.json">Source comparison</a> · <a href="/book-review/doc/book/iterations/2026-09-24-colour-review-comments/nails/report.json">Earlier native evidence, 24 September</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.manifest.json">Capture manifest</a></p></section>
<footer><p class="source-note">The existing 24 September museum image shows the salon's display hands. This writing pass does not present it as a fresh capture or a headset photograph.</p><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-flashlight-a-colour-between/index.html">A colour between</a>. Next: <a href="/compose/sources?map=Color_Rainbow&amp;doc=final">Colour and welcome</a>.</p></footer></main></body></html>"""
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'words':{'before':len(old.split()),'after':len(new.split())},'scope':'Editorial changes and preservation, current Colour capture; no runtime replay.'},indent=2)+'\n',encoding='utf-8')
print(len(checks),'publication checks passed; words',len(old.split()),'->',len(new.split()))
