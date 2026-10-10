extends Node3D
const PointBody = preload("res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd")
var desk:Node3D
var point:XRToolsPickable
var last_detent:=-1
func _ready() -> void:
	desk=get_parent()
	point=PointBody.new();point.name="DesignPoint";add_child(point)
	point.action_pressed.connect(func(_body):desk.act("HOLD"))
	desk.box(Vector3(0,1.01,2.55),Vector3(1.12,.07,.22),desk.material("e5e0dc"),true)
	desk.label("MOVE: SELECTED GENE / HELD TRIGGER: HOLD",Vector3(0,.95,2.67),.0006)
	park()
func normalized() -> float:
	var name:String=desk.sculptor.GENE_SLIDERS[desk.gene_index][0]
	var span:Array=desk.sculptor.GENE_RANGE[name]
	return inverse_lerp(span[0],span[1],desk.sculptor._dna.get(name))
func _physics_process(_dt:float) -> void:
	if point.held():
		var detent:=clampi(roundi((to_local(point.global_position).x/.8+.5)*40),0,40)
		if last_detent==-1:last_detent=detent;return
		if detent!=last_detent:
			last_detent=detent
			var gene:String=desk.sculptor.GENE_SLIDERS[desk.gene_index][0]
			desk.sculptor.set_gene_normalized(gene,detent/40.0)
			desk.sculptor._sync_sliders_from_dna()
			desk.notice="Hand edit queued / trigger holds current design."
			desk.refresh()
	else:last_detent=-1;park()
func park() -> void:
	point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3((normalized()-.5)*.8,1.18,2.55))
