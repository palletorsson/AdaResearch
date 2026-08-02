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


func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config call_deferred, i.e. after this — so the meta read happens here.
	_read_meta_overrides()
	_apply_stray()
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
	print("[Noisetorus] Config applied — readout=%s" % [readout])
