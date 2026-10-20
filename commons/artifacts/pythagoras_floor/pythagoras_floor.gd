extends Node3D
## Rearrangement proof: the same four congruent right triangles in the same
## (a+b)-square leave c², or a²+b². Only translations change between layouts.
## Panels are floor inlays; the tower slab supplies walking collision.
signal arrangement_changed(split: bool)
const Stock = preload("res://commons/artifacts/construction_triangle_brace/construction_triangle_brace.gd")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const FRAME := 7.0
## Used by the upright proof walls. Coordinates become diagram units when scaled.
@export var diagram_only := false
var a := 3.0
var b := 4.0
var split := false
var moving := false
var pieces: Array[Node3D] = []
var regions: Array[Node3D] = []
var geometry: Node3D
var console: Node3D
var status: Label3D
var equation: Label3D
var buttons: Dictionary = {}
var motion: Tween
var dark: StandardMaterial3D
var panel: StandardMaterial3D
var pink: StandardMaterial3D
var purple: StandardMaterial3D

func _ready() -> void:
	dark=Stock.material(Color("292c32"),.5)
	panel=Stock.material(Color("d5c6a9"))
	pink=Stock.material(Color("dc9bb5"))
	purple=Stock.material(Color("aea2ce"))
	for edge in [[Vector2.ZERO,Vector2(FRAME,0)],[Vector2(FRAME,0),Vector2(FRAME,FRAME)],
		[Vector2(FRAME,FRAME),Vector2(0,FRAME)],[Vector2(0,FRAME),Vector2.ZERO]]:
		line(self,edge[0],edge[1],.07,.045,dark)
	if not diagram_only:
		equation=label(self,"",Vector3(FRAME/2,.015,FRAME+.48),.004,true)
		label(self,"PYTHAGORAS / SAME FRAME, SAME FOUR TRIANGLES",Vector3(FRAME/2,.016,-.32),.0023,true)
		make_console()
	rebuild()

func poses(separated: bool) -> Array[Vector2]:
	if separated: return [Vector2(0,a),Vector2(FRAME,0),Vector2(a,FRAME),Vector2(a,a)]
	return [Vector2.ZERO,Vector2(FRAME,0),Vector2(FRAME,FRAME),Vector2(0,FRAME)]

func outline(index: int, separated: bool) -> PackedVector2Array:
	var at: Vector2=poses(separated)[index]
	var angle := index*PI/2
	return PackedVector2Array([at,at+Vector2(a,0).rotated(angle),at+Vector2(0,b).rotated(angle)])

func remainder(separated: bool) -> Array[PackedVector2Array]:
	if separated:
		return [PackedVector2Array([Vector2.ZERO,Vector2(a,0),Vector2(a,a),Vector2(0,a)]),
			PackedVector2Array([Vector2(a,a),Vector2(FRAME,a),Vector2(FRAME,FRAME),Vector2(a,FRAME)])]
	return [PackedVector2Array([Vector2(a,0),Vector2(FRAME,a),Vector2(b,FRAME),Vector2(0,b)])]

func rebuild() -> void:
	if is_instance_valid(motion): motion.kill()
	moving=false
	if is_instance_valid(geometry): geometry.free()
	pieces.clear();regions.clear()
	geometry=Node3D.new();geometry.name="ProofGeometry";add_child(geometry)
	for index in range(4):
		var piece := Node3D.new();piece.name="Triangle"+str(index+1);geometry.add_child(piece)
		var points := PackedVector2Array([Vector2.ZERO,Vector2(a,0),Vector2(0,b)])
		face(piece,points,panel,.042)
		for i in range(3): line(piece,points[i],points[(i+1)%3],.04,.055,dark)
		# The right-angle mark belongs to every unchanged panel.
		line(piece,Vector2(.26,0),Vector2(.26,.26),.025,.06,dark)
		line(piece,Vector2(.26,.26),Vector2(0,.26),.025,.06,dark)
		label(piece,str(index+1),Vector3(a/3,.065,b/3),.004,true)
		if index==0:
			var unit := "" if diagram_only else " m"
			label(piece,("a = %.0f"%a)+unit,Vector3(a/2,.065,.18),.0024,true)
			label(piece,("b = %.0f"%b)+unit,Vector3(.34,.065,b/2),.0024,true)
			label(piece,("c = %.2f"%sqrt(a*a+b*b))+unit,Vector3(a*.48,.065,b*.45),.0024,true)
		piece.rotation.y=-index*PI/2
		pieces.append(piece)
	for separated in [false,true]:
		var area := Node3D.new();area.name="LegSquares" if separated else "HypotenuseSquare"
		geometry.add_child(area);regions.append(area)
		var polygons := remainder(separated)
		for i in range(polygons.size()):
			face(area,polygons[i],pink if i==0 else purple,.018)
			var centre := Vector2.ZERO
			for point in polygons[i]: centre+=point
			centre/=polygons[i].size()
			var text := "c² = %.0f"%(a*a+b*b)
			if separated: text=("a² = %.0f"%(a*a)) if i==0 else ("b² = %.0f"%(b*b))
			if not diagram_only: text+=" m²"
			label(area,text,Vector3(centre.x,.024,centre.y),.004,true)
	set_arrangement(split,false)

