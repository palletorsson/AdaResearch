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
