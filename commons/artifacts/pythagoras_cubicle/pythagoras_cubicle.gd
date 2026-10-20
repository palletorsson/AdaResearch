extends Node3D
## Three walls made of paired square proofs, around the original 7 × 7 footprint.
## Each wall is seven metres wide: two 3.5 m square diagrams. No roof/front wall.
const ProofScene = preload("res://commons/artifacts/pythagoras_floor/pythagoras_floor.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const Stock = preload("res://commons/artifacts/construction_triangle_brace/construction_triangle_brace.gd")
const WIDTH := 7.0
var proofs: Array[Node3D] = []
var walls: Array[StaticBody3D] = []
var buttons: Dictionary = {}
var status: Label3D
var swapped := false

func _ready() -> void:
	make_wall("BackProof", Vector3.ZERO, 0, 3.0, 4.0)
	make_wall("LeftProof", Vector3(0,0,WIDTH), PI/2, 2.0, 5.0)
	make_wall("RightProof", Vector3(WIDTH,0,0), -PI/2, 1.0, 6.0)
	make_controls()

func make_wall(title: String, at: Vector3, angle: float, a: float, b: float) -> void:
	var wall := StaticBody3D.new()
	wall.name=title;wall.position=at;wall.rotation.y=angle
	wall.collision_layer=1;wall.collision_mask=0;add_child(wall);walls.append(wall)
	var dark := Stock.material(Color("35323b"), .35)
	var backing := Stock.material(Color("e6ded4"))
	# Backing and collider remain behind the mathematical plane, facing inward.
	Stock.box(wall,Vector3(WIDTH/2,1.95,-.06),Vector3(WIDTH,3.9,.12),backing)
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new()
	shape.size=Vector3(WIDTH,3.9,.12);collision.shape=shape
	collision.position=Vector3(WIDTH/2,1.95,-.06);wall.add_child(collision)
	for x in [0.0,3.5,7.0]:
		Stock.box(wall,Vector3(x,1.95,-.005),Vector3(.045,3.9,.05),dark)
	for y in [0.0,3.5,3.9]:
		Stock.box(wall,Vector3(WIDTH/2,y,-.005),Vector3(WIDTH,.045,.05),dark)
	for i in range(2):
		var proof: Node3D=ProofScene.instantiate()
		proof.name="LegSquares" if i==1 else "HypotenuseSquare"
		proof.diagram_only=true;proof.a=a;proof.b=b;proof.split=i==1
		# Floor +Y normal turns toward the viewer (+Z); text becomes upright.
		proof.position=Vector3(i*3.5,3.5,.025)
		proof.rotation.x=PI/2;proof.scale=Vector3.ONE*.5
		wall.add_child(proof);proofs.append(proof)
	label(wall,"%.0f : %.0f     /     SAME FOUR TRIANGLES     /     a² + b² = c²"%[a,b],Vector3(3.5,3.7,.035),.0024)

func make_controls() -> void:
	var host := StaticBody3D.new();host.name="Controls"
	host.position=Vector3(-.9,0,7.3);host.collision_layer=1;host.collision_mask=0;add_child(host)
	var dark := Stock.material(Color("35323b"),.3)
	Stock.box(host,Vector3(0,.5,0),Vector3(.18,1,.18),dark)
	Stock.box(host,Vector3(0,.035,0),Vector3(.5,.07,.5),dark)
	Stock.box(host,Vector3(0,1.15,0),Vector3(.95,.4,.07),dark)
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new()
	shape.size=Vector3(.5,1,.5);collision.shape=shape;collision.position.y=.5;host.add_child(collision)
	status=label(host,"SAME AREA / THREE PROPORTIONS",Vector3(0,1.29,.045),.0008)
	var actions := [swap,reset]
	for i in range(2):
		var button: Node3D=ButtonScene.instantiate()
		button.name=["SwapButton","ResetButton"][i];button.position=Vector3(-.22+i*.44,1.13,.045)
		button.rotation.x=PI/2;button.released_color=Color("dc9bb5")
		button.pressed.connect(actions[i]);host.add_child(button)
		buttons[["swap","reset"][i]]=button
		label(host,["SWAP ARRANGEMENTS","RESET"][i],Vector3(-.22+i*.44,1.02,.045),.0007)

func swap() -> void:
	for proof in proofs:
		if proof.moving: return
	swapped=not swapped
	status.text="MOVING THE SAME TRIANGLES"
	for proof in proofs: proof.rearrange()
	proofs[0].motion.finished.connect(settle, CONNECT_ONE_SHOT)

func settle() -> void:
	status.text="SAME AREA / THREE PROPORTIONS"
	buttons.swap.set_selected(swapped)

func reset() -> void:
	for i in range(proofs.size()):
		var proof: Node3D=proofs[i]
		if is_instance_valid(proof.motion): proof.motion.kill()
		proof.moving=false;proof.set_arrangement(i%2==1,false)
	swapped=false;settle()

func label(parent: Node3D, text: String, at: Vector3, pixels: float) -> Label3D:
	var node := Label3D.new();node.text=text;node.position=at
	node.font_size=32;node.pixel_size=pixels;node.outline_size=0
	node.modulate=Color("302735") if parent!=get_node_or_null("Controls") else Color("efe7de")
	parent.add_child(node);return node
