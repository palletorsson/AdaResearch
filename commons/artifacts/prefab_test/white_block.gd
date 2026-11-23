# WhiteBlock.gd - white wall slabs stood so close they read as one block; nothing in it stops a body
#
# @identity
# essence: a ten metre block of white wall slabs with no colliders; hidden in it, the catalogue's own prefabs - giant, sheared, grazing a slab's face, turning, repeated hundreds of times - in each other and in the slabs; a small pagoda at its face shows where to walk in
# desire: the learner finds out, by walking, that a wall in this world is a picture until something makes it solid
# critical_parameter: hidden - which way the prefabs are hidden (layered: all of them at once); side - the block's size
# triggers: none; the visitor walks through
# emerges: from outside a plain white block; one step through the wall, every step cuts every hidden thing somewhere else, and the two eyes are shown two different cuts
# relationships: the collider is a separate decision from the mesh, as [[contact_study]] THROUGH shows for two meshes; the primitives are the floor's own vocabulary ([[void_primitive_columns]], the Primitives halls)
# truth: seeing a wall and being stopped by it are two things, and only one of them was built here.
extends Node3D

## WHERE THIS COMES FROM. Palle, 22 November 2026: "In the middle have white wall slabs stuck closely together like
## one big 10 meter block without colliders. Inside block place a lot of color overlapping geometry primitives
## inside and a simple pagoda show you should enter the wall."
##
## Then, the same night, seeing the first build (a shell of slabs round an open room): "the inside should be the full
## segments no open space, so we get a glitch work between the surfaces when we walk inside."
##
## The block: wall slabs stood face to face through the whole depth of the block, each `slab` thick with a joint of
## `joint` between two, every slab made of segments `panel` wide, every other slab shifted half a segment so no
## joint runs through. There is no room in it. All of it is one MultiMesh, drawn on both sides, in two whites that
## differ a little from slab to slab, without a body: there is no collider anywhere in this work.
## Walking in, the eye is inside a slab, then in a joint, then inside the next: each face it crosses cuts the view.
## In the slabs: what `hidden` puts there (below), drawn from `seed`, so that inside a slab one sees the slice of
## every thing that crosses it; a lamp, since no daylight reaches in.
## The pagoda stands half in the south wall (+z, towards the arrival): four posts, three roofs, a carpet that runs
## under it into the block.
## Origin: the middle of the block, on the floor.
##
## WHAT IS HIDDEN IN IT (Palle, 23 November: "in the 10box can you figure out how we can place different hidden thing
## inside to get the most strange glitch effect, use prefabs"). `hidden` chooses. Each way puts the catalogue's own
## prefabs (commons/data/inventory/items.json, made inert as the belt makes its miniatures) into the slabs so that the
## slabs cut them differently:
##   giant     a few prefabs at four to six times their size: a tyre one walks through for a dozen slabs
##   coplanar  flat prefabs (board, sign, pallet) lying exactly IN a slab's face: two surfaces at one depth fight
##   lattice   one small prefab on a regular grid, hundreds of times, every other one mirrored (drawn inside out):
##             every slab shows the same rows of slices
##   turning   prefabs that turn and slide slowly: the slice in a slab changes while one stands still
##   sheared   crates and pallets with a shear and a stretch no carpenter gives them
##   scatter   prefabs at their own size, thrown in (the plain case, to compare with)
##   primitives  the first build: seventy-two coloured primitives, no prefab
##   grazing   flat prefabs leaned out of a slab's face by 1.5 to 6 degrees, rocking by less than one: the line
##             where one leaves a slab runs metres while the eye walks centimetres
##   zones     the block's depth in five bands from the pagoda inwards - giant, grazing, lattice, turning, sheared -
##             five different kinds of wrong, one after the other
##   layered   (the default) the same five ways through the whole block at once, in each other
## tools/probes/white_block_glitch.gd walks the eye through each, 4 cm a step, and measures. 23 Nov 2026, one run,
## inside the block, per step (0..1 of full scale; "eyes": two eyes 63 mm apart; "still": half a second standing):
##                jump    prefab in view   eyes     still
##   scatter      0.005   0.02             0.006    0
##   turning      0.006   0.02             0.006    0
##   zones        0.010   0.03             0.011    0.001
##   primitives   0.017   0.10             0.022    0
##   sheared      0.018   0.07             0.019    0
##   coplanar     0.023   0.08             0.018    0
##   grazing      0.024   0.08             0.025    0
##   giant        0.028   0.08             0.035    0
##   lattice      0.049   0.15             0.073    0.003
##   layered      0.086   0.25             0.123    0.007
## Layered is five times the old primitives on the jump and on what the two eyes disagree about, for 50 more draw calls
## (1406 against 1356). Prefabs at their own size, thrown in (scatter), are the least strange: small things fall
## between two slabs and are missed; a few turning things are mostly elsewhere. Zones spreads five ways over five
## bands, a few prefabs each, and is thin for it. A coplanar face fights the slab only from the side it lies on, and
## the eye is nearly always inside a slab, looking at that slab's inner faces: it shows less than expected.
## What is hidden is held still in itself (the health cross bobs) and checked twice a second while somebody is near:
## a TorusMesh's box is not final when its tyre is seated (2.7 m reach seated, 5.6 m seconds later).

