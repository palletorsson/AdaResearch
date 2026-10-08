# @identity
# essence: ten laser measures in one rack, all sweeping the same cone in lockstep — ten dead-parallel beams that move as one sheet of light, with a phase step that can break them into a travelling wave instead
# desire: the learner sees that ten things can be one thing, and that what makes them one is not proximity or a rail but agreement about phase — and can break that agreement with a single number and watch the object become a crowd
# critical_parameter: phase_step_deg against motion — the SAME number that turns a row into a wave under yaw turns a figure into scatter under orbit. 0 is the default because orbit is the default and two axes already make the shape
# triggers: _ready() builds the rail, the end posts, ten collars and ten laser_measure bodies; _process() turns each mount by sin and cos of TAU*f*t + i*step in quadrature, which is the cone
# emerges: a solid sheet of ten parallel beams rotating through a cylinder — and, at any non-zero phase step, that sheet coming apart into a spray. The pattern is on the far wall, never on the rack
# needs: the laser_measure primitive [present]; apply_grid_config [present, 2026-09-04]; a surface for the beams to land on within max_range [the room provides it, or the wave is invisible]
# relationships: composes commons/primitives/laser_measure (handheld, grabbable) as a MOUNTED instrument — same body, no pickup; kin to the wavefunctions sequence's phase demonstrations and to array_tutorial's index-as-argument; the rack is the array, the phase step is the rule applied to the index
# truth: an offset is not a quality of a thing, it is a relation to what the thing is already doing — which is why the same 36 degrees builds a wave out of a row and tears a figure into a spray. Under one motion agreement is dead and difference is the medium; under another, agreement is the whole object and difference is only noise. The number does not know which; it never did. Nothing crosses the rack, and something crosses the rack.

extends Node3D
class_name LaserMeasureRack

## The instrument itself, taken as a SCRIPT rather than as its scene. The scene
## (grab_laser_measure.tscn) is a grab_stick — a pickable RigidBody — and a
## mounted instrument that the physics server also owns is a fight nobody wins:
## a per-frame transform write on a body a hand can take is exactly the bug that
## kept CoordinateSystem3M's point at its spawn for three rounds. Here the body
## is built by the same code on a plain Node3D, so the rack owns the transform
## and there is nothing to grab.
const LaserMeasureScript = preload("res://commons/primitives/laser_measure/laser_measure.gd")

@export_category("The rack")
## Palle asked for ten. If you switch `motion` to yaw or pitch, 360 / count is
## the phase step that stands exactly one wave on the rack — 36 at this count.
@export_range(1, 24) var count: int = 10
## Centre-to-centre, in metres. The instrument's guard is 86 mm across, so
## anything under ~0.11 has them touching.
@export var spacing: float = 0.17
@export var rail_color: Color = Color(0.17, 0.17, 0.19)
@export var collar_color: Color = Color(0.75, 0.38, 0.13)   # the tool's own copper
@export var show_rail: bool = true

@export_category("The motion")
## What the sine drives.
##   yaw        — the beams sweep sideways; the wave is read ACROSS the far wall
##   pitch      — they sweep up and down; the wave is read as a rising line
##   orbit      — yaw and pitch in quadrature; each beam traces a cone
##   rise       — no rotation, the instruments themselves rise and fall in place
##   lissajous  — yaw at f, pitch at f * lissajous_ratio; each beam draws a figure
@export_enum("yaw", "pitch", "orbit", "rise", "lissajous") var motion: String = "orbit"
@export var amplitude_deg: float = 22.0
@export var frequency_hz: float = 0.22
## THE PATTERN LIVES HERE, and which way it cuts depends on the motion.
##
## Under `yaw` or `pitch` the offset IS the artifact: 360 / count stands one
## whole wave on the rack, and 0 collapses it to ten instruments doing the
## same thing at once, which is a bar.
##
## Under `orbit` it is the other way round, which is why 0 is the default.
## Two axes already make the figure, so the ten stay parallel and sweep a
## cone as one rigid comb; an offset there does not build anything, it only
## decorrelates ten copies of a shape that was already whole.
@export var phase_step_deg: float = 0.0
## Metres, for `rise` only.
@export var rise_amplitude: float = 0.07
@export var lissajous_ratio: float = 2.0
@export var running: bool = true

@export_category("The instruments")
## Far shorter than the handheld default of 50 m: ten beams reaching across a
## whole hall is a light show, not a measurement.
@export var max_range: float = 6.0
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 0.9)
@export var laser_hit_color: Color = Color(0.1, 1.0, 0.3, 0.9)
## Ten hit-point labels and ten target names is noise, so both are off here and
## the LCD on each handle still reads. One instrument wants its readout; ten
## want to be a wave.
@export var show_inline_readout: bool = false
@export var show_target_name: bool = false
## Off, and it must stay off by default. A rack of ten sweeping lethal beams
## across a corridor is a wall of death that nobody placed on purpose.
@export var lethal: bool = false

