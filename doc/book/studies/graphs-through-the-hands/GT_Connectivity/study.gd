extends "network_study.gd"
const Reachability = preload("reachability.gd")
var start := 4

func _init() -> void:
	ledger = Reachability.new()

func _ready() -> void:
	super._ready()
	for connection in point.action_pressed.get_connections():
		point.action_pressed.disconnect(connection.callable)
	point.action_pressed.connect(func(_source): toggle_record())
	for child in controls[0].get_children():
		if child is Label3D:
			child.text = "START"
	for child in controls[1].get_children():
		if child is Label3D:
			child.text = "RETURN"
	redraw()

# The inherited first button and key 1 call this method.
func cycle_filter() -> void:
	if point.held():
		return
	start = (start + 1) % places.size()
	redraw()

func toggle_record() -> void:
	if 7 in ledger.omitted:
		ledger.omitted.erase(7)
	else:
		ledger.omitted.append(7)
	redraw()

func _process(_delta: float) -> void:
	if point.held():
		var local := to_local(point.global_position) - FRONT
		places[start] = Vector3(local.x, local.y, 0)
	else:
		point.position = places[start] + FRONT
	redraw()

func redraw() -> void:
	super.redraw()
	var outward: Array[int] = ledger.reachable(start, false)
	var inward: Array[int] = ledger.reachable(start, true)
	for vertex in range(places.size()):
		var out: bool = vertex in outward
		var back: bool = vertex in inward
		var tag := "BOTH" if out and back else ("OUT" if out else ("BACK" if back else "neither"))
		labels[vertex].text = "%d / %s" % [vertex, tag]
		lamps[vertex].material_override.albedo_color = Color("8fe2ba") if out and back else (Color("eaa16d") if out else (Color("79a9ef") if back else Color("777984")))
	caption.text = "START %d / component %s" % [start, str(ledger.component(start))]
	caption.text += "\nOUT: reachable. BACK: can reach start. BOTH: mutual."
	caption.text += "\n1: start (release first)   trigger / 2: return   3: layout   R: reset"
	source_label.text = ledger.records[7].source
	source_label.text += "\n" + ("return omitted" if 7 in ledger.omitted else "return included")

func reset() -> void:
	if point.held():
		return
	super.reset()
	start = 4
	ledger.omitted.assign([7])
	redraw()
