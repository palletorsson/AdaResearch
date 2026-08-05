# petri_dish_worms.gd
## Simulates oscillating sine worms in a petri dish.
## Each worm follows a random walk with sinusoidal lateral oscillation,
## bouncing off the dish boundary to stay contained.
## Key parameters: num_worms sets population, oscillation_speed/amplitude
## control the sine wave, worm_speed sets forward crawling rate.
extends Node3D

class_name PetriDishWorms

## Number of worms in the dish (1–30)

# @identity
# essence: worm_segment[i].offset = amplitude * sin(oscillation_speed * t + i * phase_per_segment)
# desire: Watch tiny worms wriggle in a petri dish, their bodies undulating with traveling sine waves
# critical_parameter: oscillation_speed — controls the frequency of the sinusoidal body wave
# triggers: time drives phase-offset sine displacement along each worm body segment
# emerges: lifelike locomotion from pure sine wave propagation through a chain of segments
# needs: VR sliders for speed/count [has], observation [has]
# relationships: depends on phase-offset sine animation; contrasts with dna_specimen (motile vs static biology); unlocks biological wave locomotion
#   Kin on the `assay` axis to the softbody benches (abject_bench, becoming_bench, membrane_bench
#   and eleven more) — fourteen artifacts already ask what apparatus a specimen is surrounded by,
#   and a petri dish is the oldest member of that question even though it joined the word last.
# truth: A worm moves by passing a sine wave through its body — locomotion is traveling oscillation.
#
# DNA AXIS — assay: what the dish is surrounded by, and therefore what kind of claim it is making.
#   The five rungs are taken character for character from the bench family. The worms are NOT
#   routed through it: every rung spawns the same population with the same colours and the same
#   sine, because a variant that changed the specimen would be changing the answer rather than the
#   showing. The apparatus is added AROUND the dish.
# emerges: `control` is the rung that argues hardest — a second, identical, EMPTY dish standing
#   beside the first turns a thing you are watching into an experiment you could disagree with.

@export_range(1, 30) var num_worms: int = 8
## Segments per worm body — higher values produce smoother curves (2–50)
@export_range(2, 50) var worm_length: int = 20
## Forward crawling speed in units per second (0.01–2.0)
@export_range(0.01, 2.0, 0.01) var worm_speed: float = 0.3
## Lateral sine oscillation frequency in Hz (0.1–10.0)
@export_range(0.1, 10.0, 0.1) var oscillation_speed: float = 1.5
## Lateral oscillation width in meters (0.001–0.1)
@export_range(0.001, 0.1, 0.001) var oscillation_amplitude: float = 0.02
## Half-width of each worm ribbon in meters (0.001–0.02)
@export_range(0.001, 0.02, 0.001) var worm_radius: float = 0.012

## Radius of the petri dish in meters (0.05–0.5)
@export_range(0.05, 0.5, 0.01) var dish_radius: float = 0.15
## Height of the dish wall in meters (0.005–0.1)
@export_range(0.005, 0.1, 0.005) var dish_height: float = 0.02
## Color of the agar growth medium
@export var medium_color: Color = Color(0.9, 0.85, 0.7, 0.4)

## AXIS — WHAT SURROUNDS THE SPECIMEN, and so what kind of claim the dish is making. Adopted
## word for word (and value for value) from the softbody bench family, where fourteen artifacts
## already carry it; a private synonym here would have split one question across two vocabularies
## for no gain. Every rung builds under a single Assay node appended after the worms, so the
## shipped tree above it is untouched and auto-grounding — which only reads the root's DIRECT
## children — cannot see any of it.
##
##   none     the bare 0.16 m dish on nothing, the shipped look, 5 rooms, byte for byte
##   gauge    a 0.22 m graduated post standing 0.30 m to the left with eight tick bars, a
##            cantilever arm reaching back over the agar at 0.20 m and a stylus dropping from
##            its end to 2 cm above the culture: the dish is now being MEASURED
##   control  a second dish — same glass, same rim, same agar, no worms — standing 0.40 m to
##            the right. One dish is an observation; two dishes are an experiment
##   chart    a 0.42 x 0.26 m plate standing behind the dish at z = -0.30 carrying a plotted
##            growth curve (a fixed logistic, drawn as a ribbon, no dice involved) over a
##            ruled grid: the dish is now REPORTING
##   vitrine  four glass walls and a lid, 0.42 x 0.30 x 0.42, enclosing the dish on a shallow
##            plinth: the culture stops being live work and becomes a thing on display
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"

