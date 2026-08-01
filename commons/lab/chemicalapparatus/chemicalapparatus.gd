# chemicalapparatus.gd
# Chemistry station with bubbling liquids using sine-based animation
# Demonstrates phase relationships and harmonic motion
extends Node3D

class_name LabChemicalApparatus


# @identity
# essence: liquid_y(t) = base_y + bubble_amplitude * sin(bubble_frequency * t + phase_offset)
# desire: Watch liquids bubble and burners flicker in laboratory glassware driven by sine oscillations
# critical_parameter: bubble_frequency — controls the rhythm of bubbling across all vessels
# triggers: phase_offset_per_vessel creates staggered bubbling; trigger_reaction() activates color changes
# emerges: the feeling of an active chemistry lab from simple sinusoidal liquid oscillation
# needs: VR interaction to trigger reactions [missing], temperature control [missing]
# relationships: depends on sine-driven position animation; contrasts with GlassRack (dynamic vs static glass); unlocks lab environment
# truth: Bubbling is periodic vertical displacement — chemistry oscillates at the molecular scale.

@export_group("Bubbling")
@export var bubble_frequency: float = 2.0  # Hz
@export var bubble_amplitude: float = 0.02  # Meters
@export var phase_offset_per_vessel: float = 0.5  # Radians

@export_group("Colors")
@export var flask_liquid_color: Color = Color(0.0, 0.8, 1.0, 0.7)
@export var beaker_liquid_color: Color = Color(0.2, 1.0, 0.4, 0.7)
@export var tube_colors: Array[Color] = [
	Color(1.0, 0.3, 0.3, 0.7),
	Color(0.3, 1.0, 0.3, 0.7),
	Color(0.3, 0.3, 1.0, 0.7),
	Color(1.0, 1.0, 0.3, 0.7),
	Color(1.0, 0.3, 1.0, 0.7),
]

@export_group("Flame")
@export var flame_flicker_speed: float = 8.0
@export var flame_intensity: float = 1.5

@export_group("DNA")
## AXIS — WHAT THE GLASS ADMITS ABOUT ITSELF.
##
## The bubbling is the curriculum and is not touched by this. What the axis decides is
## whether the bench admits that anyone has ever stood at it. Laboratory glass is
## specified to be invisible — you are meant to look through it at the reaction, never at
## it — and it never manages that. There is always a rim, a meniscus, a ring where the
## level stood. How much of that the station shows is an argument about whether an
## instrument can be neutral.
##
##   none      the discipline's own picture of itself — clean vessels, the reaction
##             legible straight through, no trace of a hand. The legacy build, exactly.
##   bench     mid-job — a retort stand clamping the flask neck, an open notebook and pen
##             on the table, marker tape on the beaker. Somebody is HERE and working.
##   residue   the glass keeps the record — crust in both bottoms, a tide ring at the old
##             fill line, drips, chalky dried rings on the table, and an etched band on
##             each vessel that has gone opaque. Transparency fails where the work was.
##   exhibit   racked as evidence — seals over the flask neck and beaker mouth, numbered
##             tags wired to both, a specimen card standing on the table and a tick strip
##             on the tube rack. Nothing is running; everything is accessioned.
##
## Shared word for word with [[GlassRack]] and [[samplevialrack]] — one bench, one
## vocabulary, so a room whose vials are sealed as evidence cannot hold a chemistry
## station that still reads as pristine stock. Named `admission` and not `witness`
## because [[lab_room]] already owns `witness` for its aperture (pane | none | port |
## sash), and config keys are one flat global namespace.
@export var admission: String = "none"
const ADMISSIONS: PackedStringArray = ["none", "bench", "residue", "exhibit"]

## Internal
var time: float = 0.0
var flask_liquid: MeshInstance3D
var beaker_liquid: MeshInstance3D
var test_tubes: Array[MeshInstance3D] = []
var tube_liquids: Array[MeshInstance3D] = []
var flame_light: OmniLight3D
var flask_base_y: float
var beaker_base_y: float

func _ready() -> void:
	_read_admission_meta()
	_build_apparatus()
	# ADMISSION dressing, appended after the station exists so every node index and
	# transform above is untouched. "none" adds nothing at all and returns immediately.
	_dress_admission()

