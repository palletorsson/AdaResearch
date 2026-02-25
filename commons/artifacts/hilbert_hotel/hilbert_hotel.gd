extends Node3D
class_name HilbertHotel

## Interactive Hilbert's Hotel paradox — a row of rooms with occupants
## that shift when a new guest arrives, showing infinity + 1 = infinity.

# --- Configuration ---
@export var num_rooms: int = 10
@export var room_width: float = 0.06
@export var room_height: float = 0.08
@export var room_depth: float = 0.05
@export var room_gap: float = 0.015
@export var guest_radius: float = 0.015
@export var shift_duration: float = 0.8
@export var pause_between_shifts: float = 1.2

# --- Colors ---
var color_occupied := Color(0.25, 0.45, 0.75)
var color_empty := Color(0.15, 0.15, 0.2)
var color_guest := Color(0.9, 0.75, 0.2)
var color_new_guest := Color(0.2, 0.9, 0.4)
var color_frame := Color(0.35, 0.3, 0.25)
var color_infinity := Color(0.7, 0.5, 0.9)

# --- Internal ---
var _rooms: Array[MeshInstance3D] = []
var _room_materials: Array[StandardMaterial3D] = []
var _guests: Array[MeshInstance3D] = []
var _number_labels: Array[Label3D] = []
var _new_guest: MeshInstance3D
var _new_guest_material: StandardMaterial3D
var _status_label: Label3D
var _time: float = 0.0
var _phase: int = 0  # 0=full, 1=shifting, 2=new guest enters, 3=pause, loop
var _phase_timer: float = 0.0
var _shift_progress: float = 0.0
var _total_width: float = 0.0


func _ready() -> void:
	_total_width = num_rooms * (room_width + room_gap) - room_gap
	_build_base()
	_build_rooms()
	_build_guests()
	_build_new_guest()
	_build_labels()
	_build_infinity_sign()
	_set_phase(0)


