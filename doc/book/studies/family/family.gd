extends Node3D

@export var axis := "segments"           # the field we sweep, by its name
@export var values := "4, 8, 16, 64"     # its values, as typed into one text field

func _ready() -> void:
	for word in values.split(","):
		var title := word.strip_edges()
		var member := Globe.new()
		member.set(axis, title)
		@warning_ignore("integer_division")
		member.rings = member.segments / 2
		add_child(member)
		$"../Sheet".hang(member, str(member.get(axis)))
		print(title, " asked, ", member.get(axis), " built: ", member.triangles(), " triangles")
