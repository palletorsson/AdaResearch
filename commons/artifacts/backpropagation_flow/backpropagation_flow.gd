extends Node3D
class_name BackpropagationFlow

# @identity
# essence: a four-plane network that actually runs — forward pass, backward pass, weight update — with every connection's glow driven by the size of the gradient sitting on it, so the wave crossing right to left is the error being divided up and the dimming toward the input is that division running out
# desire: to refuse the stock backprop animation, where identical dots slide backward at identical brightness and the vanishing gradient is a sentence in the caption rather than a thing on the wall
# critical_parameter: `activation` — sigmoid's derivative peaks at 0.25, so every layer it crosses cuts the gradient to a quarter at best and the input block goes nearly dark; tanh peaks at 1.0 and the wave reaches the far end; relu passes 1 or 0 and the dimming becomes patchy instead of smooth
# triggers: _ready() builds the planes and wires them, then _process() sweeps a pulse position from the output plane to the input plane; each connection's emission is base + gain * |dE/dw| normalised * the pulse envelope, and when the sweep completes one gradient-descent step is applied and every gradient recomputed
# emerges: the brightness ranking survives the pulse — a residual glow is left behind, so by the end of a sweep all three blocks are lit at once at their true relative magnitudes and the decay is read as a comparison, not remembered from a second ago
# needs: SphereMesh/CylinderMesh [Godot built-ins]; Grid.gdshader [present]; Label3D readouts [Godot built-in]; TextScreen PAD plate [present]; neural_network_visualization.gd [precedent — its forward_pass/backward_pass are the arithmetic reimplemented here at artifact scale]
# relationships: the mechanism under every trained thing in the machinelearning sequence — what neural_network_visualization shows converging, this shows paying for that convergence one layer at a time
# truth: backpropagation is not a signal travelling backward, it is credit being divided. Each layer takes the blame handed to it, multiplies it by a derivative smaller than one, and passes the remainder on — which is why the layers nearest the input learn slowest, and why depth was a problem for thirty years before anyone found a derivative that did not shrink.

## Backprop as a lit object. The network below is small and real: random
## weights, a fixed four-sample task, sigmoid/tanh/relu forward and backward
## passes taken from neural_network_visualization.gd, and one descent step per
## pulse. Nothing here is keyframed — the numbers on the readouts are the same
## numbers driving the emission on the wires above them.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

const SPAN_X := 2.50
const CENTER_Y := 1.18
const SPREAD_Y := 0.36
const SPREAD_Z := 0.15
const NEURON_R := 0.055
const BASE_H := 0.08

## Input plane first, output plane last. The pulse runs the other way.
@export var layer_sizes: PackedInt32Array = PackedInt32Array([4, 5, 4, 2])

## The axis this artifact is actually about. Sigmoid's derivative never exceeds
## 0.25, so three layers of it can only pass 1/64 of the error through at best;
## tanh tops out at 1.0 and the wave survives; relu passes everything or
## nothing and the decay becomes ragged rather than smooth.
@export_enum("sigmoid", "tanh", "relu") var activation: String = "sigmoid"

@export var learning_rate: float = 0.6
@export var pulse_period: float = 3.4        # seconds for one output -> input sweep
@export var pulse_width: float = 0.42        # in units of layer-blocks
@export var gradient_gain: float = 4.2       # emission added at full normalised gradient
@export var base_emission: float = 0.18      # what an unlit wire still shows
@export var residual: float = 0.55           # glow a block keeps after the pulse passes
@export var rng_seed: int = 20260729

const ACTIVATIONS: PackedStringArray = ["sigmoid", "tanh", "relu"]

var _built := false
var _created: Array[Node] = []
var _rng := RandomNumberGenerator.new()

# --- network state (nested plain Arrays; only Arrays can carry element types) ---
var _weights: Array = []        # _weights[b][i][j], b = block between layer b and b+1
var _biases: Array = []         # _biases[b][j]
var _act: Array = []            # _act[l][i]
var _z: Array = []              # _z[l][i]
var _node_delta: Array = []     # _node_delta[l][i]
var _w_grad: Array = []         # _w_grad[b][i][j]
var _b_grad: Array = []
var _data_in: Array = []
var _data_out: Array = []

# --- render state ---
var _edge_mats: Array = []      # _edge_mats[b] -> flat Array of Material, index i*cols + j
var _edge_norm: Array = []      # _edge_mats twin: normalised |dE/dw| in 0..1
var _neuron_mats: Array = []    # _neuron_mats[l] -> Array of Material
var _neuron_norm: Array = []
var _readouts: Array = []       # one Label3D per block
var _error_label: Label3D = null

