extends Node3D
## Approach-height turning drums, with continuous and held comparisons behind them.
## Twelve poses stay fixed on each carrier; the carrier really rotates in world space.
## No scene-wide flashing, camera motion, hidden collision or score gates.
const Motion = preload("res://commons/artifacts/transformation_sampling/motion.gd")
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const SHAPES := ["cube","sphere","asymmetric"]
const INTERVALS := [1.0/3.0,1.0,4.0]
const COLORS := [Color("63d6ed"),Color("edb567"),Color("d987cf"),Color("92d7a0")]

@export var shape_name: String = "cube"
@export var interval: float = 1.0
@export var marked: bool = false
@export var playing: bool = true
@export var plane_height: float = 1.7
@export var drum_rate: float = TAU / 6.0
@export var show_comparisons: bool = false
var elapsed: float = 0.0
var stations: Array[Dictionary] = []
var _body_roots: Array[Node3D] = []
var _marker_nodes: Array[Node3D] = []
var _controls: Array[Label3D] = []
var _readout_time: float = 0.0

func _ready() -> void:
	for i in 4: _station(i)
	_build_controls()
	update_poses()

func _process(delta: float) -> void:
	if playing: elapsed += maxf(delta,0.0)
	update_poses()
	_readout_time += delta
	if _readout_time > 0.12:
		_readout_time = 0.0
		_update_text()

func update_poses() -> void:
	var captured: float = Motion.sample_time(elapsed,interval)
	for station in stations:
		station.live.transform = Motion.pose(station.mode,elapsed)
		station.sample.transform = Motion.pose(station.mode,captured)
		station.drum.rotation.y = fposmod(elapsed * drum_rate, TAU)

func seek(time: float) -> void:
	elapsed = maxf(0.0,time)
	playing = false
	update_poses()
	_update_text()

func set_shape(value: String) -> void:
	if value not in SHAPES: return
	shape_name = value
	_marker_nodes.clear()
	for body in _body_roots:
		for child in body.get_children():
			body.remove_child(child)
			child.queue_free()
		_dress(body,body.get_meta("body_color"))
	_update_text()

func set_mark(value: bool) -> void:
	marked = value
	for marker in _marker_nodes: marker.visible = marked
	_update_text()

func set_interval(value: float) -> void:
	interval = clampf(value,1.0/12.0,8.0)
	update_poses()
	_update_text()

func set_comparisons(value: bool) -> void:
	show_comparisons = value
	for station in stations:
		for node in station.comparisons: node.visible = value

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	# Colour never follows angle: the body itself is the comparison.
	return material

func _body(parent: Node3D, color: Color) -> Node3D:
	var body := Node3D.new()
	body.set_meta("body_color",color)
	parent.add_child(body)
	_body_roots.append(body)
	_dress(body,color)
	return body

