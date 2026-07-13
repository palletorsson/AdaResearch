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

	# Body — a softly squashed pink blob.
	var blob := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BLOB_RADIUS
	sphere.height = BLOB_RADIUS * 1.7  # squashed — rounder than tall
	blob.mesh = sphere
	blob.set_surface_override_material(0, body_mat)
	mesh_root.add_child(blob)

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

	# Legs — spider silhouette after the octapod stage. Two bent segments per
	# leg, proportions from octapod_crawler (leg_length 0.35 at its scale).
	var leg_count: int = int(stage.get("legs", 0))
	if leg_count > 0:
		var leg_mat := StandardMaterial3D.new()
		leg_mat.albedo_color = PINK_BODY.darkened(0.25)
		for i in range(leg_count):
			var angle: float = TAU * float(i) / float(leg_count) + TAU / 16.0
			var leg_root := Node3D.new()
			leg_root.name = "Leg%d" % i
			leg_root.position = Vector3(cos(angle) * BLOB_RADIUS * 0.8, -0.02, sin(angle) * BLOB_RADIUS * 0.8)
			leg_root.rotation.y = -angle
			mesh_root.add_child(leg_root)

			var upper := MeshInstance3D.new()
			var um := CapsuleMesh.new()
			um.radius = 0.014
			um.height = 0.2
			upper.mesh = um
			upper.set_surface_override_material(0, leg_mat)
			upper.position = Vector3(0.08, 0.03, 0)
			upper.rotation_degrees = Vector3(0, 0, -55)
			leg_root.add_child(upper)

			var lower := MeshInstance3D.new()
			var lm := CapsuleMesh.new()
			lm.radius = 0.011
			lm.height = 0.18
			lower.mesh = lm
			lower.set_surface_override_material(0, leg_mat)
			lower.position = Vector3(0.17, -0.05, 0)
			lower.rotation_degrees = Vector3(0, 0, 30)
			leg_root.add_child(lower)
			refs["legs"].append(leg_root)

	mesh_root.scale = Vector3.ONE * float(stage.get("scale", 1.0))
	return refs
