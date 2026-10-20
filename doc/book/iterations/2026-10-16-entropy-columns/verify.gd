extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-entropy-columns/"
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var bank=load("res://commons/artifacts/ordinary_entropies/jar_states.gd").new();stage.add_child(bank)
	check("four columns",bank.jars.size()==4)
	check("no comparison table",bank.get_node_or_null("TableTop")==null)
	check("side panel separate from specimens",bank.get_node("ReadingPanel").position==Vector3(-2.35,0,1.25))
	for i in 4:
		var column: Node3D=bank.jars[i]
		var reference=load("res://commons/artifacts/ordinary_entropies/jar_snapshot.gd").new();reference.found_state=column.found_state;reference.position.x=10;stage.add_child(reference)
		check("retained small-jar coordinates unchanged "+str(i),column.positions()==reference.positions())
		check("height reading unchanged "+str(i),is_equal_approx(column._measure_entropy(),reference._measure_entropy()))
		check("radial reading unchanged "+str(i),is_equal_approx(column.radial_entropy(),reference.radial_entropy()))
		check("two metre glass "+str(i),is_equal_approx(column.column.get_node("Glass").mesh.height,2.0))
		check("eighty displayed beads "+str(i),column.display_beads.size()==80)
		var valid:=true;var neutral:=true;var retained: Array=column.positions()
		for j in 80:
			var bead: MeshInstance3D=column.display_beads[j]
			valid=valid and bead.position.is_equal_approx(column.display_position(retained[j])) and is_equal_approx(bead.mesh.radius,0.032)
			valid=valid and Vector2(bead.position.x,bead.position.z).length()+bead.mesh.radius<=0.34 and bead.position.y-bead.mesh.radius>=0.16 and bead.position.y+bead.mesh.radius<=2.16
			neutral=neutral and not bead.material_override.emission_enabled
		check("same mapping, round beads, contained in column "+str(i),valid)
		check("non-emissive specimens "+str(i),neutral)
		check("source geometry hidden and collision disabled "+str(i),not column._jar_body.visible and column._jar_body.collision_layer==0)
		check("full-size column has collision "+str(i),column.column.get_node("ColumnBoundary")!=null)
		var before: Array=column.positions();await create_timer(0.1).timeout
		check("snapshot remains still "+str(i),before==column.positions());reference.queue_free();await process_frame
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"\t"));file.close()
	print("Checks: ",checks.size()," failures: ",failures.size());quit(0 if failures.is_empty() else 1)
