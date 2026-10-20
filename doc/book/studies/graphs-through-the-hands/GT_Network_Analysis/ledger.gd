extends "route.gd"
# Invented events. Each direction is authored, not inferred from a drawing.
var records: Array = [
	{"from": 0, "to": 1, "kind": "report", "source": "R01: 0 reports to 1."},
	{"from": 0, "to": 2, "kind": "payment", "source": "P01: 0 pays 2."},
	{"from": 1, "to": 3, "kind": "report", "source": "R02: 1 reports to 3."},
	{"from": 1, "to": 4, "kind": "payment", "source": "P02: 1 pays 4."},
	{"from": 2, "to": 5, "kind": "report", "source": "R03: 2 reports to 5."},
	{"from": 2, "to": 6, "kind": "payment", "source": "P03: 2 pays 6."},
	{"from": 4, "to": 5, "kind": "payment", "source": "P04: 4 pays 5."},
]
var omitted: Array[int] = []
var filter_kind := "all"

func active_records() -> Array[int]:
	var result: Array[int] = []
	for i in range(records.size()):
		if i not in omitted and (filter_kind == "all" or records[i].kind == filter_kind):
			result.append(i)
	return result

func counts(vertex: int) -> Vector2i:
	var result := Vector2i.ZERO
	for i in active_records():
		var record: Dictionary = records[i]
		if record.to == vertex:
			result.x += 1
		if record.from == vertex:
			result.y += 1
	return result
