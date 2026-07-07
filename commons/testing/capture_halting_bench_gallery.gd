## One-off sweep capture for the halting-bench DNA gallery.
##
## Simulates 8 Turing machines for their step budgets, captures the final tape
## state (head position, state, step counter, halt/running banner, rules table)
## as a clean 2D-ish scientific plot, and saves <id>.png + <id>.json pairs.
##
## The mathematical claim — there exist machines that halt and machines that
## don't, and no algorithm can decide, in general, which is which (halting
## problem; Turing 1936). The Busy Beaver function Σ(n) — the maximum steps a
## halting n-state machine runs before stopping — is uncomputable for n ≥ 6.
## Σ(2) = 6, Σ(3) = 14, Σ(4) = 107, Σ(5) ≥ 47,176,870.
##
## The 8 cells:
##   1. bb2_busy_beaver       — 2-state busy beaver, halts at step 6 (writes 4 ones)
##   2. bb3_busy_beaver       — 3-state busy beaver, halts at step 14 (writes 6 ones)
##   3. shift_right_forever   — 1 state, writes 1 moves right, never halts
##   4. bouncer               — 2-state bouncer, cycles, never halts
##   5. deceptive_halter      — looks like it might halt, but doesn't, within budget
##   6. long_halter           — halts after many steps (~107)
##   7. bb4_busy_beaver       — 4-state busy beaver, halts at step 107 (writes 13 ones)
##   8. unknown_at_budget     — runs for 1000 steps with no apparent halt
##
## Visual goals (matching parametric-mesh-gallery / riemann-sum-gallery):
##   - Square 1024×1024 SubViewport, MSAA 8x + FXAA, isolated World3D
##   - Orthographic camera looking head-on at the tape
##   - Tape: ~30 cells centered on the head, white squares for 0s, colored
##     squares for 1s (green for halted, red-orange for running)
##   - Read/write head: triangle pointing UP at the current tape cell
##   - State indicator: large Label3D in top-left
##   - Step counter: top-right
##   - Rules table: bottom panel, fixed-width monospace text
##   - Halt banner: top-center, GREEN "HALTED" / RED "STILL RUNNING…"
##
## BB rule sources (canonical published tables):
##   BB(2): Rado 1962, the original busy-beaver paper
##   BB(3): Rado/Lin 1965
##   BB(4): Brady 1983 (champion: 107 steps, 13 ones)
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_halting_bench_gallery.gd \
##     -- --out=user://halting_bench_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Camera framing for the 2D-ish plot. Orthographic, looking down +Z at XY plane.
const ORTHO_SIZE: float = 4.0

# Tape rendering. We always show TAPE_VISIBLE cells centered on the head.
const TAPE_VISIBLE: int = 31         # odd → exact center cell exists
const CELL_SIZE: float = 0.18        # world units per tape cell side
const CELL_GAP: float = 0.02         # small visual gap between cells
const TAPE_Y: float = -0.4           # vertical position of the tape strip

# Color palette
const TAPE_EMPTY: Color = Color(0.94, 0.94, 0.96)       # white-ish for 0
const TAPE_BORDER: Color = Color(0.18, 0.20, 0.26)      # cell outline
const ONE_HALTED: Color = Color(0.42, 0.86, 0.50)       # bright green for 1 when halted
const ONE_RUNNING: Color = Color(0.96, 0.58, 0.32)      # muted orange for 1 when running
const HEAD_COLOR: Color = Color(0.98, 0.82, 0.28)       # amber arrow
const HALT_BANNER: Color = Color(0.40, 0.85, 0.50)
const RUN_BANNER: Color = Color(0.92, 0.40, 0.42)
const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.62, 0.66, 0.74)
const PANEL_BG: Color = Color(0.10, 0.12, 0.17, 0.85)

