"""Publish the later sweep lesson and its native endless-museum evidence."""
from pathlib import Path
import ast, hashlib, html, json, re
import markdown
from tube_painting_study import REVIEW, HALL, READINGS, EDITS

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations'/REVIEW
BASE = ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine'
OUT.mkdir(parents=True, exist_ok=True)
E = html.escape

MAKING = '''## Continue a drawing that has already begun

This is the later **sweep** lesson, in **L-systems → Grammars and Curves**, before Architecture. Point Trace introduced keeping positions. Mesh introduced vertices and triangle connections; refinement introduced circular sampling; rotation supplied changing orientation. Here those tools meet: a path carries a ring, and neighbouring rings carry faces. Point Trace keeps its earlier, simpler encounter.

### First use what is here

Three supplied strokes are suspended in front of the wall. Their six pink end grips are part of the interface. Grab a lower end and move your hand slowly. The old length stays where it was; sampled positions are added beyond it. Release to leave the addition in the air. You can also continue from the other end; the stored path reverses its order before growing there.

Bring an end close to the receiving wall. Its centre snaps to the wall surface and sampling stops until you release. This makes a visible attachment. It is not a structural joint or a gravity simulation. The runs can now join through explicit sockets. Their skins can overlap and do not become a welded solid or block the visitor. Together their paths can compose another, incomplete wall in front of the room's wall.

The pen on the plinth begins a separate stroke. Pick it up, hold its trigger while moving, and release the trigger to keep the line. On desktop, the existing right-click pickup/drop and left-button held action drive the same pen. The artifact adds no player, controller mapping or installation step.

**UNDO** restores the whole drawing before the last completed gesture or geometry edit. Extending a supplied line and undoing leaves the supplied line intact. **CLEAR** removes the strokes; **EXAMPLE** replaces them with the three opening strokes using the current radius and side count. Both can be undone. **RESET** also restores default settings and returns the pen; put it down first. Undo restores geometry, not the pen pose or the next-stroke settings. History keeps the last sixteen states during this visit. Closing or unloading the hall does not save a drawing to disk.

### Inspect the same work three times

**VIEW** cycles TUBE → PATH → RINGS → TUBE. It changes the representation, not the stored positions. PATH is the retained centreline. RINGS shows the sampled cross-sections. TUBE connects them with faces and closes the two ends. The controls are available after you finish a gesture.

**THICKNESS**, **SIDES** and **COLOUR** edit the last stroke in the list and choose the setting for the next new pen stroke. Continuing an earlier stroke preserves that stroke's own material and resolution. Undo an extension before trying a different route. The readout counts the last stroke in the list, not the sum of the whole work.

### What one ring needs

The production builder is `commons/primitives/pipes/swept_tube.gd`. Its `build(path, radius, sides)` function receives positions we already know how to retain. At each position it supplies two perpendicular directions, `frame_normal` and `binormal`, across the path. This is the ring expression, taken from that builder:

```gdscript
var angle := TAU * j / float(sides)
var radial := frame_normal*cos(angle)+binormal*sin(angle)
vertices.append(points[i]+radius*radial)
```

`i` addresses a point along the path; `j` addresses a place around its ring. Changing `sides` changes the second count. It does not take more samples of your hand movement. Changing `radius` moves each ring vertex away from its centre without moving the centre.

The supplied frame transport carries the ring around bends without making it suddenly look towards world-up. Understanding or rewriting quaternion transport is not required for this first edit. First locate the familiar circular rule inside the supplied construction.

### Join two rings

Let `a` and `b` be neighbouring vertices on one ring, and `c` and `d` their corresponding neighbours on the next. This production line adds two triangles:

```gdscript
indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
```

The last address wraps to the first with `% sides`. That closes the seam around a ring. Separate triangles cap the two ends. For N path points and S sides, the body has `2 × (N - 1) × S` triangles and the two caps add `2 × S`. The total is `2 × N × S`.

Make the one source edit above before changing the path: twelve sides become eight. Each opening stroke retains its 41 centres and 0.065 m radius. The capped mesh changes from 984 to 656 triangles. Look near a curved silhouette. Then make your own continuation and compare again. The number is a check on a visible decision, not the reason to prefer one drawing.

### After the first sweep: a connected system

Choose **NETWORK** to load the three-form example. **FORM** cycles the last run and next pen stroke through tube, pipe and cable. A tube retains the path you drew. A pipe uses outer and inner rings with annular rims, leaving an open bore; its sleeves make the mouths visible. A cable redraws between its endpoints and any joined supports with a downward parabolic offset. **SAG** changes that offset while keeping the supports fixed. This is authored drape, not a simulation of gravity or cable length.

Hold the pen trigger beside another run and draw away to start a branch. To join a free end, continue it close to another run, wait for the amber marker, then release. The shared port is recorded only on release. Silver fittings mark these sockets. Connected endpoint grips disappear so extending cannot silently pull a joint apart. Use the pen there to branch, or UNDO to restore both runs and their port records. Merely crossing two skins makes no connection.

`run_network.gd` owns that relationship; `swept_tube.gd` owns the mesh. The reusable `PipeLayout` accepts named anchors and per-run `kind`, radius, sides, sag and optional sampled points. Moving an anchor rebuilds its dependent runs. Its existing glass and drain command builders remain available. See `commons/primitives/pipes/README.md` and `layouts/three_forms.json` for an executable layout example. The hand-drawn runs have no fluid, audio or electrical routing and does not save a drawing between hall visits.

### Explore the form library

**PARTS** cycles four groups from the existing pipe and glass library: straight, 45° and 90° bends, U-bend and S-bend; tee, Y-junction, cross and reducer; coil, wave, flask and beaker; cap, drip and condenser. **CABLES** shows five existing cable arrangements: chord, spline, authored sag, festoon and truss. These are supplied forms to work from, rather than five new algorithms to learn now.

Each group replaces the current drawing; UNDO brings that drawing back. A pink grip marks every declared free port, including the third and fourth arms of a junction. Choose FORM, then take a grip and draw onward. The supplied piece stays in place while a new tube, hollow pipe or cable grows from its port. Release beside another free port to connect two pieces. On supplied parts only the declared ports accept a connection; on drawn runs you can also branch along the path.

The catalogue reuses the existing geometry and port metadata through `part_library.gd`. Some stock pieces are solid display meshes; they are not all hollow plumbing. The new PIPE run has an open bore. Neither kind simulates flow. The supplied pieces keep their shape in PATH and RINGS views while your new runs reveal their construction. THICKNESS and SIDES apply to drawn runs, not the supplied part meshes. COLOUR can recolour the last supplied piece. Eight pieces and runs share the workbench budget, so a five-piece group leaves room for three additions.

### What is supplied, and what is limited

`tube_painting.gd` owns the retained strokes, undo states, view modes and bounded input. `tube_pen.gd` reuses the existing drawing pen. `tube_end.gd` reuses the existing pickup handle. `station.gd` supplies the museum console. Their complete source accompanies this tutorial; keep them intact for the first ring edit.

New samples are actual nib or end-grip positions at least 0.045 m apart. A sudden jump above 0.75 m stops further additions until release. Each stroke can retain 256 positions; the work can keep eight pieces and runs. The drawing volume and feedback keep an endpoint from writing into another exhibit. A tube at the point limit needs a separate new stroke. Tight turns and self-intersections are not repaired into a manifold solid. The pink grips and the wall are interactive/collidable; the tube skin is visual geometry. Native automated pickup and input tests are recorded separately from physical headset testing.

### Optional application: patch a sound, wake a machine

Beside the drawing workbench, the existing modular rack now has a focused VCO → VCF → VCA → SPEAKER patch. Close POWER with the physical lever or its matching button. WAVE selects saw, square, triangle or sine (0–3); FREQ and FINE change pitch, AMP changes level, and PAN moves the sound between channels. Turn CUTOFF, then switch the FILTER lever. You should hear the high harmonics change. The sound is generated continuously; adjusting the filter does not restart a recorded note.

Unplug the VCF route and connect VCO OUT directly to VCA IN. The signal bypasses the filter. An incomplete path to SPEAKER is silent. Grab and release plugs close to a compatible socket, or select an output then an input with the museum pointer. A selected occupied socket removes its cord. PATCH EXAMPLE restores the four supplied cords; UNPATCH removes them. Put down a held plug before either operation.

The second route is POWER GATE → MOTOR. Unplugging it stops the coloured bodies without breaking the sound patch. Opening the power lever stops both. Audio and gate sockets accept their own signal kind; a drawn tube crossing a socket cannot silently become an electrical connection. Moving beads show route direction and enabled state at an illustrative speed, not audio frequency or electrical propagation.

The bodies reuse transformed primitives and swept limbs. Their cranks use a shared elapsed phase at three different rates. This is a kinematic study after Jean Tinguely and Niki de Saint Phalle, not a physical motor model or a reconstruction of a particular sculpture. The connected system extends the sweep lesson; synthesizer implementation is supplied. Inspect `commons/audio/cables/live_patch.gd` for the bounded audio graph and `commons/artifacts/spine_studies/patch_and_motion.gd` for its motor receiver. Other rack presets retain their existing sound behavior.

### Optional application: let the line become a ceiling

Look above the drawing bay. The small console on the left controls a canopy made with the same `PipeLayout` and hollow sweep. **RULE** cycles woven crossings, returning U-bends and branching ribs. **DIAMETER** selects 0.36, 0.60 or 0.84 metres; **REPEAT** selects three, five or seven lanes or branch stations. **FINISH** changes pink lacquer to pale enamel and chrome. **RESET** restores the pink five-lane weave without changing the drawing or synth patch.

Keep diameter and repetition fixed. Change only the rule, then look up from the same position. In WEAVE, the two families have opposite heights at every crossing. A cosine raises and lowers each run; the next lane adds half a cycle. In RIBS, repeated branches meet a central run at named anchors. In RETURNS, each lane runs to a semicircular bend and comes back. The same rings and faces make all three; the path rule changes their relation.

`commons/primitives/pipes/pipe_canopy.gd` is the reusable generator. Its `make_layout(mode, count, radius)` returns an ordinary layout dictionary, so another scene can use it with the existing PipeLayout. The museum wrapper adds a frame, hangers, controls, luminaires and a local reflection probe. The inherited museum ceiling presets still handle conventional tiles, vents and fixtures. This installation is an open canopy above the work, leading towards Architecture.

The pipes have real inner surfaces and open mouths. The rib intersections share logical anchors but their surfaces overlap; they are not welded plumbing and carry no simulated flow. The canopy is visual geometry above the reachable drawing volume. Support posts and the console collide. Meshes rebuild only when the layout changes; changing finish reuses them. A local probe captures the surrounding room once, so it is not a live mirror of subsequent drawing or machine movement. Settings last for this hall visit. Physical Quest performance remains untested.

'''

