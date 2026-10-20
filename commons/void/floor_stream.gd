extends Node
## Vertical streaming: bounded visible frame, current live hall, shaft preview below.
## Visited content sleeps in RAM to preserve arbitrary museum artifact state.
const Residency := preload("floor_residency.gd")
const LEVELS_ABOVE := 4
const LEVELS_BELOW := 4
var game: Node3D
var building: Node3D
var content: Node3D
var focus := -1
var records: Dictionary = {}
var pinned: Array[int] = []
var elapsed := 0.0
var dirty := false

static func floor_window(current: int, count: int) -> Array[int]:
	var result: Array[int]=[]
	for i in range(maxi(0,current-LEVELS_ABOVE),mini(count,current+LEVELS_BELOW+1)): result.append(i)
	return result

func configure(owner_game: Node3D) -> void:
	game=owner_game;building=game.building;content=building.content
	content.floor_changed.connect(_changed)

## The switch happens after leaving a slab, not when merely jumping above it.
func floor_at(y: float) -> int:
	# A lift can rise into the previous hall's recessed-basin height. Keep the
	# current hall live until the player actually crosses its ceiling or bottom;
	# otherwise that lift is put to sleep beneath its own passenger.
	if focus>=0 and focus<building.spec.levels.size():
		var current_depth: float=maxf(.85,float(content.data.floors[focus].get("basin",{}).get("depth",0))+.3)
		var top: float=INF if focus==0 else float(building.spec.levels[focus-1])-.16
		if y>=float(building.spec.levels[focus])-current_depth and y<top:return focus
	for i in range(building.spec.levels.size()):
		# A recessed lesson belongs to this floor below its slab as well. Keep
		# its colliders and lethal contact live until the basin's bottom is passed.
		var depth: float=maxf(.85,float(content.data.floors[i].get("basin",{}).get("depth",0))+.3)
		if y>=float(building.spec.levels[i])-depth: return i
	return building.spec.levels.size()-1

func _process(delta: float) -> void:
	if not game.ready_for_play or game.returning: return
	elapsed+=delta
	var next := floor_at_position(game.body.global_position)
	if next!=focus: set_focus(next)
	if elapsed<0.15 and not dirty: return
	elapsed=0.0;dirty=false
	_refresh()

## An exterior, tall encounter belongs to its authored floor at every height.
## Regions follow the editable artifact transform; tower slabs keep the y rule.
func floor_at_position(at: Vector3) -> int:
	for region in get_tree().get_nodes_in_group("void_floor_extension"):
		if not region.is_inside_tree() or not region.contains_visitor(at): continue
		var ancestor: Node = region
		while ancestor != null:
			if ancestor.has_meta("void_content_floor"):
				return int(ancestor.get_meta("void_content_floor"))
			ancestor=ancestor.get_parent()
	return floor_at(at.y)

func _changed(index: int) -> void:
	if not records.has(index): records[index]=Residency.new(content.roots[index],building)
	records[index].refresh_pickables()
	records[index].needs_refresh=true
	dirty=true

## Explicit spawn/respawn completes the destination before the player is placed.
func set_focus(index: int) -> void:
	focus=clampi(index,0,building.spec.levels.size()-1)
	content.build_indices=[focus,focus+1]
	content.load_floor(focus,true)
	if focus+1<building.spec.levels.size(): content.load_floor(focus+1,false)
	for i in content.roots:
		if not records.has(i): _changed(i)
	building.show_floor_window(floor_window(focus,building.floors.size()))
	_refresh()

func _refresh() -> void:
	pinned.clear()
	for index in records:
		var record: RefCounted=records[index]
		# A descent belongs to its departure lesson until the next storey.
		# Keep its rotating support and tunnel collision live for both ends,
		# including a visitor waiting below for the returning wheel.
		if index == focus-1 and content.data.floors[index].get("artifacts",[]).any(
			func(item): return bool(item.get("config",{}).get("connects_next_floor",false))):
			pinned.append(int(index))
		# Keep a carried object and its owning lesson alive. A released object
		# that travelled with the player stays alive while it is still nearby.
		for point in record.pickables:
			# Regenerating an artifact can detach its old points before freeing them.
			if not is_instance_valid(point) or not point.is_inside_tree(): continue
			var held: bool=point.is_picked_up()
			if not game.vr and game.body.desktop_pointer._held == point: held = true
			var travelled: bool=absf(point.global_position.y-float(building.spec.levels[index]))>4.0 and point.global_position.distance_to(game.camera.global_position)<8.0
			if held or travelled:
				if not index in pinned:pinned.append(int(index))
				break
		var wanted := "live" if index==focus or index in pinned else ("preview" if index==focus+1 else "sleep")
		# A refresh also discovers late-created nodes, e.g. viewport readouts.
		record.set_mode(wanted)

func summary() -> Dictionary:
	var states := {}
	for i in range(building.floors.size()): states[str(i)]=records[i].mode if records.has(i) else "cold"
	return {"focus":focus,"visible_frame":floor_window(focus,building.floors.size()),"floors":states,"pinned":pinned.duplicate(),"pending_artifacts":content.pending.size(),"max_artifact_build_ms":content.max_build_ms}
