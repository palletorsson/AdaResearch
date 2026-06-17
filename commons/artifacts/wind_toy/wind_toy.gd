extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WindToy

## @identity
## lineage: the small, held end of the Wind ladder — a pinwheel on a stick and a streamer that
##   leans, the least you need to feel a force you can't see.
## essence: wind is air with somewhere to be; the push grows with the square of speed, so the
##   pinwheel spins faster and the streamer flattens as the breeze rises. F_drag ∝ v².
## truth: you never see the wind, only the bend of the things it pushes.

@export var wind: float = 0.6
@export var vane_color: Color = Color(0.55, 0.92, 1.0)
@export var streamer_color: Color = Color(0.98, 0.72, 0.32)
var _wheel: Node3D
var _streamer: Node3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("wind"): wind = clampf(float(config["wind"]), 0.0, 1.0)
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var steel := _steel_mat(Color(0.4, 0.42, 0.48))
	add_child(_cylinder(Vector3(0, 0.5, 0), 0.03, 1.0, steel))                 # the stick
	_wheel = Node3D.new(); _wheel.position = Vector3(0, 1.05, 0); add_child(_wheel)
	for i in range(4):                                                          # 4 pinwheel blades
		var a := TAU * float(i) / 4.0
		var blade := _box(Vector3(cos(a) * 0.22, sin(a) * 0.22, 0), Vector3(0.18, 0.10, 0.02), _glow_mat(vane_color.lerp(Color.WHITE, 0.2 * i), 1.0))
		blade.rotation.z = a
		_wheel.add_child(blade)
	_wheel.add_child(_sphere(Vector3.ZERO, 0.05, _glow_mat(vane_color, 1.2)))
	_streamer = Node3D.new(); _streamer.position = Vector3(0, 0.9, 0); add_child(_streamer)
	add_child(_billboard_label("WIND\nF ∝ v²\nthe bend of the things it pushes", Vector3(0, 1.7, 0), 22, vane_color.lerp(Color.WHITE, 0.3)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _wheel == null:
		return
	_t += delta
	_wheel.rotation.z = -_t * (1.0 + wind * 5.0)                                # spins faster with wind
	for c in _streamer.get_children():
		_streamer.remove_child(c); c.queue_free()
	var droop: float = lerpf(0.7, 0.05, wind)                                   # streamer flattens as wind rises
	var tip := Vector3(0.7, -droop + sin(_t * 6.0) * 0.05 * (1.0 - wind), 0)
	_streamer.add_child(_cylinder_between(Vector3.ZERO, tip * 0.5, 0.02, _glow_mat(streamer_color, 1.2)))
	_streamer.add_child(_cylinder_between(tip * 0.5, tip, 0.015, _glow_mat(streamer_color, 1.0)))
