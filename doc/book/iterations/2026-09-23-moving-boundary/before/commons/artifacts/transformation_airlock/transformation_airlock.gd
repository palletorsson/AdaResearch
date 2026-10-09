extends Node3D
## The chapter's three operations become a passage. Local Y=0 is the floor.
## Physical leaves follow the visible transform: no invisible opening switch,
## scaled physics nodes, player relocation or collection requirement.

signal passage_opened()
signal passage_closed()

@export var opening_seconds: float = 4.8
@export var empty_hold_seconds: float = 3.0

const DURATION := 4.8
const PLAYER_MASK := 1 | 524288
var progress: float = 0.0
var occupied: bool = false
var _empty_time: float = 0.0
var _sensor: Area3D
var _leaves: Array[AnimatableBody3D] = []
var _visuals: Array[Node3D] = []
var _shapes: Array[ConvexPolygonShape3D] = []
var _vertices: Array[PackedVector3Array] = []
var _status: Array[Label3D] = []
var _phase_lights: Array[StandardMaterial3D] = []
var _last_phase := ""
var _steel: StandardMaterial3D
var _dark: StandardMaterial3D
var _silver: StandardMaterial3D
var _cyan: StandardMaterial3D
var _amber: StandardMaterial3D

func _ready() -> void:
	_build()
	_apply_pose()

func _physics_process(delta: float) -> void:
	occupied = false
	for body in _sensor.get_overlapping_bodies():
		if is_visitor(body):
			occupied = true
			break
	_empty_time = 0.0 if occupied else _empty_time + delta
	var previous: float = progress
	if occupied:
		progress = minf(1.0, progress + delta / maxf(opening_seconds, 0.1))
	elif _empty_time >= empty_hold_seconds:
		progress = maxf(0.0, progress - delta / maxf(opening_seconds, 0.1))
	if not is_equal_approx(previous, progress):
		_apply_pose()
		if progress == 1.0: passage_opened.emit()
		if progress == 0.0: passage_closed.emit()

func is_visitor(body: Node) -> bool:
	return not is_ancestor_of(body) and (body is CharacterBody3D or body.is_in_group("player") or body.is_in_group("em_walker"))

func operation_values() -> Vector3:
	var seconds: float = progress * DURATION
	# Overlapping starts preserve three readable stages and a continuous movement.
	return Vector3(smoothstep(0.0, 1.8, seconds), smoothstep(1.5, 3.3, seconds), smoothstep(3.0, 4.8, seconds))

func _apply_pose() -> void:
	var operations: Vector3 = operation_values()
	for i in _leaves.size():
		var side: float = -1.0 if i == 0 else 1.0
		var factor: float = lerpf(1.0, 0.34, operations.z)
		var at := Vector3(side * lerpf(0.75, 2.15, operations.x), lerpf(1.4, 2.0, operations.x), -0.26)
		var turn := Basis(Vector3.BACK, side * operations.y * PI * 0.5)
		_leaves[i].transform = Transform3D(turn, at)
		_visuals[i].scale = Vector3.ONE * factor
		# Resize the actual convex resource; the AnimatableBody and collider keep scale=1.
		var points := PackedVector3Array()
		for vertex in _vertices[i]: points.append(vertex * factor)
		_shapes[i].points = points
	for i in 3:
		_phase_lights[i].emission_energy_multiplier = lerpf(0.12, 1.4, operations[i])
	var phase: String = "APPROACH TO OPEN"
	if progress > 0.0: phase = "01  /  TRANSLATE"
	if operations.y > 0.0: phase = "02  /  ROTATE"
	if operations.z > 0.0: phase = "03  /  SCALE"
	if progress >= 1.0: phase = "PASSAGE OPEN"
	if phase != _last_phase:
		for label in _status: label.text = phase
		_last_phase = phase

