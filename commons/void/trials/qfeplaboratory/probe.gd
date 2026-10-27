extends "res://tools/probes/void_transfer_probe.gd"

func focused_checks(tag: String) -> void:
	var panel:Node3D=artifact("tt")
	check(tag+"tutorial ID preserved (source content missing)",panel.current_tutorial_id==("qfep_introduction" if level==1 else "free_energy"))
	if level==1:
		var bench:Node3D=artifact("qfep_balance_workbench")
		check(tag+"original comparison mode and four rails",bench.comparison and bench._sliders.size()==4)
		await approach(bench)
		await press(bench._keep_button)
		check(tag+"KEEP via real pointer records all four components",bench._kept.size()==4 and bench._kept_outline.visible)
		var kept:Array=bench._kept.duplicate()
		bench._sliders[0].set_normalized_value(.85);await frames(20)
		check(tag+"slider API changes live reading but keeps reference",bench._kept==kept and absf(bench._F-.85)<.01)
		# The same hand-sized source scene has three semantic identities.
		for key in ["grab_sphere_F","grab_sphere_E","grab_sphere_lambda"]:
			var term:Node3D=artifact(key)
			check(tag+key+" retains pickup and term identity",term.has_method("pick_up") and str(term.get_meta("artifact_lookup_name"))==key)
	else:
		var bench:Node3D=artifact("shannon_workbench")
		check(tag+"prediction mode and authored p",bench.prediction_study and is_equal_approx(bench._p,.1))
		var before:Dictionary=bench.prediction_reading()
		var draws:Array=Array(bench._draws).duplicate()
		await approach(bench)
		await press(bench._prediction_buttons[1])
		var after:Dictionary=bench.prediction_reading()
		check(tag+"EXPECT 1 via real pointer changes prediction only",after.prediction==1 and Array(bench._draws)==draws and after.source_h==before.source_h and is_equal_approx(after.expected_error,.9))
		await press(bench._prediction_buttons[0])
		check(tag+"EXPECT 0 restores original error on same sample",bench.prediction_reading()==before and Array(bench._draws)==draws)

func capture_floor() -> void:
	await super.capture_floor()
	var bench:Node3D=artifact("qfep_balance_workbench" if level==1 else "shannon_workbench")
	await photo("%02d-original-workbench"%(level*2),bench.to_global(Vector3(2.8,2.4,4)),bench.to_global(Vector3(0,1.2,0)))