## Allow-list. An unrecognised token falls back to the bare dish rather than half an apparatus.
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Seed for worm spawning and for the random turns worms take while crawling. -1 (the default)
## draws from the global stream exactly as before — same calls, in the same order, so a shipped
## dish is byte-identical to the one that shipped yesterday.
##
## NOT AN AXIS. It exists because this artifact draws SIX unseeded numbers per worm at spawn
## (position angle, radius, heading, phase, speed jitter, hue) and one more per worm per frame
## while it crawls. Without it, five sweep frames are five different populations in five
## different colours, and the critic would read that noise as a confident BITE on whatever axis
## happened to be varying. Set it non-negative and the same eight worms come back every time,
## which is the precondition for `assay` being measurable at all.
@export var spawn_seed: int = -1
var _rng: RandomNumberGenerator = null

# Assay apparatus. Null on the legacy default — the node is not even created.
var _assay_root: Node3D

var _worms: Array[Dictionary] = []
var _worm_meshes: Array[MeshInstance3D] = []
var _worm_ims: Array[ImmediateMesh] = []
var _time: float = 0.0
var _speed_scale: float = 1.0

var _speed_slider: Node = null

@onready var dish: MeshInstance3D = $Dish
@onready var rim: MeshInstance3D = $Rim
@onready var medium: MeshInstance3D = $Medium
@onready var worm_container: Node3D = $WormContainer

## Set at the end of _ready. apply_grid_config refuses to tear anything down before it is
## true, so a caller that hands the dict over by hand cannot spawn a second population on
## top of the first.
var _built: bool = false

func _ready() -> void:
	_read_dna()
	_setup_dish()
	_spawn_worms()
	_setup_controls()
	# Appended LAST so every legacy child index and position above it is untouched, and so a
	# rung that wants to enclose the dish can see the finished dish.
	_build_assay()
	_built = true


## The grid writes config_<key> onto the artifact ROOT before add_child and only calls
## apply_grid_config deferred, i.e. AFTER _ready. Reading the metadata here means a token
## that asks for an apparatus builds it once, instead of building the bare dish and then
## tearing it down a frame later. A bare token sets no metadata and reaches nothing.
func _read_dna() -> void:
	if has_meta("config_spawn_seed"):
		spawn_seed = int(str(get_meta("config_spawn_seed")))
	if has_meta("config_assay"):
		var word: String = str(get_meta("config_assay")).strip_edges().to_lower()
		if ASSAYS.has(word):
			assay = word


## The two draws this artifact makes. At spawn_seed = -1 both fall straight through to the
## global functions the artifact has always called, in the same order and the same count, so
## the shipped dish is unchanged down to the hue of the eighth worm.
func _rf() -> float:
	if spawn_seed < 0:
		return randf()
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = spawn_seed
	return _rng.randf()


func _rf_range(from_v: float, to_v: float) -> float:
	if spawn_seed < 0:
		return randf_range(from_v, to_v)
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = spawn_seed
	return _rng.randf_range(from_v, to_v)

## Applies glass and agar materials to the dish, rim, and medium meshes.
func _setup_dish() -> void:
	if dish:
		var dish_mat = StandardMaterial3D.new()
		dish_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.2)
		dish_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dish_mat.roughness = 0.0
		dish_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		dish.material_override = dish_mat

	if rim:
		var rim_mat = StandardMaterial3D.new()
		rim_mat.albedo_color = Color(0.95, 0.97, 1.0, 0.15)
		rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rim_mat.roughness = 0.0
		rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		rim.material_override = rim_mat

	if medium:
		var medium_mat = StandardMaterial3D.new()
		medium_mat.albedo_color = medium_color
		medium_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		medium.material_override = medium_mat

