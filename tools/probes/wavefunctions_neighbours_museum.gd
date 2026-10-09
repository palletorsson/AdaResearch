extends "res://tools/probes/wavefunctions_lessons_museum.gd"

func clear_approach(owner: Node3D, at: Vector3, title: String) -> void:
    check(title+" has floor",not floor_at(at).is_empty())
    var capsule := CapsuleShape3D.new()
    capsule.radius=0.26;capsule.height=1.6
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.91)
    query.collision_mask=1|4
    var obstacles: Array=[]
    for hit in hall.get_world_3d().direct_space_state.intersect_shape(query):
        if hit.collider!=museum.get("_player") and not owner.is_ancestor_of(hit.collider):obstacles.append(str(hit.collider.get_path()))
    check(title+" is unobstructed",obstacles.is_empty())
    observations[title]=obstacles

func landing_checks() -> void:
    await super.landing_checks()
    var lattice := find_scene("/coupled_oscillator_lattice.gd")
    var tiles := find_scene("/WavePropagation3D.gd")
    var sculpture := find_scene("/kusamasine/kusama.gd")
    check("main lattice, tile field and sculpture retained",lattice!=null and tiles!=null and sculpture!=null)
    if lattice==null or tiles==null or sculpture==null:return
    var origin := hall.global_position+Vector3(0,0,4)
    for p in [Vector3(11.5,0,2.5),Vector3(11.5,0,10.5),Vector3(11.5,0,15),Vector3(3,0,16),Vector3(3,0,22),Vector3(3,0,31),Vector3(11.5,0,33.5)]:
        clear_approach(lattice,origin+p,"route "+str(p))
    var panel: Node3D=lattice._comparison_panel
    var approach: Vector3=panel.to_global(Vector3(0,0,0.8))
    approach.y=origin.y
    clear_approach(lattice,approach,"coupling controls")
    check("actual buttons are within hand height",lattice.buttons.COUPLING.global_position.y-origin.y>0.8 and lattice.buttons.COUPLING.global_position.y-origin.y<1.1)
    check("lattice has all 144 original points",lattice.oscillators.size()==144)
    check("interior has eight and corner three neighbours",lattice._get_neighbors(Vector2(6,6)).size()==8 and lattice._get_neighbors(Vector2.ZERO).size()==3)
    check("bond drawing includes diagonals without duplicates",lattice._bond_pairs.size()==506)
    var all_drawn := true
    for i in range(lattice.oscillators.size()):
        for j in lattice._get_neighbors(lattice.oscillators[i].grid_pos):
            if j>i:all_drawn=all_drawn and lattice._bond_pairs.has(Vector2i(i,j))
    check("every force relation has one drawn bond",all_drawn)
    lattice.set_process(false)
    lattice.buttons.DRIVE.pressed.emit()
    check("actual drive button selects pulse and resets state",lattice.excitation_mode=="Pulse" and lattice.time==0 and lattice.oscillators.all(func(o):return o.velocity==0 and o.displacement==0))
    for i in range(480):lattice.comparison_step(1.0/120)
    lattice._update_visualization();lattice._refresh_comparison()
    var coupled_peak: float=lattice._neighbor_peak
    check("one pulse reaches an immediate neighbour",coupled_peak>0.01)
    check("parts retain horizontal grid addresses",lattice.oscillators.all(func(o):return lattice.get_node("Oscillator_%d" % o.index).position.x==o.position.x and lattice.get_node("Oscillator_%d" % o.index).position.z==o.position.z))
    await snapshot("lattice",lattice.to_global(Vector3(4.8,3.3,4.3)),lattice.to_global(Vector3(0.2,0.8,0)),64)
    await snapshot("controls",panel.to_global(Vector3(0.1,1.7,2.1)),panel.to_global(Vector3(0,1.05,0)),55)
    lattice.buttons.COUPLING.pressed.emit()
    check("actual disconnect button restarts the comparison",lattice.time==0 and lattice.coupling_strength==0 and lattice.oscillators.all(func(o):return o.velocity==0 and o.displacement==0))
    check("drawn links disappear when disconnected",not lattice._bond_mm.visible)
    for i in range(480):lattice.comparison_step(1.0/120)
    check("independent neighbour remains exactly still",lattice._neighbor_peak==0)
    check("independent source receives the same pulse",lattice.pulse_triggered and lattice.oscillators.filter(func(o):return o.displacement!=0).size()==1)
    lattice.buttons.COUPLING.pressed.emit()
    check("reconnecting restores strength and visible bonds",lattice.coupling_strength==1.5 and lattice._bond_mm.visible)
    lattice.buttons.DRIVE.pressed.emit()
    check("drive returns to original sine mode",lattice.excitation_mode=="Sine")
    lattice.buttons.RESET.pressed.emit()
    check("reset clears peak, simulation clock and drive state",lattice._neighbor_peak==0 and lattice.time==0 and not lattice.pulse_triggered)
    lattice.set_process(true)
    check("tile field has a separate rear bay",absf(tiles.global_position.z-lattice.global_position.z)>14)
    check("tile exhibit uses the museum camera and light",tiles.museum_environment and tiles.get_children().all(func(c):return not c is Camera3D and not c is Light3D))
    var standalone = load("res://algorithms/wavefunctions/wave_propagation_3d/wave_propagation_3d.tscn").instantiate()
    check("standalone tiled field retains its own environment",not standalone.museum_environment and standalone.has_node("Camera3D") and standalone.has_node("DirectionalLight3D"))
    standalone.free()
    check("sculpture has a separate side bay",absf(sculpture.global_position.x-lattice.global_position.x)>11)
    tiles.set_process(false)
    tiles.time=1.4;tiles.animate_controls();tiles.animate_3d_wave_propagation()
    check("radial field retains four hundred tiles",tiles.tile_collision_bodies.size()==400)
    var match_collision := true
    var above_floor := true
    for i in range(tiles.tile_collision_bodies.size()):
        var p: Vector3=tiles.tile_multimesh.get_instance_transform(i).origin
        match_collision=match_collision and p.is_equal_approx(tiles.tile_collision_bodies[i].position)
        above_floor=above_floor and tiles.tile_collision_bodies[i].global_position.y-origin.y>0.15
    check("tile collision follows its separate displayed rule",match_collision)
    check("tile troughs remain visible above museum floor",above_floor)
    await snapshot("tiles",tiles.to_global(Vector3(-5,5,-8)),tiles.to_global(Vector3(0,0.1,0)),72)
    tiles.set_process(true)
    await snapshot("gallery",origin+Vector3(2,15,1),origin+Vector3(12,0,19),73)
    observations.coupling={"coupled_neighbour_peak_m":coupled_peak,"independent_neighbour_peak_m":0,"unique_bonds":506,"original_force_rule_unchanged":true}
    observations.scope="Actual museum controls, relation drawing, supported viewing positions, and exact printed study placed in the hall. Teacher-authored native checks; no independent ghost or headset claim."

func study_checks(spec: Dictionary) -> void:
    var lesson=load(spec.lesson).new()
    lesson.position=Vector3(12,0,11);lesson.rotation.y=PI;lesson.running=false
    hall.add_child(lesson)
    await tick()
    clear_approach(lesson,lesson.to_global(Vector3(0,0,2)),"student view")
    check("printed program builds complete row in the museum",lesson.points.size()==9 and lesson.links.size()==8 and lesson.label.is_inside_tree())
    for i in range(24):lesson.step(1.0/60)
    lesson.draw_state()
    check("student neighbours respond symmetrically in museum",absf(lesson.displacement[3]-lesson.displacement[5])<0.00001 and absf(lesson.displacement[3])>0.01)
    var eye: Vector3=lesson.to_global(Vector3(1.2,2.3,4.0))
    var target: Vector3=lesson.to_global(Vector3(0,1.7,0))
    var query := PhysicsRayQueryParameters3D.create(eye,target,1)
    check("student row sightline clear",hall.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
    await snapshot("student",eye,target,69)
    observations.lesson=spec.lesson
    observations.bay=[12,0,11]
    observations.bay_yaw_degrees=180
    lesson.queue_free()
    await tick()
