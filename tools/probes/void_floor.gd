## The tower floor a map stands on, found by MAP NAME - never write a floor number into a probe.
## Floors get inserted as the curriculum is reworked (2026-11-09: Trans_Scale at 18 moved every floor >= 18 down
## one), and a probe that names its floor by number goes on passing - or failing - on whatever floor now has it.
##
##   const VoidFloor = preload("res://tools/probes/void_floor.gd")
##   var FLOOR: int = VoidFloor.of("Logic_Event")             # in the rooms the game will read (--void-draft= honoured)
##   var d: int = VoidFloor.index(draft, "WaveFunctions_Intro")  # in any rooms document (a draft, a before-snapshot)
##
## A map that is not in the tower is an error, not floor 0: of()/index() print it and return -1.

static func of(map_name: String) -> int:
	return index(preload("res://commons/void/room_source.gd").read_rooms(), map_name)

## Every map's floor in one read: {map: index}. For a probe that keys a table of shots or floors by map name.
static func table() -> Dictionary:
	var result := {}
	var floors: Array = preload("res://commons/void/room_source.gd").read_rooms().get("floors", [])
	for i in floors.size(): result[str((floors[i] as Dictionary).get("map", ""))] = i
	return result

## A list of map names as floor indices, in order (an unknown map is an error and -1).
static func all(map_names: Array) -> Array[int]:
	var at := table()
	var result: Array[int] = []
	for m in map_names:
		if not at.has(m): push_error("void_floor: no floor holds map '%s'" % m)
		result.append(int(at.get(m, -1)))
	return result

static func index(rooms: Dictionary, map_name: String) -> int:
	var floors: Array = rooms.get("floors", [])
	for i in floors.size():
		if str((floors[i] as Dictionary).get("map", "")) == map_name: return i
	push_error("void_floor: no floor holds map '%s' (%d floors)" % [map_name, floors.size()])
	return -1
