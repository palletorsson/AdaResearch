extends "res://commons/artifacts/spine_studies/study_forms.gd"
## An explicitly fictional record set. A line is inspectable, not an allegation.
const NAMES := ["Fund", "Studio", "Assembly", "Office", "Builder", "Archive", "Hall", "Maintenance"]
# from, to, kind, date, record. All records are authored examples, not historical sources.
const RECORDS := [
	[0,1,"grant","04-02","F01: Fund awards Studio 12 units."],
	[0,6,"grant","04-03","F02: Fund awards Hall 20 units."],
	[1,4,"payment","04-06","P01: Studio pays Builder 8 units."],
	[6,4,"payment","04-08","P02: Hall pays Builder 6 units."],
	[6,7,"payment","04-09","P03: Hall pays Maintenance 2 units."],
	[3,2,"report","04-10","R01: Office reports to Assembly."],
	[4,3,"report","04-11","R02: Builder reports to Office."],
	[1,5,"report","04-12","R03: Studio deposits a report in Archive."],
	[7,5,"report","04-13","R04: Maintenance deposits a report in Archive."],
	[5,2,"report","04-14","R05: Archive sends records to Assembly."],
	[2,6,"grant","04-15","F03: Assembly awards Hall 3 units."],
	[3,7,"payment","04-16","P04: Office pays Maintenance 1 unit."]]
const FILTERS := ["all", "grant", "payment", "report"]
var arrangement := 0
var filter_index := 0
var selected := 0
var selected_node := 0
var drawing: Node3D
var record_label: Label3D
var measure_label: Label3D
var title: Label3D
var positions: Array[Vector3] = []

func _ready() -> void:
	block(Vector3(0,3.5,-4),Vector3(15,6.6,0.16),Color("eceae2"),true)
	for x in [-6.8,6.8]: block(Vector3(x,1.7,-4.08),Vector3(0.07,3.4,0.20),Color("4b4850"),true)
	title = inscription("A RELATION NEEDS A RECORD",Vector3(0,6.2,-3.89),0.006)
	inscription("FICTIONAL ADA RECORDS / APRIL 2026 / arrows follow the recorded direction",Vector3(0,5.77,-3.88),0.0028)
	record_label = inscription("",Vector3(0,0.85,-3.86),0.0036)
	measure_label = inscription("",Vector3(0,1.45,-3.86),0.0031,Color("993c61"))
	rebuild()

func visible_edges() -> Array:
	var edges: Array = []
	for i in RECORDS.size():
		if filter_index == 0 or RECORDS[i][2] == FILTERS[filter_index]: edges.append(i)
	return edges

func degree(node_index: int) -> Vector2i:
	var result := Vector2i.ZERO
	for i in visible_edges():
		var edge: Array = RECORDS[i]
		if edge[1] == node_index: result.x += 1
		if edge[0] == node_index: result.y += 1
	return result

func rebuild() -> void:
	if drawing: remove_child(drawing); drawing.queue_free()
	drawing = Node3D.new(); add_child(drawing); positions.clear()
	for i in NAMES.size():
		var angle := TAU*float(i)/NAMES.size()
		var at := Vector3(cos(angle)*5.3,3.68+sin(angle)*1.58,-3.85)
		if arrangement == 1: at = Vector3((i%4-1.5)*3.3,4.65-float(i/4)*2.0,-3.85)
		positions.append(at)
	var edges := visible_edges()
	if selected not in edges: selected = int(edges[0])
	for index in edges:
		var edge: Array = RECORDS[index]
		var a := positions[edge[0]]; var b := positions[edge[1]]
		var mid := (a+b)*0.5+Vector3(0,0.38+0.13*(int(index)%3),0.015)
		var points := PackedVector3Array()
		for step in 33:
			var t := float(step)/32.0
			points.append(a*(1-t)*(1-t)+mid*2*t*(1-t)+b*t*t)
		var colour := Color("b74576") if index == selected else Color("47454b")
		var curve := stroke(points,colour,0.022 if index == selected else 0.009); curve.reparent(drawing)
		var tip := points[28]; var tangent := (points[28]-points[26]).normalized()
		var side := Vector3(-tangent.y,tangent.x,0)*0.085
		var arrow := stroke(PackedVector3Array([tip-tangent*0.20+side,tip,tip-tangent*0.20-side]),colour,0.012); arrow.reparent(drawing)
	for i in NAMES.size():
		var ring := PackedVector3Array()
		for n in 49: ring.append(positions[i]+Vector3(cos(TAU*n/48.0)*0.095,sin(TAU*n/48.0)*0.095,0.03))
		var line := stroke(ring,Color("b74576") if i == selected_node else Color("37313a")); line.reparent(drawing)
		var label := inscription(NAMES[i],positions[i]+Vector3(0,0.23,0.05),0.0033); label.reparent(drawing)
	var record: Array = RECORDS[selected]
	record_label.text = "%s → %s / %s / 2026-%s\n%s" % [NAMES[record[0]],NAMES[record[1]],record[2],record[3],record[4]]
	var count := degree(selected_node)
	measure_label.text = "%s / %d incoming + %d outgoing = %d incident records / filter: %s" % [NAMES[selected_node],count.x,count.y,count.x+count.y,FILTERS[filter_index]]

func control(index: int) -> void:
	match index:
		0: arrangement = (arrangement+1)%2
		1: filter_index = (filter_index+1)%FILTERS.size()
		2:
			var edges := visible_edges(); selected = int(edges[(edges.find(selected)+1)%edges.size()])
		3: selected_node = (selected_node+1)%NAMES.size()
		_: arrangement = 0; filter_index = 0; selected = 0; selected_node = 0
	rebuild()
