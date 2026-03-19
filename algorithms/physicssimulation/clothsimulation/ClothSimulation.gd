extends Node3D

# @identity
# essence: F_spring = k * (|x2-x1| - rest) * dir. A grid of particles connected by springs. Cloth is not an object — it's a negotiation.
# desire: To drape, to ripple, to be grabbed. To show that softness emerges from many stiff connections.
# critical_parameter: k (stiffness) — low k = jelly cloth, high k = rigid sheet. Wind strength shapes the drama.
# triggers: Wind slider → cloth billows, stiffness slider → character changes, VR grab → cloth deforms toward hand
# emerges: Draping from gravity + constraints. Rippling from wind + spring response. Tearing (future) from exceeding spring limits.
# needs: VR wind slider [has], stiffness slider [has], VR grab [has]. Could use: pin/unpin control, tear threshold.
# relationships: Depends on mass_spring_damper (single spring → grid of springs). Feeds into soft_bodies. Lives in PhysicsSim_Springs.
# truth: Elasticity is memory. Every spring encodes where it wants to be. Cloth is a thousand memories negotiating with gravity.

## Cloth Simulation — spring-mass grid with MultiMesh rendering.
## Three cloths: hanging (pinned corners), floating (free), draped (over sphere).
## Structural + shear springs. Wind, gravity, sphere collision, VR grab.

@export var cloth_resolution: int = 8
@export var cloth_stiffness: float = 100.0
@export var cloth_damping: float = 5.0
@export var wind_strength: float = 3.0
@export var gravity_strength: float = 9.8

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

class ClothNode:
	var position: Vector3
	var velocity: Vector3
	var force: Vector3
	var mass: float
	var is_fixed: bool

	func _init(pos: Vector3, m: float, fixed: bool) -> void:
		position = pos
		velocity = Vector3.ZERO
		force = Vector3.ZERO
		mass = m
		is_fixed = fixed

	func apply_force(f: Vector3) -> void:
		if not is_fixed:
			force += f

	func update(delta: float) -> void:
		if is_fixed:
			return
		var acceleration := force / mass
		velocity += acceleration * delta
		velocity *= 0.995  # light damping
		position += velocity * delta
		force = Vector3.ZERO


class ClothPiece:
	var nodes: Array[ClothNode] = []
	var springs: Array[Vector2i] = []  # pairs of node indices
	var rest_lengths: Array[float] = []
	var origin: Vector3
	var cols: int
	var rows: int
	var mm: MultiMesh
	var mm_instance: MultiMeshInstance3D
	var line_mesh: ImmediateMesh
	var line_instance: MeshInstance3D
	var color: Color

	func build(resolution: int, size: Vector2, pos: Vector3, c: Color, pin_mode: int) -> void:
		origin = pos
		color = c
		cols = resolution + 1
		rows = resolution + 1
		var spacing_x := size.x / resolution
		var spacing_z := size.y / resolution

		# Create nodes
		for i in rows:
			for j in cols:
				var x := (j - resolution / 2.0) * spacing_x
				var z := (i - resolution / 2.0) * spacing_z
				var node_pos := pos + Vector3(x, 0, z)
				var fixed := false
				match pin_mode:
					0:  # pin top corners
						fixed = (i == 0) and (j == 0 or j == resolution)
					1:  # free
						fixed = false
					2:  # pin top edge
						fixed = (i == 0)
				nodes.append(ClothNode.new(node_pos, 1.0, fixed))

		# Structural + shear springs
		for i in rows:
			for j in cols:
				var idx := i * cols + j
				# Right neighbor
				if j < cols - 1:
					_add_spring(idx, idx + 1)
				# Bottom neighbor
				if i < rows - 1:
					_add_spring(idx, idx + cols)
				# Diagonal (shear)
				if i < rows - 1 and j < cols - 1:
					_add_spring(idx, idx + cols + 1)
				if i < rows - 1 and j > 0:
					_add_spring(idx, idx + cols - 1)

	func _add_spring(a: int, b: int) -> void:
		springs.append(Vector2i(a, b))
		rest_lengths.append(nodes[a].position.distance_to(nodes[b].position))

	func setup_rendering(parent: Node3D) -> void:
		# MultiMesh for nodes
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.instance_count = nodes.size()
		mm.visible_instance_count = nodes.size()
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		sphere.radial_segments = 6
		sphere.rings = 3
		mm.mesh = sphere

		mm_instance = MultiMeshInstance3D.new()
		mm_instance.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.3
		mm_instance.material_override = mat
		parent.add_child(mm_instance)

		# ImmediateMesh for springs
		line_mesh = ImmediateMesh.new()
		line_instance = MeshInstance3D.new()
		line_instance.mesh = line_mesh
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(color.r, color.g, color.b, 0.3)
		lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line_instance.material_override = lmat
		parent.add_child(line_instance)

	func render() -> void:
		# Update node positions
		for i in nodes.size():
			var xform := Transform3D.IDENTITY
			xform.origin = nodes[i].position
			mm.set_instance_transform(i, xform)
			var c := color if not nodes[i].is_fixed else Color(1.0, 1.0, 1.0)
			mm.set_instance_color(i, c)

		# Update spring lines
		var lmat := line_instance.material_override
		line_mesh.clear_surfaces()
		line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, lmat)
		for i in springs.size():
			var a := nodes[springs[i].x].position
			var b := nodes[springs[i].y].position
			line_mesh.surface_add_vertex(a)
			line_mesh.surface_add_vertex(b)
		line_mesh.surface_end()


