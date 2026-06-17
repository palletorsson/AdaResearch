extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FreeVector

## @identity
## lineage: the intimate companion to VectorBasics for the Vector basics concept — one arrow and
##   its ghost copies, carried to different origins to show a vector has no home.
## essence: a vector is two facts only — a direction and a length. Slide it anywhere and it is the
##   same vector; the ghost copies prove it. |v| = √(x²+y²), θ from the x-axis.
## truth: a vector is a journey with no starting address.

@export var vec: Vector3 = Vector3(2.4, 1.4, 0.0)
@export var vec_color: Color = Color(0.45, 0.72, 0.98)
@export var ghost_color: Color = Color(0.60, 0.64, 0.76)

var _ghosts: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	vec_color = _parse_color(config.get("vec_color", vec_color), vec_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_ghosts.clear()
	_build()


func _build() -> void:
	var gm := _glow_mat(Color(0.30, 0.32, 0.40), 0.3)
	for i in range(-2, 3):                                     # a faint reference grid
		add_child(_box(Vector3(float(i), 0, 0), Vector3(0.012, 0.012, 4.0), gm))
		add_child(_box(Vector3(0, 0, float(i)), Vector3(4.0, 0.012, 0.012), gm))
	add_child(_sphere(Vector3.ZERO, 0.06, _glow_mat(Color(0.9, 0.9, 1.0), 0.8)))   # the origin
	add_child(_arrow(Vector3.ZERO, vec, 0.05, _glow_mat(vec_color, 1.6)))           # the canonical vector
	add_child(_billboard_label("VECTOR\n|v| = %.2f   θ = %d°\na direction + a length" % [vec.length(), int(rad_to_deg(atan2(vec.y, vec.x)))],
		vec * 0.5 + Vector3(0, 0.6, 0), 26, vec_color.lerp(Color.WHITE, 0.3)))
	for o in [Vector3(-2.2, 0.0, -1.5), Vector3(1.8, 0.0, 1.6), Vector3(-1.6, 0.0, 1.2)]:  # ghost copies — same vector, elsewhere
		var g := Node3D.new(); g.position = o; add_child(g)
		g.add_child(_arrow(Vector3.ZERO, vec, 0.04, _glow_mat(ghost_color, 0.7)))
		_ghosts.append(g)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _ghosts.is_empty():
		return
	_t += delta
	_ghosts[0].position = Vector3(-2.2 + sin(_t * 0.6) * 0.9, 0.0, -1.5 + cos(_t * 0.6) * 0.6)  # carry it anywhere — still the same vector
