extends Node3D

# @identity
# essence: VERTEX = object_pos + NORMAL * noise(object_pos.xz * noise_scale + t) *
#   height_multiplier — a value-noise field sampled in world XZ, with a torus dipped
#   into it. The ring has no noise of its own; it is a probe held in a field.
# desire: to see coherent noise as something a SURFACE passes through rather than
#   something a surface has, and to be able to withdraw the surface from it
# critical_parameter: readout — how much of the field the ring is allowed to show
#   (relief | plate | none); noise_speed and hue_shift_speed are the clock, and pinning
#   them to 0 is the only way a still of this object means anything
# triggers: nothing — no interaction, no script until now. TIME drives everything: the
#   noise offset advances at noise_speed and the hue wraps every 1.38 s
# emerges: the displacement is three times the tube radius, so the "torus" is a tangle
#   that only becomes a ring again when you take the field away
# needs: nothing [has] — one mesh, one shader
# relationships: the CONTINUOUS-field sibling of [[perlin_noise_terrain]] (a sheet in
#   the same field) and of [[ten_print_maze_3d]] (the 1-bit version of the same idea);
#   shares the `readout` axis word for word with [[perlin_noise]] and [[simplex_noise]]
# truth: the ring is not made of noise. It is a shape that has been left out in it.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02).
#
# This scene had NO SCRIPT AT ALL and no exports of any kind: a TorusMesh, a
# shader, five sub-resource parameters frozen into the .tscn, and six placements
# that were all necessarily identical. To the sweep it was invisible — nothing
# to turn.
#
# Worse, and the reason this promotion is not optional: it could not be
# PHOTOGRAPHED. Everything you see is a function of TIME. noise_speed is 0.935,
# so the displacement field slides almost a full noise unit per second, and
# hue_shift_speed is 0.725, so the surface cycles the entire rainbow every 1.38
# seconds. Two captures of this artifact one second apart are two different
# objects in two different colours. Any sweep run against it before today would
# have measured the wall clock and reported it as a confident bite.
#
#   readout   HOW MUCH OF THE FIELD THE RING IS ALLOWED TO SHOW
#
#     relief   the field as FORM. The noise displaces the surface along its
#              normal by up to three times the tube radius, so the ring is eaten
#              into a tangle and the torus is barely recoverable. THE LEGACY
#              LINEAGE, byte for byte — nothing is written to the material at
#              all on this path.
#     plate    the field as IMAGE. height_multiplier goes to zero: the ring
#              comes back, clean and thin and unmistakably a torus, and the same
#              noise survives only as bright and dark mottling across its
#              surface. Identical sample, identical geometry underneath, and a
#              completely different claim about what you are looking at.
#     none     the field WITHHELD. noise_scale goes to zero as well, so every
#              vertex samples the same point of the field and the surface is one
#              flat tone: the object without its weather. This is the control —
#              the only frame in which you can see what the ring actually is.
#
# ONE WORD, FOUR ARTIFACTS. `readout` is adopted verbatim from perlin_noise and
# simplex_noise (2026-07-29) and is shared with perlin_noise_terrain and
# random_edge_profile. `relief` and `plate` carry the family's exact meaning.
# `column` is the one family value this artifact genuinely CANNOT build — a
# closed surface displaced along its own normal has nowhere to stand a bar — so
# it degrades to `none`, which is already a readout value elsewhere in the
# corpus (line, line_interface, xyz_slider_plate) and is the spelling this
# project uses for an absence.
#
# WHAT IS DELIBERATELY NOT THE AXIS. noise_scale as a grain knob (fine noise vs
# coarse noise) is the obvious second axis and it is a fact about the FIELD, not
# a claim about the object. elongation_factor is the ring's form. And the two
# speeds, which are exported here, are exported as INSTRUMENTS — the fixture
# needs them to stop the clock — not as an axis: a rate is invisible to a still.
#
# NOT TOUCHED: the shipped path. At readout=relief with both speeds at their
# shipped values this script writes nothing, duplicates nothing and frees
# nothing. It returns before it touches the material. Six placements render the
# byte-identical scene they rendered yesterday.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — how much of the field the ring is allowed to show. `relief` is the
## legacy default.
@export_enum("relief", "plate", "none") var readout: String = "relief"

