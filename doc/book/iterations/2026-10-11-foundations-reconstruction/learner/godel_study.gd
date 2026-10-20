extends "bench.gd"
const Derivation = preload("derivation.gd")
const TrialArchive = preload("trial_archive.gd")
var model := Derivation.new()
var archive := TrialArchive.new()
var journal_path := TrialArchive.DEFAULT_PATH
var pending: Dictionary = {}
var journal_label: Label3D
var journal_message := "Predict the next budget, then TRY + KEEP."
var target := "SSS0"
var budget := 2
var result: Dictionary = {}
var damaged := false

func _ready() -> void:
    start("GODEL / CHECKING IS NOT SEARCHING", ["MORE", "TARGET", "DAMAGE", "RESET"],
        [more, next_target, damage, reset])
    block(self, Vector3(0, 0.84, 1.15), Vector3(2.5, 0.08, 0.55), Color("d3ccc1"))
    var words := ["PREDICT YES", "PREDICT NO", "TRY + KEEP"]
    var actions := [predict.bind(true), predict.bind(false), run_trial]
    for i in 3:
        var button = PushButton.instantiate()
        button.position = Vector3((i-1)*0.8, 0.92, 1.15)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3.UP*0.12, 16)
    journal_label = label(self, "", Vector3(0, 1.69, -0.8), 22)
    refresh()

func cancel_prediction() -> void:
    pending.clear()
    journal_message = "Setup changed. Predict before TRY + KEEP."

func predict(accepted: bool) -> void:
    if point.held(): return
    if budget >= 8:
        journal_message = "RESET first: the next budget would exceed 8."
    else:
        pending = {"target":target, "budget":budget+1, "damage":damaged, "prediction":accepted}
        journal_message = "Next budget %d; checker accepts? %s\nTRY + KEEP will run and retain this prediction." % [budget+1, "YES" if accepted else "NO"]
    refresh()

func run_trial() -> void:
    if point.held(): return
    if pending.is_empty():
        journal_message = "Choose PREDICT YES or NO before running."
    else:
        var entry := archive.capture(model, pending.target, pending.budget, pending.damage, pending.prediction)
        var saved := archive.append(entry, journal_path)
        budget = pending.budget
        journal_message = "%s\nPredicted %s; accepted %s. %s" % [saved.message,
            str(entry.prediction), str(entry.accepted), "MATCH" if entry.prediction_matched else "DID NOT MATCH"]
        pending.clear()
    refresh()

func more() -> void:
    if point.held(): return
    cancel_prediction()
    budget = mini(8, budget+1)
    damaged = false
    refresh()

func next_target() -> void:
    if point.held(): return
    cancel_prediction()
    target = "SSSSSS0" if target=="SSS0" else "SSS0"
    damaged = false
    refresh()

func damage() -> void:
    if point.held(): return
    cancel_prediction()
    damaged = not damaged
    refresh()

func reset() -> void:
    if point.held(): return
    cancel_prediction()
    budget = 2
    damaged = false
    refresh()

func refresh() -> void:
    result = model.search(target, budget)
    var candidate: Array = result.proof.duplicate()
    if damaged and candidate.size()>1: candidate.remove_at(1)
    clear_drawing()
    for i in candidate.size():
        var at := Vector3(-1.12+i*0.28, 1.05+i*0.035, 0)
        block(drawing, at, Vector3(0.23, 0.08, 0.35), Color("94aeba"))
        label(drawing, str(i), at+Vector3(0, 0.12, 0.2), 19)
    point_home = Vector3(-1.12+(candidate.size()-1)*0.28, 1.27+(candidate.size()-1)*0.035, 0)
    readout.text = "Target %s | at most %d rule steps\n%s\nCandidate checks: %s%s" % [
        target, budget, result.status, str(model.verify(candidate, target)),
        " (step removed)" if damaged else ""]
    journal_label.text = journal_message
