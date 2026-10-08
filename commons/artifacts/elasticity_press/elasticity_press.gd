extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ElasticityPress

## @identity
## name: "Strain, pressure & elasticity"
## tier: applied
## lineage: Hooke's spring as a stored-energy bank — squeeze it and the work you do is held
##   as strain energy (½kx²); release and it pays back, springing to its rest shape.
## essence: A press, ~1m, with a plate descending onto a soft jelly block. As the plate
##   compresses the block, a strain-energy readout climbs — energy is being banked in the
##   springs. At the bottom the plate lifts, the block springs back, and the readout falls
##   to zero. Elasticity is a battery: deformation in, recovery out, nothing lost to the floor.
## truth: "SQUEEZE STORES ENERGY, RELEASE RETURNS IT — ELASTICITY IS A BATTERY"
## applications: shock absorbers, trampolines, tendons, springs — work stored and given back.

# --- STAGE-2 DNA (promoted 2026-08-12) — `platen` and `give` --------------------
#
# Two axes, and they are the two halves of one negotiation.
#
# `platen` is the TOOL. What shipped applied its load through a single hard-coded
# assumption — a ceiling over EVERY particle without exception, i.e. an infinitely wide
# flat platen. That is a claim about the press nobody had argued: that the load arrives
# everywhere at once. `plate` keeps it, character for character. `punch`, `wedge` and
# `ring` make the ceiling a function of WHERE a particle stands, and the tool mesh
# changes with it, so the picture shows the instrument as well as its mark. Hooke's law
# is identical in all four. The resting solid is different in all four — which is this
# sequence's line, form is not imposed but emerges from the material's own dynamics,
# compressed into one bench. The platen constrains; the springs decide.
#
# `give` is the MATERIAL. `stiffness` was already a float clamped to [0.4, 0.97] with no
# vocabulary attached to it. gel/jelly/rubber/resin name how far the SAME squeeze
# propagates: a gel absorbs it in the top layer and keeps its waist, a resin carries it
# to the floor and barrels. Not `flesh` (soft_mushroom: tissue quality at rest, and it
# moves stiffness, damping and pressure together), not `substance` (breathing_room: what
# a slab is made of, an appearance axis), not `temper` (spring_hopper: spring gauge in a
# mechanism). One mechanical property under a named load.
#
# DECLINED — `press_period`, and it is the most tempting export in the file because it is
# the one thing the artifact obviously DOES. At a fixed 1.45 s shutter a 2 s period and an
# 8 s period put the plate at completely different heights, so the sweep would return four
# confidently different pictures and a strong bite number that is a fact about the frame
# clock and nothing about the material. It would have passed every gate. Also declined:
# `damping` (pure decay — invisible once the thing is at rest) and `travel` (a scale on one
# axis that the union-AABB camera partly divides back out, and the same claim as `give`
# read from the tool's side).
#
# DETERMINISM — as shipped this artifact has no resting state at all. The pose is
# fmod(_t, press_period) off the wall clock, so the shutter catches whatever phase it
# happened to reach and two runs of one value are two different pictures. `held_phase`
# replaces the cycle with a constant, `settle_steps` runs the block far past the point
# where the UNLOADED drop converges, and `block_cells` raises the lattice to a density
# whose surface can take a mark.
#
# AND THAT WAS STILL NOT ENOUGH, which is the finding of this pass. A held plate does not
# imply a still block. Ported to Python and measured, three of the four platen values
# never stop moving under the held load — punch worst, at 9.8e-2 m of travel for its
# worst particle per shutter window, unchanged after 5,000 loaded steps. It is a limit
# cycle the clamp itself drives, not a transient waiting to decay, so no settle count
# reaches it. `frozen` is therefore the load-bearing member of this fixture: it stops the
# per-frame step entirely and makes the pose a pure function of settle_steps. All four
# exports are exact no-ops at their defaults. See the registry's dna.fixture.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