func _build_base() -> void:
	# Wooden platform beneath the hotel
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_total_width + 0.08, 0.015, room_depth + 0.04)
	base.mesh = box
	base.position = Vector3(0, -0.01, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_frame
	mat.roughness = 0.9
	base.material_override = mat
	add_child(base)


func _build_rooms() -> void:
	var start_x := -_total_width / 2.0 + room_width / 2.0
	for i in range(num_rooms):
		var x_pos: float = start_x + i * (room_width + room_gap)

		# Room box (open front — we use 5 faces via separate thin boxes)
		var room := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(room_width, room_height, room_depth)
		room.mesh = box
		room.position = Vector3(x_pos, room_height / 2.0, 0)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_occupied
		mat.roughness = 0.7
		mat.metallic = 0.05
		room.material_override = mat
		add_child(room)

		_rooms.append(room)
		_room_materials.append(mat)

		# Room number label on front face
		var lbl := Label3D.new()
		lbl.pixel_size = 0.001
		lbl.font_size = 28
		lbl.outline_size = 4
		lbl.text = str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector3(x_pos, room_height + 0.015, 0)
		lbl.modulate = Color(0.8, 0.85, 0.95)
		add_child(lbl)
		_number_labels.append(lbl)


func _build_guests() -> void:
	# A sphere guest inside each room
	var start_x := -_total_width / 2.0 + room_width / 2.0
	for i in range(num_rooms):
		var x_pos: float = start_x + i * (room_width + room_gap)

		var guest := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = guest_radius
		sphere.height = guest_radius * 2.0
		guest.mesh = sphere
		guest.position = Vector3(x_pos, guest_radius + 0.002, 0)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_guest
		mat.emission_enabled = true
		mat.emission = color_guest * 0.4
		mat.emission_energy_multiplier = 0.5
		mat.roughness = 0.3
		mat.metallic = 0.2
		guest.material_override = mat
		add_child(guest)

		_guests.append(guest)


func _build_new_guest() -> void:
	# The incoming guest — starts outside the hotel to the left
	_new_guest = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = guest_radius * 1.2
	sphere.height = guest_radius * 2.4
	_new_guest.mesh = sphere

	_new_guest_material = StandardMaterial3D.new()
	_new_guest_material.albedo_color = color_new_guest
	_new_guest_material.emission_enabled = true
	_new_guest_material.emission = color_new_guest * 0.6
	_new_guest_material.emission_energy_multiplier = 1.0
	_new_guest_material.roughness = 0.2
	_new_guest_material.metallic = 0.3
	_new_guest.material_override = _new_guest_material
	_new_guest.visible = false

	var start_x := -_total_width / 2.0 - (room_width + room_gap)
	_new_guest.position = Vector3(start_x, guest_radius * 1.2 + 0.002, 0)
	add_child(_new_guest)


func _build_labels() -> void:
	# Title
	var title := Label3D.new()
	title.pixel_size = 0.001
	title.font_size = 38
	title.outline_size = 5
	title.text = "Hilbert's Hotel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3(0, room_height + 0.06, 0)
	title.modulate = Color(0.9, 0.92, 1.0)
	add_child(title)

	# Status label — shows what's happening
	_status_label = Label3D.new()
	_status_label.pixel_size = 0.001
	_status_label.font_size = 24
	_status_label.outline_size = 3
	_status_label.text = "NO VACANCY — every room occupied"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.position = Vector3(0, -0.035, 0)
	_status_label.modulate = Color(0.7, 0.8, 0.95)
	add_child(_status_label)

	# Paradox label at bottom
	var paradox := Label3D.new()
	paradox.pixel_size = 0.001
	paradox.font_size = 18
	paradox.outline_size = 2
	paradox.text = "\u221e + 1 = \u221e"
	paradox.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paradox.position = Vector3(0, -0.06, 0)
	paradox.modulate = color_infinity
	add_child(paradox)


func _build_infinity_sign() -> void:
	# Infinity symbol "..." and ∞ at the right end of the row
	var end_x := _total_width / 2.0 + room_gap + 0.02

	var dots := Label3D.new()
	dots.pixel_size = 0.001
	dots.font_size = 36
	dots.outline_size = 4
	dots.text = "..."
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dots.position = Vector3(end_x, room_height / 2.0, 0)
	dots.modulate = Color(0.5, 0.5, 0.6)
	add_child(dots)

	var inf_lbl := Label3D.new()
	inf_lbl.pixel_size = 0.001
	inf_lbl.font_size = 44
	inf_lbl.outline_size = 5
	inf_lbl.text = "\u221e"
	inf_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	inf_lbl.position = Vector3(end_x + 0.04, room_height + 0.015, 0)
	inf_lbl.modulate = color_infinity
	add_child(inf_lbl)


func _process(delta: float) -> void:
	_time += delta
	_phase_timer += delta

	match _phase:
		0:  # Full hotel — pause showing "NO VACANCY"
			if _phase_timer > pause_between_shifts * 1.5:
				_set_phase(1)
		1:  # Shifting — all guests move from room n to room n+1
			_shift_progress = clampf(_phase_timer / shift_duration, 0.0, 1.0)
			_animate_shift(_shift_progress)
			if _shift_progress >= 1.0:
				_finalize_shift()
				_set_phase(2)
		2:  # New guest enters room 1
			var enter_progress := clampf(_phase_timer / (shift_duration * 0.8), 0.0, 1.0)
			_animate_new_guest(enter_progress)
			if enter_progress >= 1.0:
				_finalize_new_guest()
				_set_phase(3)
		3:  # Pause showing "ROOM FOUND!" then reset
			if _phase_timer > pause_between_shifts:
				_reset_hotel()
				_set_phase(0)


func _set_phase(p: int) -> void:
	_phase = p
	_phase_timer = 0.0
	_shift_progress = 0.0

	match p:
		0:
			_status_label.text = "NO VACANCY \u2014 every room occupied"
			_status_label.modulate = Color(0.9, 0.4, 0.3)
		1:
			_status_label.text = "New guest arrives! Move n \u2192 n+1"
			_status_label.modulate = Color(0.4, 0.8, 1.0)
			_new_guest.visible = true
		2:
			_status_label.text = "Room 1 is free! Guest enters..."
			_status_label.modulate = color_new_guest
		3:
			_status_label.text = "ROOM FOUND! \u221e + 1 = \u221e"
			_status_label.modulate = color_infinity


func _animate_shift(t: float) -> void:
	# Ease function for smooth motion
	var eased: float = _ease_in_out(t)
	var step: float = room_width + room_gap
	var start_x := -_total_width / 2.0 + room_width / 2.0

	for i in range(num_rooms):
		var base_x: float = start_x + i * step
		var target_x: float = base_x + step
		_guests[i].position.x = lerpf(base_x, target_x, eased)

	# Last guest fades out as it "moves beyond visible rooms"
	var last_alpha: float = 1.0 - t * t
	var last_mat: StandardMaterial3D = _guests[num_rooms - 1].material_override
	last_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	last_mat.albedo_color.a = last_alpha

	# Room 1 transitions to empty color
	var lerped_color: Color = color_occupied.lerp(color_empty, eased)
	_room_materials[0].albedo_color = lerped_color

	# New guest approaches from the left
	var approach_x := -_total_width / 2.0 - step
	var target_approach := -_total_width / 2.0 - room_width * 0.3
	_new_guest.position.x = lerpf(approach_x, target_approach, eased * 0.7)

	# Gentle bob for the new guest
	_new_guest.position.y = guest_radius * 1.2 + 0.002 + sin(_time * 4.0) * 0.005


func _finalize_shift() -> void:
	# Snap guests to shifted positions
	var step: float = room_width + room_gap
	var start_x := -_total_width / 2.0 + room_width / 2.0

	for i in range(num_rooms):
		var shifted_x: float = start_x + (i + 1) * step
		_guests[i].position.x = shifted_x


func _animate_new_guest(t: float) -> void:
	var eased: float = _ease_in_out(t)
	var room1_x: float = -_total_width / 2.0 + room_width / 2.0
	_new_guest.position.x = lerpf(-_total_width / 2.0 - room_width * 0.3, room1_x, eased)
	_new_guest.position.y = guest_radius * 1.2 + 0.002

	# Room 1 fills back up with new guest color
	var fill_color: Color = color_empty.lerp(color_new_guest.darkened(0.4), eased)
	_room_materials[0].albedo_color = fill_color


func _finalize_new_guest() -> void:
	var room1_x: float = -_total_width / 2.0 + room_width / 2.0
	_new_guest.position.x = room1_x


func _reset_hotel() -> void:
	# Return all guests to their original rooms
	var step: float = room_width + room_gap
	var start_x := -_total_width / 2.0 + room_width / 2.0

	for i in range(num_rooms):
		var x_pos: float = start_x + i * step
		_guests[i].position.x = x_pos
		_guests[i].position.y = guest_radius + 0.002

		# Reset transparency on last guest
		var mat: StandardMaterial3D = _guests[i].material_override
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color = color_guest
		mat.albedo_color.a = 1.0

		# Reset room colors
		_room_materials[i].albedo_color = color_occupied

	# Hide new guest and move off-screen
	_new_guest.visible = false
	_new_guest.position.x = -_total_width / 2.0 - step


func _ease_in_out(t: float) -> float:
	# Smooth cubic ease in-out
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		var f: float = 2.0 * t - 2.0
		return 0.5 * f * f * f + 1.0


## Grid system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("num_rooms"):
		num_rooms = int(config_data["num_rooms"])
	if config_data.has("shift_duration"):
		shift_duration = float(config_data["shift_duration"])
	if config_data.has("pause_between_shifts"):
		pause_between_shifts = float(config_data["pause_between_shifts"])
