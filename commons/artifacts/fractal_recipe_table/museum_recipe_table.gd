extends "res://commons/artifacts/fractal_recipe_table/recipe.gd"
## Furniture and nearby buttons around the exact printed lesson.
var fixture: Node3D
var buttons: Dictionary = {}

func _ready() -> void:
	super._ready()
	fixture.box(Vector3(0,0.47,0),Vector3(2.65,0.94,1.3),fixture.material("e7e3dc"),true,self)
	fixture.box(Vector3(0,1.65,-0.06),Vector3(2.65,1.02,0.025),fixture.material("b6b1a9"),false,self)
	for i in 4:
		var id: String = ["NEXT","KEEP","RESTORE","RESET"][i]
		var button = fixture.PUSH.instantiate()
		button.position = Vector3((i-1.5)*0.34,0.965,0.27)
		add_child(button);buttons[id]=button
		button.pressed.connect(act.bind(id))
		var tag = label(id,button.position+Vector3(0,0.01,0.085))
		tag.pixel_size=0.0012;tag.rotation_degrees.x=-70;tag.modulate=Color("28252c");tag.outline_size=0
	var prompt=label("MOVE THE POINT: KEEP 1/4, 1/3 OR 2/5\nTrigger: keep this recipe / RESET changes LIVE only",Vector3(0,0.71,0.662))
	prompt.modulate=Color("28252c");prompt.outline_size=0;prompt.pixel_size=0.0012
	var grammar=label("THIRDS → F → FfF, f → fff\nThe next hall reads a written rule",Vector3(0,0.38,0.665))
	grammar.modulate=Color("28252c");grammar.outline_size=0;grammar.pixel_size=0.0012

func _process(_dt: float) -> void:
	pass # Only the separate student workspace responds to global Enter.

func act(id: String) -> void:
	match id:
		"NEXT":advance()
		"KEEP":keep_current()
		"RESTORE":restore()
		"RESET":reset_live()