var _clock: float = 0.0
var _cycle: int = 0
var _sample: int = 0
var _error: float = 0.0


func _ready() -> void:
	_rng.seed = rng_seed
	_build_all()
	_built = true
	set_process(not Engine.is_editor_hint())


# --- network --------------------------------------------------------------

func _sizes() -> Array[int]:
	var out: Array[int] = []
	for v in layer_sizes:
		var n: int = int(v)
		if n > 0:
			out.append(n)
	while out.size() < 2:
		out.append(2)
	return out


func _activate(x: float) -> float:
	match activation:
		"tanh":
			return tanh(x)
		"relu":
			return maxf(0.0, x)
		_:
			return 1.0 / (1.0 + exp(-clampf(x, -30.0, 30.0)))


func _activate_derivative(x: float) -> float:
	match activation:
		"tanh":
			var t: float = tanh(x)
			return 1.0 - t * t
		"relu":
			return 1.0 if x > 0.0 else 0.0
		_:
			var s: float = 1.0 / (1.0 + exp(-clampf(x, -30.0, 30.0)))
			return s * (1.0 - s)


func _init_network() -> void:
	var sizes: Array[int] = _sizes()
	_weights = []
	_biases = []
	_act = []
	_z = []
	_node_delta = []
	_w_grad = []
	_b_grad = []

	for l in range(sizes.size()):
		var a: Array = []
		var zz: Array = []
		var dd: Array = []
		for i in range(sizes[l]):
			a.append(0.0)
			zz.append(0.0)
			dd.append(0.0)
		_act.append(a)
		_z.append(zz)
		_node_delta.append(dd)

	for b in range(sizes.size() - 1):
		var rows: Array = []
		var grows: Array = []
		for i in range(sizes[b]):
			var row: Array = []
			var grow: Array = []
			for j in range(sizes[b + 1]):
				row.append(_rng.randf_range(-1.1, 1.1))
				grow.append(0.0)
			rows.append(row)
			grows.append(grow)
		_weights.append(rows)
		_w_grad.append(grows)
		var bs: Array = []
		var gbs: Array = []
		for j in range(sizes[b + 1]):
			bs.append(_rng.randf_range(-0.3, 0.3))
			gbs.append(0.0)
		_biases.append(bs)
		_b_grad.append(gbs)

	# A small fixed task. Four samples is enough for the gradients to be real
	# and to keep changing; what this artifact shows is the shape of the
	# credit assignment, not the accuracy of the answer.
	_data_in = []
	_data_out = []
	for s in range(4):
		var xin: Array = []
		for i in range(sizes[0]):
			# Continuous, never zero. dE/dw for the first block is a_i * delta_j,
			# so a binary input would leave half the input wires at exactly zero
			# gradient — true, but it would read as broken wiring rather than as
			# the vanishing this artifact is about.
			xin.append(_rng.randf_range(0.12, 0.95))
		var xout: Array = []
		for j in range(sizes[sizes.size() - 1]):
			xout.append(1.0 if _rng.randf() > 0.5 else 0.0)
		_data_in.append(xin)
		_data_out.append(xout)


func _forward(inputs: Array) -> void:
	for i in range(_act[0].size()):
		var v: float = float(inputs[i]) if i < inputs.size() else 0.0
		_act[0][i] = v
		_z[0][i] = v
	for l in range(1, _act.size()):
		for j in range(_act[l].size()):
			var s: float = float(_biases[l - 1][j])
			for i in range(_act[l - 1].size()):
				s += float(_act[l - 1][i]) * float(_weights[l - 1][i][j])
			_z[l][j] = s
			_act[l][j] = _activate(s)


## Backward pass, straight off the precedent: the output layer's delta is
## (target - output) * f'(z), and every layer inward takes the weighted sum of
## the deltas ahead of it and multiplies by its own f'(z). The multiply is the
## whole story — f' < 1 means the number handed backward is smaller than the
## number handed in, every single layer.
func _backward(targets: Array) -> void:
	var out_idx: int = _act.size() - 1
	var out_deltas: Array = []
	var err_sum: float = 0.0
	for j in range(_act[out_idx].size()):
		var t: float = float(targets[j]) if j < targets.size() else 0.0
		var e: float = t - float(_act[out_idx][j])
		err_sum += e * e
		out_deltas.append(e * _activate_derivative(float(_z[out_idx][j])))
	_error = err_sum / maxf(float(_act[out_idx].size()), 1.0)
	_node_delta[out_idx] = out_deltas

	var next_deltas: Array = out_deltas
	for l in range(out_idx - 1, -1, -1):
		var cur: Array = []
		for i in range(_act[l].size()):
			var acc: float = 0.0
			for j in range(_act[l + 1].size()):
				acc += float(_weights[l][i][j]) * float(next_deltas[j])
			cur.append(acc * _activate_derivative(float(_z[l][i])))
		for j in range(_act[l + 1].size()):
			_b_grad[l][j] = float(next_deltas[j])
			for i in range(_act[l].size()):
				_w_grad[l][i][j] = float(_act[l][i]) * float(next_deltas[j])
		_node_delta[l] = cur
		next_deltas = cur