var _output_dir: String = "user://halting_bench_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── Viewport setup ──────────────────────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# Cosmetic light (unshaded materials don't need it but keeps the env happy).
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.6
	_viewport.add_child(key_light)

	# Orthographic camera looking down +Z at origin.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ORTHO_SIZE
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep over the 8 machines ───────────────────────────────────
	var machines := _build_machine_specs()
	for spec in machines:
		var result: Dictionary = _simulate(spec)
		_build_scene(spec, result)
		await create_timer(0.05).timeout
		await _capture_and_record(spec["id"], spec, result)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Eight Turing machines, each shown at its tape's final visible state after a step budget. Some halt (Busy Beaver Σ(2)=6, Σ(3)=14, Σ(4)=107); some never do (shift-right, bouncer, deceptive-halter). The undecidable cell shows a machine that has run for 1000 steps with no observable halt — we cannot, in general, prove from the rules alone whether it ever will. The halting problem (Turing 1936) made literal: you can SEE which halted, but you cannot, in general, PREDICT halting from the transition table.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"bb_references": {
			"bb2": "Rado 1962 — Σ(2) = 6 steps, 4 ones",
			"bb3": "Rado/Lin 1965 — Σ(3) = 14 steps, 6 ones",
			"bb4": "Brady 1983 — Σ(4) = 107 steps, 13 ones",
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Machine specifications ───────────────────────────────────────────
# Each spec: {
#   "id": string,
#   "name": string,
#   "rules": Dictionary { "state|read_symbol": [write_symbol, move, next_state] },
#   "halt_state": "H",
#   "step_budget": int,
#   "expected_halt": bool,
#   "notes": String,
# }
#
# Rules-table key format: "STATE|READ" → [WRITE, MOVE, NEXT_STATE]
# MOVE: -1 = left, +1 = right
# Initial state always "A" unless noted.
func _build_machine_specs() -> Array:
	var machines: Array = []

	# 1. BB(2) — canonical 2-state busy beaver (Rado 1962).
	#    A,0 → 1,R,B    A,1 → 1,L,B
	#    B,0 → 1,L,A    B,1 → 1,R,H
	#    Halts at step 6 with 4 ones on the tape.
	machines.append({
		"id": "1_bb2_busy_beaver",
		"name": "BB(2) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "H"],
		},
		"halt_state": "H",
		"step_budget": 10,
		"expected_halt": true,
		"category": "halts",
		"notes": "The smallest interesting halter. Σ(2) = 6 steps, 4 ones — Rado 1962.",
	})

	# 2. BB(3) — 3-state busy beaver (Rado/Lin 1965).
	#    A,0 → 1,R,B    A,1 → 1,R,H
	#    B,0 → 0,R,C    B,1 → 1,R,B
	#    C,0 → 1,L,C    C,1 → 1,L,A
	#    Halts at step 14 with 6 ones.
	machines.append({
		"id": "2_bb3_busy_beaver",
		"name": "BB(3) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", 1, "H"],
			"B|0": ["0", 1, "C"],
			"B|1": ["1", 1, "B"],
			"C|0": ["1", -1, "C"],
			"C|1": ["1", -1, "A"],
		},
		"halt_state": "H",
		"step_budget": 20,
		"expected_halt": true,
		"category": "halts",
		"notes": "Σ(3) = 14 steps, 6 ones — Rado/Lin 1965. The 3-state champion runs more than double Σ(2).",
	})

	# 3. shift_right_forever — 1 state, writes 1 and moves right. Never halts.
	machines.append({
		"id": "3_shift_right_forever",
		"name": "Shift-right forever",
		"rules": {
			"A|0": ["1", 1, "A"],
			"A|1": ["1", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 30,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "Obviously non-halting — 1 state, always writes 1, always moves right. The trivial counter-example.",
	})

	# 4. bouncer — 2-state, ping-pongs left and right indefinitely on a small region.
	#    A,0 → 1,R,B    A,1 → 0,L,A
	#    B,0 → 1,L,A    B,1 → 0,R,B
	#    On a blank tape this enters a stable oscillation rather than halting.
	machines.append({
		"id": "4_bouncer",
		"name": "Bouncer",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["0", -1, "A"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", 1, "B"],
		},
		"halt_state": "H",
		"step_budget": 50,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "Two states ping-ponging — falls into a recognisable cycle after a few steps. The tape grows but never halts.",
	})

	# 5. deceptive_halter — looks plausible. 3 states, writes 1s in a complex
	#    pattern, never halts within 200 steps. The point: from the rules table
	#    you cannot tell that this won't halt — it just walks the tape forever.
	#    A,0 → 1,R,B    A,1 → 1,L,C
	#    B,0 → 1,L,A    B,1 → 1,R,B
	#    C,0 → 0,R,A    C,1 → 1,L,C
	machines.append({
		"id": "5_deceptive_halter",
		"name": "Deceptive halter",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "C"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "B"],
			"C|0": ["0", 1, "A"],
			"C|1": ["1", -1, "C"],
		},
		"halt_state": "H",
		"step_budget": 200,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "From the rules alone you cannot tell — it writes, erases, bounces back. Runs the full budget without entering its halt state.",
	})

	# 6. long_halter — halts after ~107 steps. We use BB(4)'s structure but as
	#    a separate cell to read "this is just a long halter" before the cell
	#    labelled BB(4). It's literally the same machine for the demo's purpose
	#    of contrast.
	#    A,0 → 1,R,B    A,1 → 1,L,B
	#    B,0 → 1,L,A    B,1 → 0,L,C
	#    C,0 → 1,R,H    C,1 → 1,L,D
	#    D,0 → 1,R,D    D,1 → 0,R,A
	#    Brady's BB(4): 107 steps, 13 ones.
	machines.append({
		"id": "6_long_halter",
		"name": "Long halter (~107 steps)",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", -1, "C"],
			"C|0": ["1", 1, "H"],
			"C|1": ["1", -1, "D"],
			"D|0": ["1", 1, "D"],
			"D|1": ["0", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 200,
		"expected_halt": true,
		"category": "halts",
		"notes": "Mid-busy-beaver behaviour: runs for over 100 steps before stopping. The rules look no more complex than the shift-right machine, but the trajectory is.",
	})

	# 7. BB(4) — Brady's 4-state busy beaver (1983).
	#    Same machine as #6, labelled explicitly as Σ(4).
	machines.append({
		"id": "7_bb4_busy_beaver",
		"name": "BB(4) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", -1, "C"],
			"C|0": ["1", 1, "H"],
			"C|1": ["1", -1, "D"],
			"D|0": ["1", 1, "D"],
			"D|1": ["0", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 150,
		"expected_halt": true,
		"category": "halts",
		"notes": "Σ(4) = 107 steps, 13 ones — Brady 1983. The 4-state champion is nearly 8× longer than Σ(3).",
	})

	# 8. unknown_at_budget — runs for 1000 steps with no apparent halt. We pick
	#    a machine that walks the tape in a complex pattern. From the player's
	#    perspective at the 1000-step snapshot, we cannot say whether it will
	#    halt at step 1001 or never — that's the undecidability.
	#    A,0 → 1,R,B    A,1 → 0,L,C
	#    B,0 → 1,L,A    B,1 → 1,R,D
	#    C,0 → 1,R,D    C,1 → 0,L,B
	#    D,0 → 1,L,C    D,1 → 1,R,A
	machines.append({
		"id": "8_unknown_at_budget",
		"name": "Unknown — undecidable case",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["0", -1, "C"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "D"],
			"C|0": ["1", 1, "D"],
			"C|1": ["0", -1, "B"],
			"D|0": ["1", -1, "C"],
			"D|1": ["1", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 1000,
		"expected_halt": false,
		"category": "unknown",
		"notes": "1000 steps in, this machine shows no sign of halting. But we cannot prove it never will — that is the halting problem (Turing 1936). For some (machine, input) pairs, the question is undecidable.",
	})

	return machines


# ─── Simulator ───────────────────────────────────────────────────────
# Run the machine for at most step_budget steps. Returns:
# {
#   "tape": Dictionary { int position : "0"/"1" },
#   "head": int,
#   "state": String,        # final state ("H" if halted)
#   "halted": bool,
#   "steps": int,           # actual step count
#   "ones_written": int,    # count of "1"s on the tape at the end
# }
func _simulate(spec: Dictionary) -> Dictionary:
	var tape: Dictionary = {}    # int position → "0" or "1"
	var head: int = 0
	var state: String = "A"
	var halt_state: String = spec["halt_state"]
	var rules: Dictionary = spec["rules"]
	var budget: int = spec["step_budget"]
	var steps: int = 0

	for i in range(budget):
		if state == halt_state:
			break
		var read_symbol: String = "0"
		if tape.has(head):
			read_symbol = tape[head]
		var key: String = "%s|%s" % [state, read_symbol]
		if not rules.has(key):
			# Undefined transition → halt by convention (some BB conventions do this).
			state = halt_state
			break
		var rule: Array = rules[key]
		tape[head] = String(rule[0])
		head += int(rule[1])
		state = String(rule[2])
		steps += 1

	var ones: int = 0
	for k in tape.keys():
		if tape[k] == "1":
			ones += 1

	return {
		"tape": tape,
		"head": head,
		"state": state,
		"halted": (state == halt_state),
		"steps": steps,
		"ones_written": ones,
	}


# ─── Scene construction ───────────────────────────────────────────────
func _build_scene(spec: Dictionary, result: Dictionary) -> void:
	var halted: bool = result["halted"]
	var one_color: Color = ONE_HALTED if halted else ONE_RUNNING

	_add_tape(result["tape"], result["head"], one_color)
	_add_head_indicator(result["head"])
	_add_state_label(result["state"], halted)
	_add_step_counter(result["steps"], spec["step_budget"], halted)
	_add_halt_banner(halted, spec)
	_add_rules_panel(spec["rules"])
	_add_machine_name(spec["name"])
	_add_ones_counter(result["ones_written"], halted)


# ─── Tape drawing ─────────────────────────────────────────────────────
# Draw TAPE_VISIBLE cells centered on the current head position.
# Each cell is a small filled square with a black border.
# 1-cells are colored (green if halted, orange if running).
func _add_tape(tape: Dictionary, head: int, one_color: Color) -> void:
	var cells_each_side: int = TAPE_VISIBLE / 2
	var pitch: float = CELL_SIZE + CELL_GAP

	# Fill quads for cells.
	var im_fill := ImmediateMesh.new()
	# We'll do two passes — one for empty cells (white), one for filled cells (colored).
	# Actually it's cleaner to do per-cell calls; use ONE surface with vertex coloring
	# via per-vertex color in the primitive. To keep this simple we do two surfaces.

	# Empty cells (white)
	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(TAPE_EMPTY))
	for offset in range(-cells_each_side, cells_each_side + 1):
		var pos: int = head + offset
		var symbol: String = tape.get(pos, "0")
		if symbol != "0":
			continue
		var x: float = float(offset) * pitch
		var y: float = TAPE_Y
		var half: float = CELL_SIZE * 0.5
		_quad(im_fill, Vector3(x - half, y - half, 0.0),
			Vector3(x + half, y - half, 0.0),
			Vector3(x + half, y + half, 0.0),
			Vector3(x - half, y + half, 0.0))
	im_fill.surface_end()

	# Filled cells (1s in the run color).
	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(one_color))
	for offset in range(-cells_each_side, cells_each_side + 1):
		var pos: int = head + offset
		var symbol: String = tape.get(pos, "0")
		if symbol != "1":
			continue
		var x: float = float(offset) * pitch
		var y: float = TAPE_Y
		var half: float = CELL_SIZE * 0.5
		_quad(im_fill, Vector3(x - half, y - half, 0.01),
			Vector3(x + half, y - half, 0.01),
			Vector3(x + half, y + half, 0.01),
			Vector3(x - half, y + half, 0.01))
	im_fill.surface_end()

	# Cell borders (one surface, all cells)
	im_fill.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(TAPE_BORDER))
	for offset in range(-cells_each_side, cells_each_side + 1):
		var x: float = float(offset) * pitch
		var y: float = TAPE_Y
		var half: float = CELL_SIZE * 0.5
		var bl := Vector3(x - half, y - half, 0.02)
		var br := Vector3(x + half, y - half, 0.02)
		var tr := Vector3(x + half, y + half, 0.02)
		var tl := Vector3(x - half, y + half, 0.02)
		im_fill.surface_add_vertex(bl); im_fill.surface_add_vertex(br)
		im_fill.surface_add_vertex(br); im_fill.surface_add_vertex(tr)
		im_fill.surface_add_vertex(tr); im_fill.surface_add_vertex(tl)
		im_fill.surface_add_vertex(tl); im_fill.surface_add_vertex(bl)
	im_fill.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im_fill
	mi.name = "Tape"
	_scene_holder.add_child(mi)