## The allow-list, same spelling and same order as the @export_enum above. An
## unreadable word keeps the legacy default rather than blanking a ring six rooms
## expect to see.
const READOUTS: PackedStringArray = ["relief", "plate", "none"]

## THE CLOCK, exported so it can be stopped. Both defaults are the values frozen into
## noisetorus.tscn's ShaderMaterial and reproduce it exactly. A sweep or a capture MUST
## pin both to 0.0 through dna.fixture, or every frame is a different moment of a
## rainbow cycle that completes in under a second and a half.
@export var noise_speed: float = 0.935
@export var hue_shift_speed: float = 0.725

## The values the .tscn ships. `relief` with both speeds still at these numbers is the
## legacy path and takes the early return in _apply_readout(). The other two are the
## parameters this axis moves, restated so that a rebuild BACK to relief can put them
## where the scene had them — a torus that had been to `plate` and come home must not
## keep plate's flat surface.
const SHIPPED_NOISE_SPEED := 0.935
const SHIPPED_HUE_SPEED := 0.725
const SHIPPED_HEIGHT_MULTIPLIER := 0.2
const SHIPPED_NOISE_SCALE := 3.575

## Untyped on purpose: sweep fixtures set this DIRECTLY pre-_ready with the string
## "false", and a typed bool silently rejects that assignment.
##
## THE FRAMING FIX. MeshInstance3D3 is a PrismMesh floating 7.29 m above the torus,
## wearing a different noise shader (noisePlanet2) — leftover scenery from whenever
## this scene was last opened. Nothing references it and nothing is composed with it,
## but every framing routine in this project fits an artifact by the DIAGONAL of its
## bounding box, and capture_config_sweep._subtree_aabb counts every MeshInstance3D in
## the tree whether or not it is visible. So the box is 7.91 m tall for a 1.2 m object,
## its centre sits 3.84 m above the ring, and the camera backs off to about 30 m: the
## torus renders as a speck in the bottom of the frame. This is the laser_measure trap
## exactly (a 50 m beam around a 14 cm instrument), and hiding the prism does not fix
## it, because the AABB walk ignores visibility.
##
## true (the default, and what every existing placement gets) = the prism stays, exactly
## as shipped. false = it is freed, and the frame is about the torus. NOT removed
## outright, because removing it would change what six placements render today, and the
## rule for that is R1.
var stray_planet = true

## True once _ready has applied once.
var _built: bool = false
## True once anything has been written to the material. After that the legacy early
## return is off for good: a rebuild back to relief has to actively restore what plate
## or none overwrote, and returning early there would leave a flat ring wearing the
## default's name.
var _wrote_material: bool = false


# ── THE PAIR (stand:pair) — N3, 12 September 2026 ───────────────────────────
#
# IS THE RESTLESS THING A FIELD, A SURFACE, OR OUR WAY OF READING IT? The ring
# already answers half of that by itself: noiseTorus.gdshader samples one value
# per point and spends it twice, once as displacement in the vertex stage and
# once as brightness in the fragment stage, at the same coordinate, from the
# same expression. So the staging puts the two spendings side by side on one
# support and lets a visitor compare them.
#
#   stand:none  SHIPPED. One ring, both readings at once, exactly as before.
#   stand:pair  Two rings of the same size on one bench, the same shader, the
#               same noise_scale — the same FIELD — with one showing only the
#               relief and the other only the colour; a marker standing on the
#               same coordinate of both; a plate naming that coordinate, the
#               field's value there and what each reading makes of it; and
#               FREEZE · SAMPLE · AMPLITUDE · FREQUENCY.
#
# WHAT THE PAIR IS FOR. The two readings are NOT equivalent, and the room is
# honest about which one loses: the field runs from -1 to 1, the relief spends
# the whole of it (inward for the negative half) and the colour clamps the
# negative half to black. A visitor reading the mottling is reading a rectified
# field. That is not a bug in the shader; it is what a reading is.
#
# FREEZE stops BOTH clocks. Every TIME in that shader is multiplied by one of
# the two speed uniforms — the displacement offset and the hue rotation — so
# zeroing both really does stop everything, which is the thing Astra's card
# said a single material parameter at zero does not prove.
#
# AMPLITUDE is a reading and FREQUENCY is the field: height_multiplier scales
# what the surface does with the value, noise_scale changes which value is at
# this coordinate at all. The plate says which of the two just moved.
#
# AND NOTHING HERE IS SOLID. The displacement lives in the vertex stage, where
# no collider can see it, and this scene ships no collision shape at all: the
# corrugation you can see is not a corrugation you could touch.
@export_enum("none", "pair") var stand: String = "none"

