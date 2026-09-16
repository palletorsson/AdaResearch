# FoldedStrip.gd - Editable triangle strip, with an optional animated folding study
extends Node3D

# @identity
# essence: triangle_strip(24) — 26 shared vertices start as one tilted, planar ribbon
# desire: learner feels how topology (which vertices connect) differs from geometry (where vertices are)
# critical_parameter: vertex positions — neighbours share an edge while their planes can diverge
# triggers: dragging any of the 26 vertex grab spheres; study:1 opts this placement into an animated folding study
# emerges: mesh topology as a constraint — shared edges mean vertices drag each other's neighbours
# needs: [has 26 grabbable vertex handles [has], optional folding study with manual interruption]
# relationships: extends triangleprofiles into 3D; shows how strip topology enables organic forms
# truth: topology (which vertices are connected) is more fundamental than geometry (where they sit)

@export var color_main: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var color_alt: Color = Color(0.8, 0.2, 0.3, 1.0)

var vertex_color: Color = Color(0.2, 0.8, 0.3, 1.0)
@export var sphere_scale: float = 0.3
@export var strip_y_offset: float = 0.25
@export var num_triangles: int = 24
@export var strip_length: float = 4.0
@export var base_y: float = 0.0
@export var height: float = 0.5

## Freeze behavior options
@export var alter_freeze : bool = false

## AXIS — HOW MUCH OF ITS OWN MAKING THE RIBBON ADMITS. Changing facture keeps the same
## 26 points, the same 24 triangles, the same handles on the same corners. What changes is
## what the strip is willing to say it is. A primitive is met before any argument has been
## made, so this is the first argument it makes — whether a surface is a thing the world
## has or a thing somebody built out of parts.
##
##   facet     the unit announced — one flat plane per triangle, adjacent triangles in
##             alternating colours, hard normals. You can count what it is made of.
##   cast      one colour, normals averaged across the shared edges. The triangles vanish
##             and the strip reads as one continuous sheet, even though its geometry
##             still consists of the same triangles.
##   armature  the faces gone, only the edges standing as thin tubes. The topology alone —
##             which vertices are connected, which is the whole of what this artifact
##             claims is fundamental.
##   shell     every triangle given thickness, so the ribbon gains rims you can see
##             end-on. A surface has no thickness; a made thing does.
##
## Shared vocabulary with [[triangleprofiles]], a related surface wrapped on a square, so
## the two cannot stand in one room with one calling its triangles evidence and the other
## calling them nothing.
##
## Source vertex_positions, DragPointSet handles and drag paths stay the same
## under all four values. Armature adds tubes; shell adds separate prisms, including
## internal rims. Neither treatment creates a physical surface collider.
@export var facture: String = "facet"
const FACTURES: PackedStringArray = ["facet", "cast", "armature", "shell"]
## Rim depth for `shell`, in metres. Small against strip_length (4 m) — thick card, not a wall.
const SHELL_THICKNESS := 0.06
## Tube radius for `armature`, in metres. Fat enough to survive a capture downscale.
const WIRE_RADIUS := 0.012

var strip_mesh: MeshInstance3D
var drag_points: DragPointSet
var vertex_positions: Array[Vector3] = []
var fold_study: Node
var _study_requested := false

func _ready():
	strip_mesh = MeshInstance3D.new()
	strip_mesh.name = "StripMesh"
	add_child(strip_mesh)

	_initialize_straight_strip()
	_setup_drag_points()
	update_mesh()
	_sync_fold_study()

## The animated study is placement-specific. Existing tokens retain manual editing.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("facture"):
		var requested := str(config["facture"]).strip_edges().to_lower()
		requested = requested if FACTURES.has(requested) else "facet"
		if requested != facture:
			facture = requested
			if is_instance_valid(strip_mesh):
				update_mesh()
	if config.has("study"):
		var requested = config["study"]
		if requested is bool or requested is int or requested is float:
			_study_requested = bool(requested)
		else:
			_study_requested = str(requested).strip_edges().to_lower() in ["1", "true", "yes", "on"]
	_sync_fold_study()

func _sync_fold_study() -> void:
	if not _study_requested:
		if is_instance_valid(fold_study):
			remove_child(fold_study)
			fold_study.queue_free()
			fold_study = null
		return
	if is_instance_valid(fold_study) or not is_inside_tree() or not is_instance_valid(drag_points):
		return
	# Ordinary manual strips do not need the study controller.
	var study_script = load("res://commons/primitives/folded_strip/folded_strip_study.gd")
	if study_script == null:
		push_error("folded_strip: the requested folding study could not be loaded")
		return
	fold_study = study_script.new()
	fold_study.name = "FoldStudy"
	add_child(fold_study)
	fold_study.call("setup", self)


