extends "ledger.gd"
const Walker = preload("traversal.gd")

func _init() -> void:
	# A new invented report, initially omitted. Earlier records stay intact.
	records.append({"from": 5, "to": 2, "kind": "report", "source": "R04: 5 reports to 2."})
	omitted.append(7)

func directed(reverse_arrows: bool) -> Array:
	var rows: Array = []
	for vertex in range(neighbours.size()):
		rows.append([])
	for index in active_records():
		var record: Dictionary = records[index]
		var a: int = record.to if reverse_arrows else record.from
		var b: int = record.from if reverse_arrows else record.to
		if b not in rows[a]:
			rows[a].append(b)
	return rows

func reachable(start: int, reverse_arrows: bool) -> Array[int]:
	if start < 0 or start >= neighbours.size():
		return []
	var walker = Walker.new()
	walker.neighbours = directed(reverse_arrows)
	walker.restart(true)
	walker.pending.assign([start])
	while walker.next_visit() != -1:
		pass
	return walker.visited

func component(start: int) -> Array[int]:
	var outward := reachable(start, false)
	var inward := reachable(start, true)
	var result: Array[int] = []
	for vertex in range(neighbours.size()):
		if vertex in outward and vertex in inward:
			result.append(vertex)
	return result
