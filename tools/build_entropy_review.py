"""Build the Entropy review from the two independently captured Godot samples."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
REC = ROOT / 'doc/space/entropy-review-2026-09-12'
RUN = ROOT / 'ada_run/entropy-review-2026-09-12'
HALL = RUN / 'Random_Entropy'
run = json.loads((RUN / 'run.json').read_text(encoding='utf-8'))
assert run['exit'] == 0 and run['checks'] == 149 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
manifest = []


def copy(src, name):
    shutil.copyfile(src, OUT / name)
    manifest.append(name)


def save(name, text):
    (OUT / name).write_bytes(text.encode('utf-8'))
    manifest.append(name)


for src, name in [
    ('probe_entropy_desktop_drawn_live.png', 'random-entropy-drawn.png'),
    ('probe_entropy_desktop_front_live.png', 'random-entropy-sorted.png'),
    ('probe_entropy_desktop_contrast_live.png', 'random-entropy-concentrated.png'),
    ('probe_entropy_buttons_live.png', 'random-entropy-controls.png'),
    ('probe_entropy_live.json', 'random-entropy-check.json'),
    ('samples.json', 'random-entropy-samples.json'),
]:
    copy(HALL / src, name)
copy(RUN / 'run.json', 'random-entropy-run.json')
for name in ['final', 'tutorial', 'technical', 'critical']:
    copy(ROOT / f'commons/maps/Random_Entropy/{name}.md', f'random-entropy-{name}.md')

text = '''# What the gauge forgets

[Random Definition](random-definition.html) → **Random Entropy** → [Random Remove](random-remove.html)

[The primary and its book passage](/necklace/thread?map=Random_Entropy&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Entropy)

Choose two neighbouring colours. Perhaps they make a pair you would keep. Find them again in the enlarged row on the desk's front. Now press SORT and follow what happens to their closeness.

![The meter as drawn: 200 small tiles above an enlarged record of the first forty](random-entropy-drawn.png)

The upper ribbon gathers into blocks of colour. The bars hold still. So does the number. Below the moving tiles, the first forty keep the neighbours they had before. **What did the gauge fail to notice?**

![The same camera after SORT: the upper ribbon regroups while the enlarged original excerpt stays in place](random-entropy-sorted.png)

Claude's existing installation carries this encounter: `shannon_entropy_meter` is the room's one primary and its book anchor. This continuation improves the local controls and caption, checks the complete comparison and develops the text around what can actually be found at the desk.

## Keep the counts. Move the neighbours.

Here are the two complete samples exported by Godot. Try SORT before reading the explanation. The browser wraps the two-metre ribbon into ten rows of twenty; read across each row, then down. Its first-forty excerpt stays as drawn. This is a view of the captured values, not a new random generator or a reproduction of the museum lighting.

<!-- sample-view -->

The browser histogram uses a fixed **0–200 count scale** so the two samples can be compared directly. In the museum, each histogram makes its own largest bar ten centimetres tall. The different rulers are part of the comparison.

The meter begins with one tally for each symbol:

```gdscript
for s in sequence:
    counts[s] += 1
```

Nothing in that loop records where a symbol stood. SORT moves the tile instances into a stable order without rewriting the sampled sequence. In the arrival sample, 198 of 200 instances change place. Their counts remain 17, 11, 21, 31, 17, 18, 19, 24, 13 and 29. The same counts enter the next loop:

```gdscript
for c in counts:
    if c > 0:
        var p: float = float(c) / float(sequence_length)
        entropy -= p * (log(p) / log(2.0))
```

The result is **3.255647 bits per symbol**, both before and after sorting. This marginal measurement uses the shares in the sample. It does not look at neighbouring pairs or use their order to predict the next symbol. A repeated cycle through ten symbols can reach the same maximum as any other evenly populated sample.

## Another sample, another ruler

Press CONTRAST. The alphabet and sample size stay: ten symbols, two hundred draws. This second cached sample comes from a weighted source, with each symbol about half as likely as the one before it. It also has its own seed. Switching back restores the first sample; the buttons do not keep resampling it.

![The concentrated sample from the same desktop camera: symbol zero occurs 109 times, and four symbols have no occurrences](random-entropy-concentrated.png)

The first symbol occurs 109 times. Four symbols never occur. The entropy falls to **1.817600 bits per symbol**. Compare their counts with the marks on the panel: a zero still has a visible bar because the display includes this line:

```gdscript
height = max(0.002, height)
```

Every bar gets at least two millimetres. The tallest also has the same ten-centimetre height in both samples, although its count changes from 31 to 109. Its neighbours make it look dominant; its own height cannot tell you how many occurrences it holds. Read the ledger below it.

DISCLOSE first brings in the formula, then the source and its pale expected-count bars. Those expectations follow the selected source. The uniform source expects twenty of each on average; its actual sample did not divide evenly. The concentrated source supplies a descending set of expectations. Small expected values share the same minimum visible height as some zeros. Keep the numbers beside the picture.

## What becomes possible in the rearrangement?

A sorted row makes every occurrence of a colour easy to find. The original row keeps the pairs and interruptions you first encountered. You might use one as a stock of colours and the other as the beginning of a fabric. The unchanged number cannot decide which arrangement matters to that work.

There are two losses to follow here. Counts discard positions. The entropy reading condenses those counts again: from H alone you cannot recover even the ten bar values. The first-forty record lets the body remain beside some of the relations the gauge has omitted.

This gives the critical question somewhere specific to land. Which relations must a representation preserve for the thing we want to do? A high value is no general certificate of freedom, and a low one does not describe a body's possibilities. Here we can change a relation that matters to us while leaving the instrument satisfied that nothing changed.

## At the desk

![Close desktop inspection of the three front controls with matte faces and pale lettered tags](random-entropy-controls.png)

| Control | What happens here |
|---|---|
| SORT | Rearranges the upper ribbon, then restores its draw order. Counts, H and the enlarged original excerpt stay fixed. |
| CONTRAST | Selects the other cached sample, retaining the sorting choice. Its counts, colours and source expectations replace the current ones. |
| DISCLOSE | Steps the upper panel through ledger → works → origin → oracle → tally → ledger. The desk keeps its own tiles and account throughout. |

The button panel is larger, its backing and lettered tags remain readable under room lighting, and the front excerpt caption now says “first forty · as drawn.” A false ×4 label is gone: the enlargement uses different factors for width and height. Fine lettering on the upper panel still needs a closer approach. Headset reach and reading remain for a later visit.

## Evidence and the next room

**149 independent desktop checks passed, zero assertion failures, engine exit 0.** They exercise real button signals and desktop pointer presses, sorting, both orders of source/disclosure selection, source expectations, the zero and maximum-entropy endpoints, approach, unload and rebuilding. The three comparison captures share the same camera pose. The two exported samples are independently counted and their entropy recomputed; twelve production excerpts are checked across final, tutorial and technical texts.

All nine map placements remain declared. Eight instantiate; the secondary `replay_casino` has no living scene and is still missing from the built room. The primary is present and tested. The run has no script errors, but reports an unrecognized audio-bus UID, a root-certificate error, a logger failure and an ObjectDB shutdown warning. These remain recorded separately from the passing checks. No headset observation is claimed.

[Desktop report](random-entropy-check.json) · [Run receipt](random-entropy-run.json) · [Captured samples](random-entropy-samples.json) · [Tutorial](random-entropy-tutorial.md) · [Technical notes](random-entropy-technical.md) · [Critical text](random-entropy-critical.md)

**Next: [Random Remove](random-remove.html).** Before the draw chooses a place, what has already decided which places are eligible? The question moves from an arrangement on a desk into the space we can walk.
'''

samples = json.loads((HALL / 'samples.json').read_text(encoding='utf-8'))
assert all(len(s['sequence']) == 200 and s['symbols'] == 10 for s in samples.values())
sample_view = '''<section class="sample-view" aria-label="Captured entropy samples">
<div class="sample-controls"><button id="sort" type="button" aria-pressed="false">SORT</button><button id="contrast" type="button" aria-pressed="false">CONTRAST</button><label><input type="checkbox" id="expectations"> Show source expectations</label></div>
<p id="sample-status" role="status" aria-live="polite"></p>
<div class="sample-body"><div><figure><figcaption id="order-caption">200 draws · original order</figcaption><div id="ribbon" class="sample-grid" role="img" aria-label="200 symbols in original draw order"></div></figure>
<figure><figcaption>First forty · always as drawn</figcaption><div id="excerpt" class="sample-grid" role="img" aria-label="First forty symbols in original order"></div></figure>
</div><div><div class="meter"><strong id="entropy-value"></strong><span>Marginal H · ceiling log₂(10) = 3.321928 bits/symbol</span></div>
<p class="chart-key">Observed counts · fixed scale from 0 to 200<span id="ghost-key" hidden> · pale vertical ticks: source expectations</span></p>
<div id="histogram" aria-label="Symbol counts, fixed scale from zero to two hundred"></div>
<p id="count-status"></p></div></div><noscript>Download the captured samples below, or enable JavaScript to compare the two arrangements.</noscript></section>'''

script = '''<script>
const samples=__SAMPLES__;
let sorted=false, concentrated=false;
const $=id=>document.getElementById(id);
function tiles(id,sequence,palette){const node=$(id);node.replaceChildren();sequence.forEach((symbol,i)=>{const el=document.createElement('span');el.textContent=symbol;el.style.backgroundColor=`rgb(${palette[symbol].map(c=>c*100+'%').join(' ')})`;el.title=`Position ${i+1}: symbol ${symbol}`;node.append(el);});}
function render(){
 const sample=samples[concentrated?'concentrated':'uniform'];
 const sequence=sorted?[...sample.sequence].sort((a,b)=>a-b):sample.sequence;
 const counts=Array(10).fill(0);sequence.forEach(v=>counts[v]++);
 const h=-counts.reduce((sum,c)=>sum+(c?c/200*Math.log2(c/200):0),0);
 const expected=$('expectations').checked;
 tiles('ribbon',sequence,sample.symbol_colors);tiles('excerpt',sample.sequence.slice(0,40),sample.symbol_colors);
 $('ribbon').setAttribute('aria-label',`200 symbols in ${sorted?'sorted':'original draw'} order`);
 $('order-caption').textContent=`200 draws · ${sorted?'sorted by symbol':'original order'}`;
 $('sample-status').textContent=`${concentrated?'Concentrated source':'Uniform source'} · seed ${sample.seed} · ${sorted?'sorted; the first-forty record stays as drawn':'as drawn'}`;
 $('entropy-value').textContent=`${h.toFixed(6)} bits/symbol`;
 $('sort').setAttribute('aria-pressed',String(sorted));$('contrast').setAttribute('aria-pressed',String(concentrated));$('ghost-key').hidden=!expected;
 const hist=$('histogram');hist.replaceChildren();
 counts.forEach((count,i)=>{const row=document.createElement('div');row.className='count-row';
 const label=document.createElement('span');label.textContent=String(i);const track=document.createElement('div');track.className='count-track';
 const bar=document.createElement('div');bar.className='count-bar';bar.style.width=count/2+'%';bar.style.backgroundColor=`rgb(${sample.symbol_colors[i].map(c=>c*100+'%').join(' ')})`;track.append(bar);
 if(expected){const ghost=document.createElement('span');ghost.className='ghost';ghost.style.left=sample.expected_counts[i]/2+'%';track.append(ghost);}
 const value=document.createElement('span');value.className='count-value';value.textContent=String(count)+(expected?` / ${sample.expected_counts[i].toFixed(1)}`:'');
 row.setAttribute('aria-label',`Symbol ${i}: ${count} observed${expected?', '+sample.expected_counts[i].toFixed(3)+' expected':''}`);
 row.append(label,track,value);hist.append(row);});
 $('count-status').textContent=`Total ${counts.reduce((a,b)=>a+b,0)} · ${counts.filter(c=>!c).length} symbols with no occurrences${expected?' · values: observed / expected':''}`;
}
$('sort').addEventListener('click',()=>{sorted=!sorted;render();});$('contrast').addEventListener('click',()=>{concentrated=!concentrated;render();});$('expectations').addEventListener('change',render);render();
</script>'''.replace('__SAMPLES__', json.dumps(samples, separators=(',', ':')))

final = (ROOT / 'commons/maps/Random_Entropy/final.md').read_text(encoding='utf-8')
save('random-entropy.md', text.replace('<!-- sample-view -->', '[Compare the captured samples](random-entropy.html) in the interactive review.') + '\n## Book passage\n\n' + final)
style = (OUT / 'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style += '''.sample-view{background:#fbf8f0;border:1px solid #c2bbaa;padding:24px;border-radius:8px}.sample-body{display:grid;grid-template-columns:1.4fr 1fr;gap:24px}.sample-body>div{min-width:0}.sample-view figure{margin:20px 0}.sample-view figcaption{font-size:14px;margin-bottom:8px}.sample-grid{display:grid;grid-template-columns:repeat(20,minmax(0,1fr));gap:3px;background:#282b31;padding:7px}.sample-grid span{aspect-ratio:1;display:grid;place-items:center;font:12px ui-monospace,monospace;color:#141923}.sample-controls{display:flex;gap:12px;flex-wrap:wrap;align-items:center}.sample-controls label{font-size:15px}button{font:inherit;font-size:16px;padding:10px 18px;border:1px solid #716658;border-radius:4px;background:#fff;color:#242a2c;cursor:pointer}button[aria-pressed=true]{background:#743653;color:#fff}button:focus-visible,input:focus-visible{outline:3px solid #743653;outline-offset:3px}.meter{display:flex;flex-direction:column;gap:4px;margin:24px 0 12px}.meter strong{font-size:28px;font-variant-numeric:tabular-nums}.meter span,.chart-key,#count-status{font-size:14px}.count-row{display:grid;grid-template-columns:16px minmax(0,1fr) 110px;gap:10px;align-items:center;margin:4px 0;font:14px ui-monospace,monospace}.count-track{height:16px;position:relative;background:#e1ded6}.count-bar{height:100%;box-shadow:inset 0 0 0 1px #252a3240}.ghost{position:absolute;top:-2px;bottom:-2px;border-left:3px solid white;filter:drop-shadow(1px 0 #444)}.count-value{text-align:right}.chart-key{margin-bottom:12px}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:850px){.sample-body{grid-template-columns:1fr}.sample-body .meter{margin-top:0}}@media(max-width:550px){body{padding:0 14px}.sample-view{padding:12px}.sample-grid{gap:1px;padding:3px}.sample-grid span{font-size:8px}.count-row{grid-template-columns:12px minmax(0,1fr) 96px;gap:6px;font-size:12px}.meter strong{font-size:24px}td,th{padding:6px;font-size:12px}}'''
body = markdown.markdown(text, extensions=['tables', 'fenced_code']).replace('<!-- sample-view -->', sample_view)
body += '<details><summary>Read the book passage</summary>' + markdown.markdown(final, extensions=['fenced_code']) + '</details>'
save('random-entropy.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What the gauge forgets · Ada Research</title><style>' + style + '</style></head><body><main>' + body + '</main>' + script + '</body></html>\n')
(REC / 'publication-manifest.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode('utf-8'))
(REC / 'publication-hashes.json').write_bytes((json.dumps({n: hashlib.sha256((OUT / n).read_bytes()).hexdigest() for n in manifest}, indent=2) + '\n').encode('utf-8'))
print(json.dumps({'files': len(manifest), 'checks': run['checks'], 'samples': len(samples), 'symbols': 400}))
