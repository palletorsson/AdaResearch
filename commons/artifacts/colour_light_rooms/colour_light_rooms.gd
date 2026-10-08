extends Node3D
## White receiving room with a recessed pink threshold, then an open light well.
## The walls keep white albedo. Coloured local lights and concealed luminous rims
## change their appearance. This is a renderer study, not a Turrell reconstruction.
const LIGHT_LAYER := 1 << 19
const SECOND := Vector3(10.2, 0, 0)
const PALETTE: Array[Color] = [Color(1,0.80,0.60), Color(1,0.12,0.32), Color(0.32,0.18,1), Color(0.05,0.80,1), Color(0.75,1,0.88)]
var elapsed := 0.0
var running := true
var cycle_seconds := 110.0
var white_material: StandardMaterial3D
var central_light: OmniLight3D
var lamp_material: StandardMaterial3D
var ring_lights: Array[OmniLight3D] = []
var rim_materials: Array[StandardMaterial3D] = []
var walls: Array[MeshInstance3D] = []
var receiving_meshes: Array[MeshInstance3D] = []
var threshold_lights: Array[OmniLight3D] = []

func _ready() -> void:
	white_material = StandardMaterial3D.new()
	white_material.albedo_color = Color(0.92,0.91,0.88)
	white_material.roughness = 0.96
	white_material.disable_ambient_light = true
	_build_white_room()
	_build_pink_threshold()
	_build_aperture_room()
	set_meta("em_visibility_bounds", AABB(Vector3(-5,0,-7.2),Vector3(20.4,8.2,14.4)))
	set_phase(0.0)

func box(label: String, at: Vector3, size: Vector3, solid := true, mat: Material = null, obstacle := false) -> MeshInstance3D:
	var part := MeshInstance3D.new(); part.name = label
	var mesh := BoxMesh.new(); mesh.size = size
	part.mesh = mesh; part.position = at; part.layers = LIGHT_LAYER
	part.material_override = mat if mat else white_material
	add_child(part); receiving_meshes.append(part)
	if solid:
		var body := StaticBody3D.new(); var col := CollisionShape3D.new(); var shape := BoxShape3D.new()
		shape.size = size; col.shape = shape; body.add_child(col); part.add_child(body)
	if obstacle: walls.append(part)
	return part