func _descend() -> void:
	for b in range(_weights.size()):
		for i in range(_weights[b].size()):
			for j in range(_weights[b][i].size()):
				_weights[b][i][j] = float(_weights[b][i][j]) + learning_rate * float(_w_grad[b][i][j])
		for j in range(_biases[b].size()):
			_biases[b][j] = float(_biases[b][j]) + learning_rate * float(_b_grad[b][j])


## Normalise every gradient against the largest in the network, so the numbers
## driving emission are a comparison between blocks rather than an absolute
## scale nobody can read. Divided by the global max — NOT per block, which
## would rescale every block to full brightness and hide the exact decay this
## artifact exists to show.
func _refresh_norms() -> void:
	var gmax: float = 0.0
	for b in range(_w_grad.size()):
		for i in range(_w_grad[b].size()):
			for j in range(_w_grad[b][i].size()):
				gmax = maxf(gmax, absf(float(_w_grad[b][i][j])))
	if gmax < 1e-9:
		gmax = 1e-9
	for b in range(_w_grad.size()):
		var flat: Array = []
		var cols: int = _act[b + 1].size()
		for i in range(_w_grad[b].size()):
			for j in range(cols):
				flat.append(absf(float(_w_grad[b][i][j])) / gmax)
		_edge_norm[b] = flat

	var dmax: float = 0.0
	for l in range(_node_delta.size()):
		for i in range(_node_delta[l].size()):
			dmax = maxf(dmax, absf(float(_node_delta[l][i])))
	if dmax < 1e-9:
		dmax = 1e-9
	for l in range(_node_delta.size()):
		var nf: Array = []
		for i in range(_node_delta[l].size()):
			nf.append(absf(float(_node_delta[l][i])) / dmax)
		_neuron_norm[l] = nf


## Mean |dE/dw| over one block — the number printed under it, and the number
## whose collapse from right to left is the vanishing gradient.
func _block_mean(b: int) -> float:
	var total: float = 0.0
	var n: int = 0
	for i in range(_w_grad[b].size()):
		for j in range(_w_grad[b][i].size()):
			total += absf(float(_w_grad[b][i][j]))
			n += 1
	return total / maxf(float(n), 1.0)


# --- build ----------------------------------------------------------------

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


## Neuron positions: each layer is a plane in Y-Z, two columns deep once it has
## four or more units, so the layers read as sheets seen edge-on rather than a
## row of beads.
func _neuron_pos(l: int, i: int, count: int, layers: int) -> Vector3:
	var x: float = -SPAN_X * 0.5 + SPAN_X * (float(l) / maxf(float(layers - 1), 1.0))
	var cols: int = 2 if count >= 4 else 1
	var rows: int = int(ceil(float(count) / float(cols)))
	var r: int = i / cols
	var c: int = i % cols
	var y: float = CENTER_Y
	if rows > 1:
		y = CENTER_Y + SPREAD_Y * (float(r) / float(rows - 1) - 0.5) * 2.0
	var z: float = 0.0
	if cols > 1:
		z = SPREAD_Z * (float(c) - 0.5) * 2.0
	return Vector3(x, y, z)


