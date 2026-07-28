extends Node3D
class_name PressureSoftBody

# @identity
# essence: a closed SoftBody3D sphere pinned by its south pole to a plinth cap, with one slider running its pressure_coefficient from -1 to +2 — from a skin that has collapsed onto the stone to a membrane strained past the shape it was cut for
# desire: to put the single parameter that separates a rag from a balloon under a hand, and to show that nothing else about the body changes when it crosses
# critical_parameter: pressure — the volume-preservation force the solver adds along each vertex normal. Below zero it pulls inward and the sphere puddles; near zero the springs alone hold it and it sags; above one it fights the springs and the sphere goes faceted and hard
# triggers: the slider's slider_moved signal remaps 0..1 onto -1..2 and writes pressure_coefficient live; linear_stiffness stays fixed at 0.5 so the slider is the ONLY thing moving
# emerges: inflation stops reading as size. The mesh keeps its vertex count and its rest lengths the whole way; what changes is how hard the interior argues with the surface
# needs: a CLOSED mesh — pressure integrates over a sealed volume, so an open sheet gets zero force from it (breathing_room.gd:52 names the same requirement); a StaticBody3D cap to pin the pole to; slider_horizontal [present]
# relationships: the controllable twin of breathing_room, which drives the same coefficient on a schedule you cannot interrupt; upstream of the slicer, where the topology rather than the pressure is what gets edited
# truth: pressure is not inflation, it is a disagreement. The solver pushes every vertex out along its normal and the springs pull it back; the shape you see is where the two settle. Open the mesh anywhere and the argument has no interior to be about, and the body goes limp no matter what the number says.

## A single inflatable body on a plinth, with pressure_coefficient exposed on one
## slider. Everything is built procedurally in _ready(); the pin is deferred
## because SoftBody3D can only pin points once it and its attachment are in-tree.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const GSB := preload("res://commons/soft_body/grab_soft_body.gd")
const SliderScene := preload("res://commons/interactables/slider_horizontal.tscn")

const PRESSURE_MIN := -1.0        # collapsed: the interior pulls the skin in
const PRESSURE_MAX := 2.0         # over-inflated: the interior beats the springs
const STIFFNESS := 0.5            # FIXED — the slider must be the only variable

const PLINTH_H := 0.42
const PLINTH_W := 0.44
const CAP_W := 0.60
const CAP_H := 0.05
const BALL_R := 0.17

## Starting pressure, in the same -1..2 domain the slider spans.
@export_range(-1.0, 2.0, 0.01) var pressure: float = 0.5
## Plate text. Empty keeps the artifact's own name.
@export var plate_text: String = ""

var _built: bool = false
var _created: Array[Node] = []
var _soft: SoftBody3D = null
var _cap: StaticBody3D = null
## Deliberately UNTYPED. slider_horizontal.tscn's root carries a script with no
## class_name, so a `Node`-typed handle would fail static analysis the moment we
## touched set_param_name or the slider_moved signal.
var _slider = null
var _readout: Label3D = null
var _last_readout: String = ""


func _ready() -> void:
	_build_all()
	_built = true


func _own(n: Node) -> void:
	_created.append(n)
	add_child(n)


func _build_all() -> void:
	_build_plinth()
	_build_body()
	_build_slider()
	_build_readout()
	# The pole can only be pinned once both the SoftBody3D and the cap are
	# inside the tree — set_point_pinned resolves the attachment by NodePath.
	call_deferred("_pin_pole")


# --- plinth ---------------------------------------------------------------

func _build_plinth() -> void:
	var column := MeshInstance3D.new()
	column.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, PLINTH_H, PLINTH_W)
	column.mesh = box
	column.position = Vector3(0.0, PLINTH_H * 0.5, 0.0)
	column.material_override = _grid_material(
		Color(0.20, 0.21, 0.26), Color(0.40, 0.46, 0.56), 0.4)
	_own(column)

	# The cap is a real StaticBody3D: it is both the visible shelf and the thing
	# the pinned vertices hang from, so the body cannot slide off the plinth.
	_cap = StaticBody3D.new()
	_cap.name = "Cap"
	_cap.position = Vector3(0.0, PLINTH_H + CAP_H * 0.5, 0.0)
	var cap_mi := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(CAP_W, CAP_H, CAP_W)
	cap_mi.mesh = cap_box
	cap_mi.material_override = _grid_material(
		Color(0.28, 0.30, 0.36), Color(0.52, 0.60, 0.72), 0.6)
	_cap.add_child(cap_mi)
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = cap_box.size
	shape.shape = bs
	_cap.add_child(shape)
	_own(_cap)


# --- the body -------------------------------------------------------------

func _build_body() -> void:
	_soft = SoftBody3D.new()
	_soft.name = "Inflatable"
	# soft_sphere is a CLOSED sphere. Pressure integrates over a sealed volume;
	# an open sheet would take this same coefficient and do nothing with it.
	_soft.mesh = GSB.soft_sphere(BALL_R, 14, 20)
	GSB.soft_setup(_soft, {
		"mass": 2.0,
		"stiffness": STIFFNESS,
		"pressure": pressure,
		"damping": 0.2,
		"precision": 6,
		"color": Color(0.88, 0.42, 0.52),
		"emissive": true,
	})
	_soft.position = Vector3(0.0, PLINTH_H + CAP_H + BALL_R * 0.94, 0.0)
	_own(_soft)


