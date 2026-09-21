"""Publishable inspection page from verified Godot geometry, states and physical walks."""
from pathlib import Path
import ast, hashlib, json, shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/research/possible-bodies'; E=R/'doc/space/ca-forms-review-2026-09-14'; RUN=R/'ada_run/ca-forms-review-2026-09-14'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    t=p.with_name(p.name+'.tmp'); t.write_bytes((s.strip()+'\n').encode()); t.replace(p)
receipt=json.loads((RUN/'receipt.json').read_text())
assert receipt['exit']==0 and not receipt['failures'] and receipt['sources_unchanged'] and receipt['museum_and_hand_unchanged']
assert all(sha(R/p)==h for p,h in receipt['source_sha256'].items()),'Capture sources changed'
assert all(sha(R/p)==h for p,h in receipt['museum_guard_sha256'].items()),'Museum guards changed'
log=(RUN/'engine.log').read_text(encoding='utf-8',errors='replace')
assert 'SCRIPT ERROR:' not in log and 'Parse Error:' not in log
data={}
for key in ['0','1','2','3','3-reserved']:
    data[key]=json.loads((RUN/f'history-{key}.json').read_text())
    # Godot serializes PackedByteArray values as JSON-array strings.
    data[key]['history']=[json.loads(row) if isinstance(row,str) else row for row in data[key]['history']]
    assert len(data[key]['history'])==28 and all(len(row)==375 and set(row)<={0,1} for row in data[key]['history'])
    assert sum(map(sum,data[key]['history']))==data[key]['report']['occupied']
    for kind in ['form','inside']: shutil.copy2(RUN/f'{kind}-{key}.png',O/f'ca-forms-{kind}-{key}.png')