func _build_all() -> void:
	_edge_mats = []
	_edge_norm = []
	_neuron_mats = []
	_neuron_norm = []
	_readouts = []
	_clock = 0.0
	_cycle = 0
	_sample = 0

	_rng.seed = rng_seed
	_init_network()
	_forward(_data_in[0])
	_backward(_data_out[0])

	var sizes: Array[int] = _sizes()
	var layers: int = sizes.size()

	_add_base()

	# neurons
	var positions: Array = []
	for l in range(layers):
		var pl: Array = []
		var mats: Array = []
		for i in range(sizes[l]):
			var p: Vector3 = _neuron_pos(l, i, sizes[l], layers)
			var mat: Material = _grid_material(Color(0.52, 0.58, 0.68), Color(0.55, 0.85, 1.0), base_emission)
			var mi := _sphere(p, NEURON_R, mat)
			_own(mi)
			pl.append(p)
			mats.append(mat)
		positions.append(pl)
		_neuron_mats.append(mats)
		_neuron_norm.append([])

	# connections, one material per wire so each carries its own gradient
	for b in range(layers - 1):
		var flat_mats: Array = []
		for i in range(sizes[b]):
			for j in range(sizes[b + 1]):
				var w: float = absf(float(_weights[b][i][j]))
				var emat: Material = _grid_material(Color(0.38, 0.42, 0.52), Color(0.55, 0.88, 1.0), base_emission)
				var seg := _strut(positions[b][i], positions[b + 1][j], 0.0035 + 0.0035 * minf(w, 1.5), emat)
				_own(seg)
				flat_mats.append(emat)
		_edge_mats.append(flat_mats)
		_edge_norm.append([])
		_add_readout(b, layers)

	_add_error_label()
	_add_plate()
	_refresh_norms()
	_refresh_readouts()
	_paint(1.0)


func _add_base() -> void:
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var box := BoxMesh.new()
	box.size = Vector3(SPAN_X + 0.34, BASE_H, 0.48)
	rail.mesh = box
	rail.position = Vector3(0.0, BASE_H * 0.5, 0.0)
	rail.material_override = _witness_mat()
	_own(rail)
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.07, CENTER_Y - SPREAD_Y - BASE_H + 0.06, 0.07)
		post.mesh = pb
		post.position = Vector3(float(sx) * (SPAN_X * 0.5 + 0.10), BASE_H + pb.size.y * 0.5, 0.0)
		post.material_override = _witness_mat()
		_own(post)


func _add_readout(b: int, layers: int) -> void:
	var lb := Label3D.new()
	lb.name = "Readout%d" % b
	lb.font_size = 22
	lb.pixel_size = 0.0016
	lb.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lb.modulate = Color(0.72, 0.86, 1.0)
	lb.outline_size = 4
	var xa: float = -SPAN_X * 0.5 + SPAN_X * (float(b) / maxf(float(layers - 1), 1.0))
	var xb: float = -SPAN_X * 0.5 + SPAN_X * (float(b + 1) / maxf(float(layers - 1), 1.0))
	lb.position = Vector3((xa + xb) * 0.5, BASE_H + 0.14, 0.26)
	lb.text = "block %d" % b
	_own(lb)
	_readouts.append(lb)


func _add_error_label() -> void:
	_error_label = Label3D.new()
	_error_label.name = "ErrorReadout"
	_error_label.font_size = 24
	_error_label.pixel_size = 0.0017
	_error_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_error_label.modulate = Color(1.0, 0.82, 0.45)
	_error_label.outline_size = 4
	_error_label.position = Vector3(0.0, CENTER_Y + SPREAD_Y + 0.22, 0.0)
	_error_label.text = "error --"
	_own(_error_label)


func _add_plate() -> void:
	# Configure BEFORE add_child — TextScreen only rebuilds once in-tree.
	var ts := TextScreenScript.new()
	ts.name = "Plate"
	ts.mode = 2                       # Mode.PAD
	ts.width_m = 0.42
	ts.position = Vector3(0.0, BASE_H + 0.005, -0.16)
	if ts.has_method("set_text"):
		ts.set_text("BACKPROPAGATION", "brightness is |dE/dw|, normalised —\nthe pulse runs output to input and\nruns out of error on the way")
	_own(ts)


# --- animation ------------------------------------------------------------

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_clock += delta
	var period: float = maxf(pulse_period, 0.3)
	var u: float = fmod(_clock, period) / period
	var cycle: int = int(floor(_clock / period))
	if cycle != _cycle:
		_cycle = cycle
		_step()
	_paint(u)


## One sweep completed: take the descent step the sweep just computed, move to
## the next sample, and recompute. The gradients on the wires are therefore
## never the same two sweeps running — they shrink as the network learns, which
## is the second thing worth watching here.
func _step() -> void:
	_descend()
	_sample = (_sample + 1) % _data_in.size()
	_forward(_data_in[_sample])
	_backward(_data_out[_sample])
	_refresh_norms()
	_refresh_readouts()


func _refresh_readouts() -> void:
	for b in range(_readouts.size()):
		var lb: Label3D = _readouts[b]
		lb.text = "block %d\nmean |dE/dw|\n%s" % [b, _sci(_block_mean(b))]
	if _error_label != null:
		_error_label.text = "%s   sample %d   mse %s" % [activation, _sample, _sci(_error)]


