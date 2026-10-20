extends Node3D
## One unchanged colour question; only the inventory changes between trays.
const Objects=preload("objects.gd")
const Model=preload("model.gd")
var pink_count:=8
var visuals: Node3D

func _ready() -> void:rebuild()

func probabilities() -> Array:
	return [pink_count/16.0,(16-pink_count)/16.0]

func rebuild() -> void:
	if is_instance_valid(visuals):remove_child(visuals);visuals.free()
	visuals=Node3D.new();add_child(visuals)
	Objects.table(visuals,2.8,2.2)
	for i in 16:
		var p:=Vector3((i%4-1.5)*0.6,0.94,(i/4-1.5)*0.48)
		var ball:=Objects.sphere(visuals,p,0.18,Objects.PINK if i<pink_count else Objects.TEAL)
		ball.name="Ball"+str(i);ball.set_meta("pink",i<pink_count)
	var best: int=maxi(pink_count,16-pink_count)
	var guess: String="PINK or TEAL" if pink_count==8 else ("PINK" if pink_count>8 else "TEAL")
	Objects.box(visuals,Vector3(0,0.59,1.10),Vector3(2.8,0.3,0.04),Color("ece7dc"))
	Objects.ink(visuals,"Best guess: %s\n%d of 16 chances win" % [guess,best],Vector3(0,0.60,1.127),29,0.0021)

func capture() -> Dictionary:
	return {"schema":"colour-best-guess/1","pink":pink_count,"total":16,"draw":"uniform-ball-with-replacement","record":"colour"}

func restore(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema")!="colour-best-guess/1" or record.get("total")!=16:return false
	if record.get("draw")!="uniform-ball-with-replacement" or record.get("record")!="colour":return false
	var count: Variant=record.get("pink")
	if not (count is int or count is float) or not is_finite(count) or count!=int(count) or count<0 or count>16:return false
	pink_count=int(count);rebuild();return true
