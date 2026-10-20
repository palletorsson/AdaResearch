extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-09-assemblage-the-choices-remain/"
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void: run.call_deferred()
func check(title: String, ok: bool) -> void:
	checks.append({"name":title,"passed":ok})
	if not ok: failures.append(title)
	print("ASSEMBLAGE ","PASS " if ok else "FAIL ",title)
func settle() -> void:
	for i in 3: await physics_frame
	await process_frame
func samples(record: Dictionary) -> Array:
	var result: Array=[]
	for row in record.rows: result.append(row.map(func(c):return c.sample))
	return result
func count_a(bits: Array) -> int:
	var count:=0
	for row in bits:
		for a in row: if a:count+=1
	return count
func same_cells(record: Dictionary, source: Node) -> bool:
	if samples(record)!=source.samples():return false
	for r in 12:
		for c in 12:
			if record.rows[r][c].tint!=source._woven[r][c].get_meta("tint"):return false
	return true
func same_marks(study: Node, source: Node) -> bool:
	for r in 12:
		for c in 12:
			var mark: MeshInstance3D=study.drawing.get_child(0).get_child(1+r*12+c)
			var original: MeshInstance3D=source._woven[r][c]
			if not mark.mesh.size.is_equal_approx(original.mesh.size) or not is_equal_approx(mark.rotation.z,original.rotation.z):return false
	return true