## Emission per wire = base + gain * normalised gradient * envelope. The
## envelope is a gaussian centred on the pulse position, plus a residual left
## behind once the pulse has passed — without the residual the blocks are never
## lit at the same instant and the decay can only be remembered, not compared.
func _paint(u: float) -> void:
	var blocks: int = _edge_mats.size()
	if blocks == 0:
		return
	var pos: float = float(blocks) - u * (float(blocks) + 1.0)
	var width: float = maxf(pulse_width, 0.05)
	for b in range(blocks):
		var d: float = (pos - float(b)) / width
		var env: float = exp(-d * d)
		if pos < float(b):
			env = maxf(env, residual)
		var mats: Array = _edge_mats[b]
		var norms: Array = _edge_norm[b]
		for k in range(mats.size()):
			var g: float = float(norms[k]) if k < norms.size() else 0.0
			_apply_emission(mats[k], base_emission + gradient_gain * g * env)
	# neurons take the delta on the node itself, one plane ahead of the wires
	for l in range(_neuron_mats.size()):
		var dl: float = (pos - (float(l) - 0.5)) / width
		var env_n: float = exp(-dl * dl)
		if pos < float(l) - 0.5:
			env_n = maxf(env_n, residual)
		var mats_n: Array = _neuron_mats[l]
		var norms_n: Array = _neuron_norm[l]
		for i in range(mats_n.size()):
			var gn: float = float(norms_n[i]) if i < norms_n.size() else 0.0
			_apply_emission(mats_n[i], base_emission + gradient_gain * 0.8 * gn * env_n)


## Named _apply_emission, not _set — Object._set already exists and shadowing
## it silently breaks property assignment on this node.
func _apply_emission(mat: Variant, value: float) -> void:
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("emission_strength", value)
	elif mat is StandardMaterial3D:
		(mat as StandardMaterial3D).emission_energy_multiplier = value


func _sci(v: float) -> String:
	if absf(v) < 1e-12:
		return "0.0e+00"
	var e: int = int(floor(log(absf(v)) / log(10.0)))
	var m: float = v / pow(10.0, float(e))
	return "%.2fe%s%02d" % [m, "+" if e >= 0 else "-", absi(e)]


# --- pieces ---------------------------------------------------------------

func _sphere(pos: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 7
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	return mi


func _strut(a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.001)
	cyl.radial_segments = 5
	cyl.rings = 1
	mi.mesh = cyl
	var dir: Vector3 = (b - a)
	if dir.length() < 0.0001:
		dir = Vector3.UP
	dir = dir.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (a + b) * 0.5)
	mi.material_override = mat
	return mi


# --- material -------------------------------------------------------------

func _witness_mat() -> Material:
	return _grid_material(Color(0.26, 0.28, 0.34), Color(0.40, 0.45, 0.55), 0.35)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	fallback.emission_enabled = true
	fallback.emission = wire
	fallback.emission_energy_multiplier = emit
	return fallback


func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_error_label = null
	_build_all()


## Grid config. Keys: "activation", "learning_rate", "pulse_period",
## "gradient_gain", "rng_seed", "layer_sizes" (an Array of ints). Only the
## structural keys rebuild — curation_station hands every artifact it curates
## {"emissive": false} right after framing its labels, and rebuilding on that
## would throw the framing away.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_act: String = activation
	var before_seed: int = rng_seed
	var before_sizes: PackedInt32Array = layer_sizes.duplicate()

	if config_data.has("activation"):
		activation = _pick_axis(str(config_data["activation"]), ACTIVATIONS, activation)
	if config_data.has("learning_rate"):
		learning_rate = float(config_data["learning_rate"])
	if config_data.has("pulse_period"):
		pulse_period = maxf(float(config_data["pulse_period"]), 0.3)
	if config_data.has("gradient_gain"):
		gradient_gain = float(config_data["gradient_gain"])
	if config_data.has("rng_seed"):
		rng_seed = int(config_data["rng_seed"])
	if config_data.has("layer_sizes"):
		var raw: Array = config_data["layer_sizes"]
		var packed := PackedInt32Array()
		for v in raw:
			var n: int = int(v)
			if n > 0:
				packed.append(n)
		if packed.size() >= 2:
			layer_sizes = packed

	if not _built:
		return
	if activation == before_act and rng_seed == before_seed and layer_sizes == before_sizes:
		return
	_rebuild_now()
