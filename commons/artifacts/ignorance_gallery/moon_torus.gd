extends Node3D
## One shape, two sampling directions, and the museum's real moving moon.
## No painted shadow or local duplicate light: the mesh casts onto the existing floor.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const RING_STEPS := [48,32,24,16,12,8,6,4]
const TUBE_STEPS := [24,16,12,8,6,4]
const SECONDS_PER_STEP := 1.5
var form := TorusMesh.new()
var body: MeshInstance3D
var readout: Label3D
var steps: Array[Vector2i] = []
var step_index := 0
var elapsed := 0.0
var playing := true

func _ready() -> void:
	form.inner_radius=1.4
	form.outer_radius=2.5
	body=MeshInstance3D.new()
	body.name="MoonTorus"
	body.mesh=form
	body.material_override=Kit.material(Color(0.10,0.10,0.105))
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# The root is on the hall floor; the centre of the torus is five metres up.
	body.position=Vector3(2.0,5.0,0)
	add_child(body)
	for rings in RING_STEPS: steps.append(Vector2i(rings,24))
	for segments in TUBE_STEPS: steps.append(Vector2i(4,segments))
	for i in range(RING_STEPS.size()-1,-1,-1): steps.append(Vector2i(RING_STEPS[i],4))
	for i in range(TUBE_STEPS.size()-1,-1,-1): steps.append(Vector2i(48,TUBE_STEPS[i]))
	Kit.block(self,Vector3(3.6,0.8,0.04),Vector3(3.5,2.6,4.86),Kit.WHITE,false)
	Kit.label(self,"A FORM ABOVE / A SHADOW BELOW",Vector3(3.5,2.80,4.82),0.0024,PI)
	readout=Kit.label(self,"",Vector3(3.5,2.55,4.81),0.0019,PI)
	Kit.label(self,"One count changes at a time.",Vector3(3.5,2.33,4.80),0.0015,PI)
	set_step(0)

func _process(delta: float) -> void:
	if not playing: return
	elapsed+=delta
	if elapsed < SECONDS_PER_STEP: return
	var advances := int(elapsed/SECONDS_PER_STEP)
	elapsed=fmod(elapsed,SECONDS_PER_STEP)
	set_step(step_index+advances)

func set_step(index: int) -> void:
	step_index=posmod(index,steps.size())
	var counts := steps[step_index]
	if form.rings != counts.x: form.rings=counts.x
	if form.ring_segments != counts.y: form.ring_segments=counts.y
	readout.text="%d RINGS   /   %d SEGMENTS" % [counts.x,counts.y]