func set_arrangement(separated: bool, animate := true) -> void:
	if moving: return
	split=separated
	var targets := poses(split)
	if animate:
		moving=true
		for region in regions: region.hide()
		if status != null: status.text="Moving the SAME four panels.\nCompare the settled layouts."
		motion=create_tween().set_parallel(true)
		for i in range(4):
			motion.tween_property(pieces[i],"position",Vector3(targets[i].x,0,targets[i].y),2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		motion.finished.connect(settle)
	else:
		for i in range(4): pieces[i].position=Vector3(targets[i].x,0,targets[i].y)
		settle()

func settle() -> void:
	moving=false
	regions[0].visible=not split;regions[1].visible=split
	if status != null: status.text="SAME 7 × 7 FRAME / SAME FOUR TRIANGLES\n"+("Uncovered: a² and b²" if split else "Uncovered: c²")
	if equation != null: equation.text="a² + b² = c²     /     %.0f + %.0f = %.0f m²"%[a*a,b*b,a*a+b*b]
	if buttons.has("rearrange"): buttons.rearrange.set_selected(split)
	arrangement_changed.emit(split)

func rearrange() -> void:
	set_arrangement(not split)

func change_triangle() -> void:
	if moving: return
	a=2.0 if is_equal_approx(a,3.0) else 3.0;b=FRAME-a;split=false;rebuild()

func reset() -> void:
	if is_instance_valid(motion): motion.kill()
	a=3.0;b=4.0;split=false;rebuild()

func make_console() -> void:
	console=Node3D.new();console.name="Controls";console.position=Vector3(-.9,1.1,7.3)
	console.rotation_degrees.x=-35;add_child(console)
	Stock.box(console,Vector3.ZERO,Vector3(1.40,.56,.065),Stock.material(Color("ddd9ce")))
	status=label(console,"",Vector3(0,.17,.04),.0010,false)
	var actions := [rearrange,change_triangle,reset]
	var names := ["rearrange","proportions","reset"]
	var captions := ["REARRANGE","OTHER TRIANGLE","RESET 3 / 4 / 5"]
	for i in range(3):
		var button: Node3D=ButtonScene.instantiate()
		button.name=names[i].capitalize()+"Button";button.position=Vector3((i-1)*.45,-.025,.075)
		button.released_color=Color("d87caa");button.pressed.connect(actions[i]);console.add_child(button)
		buttons[names[i]]=button
		label(console,captions[i],Vector3((i-1)*.45,-.15,.04),.0008,false)
	# Fixed support, with an ordinary floor collider; controls stay reachable.
	var stand := StaticBody3D.new();stand.name="ControlStand";stand.position=Vector3(-.9,.44,7.3)
	stand.collision_layer=1;stand.collision_mask=0;add_child(stand)
	Stock.box(stand,Vector3.ZERO,Vector3(.45,.88,.45),dark)
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=Vector3(.45,.88,.45)
	collision.shape=shape;stand.add_child(collision)

func label(parent: Node3D, text: String, at: Vector3, pixels: float, flat: bool) -> Label3D:
	var node := Label3D.new();node.text=text;node.position=at;node.font_size=32;node.pixel_size=pixels
	node.outline_size=0;node.modulate=Color("25262a")
	if flat: node.rotation.x=-PI/2
	parent.add_child(node);return node

func face(parent: Node3D, points: PackedVector2Array, mat: Material, y: float) -> void:
	var triangles := Geometry2D.triangulate_polygon(points)
	var mesh := SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0,triangles.size(),3):
		# Godot's front face is clockwise when viewed from above in XZ.
		for corner in [0,1,2]:
			var point := points[triangles[index+corner]]
			mesh.set_normal(Vector3.UP);mesh.add_vertex(Vector3(point.x,y,point.y))
	var node := MeshInstance3D.new();node.mesh=mesh.commit();node.material_override=mat;parent.add_child(node)

func line(parent: Node3D, from: Vector2, to: Vector2, width: float, height: float, mat: Material) -> void:
	var a3:=Vector3(from.x,height/2,from.y);var b3:=Vector3(to.x,height/2,to.y)
	var bar:=Stock.box(parent,(a3+b3)/2,Vector3(width,height,a3.distance_to(b3)),mat)
	bar.rotation.y=-atan2(to.y-from.y,to.x-from.x)+PI/2