func source(label: String, at: Vector3, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new(); light.name = label; light.position = at
	light.light_cull_mask = LIGHT_LAYER; light.light_energy = energy
	light.omni_range = reach; light.omni_attenuation = 0.40
	light.shadow_enabled = true; light.shadow_bias = 0.04
	add_child(light); return light

func glowing() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true; mat.emission_energy_multiplier = 1.3
	return mat

func portal_wall(label: String, x: float, height: float, depth: float) -> void:
	# Two 2.4 m clear openings join the original hall and the aperture chamber.
	var span := (depth - 2.4) * 0.5
	for sign_ in [-1,1]: box(label, Vector3(x,height*0.5,sign_*(1.2+span*0.5)),Vector3(0.20,height,span),true,null,true)
	box(label+"Lintel",Vector3(x,(height+2.7)*0.5,0),Vector3(0.20,height-2.7,2.4))

func _build_white_room() -> void:
	box("WhiteFloor",Vector3(0,-0.09,0),Vector3(8.8,0.20,8.8))
	box("WhiteCeiling",Vector3(0,4.5,0),Vector3(8.8,0.20,8.8))
	for sign_ in [-1,1]: box("WhiteWall",Vector3(0,2.25,sign_*4.4),Vector3(8.8,4.5,0.20),true,null,true)
	portal_wall("WhiteEntry",-4.4,4.5,8.8)
	portal_wall("WhiteExit",4.4,4.5,8.8)
	central_light = source("OneCentralLight",Vector3(0,2.1,0),1.7,12.0)
	lamp_material = glowing()
	var globe := MeshInstance3D.new(); globe.name = "SourceGlobe"
	var sphere := SphereMesh.new(); sphere.radius = 0.12; sphere.height = 0.24
	globe.mesh = sphere; globe.material_override = lamp_material; globe.layers = LIGHT_LAYER; globe.position = central_light.position; add_child(globe)
	box("Suspension",Vector3(0,3.35,0),Vector3(0.008,2.25,0.008),false)
	# A low bench invites time without occupying the route around the light.
	box("WhiteBench",Vector3(0,0.24,3.8),Vector3(4.8,0.48,0.6),true,null,true)
	box("ConnectingFloor",Vector3(4.95,-0.09,0),Vector3(1.1,0.20,2.4))
	for sign_ in [-1,1]: box("ConnectingCheek",Vector3(4.95,1.35,sign_*1.3),Vector3(1.1,2.7,0.2),true,null,true)
	box("ConnectingRoof",Vector3(4.95,2.8,0),Vector3(1.1,0.2,2.8))

func _build_pink_threshold() -> void:
	# A real recess within the existing room footprint. Nothing covers the opening:
	# a viewer can approach through it until the original back wall stops the body.
	# Keep the source colour fixed so the changing surround remains a comparison.
	var pink := Color(1.0,0.025,0.30)
	for side in [-1,1]:
		box("ThresholdCheek",Vector3(side*3.65,2.25,-3.10),Vector3(1.5,4.5,0.24),true,null,true)
	box("ThresholdLintel",Vector3(0,3.85,-3.10),Vector3(5.8,1.3,0.24))
	box("ThresholdSoffit",Vector3(0,3.28,-3.68),Vector3(5.8,0.16,1.12))
	for side in [-1,1]:
		box("ThresholdReturn",Vector3(side*2.96,1.6,-3.68),Vector3(0.12,3.2,1.12),true,null,true)
	var reveal := glowing()
	reveal.albedo_color = Color(1,0.36,0.65)
	reveal.emission = reveal.albedo_color
	for side in [-1,1]:
		var lip := box("PinkRevealSide",Vector3(side*2.905,1.60,-3.245),Vector3(0.025,3.2,0.025),false,reveal)
		lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var top := box("PinkRevealTop",Vector3(0,3.195,-3.245),Vector3(5.8,0.025,0.025),false,reveal)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1,1]:
		var wash := source("ThresholdWash",Vector3(side*2.62,2.8,-3.65),0.65,6.0)
		wash.light_color = pink
		wash.shadow_enabled = false
		threshold_lights.append(wash)

