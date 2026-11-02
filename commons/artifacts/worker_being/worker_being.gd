class_name WorkerBeing
extends Node3D
## THE WORKER BEING (Palle, 2026-11-02): "the playground workers start out as abstract entities, sculpture-like and
## simple machines, and as the work progresses become more sophisticated - they are the same being at multiple
## stages"; "I want the worker to be a humanoid"; "one humanoid body wearing each stage's sculpture, and add joints so
## they can dance - or move".
##
## ONE HUMANOID BODY - a jointed skeleton in Modulor proportions (pelvis, spine, chest, neck, head, shoulders,
## elbows, wrists, hips, knees, ankles) - WEARING EACH STAGE'S SCULPTURE. The sculptures are the endless museum's
## dream bodies (commons/artifacts/dream_bodies), one standing on a plinth in every hall. Like the biome ladder
## (biome_object, gen 14) the stage - a hall, a sequence key or `full` - names a closure of words
## (BiomeGrammar.closure) and a part stands only when its word is in it; the SEED fixes the body whatever the stage
## (its height, the phases of its moves, its hue). So the same being stands at every stage, in the clothes of the
## hall it has reached:
##   point          the heart, a black sphere at the chest - all there is at Point_One (the biome's seed point)
##   line           the body drawn in lines, joint to joint
##   lattice        the lines wound in looping cord                     (asawa_wire._ring, the sculpture's own)
##   face           the bones as flat plates
##   solid          slabs, bone by bone: core bar, block, strip         (stijl_robot._limb; its colours wait for colour)
##   sphere         ball joints and a round head                                         (stijl_robot, ceramic_puppet)
##   subdivide      the limbs as glazed links between balls             (ceramic_puppet._chain; `unstrung` with translate)
##   ornament       a collar of Durer's polyhedron                                       (porcelain_doll's collar)
##   translate      the slabs float apart from the body as panels                        (panel_robot)
##   pickup         a cube in its hand
##   colour         its hues - before them, chalk     palette: each limb its colour      (stijl_robot)
##   light          glowing patches on its skin                                          (paik_light)
##   dress          a long skirt                                                         (masked_dancer)
##   flower         a flower on its head                                                 (brass_stamen)
##   paint / tile   a painted skin / a body in tesserae        (masked_dancer._tex_diamond / mosaic_body's tesserae)
##   spring         a brass armature with coil springs at knees and elbows               (brass_stamen)
##   gravity        feet planted on the floor; before it the figure floats 3 cm up, a statue off its plinth
##   rule           a crust of crystals on the shoulders                                 (crystal_suit)
##   recurse        fingers that branch                     branch/rewrite: coral growing from the head (coral_polyp)
##   creature       a face                                  deform_soft: ropes of soft fibre (hicks_fiber)
##   implicit       one fused skin over the joints                                       (fetish_idol)
##   bias           the made finish: graphite and brass
## AND IT MOVES - `motion` dance, walk or still - its moves growing with the walk like its body: still at Point_One;
## a sway once it moves of itself (self_move); every joint turning once it knows rotate; stepping with
## translate/run; a wave rolling down the arms with oscillate; bouncing on springs over planted feet with spring and
## gravity (the legs solve IK to the floor); varied phrases with sample/vary. `walk` swings the legs and arms in a
## gait on the spot (in the habitat the being travels under it). The seed sets the phases. `moves` (config) can
## teach the moves of a later stage than the body wears - the court's worker wears the primitives and dances the walk.
## get_state() names the parts standing and the moves; the bench is commons/testing/probe_worker_ladder.tscn.

const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
## The sculptures it wears - the dream bodies' own static helpers, handed one bone at a time (joint at the origin,
## the bone's end): Stijl's limb grammar, the ceramic puppet's chain, Asawa's cord, the masked dancer's paint.
const STIJL := preload("res://commons/artifacts/dream_bodies/bodies/stijl_robot.gd")
const PUPPET := preload("res://commons/artifacts/dream_bodies/bodies/ceramic_puppet.gd")
const ASAWA := preload("res://commons/artifacts/dream_bodies/bodies/asawa_wire.gd")
const DANCER := preload("res://commons/artifacts/dream_bodies/bodies/masked_dancer.gd")
const PHI := 1.6180339887
const BAUHAUS := [Color("d8432e"), Color("f2c230"), Color("e88aa8"), Color("2f5fa8"), Color("1f8f6a"), Color("f4f1ea")]

@export var stage := "full"
@export var seed := 7
@export_enum("dance", "walk", "still") var motion := "dance"
@export var tempo := 104.0      ## beats per minute
## The stage its MOVES come from - "" for the body's own stage. The body wears what `stage` allows; the dance can be
## taught further ahead (Palle, 2026-11-02, in the court: "let it dance the full dance, not just the sway").
@export var moves_from := ""

