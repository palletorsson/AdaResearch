extends Node
## Opt-in companion for the existing desk. Height is measured; time moves the pen.
## Missing measurements leave blank paper, never a generated waveform.
const SAMPLE_PERIOD := 0.05
const HALF_HEIGHT_RANGE := 0.70
const PAGE_WIDTH := 0.84
const MAX_SAMPLES := 1800
var host: Node3D
var _source: Node
var _label: Label3D
var _elapsed := 0.0
var _sample_clock := 0.0
var _reference_height := 0.0
var _active := false
var _full := false
var _gap_pending := false
var _outside_time := 1.0
var _source_id := 0
var _source_kind := ""
var _last_position := Vector3.ZERO
var _have_last_position := false
var _times: Array[float] = []
var _heights: Array[float] = []

func _ready() -> void:
	_source = load("res://commons/artifacts/trace_shared/measured_view_source.gd").new()
	add_child(_source)
	_source.discontinuity.connect(_interrupt)
	host._trace.clear()
	host._ink.multimesh.instance_count = 0
	host._nib.visible = false
	# The tilted back of the old sheet intersected the tabletop. Lift its
	# full depth above the table, using the already-transformed page axis.
	host._paper.position.y = host.table_h + 0.034 + absf(host._paper.basis.z.y)*0.31
	# Fine ink leaves room to read the differences between five measured rows.
	host._dot_mesh.radius = 0.0018
	host._dot_mesh.height = 0.0036
	_build_label()

func _interrupt() -> void:
	_gap_pending = true
	_have_last_position = false

func _start(height: float, camera: Camera3D, kind: String) -> void:
	host._trace.clear()
	_times.clear()
	_heights.clear()
	host._rebuild_ink()
	_elapsed = 0.0
	_sample_clock = 0.0
	_reference_height = height
	_source_id = camera.get_instance_id()
	_source_kind = kind
	_active = true
	_full = false
	_gap_pending = false
	_have_last_position = false
	host._pen_u = 0.08
	host._pen_row = 0

func _advance_clock(delta: float) -> void:
	_elapsed += delta
	var distance: float = _elapsed * maxf(host.write_speed,0.001)
	host._pen_row = int(floor(distance/PAGE_WIDTH))
	host._pen_u = 0.08 + fmod(distance,PAGE_WIDTH)
	if host._pen_row >= host.rows or _times.size() >= MAX_SAMPLES:
		_full = true
		host._nib.visible = false

func advance(delta: float) -> void:
	if delta <= 0.0: return
	var input: Dictionary = _source.read_input()
	if input.is_empty():
		if _active and not _full: _advance_clock(delta)
		_interrupt()
		host._nib.visible = false
		_label.text = "HEIGHT / TIME\nWaiting for measured input"
		return
	var camera: Camera3D = input["camera"]
	var kind: String = input["kind"]
	var p: Vector3 = host.to_local(camera.global_position)
	if not p.is_finite():
		_interrupt()
		host._nib.visible = false
		return
	var near := absf(p.x)<=0.8 and p.z>=0.40 and p.z<=1.65 and p.y>0.2 and p.y<3.2
	if not near:
		_outside_time += delta
		if _outside_time >= 0.6: _active = false
		_interrupt()
		host._nib.visible = false
		_label.text = "THE PAUSE LEAVES A LINE\nCome closer. Lower your head. Wait."
		return
	_outside_time = 0.0
	if not _active or camera.get_instance_id()!=_source_id or kind!=_source_kind:
		_start(p.y,camera,kind)
	if _full:
		_label.text = "PAGE FULL\nStep away and return for a fresh sheet."
		return
	_advance_clock(delta)
	if _full: return
	# Unobserved time has a place on the page but no fabricated samples.
	if delta>0.25 or (_have_last_position and p.distance_to(_last_position)>0.45):
		_interrupt()
	_last_position = p
	_have_last_position = true
	if _gap_pending:
		_gap_pending = false
		_sample_clock = 0.0
		host._nib.visible = false
		return
	var relative_height: float = p.y-_reference_height
	var v := height_on_page(relative_height,host._pen_row)
	host._nib.position = host._uv_to_local(host._pen_u,v)
	host._nib.visible = true
	_sample_clock += delta
	if _sample_clock >= SAMPLE_PERIOD:
		_sample_clock = 0.0
		host._trace.append(Vector2(host._pen_u,v))
		_times.append(_elapsed)
		_heights.append(p.y)
		host._rebuild_ink()
	var range_note := " / row limit" if absf(relative_height)>HALF_HEIGHT_RANGE else ""
	_label.text = kind + " HEIGHT / TIME" + range_note + "\n" + str(_times.size()) + " samples / stillness also writes"

func height_on_page(relative_height: float, row: int) -> float:
	var height_fraction := clampf(relative_height/HALF_HEIGHT_RANGE,-1.0,1.0)
	return host._row_baseline(row)-height_fraction*(0.32/float(host.rows))

func _build_label() -> void:
	var backing := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82,0.16,0.025)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.045,0.055,0.07)
	material.roughness = 0.85
	mesh.material = material
	backing.mesh = mesh
	backing.position = Vector3(0,host.table_h+0.30,-0.30)
	host.add_child(backing)
	_label = Label3D.new()
	_label.position = Vector3(0,host.table_h+0.30,-0.285)
	_label.font_size = 32
	_label.pixel_size = 0.001
	_label.modulate = Color(0.90,0.86,0.74)
	_label.outline_size = 0
	_label.text = "THE PAUSE LEAVES A LINE\nCome closer. Lower your head. Wait."
	host.add_child(_label)