var cloths: Array[ClothPiece] = []
var collision_spheres: Array[Dictionary] = []
var _time := 0.0

# VR interaction
var _left_grab := false
var _right_grab := false


func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)

	# Three cloths: hanging, free-floating, draped over sphere
	var c1 := ClothPiece.new()
	c1.build(cloth_resolution, Vector2(1.5, 1.5), Vector3(-3, 2.5, 0), Color(0.9, 0.8, 0.2), 0)
	c1.setup_rendering(self)
	cloths.append(c1)

	var c2 := ClothPiece.new()
	c2.build(cloth_resolution, Vector2(1.2, 1.2), Vector3(0, 2.0, 0), Color(0.2, 0.8, 0.9), 1)
	c2.setup_rendering(self)
	cloths.append(c2)

	var c3 := ClothPiece.new()
	c3.build(cloth_resolution, Vector2(1.0, 1.0), Vector3(3, 2.5, 0), Color(0.9, 0.3, 0.8), 2)
	c3.setup_rendering(self)
	cloths.append(c3)

	# Collision spheres
	_add_collision_sphere(Vector3(0, 0.8, 0), 0.4, Color(0.3, 0.9, 0.9))
	_add_collision_sphere(Vector3(3, 1.5, 0), 0.5, Color(0.9, 0.3, 0.3))

	_setup_labels()
	_setup_controls()
	_setup_vr()


func _add_collision_sphere(pos: Vector3, radius: float, color: Color) -> void:
	collision_spheres.append({"pos": pos, "radius": radius})
	var mesh := MeshInstance3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = radius
	smesh.height = radius * 2.0
	mesh.mesh = smesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Cloth Simulation"
	title.font_size = 20
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 4.5, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	var eq := Label3D.new()
	eq.text = "F_spring = k * (|x2-x1| - rest) * dir"
	eq.font_size = 12
	eq.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eq.position = Vector3(0.0, 3.9, 3.0)
	eq.modulate = Color(1, 1, 1, 0.5)
	add_child(eq)

	# Per-cloth labels
	for data in [["Pinned Corners", Vector3(-3, 3.5, 1.5)], ["Free Float", Vector3(0, 3.5, 1.5)], ["Pinned Edge", Vector3(3, 3.5, 1.5)]]:
		var lbl := Label3D.new()
		lbl.text = data[0]
		lbl.font_size = 14
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = data[1]
		lbl.modulate = Color(1, 1, 1, 0.6)
		add_child(lbl)


