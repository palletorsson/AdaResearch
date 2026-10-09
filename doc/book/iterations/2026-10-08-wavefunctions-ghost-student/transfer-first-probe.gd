extends SceneTree

# New applications of the printed lessons. Predictions were saved before this run.
# This is an author-made executable reading, not evidence of independent learning.
const BASE = "res://doc/book/iterations/2026-10-08-wavefunctions-ghost-student/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}

func _initialize() -> void:
    call_deferred("run")

func check(hall: String, claim: String, passed: bool) -> void:
    checks.append({"hall": hall, "claim": claim, "passed": passed})
    if not passed:
        failures.append(hall + ": " + claim)
        print("FAIL ", hall, ": ", claim)

func study(hall: String, file: String = "transfer.gd") -> Node3D:
    var node = load(BASE + "attempt/" + hall + "/" + file).new()
    root.add_child(node)
    node.set_process(false)
    node.set_physics_process(false)
    return node

func near(a: float, b: float, tolerance: float = 0.00001) -> bool:
    return absf(a - b) < tolerance

func settle() -> void:
    for i in range(5):
        await physics_frame
        await process_frame

func run() -> void:
    var hall := "WaveFunctions_Intro"
    var n = study(hall)
    check(hall,"changed recipe starts at top and reaches bottom after two seconds",near(n.height_at(0),1.55) and near(n.height_at(2),1.05))
    check(hall,"four-second period holds away from the named sample points",near(n.height_at(0.37),n.height_at(4.37)))
    n._process(0.37)
    check(hall,"actual constructed cube displays the predicted height",near(n.cube.position.y,n.height_at(0.37)) and n.label.text != "")
    n.free()

    hall = "WaveFunctions_Pendulum"
    n = study(hall)
    var original = study(hall,"02_pendulum_record.gd")
    for i in range(480):
        n._physics_process(1.0/60.0)
        original._physics_process(1.0/60.0)
    var span: float = n.history[-1].time - n.history[0].time
    check(hall,"20 slots limit duration at .1-second sampling",n.history.size()==20 and absf(span-1.9)<0.035)
    check(hall,"recording changes leave the pendulum state identical",near(n.angle,original.angle) and near(n.angular_velocity,original.angular_velocity))
    var sample = n.history[0]
    var stored: Vector3 = sample.position
    var short_depth: Vector3 = n.display_position(sample)-stored
    n.trail_speed=0.6
    check(hall,"drawing speed doubles depth without changing the observation",(n.display_position(sample)-stored).is_equal_approx(short_depth*2) and sample.position==stored)
    observations.pendulum={"count":n.history.size(),"oldest_to_newest_seconds":span}
    n.free();original.free()

    hall = "WaveFunctions_Sine_Space"
    n = study(hall)
    check(hall,"separate axis frequencies give the predicted crest and baseline",near(n.height_at(0.5,0.25),0.98) and near(n.height_at(0,0.25),0.8))
    check(hall,"X repeats after two metres and Z after one",near(n.height_at(0.27,0.13),n.height_at(2.27,0.13)) and near(n.height_at(0.27,0.13),n.height_at(0.27,1.13)))
    check(hall,"new rule reuses grid connectivity and its collision receiver",n.points.size()==289 and n.faces.size()==512 and n.boundary.shape is ConcavePolygonShape3D)
    n.free()

    hall = "WaveFunctions_Unit_Circle"
    n = study(hall)
    n._process(0.5)
    check(hall,"changed speed and radius put the point at the predicted top",n.point.position.is_equal_approx(Vector3(-0.4,2.2,0)))
    check(hall,"graph shares vertical height but retains its four-metre angle axis",near(n.marker.position.y,n.point.position.y) and near(n.graph_position(TAU).x-n.graph_position(0).x,4))
    check(hall,"circle radius remains measured from its moved centre",near(n.circle_position(0.77).distance_to(n.centre),0.6))
    n.free()

    hall = "WaveFunctions_3D_Wave_Propagation"
    n = study(hall)
    var reversed = study(hall,"reverse.gd")
    n.step(1.0/60.0);reversed.step(1.0/60.0)
    check(hall,"first step matches the hand-calculated centre velocity and displacement",near(n.velocity[3],-0.14) and near(n.displacement[3],0.2976666667))
    check(hall,"first step reaches only immediate neighbours equally",near(n.displacement[2],0.001) and near(n.displacement[4],0.001) and n.displacement[1]==0 and n.displacement[5]==0)
    for i in range(119):
        n.step(1.0/60.0);reversed.step(1.0/60.0)
    var equivalent := true
    for i in range(7):
        equivalent=equivalent and near(n.displacement[i],reversed.displacement[i]) and near(n.velocity[i],reversed.velocity[i]) and near(n.displacement[i],n.displacement[6-i])
    check(hall,"120 steps preserve symmetry and do not depend on traversal order",equivalent)
    n.free();reversed.free()

    hall = "WaveFunctions_Effect_Sound"
    n = study(hall)
    original = study(hall,"06_phase_note.gd")
    check(hall,"ratio change leaves zero-depth audio bytes exactly unchanged",n.make_note(0).data==original.make_note(0).data)
    check(hall,"positive depth makes the ratio change consequential",n.make_note(2).data!=original.make_note(2).data and near(n.frequency*n.ratio,660))
    check(hall,"same sample count and byte encoding survive the edit",n.make_note(2).data.size()==52920 and n.make_note(2).mix_rate==44100)
    n.free();original.free()

    hall = "Wavefunctions_Bernini"
    n = study(hall)
    check(hall,"taller twelve-corner shaft has the predicted topology",n.points.size()==206 and n.faces.size()==408)
    check(hall,"height changes without changing total turn",n.ring_position(8,0).is_equal_approx(Vector3(0,2.05,-0.4)) and n.ring_position(16,0).is_equal_approx(Vector3(-0.4,3.85,0)))
    var positions: Array=n.points.duplicate()
    var before: Basis=n.shaft.basis
    n.point.action();n._process(0.5)
    check(hall,"trigger changes whole-object pose while geometry stays stored",n.points==positions and not n.shaft.basis.is_equal_approx(before))
    n.free()

    hall = "WaveFunctions_John_Cage"
    n = study(hall)
    var times_ok:=true
    for i in range(6):
        times_ok=times_ok and near(n.score[i].at,0.75*(i+1))
    check(hall,"new interval generates the six predicted cumulative times",times_ok)
    var score: Array=n.score.duplicate(true)
    var rng_state: int=n.rng.state
    var fired: Array=[]
    n.event_started.connect(func(i):fired.append(i))
    n.replay();n._process(3.01)
    check(hall,"late frame dispatches all four overdue events in order",fired==[0,1,2,3])
    n.replay()
    check(hall,"replay preserves both score and random state",n.score==score and n.rng.state==rng_state and n.cursor==0)
    n.free()

    hall = "WaveFunctions_AirMusic"
    n = study(hall)
    n.position=Vector3(9,0,7);n.rotation.y=PI/3
    await settle()
    check(hall,"two equal-pitch clips are byte-identical",n.samples[0]==n.samples[1])
    n.point.global_position=n.to_global(n.bars[0].position)
    await settle()
    await create_timer(0.2).timeout
    var first_age: float=n.ages_now()[0]
    n.point.global_position=n.to_global(n.bars[1].position)
    await settle()
    var ages: PackedFloat64Array=n.ages_now()
    check(hall,"actual contact starts a second voice without restarting the first",first_age>0.1 and ages[0]>=first_age and ages[1]>=0 and ages[0]>ages[1]+0.1)
    var raw: float=float(n.samples[0].decode_s16(120)+n.samples[1].decode_s16(360))/32767.0
    check(hall,"equal clips can be read at different ages in the sum",near(n.sum_at(PackedFloat64Array([60.0/44100,180.0/44100]),0),raw))
    observations.air_music={"ages_after_second_contact":Array(ages),"first_age_before_second_contact":first_age}
    n.free()

    hall = "Wavefunctions_Sky_Stairs"
    n = study(hall)
    check(hall,"new rise gives three predicted top heights",near(n.points[0].y,0) and near(n.points[5].y,0.75) and near(n.points[10].y,1.5))
    var radial:=true
    var supported:=true
    for i in range(11):
        radial=radial and near(Vector2(n.points[i].x,n.points[i].z).length(),2.5)
        supported=supported and (n.treads[i].transform*Vector3(0,0.06,0)).is_equal_approx(n.points[i])
    check(hall,"zero amplitude keeps all centres on one circle",radial)
    check(hall,"tread top transforms still agree with sampled centres",supported)
    n.free()

    hall = "WaveFunctions_TrigWalkingPath"
    n = study(hall)
    check(hall,"changed A and lower control choose 6 and 5.75 Hz",near(n.frequency_a,6) and near(n.frequency_b,5.75))
    var cancellation:=true
    var reinforcement:=true
    for i in range(21):
        var p: float=i*0.17
        cancellation=cancellation and absf(n.values_at(2,p).z)<0.00001
        reinforcement=reinforcement and near(n.values_at(4,p).z,2*sin(p))
    check(hall,"same frequency gap cancels at two seconds and reinforces at four",cancellation and reinforcement)
    n.elapsed=0
    check(hall,"gain scales the drawing without changing the raw sum",near(n.values_at(0,PI/2).z,2) and near(n.plot_position(2,0.125).y-n.row_heights[2],0.22))
    n.free()

    hall = "WaveFunctions_Synthesis_Lab"
    n = study(hall)
    check(hall,"new recipe has predicted signed sum at a quarter cycle",near(n.sum_at(PI/2),0.5))
    var odd_symmetry:=true
    for i in range(21):
        var a: float=i*0.19
        odd_symmetry=odd_symmetry and near(n.sum_at(a+PI),-n.sum_at(a))
    check(hall,"new odd recipe reverses sign after half a cycle",odd_symmetry)
    n.phase=0.41
    n.points[2].position.y=0.8;n._process(0)
    check(hall,"lowering H3 raises quarter-cycle signal to one",near(n.sum_at(PI/2),1))
    n.points[4].action()
    check(hall,"baseline action restores new recipe but preserves phase and hold",near(n.sum_at(PI/2),0.5) and near(n.phase,0.41) and n.held)
    n.free()

    var report:=BASE+"transfer-first.json"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"New author-made variations of all twelve printed studies. Same-assistant ghost-student simulation; no independent-reader or headset claim."},"  "))
    print("TRANSFER: ",checks.size()," checks; ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
