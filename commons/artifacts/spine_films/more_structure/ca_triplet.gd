extends "res://commons/artifacts/spine_films/more_structure/structure_stage.gd"
const SOURCE = preload("res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd")
var rows: Array = []
var cells: Array[MeshInstance3D] = []
var witness: Array[MeshInstance3D] = []
var links: Array[MeshInstance3D] = []
var readout: Label3D
var on_mat: StandardMaterial3D
var off_mat: StandardMaterial3D
var table: Array = []
func _build() -> void:
	title_text = "Three neighbours choose one next cell"
	phases.assign(["Read a local neighbourhood", "Use the corresponding rule bit", "The same test goes around the ring", "Keep each generation as another ring"])
	notes.assign(["The explorer's rule 90 reads left, centre and right. A bright bead is one; a dark bead is zero.", "The three inputs select one of eight bits. This is the actual _apply_rule result.", "The row wraps: the first and last cells are neighbours. All next states read the earlier row.", "Height separates recorded generations; it is a display of time, not a third spatial CA dimension."])
	source_paths.assign(["res://commons/artifacts/ca_rule_explorer/ca_rule_explorer.gd"])
	var source = SOURCE.new()
	source.cells_x = 24; source.rows_visible = 13; source.rule = 90; source._reset()
	rows.append(source._current_row.duplicate())
	for i in 12: source._advance(); rows.append(source._current_row.duplicate())
	for pattern in 8: table.append(source._apply_rule(bool(pattern&4),bool(pattern&2),bool(pattern&1)))
	evidence = {"width":24,"generations":13,"rule":90,"truth_table":table.duplicate(),"rows":rows.duplicate(true),"source_calls":["_reset","_apply_rule","_advance"],"wrapped_edges":true,"source_never_entered_tree":true}
	source.free()
	on_mat = material(TEAL); off_mat = material(Color("35414b"))
	for gen in rows.size():
		for i in 24:
			var angle := TAU*float(i)/24.0
			var node := add_ball(Vector3(cos(angle)*1.65,.35+gen*.19,sin(angle)*1.65),.095,TEAL)
			node.material_override = on_mat if rows[gen][i] else off_mat
			cells.append(node)
	for i in 3:
		witness.append(add_ball(Vector3((i-1)*.68,2.5,2.05),.19,TEAL))
		links.append(add_rod(Vector3((i-1)*.68,2.28,2.05),Vector3(0,1.72,2.05),.016,GOLD))
	witness.append(add_ball(Vector3(0,1.43,2.05),.21,TEAL))
	readout=add_label("",Vector3(0,3.18,0),CHALK)
	film_deck(); frame_scene(Vector3(0,1.65,.2),10.9,.35,.3)
func _draw(time: float) -> void:
	var phase := phase_index(time); var u := phase_progress(time)
	var pattern := mini(int(u*8.0),7)
	for i in 3:
		witness[i].visible=phase<2
		witness[i].material_override=on_mat if (pattern & (1<<(2-i))) else off_mat
	witness[3].visible=phase==1; witness[3].material_override=on_mat if table[pattern] else off_mat
	for link in links: link.visible=phase==1
	for k in cells.size():
		var gen := k/24
		cells[k].visible = (phase==2 and gen==0 and k%24<=int(u*24)) or (phase==3 and gen<=int(u*12))
	readout.text="RULE 90  /  %d %d %d  →  %d" % [(pattern>>2)&1,(pattern>>1)&1,pattern&1,int(table[pattern])] if phase<2 else ("24 CELLS  /  EDGES WRAP" if phase==2 else "GENERATION %d  /  SAME RULE"%mini(int(u*12),12))