const PAIR_GAP: float = 1.30
const PAIR_H: float = 1.22          # the rings' centre height, a standing eye
const PAIR_INNER: float = 0.18    # a tube of radius 0.14: wide enough that the relief
const PAIR_OUTER: float = 0.46    # corrugates the surface instead of folding it through itself
const PAIR_BENCH_W: float = 2.60
const PAIR_BENCH_D: float = 0.90
const PAIR_BENCH_H: float = 0.78
# THE SHIPPED NUMBERS ARE FOR THE SHIPPED RING. height_multiplier 0.2 and noise_scale
# 3.575 were set for a torus of radius ~1.8: on the pair's 0.42 m rings that amplitude
# is half the radius (the ring photographs as a blob) and that frequency puts barely
# one noise cell across the whole ring (nothing to see). Both are scaled to this body,
# which is the same fault the trio in Noise_Columns paid a run for.
const PAIR_AMPS: Array = [0.0, 0.01, 0.02, 0.04]
const PAIR_FREQS: Array = [7.0, 14.0, 24.0]
const PAIR_SAMPLES: Array = [0.0, 0.9, 1.8, 2.7, 3.6, 4.5]   # radians round the ring

var _pair_root: Node3D = null
var _rings: Array = []              # [{kind, mesh, mat, marker}]
var _pair_readout: Label3D = null
var _pair_frozen: bool = false
var _sample_i: int = 0
var _amp_i: int = 2                 # PAIR_AMPS[2] is the shipped 0.2
var _freq_i: int = 1                # PAIR_FREQS[1] is the shipped 3.575
var _pair_time: float = 0.0
var _last_touched: String = "nothing yet"


func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config call_deferred, i.e. after this — so the meta read happens here.
	_read_meta_overrides()
	_apply_stray()
	if stand == "pair":
		_build_pair()
		_built = true
		set_process(true)
		return
	_apply_readout()
	_built = true


func _torus() -> MeshInstance3D:
	return get_node_or_null("MeshInstance3D") as MeshInstance3D


## Free the debris, if asked. queue_free rather than hide: the AABB walk that decides
## framing counts meshes, not visible meshes, and `visible = false` would leave the
## camera exactly where it was. Deferred is fine — every framing routine in this project
## measures after a settle, long after the node has left the tree.
func _apply_stray() -> void:
	if _is_truthy(stray_planet):
		return
	var prism: Node = get_node_or_null("MeshInstance3D3")
	if prism:
		remove_child(prism)          # leaves the tree synchronously
		prism.queue_free()


## Write the readout into the shader — or, on the legacy path, write nothing.
##
## THE MATERIAL IS SHARED. A ShaderMaterial declared as a [sub_resource] in a .tscn is
## NOT resource_local_to_scene, so all six noisetorus placements in a map hold the same
## Material object. Writing a parameter straight onto it would re-skin every ring in the
## building from one map token. So the material is duplicated the moment this artifact
## has anything to say, and left alone when it has not.
func _apply_readout() -> void:
	var mi: MeshInstance3D = _torus()
	if mi == null:
		return
	var legacy: bool = (readout == "relief"
		and is_equal_approx(noise_speed, SHIPPED_NOISE_SPEED)
		and is_equal_approx(hue_shift_speed, SHIPPED_HUE_SPEED))
	if legacy and not _wrote_material:
		return                       # the shipped scene, untouched, not even duplicated
	var mat: ShaderMaterial = mi.material_override as ShaderMaterial
	if mat == null:
		return
	if not mat.resource_local_to_scene:
		mat = mat.duplicate() as ShaderMaterial
		mat.resource_local_to_scene = true
		mi.material_override = mat
	_wrote_material = true
	mat.set_shader_parameter("noise_speed", noise_speed)
	mat.set_shader_parameter("hue_shift_speed", hue_shift_speed)
	match readout:
		"plate":
			# The field stops being form and becomes surface: no displacement, the
			# same sample read off as brightness. noise_scale is restated so that
			# arriving here from `none` brings the mottling back.
			mat.set_shader_parameter("height_multiplier", 0.0)
			mat.set_shader_parameter("noise_scale", SHIPPED_NOISE_SCALE)
		"none":
			# Every vertex samples the field at one point, so there is no variation
			# left to displace or to shade with: the ring in one flat tone. The tone
			# itself is whatever the shader's hash of the origin comes to — this is
			# the control frame, and what it is FOR is having no weather in it.
			mat.set_shader_parameter("height_multiplier", 0.0)
			mat.set_shader_parameter("noise_scale", 0.0)
		_:
			# relief — the shipped numbers, restated. On the first pass this writes
			# what is already there; on a rebuild out of plate or none it is the
			# restore, and it is the only reason those two values are consts.
			mat.set_shader_parameter("height_multiplier", SHIPPED_HEIGHT_MULTIPLIER)
			mat.set_shader_parameter("noise_scale", SHIPPED_NOISE_SCALE)


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

