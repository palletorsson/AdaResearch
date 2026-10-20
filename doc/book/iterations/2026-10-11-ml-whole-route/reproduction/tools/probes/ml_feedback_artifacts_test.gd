extends SceneTree
const FOLDER := "res://doc/book/iterations/2026-10-11-ml-feedback/"
const Scene = preload("res://algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.tscn")
var checks: Array = []
var failures: Array = []
var evidence: Dictionary = {}

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
    checks.append({"name":label,"passed":ok})
    if not ok: failures.append(label)
    print("ML FEEDBACK ","PASS " if ok else "FAIL ",label)

func fresh() -> Node3D:
    var artifact=Scene.instantiate()
    root.add_child(artifact); artifact.set_process(false)
    return artifact

func state(artifact: Node3D) -> Dictionary:
    return {"ticks":artifact._simulation_ticks,"time":artifact._time_elapsed,"creatures":artifact._creatures.duplicate(true),"visited":artifact._visited_grid.duplicate(true),"born":artifact._total_born,"died":artifact._total_died,"rng":artifact._rng.state}

func run() -> void:
    var artifact=fresh()
    check("opening is still thirty creatures and zero simulation time",artifact._creatures.size()==30 and artifact._time_elapsed==0)
    artifact._creatures.clear(); artifact._fill_visited_grid()
    for i in 119: artifact._process(1.0/60.0)
    var visited:=0
    for row in artifact._visited_grid:
        for cell in row: visited+=int(cell)
    check("119 ticks do not renew early, even headless",artifact._simulation_ticks==119 and visited==400)
    artifact._process(1.0/60.0); visited=0
    for row in artifact._visited_grid:
        for cell in row: visited+=int(cell)
    check("tick120 renews exactly one cell at two seconds",artifact._simulation_ticks==120 and artifact._time_elapsed==2 and visited==399)
    check("renewal clock is named on the artifact",artifact._stats_label.text.contains("2 simulated seconds"))
    artifact.free()
    var reference: Dictionary = {}
    for fps in [60,30,90,144]:
        artifact=fresh()
        for i in fps*20: artifact._process(1.0/fps)
        var snapshot:=state(artifact)
        if fps==60: reference=snapshot
        check("twenty seconds at %d render updates/s gives identical full simulation state"%fps,snapshot==reference and snapshot.ticks==1200)
        evidence[str(fps)]={"ticks":snapshot.ticks,"population":snapshot.creatures.size(),"born":snapshot.born,"died":snapshot.died}
        artifact.free()
    artifact=fresh()
    # Every trio totals exactly 0.1 s: irregular frame delivery, same elapsed time.
    for i in 200:
        for delta in [0.011,0.017,0.072]: artifact._process(delta)
    check("uneven frame delivery preserves positions energy births grid and RNG",state(artifact)==reference)
    artifact.apply_grid_config({"selection":"uniform"});var stopped:=state(artifact)
    artifact._process(2.0)
    check("composed states stay stopped even when called directly",state(artifact)==stopped and not artifact.is_processing())
    artifact.apply_grid_config({"selection":"drift"})
    check("return to drift resets clock and seeded opening",artifact._simulation_ticks==0 and artifact._simulation_accumulator==0 and artifact._creatures.size()==30)
    artifact.free()
    var network=load("res://algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.tscn").instantiate()
    network.auto_train=false;root.add_child(network)
    check("network announces target leakage on its own persistent display",network.info_display.text.begins_with("ANSWER ALREADY IN THE INPUT") and network.info_display.text.contains("Input 3 = target 2"))
    network.current_epoch=3;network.update_info_display()
    check("training refresh does not erase the disclosure",network.info_display.text.contains("answer leakage") and network.info_display.text.contains("Epoch: 3"))
    network.apply_grid_config({"topology":"flat"})
    check("flat topology rebuild retains disclosure and actual leaked fixture",network.info_display.text.contains("ANSWER ALREADY") and network.training_data[0][3]==network.target_data[0][0])
    check("topology rebuild also retains one lower disclosure panel",network.get_node("InputAudit/Disclosure").text.contains("Input 4 = target 1") and network.find_children("InputAudit","Node3D",true,false).size()==1)
    check("disclosure height follows the floor origin, not buried lowest neurons",absf(network.get_node("InputAudit").position.y-1.4)<0.00001)
    network.free(); await process_frame
    FileAccess.open(FOLDER+"artifact-tests.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Actual artifact scripts, manually delivered frame schedules and persistent display content. Native images checked separately. No human VR evaluation."},"  "))
    quit(0 if failures.is_empty() else 1)
