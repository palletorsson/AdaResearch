extends SceneTree
const Structure=preload("res://open_structure.gd")
var checks: Array=[]
var views: Array=[]
var study: Node3D
var out := "res://captures/"

func _initialize() -> void:run.call_deferred()
func check(label: String,passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	print("PASS " if passed else "FAIL ",label)

func shot(id: String) -> void:
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	var picture:=root.get_texture().get_image()
	picture.save_png(out+id+".png")
	views.append({"id":id,"eye":str(study.camera.global_position),"fov":study.camera.fov,"mode":study.structures.mode,"alternative":study.structures.alternative,"edges":study.structures.total_edges,"records":study.structures.records.size()})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1600,1000)
	study=load("res://study.tscn").instantiate();root.add_child(study)
	await process_frame
	study.panel.visible=false
	var rules: Node3D=study.structures
	for i in 5:
		var points: Array[Vector3]=rules.shape(i)
		var lines:=Structure.segments(points)
		check("nonzero edges in "+rules.NAMES[i],lines.size()==(8 if i==1 else 12))
		var unique: Dictionary={}
		for p in points:unique[str(p)]=true
		check("distinct positions in "+rules.NAMES[i],unique.size()==(5 if i==1 else 8))
		var finite:=true
		for edge in lines:
			var t:=Structure.bar_transform(edge[0],edge[1])
			finite=finite and t.origin.is_finite() and t.basis.is_finite()
		check("finite bar transforms in "+rules.NAMES[i],finite)
	check("pyramid base stays fixed",rules.shape(1).slice(0,4)==rules.shape(0).slice(0,4))
	check("taper base stays fixed",rules.shape(3).slice(0,4)==rules.shape(0).slice(0,4))
	check("shear base stays fixed",rules.shape(4).slice(0,4)==rules.shape(0).slice(0,4))
	await shot("five-forms")
	rules.set_reveal(.18);await shot("first-connections");rules.set_reveal(1)
	study.select_mode(1)
	check("grid has 25 sites",rules.records.size()==25)
	var row_complete:=true
	for row in 5:
		var forms: Dictionary={}
		for column in 5:forms[rules.form_at(column,row)]=true
		row_complete=row_complete and forms.size()==5
	check("cyclic rows each contain all five forms",row_complete)
	var addresses: Array=[]
	for r in rules.records:addresses.append(r.origin)
	await shot("cyclic-array")
	study.change_rule()
	var same_addresses:=true
	for i in rules.records.size():same_addresses=same_addresses and addresses[i]==rules.records[i].origin
	check("changing selection rule preserves addresses",same_addresses)
	check("row 1 col 0 changes form",rules.form_at(0,1)==0)
	await shot("repeated-array")
	rules.alternative=false;study.select_mode(2)
	check("five crosses each occupy nine addresses",rules.records.size()==45)
	var heights_valid:=true
	for r in rules.records:heights_valid=heights_valid and r.height>=1 and r.height<=5
	check("all selected heights fit the bound",heights_valid)
	var cross_edges: int=rules.total_edges
	await shot("five-height-rules")
	study.change_rule()
	check("filled footprint keeps five arrays of 25 addresses",rules.records.size()==125)
	check("expanded footprint adds structure",rules.total_edges>cross_edges)
	await shot("expanded-footprint")
	study.select_mode(3)
	check("continuum supplies seven sampled forms",rules.records.size()==7)
	await shot("between-forms")
	study.panel.visible=true;study.select_mode(0);await shot("controls")
	var passed:=true
	for c in checks:passed=passed and c.passed
	FileAccess.open(out+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"views":views,"engine":Engine.get_version_info(),"scope":"Standalone native Godot study; supplied controls and camera; no museum placement, human learner or physical headset trial."},"  "))
	quit(0 if passed else 1)
