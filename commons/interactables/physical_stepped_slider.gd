# physical_stepped_slider.gd
# A retained, grabbable vertical selector. Geometry moves; lettering is printed
# on its face. Pointer and near-grab input drive the same XR Tools slider.
extends Node3D

signal value_changed(value: float)

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const POINTER_LAYERS := (1 << 20) | (1 << 22)
const TRAVEL := .18

## Configure before adding to the tree. Keep physics controls at unit scale.
@export_range(2, 12) var step_count: int = 6
## Continuous parameters use the same retained handle, without detents. The
## six printed marks then show 0..1, not six permissible values.
@export var continuous: bool = false
## Authored access, configured before tree entry. A locked handle is still
## visible, but cannot be picked up or moved with a pointer.
@export var input_enabled: bool = true
@export var param_name: String = "DEPTH"
var _value: float = 0.0
var _track: XRToolsInteractableSlider
var _handle: XRToolsInteractableHandle
var _pointer: Node3D
var _pointer_start_y: float
var _pointer_start_position: float


class Track extends XRToolsInteractableSlider:
	func _process(_delta: float) -> void:
		if grabbed_handles.is_empty():
			return
		# Affine conversion also handles a transformed enclosing artifact. The
		# stock offset * basis calculation assumes an orthonormal world basis.
		var offset := 0.0
		var held_positions: Array[Vector3] = []
		for handle in grabbed_handles:
			held_positions.append(handle.global_position)
			offset += to_local(handle.global_position).x - to_local(handle.handle_origin.global_position).x
		move_slider(slider_position + offset / grabbed_handles.size())
		# Moving the parent must not move the held proxy along with it. Otherwise
		# a stationary hand repeats the same offset on successive render frames.
		for i in grabbed_handles.size():
			grabbed_handles[i].global_position = held_positions[i]


class PointerBody extends StaticBody3D:
	var control: Node3D
	func pointer_event(event: XRToolsPointerEvent) -> void:
		control.pointer_event(event)


class Handle extends XRToolsInteractableHandle:
	var control: Node3D
	func pick_up(by) -> void:
		if not enabled: return
		super(by)
	func pointer_event(event: XRToolsPointerEvent) -> void:
		control.pointer_event(event)


func _ready() -> void:
	step_count = clampi(step_count, 2, 12)
	set_process(false)
	var ivory := _material(Color(.84, .84, .73))
	var dark := _material(Color(.08, .10, .12))
	var metal := _material(Color(.30, .33, .35), .6)
	var orange := _material(Color(1.0, .36, .07))
	_box(self, "Bezel", Vector3(.154, .324, .022), Vector3(0, 0, -.004), metal)
	var face := PointerBody.new()
	face.name = "Face"
	face.control = self
	face.collision_layer = POINTER_LAYERS
	face.collision_mask = 0
	_shape(face, Vector3(.14, .31, .018))
	_box(face, "Panel", Vector3(.14, .31, .018), Vector3.ZERO, ivory)
	_box(face, "Slot", Vector3(.010, TRAVEL + .028, .002), Vector3(0, 0, .010), dark)
	add_child(face)
	_print("Title", param_name, Vector2(.115, .023), Vector3(0, .130, .0105))
	_print("ReleaseRule", "STAYS" if input_enabled else "HELD", Vector2(.08, .016), Vector3(0, -.130, .0105))
	for i in step_count:
		var y := lerpf(-TRAVEL / 2, TRAVEL / 2, float(i) / (step_count - 1))
		_box(self, "Tick_%d" % i, Vector3(.038, .0015, .001), Vector3(-.019, y, .0105), dark)
		var mark := "%.1f" % (float(i) / (step_count - 1)) if continuous else str(i + 1)
		_print("Step_%d" % (i + 1), mark, Vector2(.028, .020), Vector3(.052, y, .0105))

	var origin := Node3D.new()
	origin.name = "SliderOrigin"
	origin.position = Vector3(0, -TRAVEL / 2, .027)
	origin.rotation_degrees.z = 90
	_track = Track.new()
	_track.name = "Track"
	_track.slider_limit_max = TRAVEL
	_track.slider_steps = 0.0 if continuous else TRAVEL / (step_count - 1)
	_track.slider_position = _value * TRAVEL
	_track.default_on_release = false
	var handle_origin := Node3D.new()
	handle_origin.name = "HandleOrigin"
	_handle = Handle.new()
	_handle.name = "Handle"
	_handle.control = self
	_handle.enabled = input_enabled
	_handle.freeze = true
	_handle.collision_layer = (1 << 18) | POINTER_LAYERS
	_handle.collision_mask = 0
	_handle.picked_up_layer = 0
	_handle.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	_shape(_handle, Vector3(.044, .075, .038))
	handle_origin.add_child(_handle)
	_track.add_child(handle_origin)
	# The visible cap follows the constrained track, never the free grab proxy.
	_box(_track, "Cap", Vector3(.040, .070, .032), Vector3.ZERO, dark)
	_box(_track, "Index", Vector3(.003, .061, .002), Vector3(0, 0, .017), orange)
	for side in [-1, 1]:
		_box(_track, "Grip_%d" % side, Vector3(.007, .064, .002), Vector3(side * .013, 0, .017), metal)
	origin.add_child(_track)
	add_child(origin)
	_track.slider_moved.connect(_on_moved)
	_track.grabbed.connect(func(_node): _cancel_pointer())
	set_normalized_value(_value)


## Set silently, including before construction; integer state and cap agree.
func set_normalized_value(value: float) -> void:
	var intervals := maxi(step_count - 1, 1)
	_value = clampf(value, 0, 1) if continuous else float(roundi(clampf(value, 0, 1) * intervals)) / intervals
	if _track:
		_track.slider_position = _value * TRAVEL


func get_normalized_value() -> float:
	return _value


func _on_moved(position: float) -> void:
	var value := clampf(position / TRAVEL, 0, 1) if continuous else float(roundi(position / TRAVEL * (step_count - 1))) / (step_count - 1)
	if is_equal_approx(value, _value):
		return
	_value = value
	value_changed.emit(_value)


func pointer_event(event: XRToolsPointerEvent) -> void:
	if not input_enabled or not event or not is_instance_valid(event.pointer) or not _track:
		return
	if not _track.grabbed_handles.is_empty():
		return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(_pointer):
				return
			_pointer = event.pointer
			_pointer_start_y = to_local(event.position).y
			_pointer_start_position = _track.slider_position
			set_process(true)
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer == _pointer:
				_track.move_slider(_pointer_start_position + to_local(event.position).y - _pointer_start_y)
		XRToolsPointerEvent.Type.RELEASED, XRToolsPointerEvent.Type.EXITED:
			if event.pointer == _pointer:
				_cancel_pointer()


func _process(_delta: float) -> void:
	if not is_instance_valid(_pointer):
		_cancel_pointer()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_pointer()


func _cancel_pointer() -> void:
	_pointer = null
	set_process(false)


func _print(node_name: String, text: String, size: Vector2, at: Vector3) -> void:
	var label := BakedText.make_label_mesh(text, Color(.08, .10, .12), size, 2600, true)
	if label:
		label.name = node_name
		label.position = at
		add_child(label)


func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = .55
	return material


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = material
	parent.add_child(mesh)


func _shape(parent: CollisionObject3D, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	parent.add_child(collision)
