extends Node3D
## A transparent reading of the existing sponge, never a second solid generator.
## The point selects FIRST-level cells, even when their twenty children are shown.
const PointBody = preload("res://commons/artifacts/recursive_tree_lesson/fork_point.gd")
const FACTOR := 0.09
const CENTER := Vector3(0, 1.43, 0)
var desk: Node3D
var source: Node3D
var grip: XRToolsPickable
var miniature: Node3D
var ghosts: Node3D
var small_frame: Node3D
var large_frame: Node3D
var caption: Label3D
var selected := Vector3i(1, 1, 2)
var selected_index := 22
var kept := false
var cube_count := 1
var buttons: Dictionary = {}
var pale: StandardMaterial3D
var rose: StandardMaterial3D

func _ready() -> void:
	desk = get_parent(); source = desk.source
	position = Vector3(-1.35, 0, 2.0)
	pale = desk.material("e7e3dc"); pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pale.albedo_color.a = 0.32
	rose = desk.material("dd90ae", true)
	desk.box(Vector3(0, 0.475, 0), Vector3(1.0, 0.95, 1.1), desk.material("e7e3dc"), true, self)
	miniature = Node3D.new(); add_child(miniature)
	ghosts = Node3D.new(); add_child(ghosts)
	small_frame = cage(0.27, 0.006, self)
	large_frame = cage(3.0, 0.018, self)
	# Cancel the desk/reader transforms. This cage uses the source's local axes.
	large_frame.transform = (desk.transform * transform).affine_inverse()
	grip = PointBody.new(); grip.name = "CellPoint"; add_child(grip)
	grip.position = Vector3(0, 1.35, 0.56)
	grip.action_pressed.connect(func(_body): desk.act("NEXT"))
	for i in 3:
		var id: String = ["NEXT", "BACK", "RESET"][i]
		var button = desk.PUSH.instantiate(); button.position = Vector3((i-1)*0.30,0.97,0.42)
		add_child(button); buttons[id] = button; button.pressed.connect(desk.act.bind(id))
		var text = desk.label(id, Vector3.ZERO, 0.00050); text.reparent(self, false)
		text.position = button.position + Vector3(0,0.006,0.075); text.rotation_degrees.x = -70
	caption = desk.label("", Vector3.ZERO, 0.00095); caption.reparent(self, false)
	caption.position = Vector3(0,2.08,-0.12)
	desk.box(Vector3(0,2.08,-0.145),Vector3(1.18,0.31,0.025),desk.material("29262d"),false,self)
	var prompt = desk.label("HOLD THE POINT · FIND A CELL\nTrigger: next cut · same address at two scales",Vector3.ZERO,0.00065)
	prompt.reparent(self,false); prompt.position=Vector3(0,0.77,0.56)
	prompt.modulate=Color("29262d"); prompt.outline_size=0
	rebuild()

func cage(edge: float, width: float, host: Node3D) -> Node3D:
	var frame := Node3D.new(); host.add_child(frame)
	for a in [-0.5,0.5]:
		for b in [-0.5,0.5]:
			desk.box(Vector3(a*edge,b*edge,0),Vector3(width,width,edge),rose,false,frame)
			desk.box(Vector3(a*edge,0,b*edge),Vector3(width,edge,width),rose,false,frame)
			desk.box(Vector3(0,a*edge,b*edge),Vector3(edge,width,width),rose,false,frame)
	return frame

func clear(host: Node3D) -> void:
	for child in host.get_children(): host.remove_child(child); child.queue_free()

func model_position(source_position: Vector3) -> Vector3:
	# The model faces the same way as its parent desk; undo the desk's turn for data.
	return CENTER + desk.basis.inverse() * (source_position - Vector3.UP*4.5) * FACTOR

func rebuild() -> void:
	clear(miniature); clear(ghosts)
	for cube in source.find_all_cube_scenes():
		desk.box(model_position(source.to_local(cube.global_position)),cube.scale*FACTOR,pale,false,miniature)
	cube_count=miniature.get_child_count()
	var ghost_material = desk.material("dd90ae")
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; ghost_material.albedo_color.a=0.17
	for child in source.get_children():
		if child is MeshInstance3D and child.get_meta("menger_removed",false):
			desk.box(model_position(child.position),child.mesh.size*FACTOR,ghost_material,false,ghosts)
	set_ghosts(desk.show_removed)
	update_selection()

func set_ghosts(show_them: bool) -> void:
	ghosts.visible=show_them

func _physics_process(_dt: float) -> void:
	if grip.held():
		var p: Vector3 = desk.basis * ((to_local(grip.global_position)-CENTER)/FACTOR)
		selected = Vector3i(clampi(roundi(p.x/3.0)+1,0,2),clampi(roundi(p.y/3.0)+1,0,2),clampi(roundi(p.z/3.0)+1,0,2))
		update_selection()
	else:
		# Return the tool to the near edge; don't bury the released point in a cell.
		grip.global_transform = global_transform * Transform3D(Basis.IDENTITY,Vector3(0,1.35,0.56))

func update_selection() -> void:
	selected_index = selected.x + selected.y*3 + selected.z*9
	kept = selected_index in source.keep_positions
	var center := (Vector3(selected)-Vector3.ONE)*3.0 + Vector3.UP*4.5
	small_frame.position = model_position(center)
	large_frame.global_transform = source.global_transform * Transform3D(Basis.IDENTITY,center)
	var colour := Color("93c9d2") if kept else Color("ef8bab")
	rose.albedo_color=colour; rose.emission=colour
	caption.text = "CELL (%d, %d, %d) · %s\nFIRST CUT: 20 KEEP / 7 REMOVE\nNOW %d CUBES · cut %d / 2" % [selected.x,selected.y,selected.z,"KEEP" if kept else "REMOVE",cube_count,source.current_iteration]
