"""Publish captured Godot evidence. No JavaScript: compatible with book-review CSP."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import html
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
KIT = ROOT/'doc/book/studies/signal-room'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

report = json.loads((KIT/'captures/report.json').read_text())
assert report['failures'] == 0, 'Refuse publication of failed native checks'
provenance = json.loads((KIT/'source-hashes.json').read_text())
for item in provenance:
    assert sha(ROOT/item['source']) == item['source_sha256']
    assert sha(KIT/item['portable']) == item['portable_sha256']
for picture in (KIT/'captures').glob('*.png'):
    shutil.copyfile(picture, HERE/picture.name)
shutil.copyfile(KIT/'captures/report.json',HERE/'verification.json')
shutil.copyfile(KIT/'native.log',HERE/'native.log')
reference = Path('C:/Users/palle/AppData/Local/Temp/codex-clipboard-c3934181-486f-4fa6-aede-8b6b7268ae68.png')
if reference.exists():
    shutil.copyfile(reference,HERE/'reference.png')
for name in ['README.md','MAKING.md','ENCOUNTER.md','LINEAGE.md','source-hashes.json']:
    shutil.copyfile(KIT/name,HERE/name)

files = [KIT/name for name in ['project.godot','gallery.gd','gallery.tscn','capture.gd','README.md','MAKING.md','ENCOUNTER.md','LINEAGE.md','source-hashes.json']]
files += [p for p in (KIT/'artifacts').iterdir() if p.suffix in ('.gd','.tscn')]
with ZipFile(HERE/'different-neighbours.zip','w',ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path,'different-neighbours/'+path.relative_to(KIT).as_posix())
(HERE/'archive-hashes.json').write_text(json.dumps({p.relative_to(KIT).as_posix():sha(p) for p in files},indent=2)+'\n')

css = '''
:root{color-scheme:dark;--paper:#101215;--ink:#f2f0ec;--muted:#b3b8c0;--line:#41454c}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.65 system-ui,sans-serif}a{color:inherit;text-underline-offset:5px}header,main,footer{max-width:1400px;margin:auto;padding:45px 36px}header{padding-top:74px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.05}h1{font-size:clamp(54px,8vw,105px);margin:24px 0;max-width:900px}h2{font-size:clamp(35px,4vw,58px);margin:20px 0 28px}h3{font-size:20px}.eyebrow{text-transform:uppercase;letter-spacing:.16em;font-size:12px}.lead{font-size:24px;max-width:880px}.muted,figcaption{font-size:14px;color:var(--muted)}nav{padding:16px 36px;display:flex;gap:30px;border-block:1px solid var(--line);overflow:auto;background:#101215f5;position:sticky;top:0;z-index:3}nav a{white-space:nowrap;font-size:14px;text-decoration:none}section{padding-top:55px;margin-bottom:55px;scroll-margin-top:65px}figure{margin:25px 0}img{width:100%;display:block;height:auto}figcaption{margin:12px 0}.actions{display:flex;flex-wrap:wrap;gap:12px;margin:22px 0}.button{padding:10px 18px;border:1px solid #89909a;display:inline-block;text-decoration:none;font-size:15px;cursor:pointer;background:#171b20}.button:hover{background:#30363e}.choice{position:absolute;width:1px;height:1px;opacity:0}.state{display:none}.repeat:checked~.repeated,.rows:checked~.row-shuffle,.cells:checked~.cell-shuffle{display:block}.repeat:checked~.actions label[for=repeat],.rows:checked~.actions label[for=rows],.cells:checked~.actions label[for=cells]{background:#e1e5e9;color:#111}.choice:focus-visible~.actions{outline:2px solid #b8dcff;outline-offset:4px}article{max-width:780px;margin:38px auto;font:25px/1.7 Georgia,serif}.notes{display:grid;grid-template-columns:1fr 1fr;gap:42px}.notes p{font-size:17px}.reading{max-width:880px;margin:auto}.reading h1{font-size:50px}.reading h2{font-size:34px;margin-top:45px}.reading p{font-size:19px}pre{white-space:pre;overflow:auto;background:#22272e;padding:20px;font:16px/1.6 monospace}code{font-size:.87em}table{border-collapse:collapse;width:100%;font-size:16px}td,th{padding:15px;text-align:left;border-bottom:1px solid var(--line)}.status{border-left:2px solid #aab1bc;padding-left:20px;max-width:870px}.references summary{cursor:pointer;font-size:17px}.references img{max-width:1010px;margin:25px auto}footer{border-top:1px solid var(--line)}a:focus-visible,summary:focus-visible{outline:3px solid #b8dcff;outline-offset:5px}@media(max-width:760px){header,main,footer{padding:26px 18px}.notes{grid-template-columns:1fr;gap:18px}nav{padding:13px 18px;gap:18px}article{font-size:22px}.lead{font-size:21px}table{font-size:14px}td,th{padding:10px}section{padding-top:35px}}
'''

def md(name):
    return markdown.markdown((KIT/name).read_text(encoding='utf-8'),extensions=['fenced_code','tables'])

def fig(name,caption):
    return f'<figure><img src="{name}.png" alt="{html.escape(caption)}" loading="lazy" width="1600" height="1000"><figcaption>{caption}</figcaption></figure>'

encounter = md('ENCOUNTER.md')
encounter = encounter[encounter.index('</h1>')+5:]
count = len(report['checks'])
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Different neighbours · Ada</title><style>{css}</style>
<header><div class="eyebrow">Ada / Arrays return in Randomness / 01 October 2026</div><h1>Different neighbours.</h1><p class="lead">The whole room becomes a display. One small array reaches under your feet, up the wall and over your head.</p><p>4,096 addresses. Two values. Three ways to arrange them.</p><div class="actions"><a class="button" href="#room">Compare the rules</a><a class="button" href="different-neighbours.zip" download>Download the Godot room</a><a class="button" href="#reading">Read the passage</a></div><p class="muted">Original working study prompted by Ryoji Ikeda. Every room image below is a native Godot 4.6 capture.</p></header>
<nav aria-label="On this page"><a href="#room">01 / Whole room</a><a href="#sample">02 / Sixteen cells</a><a href="#reading">03 / Encounter</a><a href="#lineage">04 / Capability ladder</a><a href="#making">05 / Make a change</a><a href="#evidence">06 / Evidence</a></nav>
<main><section id="room"><div class="eyebrow">Hold the inventory. Change the order.</div><h2>What changes when<br>nothing is added?</h2><p>These three views keep the camera, geometry and number of each value fixed. Select a rule to compare the rendered result.</p>
<div class="compare"><input class="choice repeat" type="radio" id="repeat" name="rule" checked><input class="choice rows" type="radio" id="rows" name="rule"><input class="choice cells" type="radio" id="cells" name="rule"><div class="actions"><label class="button" for="repeat">01 · Repeat</label><label class="button" for="rows">02 · Shuffle rows</label><label class="button" for="cells">03 · Shuffle cells</label></div>
<div class="state repeated">{fig('repeat','Repeat · Two complementary banks; two-row bands. 2,048 black + 2,048 white.')}</div>
<div class="state row-shuffle">{fig('rows','Shuffle rows · Each row stays whole. A seeded permutation changes their order. The inventory stays fixed.')}</div>
<div class="state cell-shuffle">{fig('cells','Shuffle cells · Each individual value can change address. Exactly the same numbers of black and white remain.')}</div></div>
<div class="notes"><div><h3>One record surrounds a body</h3><p>The floor and far wall unfold the array continuously across their crease. Side monitors and a ceiling strip echo the same record. They are additional views of one array.</p></div><div><h3>Still enough to inspect</h3><p>The room waits for a choice. Change mode, choose a seed or advance the display by one row. The dark cells remain solid underfoot. There is no automatic flashing or soundtrack.</p></div></div>
{fig('inside','Inside the room at eye level. The side monitor repeats the record; the floor continues up the end wall.')}</section>
<section id="sample"><div class="eyebrow">Local evidence</div><h2>Sixteen cells you can count.</h2><p>The entrance monitor reads a 4 × 4 patch from the room’s displayed array. Its slider moves the window through the rows. Columns 6–9 straddle the two original banks.</p>{fig('sample','The same array, close enough to read: rows 90–93, columns 6–9, cell shuffle, seed 2026. The grid outlines include the black cells.')}
<p class="status">All three arrangements have marginal Shannon entropy <strong>H = 1 bit per symbol</strong>. That calculation counts the shares of black and white; it does not read their neighbours. A separate readout counts unequal adjacent pairs. More visible disorder does not make this particular entropy gauge rise.</p></section>
<section id="reading"><div class="eyebrow">Proposed companion passage</div><h2>Different neighbours</h2><article>{encounter}</article></section>
<section id="lineage"><div class="eyebrow">A return through earlier tools</div><h2>After Random Entropy.</h2><p>This is where the study fits: the learner can already address an array, repeat a small rule and use a seed. Now they decide which relations a rearrangement may break.</p><table><thead><tr><th>Stage</th><th>What we carry</th><th>What becomes possible here</th></tr></thead><tbody><tr><td>Array / Tutorial 3D</td><td>Index, value, row and column</td><td>One address can be inspected inside the whole.</td></tr><tr><td>Tiling / Disco</td><td>Local rule, repetition and an explicit step</td><td>A small decision becomes a surrounding pattern.</td></tr><tr><td>Random Definition / Entropy</td><td>Seed, procedure, counts and the limits of a gauge</td><td>Shuffle an existing inventory; compare what changes and what survives.</td></tr><tr><td>Later return</td><td>Texture coordinates or source-data encoding</td><td>Open the display apparatus or give its values a declared source.</td></tr></tbody></table>
<p class="status"><strong>Status:</strong> built and tested as a desktop chapter companion. It is registered, but not yet installed as a museum-spine stop. Promotion needs its own bay, main-player controls and connected entrance/exit. The current Random_Entropy hall keeps its existing works.</p><p><a href="/tutorial-lineage#node=random">Open the capability ladder</a> · <a href="/compose/sources?map=Random_Entropy&amp;doc=tutorial">Random Entropy tutorial</a> · <a href="README.md">Source and placement notes</a></p></section>
<section id="making"><div class="eyebrow">The small code decision</div><div class="reading">{md('MAKING.md')}</div>{fig('controls','Native desktop controls. The downloaded room includes walking, seed replay, three rules, a row step and the linked 4 × 4 inspection.')}</section>
<section id="evidence"><div class="eyebrow">What has been checked</div><h2>{count} native checks passed.</h2><p>Verified binary inventories, row preservation, seed replay, distinct rendered states, exact reset, 4 × 4 address agreement, the floor-to-wall UV seam, row-offset wrap, and the same visitor capsule crossing all three floor states. Walls block the capsule; the viewer can enter and leave walking mode.</p><p class="muted">Godot 4.6 / GL Compatibility / {html.escape(report['renderer'])}. {report['room_children']} immediate room children; one 16 × 256 display texture. These are standalone-room tests, not production-museum, learner or headset acceptance.</p><div class="actions"><a class="button" href="verification.json">Native check report</a><a class="button" href="source-hashes.json">Source provenance</a><a class="button" href="archive-hashes.json">Download contents</a></div>
<details class="references"><summary>Reference and the limits of the comparison</summary><img src="reference.png" alt="User-supplied slide headed Ryoji Ikeda, with a floor-to-wall black and white display"><p>The supplied slide names Datamatics; the exact photographed work and edition have not been verified. Ikeda’s <a href="https://www.ryojiikeda.com/project/testpattern/">own description of test pattern</a> explains a system that encodes source data into binary and barcode patterns. Its installations include joined floor and wall displays.</p><p>Our room uses a synthetic balanced binary array and seeded permutations. It borrows a spatial question, not the artwork’s data, score, sound or temporal behaviour. Random noise alone would not explain Ikeda’s practice.</p></details></section></main><footer><p>One address can be held in mind. A room asks us to move.</p><p class="muted">Ada / Working study / Source, scene and text kept together.</p></footer></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
print(f'Published {count} passing native checks and {len(files)} kit files to {HERE.name}')
