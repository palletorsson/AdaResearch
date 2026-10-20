extends RefCounted
const STEP := 0.5
const REACH := 8.0
const NEAR := 0.32
var nodes: Array = []
var points: Array = []
var reached: Array = []
var generation := 0
var reason := ""

static func field() -> Array:
	return [Vector3(-2,1.5,0), Vector3(-2.5,2.5,0.4), Vector3(-3,3.5,0),
		Vector3(1.5,2.5,0), Vector3(2,3.5,-0.5), Vector3(2.5,4.5,0),
		Vector3(0,5.5,1), Vector3(0,6,0)]

func reset() -> void:
	nodes = [{"position":Vector3.ZERO, "parent":-1, "target":-1, "active":true}]
	points = field()
	reached.resize(points.size()); reached.fill(false)
	generation = 0
	reason = ""

func nearest(at: Vector3) -> int:
	var chosen := -1
	var distance := REACH
	for i in points.size():
		if reached[i]: continue
		var d: float = at.distance_to(points[i])
		if d < distance:
			distance = d
			chosen = i
	return chosen

func step() -> bool:
	if nodes.size() >= 192:
		reason = "record budget"
		return false
	var additions: Array = []
	var consumed: Array = []
	for i in nodes.size():
		var branch: Dictionary = nodes[i]
		if not branch.active: continue
		var target: int = nearest(branch.position)
		if target < 0:
			branch.active = false
			continue
		var offset: Vector3 = points[target] - branch.position
		var next: Vector3 = branch.position + offset.normalized() * STEP
		additions.append({"position":next, "parent":i, "target":target, "active":true})
		branch.active = false
		if offset.length() < NEAR:
			consumed.append(target)
			branch.active = false
	for child in additions:
		if nodes.size() >= 192: break
		nodes.append(child)
	for i in consumed: reached[i] = true
	generation += 1
	reason = "" if not additions.is_empty() else "no active target in range"
	return not additions.is_empty()

func distinct_count() -> int:
	var positions: Dictionary = {}
	for row in nodes: positions[row.position] = true
	return positions.size()
