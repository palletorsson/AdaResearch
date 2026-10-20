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