func _dress(body: Node3D, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "BodyGeometry"
	if shape_name == "cube":
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE*0.55
		mesh.mesh = cube
	elif shape_name == "sphere":
		var sphere := SphereMesh.new()
		sphere.radius = 0.32
		sphere.height = 0.64
		sphere.radial_segments = 64
		sphere.rings = 32
		mesh.mesh = sphere
	else:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var points: PackedVector3Array = Motion.asymmetric_points()
		for indices in [[0,2,1],[0,1,3],[1,2,3],[2,0,3]]:
			for index in indices: surface.add_vertex(points[index])
		surface.generate_normals()
		mesh.mesh = surface.commit()
	mesh.material_override = _material(color)
	body.add_child(mesh)
	if shape_name != "sphere":
		# At eye level the rear faces can share one shade. Keep every edge equally
		# legible; no distinguished edge is added until the witness mark is enabled.
		var vertices: PackedVector3Array = Motion.cube_points() if shape_name == "cube" else Motion.asymmetric_points()
		var edge_material := _material(color.lightened(0.65))
		edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var lines := ImmediateMesh.new()
		lines.surface_begin(Mesh.PRIMITIVE_LINES,edge_material)
		for i in vertices.size():
			for j in range(i+1,vertices.size()):
				if shape_name == "cube" and not is_equal_approx(vertices[i].distance_to(vertices[j]),0.55): continue
				lines.surface_add_vertex(vertices[i]*1.002)
				lines.surface_add_vertex(vertices[j]*1.002)
		lines.surface_end()
		var edges := MeshInstance3D.new()
		edges.name = "BodyEdges"
		edges.mesh = lines
		body.add_child(edges)
	var marker := MeshInstance3D.new()
	marker.name = "WitnessMark"
	var bead := SphereMesh.new()
	bead.radius = 0.027
	bead.height = 0.054
	bead.radial_segments = 12
	bead.rings = 6
	marker.mesh = bead
	marker.material_override = _material(Color("f3f0e5"))
	marker.position = Motion.mark_point(shape_name)
	marker.visible = marked
	body.add_child(marker)
	_marker_nodes.append(marker)

func _label(parent: Node3D, text: String, at: Vector3, size: int = 28) -> Label3D:
	var label := Parts.label(parent,text,at,size)
	label.pixel_size = 0.0035
	label.outline_size = 4
	return label

func _station(index: int) -> void:
	var root := Node3D.new()
	root.name = Motion.MODES[index].capitalize()
	root.position = Vector3((0.5-index%2)*4.4,0,floori(float(index)/2.0)*6.0)
	add_child(root)
	var color: Color = COLORS[index]
	# The narrow stationary support leaves room for feet beneath the disc's edge.
	var support_height: float = plane_height - 0.04
	Parts.box(root,"SpindleSupport",Vector3(0.62,support_height,0.62),Vector3(0,support_height*0.5,0),Color("23313b"))
	Parts.box(root,"Foot",Vector3(0.74,0.06,0.74),Vector3(0,0.03,0),Color("18232d"))
	var roots: Array[Node3D] = []
	var comparisons: Array[Node3D] = []
	for j in 2:
		var mount := Node3D.new()
		mount.position = Vector3((0.5-j)*1.9,1.75,2.3)
		root.add_child(mount)
		mount.visible = show_comparisons
		comparisons.append(mount)
		roots.append(_body(mount,color))
		# Fixed crosshair proves that the translating body moved relative to its frame.
		Parts.box(mount,"ReferenceX",Vector3(1.55,0.015,0.018),Vector3(0,-0.61,0),Color("73828c"),false)
		Parts.box(mount,"ReferenceZ",Vector3(0.018,0.015,0.65),Vector3(0,-0.61,0),Color("73828c"),false)
		var comparison_label := _label(root,"CONTINUOUS" if j==0 else "HELD SAMPLE",Vector3(mount.position.x,2.3,2.35),25)
		comparison_label.visible = show_comparisons
		comparisons.append(comparison_label)
	# A fixed pose facing radially outwards arrives front-facing as the carrier turns.
	var drum := Node3D.new()
	drum.name = "TurningDrum"
	drum.position = Vector3(0,plane_height,0)
	root.add_child(drum)
	var disc := MeshInstance3D.new()
	disc.name = "ViewingPlane"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.10
	cylinder.bottom_radius = 1.10
	cylinder.height = 0.04
	cylinder.radial_segments = 48
	disc.mesh = cylinder
	disc.material_override = _material(Color("42515a"))
	disc.position = Vector3(0,-0.02,0)
	drum.add_child(disc)
	# A pale spoke makes carrier rotation visible even when a body is symmetric.
	Parts.box(drum,"CarrierSpoke",Vector3(0.025,0.006,1.06),Vector3(0,0.004,-0.53),color,false)
	var frames: Array[Node3D] = []
	for k in 12:
		var phase: float = TAU*k/12.0
		var mount := Node3D.new()
		mount.position = Vector3(sin(phase)*0.84,0.20,-cos(phase)*0.84)
		mount.rotation.y = -phase
		mount.scale = Vector3.ONE*0.44
		drum.add_child(mount)
		var frame: Node3D = _body(mount,color)
		frame.transform = Motion.pose(Motion.MODES[index],Motion.PERIOD*k/12.0)
		frames.append(frame)
	Parts.box(root,"CaptionCase",Vector3(0.9,0.45,0.045),Vector3(0,1.17,-0.34),Color("18232d"),false)
	_label(root,Motion.MODES[index].to_upper(),Vector3(0,1.30,-0.367),24)
	_label(root,"TWELVE POSES",Vector3(0,1.16,-0.367),16)
	var readout: Label3D = _label(root,"",Vector3(0,1.03,-0.367),12)
	stations.append({"mode":Motion.MODES[index],"live":roots[0],"sample":roots[1],"frames":frames,"readout":readout,"root":root,"drum":drum,"disc":disc,"comparisons":comparisons})

func _build_controls() -> void:
	Parts.box(self,"ControlPlinth",Vector3(2.8,1.05,0.65),Vector3(0,0.525,-3),Color("25363f"))
	Parts.box(self,"ControlBack",Vector3(2.8,0.45,0.15),Vector3(0,1.26,-2.90),Color("25363f"))
	for i in 5:
		var button: Node3D = PushButton.instantiate()
		button.position = Vector3((2-i)*0.50,1.12,-3.05)
		add_child(button)
		button.pressed.connect(_press.bind(i))
		_controls.append(_label(self,"",Vector3((2-i)*0.50,1.37,-3.0),23))
	_label(self,"WHAT MOVED BETWEEN THE PICTURES?",Vector3(0,1.75,-3.0),39)
	_update_text()

func _press(index: int) -> void:
	match index:
		0: set_shape(SHAPES[(SHAPES.find(shape_name)+1)%SHAPES.size()])
		1: set_mark(not marked)
		2:
			var nearest := 0
			for i in INTERVALS.size():
				if absf(INTERVALS[i]-interval)<0.01: nearest=i
			set_interval(INTERVALS[(nearest+1)%INTERVALS.size()])
		3: playing = not playing
		4: elapsed = 0.0
	update_poses()
	_update_text()

func _update_text() -> void:
	var captured: float = Motion.sample_time(elapsed,interval)
	for station in stations:
		station.readout.text = "clock %.2f s / captured %.2f s" % [elapsed,captured]
	if _controls.size()==5:
		var names := [shape_name.to_upper(),"MARK ON" if marked else "ADD MARK","SAMPLE\n%.2f s"%interval,"PAUSE" if playing else "PLAY","RESET"]
		for i in 5: _controls[i].text=names[i]
