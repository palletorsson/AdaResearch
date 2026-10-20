extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-column-mixing/"
var checks: Array=[]
var failures: Array=[]
var samples: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func sample(bank: Node3D,seconds: float) -> void:
	var record: Dictionary={"mixing_seconds":seconds,"columns":[]}
	for jar in bank.jars:
		var points: Array=[]
		for p: Vector3 in jar.positions():points.append([p.x,p.y,p.z])
		record.columns.append({"start":jar.found_state,"height_bits":jar._measure_entropy(),"radial_bits":jar.radial_entropy(),"positions":points})
	samples.append(record)
func run() -> void:
	var bank=load("res://commons/artifacts/ordinary_entropies/jar_states.gd").new();root.add_child(bank);bank.set_process(false)
	check("four full-size columns",bank.jars.size()==4)
	var starts: Array=[]
	for jar in bank.jars:
		var reference=load("res://commons/artifacts/ordinary_entropies/jar_snapshot.gd").new();reference.found_state=jar.found_state;root.add_child(reference)
		check("original starting coordinates / "+jar.found_state,reference.positions()==jar.positions())
		starts.append(jar.positions());reference.free()
	bank.advance(100)
	check("awaits visitor before starting",bank.elapsed==0 and bank.jars[0].positions()==starts[0])
	bank.restart();bank.advance(8)
	check("eight seconds to inspect starting states",bank.jars[0].positions()==starts[0])
	sample(bank,0)
	var previous_time:=0.0
	for t in [15.0,45.0,90.0,180.0]:
		bank.advance(t-previous_time);previous_time=t;sample(bank,t)
		for j in 4:
			var jar: Node3D=bank.jars[j]
			var valid:=true;var p: Array=jar.positions()
			for i in 80:
				var v: Vector3=jar.display_beads[i].position
				valid=valid and v.is_equal_approx(jar.display_position(p[i])) and Vector2(v.x,v.z).length()+0.032<=0.34 and v.y-0.032>=0.16 and v.y+0.032<=2.16
			check("visible and measured positions agree, all beads contained / %s / %d" % [t,j],valid)
			check("same 40/40 inventory / %s / %d" % [t,j],jar._particles_a.size()==40 and jar._particles_b.size()==40 and p.size()==80)
	check("late columns retain distinct microstates",bank.jars[0].positions()!=bank.jars[1].positions() and bank.jars[2].positions()!=bank.jars[3].positions())
	check("layers lose height segregation in this run",bank.jars[0]._measure_entropy()>0.85)
	check("shell loses radial segregation in this run",bank.jars[3].radial_entropy()>0.85)
	var late: Array=bank.jars[0].positions();bank.advance(1)
	check("motion continues after 180 seconds",bank.jars[0].positions()!=late)
	var paused_positions: Array=bank.jars[0].positions()
	bank.buttons.PAUSE.pressed.emit();bank.advance(10)
	check("pause control freezes time and positions",bank.paused and bank.elapsed==189 and paused_positions==bank.jars[0].positions())
	bank.buttons.RESTART.pressed.emit()
	check("restart resets all four starts and clock",not bank.paused and bank.elapsed==0 and bank.jars[0].positions()==starts[0] and bank.jars[3].positions()==starts[3])
	bank.advance(188)
	check("restart reproduces the 180-second trajectory",bank.jars[0].positions()==late)
	var column: Node3D=bank.jars[0]
	column.reset_mixing();column.advance_mixing(3.0)
	var single: Array=column.positions()
	column.reset_mixing()
	for i in 180:column.advance_mixing(1.0/60.0)
	var same:=true
	for i in 80:same=same and single[i].is_equal_approx(column.positions()[i])
	check("trajectory independent of frame chunking",same)
	bank.restart();bank.advance(9);var real_before: Array=bank.jars[0].positions()
	bank.set_process(true);await create_timer(0.3).timeout;bank.set_process(false)
	check("real process advances visible motion",real_before!=bank.jars[0].positions())
	bank.update_reading()
	check("live readout uses current positions",bank.readout.text.contains("%.2f" % bank.jars[0]._measure_entropy()))
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"samples":samples},"\t"));file.close()
	print("Checks: ",checks.size()," failures: ",failures.size());quit(0 if failures.is_empty() else 1)
