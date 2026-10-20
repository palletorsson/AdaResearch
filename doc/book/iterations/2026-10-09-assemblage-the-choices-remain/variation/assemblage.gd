extends Node3D
const Sheet = preload("sheet.gd")
const PointBody = preload("point_body.gd")
var model = Sheet.new()
var held: Dictionary={}
var drawing: Node3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	drawing=Node3D.new(); add_child(drawing)
	label=Label3D.new(); label.position=Vector3(0,2.6,0.05)
	label.font_size=28; label.pixel_size=.0018; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,1.1); add_child(point)
	point.action_pressed.connect(func(_body): act("ALPHABET"))
	held=model.keep(); refresh()

func act(action: String) -> void:
	match action:
		"ALPHABET":
			var i: int=Sheet.ALPHABETS.find(model.data.alphabet)
			model.data.alphabet=Sheet.ALPHABETS[(i+1)%Sheet.ALPHABETS.size()]
		"ODDS":
			var i: int=Sheet.ODDS.find(model.data.odds)
			model.data.odds=Sheet.ODDS[(i+1)%Sheet.ODDS.size()]
		"HOLD": held=model.keep()
		"STEP": model.step()
		"SEED": model.new_sheet(int(model.data.seed)+1)
		"RESET": model.reset()
	refresh()

func refresh() -> void:
	for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
	draw_sheet(model.data,Vector3(-.85,1.8,0),false)
	draw_sheet(held,Vector3(.85,1.8,0),false)
	draw_sheet(model.data,Vector3(0,.035,-4),true)
	var count:=0
	for row in Sheet.choices(model.data):
		for a in row: if a: count+=1
	label.text="EDITING / %s / p %.2f / %d of 144 A\nHELD / %s / p %.2f\nA or held trigger: alphabet   O: odds   H: hold\nSpace: row   N: seed   R: reset" % [model.data.alphabet,model.data.odds,count,held.alphabet,held.odds]

func draw_sheet(record: Dictionary, at: Vector3, on_floor: bool) -> void:
	var panel:=Node3D.new(); panel.position=at; drawing.add_child(panel)
	var backing:=MeshInstance3D.new(); var board:=BoxMesh.new()
	board.size=Vector3(2.6,.012,2.6) if on_floor else Vector3(1.55,1.4,.04)
	backing.mesh=board
	backing.position=Vector3(0,-.02,0) if on_floor else Vector3(0,0,-.05)
	var dark:=StandardMaterial3D.new(); dark.albedo_color=Color("152a32")
	backing.material_override=dark; panel.add_child(backing)
	var bits: Array=Sheet.choices(record)
	for r in Sheet.N:
		for c in Sheet.N:
			var a: bool=bits[r][c]
			var shape: Dictionary=Sheet.glyph(a,record.alphabet)
			var mesh:=BoxMesh.new(); mesh.size=shape.size
			var mark:=MeshInstance3D.new(); mark.mesh=mesh
			var hue: float=(.07 if a else .58)+float(record.rows[r][c].tint)*.05
			var finish:=StandardMaterial3D.new(); finish.albedo_color=Color.from_hsv(hue,.6,.95)
			finish.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mark.material_override=finish; panel.add_child(mark)
			if on_floor:
				mark.position=Vector3((c-5.5)*.2,0,(r-5.5)*.2)
				mark.basis=Basis(Vector3.RIGHT,-PI/2)*Basis(Vector3.BACK,shape.angle)
				mark.scale=Vector3(2.4,2.4,.5)
			else:
				mark.position=Vector3((c-5.5)/Sheet.N,(r-5.5)*.07,0)*1.4
				mark.rotation.z=shape.angle; mark.scale=Vector3.ONE*1.4

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var actions: Dictionary={KEY_A:"ALPHABET",KEY_O:"ODDS",KEY_H:"HOLD",KEY_SPACE:"STEP",KEY_N:"SEED",KEY_R:"RESET"}
	if actions.has(event.keycode): act(actions[event.keycode])

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,1.1))
