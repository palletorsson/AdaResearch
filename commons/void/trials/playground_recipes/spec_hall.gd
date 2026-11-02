extends "res://commons/void/trials/principal_places/places.gd"
## A PLAYGROUND SPEC AS A WALKABLE HALL (Palle, 2026-11-02: "make a new map with the artifacts that do not fit on the
## floor - I can not walk to these and inspect them"; and "test this inside their maps, then later move to the
## skyscraper"). Compiles a place spec - places, their activities, framed boards (place_spec.gd, board_builder.gd) -
## through the place builder when it loads, and builds it like the principal-places hall. The spec is `spec_path`,
## or the floor token's config "spec" (floor_content sets config_* metas before the hall is built). A trial per
## spec is written by tools/playground_trial.py, which sizes the trial's slab to hold everything in the spec.
const SpecBuilder=preload("res://commons/modular/places/place_builder.gd")
@export_file("*.json") var spec_path:=""
var spec_errors:Array=[]

func _ready()->void:
	if has_meta("config_spec"):spec_path=str(get_meta("config_spec"))
	if recipe.is_empty() and spec_path!="":
		var spec:Variant=JSON.parse_string(FileAccess.get_file_as_string(spec_path))
		if spec is Dictionary:
			var built:Dictionary=SpecBuilder.new().compile(spec);spec_errors=built.get("errors",[])
			if spec_errors.is_empty():recipe=built.recipe
		else:spec_errors=["not a JSON object: "+spec_path]
	if recipe.is_empty():
		push_error("spec hall: no recipe from '%s': %s"%[spec_path,str(spec_errors)])
		var label:=Label3D.new();label.text="SPEC REFUSED\n"+spec_path+"\n"+"\n".join(PackedStringArray(spec_errors.slice(0,6)));label.position=Vector3(0,2,0);label.font_size=40;label.pixel_size=.005;add_child(label)
		return
	super._ready()