var parts: Array[String] = []
var moves: Array[String] = []
var _closure := {}
var _move_closure := {}
var _plan := {}
var _j := {}                    # joint name -> Node3D
var _rest := {}                 # joint name -> rest Basis
var _ankle_home := {}           # "l"/"r" -> the planted ankle, in the skeleton's space
var _t := 0.0
var _root: Node3D

## The planted ankle's height: the foot slab (0.02 below it, 0.05 deep) then stands with its sole on the floor.
const ANKLE_Y := 0.045
## joint: [parent, offset at a height of 1.83 m]
const SKELETON := {
	"pelvis": ["", Vector3(0, 0.95, 0)], "spine": ["pelvis", Vector3(0, 0.12, 0)], "chest": ["spine", Vector3(0, 0.22, 0)],
	"neck": ["chest", Vector3(0, 0.22, 0)], "head": ["neck", Vector3(0, 0.1, 0)],
	"shoulder_l": ["chest", Vector3(0.19, 0.17, 0)], "elbow_l": ["shoulder_l", Vector3(0, -0.29, 0)], "wrist_l": ["elbow_l", Vector3(0, -0.26, 0)],
	"shoulder_r": ["chest", Vector3(-0.19, 0.17, 0)], "elbow_r": ["shoulder_r", Vector3(0, -0.29, 0)], "wrist_r": ["elbow_r", Vector3(0, -0.26, 0)],
	"hip_l": ["pelvis", Vector3(0.095, -0.05, 0)], "knee_l": ["hip_l", Vector3(0, -0.44, 0)], "ankle_l": ["knee_l", Vector3(0, -0.43, 0)],
	"hip_r": ["pelvis", Vector3(-0.095, -0.05, 0)], "knee_r": ["hip_r", Vector3(0, -0.44, 0)], "ankle_r": ["knee_r", Vector3(0, -0.43, 0)],
}
## bone: [joint, end offset from it, width, depth] - the visual spans the joint to the end
const BONES := {
	"pelvis": ["pelvis", Vector3(0, 0.12, 0), 0.3, 0.18], "belly": ["spine", Vector3(0, 0.22, 0), 0.3, 0.18],
	"chest": ["chest", Vector3(0, 0.22, 0), 0.36, 0.2], "neck": ["neck", Vector3(0, 0.1, 0), 0.08, 0.08],
	"head": ["head", Vector3(0, 0.23, 0), 0.19, 0.21],
	"upper_arm_l": ["shoulder_l", Vector3(0, -0.29, 0), 0.085, 0.085], "forearm_l": ["elbow_l", Vector3(0, -0.26, 0), 0.07, 0.07], "hand_l": ["wrist_l", Vector3(0, -0.1, 0), 0.08, 0.03],
	"upper_arm_r": ["shoulder_r", Vector3(0, -0.29, 0), 0.085, 0.085], "forearm_r": ["elbow_r", Vector3(0, -0.26, 0), 0.07, 0.07], "hand_r": ["wrist_r", Vector3(0, -0.1, 0), 0.08, 0.03],
	"thigh_l": ["hip_l", Vector3(0, -0.44, 0), 0.13, 0.13], "shin_l": ["knee_l", Vector3(0, -0.43, 0), 0.1, 0.1], "foot_l": ["ankle_l", Vector3(0, -0.02, 0.12), 0.09, 0.05],
	"thigh_r": ["hip_r", Vector3(0, -0.44, 0), 0.13, 0.13], "shin_r": ["knee_r", Vector3(0, -0.43, 0), 0.1, 0.1], "foot_r": ["ankle_r", Vector3(0, -0.02, 0.12), 0.09, 0.05],
}

func apply_grid_config(config: Dictionary) -> void:
	var before := [stage, seed, motion, tempo, moves_from]
	if config.has("stage") and str(config.stage).strip_edges() != "": stage = str(config.stage).strip_edges()
	if config.has("seed") and str(config.seed).is_valid_int(): seed = int(str(config.seed))
	if config.has("motion") and str(config.motion) in ["dance", "walk", "still"]: motion = str(config.motion)
	if config.has("tempo") and str(config.tempo).is_valid_float(): tempo = clampf(float(str(config.tempo)), 40.0, 200.0)
	if config.has("moves"): moves_from = str(config.moves).strip_edges()
	if is_inside_tree() and _root != null and before != [stage, seed, motion, tempo, moves_from]: _build()

func _ready() -> void:
	var config := {}
	for key in ["stage", "seed", "motion", "tempo", "moves"]:
		if has_meta("config_" + key): config[key] = get_meta("config_" + key)
	apply_grid_config(config)
	_build()

func has_word(word: String) -> bool:
	return Grammar.allows(_closure, word)

## A word the being may MOVE by (from `moves_from`, else its own stage). Planting the feet is a move.
func has_move_word(word: String) -> bool:
	return Grammar.allows(_move_closure, word)

## A joint's node (for probes, and for anything that wants to hold the being's hand).
func joint(n: String) -> Node3D:
	return _j.get(n)