## Accepts a real bool, an int, or the strings a map token and a sweep fixture carry.
func _is_truthy(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _read_meta_overrides() -> void:
	if has_meta("config_readout"):
		var v: String = str(get_meta("config_readout")).strip_edges().to_lower()
		if READOUTS.has(v):
			readout = v
		elif v != "":
			push_warning("noisetorus: unknown readout '%s' — keeping '%s'" % [v, readout])
	if has_meta("config_noise_speed"):
		noise_speed = float(str(get_meta("config_noise_speed")))
	if has_meta("config_hue_shift_speed"):
		hue_shift_speed = float(str(get_meta("config_hue_shift_speed")))
	if has_meta("config_stray_planet"):
		stray_planet = _is_truthy(get_meta("config_stray_planet"))
	if has_meta("config_stand"):
		var sv: String = str(get_meta("config_stand")).strip_edges().to_lower()
		stand = "pair" if sv in ["pair", "two", "compare", "bench"] else "none"


## Guarded like prng_crank_machine's: an unchanged readout touches nothing and says
## nothing, so curation_station's blanket apply_grid_config({"emissive": false}) cannot
## trigger a rebuild. This scene had no configuration method at all before today, so
## every token a map wrote on a noisetorus placement was parsed, logged and dropped.
func apply_grid_config(config: Dictionary) -> void:
	var before_readout: String = readout
	var before_noise: float = noise_speed
	var before_hue: float = hue_shift_speed
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                       # nothing applied yet; _ready will use these values
	_apply_stray()
	if (readout == before_readout
			and is_equal_approx(noise_speed, before_noise)
			and is_equal_approx(hue_shift_speed, before_hue)):
		return
	_apply_readout()

# ═════════════════════════════════════════════════════════════════════════════
# THE PAIR — stand:pair. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════════════

## The shader's own noise, in GDScript, line for line. The plate has to be able to
## say what the field is AT a coordinate, and the only honest source for that is
## the same expression the shader uses. Ported, not approximated:
##
##   p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
##   return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
##
## The GPU computes this in 32-bit and this runs in 64-bit, so the last digits of
## a very chaotic hash will differ. What the plate claims is the FIELD's value at
## a coordinate, which is a definition, not a screenshot.
func _hash2(p: Vector2) -> float:
	var q: Vector2 = (p * 0.3183099 + Vector2(0.71, 0.113))
	q = Vector2(q.x - floor(q.x), q.y - floor(q.y)) * 50.0
	var v: float = q.x * q.y * (q.x + q.y)
	return -1.0 + 2.0 * (v - floor(v))


func _noise2(p: Vector2) -> float:
	var i := Vector2(floor(p.x), floor(p.y))
	var f := Vector2(p.x - i.x, p.y - i.y)
	var u := Vector2(f.x * f.x * (3.0 - 2.0 * f.x), f.y * f.y * (3.0 - 2.0 * f.y))
	var a: float = _hash2(i + Vector2(0.0, 0.0))
	var b: float = _hash2(i + Vector2(1.0, 0.0))
	var c: float = _hash2(i + Vector2(0.0, 1.0))
	var d: float = _hash2(i + Vector2(1.0, 1.0))
	return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y)


