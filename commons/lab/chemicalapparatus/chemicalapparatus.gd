# chemicalapparatus.gd
# Chemistry station with bubbling liquids using sine-based animation
# Demonstrates phase relationships and harmonic motion
extends Node3D

class_name LabChemicalApparatus

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
	_build_apparatus()

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