func _process(delta: float) -> void:
	time += delta
	
	# Flask bubbling - primary sine wave
	if flask_liquid:
		var flask_bubble = bubble_amplitude * sin(time * bubble_frequency * TAU)
		flask_liquid.position.y = flask_base_y + flask_bubble
		# Glow intensity follows bubble
		if flask_liquid.material_override:
			var glow = 0.5 + 0.5 * sin(time * bubble_frequency * TAU)
			flask_liquid.material_override.emission_energy_multiplier = glow * 1.5
	
	# Beaker bubbling - phase offset
	if beaker_liquid:
		var beaker_bubble = bubble_amplitude * 0.7 * sin(time * bubble_frequency * TAU + phase_offset_per_vessel)
		beaker_liquid.position.y = beaker_base_y + beaker_bubble
		if beaker_liquid.material_override:
			var glow = 0.5 + 0.5 * sin(time * bubble_frequency * TAU + phase_offset_per_vessel)
			beaker_liquid.material_override.emission_energy_multiplier = glow * 1.2
	
	# Test tubes - cascade phase offset (wave propagation demo)
	for i in range(tube_liquids.size()):
		var tube = tube_liquids[i]
		if tube and tube.material_override:
			var phase = i * phase_offset_per_vessel * 2.0
			var glow = 0.3 + 0.7 * sin(time * bubble_frequency * 0.5 * TAU + phase)
			tube.material_override.emission_energy_multiplier = glow
			# Subtle height oscillation
			tube.scale.y = 0.8 + 0.2 * sin(time * bubble_frequency * TAU + phase)
	
	# Flame flicker - multiple frequencies for natural look
	if flame_light:
		var flicker = flame_intensity * (
			0.7 + 
			0.15 * sin(time * flame_flicker_speed) +
			0.1 * sin(time * flame_flicker_speed * 2.3) +
			0.05 * sin(time * flame_flicker_speed * 5.7)
		)
		flame_light.light_energy = flicker

func _build_apparatus() -> void:
	for child in get_children():
		child.queue_free()
	
	# Table surface
	var table = MeshInstance3D.new()
	table.name = "Table"
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(0.8, 0.03, 0.5)
	table.mesh = table_mesh
	table.position = Vector3(0, 0.015, 0)
	var table_mat = StandardMaterial3D.new()
	table_mat.albedo_color = Color(0.15, 0.15, 0.18)
	table_mat.metallic = 0.3
	table_mat.roughness = 0.6
	table.material_override = table_mat
	add_child(table)
	
	# Erlenmeyer Flask
	_create_flask(Vector3(-0.2, 0.03, 0.0))
	
	# Beaker
	_create_beaker(Vector3(0.1, 0.03, 0.05))
	
	# Test tube rack with tubes
	_create_test_tube_rack(Vector3(0.25, 0.03, -0.1))
	
	# Bunsen burner
	_create_bunsen_burner(Vector3(-0.2, 0.03, 0.18))

func _create_flask(pos: Vector3) -> void:
	var flask_container = Node3D.new()
	flask_container.name = "Flask"
	flask_container.position = pos
	add_child(flask_container)
	
	# Flask body (conical)
	var flask_body = MeshInstance3D.new()
	var flask_mesh = CylinderMesh.new()
	flask_mesh.top_radius = 0.02
	flask_mesh.bottom_radius = 0.06
	flask_mesh.height = 0.12
	flask_mesh.radial_segments = 24
	flask_body.mesh = flask_mesh
	flask_body.position = Vector3(0, 0.06, 0)
	var flask_mat = StandardMaterial3D.new()
	flask_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.25)
	flask_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flask_mat.roughness = 0.0
	flask_mat.metallic = 0.1
	flask_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flask_body.material_override = flask_mat
	flask_container.add_child(flask_body)
	
	# Flask neck
	var neck = MeshInstance3D.new()
	var neck_mesh = CylinderMesh.new()
	neck_mesh.top_radius = 0.015
	neck_mesh.bottom_radius = 0.02
	neck_mesh.height = 0.05
	neck.mesh = neck_mesh
	neck.position = Vector3(0, 0.145, 0)
	neck.material_override = flask_mat
	flask_container.add_child(neck)
	
	# Liquid inside
	flask_liquid = MeshInstance3D.new()
	flask_liquid.name = "FlaskLiquid"
	var liquid_mesh = CylinderMesh.new()
	liquid_mesh.top_radius = 0.018
	liquid_mesh.bottom_radius = 0.05
	liquid_mesh.height = 0.08
	liquid_mesh.radial_segments = 24
	flask_liquid.mesh = liquid_mesh
	flask_base_y = 0.04
	flask_liquid.position = Vector3(0, flask_base_y, 0)
	var liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_color = flask_liquid_color
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.emission_enabled = true
	liquid_mat.emission = Color(flask_liquid_color.r, flask_liquid_color.g, flask_liquid_color.b)
	liquid_mat.emission_energy_multiplier = 0.8
	flask_liquid.material_override = liquid_mat
	flask_container.add_child(flask_liquid)