func get_state() -> Dictionary:
	return {"stage": stage, "seed": seed, "known": bool((_closure.get("position", {}) as Dictionary).get("known", false)),
		"parts": parts.duplicate(), "moves": moves.duplicate(), "moves_from": moves_from, "motion": motion, "plan": _plan.duplicate(),
		"words": {"made_of": _closure.get("made_of", []), "does": _closure.get("does", []), "knows": _closure.get("knows", [])}}

## The pose at time t: the dance or the walk, the planted feet. Public so a bench can photograph any moment.
func pose_at(t: float) -> void:
	_t = t
	_pose(t)

# ─── the plan: the seed's alone ───────────────────────────────────────────────

func _seed_plan() -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.seed = hash([seed, "worker_humanoid"])
	var plan := {"height": 0.92 + 0.08 * rng.randf(), "hue": rng.randi_range(0, 4), "phases": {}, "amps": {}}
	for n in ["sway", "twist", "arm_l", "arm_r", "elbow_l", "elbow_r", "head", "step", "wave", "bounce"]:
		plan.phases[n] = rng.randf() * TAU
		plan.amps[n] = rng.randf_range(0.75, 1.25)
	return plan

# ─── build ────────────────────────────────────────────────────────────────────

func _build() -> void:
	for c in get_children(): c.free()
	parts.clear(); moves.clear(); _j.clear(); _rest.clear()
	_closure = Grammar.closure("postfoundationscrisis" if stage == "full" else stage)
	var ms := moves_from if moves_from != "" else stage
	_move_closure = Grammar.closure("postfoundationscrisis" if ms == "full" else ms)
	_plan = _seed_plan()
	_root = Node3D.new(); _root.name = "Skeleton"; _root.scale = Vector3.ONE * float(_plan.height); add_child(_root)
	for n in SKELETON:
		var j := Node3D.new(); j.name = n
		var parent: Node3D = _root if SKELETON[n][0] == "" else _j[SKELETON[n][0]]
		parent.add_child(j); j.position = SKELETON[n][1]; _j[n] = j
	_j.shoulder_l.rotation.z = deg_to_rad(8); _j.shoulder_r.rotation.z = deg_to_rad(-8)   # the arms hang a little out
	for n in _j: _rest[n] = (_j[n] as Node3D).basis
	for side in ["l", "r"]:
		_ankle_home[side] = Vector3(SKELETON["hip_" + side][1].x, ANKLE_Y, 0.0)
	_dress()
	_moves()
	_pose(0.0)
	set_process(motion != "still" and not moves.is_empty())

func _moves() -> void:
	if has_move_word("self_move"): moves.append("sway")
	if has_move_word("rotate"): moves.append("turn")
	if has_move_word("translate") or has_move_word("run"): moves.append("step")
	if has_move_word("oscillate"): moves.append("wave")
	if has_move_word("spring") and has_move_word("gravity"): moves.append("bounce")
	if has_move_word("sample") or has_move_word("vary"): moves.append("vary")

