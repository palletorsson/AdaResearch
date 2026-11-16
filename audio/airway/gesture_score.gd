extends RefCounted
## A score of gestures. A gesture drives some controls (articulators, or the breath, pitch, vibrato and
## the folds' opening) toward targets over a stretch of time, with smooth ramps and a strength. At each
## control step a control's target is the mean of the active gestures' targets weighted by strength.
## Consonants are short and strong on their own articulators; vowels are long and overlap, so the tongue
## keeps moving from vowel to vowel through the consonants.
##
## A GDScript port of Chimera's gestural score, (c) 2026 Jameson Hodge, MIT licence (audio/airway/LICENSE.chimera).

const Tract := preload("res://audio/airway/human_tract.gd")
const N_ARTIC := 17
const N_CONTROL := 22
const ABDUCTION := 17
const CLOSURE := 18
const BREATH := 19
const F0 := 20
const VIBRATO := 21
const SOURCE_NAMES: Array[String] = ["abduction", "closure", "breath", "f0", "vibrato"]

var t0 := PackedFloat64Array()
var t1 := PackedFloat64Array()
var ramp_in := PackedFloat64Array()
var ramp_out := PackedFloat64Array()
var strength := PackedFloat64Array()
## NAN where a gesture names no speed, no tag
var speed := PackedFloat64Array()
var hold := PackedFloat64Array()
var tag := PackedFloat64Array()
var keys: Array[PackedInt32Array] = []
var values: Array[PackedFloat64Array] = []
var labels: Array[String] = []
var end := 0.0

var value := PackedFloat64Array()
var weight := PackedFloat64Array()
var speed_of := PackedFloat64Array()


func _init() -> void:
	value.resize(N_CONTROL)
	weight.resize(N_CONTROL)
	speed_of.resize(N_CONTROL)


static func key_index(key_name: String) -> int:
	var i := Tract.NAMES.find(key_name)
	if i >= 0: return i
	i = SOURCE_NAMES.find(key_name)
	return N_ARTIC + i if i >= 0 else -1


## A gesture as a Dictionary: t0, t1, rampIn, rampOut, strength, targets {name: value}, and optionally
## speed, releaseHold, label, tag. `offset` is added to its times.
func add(g: Dictionary, offset := 0.0) -> void:
	var ks := PackedInt32Array()
	var vs := PackedFloat64Array()
	var targets: Dictionary = g.get("targets", {})
	var found := {}
	for key in targets:
		var i := key_index(str(key))
		if i >= 0 and targets[key] != null: found[i] = float(targets[key])
	var order := found.keys()
	order.sort()
	for i in order:
		ks.append(int(i))
		vs.append(float(found[i]))
	t0.append(float(g.get("t0", 0.0)) + offset)
	t1.append(float(g.get("t1", 0.0)) + offset)
	ramp_in.append(float(g.get("rampIn", 0.0)))
	ramp_out.append(float(g.get("rampOut", 0.0)))
	strength.append(float(g.get("strength", 1.0)))
	speed.append(float(g["speed"]) if g.get("speed") != null else NAN)
	hold.append(float(g["releaseHold"]) if g.get("releaseHold") != null else 0.0)
	tag.append(float(g["tag"]) if g.get("tag") != null else NAN)
	keys.append(ks)
	values.append(vs)
	labels.append(str(g.get("label", "")))
	var i := t0.size() - 1
	end = maxf(end, t1[i] + ramp_out[i] + hold[i])


func add_all(list: Array, offset := 0.0) -> void:
	for g in list: add(g, offset)


func clear() -> void:
	_keep(PackedInt32Array())
	end = 0.0


func size() -> int: return t0.size()


