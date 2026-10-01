extends Node3D
## Borrowed from Trace and Plane (chapters 6 and 7): the recorder, made small
## and changed for the keys. It is the script of walk.tscn. One contract:
##   Walk the Hand with the four move keys. Space (the action `pause`) closes
##   the walk and prints it as ONE LINE OF CODE, ready to paste over the list
##   `walk` in extrude.gd. Space again starts a new walk.
## The keys move the Hand in straight runs. So this recorder does not keep a
## position every few centimetres, as Trace did: it keeps the places where the
## Hand starts, turns and stops. What the line holds:
##   - those corners, on the floor (y is 0), rounded to centimetres;
##   - clockwise seen from above, whichever way you walked. Godot draws the
##     side of a triangle whose corners run clockwise, so extrude() needs it so;
##   - no corner closer than `gate` to the one before it, and none on a straight
##     line between its two neighbours.
## The Hand cannot leave the dark square, 1.6 m wide and deep: the place a
## guest has in your room. `outline` holds the last closed walk.

const Look := preload("res://supplied/look.gd")

@export var gate := 0.05      # metres: two corners closer than this are one

var kept: Array[Vector3] = []      # the walk so far: where the Hand started and where it turned
var outline: Array[Vector3] = []   # the last closed walk, clockwise seen from above
var open := true
var _before := Vector3.INF         # where the Hand was a frame ago
var _heading := Vector3.ZERO       # the way it was going then

func _ready() -> void:
	$Paper.material_override = Look.paint(Look.SHADE)
	$Hand.material_override = Look.paint(Look.BONE)

func _process(_delta: float) -> void:
	var at := Vector3($Hand.position.x, 0.0, $Hand.position.z)
	if Input.is_action_just_pressed("pause"):
		if open:
			keep(at)
			if kept.size() >= 3:
				close()
		else:
			kept.clear()
			open = true
			_before = Vector3.INF
	if open:
		follow(at)
	var line: Array = []
	for point in (kept if open else outline):
		line.append(point + Vector3.UP * 0.02)      # just above the paper
	line.append(at + Vector3.UP * 0.02 if open else line[0])
	$Strip.draw(line)
	if open:
		$Readout.text = "walk a loop: WASD or the arrows\nSpace closes it        %d corners" % kept.size()
	else:
		$Readout.text = "closed: %d corners, %.2f m2\nthe line is in the Output panel        Space: a new walk" % [outline.size(), area_of(outline)]

## One frame of the walk: keep the start, and every place where the Hand turns.
func follow(at: Vector3) -> void:
	if _before == Vector3.INF:
		keep(at)
		_before = at
		_heading = Vector3.ZERO
		return
	var step := at - _before
	if step.length() < 0.0001:
		return                                      # the Hand stands still
	var heading := step.normalized()
	if _heading != Vector3.ZERO and heading.dot(_heading) < 0.999:
		keep(_before)                               # it turned: the place it turned at is a corner
	_heading = heading
	_before = at

func keep(point: Vector3) -> void:
	if kept.is_empty() or (point - kept[-1]).length() >= gate:
		kept.append(point)

func close() -> void:
	open = false
	outline = corners_of(kept)
	if area_of(outline) < 0.0:
		outline.reverse()
	print(as_code(outline))

## The kept positions without the ones on a straight line between their neighbours.
func corners_of(points: Array[Vector3]) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for i in range(points.size()):
		var before := points[i - 1]
		var after := points[(i + 1) % points.size()]
		var run := after - before
		var off := (points[i] - before).cross(run).length() / maxf(run.length(), 0.0001)
		if off > 0.01:      # further than a centimetre from that line
			corners.append(points[i])
	return corners

## The area the outline encloses, in square metres: positive when its corners
## run clockwise seen from above, negative when they run the other way.
func area_of(points: Array[Vector3]) -> float:
	var twice := 0.0
	for i in range(points.size()):
		var a := points[i - 1]
		var b := points[i]
		twice += a.x * b.z - b.x * a.z
	return twice / 2.0

func as_code(points: Array[Vector3]) -> String:
	var parts: Array[String] = []
	for point in points:
		parts.append("Vector3(%s, 0, %s)" % [snappedf(point.x, 0.01), snappedf(point.z, 0.01)])
	return "var walk: Array[Vector3] = [" + ", ".join(parts) + "]"