func _dress() -> void:
	var finish := has_word("bias")
	var coloured := has_word("colour")
	var chalk := Color("e9e5dc")
	var hue: Color = BAUHAUS[int(_plan.hue)]
	var solid := has_word("solid")
	if has_word("point"):
		_sphere(_j.chest, "Heart", 0.07, Vector3(0, 0.1, 0.13 if solid else 0.0), _mat(Color("0b0b0c"), 0.6, 0.12)); parts.append("heart")
	if not (has_word("line") or solid):
		return   # Point_One: the heart alone
	var tex := _skin_texture()
	var i := 0
	for b in BONES:
		var spec: Array = BONES[b]
		var jn: Node3D = _j[spec[0]]
		var end: Vector3 = spec[1]
		var c: Color = chalk
		if coloured:
			if has_word("palette"): c = BAUHAUS[(int(_plan.hue) + i) % BAUHAUS.size()]
			elif b in ["pelvis", "belly", "chest"]: c = hue
			else: c = Color("f4f1ea")
		if finish: c = Color("2b2d31")
		var m := _mat(c, 0.55 if finish else 0.0, 0.3 if finish else 0.55)
		if tex != null and not finish:
			m.albedo_texture = tex; m.uv1_triplanar = true; m.uv1_scale = Vector3(4, 4, 4)
		if solid:
			var gap := 0.025 if has_word("translate") else 0.0   # panel_robot's floating plates
			var limb: bool = b.contains("arm") or b.begins_with("thigh") or b.begins_with("shin")
			if has_word("subdivide") and limb:
				# ceramic_puppet's chain: glazed links with chrome collars between ball joints; `unstrung` (its own
				# mode: the links hover off the armature) once translate is learned
				var r := float(spec[2]) * 0.5
				PUPPET._chain(jn, [Vector3.ZERO, end / 3.0, end * 2.0 / 3.0, end], [r, r * 0.92, r * 0.86, r * 0.8], [m],
					_ink(finish), _chrome(), "unstrung" if has_word("translate") else "strung")
			elif limb or b.begins_with("hand") or b.begins_with("foot") or b == "neck":
				# stijl_robot's limb: a core bar, an offset block on one face, a strip on the other
				var block: StandardMaterial3D = STIJL._mat(c if not coloured or finish else [STIJL.SAFFRON, STIJL.PINK, STIJL.RED][i % 3], 0.5, 0.55 if finish else 0.0, 0.0 if finish else 0.3)
				var core: StandardMaterial3D = m if (tex != null or finish) else STIJL._mat(chalk if not coloured else STIJL.WHITE, 0.55, 0.0, 0.2)
				var strip: StandardMaterial3D = STIJL._mat(Color("8d8f93") if not coloured else STIJL.RED, 0.5, 0.0, 0.0) if not finish else _ink(true)
				STIJL._limb(jn, Vector3.ZERO, end, float(spec[2]) * 0.6, core, block, strip, 0.25 if i % 2 else -0.25, 1.0 if i % 3 else -1.0)
			elif b == "head" and has_word("sphere"):
				var hm := _sphere(jn, "Head", 0.11, end * 0.5, m)
				if has_word("tinted_glass") and not finish: hm.material_override = _glass(c)
			else:
				_slab(jn, b, Vector3.ZERO, end, spec[2], spec[3], m, gap)
		elif has_word("face"):
			_slab(jn, b, Vector3.ZERO, end, spec[2], 0.008, _mat(chalk, 0.0, 0.7), 0.0)
		else:
			_slab(jn, b, Vector3.ZERO, end, 0.008, 0.008, _mat(Color("1d1d1f"), 0.0, 0.6), 0.0)
		if has_word("lattice") and not solid:
			# asawa_wire's cord: rings stacked along the bone, a little tilted, the body drawn in loops
			var cord := _mat(Color("8e8a80"), 0.0, 0.8)
			var n := maxi(3, int(end.length() / 0.055))
			var y := end.normalized(); var x := y.cross(Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT).normalized()
			for k in n:
				ASAWA._ring(jn, end * (float(k) + 0.5) / float(n), Basis(x, y, x.cross(y)).rotated(x, 0.22 * sin(k * 1.7)), maxf(float(spec[2]), 0.05) * 0.55, 0.004, cord)
		i += 1
	if solid: parts.append("slabs")
	elif has_word("face"): parts.append("plates")
	else: parts.append("lines")
	if has_word("lattice") and not solid: parts.append("cord")
	if has_move_word("gravity"): parts.append("planted")
	if not solid: return
	if has_word("subdivide"): parts.append("beads")
	if has_word("translate"): parts.append("panels")
	if has_word("sphere"):
		for n in _j:
			if n in ["pelvis", "head"]: continue
			if has_word("subdivide") and (n.begins_with("elbow") or n.begins_with("knee")): continue   # the chain's own balls
			_sphere(_j[n], "Ball", 0.05 if n.begins_with("hip") else 0.035, Vector3.ZERO, _mat(Color("b8913a") if finish else Color("141416"), 0.6 if finish else 0.2, 0.3))
		parts.append_array(["ball_joints", "round_head"])
	if has_word("ornament"):
		var orn := _polyhedron(0.05, _mat(Color("b8913a") if finish else Color("d9d4c7"), 0.4, 0.3))
		orn.position = Vector3(0, 0.2, 0.12); orn.rotation_degrees = Vector3(30, 20, 0); _j.chest.add_child(orn); parts.append("collar")
	if has_word("pickup"):
		_box(_j.wrist_r, "Carried", Vector3(0.1, 0.1, 0.1), Vector3(0, -0.15, 0.06), _mat(BAUHAUS[3] if coloured else Color("e8e3d6"), 0, 0.6)); parts.append("carried_cube")
	if has_word("light"):
		var spots := ["chest", "belly", "upper_arm_l", "upper_arm_r", "thigh_l", "thigh_r", "forearm_l", "shin_r", "chest"]
		for k in spots.size():
			var spec: Array = BONES[spots[k]]
			var p: Vector3 = (spec[1] as Vector3) * (0.3 + 0.07 * k) + Vector3(0.04 if k % 2 else -0.04, 0, float(spec[3]) * 0.5 + 0.004)
			var glow := _sphere(_j[spec[0]], "Glow", 0.022, p, _mat(BAUHAUS[k % 4], 0, 0.3))
			var gm: StandardMaterial3D = glow.material_override; gm.emission_enabled = true; gm.emission = BAUHAUS[k % 4]; gm.emission_energy_multiplier = 2.2
		parts.append("glow")
	if has_word("dress"):
		var skirt := MeshInstance3D.new(); var cone := CylinderMesh.new(); cone.top_radius = 0.17; cone.bottom_radius = 0.34; cone.height = 0.3; cone.radial_segments = 24
		skirt.mesh = cone; skirt.material_override = _mat(Color("2b2d31") if finish else Color("1c1a22"), 0.0, 0.5); skirt.position = Vector3(0, -0.12, 0); skirt.name = "Skirt"
		_j.pelvis.add_child(skirt); parts.append("skirt")
	if has_word("flower") and not (has_word("branch") or has_word("rewrite")):
		_flower(_j.head, Vector3(0.06, 0.24, 0)); parts.append("flower")
	if has_word("spring"):
		var brass := _mat(Color("b8913a"), 0.85, 0.3)
		for n in ["knee_l", "knee_r", "elbow_l", "elbow_r"]:
			var coil := _helix(0.06 if n.begins_with("knee") else 0.048, 6, brass); coil.name = "Spring"; _j[n].add_child(coil)
		for side in ["l", "r"]:
			var sx := 1.0 if side == "l" else -1.0
			_rod(_j["hip_" + side], "Brass", Vector3(0.075 * sx, 0, 0), Vector3(0.075 * sx, -0.44, 0), brass)
			_rod(_j["shoulder_" + side], "Brass", Vector3(0.055 * sx, 0, 0), Vector3(0.055 * sx, -0.29, 0), brass)
		parts.append_array(["springs", "brass_armature"])
	if has_word("rule"):
		var rng := RandomNumberGenerator.new(); rng.seed = hash([seed, "crystals"])
		for k in 14:
			var side := 1.0 if k % 2 else -1.0
			var spike := _polyhedron(rng.randf_range(0.015, 0.035), _mat(Color("b8913a") if finish else Color("cfe3ea"), 0.3, 0.15))
			spike.scale = Vector3(1, rng.randf_range(1.5, 3.0), 1); spike.position = Vector3(side * rng.randf_range(0.08, 0.2), rng.randf_range(0.14, 0.24), rng.randf_range(-0.08, 0.08))
			spike.rotation = Vector3(rng.randf_range(-0.5, 0.5), 0, side * rng.randf_range(0.2, 0.7)); _j.chest.add_child(spike)
		parts.append("crystals")
	if has_word("recurse"):
		for side in ["l", "r"]:
			for f in 3: _branch(_j["wrist_" + side], Vector3(0, -0.1, 0), Vector3(-0.35 + 0.35 * f, -1, 0.2).normalized(), 0.05, 2, _mat(Color("2b2b2e"), 0.2, 0.5))
		parts.append("fingers")
	if has_word("branch") or has_word("rewrite"):
		var cm := _mat(Color("b8913a") if finish else (Color("e88aa8") if coloured else Color("bdbdbd")), 0.2, 0.4)
		for k in 3: _branch(_j.head, Vector3(0, 0.2, 0), Vector3(-0.5 + 0.5 * k, 1.0, -0.2).normalized(), 0.13, 3, cm)
		parts.append("coral")
	if has_word("creature"):
		for side in [-1.0, 1.0]:
			_sphere(_j.head, "Eye", 0.022, Vector3(side * 0.045, 0.13, 0.095), _mat(Color("f4f1ea"), 0, 0.3))
			_sphere(_j.head, "Pupil", 0.01, Vector3(side * 0.045, 0.13, 0.115), _mat(Color("0b0b0c"), 0, 0.2))
		parts.append("face")
	if has_word("deform_soft"):
		var wool := [Color("d9a7a0"), Color("8a8f6a"), Color("6b7480"), Color("e9e1cf"), Color("c48b8b")]
		for k in 5:
			var rope := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = 0.16 + 0.012 * k; tor.outer_radius = 0.21 + 0.012 * k
			rope.mesh = tor; rope.material_override = _mat(wool[k], 0, 0.95)
			rope.position = Vector3(0, -0.02 + 0.07 * k, 0); rope.rotation_degrees = Vector3(8 * (k - 2), 0, 6); rope.name = "Fibre"; _j.spine.add_child(rope)
		parts.append("soft_fibre")
	if has_word("implicit"):
		for n in ["shoulder_l", "shoulder_r", "elbow_l", "elbow_r", "hip_l", "hip_r", "knee_l", "knee_r", "neck"]:
			var blob := _sphere(_j[n], "Skin", 0.075, Vector3(0, -0.03, 0), _mat(Color("3a3c41") if finish else Color("d6d8de"), 0.7, 0.18))
			blob.scale = Vector3(1, 1.5, 1)
		parts.append("fused_skin")
	if tex != null and not finish: parts.append("tesserae" if has_word("tile") else "painted_skin")
	if coloured: parts.append("hues")
	if finish: parts.append("made_finish")