func _create_beaker(pos: Vector3) -> void:
	var beaker_container = Node3D.new()
	beaker_container.name = "Beaker"
	beaker_container.position = pos
	add_child(beaker_container)
	
	# Beaker body
	var beaker_body = MeshInstance3D.new()
	var beaker_mesh = CylinderMesh.new()
	beaker_mesh.top_radius = 0.045
	beaker_mesh.bottom_radius = 0.04
	beaker_mesh.height = 0.1
	beaker_mesh.radial_segments = 24
	beaker_body.mesh = beaker_mesh
	beaker_body.position = Vector3(0, 0.05, 0)
	var beaker_mat = StandardMaterial3D.new()
	beaker_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.2)
	beaker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beaker_mat.roughness = 0.0
	beaker_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beaker_body.material_override = beaker_mat
	beaker_container.add_child(beaker_body)
	
	# Liquid inside
	beaker_liquid = MeshInstance3D.new()
	beaker_liquid.name = "BeakerLiquid"
	var liquid_mesh = CylinderMesh.new()
	liquid_mesh.top_radius = 0.038
	liquid_mesh.bottom_radius = 0.035
	liquid_mesh.height = 0.06
	beaker_liquid.mesh = liquid_mesh
	beaker_base_y = 0.03
	beaker_liquid.position = Vector3(0, beaker_base_y, 0)
	var liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_color = beaker_liquid_color
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.emission_enabled = true
	liquid_mat.emission = Color(beaker_liquid_color.r, beaker_liquid_color.g, beaker_liquid_color.b)
	liquid_mat.emission_energy_multiplier = 0.6
	beaker_liquid.material_override = liquid_mat
	beaker_container.add_child(beaker_liquid)

func _create_test_tube_rack(pos: Vector3) -> void:
	var rack = Node3D.new()
	rack.name = "TestTubeRack"
	rack.position = pos
	add_child(rack)
	
	# Rack base
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(0.15, 0.02, 0.04)
	base.mesh = base_mesh
	base.position = Vector3(0, 0.01, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.35, 0.3)
	base_mat.roughness = 0.8
	base.material_override = base_mat
	rack.add_child(base)
	
	# Test tubes
	test_tubes.clear()
	tube_liquids.clear()
	var num_tubes = min(5, tube_colors.size())
	var spacing = 0.025
	var start_x = -spacing * (num_tubes - 1) / 2.0
	
	for i in range(num_tubes):
		var tube_pos = Vector3(start_x + i * spacing, 0.02, 0)
		
		# Tube glass
		var tube = MeshInstance3D.new()
		var tube_mesh = CylinderMesh.new()
		tube_mesh.top_radius = 0.008
		tube_mesh.bottom_radius = 0.008
		tube_mesh.height = 0.08
		tube_mesh.radial_segments = 12
		tube.mesh = tube_mesh
		tube.position = tube_pos + Vector3(0, 0.04, 0)
		var tube_mat = StandardMaterial3D.new()
		tube_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.3)
		tube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tube_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		tube.material_override = tube_mat
		rack.add_child(tube)
		test_tubes.append(tube)
		
		# Liquid in tube
		var liquid = MeshInstance3D.new()
		var liq_mesh = CylinderMesh.new()
		liq_mesh.top_radius = 0.006
		liq_mesh.bottom_radius = 0.006
		liq_mesh.height = 0.04 + randf() * 0.02
		liquid.mesh = liq_mesh
		liquid.position = tube_pos + Vector3(0, 0.025, 0)
		var liq_mat = StandardMaterial3D.new()
		liq_mat.albedo_color = tube_colors[i]
		liq_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		liq_mat.emission_enabled = true
		liq_mat.emission = Color(tube_colors[i].r, tube_colors[i].g, tube_colors[i].b)
		liq_mat.emission_energy_multiplier = 0.5
		liquid.material_override = liq_mat
		rack.add_child(liquid)
		tube_liquids.append(liquid)

