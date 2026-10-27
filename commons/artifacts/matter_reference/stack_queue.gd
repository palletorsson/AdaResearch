extends "res://commons/artifacts/matter_reference/computing_board.gd"
## Real container geometry enforces LIFO/FIFO. Removal reads actual body positions.
var crates: Array = []
var chosen := 0
var removed: Array = []
const KINDS = ["monitor","extinguisher","cone","donut"]
func _init() -> void:super._init();kind = "stackqueue"
func build_controls() -> void:console(["TYPE","PUSH","POP","ENQUEUE","DEQUEUE","CLEAR"],command)
func reset_take() -> void:clear_generated();crates.clear();removed.clear();elapsed = 0
func command(id: String) -> void:
	match id:
		"TYPE":chosen = (chosen+1)%4
		"PUSH":insert("stack",KINDS[chosen])
		"ENQUEUE":insert("queue",KINDS[chosen])
		"POP":remove_first("stack")
		"DEQUEUE":remove_first("queue")
		"CLEAR":reset_take()
func insert(where: String,item: String) -> RigidBody3D:
	if ordered(where).size()>=(8 if where=="stack" else 6):return null
	var body := make_dynamic(where);body.set_meta("where",where);body.set_meta("item",item);body.set_meta("serial",serial);crates.append(body)
	var half := Vector3(.36,.26,.3);var thickness := .035
	for axis in range(3):
		for a in [-1,1]:
			for b in [-1,1]:
				var size := Vector3(thickness,thickness,thickness);size[axis] = half[axis]*2;var at := Vector3.ZERO;at[(axis+1)%3] = a*half[(axis+1)%3];at[(axis+2)%3] = b*half[(axis+2)%3];box_mesh(body,at,size,"stop")
	var item_mesh := prefab(item);item_mesh.scale = Vector3.ONE*.58;item_mesh.position.y = -.24;body.add_child(item_mesh)
	var label := Label3D.new();label.text = str(serial)+" / "+item;label.position = Vector3(0,0,.34);label.font_size = 26;label.pixel_size = .0011;body.add_child(label);return body
func ordered(where: String) -> Array:
	var list := crates.filter(func(b):return is_instance_valid(b) and str(b.get_meta("where"))==where)
	list.sort_custom(func(a,b):return to_local(a.global_position).y>to_local(b.global_position).y if where=="stack" else to_local(a.global_position).x>to_local(b.global_position).x);return list
func remove_first(where: String) -> Dictionary:
	var list := ordered(where)
	if list.is_empty():return {}
	var b: RigidBody3D = list[0];var result := {"item":b.get_meta("item"),"serial":b.get_meta("serial"),"where":where};removed.append(result);crates.erase(b);generated.erase(b);b.queue_free();return result
func _physics_process(dt: float) -> void:
	elapsed += dt
	status.text = "TYPE: "+KINDS[chosen]+" / STACK "+str(ordered("stack").size())+" / QUEUE "+str(ordered("queue").size())+"\n"+JSON.stringify(removed[-1] if not removed.is_empty() else {})