const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const Items = preload("res://commons/player/inventory_items.gd")
const HandLib = preload("res://commons/player/inventory_hand.gd")
const Vending = preload("res://commons/artifacts/vending_machine/vending_machine.gd")   # _quiet, _bounds
const WAYS: Array[String] = ["giant", "grazing", "lattice", "turning", "sheared"]
const GIANTS: Array[String] = ["tyre", "cone", "dice", "gem", "beachball", "bowlingpin", "oildrum", "woodenbox"]
const FLATS: Array[String] = ["woodenboard", "dangerx", "warningtriangle", "eupallet", "woodenboard", "dangerx", "skateboard"]
const TURNERS: Array[String] = ["tyre", "woodenboard", "gem", "cone", "skateboard", "bowlingpin", "eupallet", "oildrum"]
const CRATES: Array[String] = ["crate", "woodenbox", "eupallet", "walkramp", "cardboard", "cinderblock"]
const GRAINS: Array[String] = ["dice", "tincan"]
const PER_FRAME := 2
const WHITE := Color("f4f2ee")
const VERMILION := Color("d5352b")
const ROOF := Color("27383d")
const GOLD := Color("d9b45a")
const SHADE := Color("e7e3dc")            # every other slab, a little darker: a joint shows as a line
const JOINT := 0.014                      # between two segments of one slab

@export var side := 10.0
@export var height := 5.4
@export var slab := 0.18
@export var panel := 1.25
@export var joint := 0.008
@export var count := 72
@export var seed_value := 12
@export var pagoda := true
@export_enum("layered", "zones", "primitives", "giant", "coplanar", "grazing", "lattice", "turning", "sheared", "scatter") var hidden: String = "layered"

var walls: MultiMeshInstance3D
var shapes: Array[MultiMeshInstance3D] = []
var gate: Node3D
var shape_count := 0
var slab_count := 0                  # slabs through the depth of the block
var things: Array[Node3D] = []       # the prefabs standing in the slabs
var grids: Array[MultiMeshInstance3D] = []   # the lattice: one prefab's meshes, many times
var built := false                   # everything hidden has been made
var plan: Array[Dictionary] = []     # what was asked for, in order (a probe reads it)
var _queue: Array[Dictionary] = []
var _seat: Array = []                # [node, row, frames to wait, its box last time, times measured]
var _turning: Array = []             # [node, axis, radians a second, slide in metres, phase, its own z]
var _rocking: Array = []             # [node, axis, radians each way, speed, phase, the lean it has now]
var _lattice: Node3D                 # the lattice's MultiMeshes hang under it: it drifts as one
var _clock := 0.0
var _tidy := 0                       # frames until what is hidden is checked again
const TIDY_EVERY := 30


func apply_grid_config(config: Dictionary) -> void:
	for key in ["side", "height", "slab", "panel", "joint", "count", "pagoda", "hidden"]:
		if config.has(key): set(key, config[key])
	if config.has("seed"): seed_value = int(config.seed)
	if is_node_ready():
		for child in get_children():
			remove_child(child)
			child.queue_free()
		shapes.clear(); things.clear(); grids.clear(); plan.clear()
		_queue.clear(); _seat.clear(); _turning.clear(); _rocking.clear()
		_lattice = null
		_build()


func _ready() -> void:
	for key in ["side", "height", "slab", "panel", "joint", "count", "pagoda", "hidden"]:
		if has_meta("config_" + key): set(key, get_meta("config_" + key))
	if has_meta("config_seed"): seed_value = int(get_meta("config_seed"))
	_build()


## Is a point (in the world) inside the block?
func holds(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.x) < side * 0.5 and absf(p.z) < side * 0.5 and p.y > -0.2 and p.y < height