shutil.copy2(RUN/'controls.png',O/'ca-forms-controls.png')
shutil.copy2(R/'tools/ca_forms_review.js',O/'ca-forms-review.js')
save(O/'ca-forms-data.json',json.dumps(data,separators=(',',':')))
for name in ['receipt.json','report.json']: save(E/name,(RUN/name).read_text())
save(O/'ca-forms-verification.json',(RUN/'report.json').read_text())
css=next(ast.literal_eval(n.value) for n in ast.parse((R/'tools/build_ca_history_review.py').read_text()).body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='css' for t in n.targets))
css+='''canvas{width:100%;height:auto;display:block;border:1px solid #456169;border-radius:7px}input[type=range]{width:100%;accent-color:#e3b3ca}input[type=checkbox]{accent-color:#f0cba6;width:20px;height:20px;vertical-align:middle}label{display:inline-block;margin:14px 0}.instrument{padding:18px;background:#203e43;border-left:3px solid #ffcc70;font-variant-numeric:tabular-nums}.gallery h3{margin-bottom:8px}.table-scroll{overflow:auto}.small code{font-size:12px}.question{font:26px/1.45 Georgia,serif;max-width:780px;color:#f4d4bd}pre{padding:20px;background:#19373c;overflow:auto;font-size:14px}pre code{overflow-wrap:normal}button:focus-visible,input:focus-visible{outline:3px solid #f0cba6;outline-offset:4px}button:disabled{opacity:.5}.controls{align-items:center}'''
html='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Walk inside a history · Ada Research</title><style>__CSS__</style></head><body><main>
<nav><a href="ca-soft-rules.html">← What can a cell receive?</a><a href="learning-ladder.html">Learning ladder</a></nav>
<div class="eyebrow">Form laboratory / cellular automata × sine</div><h1>Walk inside a history.</h1>
<p class="lead">A generation can become a slice of architecture. What changes when the slice bends—and what changes when the rule does?</p>
<p class="status">Built and walked in a standalone Godot workshop. __CHECKS__ desktop checks passed. Headset review is still ahead.</p>
<figure><img src="ca-forms-inside-1.png" alt="Actual eye-height Godot view inside the curving cellular history vault"><figcaption>Inside the sine bend. Each half-metre along the vault records another generation. The history is held still while the visitor moves through it.</figcaption></figure>
<section><h2>Where does sine enter?</h2><p class="question">Keep the beginning. Change one relation. Predict whether you will still get through.</p>
<div class="controls" aria-label="Form strategy"><button data-mode="0" aria-pressed="false">Straight</button><button data-mode="1" aria-pressed="true">Sine bend</button><button data-mode="2" aria-pressed="false">Sine breath</button><button data-mode="3" aria-pressed="false">Sine in the rule</button></div>
<label><input id="reserve" type="checkbox" disabled> Reserve a corridor in the sine-rule form</label>
<h3 id="strategy-title">Sine bend</h3><p id="totals" class="instrument" aria-live="polite">Loading the recorded comparison…</p><p id="walk-result"></p><p id="strategy-note"></p>
<div class="gallery"><figure><img id="form-photo" src="ca-forms-form-1.png" alt="Actual Godot sine bend from outside"><figcaption>Actual workshop / exterior</figcaption></figure><figure><img id="inside-photo" src="ca-forms-inside-1.png" alt="Actual Godot sine bend from inside"><figcaption>Actual workshop / eye-height interior</figcaption></figure></div>
<label for="generation">Inspect a generation</label><input id="generation" type="range" min="0" max="27" value="14" step="1"><div class="controls"><button id="previous-generation">Previous generation</button><button id="next-generation">Next generation</button><output id="generation-reading" for="generation"></output></div><p id="section-reading" aria-live="polite"></p>
<div class="gallery"><article><h3>Across the vault</h3><canvas id="section-view" width="700" height="380" aria-label="Cross-section of the selected generation with a fixed-size visitor"></canvas></article><article><h3>Along the recorded walk</h3><canvas id="plan-view" width="700" height="480" aria-label="Horizontal section at eye height with the measured desktop path"></canvas></article></div>
<p class="small">Diagrams use the recorded cell states at phase zero. Grey is occupied; pink is the fixed-size visitor or recorded walk; gold selects the generation or marks the reserved strip. The plan slices the material at 1.6 m. A clear pixel is not a body-clearance test—the pink path comes from Godot collision and actual desktop movement.</p></section>
<section><h2>Four ways to make form</h2><div class="table-scroll"><table><thead><tr><th>Strategy</th><th>What changes</th><th>Measured result</th></tr></thead><tbody>
<tr><td>Straight history</td><td>The 2D section updates; each saved state occupies another 0.5 m along Z.</td><td>3,965 occupied cells. Full passage.</td></tr>
<tr><td>Sine bend</td><td>X shifts with Z. Every cellular state stays the same.</td><td>3,965 cells. Full passage along the bend.</td></tr>
<tr><td>Sine breath</td><td>Width and height expand and contract with Z. The visitor stays the same size.</td><td>3,965 cells. Full passage at these amplitudes.</td></tr>
<tr><td>Sine in the rule</td><td>The birth threshold varies between 2 and 6 neighbours as generations advance.</td><td>8,289 cells. The tested walk stops at 3.20 m.</td></tr>
<tr><td>Rule + reserved passage</td><td>The same rule runs, then the corridor is forced empty each update.</td><td>7,710 cells. Full passage; 160 occupied-cell decisions suppressed.</td></tr>
</tbody></table></div><p>The 579-cell difference between the last two histories is larger than the 160 direct suppressions. Once a cell stays empty, its neighbours inherit a different situation.</p></section>
<section><h2>What have we actually stacked?</h2><p>This is a <strong>two-dimensional cellular automaton recorded as a three-dimensional building</strong>. X and Y belong to the cell neighbourhood. Z records time. Adjacent slabs show consecutive states; the cells do not count neighbours in Z.</p><p>A genuinely 3D automaton would update a volume through three spatial directions. Its complete history adds time as a fourth coordinate. We could inspect that through animation or slices, but it is a different experiment.</p><p>Our beginning already contains an arch with small gaps. The ordinary rule repairs some of those gaps and reaches a fixed section by generation 3. We did not discover an arch from a single cell. We also hold the foundation and provide a stable workshop floor. Those choices are part of the result.</p>
<details><summary>The small rules behind the walls</summary><p>Each site reads the eight neighbours in its previous 2D section. Outside the 25 × 15 array is empty. A solid site survives with at least four neighbours. An empty site becomes solid with at least five—unless sine changes that threshold.</p><pre><code># The rule changes who can be born.
birth = 4 + int(floor(2 * sin(TAU * generation / 12.0 + phase) + 0.5))
next_cell = int(neighbours &gt;= (4 if current_cell else birth))