for filename, addition in [
    ('tutorial.md', MAKING),
    ('technical.md', '''## Sweeping a retained path

`swept_tube.gd` constructs a capped or hollow ArrayMesh with clockwise faces and radial side normals. It drops consecutive duplicate points, supplies a transported perpendicular frame, and keeps ring resolution distinct from spatial input sampling. `tube_painting.gd` bounds strokes to eight and points to 256 per stroke, with sixteen undo snapshots. End grips remain persistent pickup bodies while the displayed meshes rebuild at most thirty times per second during drawing. Release commits; extending reuses an existing record and leaves its prior centres unchanged. Wall attachment clamps the final centre to the receiver's front surface. Tube geometry does not collide or weld. FORM also offers a hollow pipe and a cable with authored parabolic sag between its endpoints and joined supports. Cable sag is a bounded shape rule, not gravity integration. Join-on-release uses shared port IDs, with visible couplers and fixed connected ends; a pen gesture beginning on another run makes a branch. Undo restores geometry and ports together. Work does not persist after its hall unloads. PATH/RINGS/TUBE share the same records. Native tests cover topology, winding, frame edge cases, pickup, trigger dispatch, extension, undo, attachment and budgets; physical Quest use and performance remain unverified.

PARTS and CABLES expose sixteen existing GlassRack segment forms and five CableBuilder arrangements through `part_library.gd`. Cached Mesh resources and local transforms are retained in undo records. Named port metadata supplies up to four persistent grips per record. Taking a free part grip creates a new run while the part stays fixed; joining to a part tests declared ports only. Thirty-two pooled pickup bodies cover eight four-port records. The catalogue shares the eight-record budget with drawn runs. Stock part meshes retain their representation in PATH/RINGS and are not uniformly hollow or watertight. Native tests cover all twenty-one forms, every free port, extension, exact undo and XR-tools pickup on a third junction port.

A separate `patch_and_motion.gd` application now sits beside the drawing. It reuses UniversalVRAudioController with the focused `patch_and_motion` preset. VCO → VCF → VCA → SPEAKER is an explicit live audio path; VCO → VCA bypasses the filter. A band-limited additive source feeds a native AudioEffectLowPassFilter on the rack's own bus. A separate typed gate route enables the three kinematic bodies. The lever controls both sources; pulling either route leaves the other intact. Body rotations and crank rods are driven by elapsed phase, not a force solver. SynthCable uses the shared sweep only when endpoints change. Plug bodies are XRToolsPickable roots, with the same socket transactions on desktop. Per-cable route snapshots survive disconnects. The museum test measures bus samples before/after filter bypass, exercises desktop ray pickup and native XR pickup, and checks aisle clearance. Other presets retain their existing sound generation; this is not a complete arbitrary modular DSP engine.

`pipe_canopy.gd` generates bounded ribs, weave and return layouts above this bay, reusing PipeLayout and swept_run. The maximum is 22 runs; no run has more than 97 points, with 24 radial sides. The widest pipe is 0.84 m across. All settings keep pipe surfaces above 5.8 m, beyond the receiving wall and drawing volume. Native checks cover all 27 layout combinations, maximum-density mesh vertices, nearest-segment weave separation, pointer dispatch and collision targets, unaffected drawing/audio routes, and static geometry reuse. The museum wrapper adds a freestanding frame and a once-updated reflection probe that excludes the pipe layer. Gloss is a StandardMaterial3D finish. Junction surfaces are not Boolean-welded and the installation has no flow simulation.
'''),
    ('critical.md', '''## An inherited beginning

The opening strokes are authored examples, not records of another online visitor. Their unfinished ends make continuation the first invitation. Undo protects what was there before your gesture. The work can become a partition without acquiring the authority of a collision wall. The shared sweep also makes a pipe or cable: a hollow passage, a drafted sag, and a retained gesture do different work even when their surfaces use the same construction. A crossing is not yet a connection; the visitor must offer an endpoint. Suspension, available ends, and easy restoration are permissions written into this apparatus. The tutorial exposes the rings and triangles while the encounter asks what it means to carry somebody else's beginning further.

The nearby kinetic study follows the user's proposed encounter between Tinguely's mechanisms and Saint Phalle's coloured bodies. Their historical collaboration is documented in [Myths & Machines](https://www.hauserwirth.com/hauser-wirth-exhibitions/niki-de-saint-phalle-and-jean-tinguely-myths-and-machines/), made with the Niki Charitable Art Foundation. These Ada figures are original procedural studies. A shared rotation rule grants each body a different rate; the visitor can interrupt the grant by removing the motor cord. Sound need not stop with it. The work makes connection, interruption and dependence available as separate acts.
''')]:
    p=ROOT/'commons/maps'/HALL/filename
    text=p.read_text(encoding='utf-8-sig')
    start='<!-- tube-making -->'; end='<!-- /tube-making -->'
    block=start+'\n\n'+addition.strip()+'\n\n'+end
    if start in text: text=re.sub(re.escape(start)+r'.*?'+re.escape(end),lambda _:block,text,flags=re.S)
    else: text=text.rstrip()+'\n\n'+block+'\n'
    text=text.replace('This application reuses trace, mesh, refinement, rotation, array, sweep.', 'This lesson introduces sweep using trace, mesh, refinement, rotation and array.')
    if filename == 'technical.md': p.write_bytes(text.encode('utf-8'))
    else: p.write_text(text,encoding='utf-8')