## Pin the south pole patch to the cap. Without this the body walks off the
## plinth within a second of the first inflation; with it, deflation reads as a
## skin draping over the stone rather than as an object that fell over.
func _pin_pole() -> void:
	if _soft == null or not is_instance_valid(_soft):
		return
	if _cap == null or not is_instance_valid(_cap):
		return
	GSB.pin_patch(_soft, Vector3(0.0, -BALL_R, 0.0), _cap, BALL_R * 0.42)


# --- control --------------------------------------------------------------

func _build_slider() -> void:
	_slider = SliderScene.instantiate()
	_slider.name = "PressureSlider"
	# Front lip of the plinth, tilted up so a standing player reads the face.
	(_slider as Node3D).position = Vector3(0.0, PLINTH_H - 0.10, PLINTH_W * 0.5 + 0.09)
	(_slider as Node3D).rotation_degrees = Vector3(-30.0, 0.0, 0.0)
	_own(_slider)
	if _slider.has_method("set_param_name"):
		_slider.set_param_name("PRESSURE")
	if _slider.has_method("set_range"):
		_slider.set_range(PRESSURE_MIN, PRESSURE_MAX)
	if _slider.has_method("set_normalized_value"):
		_slider.set_normalized_value(remap(pressure, PRESSURE_MIN, PRESSURE_MAX, 0.0, 1.0))
	if _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_pressure_slider"))


## The parameter-binding block from rounded_softbody.gd:508-510, reduced to the
## one axis this artifact is about. slider_horizontal emits its RAW track
## position, so the normalised value is read back off the node rather than
## trusted from the signal argument.
func _on_pressure_slider(_value: Variant) -> void:
	if _slider == null or not is_instance_valid(_slider):
		return
	var norm: float = 0.5
	if _slider.has_method("get_normalized_value"):
		norm = float(_slider.get_normalized_value())
	_apply_pressure(remap(norm, 0.0, 1.0, PRESSURE_MIN, PRESSURE_MAX))


func _apply_pressure(value: float) -> void:
	pressure = clampf(value, PRESSURE_MIN, PRESSURE_MAX)
	if _soft != null and is_instance_valid(_soft):
		_soft.pressure_coefficient = pressure
		_soft.linear_stiffness = STIFFNESS


# --- readout --------------------------------------------------------------

func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.font_size = 40
	_readout.pixel_size = 0.0011
	_readout.outline_size = 5
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.modulate = Color(0.95, 0.72, 0.72)
	_readout.position = Vector3(0.0, PLINTH_H + CAP_H + BALL_R * 2.1 + 0.10, 0.0)
	_own(_readout)

	var plate := Label3D.new()
	plate.name = "Plate"
	plate.text = plate_text if plate_text != "" else "PRESSURE SOFT BODY"
	plate.font_size = 40
	plate.pixel_size = 0.0009
	plate.outline_size = 4
	plate.modulate = Color(0.70, 0.76, 0.86)
	plate.position = Vector3(0.0, PLINTH_H * 0.62, PLINTH_W * 0.5 + 0.004)
	_own(plate)

	_refresh_readout()


## Four named regimes. The numbers are the same coefficient throughout; the names
## exist because "0.9" and "1.4" look alike on a slider and do not look alike on
## the body.
func _regime() -> String:
	if pressure < -0.25:
		return "COLLAPSED"
	if pressure < 0.15:
		return "SLACK"
	if pressure < 0.95:
		return "TAUT"
	return "OVER-INFLATED"


func _refresh_readout() -> void:
	if _readout == null or not is_instance_valid(_readout):
		return
	var text: String = "%s   p = %.2f" % [_regime(), pressure]
	if text == _last_readout:
		return
	_last_readout = text
	_readout.text = text


func _process(_delta: float) -> void:
	_refresh_readout()


# --- material -------------------------------------------------------------

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_soft = null
	_cap = null
	_slider = null
	_readout = null
	_last_readout = ""
	_build_all()


## Grid config. Keys: "pressure" (-1..2), "plate_text".
## A pressure change is applied LIVE — the body and the slider both move, and the
## plinth is never torn down for it. Only the plate forces a rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_plate: String = plate_text
	var want_pressure: float = pressure

	if config_data.has("pressure"):
		want_pressure = clampf(float(config_data["pressure"]), PRESSURE_MIN, PRESSURE_MAX)
	if config_data.has("plate_text"):
		plate_text = str(config_data["plate_text"])

	if not _built:
		pressure = want_pressure
		return

	if not is_equal_approx(want_pressure, pressure):
		_apply_pressure(want_pressure)
		if _slider != null and is_instance_valid(_slider) \
				and _slider.has_method("set_normalized_value"):
			_slider.set_normalized_value(
				remap(pressure, PRESSURE_MIN, PRESSURE_MAX, 0.0, 1.0))
		_refresh_readout()

	if plate_text != before_plate:
		_rebuild_now()

	print("[PressureSoftBody] Config applied — pressure=%.2f (%s)" % [pressure, _regime()])
