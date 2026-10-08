extends RefCounted
## The original panels rise; their IDs, bodies, footprint and hinge direction
## persist. Pattern is applied to those meshes, not to replacement flag objects.
const Pattern := preload("res://commons/artifacts/biome_inheritance/banner_pattern.gdshader")
const Model := preload("res://commons/artifacts/biome_primitives/encounter_model.gd")
const Grammar := preload("res://commons/biome_layers/biome_grammar.gd")
const LIFT := 2.35
const PALETTES := [
	["152e50", "f2e5ba", "d77c50"],
	["912f40", "f4dbb3", "e9ac47"],
	["26736d", "ede1b9", "eab77f"],
	["d3a342", "283347", "f6e9ca"],
	["542951", "edbca4", "74bbad"]]
const MOTIFS := ["wave arcs", "nested diamonds", "circle lattice", "chevrons", "branching lines"]
var bridge: Node3D
var materials: Array[ShaderMaterial] = []
var bars: Array[MeshInstance3D] = []
var caps: Array[MeshInstance3D] = []
var poses: Array = []
var current_time := 0.0
var current_stage := ""

func setup(owner_bridge: Node3D) -> void:
	bridge = owner_bridge
	var forms: Array = bridge.sculpture.model.forms()
	for i in range(forms.size()):
		var body: Node3D = bridge.sculpture._form_bodies[i]
		var material := ShaderMaterial.new()
		material.shader = Pattern
		material.set_shader_parameter("face_size", Vector2(float(body.get_meta("built_width")),float(forms[i].size[1])))
		material.set_shader_parameter("motif",i)
		for j in range(3):
			material.set_shader_parameter(["ground_color","line_color","accent_color"][j],Color(PALETTES[i][j]))
		materials.append(material)
		for child in body.get_children():
			if child is MeshInstance3D: child.material_override = material
		# The already-existing hinge pin becomes a taller pole, firmly grounded.
		var pole: MeshInstance3D = bridge._pins[i]
		pole.mesh = pole.mesh.duplicate()
		pole.mesh.height = LIFT + float(forms[i].size[1]) + .22
		pole.mesh.top_radius = .026
		pole.mesh.bottom_radius = .035
		pole.position.y = bridge.foundations[i] + pole.mesh.height*.5
		var cap: MeshInstance3D = bridge.sculpture._ball(bridge,.062,Color("b49a58"))
		cap.position = Vector3(pole.position.x,bridge.foundations[i]+pole.mesh.height,pole.position.z)
		caps.append(cap)
		var bar := MeshInstance3D.new()
		var shape := CylinderMesh.new()
		shape.top_radius = .021
		shape.bottom_radius = .021
		shape.height = float(forms[i].size[0])+.20
		shape.radial_segments = 12
		bar.mesh = shape
		bar.material_override = bridge.sculpture._material(Color("b49a58"))
		body.add_child(bar)
		bar.rotation.z = PI*.5
		bar.position.y = float(forms[i].size[1])*.5+.045
		bars.append(bar)

static func amount_at(seconds: float, index: int) -> float:
	var t := fposmod(seconds,20.0) - float(index)*.4
	if t < 1.5: return 0.0
	if t < 5.5: return smoothstep(1.5,5.5,t)
	if t < 10.0: return 1.0
	if t < 14.0: return 1.0-smoothstep(10.0,14.0,t)
	return 0.0

func apply_time(seconds: float) -> void:
	# Explicit recording tool only. Evolution is selected by apply_stage instead.
	current_stage = ""
	current_time = fposmod(seconds,20.0)
	var amounts: Array[float] = []
	for i in range(5): amounts.append(amount_at(seconds,i))
	_apply_amounts(amounts)

func apply_stage(hall: String) -> void:
	current_stage = hall
	current_time = 0.0
	var capabilities := Grammar.closure(hall)
	var face := Grammar.allows(capabilities,"face")
	var translate := Grammar.allows(capabilities,"translate")
	var colour := Grammar.allows(capabilities,"colour")
	var pattern := Grammar.allows(capabilities,"tile")
	_apply_amounts([1.0,1.0,1.0,1.0,1.0] if translate else [0.0,0.0,0.0,0.0,0.0],face,colour,pattern,true)

func _apply_amounts(amounts: Array, face: bool = true, colour: bool = true, pattern: bool = true, staged: bool = false) -> void:
	poses = bridge.sculpture.model.forms().duplicate(true)
	var constraints: Array = []
	for i in range(poses.size()):
		var pose: Dictionary = poses[i]
		var amount: float = amounts[i]
		var lift := LIFT*amount
		var base_y: float = bridge.foundations[i]
		var body: Node3D = bridge.sculpture._form_bodies[i]
		body.position = Model._vec(pose.center) + Vector3.UP*(base_y+lift)
		pose.center = [body.position.x,body.position.y,body.position.z]
		pose["vertical"] = [body.position.y-float(pose.size[1])*.5,body.position.y+float(pose.size[1])*.5]
		pose["lift_m"] = lift
		pose["motif"] = MOTIFS[i]
		pose["visible"] = face
		pose["colour"] = colour
		pose["pattern"] = pattern
		body.visible = face
		body.collision_layer = 1 if face else 0
		materials[i].set_shader_parameter("reveal",1.0 if staged else smoothstep(0.05,.75,amount))
		materials[i].set_shader_parameter("colour_amount",1.0 if colour else 0.0)
		materials[i].set_shader_parameter("pattern_amount",1.0 if pattern else 0.0)
		var pole: MeshInstance3D = bridge._pins[i]
		pole.visible = face
		caps[i].visible = face and amount > 0
		bars[i].visible = face and (not staged or amount > 0)
		pole.mesh.height = (lift if staged else LIFT) + float(pose.size[1]) + .22
		pole.position.y = base_y + pole.mesh.height*.5
		caps[i].position.y = base_y + pole.mesh.height
		var metal := Color("b49a58") if colour else Color("888888")
		caps[i].material_override.albedo_color = metal
		bars[i].material_override.albedo_color = metal
		# Width belongs to scale; resize the crossbar without scaling the body.
		bars[i].scale = Vector3.ONE
		bars[i].mesh.height = float(pose.size[0])+.20
		if not face: continue
		constraints.append(pose)
		# A raised panel frees its former ground; the pole still occupies its own.
		constraints.append({"id":str(pose.id)+"_pole","center":[pose.pivot[0],base_y+pole.mesh.height*.5,pose.pivot[2]],
			"size":[.07,pole.mesh.height,.07],"yaw":0.0,"vertical":[base_y,base_y+pole.mesh.height]})
	bridge.apply_clearance(constraints)

func get_state() -> Dictionary:
	return {"time_s":current_time,"cycle_s":20 if current_stage.is_empty() else 0,"stage":current_stage,
		"driver":"recording_preview" if current_stage.is_empty() else "map_capabilities",
		"max_lift_m":LIFT,"poses":poses.duplicate(true),
		"pattern":"five original procedural motifs; nobori-inspired proportions and crossbars",
		"clearance":"plant AABB height plus margin tested against lifted panels and retained poles",
		"scope":"rigid translated faces; no cloth physics, plant growth or shade feedback"}