## Creates worm simulation data and pre-allocates reusable ImmediateMesh instances.
func _spawn_worms() -> void:
	if not worm_container:
		worm_container = Node3D.new()
		worm_container.name = "WormContainer"
		add_child(worm_container)

	var worm_mat = StandardMaterial3D.new()
	worm_mat.vertex_color_use_as_albedo = true
	worm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	worm_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	worm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_worms.resize(num_worms)
	_worm_meshes.resize(num_worms)
	_worm_ims.resize(num_worms)

	for i in range(num_worms):
		var angle = _rf() * TAU
		var dist = _rf() * dish_radius * 0.7
		var start_pos = Vector3(cos(angle) * dist, 0.015, sin(angle) * dist)

		var dir_angle = _rf() * TAU
		var direction = Vector3(cos(dir_angle), 0, sin(dir_angle))

		var phase = _rf() * TAU

		# Varied worm hues: pinks, oranges, greens for contrast with agar
		var hue = _rf_range(0.0, 0.4)
		var worm_color = Color.from_hsv(hue, 0.8, 1.0)

		_worms[i] = {
			"position": start_pos,
			"direction": direction,
			"phase": phase,
			"speed": worm_speed * _rf_range(0.7, 1.3),
			"color": worm_color,
			"frequency": oscillation_speed * _rf_range(0.8, 1.2)
		}

		var im = ImmediateMesh.new()
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = im
		mesh_instance.material_override = worm_mat
		worm_container.add_child(mesh_instance)
		_worm_meshes[i] = mesh_instance
		_worm_ims[i] = im

func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("PETRI DISH", [
		[
			{"type": "slider_h", "label": "SPEED", "default": 0.5},
			{"type": "slider_h", "label": "WIGGLE", "default": oscillation_speed / 10.0},
		],
	])
	panel.position = Vector3(0, 0.5, 0.6)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)

	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)

	var wiggle_slider: Node = panel.find_child("Param_1", true, false)
	if wiggle_slider and wiggle_slider.has_signal("slider_moved"):
		wiggle_slider.slider_moved.connect(func(_pos):
			if wiggle_slider.has_method("get_normalized_value"):
				oscillation_speed = wiggle_slider.get_normalized_value() * 10.0
		)

func _on_speed_changed() -> void:
	if _speed_slider:
		_speed_scale = _speed_slider.get_normalized_value() * 2.0

func _process(delta: float) -> void:
	_time = wrapf(_time + delta, 0.0, 1000.0)

	for i in range(_worms.size()):
		_update_worm(i, delta)
		_draw_worm(i)

## Moves a worm forward, reflects off dish edges, and randomly turns.
func _update_worm(index: int, delta: float) -> void:
	var worm = _worms[index]

	var move_amount = worm.speed * _speed_scale * delta * 0.1
	worm.position += worm.direction * move_amount

	var dist_from_center = Vector2(worm.position.x, worm.position.z).length()
	if dist_from_center > dish_radius * 0.85:
		var normal = Vector3(worm.position.x, 0, worm.position.z).normalized()
		worm.direction = worm.direction - 2 * worm.direction.dot(normal) * normal
		worm.direction = worm.direction.normalized()
		worm.position = Vector3(normal.x, 0.015, normal.z) * dish_radius * 0.8

	if _rf() < 0.01:
		var turn = _rf_range(-0.3, 0.3)
		worm.direction = worm.direction.rotated(Vector3.UP, turn)

