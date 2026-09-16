from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
src=ROOT/'doc/space/randomness-dna-2026-09-16'
out=ROOT/'doc/space/entropy-ruin-2026-09-16'
s=(src/'probe.gd').read_text(encoding='utf-8').replace('randomness-dna-2026-09-16','entropy-ruin-2026-09-16')
insert='''
	if found.has("entropy_ruin"):
		var ruin: Node3D=found.entropy_ruin
		player.global_position=ruin.global_position+Vector3(0,5,-3)
		ruin.process_mode=Node.PROCESS_MODE_INHERIT; ruin.show()
		ruin.restore()
		check(ruin.pieces.size()==116,"Ruin retains 116 pieces")
		await capture_state(em,ruin.global_position+Vector3(-4.3,2.2,-6.5),ruin.global_position+Vector3(0,1.5,0),"ruin-intact")
		# Operate the real compact button rather than bypassing its wiring.
		var stage: Node3D=ruin.get_node("ExhibitStage/ReachConsole")
		var step: Node=stage.find_child("Btn_1",true,false)
		for i in range(46): step.get_node("InteractableAreaButton").emit_signal("button_pressed",step)
		check(ruin.history.size()==46,"Reachable ONE STONE button changes construction")
		await capture_state(em,ruin.global_position+Vector3(-4.3,2.2,-6.5),ruin.global_position+Vector3(0,1.5,0),"ruin-weathered")
		var damaged: Array=ruin.history.duplicate()
		var reset: Node=stage.find_child("Btn_2",true,false)
		reset.get_node("InteractableAreaButton").emit_signal("button_pressed",reset)
		check(ruin.history.is_empty() and not ruin.running,"Reachable RESTORE returns intact, paused")
		for i in range(46): ruin.weather_one()
		check(ruin.history==damaged,"Museum replay restores selected stone sequence")
		for offset in [Vector3(-6.5,0.4,0),Vector3(6.5,0.4,0),Vector3(0,0.4,-3.2),Vector3(0,0.4,3)]:
			var start: Vector3=ruin.global_position+offset
			var hit=em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,2,0)))
			check(not hit.is_empty(),"Ruin approach and bypass remain supported")
'''
s=s.replace('\tawait exercise(found,player,em)',insert+'\n\tawait exercise(found,player,em)')
(out/'probe.gd').write_text(s,encoding='utf-8')
(out/'run_probe.py').write_text((src/'run_probe.py').read_text(encoding='utf-8').replace('randomness-dna-2026-09-16','entropy-ruin-2026-09-16'),encoding='utf-8')
