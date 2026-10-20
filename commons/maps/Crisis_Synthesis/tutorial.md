# A claim keeps its warrant

**Learning elements**

- Evidence records
- reuse across models
- display scale
- word timing
- claim versus validation

The existing hall brings the formula, independent parameter controls and earlier encounters together. Its sentence-authority work repeats the same words at several scales. Build a small working copy of that operation, carrying the five model files just written. The code keeps six supplied reference cards and also imports your saved experiments from Gödel. The unchanged models are listed below. Their meanings remain distinct.

Each card keeps three fields: sentence, scope and evidence. The first five concern the two Russell cases, a unary search budget, a closed height route, a chosen prefix and a four-valued countermodel. The sixth is an authored AI proposal with no verification procedure attached. That explicit absence does not acquire a certificate from the neighbouring calculations. These examples are finite scoped records, not an automatic truth service.

`current` returns a deep copy, protecting the stored evidence from display edits. NEXT changes the selected card and starts its word rhythm again. SIZE changes font size; HOLD pauses the strip; PACE alternates 0.6 and 1.2 seconds per word and restarts it. Small label, large label and strip read one sentence. None of these controls reruns a model, changes its assumptions or upgrades its result.

The original QFEP formula remains a research proposal. Its λ and φ displays do not measure the entropy of these cards, and the logistic exhibit's r remains independent. Our work here concerns how an assertion is presented and what supports it. The familiar sphere is present as a carried body, not as an oracle that can settle the formula.

## Bring a run you actually made

As in Trace → Grid, your own work travels into another hall. The six reference cards use supplied examples. Your saved Gödel runs are additional cards, read from `user://ada_foundations_trials_v1.json`; the first personal card is selected on entry when available. They retain the target, budget, damage setting, prediction, search output, exact tested candidate, checker result, time in UTC, model identifier and source hash. The journal is read without rerunning the search or rewriting earlier entries. A source change is disclosed alongside the older result. A missing or malformed file produces a notice and no personal cards.

## Keep the difficulties distinct

| Encounter | What must be distinguished |
| --- | --- |
| Plane / sphere | Different geometric models; a changed result can be correct in each. |
| Russell | The unrestricted demand contradicts both Boolean assignments. |
| Gödel | A finite search miss; separately, the theorem's unprovability claim under specified assumptions. |
| Escher | Coincidence in a view versus connection in the measured space. |
| Brouwer | An absent witness now versus a claim about every continuation. |
| Florensky | Opposed reports and the explicitly chosen rules of consequence. |

Each difficulty calls for its own response. They do not accumulate into a verdict that justification has failed. Choose one earlier museum artifact—a trace, a woven pattern or the trained sphere—and state its inputs, rule, observed result and what the result leaves open. This final comparison is a written investigation; the current journal imports Gödel experiments only.


## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new. Also carry `membership.gd`, `derivation.gd`, `height_route.gd`, `witness.gd` and `reports.gd` from the five preceding lessons. These are executable dependencies, not hidden services. Carry `trial_archive.gd` from Gödel too. It reads the saved experiment file; no live node is transferred.

Run the supplied `synthesis.tscn` in that folder with F6. Its `synthesis_museum.gd` launcher opens **Crisis_Synthesis** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `claim_record.gd`

<!-- student-code:claim_record.gd -->
```gdscript
extends RefCounted
const Membership=preload("membership.gd")
const Derivation=preload("derivation.gd")
const HeightRoute=preload("height_route.gd")
const Witness=preload("witness.gd")
const Reports=preload("reports.gd")
const TrialArchive=preload("trial_archive.gd")
var journal_message := "No journal loaded."
var cards: Array[Dictionary] = []
var index := 0
var elapsed := 0.0
var seconds_per_word := 0.6
var paused := false
var large := false

func _init() -> void:
    var membership=Membership.new()
    var proof=Derivation.new().search("SSS0",2)
    var route=HeightRoute.new()
    var prefix=Witness.new()
    prefix.append_bit(0)
    var reports=Reports.new()
    cards=[
        {"sentence":"NEITHER ANSWER MEETS THIS DEMAND", "scope":"Unrestricted Boolean self-membership", "evidence":[membership.test(false,false).agrees,membership.test(true,false).agrees]},
        {"sentence":"NO PROOF WAS FOUND WITHIN TWO STEPS", "scope":"Unary toy syntax; target SSS0", "evidence":proof},
        {"sentence":"THE CLOSED ROUTE RETURNS ITS HEIGHT", "scope":"Four centres in one fixed frame", "evidence":route.closure()},
        {"sentence":"NO WITNESS HAS BEEN RECORDED YET", "scope":"One chosen zero; continuation open", "evidence":prefix.inspect_prefix()},
        {"sentence":"CONFLICT DOES NOT SUPPORT EVERY CLAIM", "scope":"The printed pair semantics", "evidence":reports.explosion_counterexample()},
        {"sentence":"THIS AI PROPOSAL STILL NEEDS CHECKING", "scope":"An authored sentence, not a model verdict", "evidence":"No verification procedure attached"}]

func load_journal(path: String = TrialArchive.DEFAULT_PATH) -> void:
    cards.resize(6)
    index=0
    elapsed=0
    var journal := TrialArchive.new().read(path)
    journal_message=journal.message
    if not journal.ok: return
    var current_hash := FileAccess.get_sha256(Derivation.new().get_script().resource_path)
    for entry in journal.entries:
        cards.append({"sentence":"MY PREDICTION MATCHED THIS RUN" if entry.prediction_matched else "MY PREDICTION FAILED IN THIS RUN",
            "scope":"Saved Godel experiment; finite unary model",
            "evidence":entry.duplicate(true), "student_record":true,
            "same_model_source":entry.model_sha256 == current_hash})
    if cards.size()>6: index=6

func current() -> Dictionary:
    return cards[index].duplicate(true)

func next() -> void:
    index=(index+1)%cards.size()
    elapsed=0

func advance(delta: float) -> void:
    if not paused and is_finite(delta) and delta>=0:
        var count: int=cards[index].sentence.split(" ").size()
        elapsed=fposmod(elapsed+delta,count*seconds_per_word)

func word() -> String:
    var words: PackedStringArray=cards[index].sentence.split(" ")
    return words[int(elapsed/seconds_per_word)%words.size()]

func pace() -> void:
    seconds_per_word=1.2 if seconds_per_word<1 else 0.6
    elapsed=0
```