## Rebuilds a worm's ribbon mesh with sine-wave oscillation.
## Uses TRIANGLE_STRIP for visible width instead of invisible 1-pixel lines.
func _draw_worm(index: int) -> void:
	var worm = _worms[index]
	var im = _worm_ims[index]

	im.clear_surfaces()

	if worm_length < 2:
		return

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var head_pos = worm.position
	var dir = worm.direction
	var perpendicular = Vector3(-dir.z, 0, dir.x)
	var ribbon_up = Vector3.UP  # ribbon width direction

	for j in range(worm_length):
		var t = float(j) / (worm_length - 1)
		var segment_pos = head_pos - dir * t * dish_radius * 0.6

		var wave_offset = sin(_time * worm.frequency + worm.phase + t * 6.0) * oscillation_amplitude * 2.0 * (1.0 - t * 0.5)
		segment_pos += perpendicular * wave_offset

		var alpha = 1.0 - t * 0.7
		var color = Color(worm.color.r, worm.color.g, worm.color.b, alpha)
		# Worm tapers: head is full width, tail is thinner
		var width = worm_radius * (1.0 - t * 0.6)
		var offset = perpendicular * width

		im.surface_set_color(color)
		im.surface_add_vertex(segment_pos + offset)
		im.surface_set_color(color)
		im.surface_add_vertex(segment_pos - offset)

	im.surface_end()

func _exit_tree() -> void:
	for mesh_instance in _worm_meshes:
		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	_worm_meshes.clear()
	_worm_ims.clear()

## LATENT BUG, closed here for the two keys this promotion needs (was petri_dish_worms.gd:230,
## the whole body was `pass`). The artifact advertised a configuration hook and threw every key
## away, so nothing a map wrote on the token ever reached it. The other exports — num_worms,
## oscillation_speed, worm_speed and the rest — are STILL unread, deliberately: they are the
## simulation's parameters and wiring them from a token is a curriculum change, not a DNA one.
## GUARDED, and the guard is the point. The first version of this hook fired _respawn_worms
## and _rebuild_assay on the mere PRESENCE of a key, so a token restating the value the dish
## already held threw the population away and rebuilt it. Now: return on an empty dict,
## assign only when the incoming value is legal AND different, and touch nothing at all
## before _ready has built once. None of the 5 existing placements passes any config, so
## none of them reaches a teardown.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return

	var respawn: bool = false
	var reassay: bool = false

	if config_data.has("spawn_seed"):
		# int(str(...)) because a token value arrives as a String and set()/assignment on a
		# typed int would silently reject it, leaving the dish unseeded and the sweep noisy.
		var s: int = int(str(config_data["spawn_seed"]))
		if s != spawn_seed:
			spawn_seed = s
			_rng = null
			respawn = true

	if config_data.has("assay"):
		var word: String = str(config_data["assay"]).strip_edges().to_lower()
		if ASSAYS.has(word) and word != assay:
			assay = word
			reassay = true

	if not _built:
		return
	if respawn:
		_respawn_worms()
	if reassay:
		_rebuild_assay()


## Drop the current population and draw a fresh one. Only reachable through a seed arriving in
## apply_grid_config; on the default path this never runs.
func _respawn_worms() -> void:
	for mesh_instance in _worm_meshes:
		if is_instance_valid(mesh_instance):
			mesh_instance.queue_free()
	_worm_meshes.clear()
	_worm_ims.clear()
	_worms.clear()
	_time = 0.0
	_spawn_worms()


# ── Assay axis ────────────────────────────────────────────────────────
# CONSTANTS are all measured off the shipped dish: top_radius 0.16 at y 0.0125 (so the glass
# runs y 0 .. 0.025), rim 0.165 at y 0.029, agar 0.14 at y 0.008.

const AS_DISH_R := 0.16
const AS_AGAR_TOP := 0.0155
const AS_CONTROL_X := 0.40          # centre of the control dish
const AS_POST_X := -0.30            # centre of the gauge post
const AS_CHART_Z := -0.30           # standoff of the chart plate behind the dish


func _rebuild_assay() -> void:
	if is_instance_valid(_assay_root):
		remove_child(_assay_root)
		_assay_root.queue_free()
	_assay_root = null
	_build_assay()


