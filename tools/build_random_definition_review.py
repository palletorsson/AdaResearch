"""Build an illustrated review and inspectable swatches from the captured Godot values."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
REC = ROOT / 'doc/space/random-definition-review-2026-09-12'
RUN = ROOT / 'ada_run/random-definition-review-2026-09-12'
MAP = 'Random_Definition'
HALL = RUN / MAP
run = json.loads((RUN / 'run.json').read_text(encoding='utf-8'))
assert run['exit'] == 0 and run['checks'] == 65 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
manifest = []


def copy(src, name):
    shutil.copyfile(src, OUT / name)
    manifest.append(name)


def save(name, text):
    (OUT / name).write_bytes(text.encode('utf-8'))
    manifest.append(name)


for src, name in [
    ('probe_random_definition_equal_live.png', 'random-definition-equal.png'),
    ('probe_random_definition_offset_live.png', 'random-definition-offset.png'),
    ('probe_random_definition_desktop_close_live.png', 'random-definition-panel.png'),
    ('probe_random_definition_live.json', 'random-definition-check.json'),
    ('samples.json', 'random-definition-samples.json'),
]:
    copy(HALL / src, name)
copy(RUN / 'run.json', 'random-definition-run.json')
for name in ['final', 'tutorial', 'technical', 'critical']:
    copy(ROOT / f'commons/maps/{MAP}/{name}.md', f'random-definition-{name}.md')

text = '''# A pattern that returns

[Synthesis Lab](synthesis-lab.html) → **Random Definition** → [Random Entropy](random-entropy.html)

[The primary and its book passage](/necklace/thread?map=Random_Definition&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Definition)

Choose a patch of colour you would keep. Find it in the other grid. Press REPLAY and return to those cells before surveying the whole picture. **Can a surprise return exactly?**

![Seed 42, replayed twice at the same table: the two grids match](random-definition-equal.png)

Claude's table stands in the clear east half of the hall, facing west. The cloud remains behind the visitor. All 15 artifacts remain; the book follows `seed_replay_demo` as its one primary. This continuation repairs the seed slider, finishes the panel contrast and lets the existing encounter carry the text.

## Keep the number. Change the beginning.

Press +1 DRAW. The right grid changes. Its seed is still 42, and its cubes are still in their cells. One value was requested before colouring began, then given no colour at all.

![The same camera and same seed after discarding one draw: only the right grid changes its colours](random-definition-offset.png)

Each cell takes three successive values, one for each colour channel:

```gdscript
mat.albedo_color = Color(
    _rng.randf(),
    _rng.randf(),
    _rng.randf()
)
```

Before the right grid asks for its first red, this operation can advance the generator:

```gdscript
if _extra_on and i == _columns.size() - 1:
    for k in range(extra_draws):
        _rng.randf()
```

The grouping shifts. What supplied green supplies red, blue supplies green, and the next cell's red becomes this cell's blue. Sixty-four cells still receive 192 values. The extra draw makes the right grid consume 193. The discarded value changes the assignments without moving a single cube.

REPLAY keeps this difference. +1 DRAW again restores the match. The button toggles one discarded draw; repeated presses do not accumulate more of them.

## Follow one cell into the source values

The small comparison below uses the actual 64 RGB values exported by Godot at seed 42. It does not imitate the random generator. Switch the discarded draw on, then choose a cell and follow its draw numbers. Row zero is at the bottom, as in the artifact.

<!-- sample-view -->

The swatches map the exported material values directly to CSS RGB. They help inspect the assignment; they do not reproduce the museum's lighting or tone mapping. The photographs above show the rendered hall.

## A hand can move without choosing another seed

The handle travels continuously, but its receiver rounds the position to an integer from 0 to 999. Move slowly and there are moments when your hand moves while the seed remains. At other moments a small movement selects a very different patchwork.

The earlier receiver looked for a panel name that no longer existed. Its handle could move while every seed stayed the same. The corrected path now reaches the actual slider. The visible seed, handle and grids also synchronize after RANDOM and hall rebuilding.

![The local panel now keeps dark backing, readable pale tags and a larger cased action readout under the room lighting](random-definition-panel.png)

| Control | What it does here |
|---|---|
| SEED slider | Rounds the handle position to an integer from 0 to 999 and repaints the grids. |
| REPLAY | Restores the generator to the current seed for each grid, retaining the chosen extra-draw setting. |
| RANDOM | Chooses a seed using a separate local generator. It may choose the current seed or an earlier one again. |
| +1 DRAW | Switches one discarded draw on or off before colouring the last grid. |

Waiting does not advance the colour generator. The room can continue around a picture that stays still. Rebuilding the hall returns to its configured seed and comparison; the panel does not save a visitor's selection between visits.

## Another palette worth keeping

Keep the unmatched pair for a moment. Perhaps its disagreement gives you a relation you want. An instrument made to demonstrate a match has supplied another palette. That result is available to repeat and use.

This is a specific place for the question “what bodies are possible?” The seeds can change every colour, but the panel cannot add a cell, move it away from the grid or make its sampled value a force. A thousand choices leave other decisions fixed. The source shows where another kind of change would have to begin.

We needed more than the picture's seed: a generator, an order of requests and an assignment of their results. The number was a useful way back only while the rest of that procedure remained.

## Evidence and the next room

**65 independent desktop checks passed, with zero assertion failures and engine exit 0.** The checks include exact colour bytes, independent generator reconstruction, slider endpoints and intermediate seeds, a desktop pointer drag, all three buttons, local random-state isolation, panel contrast, approach, unload and rebuild. The two comparison captures use the same camera pose. Nine production-code excerpts were verified in the final and tutorial.

The engine still reports an ObjectDB leak warning and one resource in use at shutdown. Passing assertions do not resolve that warning. Headset reach and close lettering remain for a later visit; the captures support a desktop visual review.

[Desktop report](random-definition-check.json) · [Run receipt](random-definition-run.json) · [Exported samples](random-definition-samples.json) · [Tutorial](random-definition-tutorial.md) · [Technical notes](random-definition-technical.md) · [Critical text](random-definition-critical.md)

**Next: [Random Entropy](random-entropy.html).** Carry a small patch with you. If its colours are rearranged while their counts remain, what can a histogram tell us—and what part of the encounter has it left behind?
'''
samples = json.loads((HALL / 'samples.json').read_text(encoding='utf-8'))
assert len(samples['base']) == len(samples['offset']) == 64 and len(samples['draws']) == 193
sample_view = '''<section class="sample-view" aria-label="Captured colour assignments">
<div class="sample-controls"><button id="discard" type="button" aria-pressed="false">Discard one draw</button>
<label for="cell">Inspect cell <select id="cell" aria-label="Inspect cell"></select></label></div>
<p id="sample-status" role="status" aria-live="polite">Both grids start at draw 1.</p>
<div class="sample-pair"><figure><figcaption>Seed 42 · start at draw 1</figcaption><div id="base-grid" class="sample-grid" aria-label="Unshifted grid"></div></figure>
<figure><figcaption id="right-caption">Seed 42 · start at draw 1</figcaption><div id="offset-grid" class="sample-grid" aria-label="Comparison grid"></div></figure></div>
<pre id="cell-values" aria-live="polite"></pre><noscript>Enable JavaScript to inspect cells, or download the exported samples linked below.</noscript></section>'''
script = '''<script>
const samples=__SAMPLES__;
let shifted=false;
const selector=document.querySelector('#cell');
for(let i=0;i<64;i++){const option=document.createElement('option');option.value=i;option.textContent=`${i+1} · row ${Math.floor(i/8)}, column ${i%8}`;selector.append(option);}
const order=Array.from({length:64},(_,i)=>(7-Math.floor(i/8))*8+i%8);
function grid(id,colors){const node=document.querySelector(id);node.replaceChildren();for(const i of order){const swatch=document.createElement('span');swatch.style.backgroundColor=`rgb(${colors[i].map(c=>c*100+'%').join(' ')})`;swatch.title=`Cell ${i+1}`;swatch.className=+selector.value===i?'selected':'';node.append(swatch);}}
function render(){const i=+selector.value;grid('#base-grid',samples.base);grid('#offset-grid',shifted?samples.offset:samples.base);
document.querySelector('#discard').setAttribute('aria-pressed',String(shifted));
document.querySelector('#right-caption').textContent=`Seed 42 · start at draw ${shifted?2:1}`;
document.querySelector('#sample-status').textContent=shifted?'One discarded draw. Same seed; 64 cells change their colour.':'Both grids start at draw 1.';
const lines=(label,offset,colors)=>label+'\\n'+['R','G','B'].map((c,k)=>`${c} ← draw ${i*3+k+1+offset}: ${colors[i][k].toFixed(8)}`).join('\\n');
document.querySelector('#cell-values').textContent=lines('LEFT',0,samples.base)+'\\n\\n'+lines('RIGHT',shifted?1:0,shifted?samples.offset:samples.base);}
selector.addEventListener('change',render);document.querySelector('#discard').addEventListener('click',()=>{shifted=!shifted;render();});render();
</script>'''.replace('__SAMPLES__', json.dumps(samples, separators=(',', ':')))
final = (ROOT / f'commons/maps/{MAP}/final.md').read_text(encoding='utf-8')
save('random-definition.md', text.replace('<!-- sample-view -->', '[Inspect the exported samples](random-definition-samples.json) in the interactive [review](random-definition.html).') + '\n## Book passage\n\n' + final)
style = (OUT / 'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style += '''.sample-view{background:#fbf8f0;border:1px solid #c2bbaa;padding:24px;border-radius:8px}.sample-pair{display:grid;grid-template-columns:1fr 1fr;gap:24px;max-width:640px}.sample-pair figure{margin:0;min-width:0}.sample-pair figcaption{font-size:14px;margin-bottom:10px}.sample-grid{display:grid;grid-template-columns:repeat(8,1fr);gap:3px;background:#282b31;padding:6px}.sample-grid span{aspect-ratio:1}.sample-grid .selected{outline:3px solid white;outline-offset:-3px;box-shadow:inset 0 0 0 4px black}.sample-controls{display:flex;gap:16px;flex-wrap:wrap;align-items:center}button,select{font:inherit;font-size:16px;padding:10px;border:1px solid #716658;border-radius:4px;background:#fff;color:#242a2c}button{cursor:pointer}button[aria-pressed=true]{background:#743653;color:#fff}button:focus-visible,select:focus-visible{outline:3px solid #743653;outline-offset:3px}#cell-values{font-size:15px;white-space:pre-wrap}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:550px){body{padding:0 14px}.sample-view{padding:14px}.sample-pair{gap:12px}.sample-grid{gap:2px;padding:3px}td,th{padding:6px;font-size:12px}}'''
body = markdown.markdown(text, extensions=['tables', 'fenced_code']).replace('<!-- sample-view -->', sample_view)
body += '<details><summary>Read the book passage</summary>' + markdown.markdown(final, extensions=['fenced_code']) + '</details>'
save('random-definition.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A pattern that returns · Ada Research</title><style>' + style + '</style></head><body><main>' + body + '</main>' + script + '</body></html>\n')
(REC / 'publication-manifest.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode('utf-8'))
(REC / 'publication-hashes.json').write_bytes((json.dumps({n: hashlib.sha256((OUT / n).read_bytes()).hexdigest() for n in manifest}, indent=2) + '\n').encode('utf-8'))
print(json.dumps({'files': len(manifest), 'checks': run['checks'], 'sample_cells': len(samples['base'])}))
