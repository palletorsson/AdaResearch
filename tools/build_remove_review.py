"""Illustrated removal review with playback of actual exported histories."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
REC = ROOT / 'doc/space/remove-review-2026-09-12'
RUN = ROOT / 'ada_run/remove-review-2026-09-12'
HALL = RUN / 'Random_Remove'
run = json.loads((RUN / 'run.json').read_text(encoding='utf-8'))
assert run['checks'] == 87 and not run['failures'] and run['exit'] == 0
assert run['sources_unchanged'] and run['original_hand_unchanged']
manifest = []


def copy(source, name):
    shutil.copyfile(source, OUT / name)
    manifest.append(name)


def save(name, text):
    (OUT / name).write_bytes(text.encode('utf-8'))
    manifest.append(name)


for src, dst in [
    ('probe_remove_desktop_front_live.png', 'random-remove-desk.png'),
    ('probe_remove_one_live.png', 'random-remove-one.png'),
    ('probe_remove_emptied_live.png', 'random-remove-empty.png'),
    ('probe_remove_status_live.png', 'random-remove-status.png'),
    ('probe_remove_live.json', 'random-remove-check.json'),
    ('histories.json', 'random-remove-histories.json'),
]:
    copy(HALL / src, dst)
copy(RUN / 'run.json', 'random-remove-run.json')
for name in ['final', 'tutorial', 'technical', 'critical']:
    copy(ROOT / f'commons/maps/Random_Remove/{name}.md', f'random-remove-{name}.md')

text = '''# The set before the choice

[Random Entropy](random-entropy.html) → **Random Remove** → [Random Walk](random-walk.html)

[The primary and its book passage](/necklace/thread?map=Random_Remove&role=primary) · [Waves, randomness and noise plan](/research/waves-chance-noise/index.html#Random_Remove)

Find a cube the machine cannot choose. Keep looking at it while another turns red and disappears. After several presses, this one is still standing. What has kept it there?

![The current removal bench after one desktop pointer press: the grid stays visible between the cased status at left and controls at right](random-remove-desk.png)

The existing `remove_random` bench remains the room's one primary. Its right-hand controls and left-hand status plate are Claude's accepted staging. This continuation preserves the production scripts and geometry, checks the encounter independently, and lets its distinctions carry the book text.

## A choice that cannot reach every cube

RANGE admits sixteen cubes: columns 2–5 and rows 2–5. The other forty-eight are grey. REMOVE ONE chooses only among the remaining amber candidates. A grey cube has no small chance waiting to happen in this run; it has no place in the candidate list.

![One removed cube in the captured seed-29640 range run; its slot plate remains](random-remove-one.png)

Keep going and the result becomes certain in one respect. Every admitted cube will eventually go. Sixteen completed presses empty the same square, whatever their order.

![The same camera and seed after all sixteen candidates have been removed: the final empty range was decided by the filter](random-remove-empty.png)

What differs between histories is still visible partway through. Stop there for a moment. A gap may join another, or leave a cube isolated, or make a broken rhythm you want to keep. The machine waits for the next press; it has no judgement about whether this is the place to stop.

## Eight choices, different places

Compare ROW and COLUMN below. Both start with eight candidates. At seed 777 they select the same list offsets—7, 0, 4, 2, 1, 1, 0, 0 as the lists shrink—yet those positions address different cubes. **The number of possibilities agrees while their places differ.**

This playback uses complete histories exported from the real Godot bench. It makes no fresh random draws. The flat board uses local columns left to right and rows top to bottom; it is a reading view of the model, not the museum camera. “Show removal order” exposes a record available to code and this review; the in-game plate shows only the last removal.

<!-- histories -->

The other comparisons let you replay a range or inspect two captured seeds over it. At the end, both range histories leave the same shape. Halfway through, the missing addresses can differ. RESET returns this playback to its first step, just as the bench restores its current set.

## Filter, draw, remove

The filter asks a question about each cube's original grid coordinates. ROW and COLUMN are explicit tests:

```gdscript
"Column": return is_equal_approx(pos.x, float(target_column))
"Row": return is_equal_approx(pos.z, float(target_row))
```

Already removed instances are skipped. The surviving eligible indices form a list. Only then does the private generator choose:

```gdscript
var offset := _rng.randi_range(0, active_instances.size() - 1)
var index := active_instances[offset]
```

ROW and COLUMN use equal draw bounds because both start at eight and lose one candidate per step. RANGE and ALL change those bounds as well as the available places. Keeping the seed alone is insufficient to claim equal offsets across differently sized sets.

The last operation changes how the selected instance is drawn:

```gdscript
transform.basis = Basis().scaled(Vector3.ZERO)
multimesh.set_instance_transform(index, transform)
```

The cube's instance slot remains. The remover retains its original transform; the permanent plate retains its visible address. RESET can restore this body because the implementation has kept the means of return. Your museum floor is unaffected by these small absences.

## What the reset remembers

![The cased status beside the tray names the current set, seed and counts; its lower line holds a legend or the last event](random-remove-status.png)

RESET restores all sixty-four transforms and seeds the removal generator with the current run seed. Waiting between completed removals does not consume its draws. A press during the red highlight is ignored; RESET or a mode change cancels the pending deletion so it cannot alter the new run after its delay.

NEW SEED selects a five-digit value and restores the set. It can select a previous value again; different seeds can also produce the same order. The seed is visible but there is no field for entering one. The complete procedure includes the generator, list order, eligibility rule and draw bounds as well as that number.

An excluded cube is protected from deletion here. Exclusion from a draw that offered an opportunity would have another consequence. Before treating inclusion as good or the draw as fair, ask what being chosen does. The bench makes each part available for inspection without deciding the value of every possible application.

## What is ready, and what remains

**87 independent desktop checks passed, zero assertion failures, engine exit 0.** These include the seven button signal paths, actual desktop pointer REMOVE ONE and RESET, all four masks, replay, full ROW/COLUMN/ALL histories, a pending reset or mode change, rapid repeated presses, access, the unchanged surrounding object count and unloading/rebuilding. Six full histories contain 128 removal entries; every order is a permutation of its eligible set, and the replay repeats exactly. Eleven production excerpts were checked across final and tutorial.

The front view keeps the grid and two side stations visible. The existing oblique close view partly overlaps RANGE with the tray edge, so tracked-hand approach and reach still require a later visit. The dark sphere constrains one neighbouring lane; the tested routes around the bench remain open. No headset assessment is claimed.

Three map placements remain declared. The remover and dark sphere build; the secondary `hazards_demo` has no living scene. Book and registry notes that described hunting the host map's grid are corrected. Historical capture parameters and bounds are retained with a note that their harness needs separate review.

This run has no script errors or shutdown leak warning. It does record an unrecognized audio-bus UID, root-certificate and logger errors, renderer/environment warnings, and generated decorations taking 127–298 ms to build. These diagnostics remain separate from the passing encounter checks.

[Desktop report](random-remove-check.json) · [Run receipt](random-remove-run.json) · [Captured histories](random-remove-histories.json) · [Tutorial](random-remove-tutorial.md) · [Technical notes](random-remove-technical.md) · [Critical text](random-remove-critical.md)

**Next: [Random Walk](random-walk.html).** A choice will move a body. What can it reach when each step begins from the place the previous draw left it?
'''

histories = json.loads((HALL / 'histories.json').read_text(encoding='utf-8'))
for h in histories.values():
    assert sorted(h['order']) == h['eligible'] and len(set(h['order'])) == len(h['eligible'])
view = '''<section class="history-view" aria-label="Captured removal histories">
<div class="history-controls"><label for="comparison">Compare <select id="comparison"><option value="masks">ROW and COLUMN · seed 777</option><option value="seeds">RANGE · two captured seeds</option><option value="replay">RANGE · replay the same seed</option></select></label><button type="button" id="step">REMOVE ONE</button><button type="button" id="reset">RESET</button></div>
<p id="history-status" role="status" aria-live="polite"></p>
<div class="boards"><figure><figcaption id="left-caption"></figcaption><div id="left-board" class="board" role="img"></div><p id="left-state"></p></figure><figure><figcaption id="right-caption"></figcaption><div id="right-board" class="board" role="img"></div><p id="right-state"></p></figure></div>
<label class="history-disclose"><input type="checkbox" id="show-order"> Show removal order · review only</label>
<p class="legend"><span class="key eligible"></span> eligible <span class="key excluded"></span> excluded <span class="key removed"></span> removed; address retained</p>
<p id="offset-status"></p><noscript>Download the captured histories below, or enable JavaScript to step through them.</noscript></section>'''
script = '''<script>
const histories=__HISTORIES__;
const $=id=>document.getElementById(id);
const modes={masks:[['row','ROW 3'],['column','COLUMN 3']],seeds:[['range','RANGE'],['range_new_seed','RANGE']],replay:[['range','RANGE'],['range_replay','REPLAY']]};
let step=0;
function offset(h,n){if(!n)return null;const remaining=h.eligible.filter(i=>!h.order.slice(0,n-1).includes(i));return remaining.indexOf(h.order[n-1]);}
function board(side,h,label){
 const removed=new Set(h.order.slice(0,step)),eligible=new Set(h.eligible),last=step?h.order[step-1]:null;
 $(side+'-caption').textContent=label+' · seed '+h.seed;
 const node=$(side+'-board');node.replaceChildren();
 node.setAttribute('aria-label',label+': '+step+' removed, '+(h.eligible.length-step)+' remaining');
 const cell=(content,className='coordinate')=>{const el=document.createElement('span');el.className=className;el.textContent=content;return el;};
 node.append(cell('r/c'));for(let x=0;x<8;x++)node.append(cell(x));
 for(let z=0;z<8;z++){node.append(cell(z));for(let x=0;x<8;x++){const i=z*8+x,state=removed.has(i)?'removed':eligible.has(i)?'eligible':'excluded';const el=cell(removed.has(i)?($('show-order').checked?String(h.order.indexOf(i)+1):'·'):'',state+(i===last?' last':''));el.title=`Column ${x}, row ${z}: ${state}${removed.has(i)?', removal '+(h.order.indexOf(i)+1):''}`;node.append(el);}}
 $(side+'-state').textContent=`${h.eligible.length-step} remaining · ${step} removed`+(last===null?'':` · last: column ${last%8}, row ${Math.floor(last/8)}`);
}
function render(){const choice=$('comparison').value,pair=modes[choice],left=histories[pair[0][0]],right=histories[pair[1][0]];
 board('left',left,pair[0][1]);board('right',right,pair[1][1]);
 $('step').disabled=step>=left.order.length;
 $('history-status').textContent=`Step ${step} of ${left.order.length}`+(step===left.order.length?' · the eligible sets are exhausted':` · next draw: 1/${left.order.length-step} for each remaining candidate`);
 $('offset-status').textContent=step?`Last selected offset in the remaining list: ${offset(left,step)} / ${offset(right,step)}${choice==='masks'?' · same offset, different address lists':''}`:'The candidate lists are ready. Choose a grey cube before stepping.';
}
$('step').addEventListener('click',()=>{step++;render();});$('reset').addEventListener('click',()=>{step=0;render();});$('comparison').addEventListener('change',()=>{step=0;render();});$('show-order').addEventListener('change',render);render();
</script>'''.replace('__HISTORIES__', json.dumps(histories, separators=(',', ':')))
final = (ROOT / 'commons/maps/Random_Remove/final.md').read_text(encoding='utf-8')
save('random-remove.md', text.replace('<!-- histories -->', '[Step through the captured histories](random-remove.html) in the interactive review.') + '\n## Book passage\n\n' + final)
style = (OUT / 'synthesis-lab.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style += '''.history-view{background:#fbf8f0;border:1px solid #c2bbaa;padding:24px;border-radius:8px}.history-controls{display:flex;gap:12px;flex-wrap:wrap;align-items:center}.history-controls label,.history-disclose{font-size:15px}button,select{font:inherit;font-size:15px;padding:10px;border:1px solid #716658;border-radius:4px;background:#fff;color:#242a2c}button{cursor:pointer}button:disabled{opacity:.45;cursor:default}button:focus-visible,input:focus-visible,select:focus-visible{outline:3px solid #743653;outline-offset:3px}.boards{display:grid;grid-template-columns:1fr 1fr;gap:24px;max-width:860px}.boards figure{margin:12px 0;min-width:0}.boards figcaption{font-size:15px;margin-bottom:10px;font-weight:600}.board{display:grid;grid-template-columns:22px repeat(8,minmax(0,1fr));gap:4px}.board>span{aspect-ratio:1;display:grid;place-items:center;font:13px ui-monospace,monospace;color:#151d28}.board .coordinate{color:#575950;font-size:12px}.eligible{background:#e4ab43;border:1px solid #795f20}.excluded{background:#667784;border:1px solid #485461}.removed{background:#e6e9e8;border:1px dashed #6d7a84}.last{outline:3px solid #923c59;outline-offset:-3px}.boards p,.legend,#offset-status{font-size:14px}.legend{display:flex;align-items:center;gap:7px;flex-wrap:wrap}.key{width:15px;height:15px;display:inline-block}.history-disclose{display:block;margin:12px 0}h1{font-size:clamp(32px,5vw,46px)}@media(max-width:550px){body{padding:0 14px}.history-view{padding:12px}.boards{gap:12px}.board{grid-template-columns:12px repeat(8,minmax(0,1fr));gap:2px}.board>span,.board .coordinate{font-size:8px}.boards figcaption{font-size:12px}.history-controls select{max-width:100%;font-size:12px}.history-controls label{max-width:100%}}'''
body = markdown.markdown(text, extensions=['tables','fenced_code']).replace('<!-- histories -->', view)
body += '<details><summary>Read the book passage</summary>' + markdown.markdown(final, extensions=['fenced_code']) + '</details>'
save('random-remove.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The set before the choice · Ada Research</title><style>' + style + '</style></head><body><main>' + body + '</main>' + script + '</body></html>\n')
(REC / 'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
(REC / 'publication-hashes.json').write_bytes((json.dumps({n:hashlib.sha256((OUT/n).read_bytes()).hexdigest() for n in manifest},indent=2)+'\n').encode('utf-8'))
print(json.dumps({'files':len(manifest),'checks':87,'histories':len(histories),'removals':sum(len(h['order']) for h in histories.values())}))