func _material(color: Color, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.36 if metal > 0.0 else 0.65
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func _box(parent: Node3D, title: String, size: Vector3, at: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		mesh.add_child(body)
	return mesh

func _prism(parent: Node3D, title: String, polygon: PackedVector2Array, depth: float, material: Material) -> PackedVector3Array:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
	for z_side in [-1.0, 1.0]:
		for t in range(0, triangles.size(), 3):
			for k in 3:
				var index: int = triangles[t + (k if z_side < 0.0 else 2-k)]
				var p: Vector2 = polygon[index]
				surface.add_vertex(Vector3(p.x, p.y, z_side * depth * 0.5))
	for i in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		for p in [Vector3(a.x,a.y,-depth/2),Vector3(a.x,a.y,depth/2),Vector3(b.x,b.y,depth/2),Vector3(a.x,a.y,-depth/2),Vector3(b.x,b.y,depth/2),Vector3(b.x,b.y,-depth/2)]:
			surface.add_vertex(p)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = surface.commit()
	mesh.material_override = material
	parent.add_child(mesh)
	var vertices := PackedVector3Array()
	for p in polygon:
		vertices.append(Vector3(p.x,p.y,-depth/2))
		vertices.append(Vector3(p.x,p.y,depth/2))
	return vertices

func _label(text: String, at: Vector3, font_size: int, reverse: bool = false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.003
	label.outline_size = 3
	label.position = at
	label.rotation.y = 0.0 if reverse else PI
	label.modulate = Color(0.74,0.92,0.95)
	add_child(label)
	return label

func _build() -> void:
	_steel = _material(Color("344750"), 0.75)
	_dark = _material(Color("101b24"), 0.5)
	_silver = _material(Color("a8b7b8"), 0.7)
	_cyan = _material(Color("39e3dd"), 0.25, 1.2)
	_amber = _material(Color("ffb35c"), 0.3, 0.8)
	# Fixed backs close the entire 8m bulkhead except its 3m x 2.8m aperture.
	for side in [-1.0,1.0]:
		# Half-cell collars join a 9-cell grid opening without a body-width bypass.
		_box(self,"WallCollar",Vector3(0.65,3.65,0.55),Vector3(side*4.175,1.825,0.0),_steel,true)
		_box(self,"PocketBack",Vector3(2.5,3.0,0.24),Vector3(side*2.75,1.5,0.34),_dark,true)
		_box(self,"OuterSpine",Vector3(0.25,3.65,0.95),Vector3(side*3.87,1.825,0.0),_steel,true)
		_box(self,"InnerJamb",Vector3(0.13,2.8,0.35),Vector3(side*1.565,1.4,0.18),_silver,true)
		_box(self,"JambLight",Vector3(0.035,2.55,0.02),Vector3(side*1.57,1.4,-0.01),_cyan)
		for j in 4:
			_box(self,"CoolingFin",Vector3(1.85,0.055,0.18),Vector3(side*2.78,0.35+j*0.16,0.12),_steel)
		for y in [0.25,3.35]:
			_box(self,"CornerFastener",Vector3(0.10,0.1,0.06),Vector3(side*3.87,y,-0.5),_amber)
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side*2.6,3.18,-0.18)
		add_child(shoulder)
		_prism(shoulder,"SlopingArmor",PackedVector2Array([Vector2(-1.2,-0.17),Vector2(1.2,-0.17),Vector2(1.05,0.4),Vector2(-0.85,0.55)]),0.55,_steel)
	_box(self,"Lintel",Vector3(3.0,1.0,0.75),Vector3(0,3.3,0.12),_dark,true)
	_box(self,"Brow",Vector3(4.0,0.15,0.8),Vector3(0,3.83,-0.07),_silver)
	_box(self,"HeaderFace",Vector3(3.55,0.42,0.08),Vector3(0,3.48,-0.33),_steel)
	# A flush threshold has no collision step that could trip the player.
	_box(self,"Threshold",Vector3(3.0,0.012,0.85),Vector3(0,0.006,0),_steel)
	for side in [-1.0,1.0]:
		_box(self,"FloorGuide",Vector3(0.028,0.014,2.3),Vector3(side*1.34,0.014,-1.25),_cyan)
	for i in 3:
		var glow: StandardMaterial3D = _material([Color("48d9ec"),Color("ffb451"),Color("ec73cf")][i],0.1,0.12)
		_phase_lights.append(glow)
		_box(self,"OperationLight",Vector3(0.68,0.055,0.03),Vector3((i-1)*0.93,3.08,-0.30),glow)
	_label("MAKE ROOM",Vector3(0,3.53,-0.38),70)
	_status.append(_label("APPROACH TO OPEN",Vector3(0,3.23,-0.32),32))
	_status.append(_label("APPROACH TO OPEN",Vector3(0,3.23,0.53),32,true))
	for i in 2: _build_leaf(i)
	_sensor = Area3D.new()
	_sensor.name = "VisitorClearance"
	_sensor.collision_layer = 0
	_sensor.collision_mask = PLAYER_MASK
	var collider := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(8.8,4.6,9.0)
	collider.shape = bounds
	collider.position.y = 2.0
	_sensor.add_child(collider)
	add_child(_sensor)

func _build_leaf(index: int) -> void:
	var side: float = -1.0 if index == 0 else 1.0
	var body := AnimatableBody3D.new()
	body.name = "LeftLeaf" if index == 0 else "RightLeaf"
	body.sync_to_physics = false
	body.collision_layer = 1
	add_child(body)
	_leaves.append(body)
	var visuals := Node3D.new()
	visuals.name = "Armor"
	body.add_child(visuals)
	_visuals.append(visuals)
	var polygon := PackedVector2Array([Vector2(-0.75,-1.4),Vector2(0.75,-1.4),Vector2(0.75,1.4),Vector2(-0.75,1.4)])
	var points: PackedVector3Array = _prism(visuals,"PhysicalPlate",polygon,0.26,_steel)
	_vertices.append(points)
	var collider := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = points
	collider.shape = hull
	body.add_child(collider)
	_shapes.append(hull)
	# Raised chamfered armor on both faces; the underlying sealed plate remains legible.
	for face in [-1.0,1.0]:
		for tier in 3:
			var plate := Node3D.new()
			plate.position = Vector3(0, -0.91 + tier*0.91, face*0.145)
			visuals.add_child(plate)
			_prism(plate,"ChamferedArmor",PackedVector2Array([Vector2(-0.65,-0.35),Vector2(0.47,-0.35),Vector2(0.65,-0.16),Vector2(0.65,0.35),Vector2(-0.47,0.35),Vector2(-0.65,0.16)]),0.06,_silver if tier==1 else _dark)
			_box(plate,"ArmorInlay",Vector3(0.8,0.025,0.018),Vector3(0,-0.23,face*0.045),_amber if tier==1 else _cyan)
		_box(visuals,"MeetingStrip",Vector3(0.045,2.55,0.025),Vector3(-side*0.70,0,face*0.17),_cyan)
		_box(visuals,"LockShoulder",Vector3(0.28,0.5,0.14),Vector3(side*0.52,0,face*0.23),_steel)
		_box(visuals,"LockLight",Vector3(0.06,0.32,0.018),Vector3(side*0.52,0,face*0.31),_amber)