const PLATENS: Array = ["plate", "punch", "wedge", "ring"]
const GIVES: Array = ["gel", "jelly", "rubber", "resin"]
## `jelly` is deliberately ABSENT from this table. It is the short-circuit: it returns the
## `stiffness` export itself rather than a copy of its literal, so the shipped 0.85 stays
## the single source of that number and a map that sets stiffness by hand keeps working.
const GIVE_STIFFNESS: Dictionary = {"gel": 0.45, "rubber": 0.93, "resin": 0.97}
## `_rng` is inherited from embodied_prop.gd and read NOWHERE in this file. The shipped
## `_rng.randomize()` therefore bought nothing and cost the only guarantee that matters
## here — that two runs of one value are one picture. A constant, not randi().
const RNG_SEED: int = 20260812

@export_enum("plate", "punch", "wedge", "ring") var platen: String = "plate"
@export_enum("gel", "jelly", "rubber", "resin") var give: String = "jelly"

@export var block_size: float = 0.5
@export var stiffness: float = 0.85
@export var press_period: float = 4.0
@export var block_col: Color = Color(0.95, 0.55, 0.40)
@export var plate_col: Color = Color(0.55, 0.58, 0.64)
@export var frame_col: Color = Color(0.20, 0.21, 0.25)
@export var readout_col: Color = Color(0.98, 0.78, 0.45)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

# --- fixture exports. Each is a no-op at its default; see the registry's dna.fixture.
## Below 0.0 the plate runs its cycle exactly as shipped. At or above 0.0 the cycle is
## replaced by this constant phase everywhere it is read, so the plate is HELD and the
## wall clock selects nothing.
@export var held_phase: float = -1.0
## Pre-settle steps. 30 is the shipped literal.
@export var settle_steps: int = 30
## Particles per block edge. 3 is the shipped literal; cell is derived so the block's
## EXTENT is block_size at any count.
@export var block_cells: int = 3
## Stop stepping the material once _make_sim() has settled it.
##
## THIS IS THE ONE THAT MAKES THE MEASUREMENT REAL, and it was added because the
## arithmetic said the rest of the fixture was not enough. A held plate does not imply a
## still block: under a NARROW tool this material never stops moving. Measured on a port
## of soft_body_sim to Python, the worst particle still travels 9.8e-2 m per 87-frame
## shutter window at platen = punch, and it is 9.8e-2 m after 5,000 loaded steps just as
## it is after 260 — a sustained limit cycle, not a decaying transient. The clamp moves a
## particle's position without touching prev_position (unlike the sim's own floor
## collision, which sets both), so every step it fires it injects velocity, and under a
## punch the surrounding material drags the clamped column back above the ceiling every
## step so it fires forever. plate settles to 1.3e-5 m; punch, ring and wedge do not.
##
## That would be survivable if the shutter counted frames. It does not:
## capture_config_sweep waits `await create_timer(SETTLE).timeout`, a WALL-CLOCK 1.1 s,
## while _process steps the sim once per rendered frame. So the number of steps taken
## before the picture is a fact about the achieved frame rate, and on a limit cycle two
## runs of one value are two different pictures — the exact failure this artifact's
## `press_period` was declined for, arriving by the back door.
##
## Frozen, the pose is the state after exactly settle_steps deterministic steps and no
## clock, delta or frame count enters it at all. Default false: _process runs as shipped.
@export var frozen: bool = false

var _t: float = 0.0
var _sim = null
var _block_node: Node3D = null
var _spheres_mm: MultiMesh = null
var _plate: Node3D = null
var _readout: Label3D = null
var _block_top0: float = 0.0
var _plate_x: float = 0.0
var _stiff: float = 0.85
var _owned: Array[Node] = []
var _sig: String = ""