func _create_bunsen_burner(pos: Vector3) -> void:
	var burner = Node3D.new()
	burner.name = "BunsenBurner"
	burner.position = pos
	add_child(burner)
	
	# Base
	var base = MeshInstance3D.new()
	var base_mesh = CylinderMesh.new()
	base_mesh.top_radius = 0.03
	base_mesh.bottom_radius = 0.04
	base_mesh.height = 0.02
	base.mesh = base_mesh
	base.position = Vector3(0, 0.01, 0)
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.2, 0.22)
	base_mat.metallic = 0.8
	base.material_override = base_mat
	burner.add_child(base)
	
	# Tube
	var tube = MeshInstance3D.new()
	var tube_mesh = CylinderMesh.new()
	tube_mesh.top_radius = 0.012
	tube_mesh.bottom_radius = 0.015
	tube_mesh.height = 0.08
	tube.mesh = tube_mesh
	tube.position = Vector3(0, 0.06, 0)
	tube.material_override = base_mat
	burner.add_child(tube)
	
	# Flame light
	flame_light = OmniLight3D.new()
	flame_light.name = "FlameLight"
	flame_light.position = Vector3(0, 0.12, 0)
	flame_light.light_color = Color(1.0, 0.6, 0.2)
	flame_light.light_energy = flame_intensity
	flame_light.omni_range = 0.5
	burner.add_child(flame_light)
	
	# Flame mesh (inner blue cone)
	var flame_inner = MeshInstance3D.new()
	var flame_mesh = CylinderMesh.new()
	flame_mesh.top_radius = 0.0
	flame_mesh.bottom_radius = 0.015
	flame_mesh.height = 0.05
	flame_inner.mesh = flame_mesh
	flame_inner.position = Vector3(0, 0.125, 0)
	var flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(0.3, 0.5, 1.0, 0.8)
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(0.4, 0.6, 1.0)
	flame_mat.emission_energy_multiplier = 3.0
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_inner.material_override = flame_mat
	burner.add_child(flame_inner)
	
	# Outer orange flame
	var flame_outer = MeshInstance3D.new()
	flame_outer.mesh = flame_mesh.duplicate()
	(flame_outer.mesh as CylinderMesh).bottom_radius = 0.025
	(flame_outer.mesh as CylinderMesh).height = 0.07
	flame_outer.position = Vector3(0, 0.135, 0)
	var flame_out_mat = StandardMaterial3D.new()
	flame_out_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.4)
	flame_out_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_out_mat.emission_enabled = true
	flame_out_mat.emission = Color(1.0, 0.4, 0.1)
	flame_out_mat.emission_energy_multiplier = 2.0
	flame_out_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_outer.material_override = flame_out_mat
	burner.add_child(flame_outer)

## Public API
func set_bubble_frequency(freq: float) -> void:
	bubble_frequency = freq

func trigger_reaction() -> void:
	# Flash all liquids
	var original_flask = flask_liquid_color
	var original_beaker = beaker_liquid_color
	if flask_liquid and flask_liquid.material_override:
		flask_liquid.material_override.emission = Color.WHITE
	if beaker_liquid and beaker_liquid.material_override:
		beaker_liquid.material_override.emission = Color.WHITE
	
	await get_tree().create_timer(0.5).timeout

	if flask_liquid and flask_liquid.material_override:
		flask_liquid.material_override.emission = original_flask
	if beaker_liquid and beaker_liquid.material_override:
		beaker_liquid.material_override.emission = original_beaker

# =============================================================================
# ADMISSION — what the glass admits about itself
# =============================================================================
# Everything below is APPENDED. It runs after _build_apparatus(), adds one child
# named "Admission" and touches nothing that already exists. `admission == "none"`
# returns before that child is created, so the legacy station is reproduced
# node for node. The bubbling maths is not read here at all.

const ADMISSION_ROOT := "Admission"

## The station's fixed layout, copied from _build_apparatus so the dressing lands on
## the actual vessels rather than on a guess. Table top is y = 0.03.
const WIT_TABLE_TOP := 0.03
const WIT_FLASK := Vector3(-0.2, 0.03, 0.0)
const WIT_BEAKER := Vector3(0.1, 0.03, 0.05)
const WIT_RACK := Vector3(0.25, 0.03, -0.1)