func _keep(rows: PackedInt32Array) -> void:
	var n_t0 := PackedFloat64Array()
	var n_t1 := PackedFloat64Array()
	var n_in := PackedFloat64Array()
	var n_out := PackedFloat64Array()
	var n_strength := PackedFloat64Array()
	var n_speed := PackedFloat64Array()
	var n_hold := PackedFloat64Array()
	var n_tag := PackedFloat64Array()
	var n_keys: Array[PackedInt32Array] = []
	var n_values: Array[PackedFloat64Array] = []
	var n_labels: Array[String] = []
	for i in rows:
		n_t0.append(t0[i])
		n_t1.append(t1[i])
		n_in.append(ramp_in[i])
		n_out.append(ramp_out[i])
		n_strength.append(strength[i])
		n_speed.append(speed[i])
		n_hold.append(hold[i])
		n_tag.append(tag[i])
		n_keys.append(keys[i])
		n_values.append(values[i])
		n_labels.append(labels[i])
	t0 = n_t0
	t1 = n_t1
	ramp_in = n_in
	ramp_out = n_out
	strength = n_strength
	speed = n_speed
	hold = n_hold
	tag = n_tag
	keys = n_keys
	values = n_values
	labels = n_labels


## Smooth activation 0..1..0 with cosine ramps.
func activation(i: int, t: float) -> float:
	if t <= t0[i] - ramp_in[i] or t >= t1[i] + ramp_out[i]: return 0.0
	if t < t0[i]:
		return 0.5 - 0.5 * cos(PI * ((t - (t0[i] - ramp_in[i])) / maxf(1e-6, ramp_in[i])))
	if t > t1[i]:
		return 0.5 + 0.5 * cos(PI * ((t - t1[i]) / maxf(1e-6, ramp_out[i])))
	return 1.0


## End every gesture with this tag at time t: one not yet begun is dropped, one still ramping in turns
## round from its present activation, one at full strength starts its ramp-out now.
func release(which: float, t: float) -> void:
	var rows := PackedInt32Array()
	for i in t0.size():
		if tag[i] != which or t > t0[i] - ramp_in[i]: rows.append(i)
	_keep(rows)
	for i in t0.size():
		if tag[i] != which or t1[i] <= t: continue
		if t < t0[i]:
			var a := activation(i, t)
			var w := acos(minf(1.0, maxf(-1.0, 2.0 * a - 1.0))) / PI
			t1[i] = t - w * maxf(1e-6, ramp_out[i])
			t0[i] = t1[i]
		else:
			t1[i] = t
	end = 0.0
	for i in t0.size(): end = maxf(end, t1[i] + ramp_out[i] + hold[i])


## Drop gestures wholly finished before t.
func prune(t: float) -> void:
	if t0.is_empty(): return
	var rows := PackedInt32Array()
	for i in t0.size():
		if t1[i] + ramp_out[i] + hold[i] > t: rows.append(i)
	if rows.size() != t0.size(): _keep(rows)


## Blend every control at time t into `value`, `weight`, `speed_of`.
func blend_all(t: float) -> void:
	value.fill(0.0)
	weight.fill(0.0)
	speed_of.fill(1.0)
	for i in t0.size():
		var lo := t0[i] - ramp_in[i]
		var gs := speed[i]
		var in_speed := not is_nan(gs) and gs != 0.0 and t >= lo and t <= t1[i] + ramp_out[i] + hold[i]
		var act := 0.0
		if not (t <= lo or t >= t1[i] + ramp_out[i]):
			if t < t0[i]: act = 0.5 - 0.5 * cos(PI * ((t - lo) / maxf(1e-6, ramp_in[i])))
			elif t > t1[i]: act = 0.5 + 0.5 * cos(PI * ((t - t1[i]) / maxf(1e-6, ramp_out[i])))
			else: act = 1.0
		if act <= 0.0 and not in_speed: continue
		var w := act * strength[i]
		var ks := keys[i]
		var vs := values[i]
		for q in ks.size():
			var key := ks[q]
			if in_speed and gs > speed_of[key]: speed_of[key] = gs
			if act <= 0.0: continue
			weight[key] += w
			value[key] += w * vs[q]
	for key in N_CONTROL:
		value[key] = value[key] / weight[key] if weight[key] > 0.0 else 0.0
