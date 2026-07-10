# ProximityLOD.gd — the computation budget for dense generated maps.
# Palle (on the CA hall): "they become computation heavy... individual maps
# do not pack all cellular automata processes in one big map."
#
# GATED by map settings.proximity_lod (mission halls/rooms emit it; hand-made
# maps are untouched — no flag, no manager). Artifacts beyond `radius` of the
# current camera get process_mode DISABLED (sims freeze, visuals keep their
# last built frame); they wake when the player comes back inside. Headless
# runs have no camera -> nothing ever freezes, so captures and probes see
# fully-built artifacts.
#
# Grace period lets _ready/deferred procedural builds finish before the first
# freeze. Opt out per artifact: config proximity_lod:false.
extends Node

var radius: float = 14.0
var hysteresis: float = 2.0
var grace_s: float = 3.0


func configure(cfg) -> void:
	if cfg is Dictionary:
		radius = float(cfg.get("radius", radius))
		hysteresis = float(cfg.get("hysteresis", hysteresis))
		grace_s = float(cfg.get("grace_s", grace_s))


func _ready() -> void:
	var t := Timer.new()
	t.wait_time = 0.4
	t.autostart = true
	t.timeout.connect(_tick)
	add_child(t)


func _tick() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return                          # headless / no player: never freeze
	var now: float = Time.get_ticks_msec() / 1000.0
	for n in get_tree().get_nodes_in_group("vr_editable_artifact"):
		if not (n is Node3D) or not is_instance_valid(n):
			continue
		if n.has_meta("config_proximity_lod") \
				and str(n.get_meta("config_proximity_lod")).to_lower() in ["false", "0", "off"]:
			continue
		if not n.has_meta("plod_born"):
			n.set_meta("plod_born", now)
			continue
		if now - float(n.get_meta("plod_born")) < grace_s:
			continue                    # let procedural _ready builds finish
		var d: float = cam.global_position.distance_to(n.global_position)
		if n.process_mode != Node.PROCESS_MODE_DISABLED and d > radius + hysteresis:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		elif n.process_mode == Node.PROCESS_MODE_DISABLED and d < radius - hysteresis:
			n.process_mode = Node.PROCESS_MODE_INHERIT