## The field at an object-space point, at a time. This is the shader's
## `vec2(object_pos.x * noise_scale, object_pos.z * noise_scale) + time_offset`.
func field_value(x: float, z: float, t: float) -> float:
	var scale: float = float(PAIR_FREQS[_freq_i])
	var off: float = fmod(t, 3600.0) * noise_speed
	return _noise2(Vector2(x * scale + off, z * scale + off))


## What each reading makes of that value. The relief spends all of it; the colour
## clamps the negative half to black, because ALBEDO cannot go below zero.
func relief_of(value: float) -> float:
	return value * float(PAIR_AMPS[_amp_i])


func colour_of(value: float) -> float:
	return maxf(value, 0.0)


func _sample_point() -> Vector3:
	var a: float = float(PAIR_SAMPLES[_sample_i])
	var r: float = (PAIR_INNER + PAIR_OUTER) * 0.5 + (PAIR_OUTER - PAIR_INNER) * 0.5
	return Vector3(cos(a) * r, 0.0, sin(a) * r)


func _build_pair() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var mi: MeshInstance3D = _torus()
	var shader: Shader = null
	if mi != null and mi.material_override is ShaderMaterial:
		shader = (mi.material_override as ShaderMaterial).shader
		mi.visible = false          # the shipped ring steps aside; the pair is the exhibit
	_pair_root = Node3D.new()
	_pair_root.name = "Pair"
	add_child(_pair_root)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.58, 0.57, 0.55)
	stone.roughness = 0.9
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85

	var body := StaticBody3D.new()
	body.name = "Bench"
	_pair_root.add_child(body)
	body.add_child(HangarKit.box(Vector3(0, PAIR_BENCH_H - 0.02, 0), Vector3(PAIR_BENCH_W, 0.04, PAIR_BENCH_D), stone))
	body.add_child(HangarKit.box(Vector3(0, (PAIR_BENCH_H - 0.04) * 0.5, 0), Vector3(PAIR_BENCH_W * 0.9, PAIR_BENCH_H - 0.04, PAIR_BENCH_D * 0.6), stone))
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(PAIR_BENCH_W, PAIR_BENCH_H, PAIR_BENCH_D)
	col.shape = shape
	col.position = Vector3(0, PAIR_BENCH_H * 0.5, 0)
	body.add_child(col)

	_rings.clear()
	for entry in [["relief", -PAIR_GAP * 0.5, "AS RELIEF · the field moves the surface"], ["colour", PAIR_GAP * 0.5, "AS COLOUR · the field lights the surface"]]:
		var kind: String = entry[0]
		var x: float = entry[1]
		var holder := Node3D.new()
		holder.name = "Ring_%s" % kind
		holder.position = Vector3(x, PAIR_H, 0.0)
		_pair_root.add_child(holder)
		var ring := MeshInstance3D.new()
		ring.name = "Torus"
		var tm := TorusMesh.new()
		tm.inner_radius = PAIR_INNER
		tm.outer_radius = PAIR_OUTER
		# the relief is sampled per VERTEX, so the mesh has to out-resolve the field or the
		# corrugation aliases into spikes (measured: 13 noise cells across 48 segments
		# photographed as crumpled paper)
		tm.rings = 96
		tm.ring_segments = 40
		ring.mesh = tm
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.resource_local_to_scene = true
		ring.material_override = mat
		holder.add_child(ring)
		# a post, so the ring stands rather than floats
		var post: MeshInstance3D = HangarKit.box(Vector3(x, (PAIR_H - PAIR_OUTER + PAIR_BENCH_H) * 0.5, 0.0),
				Vector3(0.06, PAIR_H - PAIR_OUTER - PAIR_BENCH_H + 0.1, 0.06), stone)
		post.name = "Post_%s" % kind
		_pair_root.add_child(post)
		# the marker: one on each ring, at the same coordinate of the same field
		var marker := MeshInstance3D.new()
		marker.name = "Marker"
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.07
		marker.mesh = sm
		marker.material_override = HangarKit.emissive(Color(1.0, 0.95, 0.55), 2.4)
		holder.add_child(marker)
		var cap: MeshInstance3D = HangarKit.stencil(entry[2], Vector2(0.92, 0.040), Color(0.16, 0.17, 0.19))
		if cap:
			cap.name = "Caption_%s" % kind
			cap.position = Vector3(x, PAIR_BENCH_H + 0.09, PAIR_BENCH_D * 0.5 - 0.03)
			_pair_root.add_child(cap)
		_rings.append({"kind": kind, "mesh": ring, "mat": mat, "marker": marker, "holder": holder})

	var case_root := Node3D.new()
	case_root.name = "Readout"
	case_root.set_meta("em_local_instrument", true)
	case_root.position = Vector3(-0.50, PAIR_BENCH_H + 0.30, PAIR_BENCH_D * 0.5 + 0.02)
	case_root.rotation_degrees = Vector3(-18, 0, 0)
	_pair_root.add_child(case_root)
	case_root.add_child(HangarKit.box(Vector3.ZERO, Vector3(1.22, 0.28, 0.014), dark))
	_pair_readout = Label3D.new()
	_pair_readout.name = "Text"
	_pair_readout.pixel_size = 0.00092
	_pair_readout.font_size = 17
	_pair_readout.line_spacing = 0.5
	_pair_readout.modulate = Color(0.88, 0.94, 1.0)
	_pair_readout.outline_size = 3
	_pair_readout.outline_modulate = Color(0, 0, 0, 1)
	_pair_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_pair_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_pair_readout.position = Vector3(-0.585, 0.128, 0.010)
	case_root.add_child(_pair_readout)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		var panel: Node3D = RackTpl.create_panel("", [
			[{"type": "button", "label": "FREEZE"}, {"type": "button", "label": "SAMPLE"}],
			[{"type": "button", "label": "AMPLITUDE"}, {"type": "button", "label": "FREQUENCY"}],
		], true)
		panel.name = "Panel"
		panel.set_meta("em_local_instrument", true)
		panel.position = Vector3(0.92, PAIR_BENCH_H + 0.24, PAIR_BENCH_D * 0.5 + 0.08)
		panel.rotation_degrees = Vector3(-26, 0, 0)
		panel.scale = Vector3(1.4, 1.4, 1.4)
		_pair_root.add_child(panel)
		var actions := {"Btn_0": func(): toggle_pair_freeze(), "Btn_1": func(): next_sample(), "Btn_2": func(): cycle_amplitude(), "Btn_3": func(): cycle_frequency()}
		for btn_name in actions.keys():
			var btn: Node = panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())

	_apply_pair_params()
	_place_markers()
	_update_pair_readout()