var _mounts: Array[Node3D] = []
var _base_y: PackedFloat32Array = PackedFloat32Array()
var _t: float = 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	# remove BEFORE freeing: queue_free lands at end of frame, so a rebuild that
	# only queues leaves the old ten in the tree for one more frame, still
	# raycasting and still drawn on top of the new ten
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mounts.clear()
	_base_y = PackedFloat32Array()

	var n: int = maxi(1, count)
	var span: float = float(n - 1) * spacing

	if show_rail:
		_build_rail(span)

	for i in range(n):
		var x: float = float(i) * spacing - span * 0.5
		var pivot := Node3D.new()
		pivot.name = "Mount%d" % i
		pivot.position = Vector3(x, 0.0, 0.0)
		add_child(pivot)
		_mounts.append(pivot)
		_base_y.append(0.0)

		# the collar it sits in — without it ten tools hang in mid-air
		var collar := MeshInstance3D.new()
		collar.name = "Collar"
		var cm := CylinderMesh.new()
		cm.top_radius = 0.032
		cm.bottom_radius = 0.032
		cm.height = 0.030
		cm.radial_segments = 16
		collar.mesh = cm
		# the barrel runs along Z, so the collar around it does too
		collar.rotation_degrees = Vector3(90, 0, 0)
		var col_mat := StandardMaterial3D.new()
		col_mat.albedo_color = collar_color
		col_mat.metallic = 0.7
		col_mat.roughness = 0.35
		collar.material_override = col_mat
		pivot.add_child(collar)

		# EXPORTS BEFORE add_child. laser_measure builds its whole body in
		# _ready, and add_child runs _ready immediately — a value set afterwards
		# is a value the body was not built with.
		var lm := Node3D.new()
		lm.name = "LaserMeasure%d" % i
		lm.set_script(LaserMeasureScript)
		lm.set("max_range", max_range)
		lm.set("laser_color", laser_color)
		lm.set("laser_hit_color", laser_hit_color)
		lm.set("show_inline_readout", show_inline_readout)
		lm.set("show_target_name", show_target_name)
		lm.set("lethal", lethal)
		# the handle sits back in the collar with the guard proud of it
		lm.position = Vector3(0.0, 0.0, -0.02)
		pivot.add_child(lm)


func _build_rail(span: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = rail_color
	mat.metallic = 0.25
	mat.roughness = 0.6

	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var bm := BoxMesh.new()
	bm.size = Vector3(span + 0.18, 0.045, 0.055)
	rail.mesh = bm
	rail.position = Vector3(0.0, 0.0, 0.075)   # behind the handles
	rail.material_override = mat
	add_child(rail)

	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post%s" % ("L" if sx < 0.0 else "R")
		var pm := BoxMesh.new()
		pm.size = Vector3(0.045, 0.30, 0.055)
		post.mesh = pm
		post.position = Vector3(sx * (span * 0.5 + 0.068), -0.17, 0.075)
		post.material_override = mat
		add_child(post)


func _process(delta: float) -> void:
	if _mounts.is_empty() or not running:
		return
	_t += delta
	var amp: float = deg_to_rad(amplitude_deg)
	var step: float = deg_to_rad(phase_step_deg)
	var w: float = TAU * frequency_hz * _t
	for i in range(_mounts.size()):
		var pivot: Node3D = _mounts[i]
		var phase: float = w + float(i) * step
		match motion:
			"pitch":
				pivot.rotation = Vector3(amp * sin(phase), 0.0, 0.0)
			"orbit":
				# quadrature: the same sine a quarter turn apart on two axes, so
				# the beam traces a cone rather than a line
				pivot.rotation = Vector3(amp * sin(phase), amp * cos(phase), 0.0)
			"rise":
				pivot.rotation = Vector3.ZERO
				pivot.position.y = _base_y[i] + rise_amplitude * sin(phase)
			"lissajous":
				pivot.rotation = Vector3(
					amp * sin(phase * lissajous_ratio), amp * sin(phase), 0.0)
			_:
				pivot.rotation = Vector3(0.0, amp * sin(phase), 0.0)


## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "count" · "spacing" · "motion" · "amplitude_deg" · "frequency_hz"
##   "phase_step_deg" · "rise_amplitude" · "lissajous_ratio" · "running"
##   "max_range" · "lethal" · "show_rail" · "readouts"
##   "laser_color" / "hit_color" — Color, [r,g,b] or an html string
## Anything that changes the BODIES rebuilds; the motion keys do not, because a
## rebuild restarts the wave from zero and the whole point is that it is running.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false

	if config_data.has("count"):
		count = clampi(int(config_data["count"]), 1, 24)
		rebuild = true
	if config_data.has("spacing"):
		spacing = float(config_data["spacing"])
		rebuild = true
	if config_data.has("max_range"):
		max_range = float(config_data["max_range"])
		rebuild = true
	if config_data.has("show_rail"):
		show_rail = bool(config_data["show_rail"])
		rebuild = true
	if config_data.has("lethal"):
		lethal = bool(config_data["lethal"])
		rebuild = true
	if config_data.has("readouts"):
		show_inline_readout = bool(config_data["readouts"])
		rebuild = true
	if config_data.has("laser_color"):
		laser_color = _as_color(config_data["laser_color"], laser_color)
		rebuild = true
	if config_data.has("hit_color"):
		laser_hit_color = _as_color(config_data["hit_color"], laser_hit_color)
		rebuild = true

	if config_data.has("motion"):
		var m: String = str(config_data["motion"]).to_lower().strip_edges()
		if m in ["yaw", "pitch", "orbit", "rise", "lissajous"]:
			motion = m
	if config_data.has("amplitude_deg"):
		amplitude_deg = float(config_data["amplitude_deg"])
	if config_data.has("frequency_hz"):
		frequency_hz = float(config_data["frequency_hz"])
	if config_data.has("phase_step_deg"):
		phase_step_deg = float(config_data["phase_step_deg"])
	if config_data.has("rise_amplitude"):
		rise_amplitude = float(config_data["rise_amplitude"])
	if config_data.has("lissajous_ratio"):
		lissajous_ratio = float(config_data["lissajous_ratio"])
	if config_data.has("running"):
		running = bool(config_data["running"])

	if rebuild and is_inside_tree():
		_build()


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
