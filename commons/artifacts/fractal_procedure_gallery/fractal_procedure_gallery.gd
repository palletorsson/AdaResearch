extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Room-local staging. Original algorithms and their standalone modes are untouched.
## Ten existing works remain; rear examples are explicitly held for comparison.
var staged := false
var elapsed := 0.0
var hall: Node3D
var held: Dictionary = {}
var recipe_table: Node3D

func _ready() -> void:
	box(Vector3(0,0.45,0),Vector3(1.3,0.9,0.32),material("263a44"),true)
	var card := label("WHAT WOULD YOU TELL\nTHE NEXT CALL?\n\ninput / descendants / stop\nthen: what did the display add?",Vector3(0,1.38,0.03),0.00115)
	card.font_size=30
	hall=get_parent()
	while hall!=null and not hall.has_meta("em_map"):hall=hall.get_parent()
	if hall==null or str(hall.get_meta("em_map"))!="Fractal_Synthesis":set_process(false)

func _process(delta: float) -> void:
	if staged:return
	elapsed+=delta
	var fib: Node3D
	var sierp: Node3D
	var clouds: Node3D
	for node in hall.find_children("*","Node3D",true,false):
		var script=node.get_script()
		if script==null:continue
		match str(script.resource_path):
			"res://algorithms/fractals/fibonacci_sequences/FibonacciSequences.gd":fib=node
			"res://algorithms/fractals/sierpinskitriangle/sierpinski_triangle.gd":sierp=node
			"res://algorithms/fractals/fractal_clouds/fractal_clouds.gd":clouds=node
	if fib==null or sierp==null or clouds==null:
		if elapsed>15:push_error("Procedure gallery could not locate its retained specimens");set_process(false)
		return
	# Build each original Fibonacci view once at time zero. Stop only its local
	# process callback, not the museum clock or another artifact's simulation.
	fib.set_process(false)
	fib.time=0.0
	for name_ in ["NumberSequence","GoldenSpiral","NaturalPatterns","RecursionVisualization"]:
		var host=fib.get_node(name_)
		for child in host.get_children():host.remove_child(child);child.queue_free()
	fib.visualize_number_sequence();fib.create_golden_spiral();fib.show_natural_patterns();fib.demonstrate_recursion()
	fib.get_node("RecursionVisualization").position.y+=6.5
	# A held finite gasket supplies a readable secondary specimen rather than
	# hundreds of coincident moving physics bodies in this comparison gallery.
	sierp.auto_start=false
	sierp.is_subdividing=false
	sierp.reset()
	sierp.is_subdividing=false
	for i in range(3):sierp.step()
	for body in sierp.find_children("*","RigidBody3D",true,false):body.freeze=true
	clouds.animate=false
	held={"fibonacci":fib,"gasket":sierp,"cloud":clouds}
	for layer in hall.find_children("*","CanvasLayer",true,false):layer.hide()
	for lamp in hall.find_children("*","DirectionalLight3D",true,false):lamp.hide()
	var lights:=Node3D.new();lights.name="ProcedureGalleryLights";hall.add_child(lights)
	for at in [Vector3(5.5,4.4,9),Vector3(13.5,4.4,9),Vector3(9.5,4.4,21),Vector3(9.5,4.4,31)]:
		var light:=OmniLight3D.new();light.position=at;light.light_energy=2.1;light.omni_range=12;light.light_color=Color("f3e6d6");lights.add_child(light)
	var tag:=label("HELD EXAMPLES\nCompare rules, not complexity scores",Vector3.ZERO,0.002)
	tag.reparent(hall,false);tag.position=Vector3(9.5,1.7,17);tag.rotation.y=PI
	staged=true
	recipe_table=load("res://commons/artifacts/fractal_recipe_table/museum_recipe_table.gd").new()
	recipe_table.fixture=self;recipe_table.name="RecipeTable"
	recipe_table.position=Vector3(9.5,0,8.5);recipe_table.rotation.y=PI
	hall.add_child(recipe_table)
	set_process(false)