### `synthesis_study.gd`

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "bench.gd"
const ClaimRecord=preload("claim_record.gd")
var model:=ClaimRecord.new()
var journal_path := ClaimRecord.TrialArchive.DEFAULT_PATH
var journal_label: Label3D
var strip: Label3D
var wall: Label3D
var small: Label3D

func _ready() -> void:
    start("SYNTHESIS / A CLAIM AND ITS WARRANT", ["NEXT", "SIZE", "HOLD", "PACE"],
        [next_card,resize,hold,pace])
    wall=label(drawing,"",Vector3(0,1.42,-0.05),25)
    small=label(drawing,"",Vector3(0,1.04,0.4),12)
    strip=label(drawing,"",Vector3(0,1.2,0.2),25)
    point_home=Vector3(-1.15,1.14,0.4)
    journal_label=label(self,"",Vector3(0,1.69,-0.8),20)
    model.load_journal(journal_path)
    refresh()

func next_card() -> void:
    if point.held(): return
    model.next()
    refresh()

func resize() -> void:
    model.large=not model.large
    refresh()

func hold() -> void:
    model.paused=not model.paused
    refresh()

func pace() -> void:
    model.pace()
    refresh()

func _process(delta: float) -> void:
    model.advance(delta)
    if strip!=null: strip.text=model.word()

func refresh() -> void:
    var card:=model.current()
    small.text=card.sentence
    wall.text=card.sentence
    wall.font_size=25 if model.large else 17
    strip.text=model.word()
    readout.text="%d / %d | %s\nEvidence: %s\n%s | %.1f seconds/word"%[
        model.index+1,model.cards.size(),card.scope,str(card.evidence).left(110),
        "HELD" if model.paused else "RUNNING",model.seconds_per_word]
    journal_label.text=model.journal_message
    if card.get("student_record", false):
        var e: Dictionary=card.evidence
        readout.text="SAVED RUN %d | %s | budget %d | damage %s\nPredicted %s; checker accepted %s\n%s | examined %d" % [
            model.index-5,e.target,int(e.budget),str(e.damage),str(e.prediction),str(e.accepted),
            e.search_result.status,int(e.search_result.examined)]
        journal_label.text="%s | source %s\n%s; saved evidence is not rerun." % [
            e.saved_at,e.model_sha256.left(12),"Same model source" if card.same_model_source else "Different model source"]
```

## Predict, build, check

Freeze a copy of the current card. Change font size, hold for several simulated seconds, change pace, and complete a word cycle. Its scope and evidence must remain exactly the same. At the proof card, identify the target and budget before reading the large sentence. At the AI card, ask for a source or executable test; do not accept size, repetition or fluent wording as that evidence.

Edit a sentence in `cards` and run the three displays. The program will faithfully print even a false or overbroad sentence. This is a deliberate limit of the display, not permission to report the edited claim as validated. Compare it with the evidence kept alongside it and revise the words when they disagree.

Carry this practice into the QFEP laboratory: define the quantities, implement the operation, preserve the record and let someone challenge what the result entitles us to say.

At your own card, identify what you predicted before the run and whether it matched. A failed prediction is part of the evidence. Visit another card and return; restart the hall. The saved inputs and result must survive both. If the model source changes, retain the earlier card and read its source warning; a hash identifies bytes, not the truth or authorship of a record. The reader validates the record's format, not the historical honesty of someone editing its JSON.


The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
