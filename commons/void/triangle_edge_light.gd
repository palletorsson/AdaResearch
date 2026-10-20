extends Node3D
## Read-only light skin for existing triangle geometry and its real handles.
## Two lights per artifact, never one light per edge or vertex.
const CAPACITY := 128
var kind := "boundary"
var source: Node3D
var tubes: MultiMeshInstance3D
var lamps: Array[OmniLight3D] = []
var segments: Array[Vector3] = []
var watched: Dictionary = {}
var held: Dictionary = {}
var glow_left := 0.0
var tick := 0.0

func _ready() -> void:
	source = get_parent()
	set_as_top_level(true)
	global_transform = Transform3D.IDENTITY
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("ffd6e9")
	finish.emission_enabled = true
	finish.emission = Color("ffa5d3")
	finish.emission_energy_multiplier = 1.6
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var tube := CylinderMesh.new()
	tube.top_radius = .012; tube.bottom_radius = .012
	tube.height = 1; tube.radial_segments = 8; tube.rings = 0
	tube.material = finish
	tubes = MultiMeshInstance3D.new()
	tubes.name = "LitEdges"
	tubes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tubes.multimesh = MultiMesh.new()
	tubes.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tubes.multimesh.mesh = tube
	tubes.multimesh.instance_count = CAPACITY
	tubes.multimesh.visible_instance_count = 0
	add_child(tubes)
	for i in range(2):
		var lamp := OmniLight3D.new()
		lamp.name = "EdgeLight%d" % i
		lamp.light_color = Color("ffd0e6")
		lamp.omni_range = 3.3; lamp.omni_attenuation = 1.3
		lamp.shadow_enabled = false; lamp.visible = false
		add_child(lamp); lamps.append(lamp)
	add_to_group("void_triangle_light")
	refresh()

func _process(delta: float) -> void:
	glow_left = maxf(0, glow_left-delta)
	if not held.is_empty(): glow_left = 2.0
	tick += delta
	if tick < .05: return
	tick = 0
	refresh()

func pulse() -> void:
	glow_left = 2.0

func watch(point: Node) -> void:
	if not is_instance_valid(point) or watched.has(point.get_instance_id()): return
	var id := point.get_instance_id()
	if not point.has_signal("picked_up"): return
	watched[id] = true
	point.picked_up.connect(func(_object): held[id] = true; pulse())
	point.dropped.connect(func(_object): held.erase(id); pulse())
	point.tree_exiting.connect(func(): held.erase(id); watched.erase(id))
	if point.has_method("is_picked_up") and point.is_picked_up(): held[id] = true

func edge(a: Vector3, b: Vector3) -> void:
	if a.distance_squared_to(b) > .000001:
		segments.append(a); segments.append(b)

func refresh() -> void:
	segments.clear()
	match kind:
		"boundary":
			for line in source.snap_lines:
				watch(line.endpoint_a); watch(line.endpoint_b)
				edge(line.endpoint_a.global_position, line.endpoint_b.global_position)
		"drawing":
			watch(source._grab_point)
			for point in source.point_indicators: watch(point)
			var pairs: Dictionary = {}
			for face in source.completed_triangles:
				for i in range(3): pairs[Vector2i(mini(face.points[i],face.points[(i+1)%3]),maxi(face.points[i],face.points[(i+1)%3]))] = true
			for i in range(1,source.current_path.size()): pairs[Vector2i(source.current_path[i-1],source.current_path[i])] = true
			for pair in pairs: edge(source.placed_points[pair.x],source.placed_points[pair.y])
		"quad", "strip":
			for point in source.drag_points.get_spheres(): watch(point)
			var vertices: Array = source.vertex_positions
			var pairs: Dictionary = {}
			if kind == "quad":
				for pair in [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,0),Vector2i(0,2)]: pairs[pair] = true
			else:
				for i in range(vertices.size()-2):
					for pair in [Vector2i(i,i+1),Vector2i(i+1,i+2),Vector2i(i,i+2)]: pairs[pair] = true
			for pair in pairs: edge(source.to_global(vertices[pair.x]),source.to_global(vertices[pair.y]))
		"table":
			for piece in source.pieces:
				watch(piece)
				# Only the held face shines; the whole table does not become a lamp.
				if not held.has(piece.get_instance_id()): continue
				var vertices := [Vector3(-.23,.015,-.133),Vector3(.23,.015,-.133),Vector3(0,.015,.265)]
				for i in range(3): edge(piece.to_global(vertices[i]),piece.to_global(vertices[(i+1)%3]))
	for panel in source.find_children("*", "Node3D", false, false):
		if panel.get("buttons") is Dictionary and not watched.has(panel.get_instance_id()):
			watched[panel.get_instance_id()] = true
			for button in panel.buttons.values():
				if button.has_signal("pressed"): button.pressed.connect(pulse)
	_render()

func _render() -> void:
	var count := mini(segments.size()/2,CAPACITY) if glow_left>0 else 0
	tubes.multimesh.visible_instance_count = count
	var bounds := AABB()
	for i in range(count):
		var a := segments[i*2]; var b := segments[i*2+1]
		var offset := b-a
		var rotation := Basis(Quaternion(Vector3.UP,offset.normalized()))
		rotation.y *= offset.length()
		tubes.multimesh.set_instance_transform(i,Transform3D(rotation,(a+b)*.5))
		bounds = AABB(a,Vector3.ZERO) if i==0 else bounds.expand(a)
		bounds = bounds.expand(b)
	tubes.multimesh.custom_aabb = bounds.grow(.02) if count>0 else AABB()
	for i in range(2):
		lamps[i].visible = count>0
		if count == 0: continue
		var segment := mini(count-1, floori(float(count)*(i+.5)/2))
		lamps[i].position = (segments[segment*2]+segments[segment*2+1])*.5
		lamps[i].light_energy = .8*minf(1,glow_left/.35)