func _quad(im: ImmediateMesh, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3) -> void:
	im.surface_add_vertex(bl)
	im.surface_add_vertex(br)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(tl)


# ─── Head indicator ───────────────────────────────────────────────────
# Triangle pointing UP at the current tape cell (head is the center cell).
func _add_head_indicator(_head: int) -> void:
	# The head is always at the center cell in the rendering (we render
	# centered on head), so the indicator sits at x=0 below the tape.
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(HEAD_COLOR))
	var tip_y: float = TAPE_Y - CELL_SIZE * 0.55
	var base_y: float = tip_y - 0.18
	var half_w: float = 0.12
	im.surface_add_vertex(Vector3(0.0, tip_y, 0.03))
	im.surface_add_vertex(Vector3(-half_w, base_y, 0.03))
	im.surface_add_vertex(Vector3(half_w, base_y, 0.03))
	im.surface_end()

	# Small "head" label below.
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "Head"
	_scene_holder.add_child(mi)

	var lab := Label3D.new()
	lab.text = "head"
	lab.font_size = 36
	lab.outline_size = 6
	lab.modulate = HEAD_COLOR
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, base_y - 0.08, 0.03)
	_scene_holder.add_child(lab)


# ─── State indicator (top-left) ───────────────────────────────────────
func _add_state_label(state: String, halted: bool) -> void:
	var state_text: String = "STATE " + state
	if halted:
		state_text = "HALT"

	var lab := Label3D.new()
	lab.text = state_text
	lab.font_size = 72
	lab.outline_size = 12
	lab.modulate = TEXT_BRIGHT if not halted else HALT_BANNER
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(-1.85, 1.55, 0.02)
	_scene_holder.add_child(lab)