func roof_ring(label: String, centre: Vector3, outer: Vector2, hole: Vector2, mat: Material = null, thickness := 0.20) -> void:
	var sides := (outer.x - hole.x) * 0.5
	var ends := (outer.y - hole.y) * 0.5
	for sign_ in [-1,1]:
		var side := box(label+"Side",centre+Vector3(sign_*(hole.x*0.5+sides*0.5),0,0),Vector3(sides,thickness,outer.y),mat == null,mat)
		var end := box(label+"End",centre+Vector3(0,0,sign_*(hole.y*0.5+ends*0.5)),Vector3(hole.x,thickness,ends),mat == null,mat)
		if mat != null:
			side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			end.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_aperture_room() -> void:
	box("ApertureFloor",SECOND+Vector3(0,-0.09,0),Vector3(9.2,0.20,14))
	portal_wall("ApertureEntry",SECOND.x-4.6,4.3,14)
	box("ApertureEast",SECOND+Vector3(4.6,2.15,0),Vector3(0.20,4.3,14),true,null,true)
	for sign_ in [-1,1]: box("ApertureEnd",SECOND+Vector3(0,2.15,sign_*7),Vector3(9.2,4.3,0.20),true,null,true)
	for level in 3:
		var height := 4.4 + level * 1.35
		var hole := Vector2(5.8 - level*1.35,8.2 - level*1.7)
		var outer := Vector2(9.2,14)
		roof_ring("CeilingLevel%d" % level,SECOND+Vector3(0,height,0),outer,hole)
		# Close the sides between levels: one stepped light well, with one sky
		# aperture, instead of disconnected slabs leaking sky around their edges.
		if level < 2:
			for side in [-1,1]:
				box("WellSide%d" % level,SECOND+Vector3(side*(hole.x*0.5+0.06),height+0.675,0),Vector3(0.12,1.15,hole.y))
				box("WellEnd%d" % level,SECOND+Vector3(0,height+0.675,side*(hole.y*0.5+0.06)),Vector3(hole.x+0.24,1.15,0.12))
		var rim := glowing(); rim_materials.append(rim)
		# Thin luminous reveals sit on the actual lip; the centre stays open.
		roof_ring("LuminousReveal%d" % level,SECOND+Vector3(0,height-0.115,0),hole+Vector2(0.075,0.075),hole,rim,0.025)
		for sign_ in [-1,1]:
			var light := source("HiddenWash%d" % level,SECOND+Vector3(sign_*(hole.x*0.5+0.12),height-0.26,0),1.2,9.0)
			light.shadow_enabled = false
			ring_lights.append(light)
	# A 1:7.5 ramp changes eye level while preserving a quiet, continuous walk.
	var ramp := box("SlowRamp",SECOND+Vector3(3.5,0.55,0),Vector3(1.65,0.20,9.08))
	ramp.rotation.x = atan(1.2/9.0)
	box("UpperLanding",SECOND+Vector3(0.7,1.10,-5.75),Vector3(7.2,0.20,2.5))
	box("LandingParapet",SECOND+Vector3(0.7,1.7,-6.9),Vector3(7.2,1.2,0.16),true,null,true)
	box("LandingInnerRail",SECOND+Vector3(-0.15,1.7,-4.54),Vector3(5.3,1.0,0.08),true,null,true)
	box("LandingEndRail",SECOND+Vector3(-2.86,1.7,-5.75),Vector3(0.08,1.0,2.5),true,null,true)
	# A low continuous kerb keeps the ramp edge legible and contains a walking body.
	var rail := box("RampInnerRail",SECOND+Vector3(2.64,1.1,0),Vector3(0.08,1.0,9.08),true,null,true)
	rail.rotation.x = ramp.rotation.x
	box("ApertureBench",SECOND+Vector3(-3.7,0.28,3.1),Vector3(0.6,0.56,3.0),true,null,true)

func palette_at(t: float) -> Color:
	var p := fposmod(t,1.0) * PALETTE.size()
	var i := int(floor(p)); var f := smoothstep(0.0,1.0,p-i)
	return PALETTE[i].lerp(PALETTE[(i+1)%PALETTE.size()],f)

func set_phase(phase: float) -> void:
	elapsed = fposmod(phase,1.0) * cycle_seconds
	var c := palette_at(phase)
	central_light.light_color = c
	lamp_material.albedo_color = c; lamp_material.emission = c
	for level in 3:
		# Closely related hues let the depth read without turning the well into
		# three unrelated signs. The rendered sky is outside this colour cycle.
		var colour := palette_at(phase + level*0.055)
		rim_materials[level].albedo_color = colour; rim_materials[level].emission = colour
		ring_lights[level*2].light_color = colour; ring_lights[level*2+1].light_color = colour

func _process(delta: float) -> void:
	if running: set_phase((elapsed + delta) / cycle_seconds)

func get_museum_occupied_cells() -> Array:
	# Only body-height partitions and furniture reserve floor cells. The rooms'
	# floors, roof slabs and traversable ramp must not seal their whole envelope.
	var cells: Dictionary = {}
	for wall in walls:
		var bounds := wall.global_transform * wall.mesh.get_aabb()
		for z in range(int(floor(bounds.position.z)),int(ceil(bounds.end.z))):
			for x in range(int(floor(bounds.position.x)),int(ceil(bounds.end.x))): cells[Vector2i(x,z)] = true
	return cells.keys()
