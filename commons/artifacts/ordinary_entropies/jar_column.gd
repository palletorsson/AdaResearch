extends "res://commons/artifacts/ordinary_entropies/jar_snapshot.gd"
## Enlarge the retained starting record, then mix with a reproducible bounded walk.
const Objects=preload("objects.gd")
const Mixing=preload("column_mixing.gd")
const COLUMN_RADIUS:=0.52
const COLUMN_HEIGHT:=2.30
const COLUMN_BOTTOM:=0.46
const BEAD_RADIUS:=0.043
const COLOUR_A:=Color("b49af7") # Lavender
const COLOUR_B:=Color("f58b91") # Warm coral
var column: Node3D
var display_beads: Array[MeshInstance3D]=[]
var stream_index:=0
var mixing=Mixing.new()

func _ready() -> void:
	super._ready()
	# Keep the original measurement coordinates and RNG consumption intact.
	# Hidden source bodies have no collision; the large column owns its boundary.
	_jar_body.hide();_jar_body.collision_layer=0;_jar_body.collision_mask=0
	for group in [_particles_a,_particles_b]:
		for body in group:body.collision_layer=0;body.collision_mask=0
	column=Node3D.new();column.name="ColumnDisplay";add_child(column)
	var glass:=StandardMaterial3D.new()
	glass.albedo_color=Color(0.91,0.94,0.95,0.075)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness=0.12;glass.metallic=0.0
	glass.cull_mode=BaseMaterial3D.CULL_BACK
	var shell:=MeshInstance3D.new();shell.name="Glass";shell.mesh=jar_shell();shell.material_override=glass
	shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;column.add_child(shell)
	var metal:=Objects.material(Color("a4afb3"));metal.metallic=0.45;metal.roughness=0.45
	var base:=Objects.material(Color("eee8df"));base.roughness=0.48
	cylinder("Foot",0.56,0.08,0.44,metal)
	cylinder("LowerCollar",0.53,0.025,COLUMN_BOTTOM,metal)
	cylinder("UpperCollar",0.46,0.045,COLUMN_BOTTOM+COLUMN_HEIGHT,metal)
	cylinder("Lid",0.48,0.075,COLUMN_BOTTOM+COLUMN_HEIGHT+0.04,base)
	var boundary:=StaticBody3D.new();boundary.name="ColumnBoundary";column.add_child(boundary)
	var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new()
	shape.radius=0.56;shape.height=COLUMN_HEIGHT+0.14;collision.shape=shape;collision.position.y=0.40+shape.height/2;boundary.add_child(collision)
	var etch:=Objects.material(Color("a3b5ba"));etch.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;etch.albedo_color.a=0.32
	for band in range(1,6):
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new()
		torus.inner_radius=COLUMN_RADIUS-0.001;torus.outer_radius=COLUMN_RADIUS+0.001
		torus.rings=48;torus.ring_segments=6;ring.mesh=torus;ring.material_override=etch
		column.add_child(ring);ring.position.y=COLUMN_BOTTOM+COLUMN_HEIGHT*band/6.0
	var retained:=positions()
	for i in retained.size():
		var bead:=Objects.sphere(column,display_position(retained[i]),BEAD_RADIUS,COLOUR_A if i<40 else COLOUR_B)
		bead.name="Bead"+str(i);bead.material_override.roughness=0.7;bead.material_override.metallic=0
		display_beads.append(bead)
	# Enlarge the view without speeding up the established slow mixing trajectory.
	mixing.configure(retained,jar_radius-jar_wall_thickness-particle_radius,jar_height/2-particle_radius*2,Vector3(jar_radius/0.34,jar_height/2.0,jar_radius/0.34),stream_index)

func jar_shell() -> ArrayMesh:
	# Open, outward-facing skin; no overlapping transparent end caps.
	var profile: Array[Vector2]=[Vector2(0.50,0.46),Vector2(0.52,0.50),Vector2(0.52,2.54),Vector2(0.515,2.60),Vector2(0.49,2.67),Vector2(0.445,2.73),Vector2(0.445,2.76)]
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in profile.size()-1:
		for j in 96:
			for index in [Vector2i(k,j),Vector2i(k,j+1),Vector2i(k+1,j),Vector2i(k,j+1),Vector2i(k+1,j+1),Vector2i(k+1,j)]:
				var p: Vector2=profile[index.x];var angle: float=TAU*index.y/96.0
				var slope: Vector2=profile[mini(index.x+1,profile.size()-1)]-profile[maxi(0,index.x-1)]
				surface.set_normal(Vector3(slope.y*cos(angle),-slope.x,slope.y*sin(angle)).normalized())
				surface.add_vertex(Vector3(p.x*cos(angle),p.y,p.x*sin(angle)))
	return surface.commit()

func advance_mixing(seconds: float) -> void:
	mixing.advance(seconds);show_mixing()

func reset_mixing() -> void:
	mixing.reset();show_mixing()

func show_mixing() -> void:
	# The readout and visible beads use the same interpolated coordinates.
	for i in mixing.current.size():
		var body: RigidBody3D=_particles_a[i] if i<40 else _particles_b[i-40]
		body.position=mixing.current[i]
		display_beads[i].position=display_position(mixing.current[i])

func display_position(retained: Vector3) -> Vector3:
	return Vector3(retained.x*COLUMN_RADIUS/jar_radius,COLUMN_BOTTOM+COLUMN_HEIGHT/2+retained.y*COLUMN_HEIGHT/jar_height,retained.z*COLUMN_RADIUS/jar_radius)

func cylinder(label: String,radius: float,height: float,y: float,material: Material) -> void:
	var view:=MeshInstance3D.new();view.name=label
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=64
	view.mesh=mesh;view.material_override=material;column.add_child(view);view.position.y=y
