extends XRToolsPickable
const Surface=preload("writing_surface.gd")
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")
var wall: Node3D
var note_index:=0
var tint:=Color("f3df87")
var surface: Node3D
var pinned_at:=Vector2.ZERO
var desktop_held:=false

func _ready() -> void:
	freeze=true;release_mode=ReleaseMode.FROZEN;collision_layer=4;collision_mask=0
	Objects.box(self,Vector3.ZERO,Vector3(0.36,0.36,0.009),tint)
	var shape:=BoxShape3D.new();shape.size=Vector3(0.36,0.36,0.035)
	var collider:=CollisionShape3D.new();collider.shape=shape;add_child(collider)
	surface=Surface.new();surface.size=Vector2(0.32,0.32);surface.resolution=256
	surface.paper_color=tint;surface.position.z=0.006;add_child(surface)
	surface.edited.connect(wall.mark_dirty)
	super()
	dropped.connect(func(_body):pin.call_deferred())

func on_desktop_grab(_pointer: Node) -> void:desktop_held=true
func on_desktop_drop(_pointer: Node) -> void:
	desktop_held=false;pin.call_deferred()

func pin() -> void:
	if is_picked_up() or desktop_held:return
	var p: Vector3=wall.to_local(global_position)
	# Release near the wall to pin. A note released away returns to its last place.
	if absf(p.z-0.22)<0.55 and absf(p.x)<3.1 and p.y>0.2 and p.y<2.3:
		pinned_at=Vector2(clampf(p.x,-2.9,2.9),clampf(p.y,0.3,2.1))
	freeze=true;linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO
	global_transform=wall.global_transform*Transform3D(Basis(),Vector3(pinned_at.x,pinned_at.y,0.22+note_index*0.001))
	force_update_transform();reset_physics_interpolation();wall.mark_dirty()