func _ready() -> void:
	_rng.seed = RNG_SEED
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("block_size"):
		block_size = clampf(float(config["block_size"]), 0.3, 0.8)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.4, 0.97)
	if config.has("press_period"):
		press_period = clampf(float(config["press_period"]), 2.0, 8.0)
	if config.has("block_col"):
		block_col = _parse_color(config["block_col"], block_col)
	if config.has("platen"):
		platen = _pick(config["platen"], PLATENS, platen)
	if config.has("give"):
		give = _pick(config["give"], GIVES, give)
	if config.has("held_phase"):
		held_phase = clampf(float(config["held_phase"]), -1.0, 1.0)
	if config.has("settle_steps"):
		settle_steps = clampi(int(config["settle_steps"]), 1, 2000)
	if config.has("block_cells"):
		block_cells = clampi(int(config["block_cells"]), 2, 9)
	if config.has("frozen"):
		frozen = bool(config["frozen"])
	# REBUILD GUARD. The shipped version tore the artifact down on every call, whatever
	# arrived — including a call that changed nothing. Compare a signature of every value
	# the build actually reads and return before touching a live simulation otherwise.
	# `press_period` is deliberately not in it. _build() does reach it, through
	# _press_amount() — but only ever at _t == 0, where fmod(0.0, anything) is 0.0, or
	# under a held_phase that overrides the cycle outright. It therefore cannot change what
	# gets built, and a period-only change takes effect on the next frame without
	# restarting the material.
	if _signature() == _sig and not _owned.is_empty():
		return
	_teardown()
	_build()


func _signature() -> String:
	return "%s|%s|%.5f|%.5f|%.5f|%d|%d|%s|%s|%s" % [
		platen, give, block_size, stiffness, held_phase,
		maxi(1, settle_steps), maxi(2, block_cells),
		"1" if frozen else "0",
		"1" if emissive else "0", str(block_col),
	]


func _pick(value: Variant, allowed: Array, fallback: String) -> String:
	var s: String = String(value).strip_edges().to_lower()
	return s if allowed.has(s) else fallback


func _own(n: Node) -> Node:
	add_child(n)
	_owned.append(n)
	return n


func _teardown() -> void:
	# ONLY the nodes this script created. The shipped version walked get_children() and
	# freed everything it found, which takes a plinth, a highlight, or anything else a
	# host has parented here down with it.
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_sim = null
	_block_node = null
	_spheres_mm = null
	_plate = null
	_readout = null


## The material's half of the negotiation. jelly short-circuits to the `stiffness` export,
## so the default is bit-identical by construction and not by arithmetic that lands near it.
func _stiffness() -> float:
	if give == "jelly" or not GIVE_STIFFNESS.has(give):
		return stiffness
	return float(GIVE_STIFFNESS[give])


## Where the tool TOUCHES. The shipped press answered "everywhere" without ever saying so.
func _under_platen(p: Vector3) -> bool:
	match platen:
		"punch":
			return Vector2(p.x, p.z).length() <= block_size * 0.22
		"wedge":
			return absf(p.z) <= block_size * 0.10
		"ring":
			return Vector2(p.x, p.z).length() >= block_size * 0.30
	return true


## The clamp, masked. At platen == "plate" the mask short-circuits and what runs is the
## shipped loop character for character: every particle above the ceiling, pinned to it.
func _press_ceiling(ceil_y: float) -> void:
	var everywhere: bool = platen == "plate"
	for i in _sim.positions.size():
		if _sim.positions[i].y > ceil_y and (everywhere or _under_platen(_sim.positions[i])):
			_sim.positions[i].y = ceil_y


func _press_amount() -> float:
	var phase: float = fmod(_t, press_period) / press_period
	if held_phase >= 0.0:
		phase = clampf(held_phase, 0.0, 1.0)
	var press_amt: float = 0.0
	if phase < 0.5:
		press_amt = (phase / 0.5)                  # 0 -> 1 squeeze
	else:
		press_amt = (1.0 - (phase - 0.5) / 0.5)    # 1 -> 0 release
	# Ease for a soft mechanical feel.
	return press_amt * press_amt * (3.0 - 2.0 * press_amt)