func _initialize_straight_strip():
	# Both rows lie in one plane: their different heights tilt it, rather than fold it.
	vertex_positions.clear()

	var num_verts = num_triangles + 2
	var segment_width = strip_length / float(num_verts - 1)
	var start_x = -strip_length / 2.0

	for i in range(num_verts):
		var x = start_x + i * segment_width

		# Alternate between front/back Z positions and vary height to make it stand
		# Even indices: front row (z positive), Odd indices: back row (z negative)
		var z_offset: float
		var y_val: float

		if i % 2 == 0:
			# Front row - lower, extends forward
			z_offset = 0.15
			y_val = base_y + height * 0.3 + strip_y_offset
		else:
			# Back row - higher, extends backward
			z_offset = -0.15
			y_val = base_y + height + strip_y_offset

		vertex_positions.append(Vector3(x, y_val, z_offset))

func _setup_drag_points():
	drag_points = DragPointSet.new()
	drag_points.name = "GrabPoints"
	add_child(drag_points)
	drag_points.point_moved.connect(_on_point_moved)

	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		var col = color_main if (i % 2 == 0) else color_alt
		point_configs.append({
			"id": i,
			"name": "Grab_%02d" % i,
			"position": vertex_positions[i],
			"meta": {"point_index": i},
			"scale": sphere_scale,
			"color": col
		})

	drag_points.setup(point_configs, {
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true
	})

func update_mesh():
	var _f = str(facture).strip_edges().to_lower()
	facture = _f if FACTURES.has(_f) else "facet"

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	strip_mesh.material_override = mat
	
	for i in range(num_triangles):
		if i + 2 >= vertex_positions.size():
			break
			
		var triangle := _oriented_triangle(i)
		
		# Alternating colors: Main vs Alt
		# A consecutive triple is one triangle; a crease needs different planes.
		var col = color_main
		if i % 2 != 0:
			col = color_alt
			
		add_double_sided_triangle(st, triangle[0], triangle[1], triangle[2], col)

	strip_mesh.mesh = st.commit()

	# Other treatments read the same source positions and connectivity.
	if facture != "facet":
		_apply_facture()

func add_double_sided_triangle(st: SurfaceTool, v1, v2, v3, color: Color):
	# One coherent face. CULL_DISABLED displays both sides without coincident copies
	# with opposing normals fighting for the same pixels.
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	# Godot uses clockwise front faces; agree with SurfaceTool.generate_normals().
	var normal = -edge1.cross(edge2).normalized()
	
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(0,0))
	st.add_vertex(v1)
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(1,0))
	st.add_vertex(v2)
	st.set_color(color)
	st.set_normal(normal)
	st.set_uv(Vector2(0,1))
	st.add_vertex(v3)
	

func apply_paper_material(mesh_instance: MeshInstance3D, color: Color):
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.95) # Paper white
	material.roughness = 1.0
	material.metallic = 0.0
	material.metallic_specular = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # Render both sides anyway

	# To make it look cool, maybe use the shader?
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		var sm = ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("wireframe_color", Color.BLACK)
		sm.set_shader_parameter("fill_color", Color(0.95, 0.95, 1.0)) # White-blue paper
		mesh_instance.material_override = sm
	else:
		mesh_instance.material_override = material

func reset_strip():
	if is_instance_valid(fold_study):
		var held: Dictionary = fold_study.get("held")
		if not held.is_empty():
			return
	_initialize_straight_strip()
	if drag_points:
		drag_points.set_points_positions(vertex_positions)
	update_mesh()
	if is_instance_valid(fold_study):
		fold_study.call("restart")

func _on_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	if is_instance_valid(fold_study) and bool(fold_study.call("is_playing")):
		return
	var point_index: int = int(meta.get("point_index", index))
	if point_index >= 0 and point_index < vertex_positions.size():
		if vertex_positions[point_index].distance_squared_to(position) >= 0.000000000001:
			vertex_positions[point_index] = position
			update_mesh()

func _on_point_picked_up(_index: int, _pickable, _meta: Dictionary) -> void: pass
func _on_point_dropped(_index: int, _pickable, _meta: Dictionary) -> void: pass

func print_help():
	print("=== Folded Strip (Editable) ===")
	print("Drag any vertex sphere to reshape the strip.")
	print("R: Reset to standing position")


# ── FACTURE ──────────────────────────────────────────────────────────────────
# Three restatements of a strip that has already been built. Each one reads
# vertex_positions and num_triangles — the same numbers the legacy path read — and writes
# only strip_mesh.mesh and strip_mesh.material_override. Nothing here touches the drag
# handles, the topology, or a single vertex position.