# The bend changes where the saved state is placed.
x = x + 1.4 * sin(TAU * z / 14.0 + phase)

# The breath changes the room around an unchanged body.
x = x * (1.0 + 0.5 * sin(TAU * z / 14.0 + phase))
y = y * (1.0 + 0.25 * sin(TAU * z / 14.0 + phase))</code></pre><p>These are alternative strategies. Sine breath is variation along the length, not an automatically moving wall. The console changes phase and rebuilds while the visitor is outside.</p></details></section>
<section class="reading"><h2>The passage has an author.</h2><p>At first the wall makes room for you. A hollow follows the beginning you were given. You walk further into the record. The curve takes the exit out of view, although no cell has changed its decision.</p><p>Return to the console. Put sine into the rule.</p><p>The same beginning now carries you only part of the way. Ahead, the space your body needs has become material. The rule did not fail to make form. It made a form that refuses this walk.</p><p>Reserve the corridor. The way opens. A number appears: 160. Each count marks a decision we overruled so this body could pass.</p><p>There is an architectural question inside that number: whose passage do we protect, and which possible forms do we give up to protect it?</p></section>
<section><h2>Try the built workshop</h2><figure><img src="ca-forms-controls.png" alt="Actual Godot workshop console with strategy, phase, corridor, layers and replay buttons"><figcaption>Eight working controls. Step back to the entrance to change geometry. LAYERS exposes 8, 16 or 28 saved generations.</figcaption></figure>
<p>In Godot, open <code>res://commons/artifacts/ca_history_vault/workshop.tscn</code> and run that scene. Walk with WASD or the arrow keys; look with the mouse; click the console. Escape releases or recaptures the pointer.</p>
<p class="small">This is a separate form laboratory. It has not replaced CA_SoftRules or been inserted into the active museum route. The reusable artifact is registered as <code>ca_history_vault</code>.</p>
<details><summary>Evidence and the next test</summary><p>__CHECKS__ Godot checks cover agreement of every cell with an independent Python implementation, preservation of state under geometric transformations, changed history under sine and phase, actual displayed/collision triangle agreement, five physical walks, eight pointer controls, layer exposure and the occupied-room rebuild guard. Desktop visitor: 1.8 m tall, 0.6 m wide. No runtime script errors. These five walks establish the stated parameter settings; they do not establish every phase, seed or amplitude.</p><p>The first three strategies curve or scale geometry without changing its connectivity. Body access can still change when a passage becomes too small. The stronger follow-up is a comparison of several less architectural seeds, followed by a truly 3D neighbourhood. Only after that should we claim rules that generate new connected chambers, tunnels or branching forms.</p><p><a href="ca-forms-verification.json">Runtime checks and walk traces</a> · <a href="ca-forms-data.json">Recorded cellular histories</a> · <a href="ca-forms-notes.md">Methods and interpretation</a></p></details></section>
<footer class="small">Ada Research / 14 September 2026 / a form-making detour from <a href="ca-soft-rules.html">CA_SoftRules</a>. The next main hall remains CA_EdgeOfChaos.</footer></main><script src="ca-forms-review.js"></script></body></html>'''
save(O/'ca-form-strategies.html',html.replace('__CSS__',css).replace('__CHECKS__',str(receipt['checks'])))
notes='''# Walk inside a history — form study, 14 September 2026