func _build() -> void:
	built = false
	_walls()
	if hidden == "primitives": _inside()
	else: _hide()
	# no daylight reaches into a closed block
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0, height - 1.3, 0)
	lamp.light_energy = 1.8
	lamp.omni_range = side * 0.95
	lamp.omni_attenuation = 0.6
	lamp.shadow_enabled = false
	add_child(lamp)
	if pagoda: _pagoda()
	if _queue.is_empty(): built = true
	set_process(true)


# ------------------------------------------------------------------------------------------------ what is hidden

## The plan: which prefab stands where and how, drawn from `seed`. Built over the next frames (_process).
func _hide() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var inner := side * 0.5 - 0.1
	match hidden:
		"zones":
			# bands from the pagoda (+z) inwards, one way in each
			var band := (2.0 * inner) / WAYS.size()
			for i in WAYS.size():
				_plan_way(WAYS[i], inner - (i + 1) * band, inner - i * band, rng, 0.3)
		"layered":
			# every way through the whole block at once, in each other
			for way in WAYS: _plan_way(way, -inner, inner, rng, 0.55)
		_:
			_plan_way(hidden, -inner, inner, rng, 1.0)
	plan.assign(_queue.duplicate())


## One way's rows between two depths. `share`: how much of a whole block's number of them.
func _plan_way(way: String, z0: float, z1: float, rng: RandomNumberGenerator, share: float) -> void:
	var reach := side * 0.5 - 1.2
	var deep := z1 - z0
	match way:
		"giant":
			for i in maxi(2, roundi(12 * share)):
				_queue.append({"way": way, "id": GIANTS[rng.randi() % GIANTS.size()], "at": Vector3(rng.randf_range(-reach, reach) * 0.8, rng.randf_range(0.6, 2.6), rng.randf_range(z0, z1)),
					"basis": Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)), "longest": rng.randf_range(3.6, 6.2)})
		"coplanar":
			var pitch := slab + joint
			for i in maxi(2, roundi(44 * share)):
				# a slab's own face, by its number: the prefab's flat side is set exactly on it when it is seated
				var n := clampi(int(round((rng.randf_range(z0, z1) + side * 0.5) / pitch)), 1, slab_count - 1)
				_queue.append({"way": way, "id": FLATS[rng.randi() % FLATS.size()], "at": Vector3(rng.randf_range(-reach, reach), rng.randf_range(0.5, 4.2), 0.0),
					"face": n, "ahead": i % 3 != 2, "roll": rng.randi() % 4 * PI / 2.0 + rng.randf_range(-0.2, 0.2), "longest": rng.randf_range(1.6, 3.4)})
		"grazing":
			for i in maxi(2, roundi(14 * share)):
				# nearly in a slab's face: leaned out of it by one and a half to six degrees, about a line in the face
				var line := rng.randf() * PI
				_queue.append({"way": way, "id": FLATS[rng.randi() % FLATS.size()], "at": Vector3(rng.randf_range(-reach, reach) * 0.6, rng.randf_range(1.6, 3.4), rng.randf_range(z0 + 0.3, z1 - 0.3)),
					"roll": rng.randf() * TAU, "axis": Vector3(cos(line), sin(line), 0.0), "tilt": deg_to_rad(rng.randf_range(1.5, 6.0)) * (1.0 if rng.randf() < 0.5 else -1.0),
					"rock": deg_to_rad(rng.randf_range(0.35, 0.8)), "speed": rng.randf_range(0.45, 0.9), "phase": rng.randf() * TAU, "longest": rng.randf_range(4.0, 7.0)})
		"lattice":
			var id := GRAINS[rng.randi() % GRAINS.size()]
			var cells: Array[Vector3] = []
			var layers := maxi(2, int(deep / 0.75))
			for k in layers:
				for j in 5:
					for i in 8:
						cells.append(Vector3(-reach + i * (2.0 * reach / 7.0), 0.45 + j * 1.05, z0 + (k + 0.5) * deep / layers))
			_queue.append({"way": way, "id": id, "cells": cells, "longest": 0.42})
		"turning":
			for i in maxi(2, roundi(14 * share)):
				_queue.append({"way": way, "id": TURNERS[rng.randi() % TURNERS.size()], "at": Vector3(rng.randf_range(-reach, reach), rng.randf_range(0.7, 3.6), rng.randf_range(z0 + 0.4, z1 - 0.4)),
					"basis": Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)), "longest": rng.randf_range(2.2, 4.4),
					"axis": Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3)).normalized(), "speed": rng.randf_range(0.35, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0),
					"slide": rng.randf_range(0.25, 0.6), "phase": rng.randf() * TAU})
		"sheared":
			for i in maxi(2, roundi(20 * share)):
				# a shear and a stretch: one side pulled along, one axis drawn out, one pressed flat
				var skew := Basis(Vector3(1, rng.randf_range(-0.9, 0.9), 0), Vector3(rng.randf_range(-0.8, 0.8), 1, rng.randf_range(-0.8, 0.8)), Vector3(0, rng.randf_range(-0.9, 0.9), 1))
				var stretch := Basis.from_scale(Vector3(rng.randf_range(2.0, 6.0), rng.randf_range(0.12, 0.6), rng.randf_range(1.0, 3.0)))
				_queue.append({"way": way, "id": CRATES[rng.randi() % CRATES.size()], "at": Vector3(rng.randf_range(-reach, reach) * 0.8, rng.randf_range(0.8, 3.2), rng.randf_range(z0, z1)),
					"basis": Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)) * skew * stretch, "longest": 0.0})
		"scatter":
			var stock := GIANTS + TURNERS + CRATES
			for i in maxi(2, roundi(28 * share)):
				_queue.append({"way": way, "id": stock[rng.randi() % stock.size()], "at": Vector3(rng.randf_range(-reach, reach), rng.randf_range(0.3, 4.0), rng.randf_range(z0, z1)),
					"basis": Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)), "longest": 0.0})


