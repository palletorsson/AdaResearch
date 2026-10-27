extends XRToolsPickable
## Canonical 28 cm carried point for Trace. Surface-test showers intentionally
## retain their separate white factory: this body keeps hand pickup and trace.
@export var colour := Color("090a0c")
func _ready() -> void:
	super()
	mass=.3;freeze=true;release_mode=ReleaseMode.UNFROZEN;continuous_cd=true
	linear_damp=.06;angular_damp=.08
	physics_material_override=PhysicsMaterial.new()
	physics_material_override.friction=.6;physics_material_override.bounce=.02
	var visible := MeshInstance3D.new();visible.name="PointSkin"
	var sphere := SphereMesh.new();sphere.radius=.14;sphere.height=.28;sphere.radial_segments=32;sphere.rings=16
	visible.mesh=sphere
	var finish := StandardMaterial3D.new();finish.albedo_color=colour;finish.roughness=.27
	visible.material_override=finish;add_child(visible)
	var collision := CollisionShape3D.new();collision.name="PointCollision"
	var shape := SphereShape3D.new();shape.radius=.14;collision.shape=shape;add_child(collision)
