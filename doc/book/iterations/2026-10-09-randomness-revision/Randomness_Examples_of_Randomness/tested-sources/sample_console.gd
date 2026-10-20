extends "res://commons/artifacts/camera_glitch_study/glitch_console.gd"
## The image instrument's physical control vocabulary; a distinct sampling lesson.
const BUDGETS := [100,500,2000,8000]
var host: Node3D
var comparison: Label3D
var comparison_rows: Array[Dictionary] = []

func _ready() -> void:
	name="SampleBudgetConsole"
	box(self,Vector3(0,.025,0),Vector3(.88,.05,.48),INK,true)
	for x in [-.4,.4]:box(self,Vector3(x,.46,-.05),Vector3(.035,.87,.20),INK,true)
	face=Node3D.new();face.position.y=.96;face.rotation_degrees.x=-55;add_child(face)
	box(face,Vector3.ZERO,Vector3(1.16,.68,.058),INK,true)
	box(face,Vector3(0,0,.032),Vector3(1.13,.65,.012),PAPER)
	text(face,"MONTE CARLO / KEEP THE RUN",Vector3(0,.285,.042),.00052,INK)
	box(face,Vector3(-.28,.14,.042),Vector3(.49,.17,.006),INK)
	screen_title=text(face,"",Vector3(-.28,.16,.049),.00055,PAPER)
	screen_state=text(face,"",Vector3(-.28,.08,.049),.00035,Color("a2c6b9"))
	effect_dial=dial("BUDGET",Vector3(-.30,-.09,.045),1,4,0)
	var hinge=effect_dial.get_node("DialOrigin/InteractableHinge")
	hinge.hinge_limit_min=0.0;hinge.hinge_limit_max=270.0;hinge.hinge_steps=90.0
	for child in effect_dial.get_children():
		if child is MeshInstance3D:child.queue_free()
	for i in 4:
		var angle:=deg_to_rad(i*90.0)
		var mark:=box(effect_dial,Vector3(cos(angle)*.055,sin(angle)*.055,.008),Vector3(.002,.008,.002),INK)
		mark.rotation.z=angle-PI*.5
	# Numeric label shows the actual selected sample budget, not the dial index.
	text(face,"100 / 500 / 2000 / 8000",Vector3(-.3,-.25,.044),.00033,INK)
	button("THROW",Vector2(.115,.12),.20);button("+100",Vector2(.365,.12),.20)
	button("FILL",Vector2(.115,-.01),.20);button("REPLAY",Vector2(.365,-.01),.20)
	button("NEXT SEED",Vector2(.115,-.14),.20);button("8 SEEDS",Vector2(.365,-.14),.20)
	text(face,"GENERATED SAMPLES / NO HAND AIM",Vector3(.24,-.25,.044),.00029,INK)
	for id in buttons:
		buttons[id].get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(id))
	hinge.hinge_moved.connect(func(_angle):
		var index:=roundi(effect_dial.get_normalized_value()*3)
		if host.max_darts!=BUDGETS[index]:
			host.max_darts=BUDGETS[index];host.budget_replay();comparison_rows.clear();refresh())
	# A small reading beside the existing board, facing the same visitor.
	box(host,Vector3(1.03,1.18,.035),Vector3(.91,.72,.04),INK)
	comparison=text(host,"",Vector3(1.03,1.18,.062),.00068,PAPER)
	comparison.font_size=32
	refresh()

func act(id: String) -> void:
	match id:
		"THROW":host.budget_add(1)
		"+100":host.budget_add(100)
		"FILL":host.budget_add(host.max_darts)
		"REPLAY":host.budget_replay()
		"NEXT SEED":host.dart_seed+=1;host.budget_replay()
		"8 SEEDS":comparison_rows=host.sample_run.compare_seeds(host.dart_seed,host.max_darts)
	if id!="8 SEEDS":comparison_rows.clear()
	refresh()

func refresh() -> void:
	if not is_instance_valid(screen_title):return
	var n:int=host.sample_run.points.size()
	var estimate:String="--" if n==0 else "%.6f"%host.sample_run.estimate()
	screen_title.text="SEED %d   /   %d of %d\nPI ~ %s"%[host.dart_seed,n,host.max_darts,estimate]
	screen_state.text="ALL %d COUNTED / NEWEST %d SHOWN"%[n,mini(n,300)]
	var index:int=BUDGETS.find(host.max_darts)
	effect_dial.set_normalized_value(float(maxi(index,0))/3.0)
	effect_dial.get_node("Frame/Label3DValue").text=str(host.max_darts)
	var lines:PackedStringArray=[]
	if comparison_rows.is_empty():
		lines.append("ONE RUN / ONE PREFIX")
		lines.append("BUDGET starts the same seed again.")
		lines.append("FILL reaches that many samples.")
		lines.append("REPLAY clears and rewinds the seed.")
		lines.append("8 SEEDS keeps this board untouched.")
		lines.append("")
		lines.append("More samples can still increase error.")
	else:
		lines.append("8 SEEDS / %d SAMPLES EACH"%host.max_darts)
		lines.append("seed       estimate        signed error")
		var absolute_error:=0.0
		for row in comparison_rows:
			lines.append("%d       %.5f       %+.5f"%[row.seed,row.estimate,row.error])
			absolute_error+=absf(row.error)
		lines.append("mean absolute error: %.5f"%(absolute_error/8))
		lines.append("This fixture; no monotonic guarantee.")
	comparison.text="\n".join(lines)