# ─── Step counter (top-right) ─────────────────────────────────────────
func _add_step_counter(steps: int, budget: int, halted: bool) -> void:
	var text: String = "step %d/%d" % [steps, budget]
	if halted:
		text = "halted at %d" % steps

	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 56
	lab.outline_size = 10
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lab.position = Vector3(1.85, 1.55, 0.02)
	_scene_holder.add_child(lab)


# ─── Halt banner (top-center) ─────────────────────────────────────────
func _add_halt_banner(halted: bool, spec: Dictionary) -> void:
	# Background box
	var im := ImmediateMesh.new()
	var bg_color: Color = HALT_BANNER if halted else RUN_BANNER
	bg_color.a = 0.85
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(bg_color))
	var x_half: float = 0.85
	var y_lo: float = 1.20
	var y_hi: float = 1.45
	_quad(im, Vector3(-x_half, y_lo, 0.01),
		Vector3(x_half, y_lo, 0.01),
		Vector3(x_half, y_hi, 0.01),
		Vector3(-x_half, y_hi, 0.01))
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "HaltBanner"
	_scene_holder.add_child(mi)

	# Banner text
	var banner_text: String = "HALTED" if halted else "STILL RUNNING…"
	if spec.get("category", "") == "unknown" and not halted:
		banner_text = "STATUS UNKNOWN"

	var lab := Label3D.new()
	lab.text = banner_text
	lab.font_size = 84
	lab.outline_size = 14
	lab.modulate = Color(0.04, 0.05, 0.08)
	lab.outline_modulate = Color(1.0, 1.0, 1.0, 0.4)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, (y_lo + y_hi) * 0.5, 0.02)
	_scene_holder.add_child(lab)


