from write_postcrisis_code import DEST
FILES={
'assertions.gd':'''extends RefCounted
var checks: Array[Dictionary] = []
func expect(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    assert(condition,label)
''',
'check.gd':'''extends SceneTree
func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty(): push_error("Supply an assertion script path"); quit(1); return
    var script = load(args[0])
    if script==null: quit(1); return
    var suite = script.new()
    suite.run()
    var passed: bool = not suite.checks.is_empty()
    for result in suite.checks: passed = passed and result.passed
    print("PASS" if passed else "FAIL", " / ",args[0]," / ",suite.checks.size()," assertions")
    quit(0 if passed else 1)
''',
'assert_bias.gd':'''extends "assertions.gd"
const Model = preload("distinctions.gd")
func run() -> void:
    var model := Model.new()
    var opening := model.layout(0)
    var middle := model.layout(.5)
    var end := model.layout(1)
    expect("six identities retained",opening.size()==6 and Model.WORDS.size()==6)
    expect("warm midpoint .32",is_equal_approx(middle[0].distance_to(middle[1]),.32))
    expect("grey midpoint .66",is_equal_approx(middle[3].distance_to(middle[4]),.66))
    expect("compression reduces warm gap",end[0].distance_to(end[1])<opening[0].distance_to(opening[1]))
    expect("fresh arrays leave earlier arrangement intact",is_equal_approx(opening[0].x,-.52))
    expect("range clamps at upper end",model.layout(3)==end)
    expect("range clamps at lower end",model.layout(-1)==opening)
''',
'assert_ethics.gd':'''extends "assertions.gd"
const Model = preload("seating.gd")
func run() -> void:
    var model := Model.new()
    var rows := model.layout(false)
    var ring := model.layout(true)
    expect("same six seats",rows.size()==6 and ring.size()==6)
    expect("layout changes positions",rows!=ring)
    var gaps := model.gaps(ring)
    for i in 6: expect("equal circular gap %d"%i,is_equal_approx(gaps[i],gaps[0]))
    expect("indexed row wrap differs",not is_equal_approx(model.gaps(rows)[0],model.gaps(rows)[2]))
    var doubled: Array[Vector3] = []
    for p in ring: doubled.append(p*2)
    expect("scaling doubles measured gaps",is_equal_approx(model.gaps(doubled)[0],gaps[0]*2))
    var kept := ring.duplicate()
    expect("same geometry passes loose rule",model.accepts(ring,.5))
    expect("same geometry fails strict rule",not model.accepts(ring,.9))
    expect("changing criterion leaves positions",ring==kept)
    expect("all pairs checked not just indexed neighbours",not model.accepts([Vector3.ZERO,Vector3(2,0,0),Vector3(.1,0,0),Vector3(4,0,0)],.5))
    expect("invalid spacing rule refused",not model.accepts(ring,-1) and not model.accepts(ring,NAN))
''',
'assert_conflict.gd':'''extends "assertions.gd"
const Claims = preload("claims.gd")
func run() -> void:
    var model := Claims.new()
    model.add("door@12","open",true,"A","observation A")
    model.add("door@12","open",false,"B","observation B")
    var before := model.records.duplicate(true)
    expect("opposed reports both supported",model.support("door@12","open")==Vector2i(1,1))
    expect("selection succeeds",model.resolve(0))
    expect("selection does not erase evidence",model.records==before)
    expect("selection does not resolve support",model.support("door@12","open")==Vector2i(1,1))
    expect("unrelated Q gains no support",model.support("door@12","Q")==Vector2i.ZERO)
    model.add("door@13","open",true,"C","later time")
    expect("different time stays separate",model.support("door@13","open")==Vector2i(1,0))
    expect("bad selection refused",not model.resolve(9) and model.selected==0)
    expect("reopen retains records",model.resolve(-1) and model.records.size()==3)
''',
'assert_situated.gd':'''extends "assertions.gd"
const Model = preload("viewpoints.gd")
func run() -> void:
    var model := Model.new()
    var original := model.claims.records.duplicate(true)
    var hidden := model.read(2,true)
    expect("source covered in view",hidden.source=="COVERED")
    expect("same subject",hidden.subject=="4729")
    expect("coverage preserves underlying data",model.claims.records==original)
    hidden.predicate = "ALTERED"
    expect("returned copy independent",model.read(2,false).predicate=="DANGEROUS")
    expect("source recoverable",model.read(2,false).source=="SW")
    expect("authored confidence .92",is_equal_approx(model.read(2,false).confidence,.92))
    expect("invalid view refused",model.read(4,false).is_empty())
    expect("different predicates are not negations",model.claims.support("4729","DANGEROUS")==Vector2i(1,0))
''',
'assert_collective.gd':'''extends "assertions.gd"
const Model = preload("contributions.gd")
func run() -> void:
    var model := Model.new()
    for source in ["A","A","B"]: model.add(source,Vector3.ZERO)
    expect("arrivals are not sources",model.additions==3 and model.sources.size()==2 and model.participations==2)
    expect("undisputed revision refused",not model.revise(0,Vector3.ONE))
    expect("dispute accepted",model.dispute(0))
    expect("revision accepted",model.revise(0,Vector3.ONE))
    expect("revision keeps source and original",model.pieces[0].source=="A" and model.pieces[0].original==Vector3.ZERO)
    expect("revision not addition or settlement",model.pieces.size()==3 and model.additions==3 and model.revisions==1 and model.pieces[0].disputed)
    model.next_version()
    model.add("A",Vector3.UP)
    expect("new version resets only local source set",model.sources.size()==1 and model.ever.size()==2 and model.participations==3 and model.additions==4)
    expect("previous version kept independently",model.previous.size()==3 and model.previous[0].pose==Vector3.ONE)
    expect("invalid index refused",not model.dispute(-1) and not model.revise(99,Vector3.ZERO))
''',
'assert_rhizome.gd':'''extends "assertions.gd"
const Model = preload("network.gd")
func run() -> void:
    var model := Model.new()
    model.seed_samples(47)
    expect("two unlinked seeds",model.points.size()==2 and model.edges.is_empty() and model.components()==2)
    while model.grow(): pass
    var positions := model.points.duplicate()
    model.rewire(1)
    expect("one link forms forest with two components",model.edges.size()==22 and model.components()==2)
    model.rewire(3)
    expect("three links connect and create cycles",model.components()==1 and model.edges.size()>model.points.size()-1)
    expect("rewiring leaves positions",model.points==positions)
    var edges := model.edges.duplicate()
    model.active[0] = false
    expect("cut node has zero active degree",model.neighbours(0).is_empty())
    expect("cut prevents growth",not model.grow())
    model.active[0] = true
    expect("restore uses same edges",model.edges==edges and model.components()==1)
    model.replay()
    while model.grow(): pass
    expect("replay exactly retains samples",model.points==positions)
    var other := Model.new()
    other.seed_samples(47)
    while other.grow(): pass
    expect("fresh same seed recreates positions",other.points==positions)
    other.seed_samples(48)
    expect("new seed changes samples",other.samples!=model.samples)
''',
'assert_assembly.gd':'''extends "assertions.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
func run() -> void:
    var model := Body.new()
    expect("thirteen joints twelve edges one component",model.graph.points.size()==13 and model.graph.edges.size()==12 and model.graph.components()==1)
    expect("unchanged release not an edit",not model.move_joint(6,Body.START[6]))
    expect("moved hand accepted",model.move_joint(6,Body.START[6]+Vector3.UP*.2))
    expect("displacement and edits start together",model.displaced()==1 and model.edits==1)
    model.move_joint(6,Body.START[6])
    expect("return reduces displacement not edit count",model.displaced()==0 and model.edits==2)
    var positions := model.graph.points.duplicate()
    expect("hand connection can meet head",model.join(1,1))
    expect("connection change preserves all positions",model.graph.points==positions)
    expect("hand is isolated",model.graph.neighbours(6).is_empty() and model.graph.components()==2)
    expect("other end rejoins hand",model.join(0,6) and model.graph.components()==1)
    expect("self link refused",not model.join(1,6))
    expect("duplicate link refused",not model.join(0,0))
    var storage := PoseFile.new()
    var roundtrip := storage.decode(JSON.parse_string(JSON.stringify(model.pack())))
    expect("JSON float indices restored",roundtrip.ok and roundtrip.body.graph.edges==model.graph.edges)
    expect("all coordinates restored",roundtrip.body.graph.points==model.graph.points)
    var broken := model.pack(); broken.edges[0]=[0,0]
    expect("bad edge refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.positions[0][0]="not a coordinate"
    expect("bad coordinate refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edges[5]=[1.5,2]
    expect("fractional indices refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edits=-1
    expect("negative edit count refused",not storage.decode(broken).ok)
    expect("nonfinite input refused",not model.move_joint(0,Vector3(INF,0,0)))
''',
'assert_synthesis.gd':'''extends "assertions.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
const Observation = preload("observation.gd")
const NOTE = "user://ada_postcrisis_note_assert_only.json"
const PATH = "user://ada_postcrisis_assert_only.json"
func run() -> void:
    if FileAccess.file_exists(PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    var storage := PoseFile.new()
    expect("missing record is explicitly empty",storage.read(PATH).ok and storage.read(PATH).empty)
    var model := Body.new()
    model.move_joint(6,Body.START[6]+Vector3.UP*.2)
    model.join(1,1)
    expect("real disk save succeeds",storage.save(model,PATH))
    var bytes := FileAccess.get_file_as_string(PATH)
    var second_reader := PoseFile.new()
    var read := second_reader.read(PATH)
    expect("fresh reader restores graph",read.ok and read.body.graph.edges==model.graph.edges)
    expect("fresh reader restores positions and edits",read.body.graph.points==model.graph.points and read.body.edits==2)
    expect("reading does not rewrite file",FileAccess.get_file_as_string(PATH)==bytes)
    var bad := FileAccess.open(PATH,FileAccess.WRITE); bad.store_string("{broken"); bad.close()
    expect("malformed file refused",not storage.read(PATH).ok)
    expect("saving cannot silently erase invalid record",not storage.save(model,PATH) and FileAccess.get_file_as_string(PATH)=="{broken")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
    expect("unwritable parent reports failure",not storage.save(model,"user://ada_absent_postcrisis_test_folder/pose.json"))
    if FileAccess.file_exists(NOTE): DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
    var notes := Observation.new()
    var before := Body.new()
    expect("empty prediction refused",not notes.begin(before,"",NOTE))
    expect("prediction can precede an edit",notes.begin(before,"All joints will stay connected.",NOTE))
    expect("existing prediction not overwritten",not notes.begin(before,"Replace it",NOTE))
    var pending := FileAccess.get_file_as_string(NOTE)
    expect("unchanged body cannot complete trial",not notes.finish(before,"No change","Keep",NOTE))
    expect("failed completion retains prediction",FileAccess.get_file_as_string(NOTE)==pending)
    expect("observation and reason required",not notes.finish(model,"","Keep",NOTE))
    expect("changed body accepts observation",notes.finish(model,"The hand is isolated; two groups.","Keep this case to compare with a connected body.",NOTE))
    var note := notes.read(NOTE)
    expect("wrong prediction retained",note.prediction=="All joints will stay connected.")
    expect("before and after are independent",note.before.edits==0 and note.after.edits==2)
    expect("note binds complete pose",notes.matches(note,model))
    model.move_joint(6,Body.START[6])
    expect("later pose is a different observation subject",not notes.matches(note,model))
    var kept_note := FileAccess.get_file_as_string(NOTE)
    expect("completed note not silently rewritten",not notes.finish(model,"Replace","Replace",NOTE) and FileAccess.get_file_as_string(NOTE)==kept_note)
    expect("incomplete note schema refused",not notes.valid({"schema":1,"complete":true}))
    var broken_note := note.duplicate(true)
    broken_note.after.edges[0]=[0,0]
    expect("invalid pose inside note refused",not notes.valid(broken_note))
    var bad_note := FileAccess.open(NOTE,FileAccess.WRITE)
    bad_note.store_string("{broken");bad_note.close()
    expect("invalid note retained without blocking pose decoding",notes.read(NOTE).is_empty() and not notes.finish(model,"Replace","Replace",NOTE) and FileAccess.get_file_as_string(NOTE)=="{broken" and storage.decode(model.pack()).ok)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(NOTE))
''',
}
def main():
    for name,code in FILES.items(): (DEST/name).write_text(code,encoding='utf8')
    print('Wrote visible assertion suites')
if __name__=='__main__':main()