func _apply_facture() -> void:
	var st := SurfaceTool.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	match facture:
		"cast":
			# One colour and averaged normals on consistently oriented triangles.
			# Smoothing changes the shading, not the strip's actual creases.
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(num_triangles):
				if i + 2 >= vertex_positions.size():
					break
				var triangle := _oriented_triangle(i)
				_tri(st, triangle[0], triangle[1], triangle[2], color_main, false)
			st.index()
			st.generate_normals()
		"armature":
			# Faces gone, edge graph standing. Tubes, not PRIMITIVE_LINES: a one-pixel
			# wire disappears when a capture is downscaled, and an axis that disappears
			# measures the same as an axis that does nothing.
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for e in _unique_edges():
				_tube(st, vertex_positions[e.x], vertex_positions[e.y], WIRE_RADIUS, color_main)
		"shell":
			# Every triangle given a body. The ribbon keeps its exact surface and gains
			# rims you can see end-on — the moment a described surface becomes a made one.
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(num_triangles):
				if i + 2 >= vertex_positions.size():
					break
				var col: Color = color_main if (i % 2) == 0 else color_alt
				var triangle := _oriented_triangle(i)
				_prism(st, triangle[0], triangle[1], triangle[2], SHELL_THICKNESS, col)
		_:
			return

	strip_mesh.mesh = st.commit()
	strip_mesh.material_override = mat


## Successive triples in a triangle strip reverse winding. Swap the first two
## corners on odd faces so normals agree across the planar starting surface.
func _oriented_triangle(index: int) -> Array[Vector3]:
	if index % 2 == 0:
		return [vertex_positions[index], vertex_positions[index + 1], vertex_positions[index + 2]]
	return [vertex_positions[index + 1], vertex_positions[index], vertex_positions[index + 2]]


## Every edge of the strip once — the rails (i,i+1) and the rungs (i,i+2) that make the
## triangles share sides in the first place.
func _unique_edges() -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for i in range(num_triangles):
		if i + 2 >= vertex_positions.size():
			break
		for pair in [Vector2i(i, i + 1), Vector2i(i + 1, i + 2), Vector2i(i, i + 2)]:
			var lo: int = mini(int(pair.x), int(pair.y))
			var hi: int = maxi(int(pair.x), int(pair.y))
			var key: int = lo * 100000 + hi
			if seen.has(key):
				continue
			seen[key] = true
			out.append(Vector2i(lo, hi))
	return out


## One triangle. flat=true stamps the face normal on all three corners (hard edges);
## flat=false leaves normals unset so SurfaceTool.generate_normals() can average them.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, flat: bool) -> void:
	# Match Godot's generated smooth normals; extrusion uses its own geometric normal.
	var n: Vector3 = -(b - a).cross(c - a).normalized()
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(b)
	if flat:
		st.set_normal(n)
	st.set_color(col)
	st.add_vertex(c)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, col: Color) -> void:
	_tri(st, p0, p1, p2, col, true)
	_tri(st, p0, p2, p3, col, true)


## A three-sided tube from a to b — the cheapest thing that still reads as a wire at
## capture distance.
func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.000001:
		return
	var n: Vector3 = d.normalized()
	var seed_up: Vector3 = Vector3.UP
	if absf(n.dot(Vector3.UP)) > 0.9:
		seed_up = Vector3.RIGHT
	var u: Vector3 = n.cross(seed_up).normalized() * r
	var v: Vector3 = n.cross(u).normalized() * r
	var off: Array = []
	for k in range(3):
		var ang: float = TAU * float(k) / 3.0
		off.append(u * cos(ang) + v * sin(ang))
	for k in range(3):
		var o0: Vector3 = off[k]
		var o1: Vector3 = off[(k + 1) % 3]
		_quad(st, a + o0, a + o1, b + o1, b + o0, col)


## One triangle extruded into a slab of thickness t, rims in a darker tone so the edge
## you can now see end-on is legible against the face.
func _prism(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, t: float, col: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if n.length_squared() < 0.5:
		return
	var h: Vector3 = n * (t * 0.5)
	var a0: Vector3 = a + h
	var b0: Vector3 = b + h
	var c0: Vector3 = c + h
	var a1: Vector3 = a - h
	var b1: Vector3 = b - h
	var c1: Vector3 = c - h
	_tri(st, a0, b0, c0, col, true)
	_tri(st, a1, c1, b1, col, true)
	var rim: Color = col.darkened(0.42)
	_quad(st, a0, b0, b1, a1, rim)
	_quad(st, b0, c0, c1, b1, rim)
	_quad(st, c0, a0, a1, c1, rim)