func _plate_local_y(press_amt: float) -> float:
	var travel: float = block_size * 0.45
	return _block_top0 + 0.05 - press_amt * travel


func _make_sim() -> void:
	# cell is derived so the block's EXTENT stays block_size at any count. At the shipped
	# block_cells = 3 this is block_size / 2.0 — bit-identical to the literal
	# `block_size * 0.5` it replaces, both being exact in binary.
	var cells: int = maxi(2, block_cells)
	var cell: float = block_size / float(cells - 1)
	var steps: int = maxi(1, settle_steps)
	var sim = SBShapes.make_jelly_grid(cells, cells, cells, cell, _stiff)
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -2.0, 0.0)
	sim.damping = 0.9
	_sim = sim
	for _i in steps:
		_sim.step()
	# Remember the resting top so we can measure compression later.
	_block_top0 = _block_top()
	if held_phase >= 0.0:
		# THE POSE IS PINNED, SO IT MUST ARRIVE ALREADY LOADED. Settling unloaded and
		# letting _process squeeze from frame 1 photographs the squeeze happening, which
		# is a transient, not a measurement. Same masked ceiling as the frame loop, run
		# to its fixed point before anything is rendered, and ending on a step() so the
		# state matches what a frame renders.
		var held_ceiling: float = _plate_local_y(_press_amount()) - 0.02
		for _i in steps:
			_press_ceiling(held_ceiling)
			_sim.step()


## Highest particle. `mask_to_platen` asks the same question of the surface the TOOL
## actually touches — at platen == "plate" the mask is everything and the loop is the
## shipped one exactly.
func _block_top(mask_to_platen: bool = false) -> float:
	var masked: bool = mask_to_platen and platen != "plate"
	var top: float = -INF
	for i in _sim.positions.size():
		if masked and not _under_platen(_sim.positions[i]):
			continue
		top = maxf(top, _sim.positions[i].y)
	return top


## One solid, 0.05 thick, whose horizontal footprint IS the mask above. The tool is the
## mask: nothing in the picture asks the reader to take that on trust.
func _make_platen(world_y: float) -> Node3D:
	var mat: StandardMaterial3D = _steel_mat(plate_col)
	match platen:
		"punch":
			return _cylinder(Vector3(0.0, world_y, 0.0), block_size * 0.22, 0.05, mat)
		"wedge":
			return _box(Vector3(0.0, world_y, 0.0),
				Vector3(block_size + 0.18, 0.05, block_size * 0.20), mat)
		"ring":
			var r_in: float = block_size * 0.30
			var r_out: float = (block_size + 0.18) * 0.5
			var tube: float = (r_out - r_in) * 0.5
			var ring: MeshInstance3D = _torus(Vector3(0.0, world_y, 0.0),
				(r_in + r_out) * 0.5, tube, mat)
			# A torus is round in section and would stand 2 x tube tall. Flatten it to the
			# same 0.05 every other value has, so all four tools meet the block at the same
			# height and the axis is about WHERE they touch, not how thick they are.
			ring.scale = Vector3(1.0, 0.05 / maxf(tube * 2.0, 0.001), 1.0)
			return ring
	return _box(Vector3(0.0, world_y, 0.0),
		Vector3(block_size + 0.18, 0.05, block_size + 0.18), mat)


