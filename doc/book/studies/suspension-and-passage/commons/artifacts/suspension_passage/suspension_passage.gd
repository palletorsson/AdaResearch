extends "../reference_studies/build.gd"
## Original arrangement study after Hatoum, not a reconstruction or debris simulation.
const Score = preload("./score.gd")
const Fragment = preload("../reference_studies/suspension.gd")
var pieces: Array[Node3D] = []
var cables: Array[MeshInstance3D] = []
var lifted_cells: Array[bool] = []
var arrangement := 0

func build() -> void:
	pieces.clear()
	cables.clear()
	lifted_cells.clear()
	var factory := Fragment.new()
	factory.amount = 0.80
	var stone := ShaderMaterial.new()
	stone.shader = preload("./stone.gdshader")
	var metal := material(Color(0.15, 0.135, 0.12), 0.66, 0.35)
	var wire := material(Color(0.25, 0.24, 0.23), 0.6, 0.5)
	for z in Score.SIDE:
		for x in Score.SIDE:
			var i := z * Score.SIDE + x
			var holder := Node3D.new()
			holder.name = "Fragment_%02d_%02d" % [x,z]
			add_child(holder)
			pieces.append(holder)
			lifted_cells.append(false)
			# The collider is the convex hull of the same scaled mesh vertices.
			var source: ArrayMesh = factory.fragment(i)
			var vertices: PackedVector3Array = source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for vertex in vertices:
				tool.add_vertex(vertex * Vector3(0.82, 1.35, 0.82))
			tool.generate_normals()
			var mesh := tool.commit()
			var visual := mesh_at(mesh, Vector3.ZERO, stone)
			visual.reparent(holder, false)
			var body := StaticBody3D.new()
			body.name = "Contact"
			var shape := CollisionShape3D.new()
			shape.shape = mesh.create_convex_shape(true, false)
			body.add_child(shape)
			holder.add_child(body)
			var bar := segment(Vector3(0,-0.46,0), Vector3(0,0.46,0), 0.012, metal)
			bar.reparent(holder, false)
			var bar_body := StaticBody3D.new()
			var bar_shape := CollisionShape3D.new()
			var bar_bounds := CylinderShape3D.new()
			bar_bounds.radius = 0.012
			bar_bounds.height = 0.92
			bar_shape.shape = bar_bounds
			bar_body.add_child(bar_shape)
			holder.add_child(bar_body)
			for y in 6:
				var rib := ring(Vector3(0,-0.40+y*0.16,0),0.016,0.003,metal)
				rib.reparent(holder, false)
			var site: Vector3 = Score.site(x,z)
			cables.append(segment(site + Vector3(0,1.61,0), site + Vector3(0,5.10,0), 0.0035, wire))
	for x in Score.SIDE:
		var at: Vector3 = Score.site(x,0)
		segment(Vector3(at.x,5.10,-2.70),Vector3(at.x,5.10,2.70),0.019,metal)
	for z in [-2.70,2.70]:
		segment(Vector3(-2.70,5.10,z),Vector3(2.70,5.10,z),0.024,metal)
	factory.free()
	apply_rule(arrangement)

func apply_rule(which: int) -> void:
	arrangement = clampi(which,0,1)
	for z in Score.SIDE:
		for x in Score.SIDE:
			lifted_cells[z*Score.SIDE+x] = Score.lifted(x,z,arrangement)
	update_heights()

func swap_cells(first: int, second: int) -> bool:
	if first < 0 or second < 0 or first >= pieces.size() or second >= pieces.size():
		return false
	if lifted_cells[first] == lifted_cells[second]:
		return false
	var old := lifted_cells[first]
	lifted_cells[first] = lifted_cells[second]
	lifted_cells[second] = old
	arrangement = 2
	update_heights()
	return true

func update_heights() -> void:
	var high_count := 0
	var sites: Array[Vector3] = []
	var heights: Array[float] = []
	for i in pieces.size():
		var x := i % Score.SIDE
		var z := i / Score.SIDE
		var at: Vector3 = Score.site(x,z)
		var height: float = Score.HIGH if lifted_cells[i] else Score.LOW
		pieces[i].position = at + Vector3(0,height,0)
		var top := height + 0.46
		cables[i].position = at + Vector3(0,(top+5.10)*0.5,0)
		(cables[i].mesh as CylinderMesh).height = 5.10-top
		heights.append(height)
		sites.append(at)
		high_count += 1 if lifted_cells[i] else 0
	evidence = {"fragments":pieces.size(),"raised":high_count,"sites":sites,"heights":heights,"arrangement":arrangement,"seed":821}
	state_changed.emit(evidence)
