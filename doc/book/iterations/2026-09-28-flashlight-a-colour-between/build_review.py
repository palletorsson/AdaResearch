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
changed={'commons/maps/Color_Flashlight/final.md','commons/maps/Color_Flashlight/tutorial.md','commons/maps/Color_Flashlight/field_notes.md','commons/data/museum_core_encounters.json'}
for name,digest in json.loads(read(HERE/'baseline.json')).items():
 if name not in changed:check('Preserved '+name,sha(ROOT/name)==digest)
rel=Path('commons/maps/Color_Flashlight/final.md');old=read(HERE/'before'/rel);new=read(ROOT/rel)
changes=json.loads(read(HERE/'changes.json'))
figure=re.search(r'!\[[^\]]*\]\([^\n]+\)',old).group(0)
expected=old.replace(changes[0]['before'],changes[0]['after']).replace(changes[1]['before']+'\n\n','').replace(figure,figure+'\n\n'+changes[1]['after'])
check('Only recorded wording edits and assignment relocation',expected==new)
check('Code preserved exactly',re.findall(r'```gdscript.*?```',old,re.S)==re.findall(r'```gdscript.*?```',new,re.S))
check('Encounter anchors preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Limits, critical ending and Nails handoff preserved',old[old.index('There is a useful limit here.'):]==new[new.index('There is a useful limit here.'):])
check('Follow board and sphere before code',new.index('Aim a beam off')<new.index('Beside the board stands')<new.index('```gdscript'))
check('Existing figure unchanged',re.findall(r'!\[[^\]]*\]\([^\n]+\)',old)==re.findall(r'!\[[^\]]*\]\([^\n]+\)',new))
image_path=re.search(r'\]\(([^)]+)\)',figure).group(1)
with Image.open(ROOT/image_path.removeprefix('/book-review/')) as im:im.verify()
check('Native figure readable',True)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));entry=core['rooms']['Color_Flashlight']
check('Catalogue text hash current',entry['text_sha256']==sha(ROOT/rel))
for key in ['text_sha256','local_review']:before['rooms']['Color_Flashlight'][key]=entry[key]
check('Only this chapter hash and review changed in catalogue',core==before)
manifest=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current chapter sources',len(manifest['maps'])==8 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Current capture hash',sha(ROOT/'doc/book/captures/color/color-book.md')==manifest['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
(HERE/'Color_Flashlight.current.md').write_text(new,encoding='utf-8')
(HERE/'Color_Flashlight.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Flashlight/final.md',tofile='current/Color_Flashlight/final.md')),encoding='utf-8')
rows=''.join('<tr><td><h3>'+c['label']+'</h3>'+render(c['before'])+'</td><td>'+render(c['after'])+'</td></tr>' for c in changes)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-colour-another-order/index.html'),re.S).group(1)
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A colour between — Flashlight</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_FLASHLIGHT · 28 SEPTEMBER 2026 · LIGHT AND RELATION</p><h1>A colour between.</h1><p>One face brightens while its neighbour stays dull. Move the lamp, and the difference changes places. No face has been repainted.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Compare the passages</a><a href="#decisions">Decisions and evidence</a><a href="color-book.md">Full Colour capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Flashlight&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Follow the light before reading its value</h2><p>The code and channel explanation now follow the board-to-sphere encounter and its figure. The exact diff includes that move. The two wording changes appear below; the ending remains intact.</p><p>{len(old.split())} → {len(new.split())} words, including code and caption. <a href="Color_Flashlight.diff">Exact text diff</a> · <a href="Color_Flashlight.current.md">Current Markdown</a></p><table class="passages"><thead><tr><th>Before this pass</th><th>Current final.md</th></tr></thead><tbody>{rows}</tbody></table></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}<p><a href="source-comparison.json">Source comparison</a> · <a href="/book-review/doc/book/iterations/2026-09-23-flashlight-faceted-sphere/report.json">Earlier native evidence, 23 September</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="color-book.manifest.json">Capture manifest</a></p></section>
<footer><p class="source-note">The native museum figure retains its 23 September source date. This writing pass does not present it as a new capture.</p><p>Previous: <a href="/book-review/doc/book/iterations/2026-09-28-colour-another-order/index.html">Another order among the parts</a>. Next: <a href="/compose/sources?map=Color_Nails&amp;doc=final">The choosing hand</a>.</p></footer></main></body></html>"""
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'words':{'before':len(old.split()),'after':len(new.split())},'scope':'Editorial changes and preservation, current Colour capture; no runtime replay.'},indent=2)+'\n',encoding='utf-8')
print(len(checks),'publication checks passed; words',len(old.split()),'->',len(new.split()))