## The skin's pattern: tesserae once tiles are learned (mosaic_body), stripes of paint before them.
func _skin_texture() -> Texture2D:
	if not has_word("solid"): return null
	if has_word("tile"):
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		var stones := [Color("2f7f7a"), Color("4fa3b8"), Color("e9e5dc"), Color("1f8f6a")]
		for y in 64:
			for x in 64:
				var grout := x % 8 == 0 or y % 8 == 0
				img.set_pixel(x, y, Color("e9e5dc") if grout else stones[absi(hash([x / 8, y / 8, seed])) % 4])
		return ImageTexture.create_from_image(img)
	if has_word("paint"):   # masked_dancer's body paint, the dancer's diamond lattice in the being's hue
		var rng := RandomNumberGenerator.new(); rng.seed = hash([seed, "paint"])
		return DANCER._tex_diamond(rng, Color("f4f1ea"), BAUHAUS[int(_plan.hue)].darkened(0.35), BAUHAUS[int(_plan.hue)])
	return null

# ─── moving: the dance and the walk ───────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	_pose(_t)

func _pose(t: float) -> void:
	if _root == null or _j.is_empty(): return
	for n in _j: (_j[n] as Node3D).basis = _rest[n]
	var beat := t * tempo / 60.0 * TAU
	var ph: Dictionary = _plan.phases; var am: Dictionary = _plan.amps
	var pelvis_offset := Vector3.ZERO
	var feet := {"l": Vector3.ZERO, "r": Vector3.ZERO}
	if motion == "still" or moves.is_empty():
		pass
	elif motion == "walk":
		# a gait on the spot: legs and arms swinging opposite, the pelvis rising on each step
		var g := beat * 0.5
		if "step" in moves or "turn" in moves:
			for side in ["l", "r"]:
				var p := g + (0.0 if side == "l" else PI)
				feet[side] = Vector3(0, 0.07 * maxf(0.0, sin(p)), 0.16 * cos(p))
				_rot("shoulder_" + side, Vector3.RIGHT, -0.45 * cos(p))
				_rot("elbow_" + side, Vector3.RIGHT, -0.35)
			_rot("pelvis", Vector3.UP, 0.08 * sin(g))
			pelvis_offset.y = -0.02 * absf(cos(g))
		elif "sway" in moves:
			_rot("pelvis", Vector3.FORWARD, 0.05 * sin(g))
	else:
		var vary := 1.0 + (0.35 * sin(beat * 0.125 + float(ph.wave)) if "vary" in moves else 0.0)
		if "sway" in moves:   # the dance it has at the primitives: it moves of itself, rocking and swinging, nothing turning yet
			_rot("pelvis", Vector3.FORWARD, 0.09 * am.sway * sin(beat * 0.5 + ph.sway))
			_rot("chest", Vector3.FORWARD, -0.12 * am.sway * sin(beat * 0.5 + ph.sway))
			_rot("shoulder_l", Vector3.RIGHT, 0.5 * sin(beat * 0.5 + ph.arm_l)); _rot("shoulder_r", Vector3.RIGHT, -0.5 * sin(beat * 0.5 + ph.arm_l))
			_rot("shoulder_l", Vector3.BACK, 0.25 * (0.5 + 0.5 * sin(beat + ph.arm_r))); _rot("shoulder_r", Vector3.FORWARD, 0.25 * (0.5 + 0.5 * sin(beat + ph.arm_r + PI)))
			_rot("neck", Vector3.RIGHT, 0.12 * sin(beat + ph.head))
			pelvis_offset.y = 0.025 * absf(sin(beat * 0.5 + ph.sway))   # it rises off its plinth on each swing
		if "turn" in moves:
			_rot("pelvis", Vector3.UP, 0.25 * am.twist * vary * sin(beat * 0.25 + ph.twist))
			_rot("chest", Vector3.UP, -0.3 * am.twist * sin(beat * 0.25 + ph.twist))
			_rot("shoulder_l", Vector3.BACK, 1.1 * am.arm_l * vary * (0.5 + 0.5 * sin(beat * 0.5 + ph.arm_l)))
			_rot("shoulder_r", Vector3.FORWARD, 1.1 * am.arm_r * (0.5 + 0.5 * sin(beat * 0.5 + ph.arm_r)))
			_rot("elbow_l", Vector3.RIGHT, -0.9 * am.elbow_l * (0.5 + 0.5 * sin(beat + ph.elbow_l)))
			_rot("elbow_r", Vector3.RIGHT, -0.9 * am.elbow_r * (0.5 + 0.5 * sin(beat + ph.elbow_r)))
			_rot("head", Vector3.UP, 0.35 * sin(beat * 0.5 + ph.head)); _rot("neck", Vector3.RIGHT, 0.12 * sin(beat + ph.head))
		if "wave" in moves:   # a wave rolling out along each arm: shoulder, elbow, wrist, a phase behind each other
			for side in ["l", "r"]:
				var sgn := 1.0 if side == "l" else -1.0
				for k in 3:
					_rot(["shoulder_", "elbow_", "wrist_"][k] + side, Vector3.FORWARD, sgn * 0.35 * sin(beat - 0.9 * k + ph.wave))
		if "step" in moves:
			pelvis_offset.x = 0.07 * am.step * sin(beat * 0.5 + ph.step)
			var lift := maxf(0.0, sin(beat * 0.5 + ph.step))
			feet["l" if lift > 0.0 else "r"] = Vector3(0, 0.05 * absf(sin(beat * 0.5 + ph.step)), 0)
		if "bounce" in moves:
			pelvis_offset.y = -0.045 * am.bounce * (0.5 + 0.5 * cos(beat * 2.0 + ph.bounce))
	_j.pelvis.position = _pelvis_rest() + pelvis_offset
	if has_move_word("gravity"):
		_plant_feet(feet)
	else:
		# a floating figure's legs swing freely (FK) - the statue off its plinth
		for side in ["l", "r"]:
			if feet[side] != Vector3.ZERO:
				_rot("hip_" + side, Vector3.RIGHT, -feet[side].z * 2.0 - feet[side].y * 4.0)
				_rot("knee_" + side, Vector3.RIGHT, feet[side].y * 8.0)

