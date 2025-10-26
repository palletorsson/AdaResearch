# PolyhedraShowcase.gd - Visual demonstration of polyhedra for infoboards
extends Node3D

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")

@export var showcase_type: String = "platonic_solids"
@export var spacing: float = 1.5

var polyhedra: Array[Node3D] = []

func _ready():
	match showcase_type:
		"platonic_solids":
			create_platonic_solids_showcase()
		"johnson_solids":
			create_johnson_solids_showcase()
		"single_tetrahedron":
			create_single_polyhedron("tetrahedron")
		"single_octahedron":
			create_single_polyhedron("octahedron")
		"single_cube":
			create_single_polyhedron("cube")

func create_platonic_solids_showcase():
	var solids = [
		{"create": PolyhedronFactory.create_tetrahedron(0.4, Color.MAGENTA), "name": "Tetrahedron"},
		{"create": PolyhedronFactory.create_cube(0.4, Color.CYAN), "name": "Cube"},
		{"create": PolyhedronFactory.create_octahedron(0.4, Color.YELLOW), "name": "Octahedron"},
		{"create": PolyhedronFactory.create_dodecahedron(0.4, Color(1.0, 0.5, 1.0)), "name": "Dodecahedron"},
		{"create": PolyhedronFactory.create_icosahedron(0.4, Color(0.5, 1.0, 0.5)), "name": "Icosahedron"}
	]

	var total_width = (solids.size() - 1) * spacing
	var start_x = -total_width / 2.0

	for i in range(solids.size()):
		var solid = solids[i]["create"]
		solid.position.x = start_x + i * spacing
		add_child(solid)
		polyhedra.append(solid)

		# Add label
		var label = Label3D.new()
		label.text = solids[i]["name"]
		label.font_size = 8
		label.outline_size = 2
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(solid.position.x, -0.6, 0)
		add_child(label)

func create_johnson_solids_showcase():
	var solids = [
		{"create": PolyhedronFactory.create_square_pyramid(0.4, Color(1.0, 0.7, 0.3)), "name": "Square Pyramid (J1)"},
		{"create": PolyhedronFactory.create_triangular_cupola(0.4, Color(0.7, 0.9, 1.0)), "name": "Triangular Cupola (J3)"}
	]

	var start_x = -(solids.size() - 1) * spacing / 2.0

	for i in range(solids.size()):
		var solid = solids[i]["create"]
		solid.position.x = start_x + i * spacing
		add_child(solid)
		polyhedra.append(solid)

		# Add label
		var label = Label3D.new()
		label.text = solids[i]["name"]
		label.font_size = 8
		label.outline_size = 2
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(solid.position.x, -0.6, 0)
		add_child(label)

func create_single_polyhedron(type: String):
	var solid: Node3D
	match type:
		"tetrahedron":
			solid = PolyhedronFactory.create_tetrahedron(0.6, Color.MAGENTA)
		"octahedron":
			solid = PolyhedronFactory.create_octahedron(0.6, Color.YELLOW)
		"cube":
			solid = PolyhedronFactory.create_cube(0.6, Color.CYAN)

	if solid:
		add_child(solid)
		polyhedra.append(solid)

func _process(delta):
	# Rotate all polyhedra for visual interest
	for poly in polyhedra:
		if poly:
			poly.rotate_y(delta * 0.5)
			poly.rotate_x(delta * 0.3)