# ─── Rules panel (bottom) ─────────────────────────────────────────────
# A small panel listing the transition rules in the form
# "A,0 → 1,R,B"  one rule per line.
func _add_rules_panel(rules: Dictionary) -> void:
	# Panel background
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(PANEL_BG))
	var x_half: float = 1.85
	var y_lo: float = -1.85
	var y_hi: float = -0.82
	_quad(im, Vector3(-x_half, y_lo, 0.01),
		Vector3(x_half, y_lo, 0.01),
		Vector3(x_half, y_hi, 0.01),
		Vector3(-x_half, y_hi, 0.01))
	im.surface_end()
	# Panel border
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(0.35, 0.40, 0.50, 0.7)))
	var bl := Vector3(-x_half, y_lo, 0.02)
	var br := Vector3(x_half, y_lo, 0.02)
	var tr := Vector3(x_half, y_hi, 0.02)
	var tl := Vector3(-x_half, y_hi, 0.02)
	im.surface_add_vertex(bl); im.surface_add_vertex(br)
	im.surface_add_vertex(br); im.surface_add_vertex(tr)
	im.surface_add_vertex(tr); im.surface_add_vertex(tl)
	im.surface_add_vertex(tl); im.surface_add_vertex(bl)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "RulesPanel"
	_scene_holder.add_child(mi)

	# Title
	var title := Label3D.new()
	title.text = "RULES"
	title.font_size = 32
	title.outline_size = 6
	title.modulate = TEXT_DIM
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	title.shaded = false
	title.no_depth_test = true
	title.pixel_size = 0.0025
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector3(-x_half + 0.08, y_hi - 0.10, 0.03)
	_scene_holder.add_child(title)

	# Format and render rules.
	var lines: Array = _format_rules(rules)
	# Layout in up to TWO COLUMNS, each column showing up to 4 rules.
	var col_count: int = 2 if lines.size() > 4 else 1
	var rows_per_col: int = int(ceil(float(lines.size()) / float(col_count)))
	var col_width: float = (x_half * 2.0 - 0.16) / float(col_count)

	for i in range(lines.size()):
		var col: int = i / rows_per_col
		var row: int = i % rows_per_col
		var rule_lab := Label3D.new()
		rule_lab.text = lines[i]
		rule_lab.font_size = 36
		rule_lab.outline_size = 6
		rule_lab.modulate = TEXT_BRIGHT
		rule_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		rule_lab.shaded = false
		rule_lab.no_depth_test = true
		rule_lab.pixel_size = 0.0025
		rule_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var x: float = -x_half + 0.10 + float(col) * col_width
		var y: float = (y_hi - 0.28) - float(row) * 0.16
		rule_lab.position = Vector3(x, y, 0.03)
		_scene_holder.add_child(rule_lab)