func _pelvis_rest() -> Vector3:
	var p: Vector3 = SKELETON.pelvis[1]
	if not has_move_word("gravity"): p.y += 0.03 / float(_plan.height)
	return p

func _rot(n: String, axis: Vector3, angle: float) -> void:
	var j: Node3D = _j[n]
	j.basis = j.basis * Basis(axis, angle)

## Two-bone IK in the skeleton's space: hip -> knee -> ankle reaching the planted ankle (plus the move's lift and
## stride), the knee bending forward, the foot flat and facing ahead.
func _plant_feet(feet: Dictionary) -> void:
	var l1 := 0.44; var l2 := 0.43
	var pelvis_xf: Transform3D = _j.pelvis.transform
	for side in ["l", "r"]:
		var hip: Node3D = _j["hip_" + side]; var knee: Node3D = _j["knee_" + side]; var ankle: Node3D = _j["ankle_" + side]
		var hip_pos: Vector3 = pelvis_xf * hip.position
		var target: Vector3 = _ankle_home[side] + feet[side]
		var to := target - hip_pos
		var d := clampf(to.length(), 0.05, l1 + l2 - 0.0005)
		var dir := to.normalized()
		var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
		var inner := acos(clampf((l1 * l1 + l2 * l2 - d * d) / (2.0 * l1 * l2), -1.0, 1.0))
		var lateral := dir.cross(Vector3.BACK).normalized() if absf(dir.dot(Vector3.BACK)) < 0.99 else Vector3.RIGHT
		# the hip's frame from the bend's own axis: x = the knee's hinge, y = up the thigh. A shortest-arc rotation
		# would twist the hinge out of the plane that holds the target, and the foot would miss the floor.
		var best := {}
		for sa in [1.0, -1.0]:
			var thigh_dir := dir.rotated(lateral, sa * a)
			var hip_world := Basis(lateral, -thigh_dir, lateral.cross(-thigh_dir))
			var knee_at := hip_pos + thigh_dir * l1
			for sb in [1.0, -1.0]:
				var kb := Basis(Vector3.RIGHT, sb * (PI - inner))
				var err := (knee_at + (hip_world * kb * Vector3.DOWN) * l2).distance_to(target)
				var forward := thigh_dir.z   # the knee goes forward
				if best.is_empty() or err < float(best.err) - 1e-4 or (absf(err - float(best.err)) < 1e-4 and forward > float(best.fwd)):
					best = {"err": err, "fwd": forward, "hip": hip_world, "knee": kb}
		hip.basis = pelvis_xf.basis.inverse() * (best.hip as Basis)
		knee.basis = best.knee
		ankle.basis = (pelvis_xf.basis * hip.basis * knee.basis).inverse()   # the foot flat, facing ahead

