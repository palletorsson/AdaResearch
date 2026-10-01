extends Node3D
## Given: it joins the parts of the study and does none of its work.
##   Body      the MeshInstance3D with field_body.gd, the script the lesson builds
##   Walker    the supplied walker: WASD or the arrows walk it, C changes the camera
##   Readout   one line over the scene: what the body is now and what it cost
## Space  the next threshold of 0.2, 0.4, 0.6 and 0.8, and the body is built again
## M      a standing hole in the field, 0.6 m in front of the walker
## It asks the body only for what the body has at that stage of the lesson, so
## it runs with every stage. From the moment a build is asked for with a key
## until two frames after the new skin is on, it keeps the longest frame.

const Look := preload("res://supplied/look.gd")
const VALUES := [0.2, 0.4, 0.6, 0.8]

var watching := false   # a build was asked for and we are counting frames
var left := -1          # frames still to count after the new skin is on
var longest := -1.0     # the longest frame while counting, in milliseconds; -1: not counted yet
var triangles := 0      # of the skin that is on now
var _before := 0        # the clock at the frame before, in microseconds

func _ready() -> void:
	$Readout.modulate = Look.INK
	$Readout.outline_modulate = Look.SHADE
	$Readout.outline_size = 12
	if $Body.has_signal("built"):
		$Body.built.connect(_on_built)
		if $Body.mesh != null:
			_on_built()   # the body was built before this script began to listen

## Start counting frames: call it just before a build is asked for.
func watch() -> void:
	watching = true
	left = -1
	longest = 0.0

func _on_built() -> void:
	left = 2
	var mesh: Mesh = $Body.mesh
	@warning_ignore("integer_division")
	triangles = mesh.surface_get_array_len(0) / 3 if mesh != null and mesh.get_surface_count() > 0 else 0
	say()

func next_threshold() -> void:
	if not $Body.has_method("rebuild"):
		return
	var i := VALUES.find(snappedf($Body.threshold, 0.01))
	$Body.threshold = VALUES[(i + 1) % VALUES.size()]
	watch()
	$Body.rebuild()

func carve_ahead() -> void:
	if not $Body.has_method("carve"):
		return
	watch()
	$Body.carve($Walker.global_position - $Walker.global_basis.z * 0.6)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if watching and _before > 0:
		longest = maxf(longest, (now - _before) / 1000.0)
		if left > 0:
			left -= 1
		elif left == 0:
			watching = false
			say()
	_before = now
	if Input.is_action_just_pressed("pause"):
		next_threshold()
	if Input.is_action_just_pressed("drop"):
		carve_ahead()

## Writes the line over the scene. `longest` is known two frames after the skin is on.
func say() -> void:
	var body := $Body
	var where := "on a worker thread" if body.get("threaded") else "on the main thread"
	var frame := "press Space to count it"
	if watching:
		frame = "..."
	elif longest >= 0.0:
		frame = "%.0f ms" % longest
	$Readout.text = "threshold %.1f: %d %s, %d triangles\nbuilt in %.0f ms %s; the longest frame meanwhile %s\nSpace: the next threshold    M: carve ahead of the walker" % [
		body.threshold, body.pieces, "body" if body.pieces == 1 else "bodies", triangles, body.cost, where, frame]
