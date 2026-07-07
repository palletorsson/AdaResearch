# Locatable Knowledge Station — every fact carries its address
#
# A study desk with three open books. Each book displays a glowing claim, but each claim
# is tagged with its source — a place, a person, a moment. The tag is *part of* the claim,
# not an annotation after the fact. As the player approaches each book, the claim and
# its location reveal together.
#
# This counters the encyclopedia fantasy of placeless knowledge. Every fact is *from
# somewhere*. Knowledge is locatable; without a where, the fact is the encyclopedia's
# own ghost.
#
# @identity: First map where knowledge carries its origin like grain in wood.
# @qfep_term: Edge — locatable, not universal.

extends Node3D
class_name LocatableKnowledgeStation

@export var desk_color: Color = Color(0.4, 0.3, 0.22, 1.0)
@export var book_color: Color = Color(0.6, 0.85, 0.95, 1.0)
@export var tag_color: Color = Color(0.95, 0.7, 0.4, 1.0)

var _book_positions: Array = [
	{"pos": Vector3(-0.5, 0.95, 0.1), "claim": "Water boils at 100°C", "source": "at sea level, Earth, 1742"},
	{"pos": Vector3(0.0, 0.95, 0.15), "claim": "Money is real", "source": "in markets where trust holds"},
	{"pos": Vector3(0.5, 0.95, 0.1), "claim": "X is a man", "source": "in the eyes of the registrar"},
]


func _ready() -> void:
	_build_desk()
	for book in _book_positions:
		_build_book(book)
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _build_desk() -> void:
	var desk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.05, 0.6)
	desk.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = desk_color
	mat.roughness = 0.7
	desk.material_override = mat
	desk.position.y = 0.9
	add_child(desk)
	# Four legs.
	for x_off in [-0.7, 0.7]:
		for z_off in [-0.25, 0.25]:
			var leg := MeshInstance3D.new()
			var leg_box := BoxMesh.new()
			leg_box.size = Vector3(0.06, 0.85, 0.06)
			leg.mesh = leg_box
			leg.material_override = mat
			leg.position = Vector3(x_off, 0.45, z_off)
			add_child(leg)


func _build_book(book: Dictionary) -> void:
	var pos: Vector3 = book["pos"]
	# The book itself.
	var book_mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.32, 0.04, 0.22)
	book_mesh.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = book_color
	mat.emission_enabled = true
	mat.emission = book_color
	mat.emission_energy_multiplier = 0.5
	mat.roughness = 0.4
	book_mesh.material_override = mat
	book_mesh.position = pos
	add_child(book_mesh)
	# Claim label.
	var claim := Label3D.new()
	claim.text = book["claim"]
	claim.font_size = 18
	claim.outline_size = 4
	claim.modulate = book_color
	claim.position = pos + Vector3(0, 0.16, 0)
	claim.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(claim)
	# Source tag.
	var source := Label3D.new()
	source.text = "· " + book["source"]
	source.font_size = 14
	source.outline_size = 3
	source.modulate = tag_color
	source.position = pos + Vector3(0, 0.06, 0)
	source.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(source)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "every fact is from somewhere"
	label.font_size = 26
	label.outline_size = 6
	label.modulate = tag_color
	label.position = Vector3(0, 1.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