func _setup_controls() -> void:
	var panel := Node3D.new()
	panel.position = Vector3(0.0, 1.0, 3.5)
	add_child(panel)

	# Wind slider
	var wind_slider = SLIDER_HORIZONTAL.instantiate()
	wind_slider.name = "WindSlider"
	wind_slider.position = Vector3(-0.8, 0, 0)
	wind_slider.rotation_degrees.x = -45
	wind_slider.scale = Vector3(0.7, 0.7, 0.7)
	var wlabel = wind_slider.get_node_or_null("Frame/LabelName")
	if wlabel:
		wlabel.text = "WIND"
	panel.add_child(wind_slider)
	wind_slider.slider_moved.connect(func(_pos):
		if wind_slider.has_method("get_normalized_value"):
			wind_strength = wind_slider.get_normalized_value() * 10.0
	)

	# Stiffness slider
	var stiff_slider = SLIDER_HORIZONTAL.instantiate()
	stiff_slider.name = "StiffnessSlider"
	stiff_slider.position = Vector3(0.8, 0, 0)
	stiff_slider.rotation_degrees.x = -45
	stiff_slider.scale = Vector3(0.7, 0.7, 0.7)
	var slabel = stiff_slider.get_node_or_null("Frame/LabelName")
	if slabel:
		slabel.text = "STIFFNESS"
	panel.add_child(stiff_slider)
	stiff_slider.slider_moved.connect(func(_pos):
		if stiff_slider.has_method("get_normalized_value"):
			cloth_stiffness = 20.0 + stiff_slider.get_normalized_value() * 180.0
	)


func _setup_vr() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if xr_origin:
		var left = xr_origin.get_node_or_null("LeftController")
		var right = xr_origin.get_node_or_null("RightController")
		if left:
			left.button_pressed.connect(func(b): if b == "trigger_click" or b == "grip_click": _left_grab = true)
			left.button_released.connect(func(b): if b == "trigger_click" or b == "grip_click": _left_grab = false)
		if right:
			right.button_pressed.connect(func(b): if b == "trigger_click" or b == "grip_click": _right_grab = true)
			right.button_released.connect(func(b): if b == "trigger_click" or b == "grip_click": _right_grab = false)


func _process(delta: float) -> void:
	_time += delta

	for cloth in cloths:
		_apply_forces(cloth)
		_update_physics(cloth, delta)
		_apply_constraints(cloth)
		_handle_collisions(cloth)
		cloth.render()

	_vr_grab()


func _apply_forces(cloth: ClothPiece) -> void:
	var wind_dir := Vector3(sin(_time * 0.7), 0, cos(_time * 0.5)).normalized()
	for node in cloth.nodes:
		node.apply_force(Vector3(0, -gravity_strength * node.mass, 0))
		# Wind with noise
		var wind_noise := sin(_time * 3.0 + node.position.x * 2.0 + node.position.z) * 0.5
		node.apply_force(wind_dir * (wind_strength + wind_noise))


func _update_physics(cloth: ClothPiece, delta: float) -> void:
	for node in cloth.nodes:
		node.update(delta)


func _apply_constraints(cloth: ClothPiece) -> void:
	# Spring constraints (position-based correction)
	for iter in 3:
		for i in cloth.springs.size():
			var n1 := cloth.nodes[cloth.springs[i].x]
			var n2 := cloth.nodes[cloth.springs[i].y]
			var diff := n2.position - n1.position
			var dist := diff.length()
			if dist < 0.001:
				continue
			var rest := cloth.rest_lengths[i]
			var correction := diff.normalized() * (dist - rest) * 0.5
			if not n1.is_fixed:
				n1.position += correction * 0.5
			if not n2.is_fixed:
				n2.position -= correction * 0.5


func _handle_collisions(cloth: ClothPiece) -> void:
	for node in cloth.nodes:
		if node.is_fixed:
			continue
		# Floor
		if node.position.y < 0.0:
			node.position.y = 0.0
			node.velocity.y = 0.0
		# Spheres
		for sphere in collision_spheres:
			var diff := node.position - sphere["pos"]
			var dist := diff.length()
			if dist < sphere["radius"]:
				node.position = sphere["pos"] + diff.normalized() * sphere["radius"]
				node.velocity *= 0.5


func _vr_grab() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if not xr_origin:
		return

	var controllers := []
	if _left_grab:
		var left = xr_origin.get_node_or_null("LeftController")
		if left:
			controllers.append(to_local(left.global_position))
	if _right_grab:
		var right = xr_origin.get_node_or_null("RightController")
		if right:
			controllers.append(to_local(right.global_position))

	for ctrl_pos in controllers:
		for cloth in cloths:
			for node in cloth.nodes:
				if node.is_fixed:
					continue
				if node.position.distance_to(ctrl_pos) < 0.2:
					node.apply_force((ctrl_pos - node.position).normalized() * 50.0)
					node.velocity *= 0.8


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