func _read_admission_meta() -> void:
	## The grid stamps config_<key> metadata BEFORE add_child, so this is readable from
	## _ready(). An unknown word keeps the default rather than blanking the axis.
	if has_meta("config_admission"):
		admission = _pick_admission(str(get_meta("config_admission")))


func _pick_admission(raw: String) -> String:
	var w: String = raw.strip_edges().to_lower()
	return w if ADMISSIONS.has(w) else admission


## Additive: only the `admission` key does anything here. A token carrying anything else
## leaves the station exactly as it was built.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("admission"):
		admission = _pick_admission(str(config_data["admission"]))
		_dress_admission()


func _dress_admission() -> void:
	var old: Node = get_node_or_null(ADMISSION_ROOT)
	if old:
		remove_child(old)
		old.queue_free()
	if admission == "none":
		return

	var root := Node3D.new()
	root.name = ADMISSION_ROOT
	add_child(root)

	match admission:
		"bench":
			_admission_bench(root)
		"residue":
			_admission_residue(root)
		"exhibit":
			_admission_exhibit(root)
		_:
			pass


## BENCH — somebody is at this station. A retort stand behind the flask closes a clamp
## on its neck, an open notebook and a pen lie on the table, and marker tape rings the
## beaker where the level was being watched.
func _admission_bench(root: Node3D) -> void:
	var steel: StandardMaterial3D = _admission_mat(Color(0.60, 0.62, 0.66), 0.35, 0.85)
	var paper: StandardMaterial3D = _admission_mat(Color(0.93, 0.91, 0.84), 0.88, 0.0)
	var ink: StandardMaterial3D = _admission_mat(Color(0.10, 0.10, 0.13), 0.8, 0.0)

	# Retort stand behind the flask: base plate, rod, boss, clamp arm, two jaws.
	var stand_x: float = WIT_FLASK.x - 0.10
	var stand_z: float = WIT_FLASK.z - 0.09
	_admission_box(root, Vector3(stand_x + 0.02, WIT_TABLE_TOP + 0.008, stand_z),
		Vector3(0.11, 0.016, 0.08), steel)
	_admission_cyl(root, Vector3(stand_x, WIT_TABLE_TOP + 0.145, stand_z), 0.007, 0.29, steel)
	_admission_box(root, Vector3(stand_x, WIT_TABLE_TOP + 0.155, stand_z),
		Vector3(0.028, 0.030, 0.028), steel)
	_admission_cyl_x(root, Vector3((stand_x + WIT_FLASK.x - 0.018) * 0.5, WIT_TABLE_TOP + 0.155, stand_z),
		0.005, absf(WIT_FLASK.x - 0.018 - stand_x), steel)
	_admission_cyl_z(root, Vector3(WIT_FLASK.x - 0.018, WIT_TABLE_TOP + 0.155, (stand_z + WIT_FLASK.z) * 0.5),
		0.005, absf(WIT_FLASK.z - stand_z), steel)
	# jaws closing on the neck
	for jaw_i in range(2):
		var jz: float = -1.0 + 2.0 * float(jaw_i)
		_admission_box(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.155, WIT_FLASK.z + jz * 0.026),
			Vector3(0.030, 0.014, 0.026), steel)

	# The notebook, open and written in, with a pen across it.
	var nb: Vector3 = Vector3(-0.03, WIT_TABLE_TOP + 0.002, 0.16)
	_admission_box(root, nb, Vector3(0.20, 0.004, 0.13), paper)
	_admission_box(root, nb + Vector3(0, 0.0025, 0), Vector3(0.003, 0.002, 0.13), ink)
	for i in range(5):
		var ly: float = -0.048 + 0.024 * float(i)
		_admission_box(root, nb + Vector3(-0.052, 0.003, ly), Vector3(0.075, 0.002, 0.004), ink)
		_admission_box(root, nb + Vector3(0.052, 0.003, ly), Vector3(0.062, 0.002, 0.004), ink)
	var pen: MeshInstance3D = _admission_cyl(root, nb + Vector3(0.05, 0.010, -0.02), 0.004, 0.12, ink)
	pen.rotation_degrees = Vector3(90, 24, 0)

	# Marker tape where the level was being watched. The flask ring tapers with the cone
	# (radius runs 0.06 at the foot to 0.02 at the shoulder over 0.12 of height).
	_admission_cyl(root, Vector3(WIT_BEAKER.x, WIT_TABLE_TOP + 0.072, WIT_BEAKER.z), 0.047, 0.006, paper)
	_admission_cyl(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.098, WIT_FLASK.z), 0.0295, 0.006, paper, 0.0275)


