extends RefCounted
var initial := {"prey":0, "predator":0}
var events: Array[Dictionary] = []

func begin(prey: int, predators: int) -> void:
	initial = {"prey":prey, "predator":predators}
	events.clear()

func record(event: Dictionary) -> void:
	events.append(event.duplicate(true))

func total(species: String, kind: String) -> int:
	var amount := 0
	for event in events:
		if event.species == species and event.kind == kind:
			amount += int(event.amount)
	return amount

func expected(species: String, include_supplied: bool = false) -> int:
	var count: int = initial[species]
	count += total(species,"birth")
	count -= total(species,"loss")
	if include_supplied:
		count += total(species,"supplied")
	return count

func difference(species: String, actual: int, include_supplied: bool = false) -> int:
	return actual-expected(species,include_supplied)