## Both rings get the same field and differ in what they are allowed to show.
func _apply_pair_params() -> void:
	for r in _rings:
		var mat: ShaderMaterial = r["mat"]
		if mat == null:
			continue
		mat.set_shader_parameter("noise_scale", float(PAIR_FREQS[_freq_i]))
		mat.set_shader_parameter("height_multiplier", float(PAIR_AMPS[_amp_i]))
		mat.set_shader_parameter("elongation_factor", 1.0)
		mat.set_shader_parameter("noise_speed", 0.0 if _pair_frozen else noise_speed)
		mat.set_shader_parameter("hue_shift_speed", 0.0 if _pair_frozen else hue_shift_speed)
		mat.set_shader_parameter("show_relief", 1.0 if str(r["kind"]) == "relief" else 0.0)
		mat.set_shader_parameter("show_colour", 1.0 if str(r["kind"]) == "colour" else 0.0)


## The marker stands on the surface at the sampled coordinate — on the relief ring
## it rides the displacement, so the same coordinate is visibly in two states.
func _place_markers() -> void:
	var p: Vector3 = _sample_point()
	var v: float = field_value(p.x, p.z, _pair_time)
	for r in _rings:
		var marker: Node3D = r["marker"]
		if marker == null or not is_instance_valid(marker):
			continue
		var out: float = relief_of(v) if str(r["kind"]) == "relief" else 0.0
		var dir: Vector3 = Vector3(p.x, 0.0, p.z).normalized()
		marker.position = Vector3(p.x, 0.0, p.z) + dir * (out + 0.04)


func _process(delta: float) -> void:
	if stand != "pair":
		return
	if not _pair_frozen:
		_pair_time += delta
		_place_markers()
		if fmod(_pair_time, 0.25) < delta:
			_update_pair_readout()


