extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name HilbertHotelRoom

## @identity
## name: Hilbert's Hotel — Always Room For More
## lineage: Hilbert's thought experiment for countable infinity. A hotel with
##   infinitely many rooms, all occupied, can still take a new guest: every guest
##   in room n moves to room n+1, freeing room 1.
## essence: a room-scale corridor of numbered doors receding to a vanishing
##   point, every door lit OCCUPIED. A new guest arrives; a shift ripples down
##   the line as each guest steps from n to n+1, and door 1 opens for the guest.
## truth: infinitely many rooms — always room for more. A full infinite set can
##   still absorb new members, because n -> n+1 is a bijection onto a proper
##   subset of itself. Infinity is not a number; it does not "fill up."

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var occupied_gold: Color = Color(0.98, 0.80, 0.32)
@export var vacant_green: Color = Color(0.40, 0.92, 0.55)
@export var room_size: float = 7.0
@export var shift_period: float = 3.0
@export var room_count: int = 9

var _doors: Array = []      # MeshInstance3D lamps
var _guests: Array = []     # Node3D guest tokens
var _door_x: Array = []     # float x positions
var _new_guest: Node3D
var _shift_label: Label3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_doors = []
	_guests = []
	_door_x = []
	var purple_mat := _glow_mat(wire_purple, 0.5)
	var floor_mat := _matte_mat(Color(0.07, 0.08, 0.13), 0.9)
	var wall_mat := _glow_mat(cool_white, 0.4)
	var frame_mat := _steel_mat(Color(0.32, 0.34, 0.42))

	# --- floor ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.06, room_size), floor_mat))
	var hs: float = room_size * 0.5

	# chalk floor centerline running to the vanishing point
	add_child(_box(Vector3(0.0, 0.01, 0.0), Vector3(0.02, 0.01, room_size - 0.4), purple_mat))

	# --- the back wall of the corridor with numbered doors, receding ---
	# doors march from near (right, large) to far (left, small) toward a vanishing point
	var z_wall: float = -0.9  # doors sit along the back wall plane
	var wall_y: float = 1.2
	# the long wall behind the doors
	add_child(_box(Vector3(0.0, wall_y, z_wall - 0.15), Vector3(room_size - 0.4, 2.4, 0.06), wall_mat))

	# perspective: near door big on the right, far doors shrink toward left vanishing point
	var x_near: float = hs - 0.8
	var x_far: float = -hs + 0.6
	for i in range(room_count):
		var f: float = float(i) / float(room_count - 1)
		# ease so far doors crowd together (perspective)
		var fx: float = 1.0 - pow(1.0 - f, 1.6)
		var x: float = lerpf(x_near, x_far, fx)
		var sc: float = lerpf(1.0, 0.32, fx)  # shrink with distance
		_door_x.append(x)

		var holder := Node3D.new()
		holder.position = Vector3(x, 0.0, z_wall)
		holder.scale = Vector3.ONE * sc
		add_child(holder)
		# door frame
		holder.add_child(_box(Vector3(0.0, 0.95, 0.0), Vector3(0.5, 1.9, 0.08), frame_mat))
		holder.add_child(_box(Vector3(0.0, 0.95, 0.04), Vector3(0.36, 1.7, 0.04), _glass_mat(wire_purple, 0.10)))
		# OCCUPIED lamp above the door
		var lamp: MeshInstance3D = _sphere(Vector3(0.0, 2.0, 0.06), 0.06, _glow_mat(occupied_gold, 1.2))
		holder.add_child(lamp)
		_doors.append(lamp)
		# room number
		holder.add_child(_billboard_label(str(i + 1), Vector3(0.0, 1.0, 0.08), 22, cool_white))

		# a guest token standing in front of each door (all rooms full)
		var guest := Node3D.new()
		guest.position = Vector3(x, 0.0, z_wall + 0.7 * sc)
		guest.scale = Vector3.ONE * sc
		add_child(guest)
		var skin := _matte_mat(Color(0.80, 0.84, 0.95), 0.6)
		guest.add_child(_sphere(Vector3(0.0, 0.62, 0.0), 0.10, skin))
		guest.add_child(_cylinder(Vector3(0.0, 0.34, 0.0), 0.09, 0.4, skin))
		_guests.append(guest)

	# "to infinity" marker at the far end
	add_child(_billboard_label("...  to infinity", Vector3(x_far - 0.3, 1.3, z_wall), 16, wire_purple))

	# --- the NEW guest arriving from the near end ---
	_new_guest = Node3D.new()
	_new_guest.position = Vector3(x_near + 1.4, 0.0, z_wall + 1.2)
	add_child(_new_guest)
	var new_skin := _matte_mat(vacant_green, 0.5)
	_new_guest.add_child(_sphere(Vector3(0.0, 0.66, 0.0), 0.12, new_skin))
	_new_guest.add_child(_cylinder(Vector3(0.0, 0.36, 0.0), 0.10, 0.44, new_skin))
	add_child(_billboard_label("new guest", _new_guest.position + Vector3(0.0, 1.0, 0.0), 14, vacant_green))

	# the rule label (updates as the shift happens)
	_shift_label = _billboard_label("everyone: room n -> room n+1", Vector3(0.0, 2.6, 0.0), 20, occupied_gold)
	add_child(_shift_label)

	# --- overhead title ---
	add_child(_billboard_label("INFINITELY MANY ROOMS", Vector3(0.0, 3.7, 0.0), 36, cool_white))
	add_child(_billboard_label("ALWAYS ROOM FOR MORE", Vector3(0.0, 3.4, 0.0), 30, occupied_gold))
	add_child(_billboard_label("Hilbert's hotel — countable infinity", Vector3(0.0, 3.12, 0.0), 16, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	var phase: float = fmod(_t, shift_period) / shift_period
	# Phase layout:
	#   0.0-0.35  new guest walks up to door 1
	#   0.35-0.75 the shift ripples: each guest n moves to door n+1
	#   0.75-1.0  door 1 lit vacant, new guest enters, then reset
	var z_wall: float = -0.9

	# --- shift ripple: guest i moves from its door toward door i+1 ---
	var shift_amt: float = clampf((phase - 0.35) / 0.4, 0.0, 1.0)
	var ripple_eased: float = shift_amt * shift_amt * (3.0 - 2.0 * shift_amt)
	for i in range(_guests.size()):
		var guest: Node3D = _guests[i]
		if not is_instance_valid(guest):
			continue
		var from_x: float = _door_x[i]
		var to_x: float = _door_x[i + 1] if i + 1 < _door_x.size() else _door_x[i] - 0.6
		# stagger the ripple so it visibly travels down the corridor
		var local: float = clampf(ripple_eased * float(_guests.size()) - float(i), 0.0, 1.0)
		var lx: float = lerpf(from_x, to_x, local)
		var sc: float = guest.scale.x
		guest.position.x = lx
		# little hop while moving
		guest.position.y = sin(local * PI) * 0.08 * sc

	# --- door lamps: door 1 turns vacant-green during the shift, gold otherwise ---
	for i in range(_doors.size()):
		var lamp: MeshInstance3D = _doors[i]
		if not is_instance_valid(lamp):
			continue
		var m: StandardMaterial3D = lamp.material_override as StandardMaterial3D
		if m == null:
			continue
		var base_e: float = 1.2 if emissive else 0.4
		if i == 0 and shift_amt > 0.3 and phase < 0.92:
			# room 1 freed: green
			m.albedo_color = vacant_green
			m.emission = vacant_green
			m.emission_energy_multiplier = base_e * (1.0 + 0.5 * sin(_t * 6.0))
		else:
			m.albedo_color = occupied_gold
			m.emission = occupied_gold
			m.emission_energy_multiplier = base_e

	# --- the new guest walks to door 1, waits, then enters ---
	if is_instance_valid(_new_guest):
		var x_near: float = _door_x[0] if _door_x.size() > 0 else 2.0
		var start := Vector3(x_near + 1.4, 0.0, z_wall + 1.2)
		var at_door := Vector3(x_near, 0.0, z_wall + 0.7)
		if phase < 0.35:
			var f: float = phase / 0.35
			_new_guest.position = start.lerp(at_door, f * f * (3.0 - 2.0 * f))
			_new_guest.visible = true
		elif phase < 0.88:
			_new_guest.position = at_door
			_new_guest.visible = true
			_new_guest.position.y = sin(_t * 5.0) * 0.03
		else:
			# steps into room 1 and the cycle resets
			var f2: float = (phase - 0.88) / 0.12
			_new_guest.position = at_door.lerp(Vector3(x_near, 0.0, z_wall), f2)
			_new_guest.visible = f2 < 0.7

	# --- the rule label pulses during the shift ---
	if is_instance_valid(_shift_label):
		var lit: float = 0.5 + 0.5 * sin(_t * 4.0)
		var active: bool = shift_amt > 0.0 and shift_amt < 1.0
		_shift_label.modulate = occupied_gold.lerp(cool_white, (lit * 0.4) if active else 0.0)
		_shift_label.scale = Vector3.ONE * (1.0 + (lit * 0.12 if active else 0.0))
