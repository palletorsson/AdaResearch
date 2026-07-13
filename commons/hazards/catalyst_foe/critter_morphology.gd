# critter_morphology.gd
# The catalyst foe's evolving body — ONE pink critter across the spine.
#
# Before color (soft_stages order <= 4) the foe is the legacy grey lab cube.
# After color the critter hatches and grows with the curriculum:
#   mote    (order > 4)   — tiny legless pink blob, hovers, cute, pops on contact
#   serpent (order >= 6)  — wavefunctions: it swims through the air in a sine wave
#   octapod (order >= 7)  — randomness: lands, grows 8 legs — the spider silhouette
#                           borrowed from octapod_crawler (cheap cylinders here;
#                           the full IK rig in octapod_ik.tscn is a future swap-in)
#   many    (order >= 9)  — cellular automata: vents emit double waves
#   grand   (order >= 10) — fractals onward: it is simply bigger
#
# Stage traits are CUMULATIVE (a grand critter still has legs and pops).
# Pure static helpers — CatalystFoe owns state; this file owns geometry + table.

extends RefCounted

const PINK_BODY := Color(0.93, 0.28, 0.60)
const PINK_GLOW := Color(1.0, 0.52, 0.74)
const BLOB_RADIUS := 0.16

# The blob surface reuses the catalyst orb's vertex-noise shader (a
# 3D-simplex-displaced breathing sphere) with a pink palette.
const ORB_NOISE_SHADER := preload("res://commons/hazards/becoming_catalyst/orb_noise.gdshader")
# Plant-and-step leg rig (gait ported from the six_leg hexapod).
const CritterLegs := preload("res://commons/hazards/catalyst_foe/critter_legs.gd")


## Stage traits for a soft_stages order value. order <= 4 → legacy cube.
static func stage_for(order: float) -> Dictionary:
	if order <= 4.0:
		return {
			"name": "cube", "scale": 1.0, "flying": false, "hover": 0.0,
			"legs": 0, "wave": false, "jitter": 0.0, "wave_mult": 1, "pop": false,
		}
	var s: Dictionary = {
		"name": "mote", "scale": 1.0, "flying": true, "hover": 0.55,
		"legs": 0, "wave": false, "jitter": 0.0, "wave_mult": 1, "pop": true,
	}
	if order >= 6.0:
		s["name"] = "serpent"
		s["wave"] = true
		s["scale"] = 1.25
	if order >= 7.0:
		s["name"] = "octapod"
		s["flying"] = false
		s["wave"] = false
		s["hover"] = 0.0
		s["legs"] = 8
		s["scale"] = 1.9
		s["jitter"] = 0.6
	if order >= 9.0:
		s["name"] = "many"
		s["wave_mult"] = 2
	if order >= 10.0:
		s["name"] = "grand"
		s["scale"] = 2.8
	return s


## Build the critter body onto mesh_root using the shared body material.
## Returns animatable refs: {"legs": Array[Node3D], "eyes": Array[Node3D]}.
static func build(mesh_root: Node3D, body_mat: StandardMaterial3D, stage: Dictionary) -> Dictionary:
	var refs: Dictionary = {"legs": [], "eyes": []}

	# Body — a softly squashed pink blob, breathing via the orb's
	# vertex-noise shader (organic wobble, palette mixed by the noise).
	var blob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BLOB_RADIUS
	sphere.height = BLOB_RADIUS * 1.7  # squashed — rounder than tall
	sphere.radial_segments = 48
	sphere.rings = 24
	blob.mesh = sphere
	var blob_mat := ShaderMaterial.new()
	blob_mat.shader = ORB_NOISE_SHADER
	blob_mat.set_shader_parameter("palette_a", PINK_BODY.darkened(0.15))
	blob_mat.set_shader_parameter("palette_b", PINK_BODY)
	blob_mat.set_shader_parameter("palette_c", Color(1.0, 0.74, 0.86))
	blob_mat.set_shader_parameter("noise_scale", 6.0)
	blob_mat.set_shader_parameter("noise_amount", 0.045)
	blob_mat.set_shader_parameter("time_scale", 0.9)
	blob_mat.set_shader_parameter("emission_energy", 1.1)
	blob_mat.set_shader_parameter("halo_softness", 0.3)
	blob.set_surface_override_material(0, blob_mat)
	mesh_root.add_child(blob)
	refs["blob_mat"] = blob_mat
	# body_mat still tints eyes-adjacent accents + the friend badge; the
	# blob itself is shader-driven (personality tints go via set_blob_tint).

	# Eyes — oversized, front-facing (+Z is the facing direction).
	var eye_white := StandardMaterial3D.new()
	eye_white.albedo_color = Color(0.98, 0.97, 0.99)
	var eye_dark := StandardMaterial3D.new()
	eye_dark.albedo_color = Color(0.12, 0.10, 0.16)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.045
		em.height = 0.09
		eye.mesh = em
		eye.set_surface_override_material(0, eye_white)
		eye.position = Vector3(side * 0.065, 0.035, BLOB_RADIUS * 0.82)
		mesh_root.add_child(eye)
		var pupil := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = 0.022
		pm.height = 0.044
		pupil.mesh = pm
		pupil.set_surface_override_material(0, eye_dark)
		pupil.position = Vector3(0, 0, 0.032)
		eye.add_child(pupil)
		refs["eyes"].append(eye)

	# Blush — two flat darker-pink discs on the cheeks.
	var blush_mat := StandardMaterial3D.new()
	blush_mat.albedo_color = Color(0.85, 0.18, 0.45)
	for side in [-1.0, 1.0]:
		var blush := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.03
		bm.bottom_radius = 0.03
		bm.height = 0.004
		blush.mesh = bm
		blush.set_surface_override_material(0, blush_mat)
		blush.position = Vector3(side * 0.12, -0.02, BLOB_RADIUS * 0.62)
		blush.rotation_degrees = Vector3(90, 0, side * -20)
		mesh_root.add_child(blush)

	# Legs — the plant-and-step rig (gait ported from the six_leg hexapod;
	# feet stay planted in the world while the body moves, then lift and
	# step). Self-driving: it reads the body's velocity and ground height.
	var leg_count: int = int(stage.get("legs", 0))
	if leg_count > 0:
		var legs = CritterLegs.new()
		legs.name = "GaitRig"
		legs.leg_count = leg_count
		mesh_root.add_child(legs)
		refs["legs_node"] = legs

	mesh_root.scale = Vector3.ONE * float(stage.get("scale", 1.0))
	return refs


## Retint the shader blob (personality arc / friend hue). No-op on the
## legacy cube (no blob_mat in refs).
static func set_blob_tint(refs: Dictionary, tint: Color, energy: float) -> void:
	var bm = refs.get("blob_mat")
	if bm is ShaderMaterial:
		var mat := bm as ShaderMaterial
		mat.set_shader_parameter("palette_a", tint.darkened(0.15))
		mat.set_shader_parameter("palette_b", tint)
		mat.set_shader_parameter("palette_c", tint.lightened(0.4))
		mat.set_shader_parameter("emission_energy", energy)