## RESIDUE — the glass keeps the record. Crust in both bottoms, a tide ring where the
## level stood, drips down the outside, chalky dried rings on the table, and an etched
## band on each vessel that has gone opaque: transparency fails where the work was.
func _admission_residue(root: Node3D) -> void:
	var crust: StandardMaterial3D = _admission_mat(Color(0.22, 0.17, 0.09), 0.97, 0.0)
	var tide: StandardMaterial3D = _admission_mat(Color(0.38, 0.30, 0.16), 0.92, 0.0)
	var frost: StandardMaterial3D = _admission_mat(Color(0.80, 0.82, 0.79), 1.0, 0.0)
	var chalk: StandardMaterial3D = _admission_mat(Color(0.52, 0.48, 0.38), 0.96, 0.0)

	# Flask: crust settled in the cone, a tide line, the etched belly, two drips. Every
	# ring tapers with the cone — radius 0.06 at the foot, 0.02 at the shoulder, over
	# 0.12 of height, so r(y) = 0.06 - 0.04 * (y - 0.03) / 0.12.
	_admission_cyl(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.008, WIT_FLASK.z),
		0.0555, 0.016, crust, 0.0500)
	_admission_cyl(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.075, WIT_FLASK.z),
		0.0375, 0.006, tide, 0.0355)
	_admission_cyl(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.038, WIT_FLASK.z),
		0.0522, 0.032, frost, 0.0415)
	for d in range(2):
		var a: float = 0.7 + 2.1 * float(d)
		_admission_box(root, Vector3(WIT_FLASK.x + cos(a) * 0.044, WIT_TABLE_TOP + 0.038,
			WIT_FLASK.z + sin(a) * 0.044), Vector3(0.008, 0.075, 0.008), tide)

	# Beaker: the same story on a straight wall, where the ring reads hardest.
	_admission_cyl(root, Vector3(WIT_BEAKER.x, WIT_TABLE_TOP + 0.007, WIT_BEAKER.z), 0.036, 0.014, crust)
	_admission_cyl(root, Vector3(WIT_BEAKER.x, WIT_TABLE_TOP + 0.062, WIT_BEAKER.z), 0.047, 0.006, tide)
	_admission_cyl(root, Vector3(WIT_BEAKER.x, WIT_TABLE_TOP + 0.030, WIT_BEAKER.z), 0.046, 0.028, frost)
	for d in range(2):
		var a2: float = 1.9 + 2.4 * float(d)
		_admission_box(root, Vector3(WIT_BEAKER.x + cos(a2) * 0.044, WIT_TABLE_TOP + 0.031,
			WIT_BEAKER.z + sin(a2) * 0.044), Vector3(0.007, 0.062, 0.007), tide)

	# Plugs of dried sample left in the tubes.
	for i in range(5):
		var tx: float = WIT_RACK.x - 0.05 + 0.025 * float(i)
		_admission_cyl(root, Vector3(tx, WIT_TABLE_TOP + 0.026, WIT_RACK.z), 0.0075, 0.010, crust)

	# Dried rings on the table itself — the bench remembers what was set down on it.
	var rings: Array = [Vector3(-0.06, 0, -0.14), Vector3(0.30, 0, 0.14), Vector3(0.02, 0, 0.06),
		Vector3(-0.31, 0, -0.17)]
	for i in range(rings.size()):
		var rv: Vector3 = rings[i]
		var rr: float = 0.030 + 0.012 * float(i % 3)
		_admission_cyl(root, Vector3(rv.x, WIT_TABLE_TOP + 0.0012, rv.z), rr, 0.0016, chalk)