func key(study: Node, code: int) -> void:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=true;study._unhandled_key_input(e)
func run() -> void:
	var host:=Node3D.new();host.position=Vector3(4,0,2);host.rotation.y=.7;root.add_child(host)
	var study=load(DIR+"printed/assemblage.gd").new();host.add_child(study);await settle()
	var model=study.model;var initial:Dictionary=model.keep();var initial_bits:Array=model.choices(initial);var initial_count:=count_a(initial_bits)
	check("Printed program builds three144-mark sheets and inherited point",study.drawing.get_child_count()==3 and study.drawing.get_child(0).get_child_count()==145 and study.point.has_method("pick_up"))
	check("Opening witness retains complete separate record",study.held==initial and not is_same(study.held.rows,model.data.rows))
	var source=load("res://commons/artifacts/ten_print_textile/ten_print_textile.gd").new()
	source.cols=12;source.rows=12;source.weave_seed=1010;source.weaving=false;root.add_child(source);await settle()
	check("All initial samples and tint draws match source",same_cells(model.data,source))
	check("Strict decisions and glyph geometry match source",model.choices(model.data)==source.choices() and same_marks(study,source))
	var state:int=model.rng.state
	for i in 3: study.act("ALPHABET")
	check("Alphabet cycle consumes no draws and restores complete record",model.data==initial and model.rng.state==state)
	study.act("ODDS");var bits:Array=model.choices(model.data);var expected:=0;var changed:=0;var only_admits:=true
	for r in 12:
		for c in 12:
			var value:float=initial.rows[r][c].sample
			if value>=.5 and value<.75:expected+=1
			if bits[r][c]!=initial_bits[r][c]:changed+=1;only_admits=only_admits and bits[r][c] and not initial_bits[r][c]
	check("Odds changes only samples in half-open interval",changed==expected and changed>0 and only_admits and model.rng.state==state and samples(model.data)==samples(initial))
	var equality:Dictionary={"odds":.5,"rows":[[{"sample":.499},{"sample":.5},{"sample":.501}]]}
	check("A sample equal to threshold is B",model.choices(equality)==[[true,false,false]])
	study.act("HOLD");var witness:Dictionary=study.held.duplicate(true)
	study.act("ALPHABET");study.act("STEP");study.act("SEED");study.act("RESET")
	check("Held snapshot survives alphabet row seed and reset edits",study.held==witness and model.data==initial)
	var copy:Dictionary=model.keep();copy.rows[0][0].sample=-1
	check("Deep copy isolates nested cell writes",model.data==initial)
	study.act("STEP");var after:Dictionary=model.keep()
	check("One step drops oldest and preserves eleven whole rows",after.rows.slice(0,11)==initial.rows.slice(1,12) and after.rows.size()==12 and after.rows[-1].size()==12)
	source.step_row();check("New row and RNG call order agree with source",same_cells(after,source) and model.rng.state==source._rng.state)
	for i in 40: model.step();source.step_row();await process_frame
	check("Forty further rows retain bounded queue and source agreement",model.data.rows.size()==12 and source._bolt.get_child_count()==144 and same_cells(model.data,source))
	study.act("RESET");source.reset_cloth(1010)
	check("Reset reproduces every opening sample and tint",model.data==initial and same_cells(model.data,source))
	var all_match:=true;var comparisons:=0
	for seed_value in [1010,37]:
		model.new_sheet(seed_value);source.reset_cloth(seed_value)
		for alphabet in model.ALPHABETS:
			for odds in model.ODDS:
				model.data.alphabet=alphabet;model.data.odds=odds;study.refresh();source.reinterpret(alphabet,odds)
				all_match=all_match and same_cells(model.data,source) and model.choices(model.data)==source.choices() and same_marks(study,source)
				comparisons+=1;await process_frame
	check("Thirty source comparisons match samples choices and glyph geometry",all_match)
	study.act("RESET")
	var floor=study.drawing.get_child(2);var wall=study.drawing.get_child(0);var layout_ok:=true
	for r in 12:
		for c in 12:
			var i:=1+r*12+c;var mark:MeshInstance3D=floor.get_child(i);var on_wall:MeshInstance3D=wall.get_child(i)
			layout_ok=layout_ok and mark.mesh.size.is_equal_approx(on_wall.mesh.size) and mark.position.is_equal_approx(Vector3((c-5.5)*.2,0,(r-5.5)*.2)) and mark.material_override.albedo_color.is_equal_approx(on_wall.material_override.albedo_color)
	check("Floor reads same choices and tints at declared addresses",layout_ok)
	check("Drawn sheets and backing add no collision",study.drawing.find_children("*","CollisionObject3D",true,false).is_empty())
	var variant=load(DIR+"variation/assemblage.gd").new();host.add_child(variant);await settle()
	study.act("ALPHABET");study.act("ALPHABET");variant.act("ALPHABET");variant.act("ALPHABET")
	check("Full student variation keeps samples decisions and count",variant.model.data==model.data and variant.model.choices(variant.model.data)==model.choices(model.data) and count_a(variant.model.choices(variant.model.data))==initial_count)
	var exchanged:=true
	for i in range(1,145):
		var a:MeshInstance3D=study.drawing.get_child(0).get_child(i);var b:MeshInstance3D=variant.drawing.get_child(0).get_child(i)
		var bit:bool=initial_bits[(i-1)/12][(i-1)%12];var factor:=1.0/3 if bit else 3.0
		exchanged=exchanged and is_equal_approx(b.mesh.size.x,a.mesh.size.x*factor) and is_equal_approx(b.mesh.size.y,a.mesh.size.y*factor) and b.position==a.position and b.material_override.albedo_color==a.material_override.albedo_color
	check("Student variation swaps sizes without moving or recolouring cells",exchanged)
	variant.queue_free();await settle()
	var wrong=load(DIR+"wrong_alias/sheet.gd").new();var aliased:Dictionary=wrong.keep();var wanted:Dictionary=aliased.duplicate(true);wrong.step()
	check("Test rejects shallow snapshot fault",aliased!=wanted)
	var redraw=load(DIR+"wrong_redraw/assemblage.gd").new();host.add_child(redraw);await settle();var before:Dictionary=redraw.model.keep();redraw.act("ALPHABET")
	check("Test rejects redraw-on-alphabet fault",samples(redraw.model.data)!=samples(before));redraw.queue_free();await settle()
	study.act("RESET");key(study,KEY_A);key(study,KEY_O);key(study,KEY_H);key(study,KEY_SPACE);key(study,KEY_N);key(study,KEY_R)
	check("Six keyboard bindings execute and reset editing only",model.data==initial and study.held.alphabet=="orthogonals" and is_equal_approx(study.held.odds,.75))
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await settle();controller.global_position+=Vector3(.3,.2,0);await settle()
	check("Pickup and hand movement preserve complete editing record",study.point.is_picked_up() and model.data==initial)
	study.point.action();await settle()
	check("Held trigger changes only alphabet",model.data.alphabet=="orthogonals" and samples(model.data)==samples(initial) and model.choices(model.data)==initial_bits)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await settle()
	check("Release parks point on transformed host",study.point.position.is_equal_approx(Vector3(0,1.15,1.1)))
	FileAccess.open(DIR+"saved-opening.json",FileAccess.WRITE).store_string(JSON.stringify(initial,"  "))
	origin.queue_free();host.queue_free();source.queue_free();await settle()
	var result:Dictionary={"checks":checks,"failures":failures,"passed":failures.is_empty(),"source_comparisons":comparisons,"initial_A":initial_count,"scope":"Author-led exact printed code, complete student variation, two faulty implementations, source comparisons and supplied XRTools poses. No independent learner or headset claim."}
	FileAccess.open(DIR+"checks.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
