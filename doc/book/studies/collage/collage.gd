extends Node3D

@export var made := "by hand, drafted, found"   # how each body was made, in the order they stand

func _ready() -> void:
	for word in made.split(","):
		var how := word.strip_edges()
		var body := make(how)
		if body == null:
			push_error("no body here was made this way: " + how)
			continue
		add_child(body)
		$"../Sheet".hang(body, how)
		print(how, ": ", body.triangles(), " triangles")

func make(how: String) -> Node3D:
	if how == "by hand":
		return Solid.new()
	if how == "drafted":
		return load("res://drafted_solid.gd").new()
	if how == "found":
		return Found.new()
	return null