## EXHIBIT — the station accessioned. A seal over the flask neck and the beaker mouth, a
## numbered tag wired to each, a specimen card standing on the table and a tick strip on
## the tube rack. Nothing here is running; everything here is held.
func _admission_exhibit(root: Node3D) -> void:
	var card: StandardMaterial3D = _admission_mat(Color(0.91, 0.89, 0.81), 0.85, 0.0)
	var ink: StandardMaterial3D = _admission_mat(Color(0.09, 0.09, 0.12), 0.8, 0.0)
	var wire: StandardMaterial3D = _admission_mat(Color(0.58, 0.58, 0.62), 0.4, 0.8)
	var seal: StandardMaterial3D = _admission_mat(Color(0.82, 0.30, 0.14), 0.7, 0.0)

	# Seals over the two open mouths.
	_admission_cyl(root, Vector3(WIT_FLASK.x, WIT_TABLE_TOP + 0.172, WIT_FLASK.z), 0.020, 0.008, seal)
	_admission_cyl(root, Vector3(WIT_BEAKER.x, WIT_TABLE_TOP + 0.098, WIT_BEAKER.z), 0.047, 0.007, seal)

	# Tag wired to the flask neck.
	_admission_cyl_x(root, Vector3(WIT_FLASK.x + 0.030, WIT_TABLE_TOP + 0.150, WIT_FLASK.z),
		0.0016, 0.052, wire)
	_admission_tag(root, Vector3(WIT_FLASK.x + 0.062, WIT_TABLE_TOP + 0.118, WIT_FLASK.z),
		0.055, 0.036, card, ink)

	# Tag wired to the beaker rim.
	_admission_cyl_x(root, Vector3(WIT_BEAKER.x + 0.062, WIT_TABLE_TOP + 0.094, WIT_BEAKER.z),
		0.0016, 0.045, wire)
	_admission_tag(root, Vector3(WIT_BEAKER.x + 0.092, WIT_TABLE_TOP + 0.066, WIT_BEAKER.z),
		0.050, 0.034, card, ink)

	# Tick strip along the front of the tube rack — one number per tube.
	_admission_box(root, Vector3(WIT_RACK.x, WIT_TABLE_TOP + 0.012, WIT_RACK.z + 0.024),
		Vector3(0.150, 0.018, 0.003), card)
	for i in range(5):
		var tx: float = WIT_RACK.x - 0.05 + 0.025 * float(i)
		_admission_box(root, Vector3(tx, WIT_TABLE_TOP + 0.012, WIT_RACK.z + 0.026),
			Vector3(0.004, 0.011, 0.003), ink)

	# The accession card standing at the front edge of the table, with its barcode.
	var cz: float = 0.20
	var cy: float = WIT_TABLE_TOP + 0.052
	_admission_box(root, Vector3(-0.06, cy, cz), Vector3(0.30, 0.100, 0.004), card)
	_admission_box(root, Vector3(-0.06, WIT_TABLE_TOP + 0.004, cz - 0.010),
		Vector3(0.30, 0.008, 0.024), card)
	for k in range(11):
		var bx: float = -0.06 + (-0.125 + 0.025 * float(k))
		var bw: float = 0.005 if k % 2 == 0 else 0.010
		_admission_box(root, Vector3(bx, cy - 0.014, cz + 0.003), Vector3(bw, 0.050, 0.003), ink)
	_admission_box(root, Vector3(-0.06, cy + 0.034, cz + 0.003), Vector3(0.26, 0.009, 0.003), ink)


func _admission_tag(root: Node3D, center: Vector3, w: float, h: float,
		card: Material, ink: Material) -> void:
	_admission_box(root, center, Vector3(w, h, 0.003), card)
	for k in range(2):
		_admission_box(root, center + Vector3(0, h * (0.22 - 0.42 * float(k)), 0.0025),
			Vector3(w * 0.66, h * 0.13, 0.002), ink)


# ── Admission geometry helpers ──────────────────────────────────────────────────

func _admission_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _admission_box(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


## `top_radius` below 0 means "same as radius". The Erlenmeyer is a CONE, so a straight
## collar sized to its foot floats free of the glass at the top of the band and a collar
## sized to its shoulder cuts into it; the bands that ring the flask taper with it.
func _admission_cyl(parent: Node3D, center: Vector3, radius: float, height: float,
		mat: Material, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = maxf(top_radius if top_radius >= 0.0 else radius, 0.0004)
	mesh.bottom_radius = maxf(radius, 0.0004)
	mesh.height = maxf(height, 0.0006)
	mesh.radial_segments = 16
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


func _admission_cyl_x(parent: Node3D, center: Vector3, radius: float, length: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _admission_cyl(parent, center, radius, maxf(length, 0.001), mat)
	mi.rotation_degrees = Vector3(0, 0, 90)
	return mi


func _admission_cyl_z(parent: Node3D, center: Vector3, radius: float, length: float, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = _admission_cyl(parent, center, radius, maxf(length, 0.001), mat)
	mi.rotation_degrees = Vector3(90, 0, 0)
	return mi
