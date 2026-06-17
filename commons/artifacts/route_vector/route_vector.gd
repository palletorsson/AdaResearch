extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RouteVector

## @identity
## lineage: the applied face of Vector basics — a delivery route. A from-pin and a to-pin, and the
##   one arrow between them is the displacement: the trip, not the places.
## essence: a vector is the journey A→B — its components say "go this far east, this far up", its
##   length says how far in all. A courier travels the arrow to show it is a single move.
## truth: a vector is a journey with no starting address — only a direction and a distance.

@export var from_pt: Vector3 = Vector3(-2.2, 0.12, -1.6)
@export var to_pt: Vector3 = Vector3(2.4, 0.12, 1.7)
@export var route_color: Color = Color(0.45, 0.72, 0.98)
var _courier: Node3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var gm := _glow_mat(Color(0.30, 0.32, 0.40), 0.3)
	for i in range(-3, 4):
		add_child(_box(Vector3(i, 0, 0), Vector3(0.012, 0.012, 6.0), gm))
		add_child(_box(Vector3(0, 0, i), Vector3(6.0, 0.012, 0.012), gm))
	add_child(_sphere(from_pt, 0.14, _glow_mat(Color(0.5, 0.92, 0.5), 1.4)))
	add_child(_billboard_label("A", from_pt + Vector3(0, 0.4, 0), 22, Color(0.6, 0.95, 0.6)))
	add_child(_sphere(to_pt, 0.14, _glow_mat(Color(0.98, 0.55, 0.4), 1.4)))
	add_child(_billboard_label("B", to_pt + Vector3(0, 0.4, 0), 22, Color(0.98, 0.6, 0.45)))
	add_child(_arrow(from_pt, to_pt, 0.05, _glow_mat(route_color, 1.6)))
	var d: Vector3 = to_pt - from_pt
	add_child(_billboard_label("ROUTE  (B − A)\ngo %.1f x, %.1f y, %.1f z   ·   |v| = %.2f\na vector is the trip, not the place" % [d.x, d.y, d.z, d.length()],
		from_pt.lerp(to_pt, 0.5) + Vector3(0, 1.0, 0), 23, route_color.lerp(Color.WHITE, 0.3)))
	_courier = Node3D.new(); add_child(_courier)
	_courier.add_child(_sphere(Vector3.ZERO, 0.1, _glow_mat(route_color.lerp(Color.WHITE, 0.4), 1.8)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _courier == null:
		return
	_t += delta * 0.4
	_courier.position = from_pt.lerp(to_pt, fmod(_t, 1.0))   # a courier walking the displacement