## One prefab: the item's own scene with its own config, inert (no body, no collider, no group).
func _prefab(id: String) -> Node3D:
	var it := Items.item(id)
	if it.is_empty(): return null
	var path := Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path): return null
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D:
		n.free()
		return null
	var cfg := Items.config_for(it, {})
	for k in cfg: n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"): n.apply_grid_config(cfg)
	n.name = "Hidden_" + id
	n.set_meta("plan_id", id)
	HandLib._make_inert(n)
	n.ready.connect(func(): HandLib._make_inert(n); Vending._quiet(n, false), CONNECT_ONE_SHOT)
	return n as Node3D


## How much bigger than itself a prefab stands, for its longest side to be `longest` metres (0: its own size).
func _grown(id: String, longest: float) -> float:
	var it := Items.item(id)
	var own: Variant = it.get("scale", 1.0)
	var keep := float(own) if own != null else 1.0
	if longest <= 0.0: return keep
	var size: Array = it.get("size", [0.3, 0.3, 0.3])
	return longest / maxf(maxf(float(size[0]), float(size[1])), maxf(float(size[2]), 0.05))


func _process(delta: float) -> void:
	# make what the plan asks for, two a frame
	for i in mini(PER_FRAME, _queue.size()):
		var row: Dictionary = _queue.pop_front()
		var thing := _prefab(str(row.id))
		if thing == null: continue
		add_child(thing)
		var grow := _grown(str(row.id), float(row.get("longest", 0.0)))
		match str(row.way):
			"coplanar", "grazing", "lattice":
				thing.transform = Transform3D(Basis.from_scale(Vector3.ONE * grow), Vector3(0, 1.0, 0))
			_:
				thing.transform = Transform3D((row.basis as Basis) * Basis.from_scale(Vector3.ONE * grow), row.at)
		_seat.append([thing, row, 3, AABB(), 0])
	# once a prefab has built itself: seat it the way its row asks
	for i in range(_seat.size() - 1, -1, -1):
		var wait: Array = _seat[i]
		wait[2] = int(wait[2]) - 1
		if int(wait[2]) > 0: continue
		var thing := wait[0] as Node3D
		if not is_instance_valid(thing):
			_seat.remove_at(i)
			continue
		# a prefab that moves by itself (the health cross bobs and spins) is held still; one that is still building
		# gets three more frames, until its box stops changing
		_still(thing)
		var now := _local_box(thing)
		var then: AABB = wait[3]
		if int(wait[4]) < 12 and (int(wait[4]) == 0 or not now.position.is_equal_approx(then.position) or not now.size.is_equal_approx(then.size)):
			wait[2] = 3
			wait[3] = now
			wait[4] = int(wait[4]) + 1
			continue
		_seat.remove_at(i)
		HandLib._make_inert(thing)
		var row: Dictionary = wait[1]
		thing.set_meta("hidden_way", str(row.way))
		match str(row.way):
			"coplanar": _lay_in_a_face(thing, row)
			"grazing":
				_lay_grazing(thing, row)
				_rocking.append([thing, row.axis, float(row.rock), float(row.speed), float(row.phase), 0.0])
			"lattice":
				_repeat(thing, row)
				continue
			"turning":
				_keep_turning_inside(thing, float(row.slide))
				_turning.append([thing, row.axis, float(row.speed), float(row.slide), float(row.phase), thing.position.z])
			_: _keep_inside(thing, false)
		things.append(thing)
	if _queue.is_empty() and _seat.is_empty(): built = true
	var eye := get_viewport().get_camera_3d()
	if eye == null or to_local(eye.global_position).length() > side * 1.6: return
	# what is hidden stays inside. Checked again and again, not only when seated: a prefab's mesh may still change
	# after it has been made (a TorusMesh's box is not final when its tyre is seated - measured 2.7 m reach seated,
	# 5.6 m a few seconds later, 23 Nov 2026)
	_tidy -= 1
	if _tidy <= 0 and built:
		_tidy = TIDY_EVERY
		_keep_all_inside()
	if _turning.is_empty() and _rocking.is_empty() and not is_instance_valid(_lattice): return
	_clock += delta
	for row: Array in _turning:
		var thing := row[0] as Node3D
		if not is_instance_valid(thing): continue
		thing.basis = Basis(row[1] as Vector3, float(row[2]) * delta) * thing.basis
		thing.position.z = float(row[5]) + sin(_clock * 0.5 + float(row[4])) * float(row[3])
	# a grazing plane rocks by less than a degree: the line where it leaves a slab runs metres
	for row: Array in _rocking:
		var thing := row[0] as Node3D
		if not is_instance_valid(thing): continue
		var lean := sin(_clock * float(row[3]) + float(row[4])) * float(row[2])
		thing.basis = Basis(row[1] as Vector3, lean - float(row[5])) * thing.basis
		row[5] = lean
	# the lattice drifts as one, half a slab each way and a degree round: every slice in every slab changes
	if is_instance_valid(_lattice):
		_lattice.position.z = sin(_clock * 0.45) * (slab + joint) * 0.5
		_lattice.rotation.y = sin(_clock * 0.31) * 0.02