func _update_pair_readout() -> void:
	if _pair_readout == null or not is_instance_valid(_pair_readout):
		return
	var p: Vector3 = _sample_point()
	var v: float = field_value(p.x, p.z, _pair_time)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("one field, two readings%s · amplitude %.2f · frequency %.3f" % [
		("  FROZEN at t %.2f s" % _pair_time) if _pair_frozen else "", float(PAIR_AMPS[_amp_i]), float(PAIR_FREQS[_freq_i])])
	lines.append("sample  x %+.3f  z %+.3f   field value %+.3f" % [p.x, p.z, v])
	lines.append("relief  %+.3f m of surface" % relief_of(v))
	if v < 0.0:
		lines.append("colour  black — the reading clamps at zero and loses this half")
	else:
		lines.append("colour  brightness %.3f of the hue" % colour_of(v))
	lines.append("last touched: %s · no collider anywhere: the relief is not a surface you can hit" % _last_touched)
	_pair_readout.text = "\n".join(lines)


## Stop both clocks. Every TIME in the shader is multiplied by one of these two.
func toggle_pair_freeze() -> void:
	if stand != "pair":
		return
	_pair_frozen = not _pair_frozen
	_last_touched = "FREEZE"
	_apply_pair_params()
	_update_pair_readout()


func next_sample() -> void:
	if stand != "pair":
		return
	_sample_i = (_sample_i + 1) % PAIR_SAMPLES.size()
	_last_touched = "SAMPLE"
	_place_markers()
	_update_pair_readout()


## A READING. The value at the coordinate does not move.
func cycle_amplitude() -> void:
	if stand != "pair":
		return
	_amp_i = (_amp_i + 1) % PAIR_AMPS.size()
	_last_touched = "AMPLITUDE (a reading: the field did not move)"
	_apply_pair_params()
	_place_markers()
	_update_pair_readout()


## THE FIELD. Another value stands at this coordinate now.
func cycle_frequency() -> void:
	if stand != "pair":
		return
	_freq_i = (_freq_i + 1) % PAIR_FREQS.size()
	_last_touched = "FREQUENCY (the field itself: another value is here now)"
	_apply_pair_params()
	_place_markers()
	_update_pair_readout()


## The pair as the room can read it.
func pair_state() -> Dictionary:
	var p: Vector3 = _sample_point()
	var v: float = field_value(p.x, p.z, _pair_time)
	var rings: Array = []
	for r in _rings:
		var mat: ShaderMaterial = r["mat"]
		var mesh: MeshInstance3D = r["mesh"]
		rings.append({
			"kind": r["kind"],
			"show_relief": float(mat.get_shader_parameter("show_relief")) if mat != null else -1.0,
			"show_colour": float(mat.get_shader_parameter("show_colour")) if mat != null else -1.0,
			"noise_scale": float(mat.get_shader_parameter("noise_scale")) if mat != null else -1.0,
			"height_multiplier": float(mat.get_shader_parameter("height_multiplier")) if mat != null else -1.0,
			"noise_speed": float(mat.get_shader_parameter("noise_speed")) if mat != null else -1.0,
			"hue_shift_speed": float(mat.get_shader_parameter("hue_shift_speed")) if mat != null else -1.0,
			"shader": str(mat.shader.resource_path).get_file() if mat != null and mat.shader != null else "-",
			"marker_at": [snappedf((r["marker"] as Node3D).position.x, 0.001), snappedf((r["marker"] as Node3D).position.y, 0.001), snappedf((r["marker"] as Node3D).position.z, 0.001)],
			"aabb": snappedf((mesh.mesh as TorusMesh).outer_radius, 0.001) if mesh != null else -1.0,
		})
	return {
		"stand": stand, "frozen": _pair_frozen, "time": snappedf(_pair_time, 0.01),
		"sample_index": _sample_i, "sample_at": [snappedf(p.x, 0.001), snappedf(p.z, 0.001)],
		"value": snappedf(v, 0.0001), "relief": snappedf(relief_of(v), 0.0001), "colour": snappedf(colour_of(v), 0.0001),
		"amplitude": float(PAIR_AMPS[_amp_i]), "frequency": float(PAIR_FREQS[_freq_i]),
		"amp_index": _amp_i, "freq_index": _freq_i, "last_touched": _last_touched,
		"rings": rings,
	}
