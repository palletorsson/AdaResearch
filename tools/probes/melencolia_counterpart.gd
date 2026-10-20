extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var tableau := find_scene("/EngravingScene.gd")
	check("actual Durer tableau found in the museum", tableau != null)
	if tableau == null: return
	await snapshot("melencolia-before", tableau.to_global(Vector3(0.2, 2.4, 7.8)), tableau.to_global(Vector3(0, 2.2, 0)), 59)
	var skull: CharacterBody3D = load("res://commons/hazards/catalyst_counterpart/tableau_preview.gd").mount(tableau)
	check("same counterpart script supplies the first sighting", skull != null and str(skull.get_script().resource_path).ends_with("/flying_skull.gd"))
	if skull == null: return
	check("seated figure hidden only in this preview", not tableau.get_node("Melencolia").visible)
	check("old figure no longer leaves an invisible body", tableau.get_node("Melencolia/SeatedBody").collision_layer == 0)
	check("historical instruments and solid retained", tableau.groups.has("MagicSquare") and tableau.groups.has("Polyhedron") and tableau.groups.has("Sphere"))
	var at: Transform3D = skull.global_transform
	await create_timer(1.2).timeout
	check("skull remains absolutely stationary", skull.global_transform.is_equal_approx(at))
	check("only its pale fire moves", skull.flame.emitting and skull.flame.amount == 48 and not skull.is_physics_processing())
	check("first sighting cannot attack or block passage", not skull.active and skull.collision_layer == 0 and skull.collision_mask == 0 and skull.tags == 0)
	await snapshot("melencolia-burning-counterpart", tableau.to_global(Vector3(0.2, 2.4, 7.8)), tableau.to_global(Vector3(0, 2.2, 0)), 59)
	await snapshot("melencolia-skull-close", tableau.to_global(Vector3(1.5, 2.6, 3.0)), skull.global_position + Vector3.UP * 0.05, 53)
	observations["scope"] = "Test-only Durer substitution in the actual museum. The authored map is unchanged. Motion and defence begin in the Transformation trial."