func _format_rules(rules: Dictionary) -> Array:
	# Sort keys for deterministic ordering: A|0, A|1, B|0, B|1, ...
	var keys: Array = rules.keys()
	keys.sort()
	var out: Array = []
	for k in keys:
		var rule: Array = rules[k]
		var parts: PackedStringArray = String(k).split("|")
		var state: String = parts[0]
		var read_sym: String = parts[1]
		var write_sym: String = String(rule[0])
		var move: String = "R" if int(rule[1]) > 0 else "L"
		var next_state: String = String(rule[2])
		out.append("%s,%s → %s,%s,%s" % [state, read_sym, write_sym, move, next_state])
	return out


# ─── Machine name label (under banner) ────────────────────────────────
func _add_machine_name(name: String) -> void:
	var lab := Label3D.new()
	lab.text = name
	lab.font_size = 48
	lab.outline_size = 8
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, 0.95, 0.02)
	_scene_holder.add_child(lab)


# ─── Ones counter (above the tape, low key) ───────────────────────────
func _add_ones_counter(ones: int, halted: bool) -> void:
	var prefix: String = "ones written: " if halted else "ones on tape: "
	var lab := Label3D.new()
	lab.text = "%s%d" % [prefix, ones]
	lab.font_size = 40
	lab.outline_size = 8
	lab.modulate = TEXT_DIM
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, -0.05, 0.02)
	_scene_holder.add_child(lab)


# ─── Materials ────────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # tri winding for our ImmediateMesh quads is CW from +Z
	return mat


func _unshaded_material_transparent(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(c.r, c.g, c.b, 1.0)
	mat.emission_energy_multiplier = 0.25
	return mat


# ─── Capture and record ──────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, spec: Dictionary, result: Dictionary) -> void:
	# Yield a few frames so the viewport renders before sampling.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar — full machine config + simulation result.
	# Convert rules dict to a serialisable form.
	var rules_out: Dictionary = {}
	for k in spec["rules"].keys():
		var r: Array = spec["rules"][k]
		rules_out[k] = {
			"write": String(r[0]),
			"move": int(r[1]),
			"next_state": String(r[2]),
		}

	# Tape compressed as a sorted list of (position, symbol).
	var tape_out: Array = []
	var positions: Array = result["tape"].keys()
	positions.sort()
	for p in positions:
		tape_out.append([int(p), String(result["tape"][p])])

	var cfg := {
		"machine_name": spec["name"],
		"id": id,
		"category": spec.get("category", ""),
		"rules": rules_out,
		"halt_state": spec["halt_state"],
		"step_budget": spec["step_budget"],
		"expected_halt": spec["expected_halt"],
		"halted": result["halted"],
		"steps_to_halt": result["steps"] if result["halted"] else null,
		"steps_run": result["steps"],
		"ones_written": result["ones_written"],
		"final_state": result["state"],
		"final_head_position": result["head"],
		"tape_at_end": tape_out,
		"notes": spec["notes"],
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(cfg, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"name": spec["name"],
		"category": spec.get("category", ""),
		"halted": result["halted"],
		"steps_to_halt": result["steps"] if result["halted"] else null,
		"steps_run": result["steps"],
		"step_budget": spec["step_budget"],
		"ones_written": result["ones_written"],
		"notes": spec["notes"],
		"image": "/halting-bench-gallery/%s" % img_rel,
		"config": "/halting-bench-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  halted=%s  steps=%d  ones=%d" % [
		id, result["halted"], result["steps"], result["ones_written"]
	])