func _build_assay() -> void:
	match assay:
		"gauge":
			_assay_root_node()
			_assay_gauge()
		"control":
			_assay_root_node()
			_assay_control()
		"chart":
			_assay_root_node()
			_assay_chart()
		"vitrine":
			_assay_root_node()
			_assay_vitrine()
		_:
			pass                                  # "none" — the legacy lineage, nothing added


## One wrapper node for the whole apparatus. It is a plain Node3D, which is also why
## _auto_ground_artifact cannot see any of this: that walk types only the root's DIRECT
## children, and a Node3D is not one of the three types it measures.
func _assay_root_node() -> void:
	_assay_root = Node3D.new()
	_assay_root.name = "Assay"
	add_child(_assay_root)


func _as_metal(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = 0.55
	mat.roughness = 0.42
	return mat


func _as_glass() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.97, 1.0, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _as_box(size: Vector3, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	return _as_box_under(_assay_root, size, at, mat)


## Same box, parented somewhere other than the assay root — the chart hangs its rules and its
## curve off the tilted plate so they tilt with it instead of floating in front of it.
func _as_box_under(parent: Node3D, size: Vector3, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _as_cylinder(top_r: float, bot_r: float, h: float, at: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = h
	cyl.radial_segments = 32
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.position = at
	mi.material_override = mat
	_assay_root.add_child(mi)
	return mi


## GAUGE — the dish stops being watched and starts being measured. A graduated post, a
## cantilever reaching back over the culture, and a stylus hanging above the agar.
func _assay_gauge() -> void:
	var steel := _as_metal(Color(0.62, 0.64, 0.68))
	var brass := _as_metal(Color(0.85, 0.68, 0.30))
	_as_box(Vector3(0.05, 0.012, 0.09), Vector3(AS_POST_X, 0.006, 0.0), steel)   # foot
	_as_box(Vector3(0.022, 0.22, 0.022), Vector3(AS_POST_X, 0.11, 0.0), steel)   # column
	for i in range(8):
		var y: float = 0.035 + 0.024 * float(i)
		var long_tick: bool = (i % 2) == 0
		var w: float = 0.040 if long_tick else 0.026
		_as_box(Vector3(w, 0.0035, 0.006), Vector3(AS_POST_X + w * 0.5 + 0.011, y, 0.012), brass)
	# Cantilever arm reaching from the post back over the centre of the dish, and the stylus.
	var reach: float = absf(AS_POST_X) + 0.02
	_as_box(Vector3(reach, 0.014, 0.018), Vector3(AS_POST_X + reach * 0.5, 0.20, 0.0), steel)
	_as_box(Vector3(0.008, 0.16, 0.008), Vector3(-0.02, 0.12, 0.0), brass)
	_as_cylinder(0.0, 0.007, 0.018, Vector3(-0.02, AS_AGAR_TOP + 0.028, 0.0), brass)


## CONTROL — the rung that turns an observation into an experiment. Same glass, same rim, same
## agar, standing 0.40 m away. No worms: WormContainer is not duplicated, and that absence is
## the whole content of this rung.
func _assay_control() -> void:
	var glass := _as_glass()
	var agar := StandardMaterial3D.new()
	agar.albedo_color = medium_color
	agar.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var c := Vector3(AS_CONTROL_X, 0.0, 0.0)
	_as_cylinder(AS_DISH_R, 0.15, 0.025, c + Vector3(0, 0.0125, 0), glass)
	_as_cylinder(0.165, AS_DISH_R, 0.008, c + Vector3(0, 0.029, 0), glass)
	_as_cylinder(0.14, 0.14, 0.015, c + Vector3(0, 0.008, 0), agar)
	var tag := Label3D.new()
	tag.text = "CONTROL\nno culture"
	tag.pixel_size = 0.001
	tag.font_size = 10
	tag.outline_size = 2
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.modulate = Color(0.6, 0.7, 0.8, 0.8)
	tag.position = c + Vector3(0, -0.01, 0.18)
	_assay_root.add_child(tag)


## CHART — the dish reporting. A ruled plate standing behind the culture with a growth curve
## drawn on it. The curve is a FIXED logistic, not a sample: a rung that rolled dice would make
## every capture of this artifact a different picture and the axis unmeasurable.
func _assay_chart() -> void:
	var w: float = 0.42
	var h: float = 0.26
	var board := _as_metal(Color(0.10, 0.11, 0.13))
	board.metallic = 0.15
	board.roughness = 0.85
	var plate := _as_box(Vector3(w, h, 0.010), Vector3(0.0, h * 0.5 + 0.02, AS_CHART_Z), board)
	plate.rotation_degrees = Vector3(-8, 0, 0)

	var rule := _as_metal(Color(0.38, 0.42, 0.46))
	rule.metallic = 0.0
	for i in range(5):
		var gy: float = -h * 0.5 + h * (float(i) + 0.5) / 5.0
		_as_box_under(plate, Vector3(w * 0.88, 0.0022, 0.004), Vector3(0, gy, 0.007), rule)

	# The logistic itself, drawn as a chain of short segments so it reads as a line at a metre.
	var ink := _as_metal(Color(0.30, 0.95, 0.65))
	ink.metallic = 0.0
	ink.emission_enabled = true
	ink.emission = Color(0.30, 0.95, 0.65)
	ink.emission_energy_multiplier = 1.4
	var steps: int = 28
	var prev := Vector2(-w * 0.44, -h * 0.40)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var y_norm: float = 1.0 / (1.0 + exp(-10.0 * (t - 0.45)))
		var p := Vector2(-w * 0.44 + w * 0.88 * t, -h * 0.40 + h * 0.78 * y_norm)
		var mid: Vector2 = (prev + p) * 0.5
		var d: Vector2 = p - prev
		var seg := _as_box_under(plate, Vector3(d.length(), 0.006, 0.005), Vector3(mid.x, mid.y, 0.010), ink)
		seg.rotation_degrees = Vector3(0, 0, rad_to_deg(atan2(d.y, d.x)))
		prev = p

	var cap := Label3D.new()
	cap.text = "POPULATION"
	cap.pixel_size = 0.001
	cap.font_size = 10
	cap.outline_size = 2
	cap.modulate = Color(0.6, 0.7, 0.8, 0.85)
	cap.position = Vector3(0, h + 0.05, AS_CHART_Z + 0.02)
	_assay_root.add_child(cap)


## VITRINE — the culture stops being live work. Four walls, a lid and a shallow plinth: the
## dish is now a thing on display, which is a different claim about what you are looking at.
func _assay_vitrine() -> void:
	var glass := _as_glass()
	var plinth := _as_metal(Color(0.16, 0.17, 0.20))
	plinth.metallic = 0.25
	plinth.roughness = 0.8
	var half: float = 0.21
	var top: float = 0.30
	var t: float = 0.006
	_as_box(Vector3(half * 2.0 + 0.04, 0.012, half * 2.0 + 0.04), Vector3(0, -0.006, 0), plinth)
	_as_box(Vector3(half * 2.0, t, half * 2.0), Vector3(0, top, 0), glass)
	_as_box(Vector3(half * 2.0, top, t), Vector3(0, top * 0.5, -half), glass)
	_as_box(Vector3(half * 2.0, top, t), Vector3(0, top * 0.5, half), glass)
	_as_box(Vector3(t, top, half * 2.0), Vector3(-half, top * 0.5, 0), glass)
	_as_box(Vector3(t, top, half * 2.0), Vector3(half, top * 0.5, 0), glass)
	# Corner posts, so the case reads as a case and not as four floating panes.
	var post := _as_metal(Color(0.55, 0.57, 0.60))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_as_box(Vector3(0.010, top, 0.010), Vector3(half * sx, top * 0.5, half * sz), post)