User request: walk inside stacked cellular generations, combine sine and cellular automata, and compare form-making strategies.

Implemented standalone scene: res://commons/artifacts/ca_history_vault/workshop.tscn. Registered reusable artifact: ca_history_vault. Museum map/plan/primary/book sources remain guarded and unchanged. This is an experiment, not a new main-sequence hall.

25 × 15 binary cross-section, 28 generations, 0.4 m XY cells, 0.5 m slabs in Z. Eight-neighbour Moore update, synchronous previous state, empty outer boundary, survival >=4, birth >=5. The seed already contains an imperfect arch, and y=0 is held solid. The ordinary section stabilizes at generation 3. This is 2D CA plus recorded time, not 3D neighbourhood evolution. The workshop supplies a stable floor as well.

Strategies: straight history; x += 1.4 sin(2πz/14+phase); scale x by 1+.5sin and y by 1+.25sin; or change birth threshold to 4+floor(2sin(2πg/12+phase)+.5). These controls are separate alternatives. The geometry is held still during traversal. A declared optional corridor forces abs(x-12)<=2, y=1..6 empty after every update; its gold marks disclose intervention. This reserves a 2 m-wide, 2.4 m-high strip before geometric scaling.

At phase zero, straight/bend/breath each contain 3,965 occupied cells and preserve all binary states. Actual desktop traversal passed all three. The sine-rule history contains 8,289 occupied cells; the tested centre walk stops near z=3.20 m. Reserving the corridor yields 7,710 occupied cells and a complete traversal while suppressing 160 birth or survival decisions. The 579-cell difference includes propagation of those interventions.

35 rendered Godot checks: independent Python cell oracle; history preservation and change; phase changes state; neighbour locality; surface/collision triangle agreement; floor normals; five real physical walks; all eight actual pointer controls; eight-layer end face; occupied-room rebuild guard. All pass; no runtime script errors. A pre-existing missing-UID startup diagnostic remains unrelated. Walk tests use the actual 1.8 m-tall, 0.6 m-wide desktop capsule. Parameter tests do not establish all seeds, phases or amplitudes. Headset review is deferred.

Interpretation: a continuous geometric bend need not alter connectivity. It does change visibility and routes in physical coordinates. Scale can change which fixed-size body fits even while connectivity stays intact. Rule changes can fill an opening. Reserving a route is an explicit architectural decision, not spontaneous hospitality of the automaton.

Next useful comparison: multiple seeds without a preformed arch, fixed rule/volume budget, visible connected voids, and measured body access. Then compare a true 3D neighbourhood to the 2D history. Do not treat this initial arch test as proof of open-ended morphogenesis.
'''
save(O/'ca-forms-notes.md',notes)
save(E/'README.md',notes+'\n\nEvidence: receipt.json, report.json, publish hashes, browser checks and the linked published photographs. Reproduce with python -X utf8 ada_run/review_ca_forms.py, then python -X utf8 tools/build_ca_forms_review.py. The runner preserves existing editors and refuses unknown concurrent games/captures. It owns only its isolated muted Godot process.\n')
manifest=[p.relative_to(R/'doc/research').as_posix() for p in O.glob('ca-forms-*') if p.suffix in ['.js','.md','.png','.json']]+['possible-bodies/ca-form-strategies.html']
save(E/'publish-targets.json',json.dumps(sorted(manifest),indent=2))
save(E/'publish-hashes.json',json.dumps({p:sha(R/'doc/research'/p) for p in manifest},indent=2))
save(R/'ada_run/publish_ca_forms.ps1',(R/'ada_run/publish_ca_soft_rules.ps1').read_text().replace('ca-soft-rules-review-2026-09-14','ca-forms-review-2026-09-14'))
print('Built',len(manifest),'assets from verified Godot captures.')