func _build() -> void:
	_stiff = _stiffness()

	# Press frame: base, two posts, top beam (the applied device)
	_own(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.9, 0.08, 0.7), _matte_mat(frame_col, 0.8)))
	_own(_cylinder_between(Vector3(-0.38, 0.08, -0.0), Vector3(-0.38, 1.05, 0.0), 0.035, _steel_mat(Color(0.4, 0.42, 0.46))))
	_own(_cylinder_between(Vector3(0.38, 0.08, 0.0), Vector3(0.38, 1.05, 0.0), 0.035, _steel_mat(Color(0.4, 0.42, 0.46))))
	_own(_box(Vector3(0.0, 1.08, 0.0), Vector3(0.86, 0.08, 0.3), _matte_mat(frame_col, 0.8)))

	_make_sim()

	# Soft block as a live MultiMesh of particle spheres (no per-frame geometry rebuild).
	_block_node = Node3D.new()
	_block_node.position = Vector3(0.0, 0.08, 0.0)
	_own(_block_node)

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = block_size * 0.16
	sm.height = block_size * 0.32
	mm.mesh = sm
	mm.instance_count = _sim.positions.size()
	_spheres_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = block_col
	bmat.roughness = 0.45
	bmat.emission_enabled = true
	bmat.emission = block_col
	bmat.emission_energy_multiplier = 0.3 if emissive else 0.0
	mmi.material_override = bmat
	_block_node.add_child(mmi)
	_refresh_block()

	# The descending platen. At a held phase it is placed where it is HELD, so frame 0 is
	# already the loaded pose; at the shipped default press_amt is 0 and this is the
	# literal `_block_top0 + 0.05` it replaces.
	_plate = _make_platen(0.08 + _plate_local_y(_press_amount()))
	_own(_plate)

	# Readout panel
	_own(_box(Vector3(0.52, 0.6, 0.2), Vector3(0.34, 0.2, 0.02), _matte_mat(Color(0.10, 0.11, 0.14), 0.4)))
	# FROZEN means _process never runs, so the readout has to be right HERE or the picture
	# prints 0.000 J across a visibly squeezed block — a caption contradicting its own
	# photograph. At the default this is the shipped literal _readout_text(0.0).
	var u0: float = _energy() if frozen else 0.0
	_readout = _billboard_label(_readout_text(u0), Vector3(0.52, 0.6, 0.22), 16, readout_col)
	_own(_readout)

	_own(_billboard_label("SQUEEZE STORES ENERGY, RELEASE RETURNS IT", Vector3(0.0, 1.5, 0.0), 20, label_col))

	_sig = _signature()


func _refresh_block() -> void:
	if _spheres_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_spheres_mm.set_instance_transform(i, t)


func _readout_text(energy: float) -> String:
	return "STRAIN ENERGY\nU = %.3f J\n(banked in the springs)" % energy


## Strain energy ~ how far the block is compressed from rest (½ k x²). Measured on the
## surface the tool touches, so a punch that has driven 20 cm into the middle does not read
## zero because an untouched corner is still at its rest height.
func _energy() -> float:
	var compression: float = maxf(_block_top0 - _block_top(true), 0.0)
	return 0.5 * (_stiff * 60.0) * compression * compression


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# THE POSE IS THE DELIVERABLE, AND A FRAME IS NOT A UNIT OF TIME. Everything below
	# advances the material once per rendered frame, so under a wall-clock shutter the
	# number of steps taken before the picture is a fact about the frame rate. That is
	# harmless only while the material is at a fixed point, and under a narrow platen it
	# never reaches one. Frozen, _make_sim() has already produced the whole pose from a
	# fixed step count and nothing here may touch it. See the `frozen` export.
	if frozen:
		return
	_t += delta
	if _sim == null:
		return

	# Plate cycles down (compress) then up (release) — unless held_phase pins the phase,
	# in which case this returns the same constant every frame and _t selects nothing.
	var press_amt: float = _press_amount()
	var plate_y_local: float = _plate_local_y(press_amt)
	if _plate != null:
		_plate.position.y = 0.08 + plate_y_local

	# Push the particles the TOOL covers down to follow it; let the springs distribute the
	# squeeze. That distribution is the whole argument, and it is what `platen` moves.
	_press_ceiling(plate_y_local - 0.02)
	_sim.step()
	_refresh_block()

	if _readout != null:
		_readout.text = _readout_text(_energy())