# Reuse the existing review's typography without importing its publishing side effects.
parsed=ast.parse((ROOT/'tools/publish_paired_time_study.py').read_text(encoding='utf-8'))
css=next(ast.literal_eval(n.value) for n in parsed.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='css' for t in n.targets))
css+=''.join(f'.states #{s}:checked~.{s}{{display:block}}' for s in ['skin','path','rings','continued','network','network-joined'] + ['parts-'+str(i) for i in range(5)] + ['parts-extended','parts-connected'])
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+E(title)+'</title><style>'+css+'</style></head><body>'+body+'</body></html>'

sources={}
for rel in ['commons/artifacts/spine_studies/'+n for n in ['tube_surface.gd','tube_painting.gd','tube_pen.gd','tube_end.gd']] + ['commons/primitives/pipes/'+n for n in ['swept_tube.gd','run_network.gd','swept_run.gd','pipe_layout.gd','part_library.gd']]:
    p=ROOT/rel; name=p.name; raw=p.read_bytes()
    sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(raw).hexdigest()
    (OUT/(name+'.html')).write_text(page(name,'<main><a href="index.html#making">Back to the work</a><h2>'+E(name)+'</h2><pre>'+E(raw.decode())+'</pre></main>'),encoding='utf-8')
raw=(ROOT/'commons/maps'/HALL/'tutorial.md').read_bytes()
(OUT/'making.html').write_text(page('Continue a tube / making','<meta name="source-sha256" content="'+hashlib.sha256(raw).hexdigest()+'"><main><a href="index.html#making">Back to the work</a>'+markdown.markdown(raw.decode(),extensions=['fenced_code','tables'])+'</main>'),encoding='utf-8')
report_path=BASE/'figures'/f'{HALL}-report.json'
report=json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {'passed':False,'checks':[]}
(OUT/'evidence.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(OUT/'sources.json').write_text(json.dumps(sources,indent=2)+'\n',encoding='utf-8')
states=[('network','05 / Pipe, cable, tube','NETWORK on the museum console: a hollow white pipe with sleeves, a black cable with authored sag, and a retained pink gesture. Silver sockets mark explicit connections.'),('network-joined','06 / Joined after use','The free pink end has been extended into the cable through the same sampled-input entry as the pickup, then released to join. Undo can restore the earlier work.'),('skin','01 / Already begun','Three suspended strokes, with a pickup at either end.'),('path','02 / Path','The same retained centres, without the surface.'),('rings','03 / Rings','Cross-sections around those centres. No path point has moved.'),('continued','04 / Continued','A deterministic continuation replayed through the same position-sampling function used by the pickups. The pink stroke reaches the wall; the other two remain suspended.')]
controls=''.join(f'<input type="radio" name="state" id="{s}" '+('checked ' if i==0 else '')+f'><label for="{s}">{E(label)}</label>' for i,(s,label,_) in enumerate(states))
figures=''.join(f'<figure class="{s}"><img src="../2026-10-02-studies-in-the-spine/figures/tube-{s}.png" alt="{E(caption)}"><figcaption>{E(caption)} Native Godot capture, from the same camera inside the endless museum.</figcaption></figure>' for s,_,caption in states)
reading=markdown.markdown(READINGS['tube_painting'])
form_states=[('parts-0','Bends','Straight, 45° and 90° bends, U-bend and S-bend.'),('parts-1','Branches','Tee, Y-junction, cross and reducer. Each free branch has a pickup grip.'),('parts-2','Coils and vessels','Coil, wave, flask and beaker, in pink.'),('parts-3','End pieces','Cap, drip and condenser. Connection points come from each model’s port metadata.'),('parts-4','Cable forms','Chord, spline, authored sag, festoon and truss.'),('parts-extended','After pickup','A new run extends from the cross’s third port after an automated XR-tools pickup and release. The original piece remains in place.')]
form_states.append(('parts-connected','Connected','A pink run joins the cross to the Y-junction through their named ports, using a deterministic sampled gesture. Undo restores both free ports and removes the addition.'))
form_controls=''.join(f'<input type="radio" name="form" id="{s}" '+('checked ' if i==1 else '')+f'><label for="{s}">{E(label)}</label>' for i,(s,label,_) in enumerate(form_states))
form_figures=''.join(f'<figure class="{s}"><img loading="lazy" src="../2026-10-02-studies-in-the-spine/figures/tube-{s}.png" alt="{E(caption)}"><figcaption>{E(caption)} Captured in the endless museum.</figcaption></figure>' for s,_,caption in form_states)
form_section=f'''<section id="forms"><h2>Twenty-one forms to continue</h2><p>The existing pipe, glass and cable libraries now meet at this workbench. PARTS cycles four groups; CABLES opens the five cable arrangements. Each selection replaces the current work. UNDO brings it back.</p><div class="states">{form_controls}{form_figures}</div><p>Choose FORM, then take a free pink grip and draw onward. The supplied part stays fixed; your new run can reach another part’s free port or remain suspended. Parts and additions share eight available places.</p><p>The stock models include solid display forms. New PIPE runs are hollow; connections are explicit shared sockets, with no fluid simulation. PATH and RINGS reveal the runs you draw while the stock forms keep their shape.</p><p><a href="part_library.gd.html">The library adapter</a> · <a href="making.html">Continue with the making lesson</a></p></section>'''
passed=sum(c['passed'] for c in report['checks'])
body=f'''<header><div class="eyebrow">Ada / L-systems / Grammars and Curves / 2 October 2026</div><h1>A line takes up room.</h1><p class="lead">Someone has already begun. Take an end and continue.</p><p>A later geometry encounter, before Architecture. Continue the opening strokes, or choose NETWORK to combine a pipe, a cable and a drawn tube.</p><nav><a href="#museum">In the museum</a><a href="#reading">Reading</a><a href="#making">Making</a></nav></header><main><section id="museum"><div class="states">{controls}{figures}</div><p>Grab either pink end and extend the tube. Release in the air to leave it suspended; bring it close to the wall to attach. Use the pen for a separate stroke, or begin beside an existing run to branch. Release an end near another run to join at the amber marker. UNDO restores the drawing and its joints before your last gesture.</p><details><summary>The work and its console</summary><img loading="lazy" src="../2026-10-02-studies-in-the-spine/figures/tube_painting.png" alt="Tube painting installed in the actual museum, with pen and console"><p>THICKNESS · SIDES · COLOUR · VIEW · UNDO · CLEAR · EXAMPLE · PEN HOME · RESET · FORM · SAG · NETWORK</p><p>Grips continue free ends. Connected ends become fixed sockets; draw from a socket to branch. FORM cycles tube, pipe and cable for the last run and the next pen stroke. SAG changes the last cable’s drape. Thickness, sides and colour edit the last run and set the next pen stroke. Finish a gesture before changing those settings.</p></details></section><section id="reading" class="reading">{reading}</section><section id="making"><h2>When a path can carry a surface</h2><div class="note"><p>Point → line → retained trace → mesh faces → circular sampling and orientation → rings along a path → tube painting.</p><p>This adds one later capability, <strong>sweep</strong>. The early Point Trace lesson keeps its simpler task. Here the current hall's interpreted paths acquire width before we enter Architecture.</p></div><p>The first edit keeps the centres and radius while changing twelve ring sides to eight. Each opening stroke changes from 984 triangles to 656. Then extend it and inspect what your gesture added.</p><p><a href="making.html">Read the separate making lesson</a> · <a href="swept_tube.gd.html">The shared surface builder</a> · <a href="tube_painting.gd.html">The drawing and undo logic</a> · <a href="/tutorial-lineage#node=sweep">See the lineage</a></p><details><summary>What the work holds, and what it leaves out</summary><p>The supplied strokes are authored beginnings. The skin remains visual geometry. Pipe bores are open; cable sag is a drafted shape, not a rope simulation. Shared sockets create logical connections; the fitting meshes are not Boolean-welded plumbing, and no liquid or audio flows through them. Wall attachment fixes an endpoint; crossing alone does not join runs. Up to eight strokes and sixteen undo states live in this hall instance. They are not saved after unloading it.</p><p>Sampling retains actual input positions, with a 0.045 m minimum gap and 256-point limit per stroke. The supplied frame transport is available to inspect without becoming the first exercise.</p><p><a href="tube_pen.gd.html">Pen input</a> · <a href="tube_end.gd.html">End pickup</a> · <a href="run_network.gd.html">Connections</a> · <a href="pipe_layout.gd.html">Reusable layout</a></p></details><p class="small">{passed} / {len(report['checks'])} native checks pass, including production pickup/trigger routes, mesh winding, preserved paths, wall attachment, undo and limits. Headset comfort and Quest performance await a physical pass.</p><p class="small"><a href="evidence.json">Native results</a> · <a href="sources.json">Source hashes</a></p></section></main><footer><a href="../2026-10-02-studies-in-the-spine/index.html#tube_painting">Installed studies</a></footer>'''
body=body.replace('<a href="#reading">Reading</a>','<a href="#forms">All forms</a><a href="#reading">Reading</a>')
body=body.replace('<section id="reading"','<section><h2>A cord makes something happen</h2><p>The existing synth rack and a rotating three-body machine now share this bay.</p><p><a href="../2026-10-02-patch-and-motion/index.html">See the working patch and machine in the museum</a></p></section>'+form_section+'<section id="reading"')
body=body.replace('FORM · SAG · NETWORK</p>','FORM · SAG · NETWORK · PARTS · CABLES</p>')
body=body.replace('<section id="reading"','<section><h2>The line becomes a ceiling</h2><p>Large glossy pipes carry the same sweep into the space overhead.</p><p><a href="../2026-10-02-glossy-pipe-ceiling/index.html#museum">Compare ribs, weave and returning loops in the museum</a></p></section><section id="reading"')
body=body.replace('Up to eight strokes and sixteen undo states','Up to eight pieces and runs and sixteen undo states')
(OUT/'index.html').write_text(page('A line takes up room — Ada tube painting',body),encoding='utf-8')
(OUT/'README.md').write_text('''# A line takes up room

User direction: place tube painting later in the geometry lineage, and begin with existing suspended strokes that can be extended from their ends. Implemented in LSystems_Grammars_And_Curves, before Architecture; the early Point_Trace encounter is untouched by this pass.

Three authored starters, six persistent end pickups, new-stroke pen, wall endpoint attachment, path/rings/skin views, thickness/sides/colour, undo, clear, example and reset. FORM, SAG and NETWORK add hollow pipes, drafted cables, joining and branching through a shared sweep and explicit port records. The runs are visual geometry with pickup grips and logical sockets, not soft bodies or welded solids. The older PipeLayout now supports its real glass/drain APIs and sampled pipe/tube/cable paths; the older cable builder shares the sweep, uses span-aligned sag handles, and rebuilds only after changes. Work is retained in the current hall instance; no disk persistence.

PARTS and CABLES also expose all sixteen stock glass/pipe segments and five cable arrangements. The fixed pieces retain their existing meshes and named ports. Every free port can start a new run; junctions expose third and fourth grips. Supplied meshes are not all hollow plumbing. The eight-record budget counts pieces and drawn runs together. Native tests extend every port and restore the exact earlier records with undo, join two pieces, and exercise XR-tools pickup on a cross branch. Seven form-library images show the actual museum.

The curriculum adds the sweep capability after trace, mesh, refinement, rotation and arrays. Canonical final/tutorial/technical/critical and placement companions are updated. Review evidence comes from the actual endless museum in a private Godot runtime, not the artifact grid. The continued-state image uses a deterministic sampled-input replay; XR and desktop pickup routes have separate assertions.

Reproduce: publish_spine_studies.py, capture_spine_studies.py LSystems_Grammars_And_Curves, publish_tube_painting.py, publish_spine_studies.py; export the lsystems book, refresh companion snapshots, build_tutorial_lineage.py, verify_spine_studies.py --http --refresh-provenance. Re-run this publisher after the final tutorial normalization to keep its making snapshot current.

Physical headset use and Quest performance are unverified. Saved locally; not committed.
''',encoding='utf-8')
print(f'Published {REVIEW}: {passed}/{len(report["checks"])} native checks.')