## A prefab's meshes as one box in the block's own metres.
func _local_box(thing: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var back := global_transform.affine_inverse()
	# a composite prefab draws its repeated parts as one MultiMesh a kind (builder.gd batch_repeats): count those too
	for part in thing.find_children("*", "GeometryInstance3D", true, false):
		if not (part is MeshInstance3D or part is MultiMeshInstance3D) or not (part as Node3D).is_visible_in_tree(): continue
		if part is MeshInstance3D and (part as MeshInstance3D).mesh == null: continue
		if part is MultiMeshInstance3D and ((part as MultiMeshInstance3D).multimesh == null or (part as MultiMeshInstance3D).multimesh.instance_count == 0): continue
		var b: AABB = (back * (part as Node3D).global_transform) * (part as VisualInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## What is hidden stays hidden: a prefab too big for the block is made smaller about its own middle, and one that
## reaches out of a wall, the roof or the floor is moved in. `keep_z`: only sideways and in height (its depth is set).
func _keep_inside(thing: Node3D, keep_z: bool) -> void:
	var box := _local_box(thing)
	if box.size == Vector3.ZERO: return
	var room := Vector3(side - 0.3, height - 0.12, side - 0.3)
	var fit := minf(1.0, minf(room.x / maxf(box.size.x, 0.01), room.y / maxf(box.size.y, 0.01)))
	if not keep_z: fit = minf(fit, room.z / maxf(box.size.z, 0.01))
	if fit < 1.0:
		var mid := box.get_center()
		thing.transform = Transform3D(Basis.from_scale(Vector3.ONE * fit), mid - mid * fit) * thing.transform
		box = _local_box(thing)
	var half := box.size * 0.5
	var at := box.get_center()
	var to := at.clamp(Vector3(-side * 0.5 + 0.15, 0.06, -side * 0.5 + 0.15) + half, Vector3(side * 0.5 - 0.15, height - 0.06, side * 0.5 - 0.15) - half)
	if keep_z: to.z = at.z
	thing.position += to - at


## Every hidden prefab inside the block: a turner by the reach it has in its own frame, the rest by their boxes.
func _keep_all_inside() -> void:
	for row: Array in _turning:
		var thing := row[0] as Node3D
		if not is_instance_valid(thing): continue
		thing.position.z = float(row[5])
		_keep_turning_inside(thing, float(row[3]))
		row[5] = thing.position.z
	for thing: Node3D in things:
		if not is_instance_valid(thing) or str(thing.get_meta("hidden_way", "")) == "turning": continue
		_keep_inside(thing, str(thing.get_meta("hidden_way", "")) == "coplanar")


## A prefab's own motion stops: nothing in it runs a frame of its own (the block moves what it moves).
func _still(thing: Node3D) -> void:
	for n in [thing] + thing.find_children("*", "", true, false):
		(n as Node).set_process(false)
		(n as Node).set_physics_process(false)
		if n is AnimationPlayer: (n as AnimationPlayer).pause()


## How far a prefab reaches from its own origin, in the block's metres - the same whichever way it is turned: every
## part's box is taken in the prefab's own frame, where turning does not change it.
func _own_reach(thing: Node3D) -> float:
	var back := thing.global_transform.affine_inverse()
	var reach := 0.0
	for part in thing.find_children("*", "GeometryInstance3D", true, false):
		if not (part is MeshInstance3D or part is MultiMeshInstance3D) or not (part as Node3D).is_visible_in_tree(): continue
		var b: AABB = (back * (part as Node3D).global_transform) * (part as VisualInstance3D).get_aabb()
		for i in 8: reach = maxf(reach, b.get_endpoint(i).length())
	return reach * thing.basis.get_scale().x


## The same for a prefab that turns about its own origin and slides in depth: the ball it sweeps stays inside.
func _keep_turning_inside(thing: Node3D, slide: float) -> void:
	var reach := _own_reach(thing)
	if reach <= 0.0: return
	var room := minf(side - 0.3 - 2.0 * slide, height - 0.12) * 0.5
	if reach > room:
		thing.basis = Basis.from_scale(Vector3.ONE * (room / reach)) * thing.basis
		reach = room
	thing.position = thing.position.clamp(Vector3(-side * 0.5 + 0.15 + reach, 0.06 + reach, -side * 0.5 + 0.15 + slide + reach), Vector3(side * 0.5 - 0.15 - reach, height - 0.06 - reach, side * 0.5 - 0.15 - slide - reach))


## A flat prefab laid IN a slab's face: turned so its thin side looks along z, rolled, then moved until its own flat
## side is exactly the slab's - two surfaces at one depth. The eye is nearly always INSIDE a slab (a joint is 8 mm),
## and from inside a slab it sees the inner side of that slab's own faces. So the prefab lies on the OUTER side of a
## face, its body in the joint and the next slab: `ahead`, on the north face of slab `face` (seen by a walker heading
## in from the pagoda); otherwise on its south face (seen on looking back).
func _lay_in_a_face(thing: Node3D, row: Dictionary) -> void:
	var box := _local_box(thing)
	if box.size == Vector3.ZERO: return
	var turn := Basis.IDENTITY
	if box.size.y <= box.size.x and box.size.y <= box.size.z: turn = Basis(Vector3.RIGHT, PI / 2.0)        # thin up: tip it over
	elif box.size.x <= box.size.y and box.size.x <= box.size.z: turn = Basis(Vector3.UP, PI / 2.0)         # thin sideways: turn it
	thing.basis = Basis(Vector3.BACK, float(row.roll)) * turn * thing.basis
	var pitch := slab + joint
	box = _local_box(thing)
	var room := int(ceil((box.size.z + 0.15) / pitch))                                 # slabs its body needs
	var north := -(slab_count * pitch - joint) * 0.5 + clampi(int(row.face), room, slab_count - 1 - room) * pitch   # the north face of that slab
	var want: Vector3 = row.at
	var deep := (north - box.end.z) if bool(row.get("ahead", true)) else (north + slab - box.position.z)
	thing.position += Vector3(want.x - box.get_center().x, want.y - box.get_center().y, deep)
	_keep_inside(thing, true)


## A flat prefab at a GRAZING angle to the slabs: nearly in a slab's face, leaned out of it by a few degrees. A slab
## is 18 cm deep; a plane at 2 degrees to its faces climbs five metres from the face behind the eye to the face ahead.
## The line where it leaves the slab therefore runs about thirty times as fast as the eye walks, and the two eyes of
## a headset, a few centimetres apart in depth as soon as the head is turned, see it in two places.
func _lay_grazing(thing: Node3D, row: Dictionary) -> void:
	var box := _local_box(thing)
	if box.size == Vector3.ZERO: return
	var turn := Basis.IDENTITY
	if box.size.y <= box.size.x and box.size.y <= box.size.z: turn = Basis(Vector3.RIGHT, PI / 2.0)
	elif box.size.x <= box.size.y and box.size.x <= box.size.z: turn = Basis(Vector3.UP, PI / 2.0)
	thing.basis = Basis(row.axis as Vector3, float(row.tilt)) * Basis(Vector3.BACK, float(row.roll)) * turn * thing.basis
	box = _local_box(thing)
	thing.position += (row.at as Vector3) - box.get_center()
	_keep_inside(thing, false)


## One prefab's meshes, many times: the lattice. The prefab itself is the pattern and is put away afterwards.
func _repeat(thing: Node3D, row: Dictionary) -> void:
	var cells: Array = row.cells
	var back := thing.global_transform.affine_inverse()
	var grow := thing.basis
	for part in thing.find_children("*", "MeshInstance3D", true, false):
		var mesh := part as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var own := back * mesh.global_transform
		var many := MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_3D
		many.mesh = mesh.mesh
		many.instance_count = cells.size()
		for i in cells.size():
			# every other one mirrored: a MultiMesh keeps the winding of a mirrored instance, so it is drawn inside
			# out - the eye sees the far inner sides of the prefab and not its near skin
			var flip := Basis.from_scale(Vector3(-1, 1, 1)) if i % 2 == 1 else Basis.IDENTITY
			many.set_instance_transform(i, Transform3D(flip * grow, cells[i]) * own)
		var node := MultiMeshInstance3D.new()
		node.name = "Grid"
		node.multimesh = many
		node.material_override = mesh.material_override
		if not is_instance_valid(_lattice):
			_lattice = Node3D.new()
			_lattice.name = "Lattice"
			add_child(_lattice)
		_lattice.add_child(node)
		grids.append(node)
	remove_child(thing)
	thing.queue_free()


func _walls() -> void:
	var places: Array[Transform3D] = []
	var tones: Array[Color] = []
	var across := maxi(2, int(round(side / panel)))
	var wide := side / across
	var pitch := slab + joint
	slab_count = int(floor((side + joint) / pitch))
	var first := -(slab_count * pitch - joint) * 0.5 + slab * 0.5
	for n in slab_count:
		var z := first + n * pitch
		var shifted := n % 2 == 1
		var tone := WHITE if n % 2 == 0 else SHADE
		for i in (across + 1 if shifted else across):
			var w := wide
			var x := -side * 0.5 + (i + 0.5) * wide
			if shifted:
				# half a segment along, with a half segment at each end
				x = -side * 0.5 + i * wide
				if i == 0: w = wide * 0.5; x = -side * 0.5 + wide * 0.25
				elif i == across: w = wide * 0.5; x = side * 0.5 - wide * 0.25
			places.append(Transform3D(Basis.from_scale(Vector3(w - JOINT, height, slab)), Vector3(x, height * 0.5, z)))
			tones.append(tone)
	walls = _many("Slabs", BoxMesh.new(), places, tones, _glowing(true, 0.62))


func _inside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	var ring := TorusMesh.new()
	ring.inner_radius = 0.28
	ring.outer_radius = 0.5
	var pill := CapsuleMesh.new()
	pill.radius = 0.3
	pill.height = 1.0
	var kinds := [["Boxes", BoxMesh.new()], ["Spheres", ball], ["Cylinders", cylinder], ["Cones", cone], ["Prisms", PrismMesh.new()], ["Rings", ring], ["Capsules", pill]]
	var paint := _glowing(false, 0.5)
	var inner := side * 0.5 - 0.05      # the block's own faces
	var under := height - 0.05          # and its top
	shape_count = 0
	for k in kinds.size():
		var share := count / kinds.size() + (1 if k < count % kinds.size() else 0)
		var places: Array[Transform3D] = []
		var colours: Array[Color] = []
		for i in share:
			var big := rng.randf_range(0.55, 2.3)
			var squash := Vector3(big * rng.randf_range(0.7, 1.25), big * rng.randf_range(0.7, 1.35), big * rng.randf_range(0.7, 1.25))
			var turn := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
			# however it is turned, it reaches no further than half its diagonal: placed that far from every wall and
			# from the roof. It may stand up to its middle in the floor, which hides what is under it.
			var reach := squash.length() * 0.5
			var span := maxf(inner - reach, 0.2)
			var low := minf(reach * 0.5, under - reach)
			places.append(Transform3D(turn * Basis.from_scale(squash), Vector3(rng.randf_range(-span, span), rng.randf_range(low, maxf(under - reach, low + 0.05)), rng.randf_range(-span, span))))
			colours.append(Color.from_hsv(rng.randf(), rng.randf_range(0.72, 1.0), rng.randf_range(0.88, 1.0)))
		shapes.append(_many(str(kinds[k][0]), kinds[k][1], places, colours, paint))
		shape_count += share


## A surface in its instance's own colour that also lights itself by `glow`: inside a slab no lamp is on the side one
## sees a face from, and a white that is only lit turns grey there. `both`: drawn from both sides (the slabs).
func _glowing(both: bool, glow: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode %s;\nuniform float glow = 0.5;\nvoid fragment() {\n\tALBEDO = COLOR.rgb;\n\tROUGHNESS = 0.8;\n\tEMISSION = COLOR.rgb * glow;\n}\n" % ("cull_disabled" if both else "cull_back")
	var paint := ShaderMaterial.new()
	paint.shader = shader
	paint.set_shader_parameter("glow", glow)
	return paint


func _many(title: String, mesh: Mesh, places: Array[Transform3D], colours: Array[Color], paint: Material) -> MultiMeshInstance3D:
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = not colours.is_empty()
	many.mesh = mesh
	many.instance_count = places.size()
	for i in places.size():
		many.set_instance_transform(i, places[i])
		if many.use_colors: many.set_instance_color(i, colours[i])
	var node := MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = many
	node.material_override = paint
	add_child(node)
	return node


## Four posts, three roofs, a carpet into the wall: here is where one walks in.
func _pagoda() -> void:
	gate = Node3D.new()
	gate.name = "Pagoda"
	gate.position = Vector3(0, 0, side * 0.5 + 0.35)
	add_child(gate)
	var span := 1.3
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_part(BoxMesh.new(), Vector3(sx * span, 1.3, sz * span), Vector3(0.18, 2.6, 0.18), VERMILION, "Post")
	for sz in [-1.0, 1.0]:
		_part(BoxMesh.new(), Vector3(0, 2.52, sz * span), Vector3(span * 2.0 + 0.5, 0.16, 0.16), VERMILION, "Beam")
	for sx in [-1.0, 1.0]:
		_part(BoxMesh.new(), Vector3(sx * span, 2.52, 0), Vector3(0.16, 0.16, span * 2.0 + 0.5), VERMILION, "Beam")
	var at := 2.6
	for tier in [[4.0, 2.0, 0.5, 0.36], [3.1, 1.5, 0.45, 0.3], [2.3, 0.3, 0.72, 0.0]]:
		var roof := CylinderMesh.new()
		roof.radial_segments = 4
		roof.rings = 1
		roof.bottom_radius = float(tier[0]) / sqrt(2.0)
		roof.top_radius = float(tier[1]) / sqrt(2.0)
		roof.height = float(tier[2])
		var part := _part(roof, Vector3(0, at + float(tier[2]) * 0.5, 0), Vector3.ONE, ROOF, "Roof")
		part.rotation.y = PI / 4.0
		# a thin gold eave under each roof
		_part(BoxMesh.new(), Vector3(0, at + 0.02, 0), Vector3(float(tier[0]) + 0.06, 0.04, float(tier[0]) + 0.06), GOLD, "Eave")
		at += float(tier[2])
		if float(tier[3]) > 0.0:
			_part(BoxMesh.new(), Vector3(0, at + float(tier[3]) * 0.5, 0), Vector3(float(tier[1]) * 0.9, float(tier[3]), float(tier[1]) * 0.9), VERMILION, "Neck")
			at += float(tier[3])
	var knob := SphereMesh.new()
	knob.radius = 0.15
	knob.height = 0.3
	_part(knob, Vector3(0, at + 0.12, 0), Vector3.ONE, GOLD, "Finial")
	# the way in: a carpet from in front of the pagoda, under it, into the block
	var carpet := Kit.block(self, Vector3(1.5, 0.012, 5.4), Vector3(0, 0.007, side * 0.5 - 0.3), Color("e2574c"), false)
	carpet.name = "Carpet"
	carpet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plate := _part(BoxMesh.new(), Vector3(0, 2.2, span + 0.1), Vector3(1.9, 0.42, 0.03), Color("fbf7ee"), "Plate")
	var words := Kit.label(gate, "WALK IN\nthis wall stops nobody", plate.position + Vector3(0, 0, 0.02), 0.0024)
	words.name = "Words"
	words.modulate = Color("1d1d1f")


func _part(mesh: Mesh, at: Vector3, size: Vector3, colour: Color, title: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.position = at
	node.scale = size
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.7
	node.material_override = paint
	gate.add_child(node)
	return node