## Where an ankle stands, in the skeleton's space (for the bench's planted-feet check).
func ankle_in_skeleton(side: String) -> Vector3:
	return _root.global_transform.affine_inverse() * (_j["ankle_" + side] as Node3D).global_position

# ─── meshes ───────────────────────────────────────────────────────────────────

func _mat(c: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.metallic = metal; m.roughness = rough
	return m

func _ink(finish: bool) -> StandardMaterial3D:
	return _mat(Color("b8913a") if finish else STIJL.INK, 0.6 if finish else 0.1, 0.3)

func _chrome() -> StandardMaterial3D:
	return _mat(Color("c9ccd1"), 0.9, 0.2)

func _glass(c: Color) -> StandardMaterial3D:
	var m := _mat(Color(c.r, c.g, c.b, 0.45), 0.0, 0.1); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _sphere(parent: Node, n: String, r: float, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0; sm.radial_segments = 16; sm.rings = 8
	mi.mesh = sm; mi.material_override = mat; mi.position = at; mi.name = n; parent.add_child(mi, true)
	return mi

func _box(parent: Node, n: String, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.material_override = mat; mi.position = at; mi.name = n; parent.add_child(mi, true)
	return mi

## A slab from a to b (the joint's space), w x depth across; `gap` floats two panels off a core (panel_robot).
func _slab(parent: Node3D, n: String, a: Vector3, b: Vector3, w: float, depth: float, mat: Material, gap: float) -> void:
	var d := b - a; var l := d.length()
	if l < 0.001: return
	var y := d / l
	var x := y.cross(Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	if gap > 0.0:
		for sgn in [-1.0, 1.0]:
			var p := MeshInstance3D.new(); var pb := BoxMesh.new(); pb.size = Vector3(w, l * 0.9, depth * 0.3)
			p.mesh = pb; p.material_override = mat; p.name = n + "_panel"
			p.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5 + z * sgn * (depth * 0.5 + gap)); parent.add_child(p, true)
		var core := MeshInstance3D.new(); var cb := BoxMesh.new(); cb.size = Vector3(w * 0.45, l * 0.95, depth * 0.45)
		core.mesh = cb; core.material_override = _mat(Color("d9d6cf"), 0.3, 0.4); core.name = n + "_core"
		core.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5); parent.add_child(core, true)
		return
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(w, l, depth)
	mi.mesh = bm; mi.material_override = mat; mi.name = n
	mi.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5); parent.add_child(mi, true)

func _rod(parent: Node3D, n: String, a: Vector3, b: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new(); var c := CylinderMesh.new(); c.top_radius = 0.008; c.bottom_radius = 0.008; c.height = 1.0
	mi.mesh = c; mi.material_override = mat; mi.name = n
	var d := b - a; var y := d.normalized(); var x := y.cross(Vector3.BACK).normalized(); var z := x.cross(y)
	mi.transform = Transform3D(Basis(x, y * d.length(), z), (a + b) * 0.5); parent.add_child(mi, true)

## asawa_wire: the bone wound in looping cord.
func _loops(parent: Node3D, n: String, end: Vector3, r: float) -> void:
	var count := maxi(3, int(end.length() / 0.06))
	var y := end.normalized(); var x := y.cross(Vector3.BACK if absf(y.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT).normalized()
	for k in count:
		var ring := MeshInstance3D.new(); var tor := TorusMesh.new(); tor.inner_radius = r; tor.outer_radius = r + 0.006
		tor.rings = 12; tor.ring_segments = 4; ring.mesh = tor; ring.material_override = _mat(Color("8e8a80"), 0.0, 0.8); ring.name = n + "_cord"
		ring.transform = Transform3D(Basis(x, y, x.cross(y)).rotated(x, 0.25 * sin(k * 1.7)), end * (float(k) + 0.5) / float(count))
		parent.add_child(ring, true)

func _helix(r: float, turns: int, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := turns * 16
	for i in n + 1:
		var f := float(i) / float(n); var a := TAU * turns * f
		st.add_vertex(Vector3(cos(a) * r, 0.06 - 0.12 * f, sin(a) * r))
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = mat
	return mi

func _polyhedron(r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = r; sm.height = r * 2.0; sm.radial_segments = 4; sm.rings = 2
	mi.mesh = sm; mi.material_override = mat; mi.name = "Polyhedron"
	return mi

func _flower(parent: Node, at: Vector3) -> void:
	_box(parent, "Stem", Vector3(0.008, 0.1, 0.008), at + Vector3(0, 0.05, 0), _mat(Color("2f7a3e"), 0, 0.7))
	for i in 6:
		var a := TAU * i / 6.0
		_sphere(parent, "Petal", 0.02, at + Vector3(cos(a) * 0.028, 0.1, sin(a) * 0.028), _mat(BAUHAUS[2], 0, 0.6))
	_sphere(parent, "FlowerHeart", 0.015, at + Vector3(0, 0.103, 0), _mat(BAUHAUS[1], 0, 0.6))

## Grown by rewriting F -> F[+F][-F].
func _branch(parent: Node3D, from: Vector3, dir: Vector3, length: float, depth: int, mat: Material) -> void:
	var to := from + dir * length
	var mi := MeshInstance3D.new(); var c := CylinderMesh.new(); c.top_radius = 0.006; c.bottom_radius = 0.009; c.height = 1.0
	mi.mesh = c; mi.material_override = mat; mi.name = "Branch"
	var x := dir.cross(Vector3.BACK if absf(dir.dot(Vector3.BACK)) < 0.95 else Vector3.RIGHT).normalized()
	mi.transform = Transform3D(Basis(x, dir * length, x.cross(dir)), (from + to) * 0.5); parent.add_child(mi, true)
	if depth <= 1:
		_sphere(parent, "Tip", 0.012, to, mat)
		return
	for sgn in [-1.0, 1.0]:
		_branch(parent, to, dir.rotated(x, sgn * 0.5).normalized(), length * 0.7, depth - 1, mat)
