extends RefCounted

const STEP := 0.5
const REACH := 8.0
const KILL := 0.32
var nodes: Array = []
var points: Array = []
var active: Array = []
var network := false
var generation := 0
var reason := ""

static func field(wide: bool) -> Array:
	if not wide:
		return [Vector3(-2,3,0), Vector3(2,3,0), Vector3(0,5,0)]
	return [Vector3(-2,1.5,0), Vector3(-2.5,2.5,0.4), Vector3(-3,3.5,0),
		Vector3(1.5,2.5,0), Vector3(2,3.5,-0.5), Vector3(2.5,4.5,0),
		Vector3(0,5.5,1), Vector3(0,6,0)]

func reset(wide: bool) -> void:
	nodes = [{"position":Vector3.ZERO, "parent":-1}]
	points = field(wide)
	active = points.duplicate()
	generation = 0
	reason = ""

func eligible() -> Array:
	var result: Array = []
	for i in nodes.size():
		if true or not nodes.any(func(n): return n.parent == i): result.append(i)
	return result

func decision() -> Dictionary:
	var sites: Array = eligible()
	var sums: Dictionary = {}
	for i in sites: sums[i] = Vector3.ZERO
	var remove: Array = []
	var votes: Array = []
	for p in active:
		var nearest := -1
		var distance := REACH
		for i in sites:
			var d: float = p.distance_to(nodes[i].position)
			if d < distance:
				distance = d
				nearest = i
		if nearest < 0: continue
		if distance <= KILL:
			remove.append(p)
		else:
			var direction: Vector3 = (p - nodes[nearest].position).normalized()
			sums[nearest] += direction
			votes.append({"point":p, "site":nearest, "direction":direction})
	return {"sums":sums, "remove":remove, "votes":votes}

func step() -> bool:
	if generation >= 60 or nodes.size() >= 192:
		reason = "budget"
		return false
	var d: Dictionary = decision()
	for p in d.remove: active.erase(p)
	var additions: Array = []
	for i in d.sums:
		var sum: Vector3 = d.sums[i]
		if sum.length_squared() < 0.00000001: continue
		var next: Vector3 = nodes[i].position + sum.normalized() * STEP
		if network and (nodes.any(func(n): return n.position.distance_squared_to(next) < 0.00000001)
			or additions.any(func(n): return n.position.distance_squared_to(next) < 0.00000001)): continue
		if nodes.size() + additions.size() >= 192: break
		additions.append({"position":next, "parent":i})
	nodes.append_array(additions)
	generation += 1
	reason = "" if not additions.is_empty() else ("targets reached" if active.is_empty() else "no new direction")
	return not additions.is_empty()
