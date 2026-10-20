from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Topology_Entropy_Morphogenesis';S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
S.mkdir(exist_ok=True)
code='''extends Node3D
const PointBody = preload("point_body.gd")
const CUT_SPAN := 0.15
const MODES := ["ALL", "FREQUENCY", "NOISE", "CUT"]
var mode := 0
var preview := 0.3
var committed := 0.3
var built_mode := 0
var point: XRToolsPickable
var reading := Label3D.new()
var generators: Array[GyroidFieldGenerator] = []
var holders: Array[Node3D] = []

func recipe(value: float, choice: int) -> Dictionary:
	var s := clampf(value, 0.0, 1.0)
	var f := s if choice == 0 or choice == 1 else 0.3
	var n := s if choice == 0 or choice == 2 else 0.3
	var t := s if choice == 0 or choice == 3 else 0.3
	return {"frequency": lerpf(0.9, 1.6, f),
		"noise_amp": lerpf(0.05, 0.20, n),
		"threshold": CUT_SPAN * (2.0 * t - 1.0)}

func assign(generator: GyroidFieldGenerator, values: Dictionary) -> void:
	generator.frequency = values.frequency
	generator.noise_amp = values.noise_amp
	generator.threshold = values.threshold

func apply_preview() -> void:
	assign(generators[1], recipe(preview, mode))
	generators[1].regenerate(holders[1])
	committed = preview
	built_mode = mode
	refresh()

func reset() -> void:
	mode = 0
	preview = 0.3
	apply_preview()

func _ready() -> void:
	for side in 2:
		var holder := Node3D.new()
		holder.position = Vector3(-1.25 if side == 0 else 1.25, 1.6, 0)
		holder.scale = Vector3.ONE * 0.25
		add_child(holder)
		holders.append(holder)
		var generator := GyroidFieldGenerator.new()
		generator.box_size = Vector3.ONE * 8.0
		generator.voxel_resolution = Vector3i(24, 24, 24)
		generator.noise.seed = 1337
		assign(generator, recipe(0.3, 0))
		generator.generate_gyroid_mesh(holder)
		generator.generate_collision(holder)
		generators.append(generator)
		plinth(holder.position.x)
		caption("A / KEPT AT 0.30" if side == 0 else "B / YOUR RECIPE", Vector3(holder.position.x, 2.8, 0))
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body):
		if point.held(): apply_preview())
	park()
	reading.position = Vector3(0, 3.25, 0.8)
	reading.font_size = 40
	reading.pixel_size = 0.002
	add_child(reading)
	caption("PULL UP: 0.80m -> 1.60m / TRIGGER: BUILD", Vector3(0, 0.65, 1.35))
	refresh()

func _physics_process(_delta: float) -> void:
	if point.held():
		preview = clampf((to_local(point.global_position).y - 0.8) / 0.8, 0.0, 1.0)
		refresh()
	else:
		park()

func park() -> void:
	point.position = Vector3(0, 0.8 + preview * 0.8, 1.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = (mode + 1) % MODES.size()
			KEY_UP: preview = minf(1.0, preview + 0.1)
			KEY_DOWN: preview = maxf(0.0, preview - 0.1)
			KEY_SPACE: apply_preview()
			KEY_R: reset()
			_: return
		refresh()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	var values := recipe(preview, mode)
	reading.text = "PREVIEW %.2f / %s\\nk %.3f   noise %.3f   cut %.3f\\nBUILT %.2f / %s\\n1: MODE   UP/DOWN: PREVIEW   SPACE: BUILD   R: RESET" % [preview, MODES[mode], values.frequency, values.noise_amp, values.threshold, committed, MODES[built_mode]]

func caption(words: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = 32
	label.pixel_size = 0.002
	add_child(label)

func plinth(x: float) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1, 0.6, 2.1)
	surface.mesh = mesh
	surface.position = Vector3(x, 0.3, 0)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("33343d")
	surface.material_override = finish
	add_child(surface)
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	boundary.shape = shape
	surface.add_child(body)
	body.add_child(boundary)
'''
(S/'recipe.gd').write_bytes(code.encode())
shutil.copyfile(S.parent/'ProceduralGeneration_Reaction_Diffusion_Systems/point_body.gd',S/'point_body.gd')
(S/'study.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="recipe.gd" id="1"]\n\n[node name="MorphogenesisLesson" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf8')
intro='''# Who connected the controls?

**Learning elements**

- One control, several named parameters
- Holding other parameters fixed
- Field values versus a selected boundary
- Previewing a change before rebuilding geometry

<!-- @entropy_morphogenesis -->

Look through one opening in the large pale surface. Press S at the museum desk. The form is reconstructed. Follow the opening, then read the new frequency, noise amplitude and threshold. A single action changed three numbers.

Last hall you kept two fields at the same step and isolated their local reaction. Keep that way of comparing. Here we use a different field: a three-dimensional sine rule with a fixed noise contribution. It is not the previous concentration array lifted into space, and it has no simulation clock.

The existing generator samples this field and constructs a boundary. We will keep that machinery supplied and write the recipe that controls it. The same PointBody becomes our hand control. Two small surfaces make the comparison readable: A keeps the opening recipe; B receives your change.

## The operation

Read `recipe()` first. Its three named outputs have different jobs. **Frequency** changes how quickly the sine field varies across space. **Noise amplitude** changes the contribution of a fixed noise field. **Threshold** chooses which field value becomes the boundary. Moving a threshold does not alter the underlying sine-and-noise values.

ALL connects the selected value to all three outputs. FREQUENCY, NOISE and CUT connect it to one output and hold the other two at their opening value, 0.3. Each comparison therefore returns to a common reference; it does not accumulate the previous mode's edits.

At value 0.3, the recipe is frequency **1.11**, noise **0.095**, cut **−0.06**. Predict value 1 before rebuilding:

|Mode|Frequency|Noise amplitude|Cut|
|---|---:|---:|---:|
|ALL|1.60|0.20|0.15|
|FREQUENCY|1.60|0.095|−0.06|
|NOISE|1.11|0.20|−0.06|
|CUT|1.11|0.095|0.15|

`lerpf()` interpolates between two numbers. The cut uses a centred range: `2 * value - 1` runs from −1 to 1; `CUT_SPAN` sets its extent. The dictionary retains the names when `assign()` passes the outputs to their recipients. None of these calculations measures entropy.

## Run beside the existing artifact

In the Endless Museum project, put `recipe.gd` and the unchanged `point_body.gd` in one folder. Attach `recipe.gd` to an empty Node3D at floor level and unit scale in a clear part of this hall. It creates both small specimens, plinths, labels and the point. The museum already supplies the player, camera, lighting and XRTools. The accompanying `study.tscn` is this one-node host.

**Supplied dependency:** the project's `GyroidFieldGenerator`, declared in `algorithms/spacetopology/gyroid_cheese/GyroidFieldGenerator.gd`, supplies field sampling, surface extraction and collision. Its MarchingCubesGenerator, VoxelChunk and CaveCollisionGenerator dependencies remain in the project. We do not recreate their algorithms or claim they have been taught here. This example runs inside the project, not in a blank Godot installation.

Both generators use seed 1337, an eight-unit cube and 24 sampling cells per edge. Their holders display them at quarter scale. Each specimen is two metres wide; the generator's field coordinates stay unchanged. This deliberately cubic fixture avoids the supplied generator's use of one spacing derived from box width for all three axes. The large installed specimen has its own dimensions and is not an identical third copy.

### recipe.gd — complete construction

The lesson's new code is `recipe()` and `assign()`. The rest connects their result to supplied geometry and the familiar point. It is printed in full so the host can run without hidden child nodes.

'''
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
end='''
## Try the comparison

Press **1** to select ALL, FREQUENCY, NOISE or CUT. Pick up the black point. Raising it from 0.8 to 1.6 metres in the lesson's local frame previews a value from 0 to 1; beyond those heights the value is clamped. Press its trigger to rebuild B. Previewing alone leaves both meshes intact. Releasing keeps the last preview and built geometry. The readout distinguishes them.

On desktop, **Up/Down** adjust the preview, **Space** builds and **R** resets. These clock-free comparisons also work with keyboard controls while you inspect the museum. Mode selection is keyboard-driven in this compact student host; the installed large artifact has its separate VR desk.

Build B at value 1 in each mode. Check the numbers against the table and return to the same beginning when comparing appearances. A stays unchanged throughout. Two surfaces that look different need not have different connectivity. More triangles need not provide more room to pass. These small models have collision surfaces, but are not a test that a player can walk through the large exhibit.

### point_body.gd — carried unchanged

Copy this file from Reaction–diffusion. We reuse its shape, collision and pickup behaviour; the trigger now commits a recipe instead of planting a patch.

'''
tail='''
## Make an independent change

Change only `CUT_SPAN` from **0.15 to 0.30** and restart. Predict ALL at value 1: frequency and noise remain **1.60** and **0.20**; the cut becomes **0.30**. The opening cut also becomes **−0.12**, because the same recipe builds A at 0.3. In CUT mode, B's frequency and noise remain **1.11** and **0.095**. Check these consequences before judging the surface.

For one point in space, changing just the threshold by 0.15 changes the generator's normalized density by −0.025 wherever its clamp does not activate: its conversion is `(field - threshold) / 6 + 0.5`. That is a testable consequence of the supplied mapping. It does not predict every opening or a universal change in topology.

The museum's S control bundles parameters. LEVEL changes its threshold centre; NOISE toggles its noise contribution; RESOLUTION changes sampling; RESET restores the opening settings. These are authored choices. The source name “entropy” does not turn the control into a measured entropy value.

This closes Soft Bodies with a reusable distinction: **the rule that changes a state, the rule that selects a surface, and the control that binds those decisions are separate things you can inspect and alter.** A body can be driven, constrained, sampled or reconstructed. Being able to name the operation lets you decide what to carry forward.

<!-- @ -->
'''
(M/'tutorial.md').write_bytes((intro+block('recipe.gd')+end+block('point_body.gd')+tail).encode())
final='''# Who connected the controls?

<!-- @entropy_morphogenesis -->

Choose an opening in the pale surface. You can see the room through it. Touch S and the opening changes: an edge advances, a neck draws in, another passage comes into view. The single control makes the transformation feel like one decision.

Read the numbers beside your hand. Several things moved together. Someone connected them before you arrived.

In the previous hall, a pattern could require continuing exchange and supply. Here the surface waits. It is reconstructed from a spatial rule when you ask it to change. Its appearance may suggest growth; the mechanism does not remember a body growing. The distinction matters because it tells us what kinds of intervention are available.

Keep the field and move the cut. A different surface appears without the values underneath becoming different. Change the frequency instead and those values change across space. The two actions can produce equally striking images. They ask different things of the system.

This is where the small paired specimens help. One keeps its recipe while the other receives your intervention. A hand can make a complicated change quickly. A comparison can slow that change enough to see what the gesture contained. Neither speed nor hesitation has to belong permanently to the interface.

The source calls its master value entropy. Here the word names a chosen path through settings. No distribution is measured to produce it. We can be drawn to the suggestion of disorder becoming form while still asking what the control actually joins. A name can open an association. It can also make an arrangement seem inevitable.

There is pleasure in leaving that arrangement. Keep the disturbance and change the cut. Keep the cut and change the spacing. Retain a result the default path passed by. An interface that lets you separate its connections makes room for intentions its author did not anticipate.

Now return to the large surface. An opening in an image is not yet a passage for your body. The mesh, its collision surface and your scale have to meet. A finer sampling may describe the boundary differently; it does not promise that the opening will admit you. You must try the relation at the scale where it matters.

Across these rooms, the point has joined a yielding body, held a boundary, moved with a support and helped keep a moment as a sculpture. A surface could seem alive because it turned. A pattern could persist because exchanges continued. Here a control gathered several choices into one movement of your hand.

We leave with those differences still available. The next body need not begin from nothing. We can carry a point, a relation, a saved shape or a rule—and ask which part we are willing to let change.

<!-- @ -->
'''
(M/'final.md').write_bytes(final.encode())
print(S)
