extends Node3D

# @identity
# essence: VERTEX = object_pos + NORMAL * noise(object_pos.xz * noise_scale + t) *
#   height_multiplier — the same value-noise field as noisetorus, with a 30 m
#   flip-faced sphere dipped into it. A dome-scale probe held in a field.
# desire: to stand under (or before) a sky-sized surface and see coherent noise
#   as weather passing through it rather than texture painted on it
# critical_parameter: readout — how much of the field the sphere is allowed to
#   show (relief | plate | none); noise_speed and hue_shift_speed are the clock,
#   and pinning them to 0 is the only way a still of this object means anything
# triggers: nothing — no interaction, no script until now. TIME drives all of it:
#   the field slides at noise_speed and the hue wraps every 20 s
# emerges: at noise_scale 48.39 the displacement is speckle-frequency, so relief
#   reads as a ball of needles — the field is FINE here where the torus's is broad
# needs: nothing [has] — one mesh, one shader (noisePlanet2, shared with the
#   prism that floats over noisetorus)
# relationships: the sphere sibling of [[noisetorus]] — same shader family, same
#   scriptless birth, same promotion, same axis word for word; shares `readout`
#   with [[perlin_noise]] and [[simplex_noise]]
# truth: the sphere is not made of noise. It is a shape that has been left out in it.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06) — adopted VERBATIM from noisetorus
# (2026-08-02), the same scene shape one folder over: a scriptless root (this
# one is even still NAMED "Noisetorus" in the .tscn), one MeshInstance3D, one
# ShaderMaterial frozen into the file, and every parameter a function of TIME.
# Two captures of this artifact seconds apart are two different objects in two
# different colours; a sweep run against it before today would have measured
# the wall clock and called it a bite.
#
#   readout   HOW MUCH OF THE FIELD THE SPHERE IS ALLOWED TO SHOW
#
#     relief   the field as FORM. The noise displaces every vertex along its
#              normal at speckle frequency (noise_scale 48.39 across a half-unit
#              object radius), so the sphere is a spined, needled mass — radius
#              swinging ±40% at grain finer than a degree. THE LEGACY LINEAGE,
#              byte for byte: on this path with the speeds at their shipped
#              values, nothing is written to the material at all.
#     plate    the field as IMAGE. height_multiplier goes to zero: the sphere
#              comes back perfectly round, and the same sample survives only as
#              fine bright/dark mottling across the surface. Identical field,
#              identical geometry underneath, a different claim about what you
#              are looking at.
#     none     the field WITHHELD. noise_scale goes to zero too, so every vertex
#              samples one point and the sphere is a single flat tone — the
#              control frame, the object without its weather.
#
# `column` is the family value a closed surface cannot build (nowhere to stand a
# bar), exactly as noisetorus records — so it is not declared, and an unknown
# word keeps the default.
#
# NOT THE AXIS: noise_scale as a grain knob is a fact about the FIELD; the two
# speeds are exported as INSTRUMENTS for the fixture (a rate is invisible to a
# still); elongation_factor is the sphere's form and stays frozen in the .tscn.
#
# NOT TOUCHED: the shipped path. At readout=relief with both speeds at their
# shipped values this script writes nothing and duplicates nothing — the two
# placements render the byte-identical scene they rendered yesterday.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — how much of the field the sphere is allowed to show. `relief` is
## the legacy default.
@export_enum("relief", "plate", "none") var readout: String = "relief"

## The allow-list, same spelling and order as the @export_enum above. An unknown
## word keeps the legacy default rather than flattening a dome two rooms expect.
const READOUTS: PackedStringArray = ["relief", "plate", "none"]

## THE CLOCK, exported so it can be stopped. Both defaults are the values frozen
## into noisesphere.tscn's ShaderMaterial and reproduce it exactly. A sweep MUST
## pin both to 0.0 through dna.fixture, or every frame is a different moment of
## a hue cycle that completes in 20 seconds.
@export var noise_speed: float = 0.05
@export var hue_shift_speed: float = 0.05

## The values the .tscn ships, restated so a rebuild BACK to relief can restore
## what plate or none overwrote.
const SHIPPED_NOISE_SPEED := 0.05
const SHIPPED_HUE_SPEED := 0.05
const SHIPPED_HEIGHT_MULTIPLIER := 0.2
const SHIPPED_NOISE_SCALE := 48.39

## True once _ready has applied once.
var _built: bool = false
## True once anything has been written to the material — after that, the legacy
## early return is off for good and relief must actively restore its numbers.
var _wrote_material: bool = false


func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config deferred (after this), so the meta read happens here.
	_read_meta_overrides()
	_apply_readout()
	_built = true


func _sphere() -> MeshInstance3D:
	return get_node_or_null("MeshInstance3D4") as MeshInstance3D


## Write the readout into the shader — or, on the legacy path, write nothing.
##
## THE MATERIAL IS SHARED. The ShaderMaterial is a [sub_resource] of the .tscn
## and is NOT resource_local_to_scene, so every noisesphere placement in a map
## holds the same Material object. It is duplicated the moment this artifact has
## anything to say, and left alone when it has not.
func _apply_readout() -> void:
	var mi: MeshInstance3D = _sphere()
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
			# No displacement; the same sample read off as brightness. noise_scale
			# is restated so that arriving here from `none` brings the mottling back.
			mat.set_shader_parameter("height_multiplier", 0.0)
			mat.set_shader_parameter("noise_scale", SHIPPED_NOISE_SCALE)
		"none":
			# One sample for every vertex: the sphere in one flat tone. What this
			# frame is FOR is having no weather in it.
			mat.set_shader_parameter("height_multiplier", 0.0)
			mat.set_shader_parameter("noise_scale", 0.0)
		_:
			# relief — the shipped numbers, restated; on a rebuild out of plate or
			# none this is the restore.
			mat.set_shader_parameter("height_multiplier", SHIPPED_HEIGHT_MULTIPLIER)
			mat.set_shader_parameter("noise_scale", SHIPPED_NOISE_SCALE)


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

func _read_meta_overrides() -> void:
	if has_meta("config_readout"):
		var v: String = str(get_meta("config_readout")).strip_edges().to_lower()
		if READOUTS.has(v):
			readout = v
		elif v != "":
			push_warning("noisesphere: unknown readout '%s' — keeping '%s'" % [v, readout])
	if has_meta("config_noise_speed"):
		noise_speed = float(str(get_meta("config_noise_speed")))
	if has_meta("config_hue_shift_speed"):
		hue_shift_speed = float(str(get_meta("config_hue_shift_speed")))


## This scene had no script at all before today, so every token a map wrote on a
## noisesphere placement was parsed, logged and dropped. Guarded: an unchanged
## readout touches nothing, so curation_station's blanket {"emissive": false}
## cannot force a material duplicate.
func apply_grid_config(config: Dictionary) -> void:
	var before_readout: String = readout
	var before_noise: float = noise_speed
	var before_hue: float = hue_shift_speed
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                       # nothing applied yet; _ready will use these values
	if (readout == before_readout
			and is_equal_approx(noise_speed, before_noise)
			and is_equal_approx(hue_shift_speed, before_hue)):
		return
	_apply_readout()
