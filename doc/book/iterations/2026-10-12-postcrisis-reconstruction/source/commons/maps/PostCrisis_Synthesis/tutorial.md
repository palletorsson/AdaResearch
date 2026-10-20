# The body that crosses the threshold

**Learning elements**

- Reconstruction from a file
- Counts versus state
- Missing and invalid records
- Observation tied to a saved pose

Bring the file made by the preceding student lesson into the existing Synthesis hall. The installed amber body and ledger already demonstrate the workshop's separate record. Our working copy reconstructs the student's record beside its starting body. No live point node travels between scenes: the data supplies positions and connections to new instances of familiar renderers.

READ validates the file using the same `PoseFile`; it does not silently repair or invent data. With no record, the second place stays empty. With an invalid record, the error remains visible and the file remains unchanged. A valid read produces a `Body` whose coordinates, connectivity and edit count match the saved version.

Edits count changed releases. Displaced joints compare the current positions with the starting positions. Moving a joint away and back can therefore raise edits while reducing displacement. A rerouted connection can change the number of connected groups without moving any joint. These are different questions answered from the same record.

JOINT changes the displayed selection without rewriting the file. Taking and releasing the sphere also leaves the record intact: this is a reader, not another editor. The complete code is short because validation, graph traversal and rendering were written earlier. To investigate accountability, keep the next question separate: what activity did a change enable or obstruct, what observation supports that judgement, and who can revisit it? The pose schema alone supplies none of those answers.

An optional note makes one investigation inspectable. Fill the empty `observation` and `keep_reason` strings in `synthesis_study.gd` with what you noticed and why you choose to keep this change, then run the lesson and press KEEP NOTE. This completes the separate prediction record begun in Assembly. It retains the before and after poses, your original prediction (even if wrong), observation and reason. READ can tell whether the completed note still matches the current pose. If another edit replaced the pose on disk, KEEP NOTE requires READ first; it will not silently attach your note to that newer body.

These are text values you write in the two student scripts; there is no new VR keyboard or automatic interpretation of your intention. Open the JSON under Godot's user data folder to read the complete note. The program checks structure and pose identity, not the truth of your explanation, whether the prediction was sincere, or whether anybody else agrees. It saves no participant identity, gesture path or full revision history. This is evidence for revisiting one decision, not a finished accountability system. Keeping a before snapshot also does not implement an Undo command.

## Continue the student folder

Keep the files from **Change a position, change a neighbour** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.

The supplied [`synthesis.tscn`](../../../doc/book/studies/postcrisis-lineage/synthesis.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`synthesis_museum.gd`](../../../doc/book/studies/postcrisis-lineage/synthesis_museum.gd), set the `LESSON` preload to your `synthesis_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum's supplied `push_button.tscn`.

## Complete new code

### `synthesis_study.gd`

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "study_base.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
const Observation = preload("observation.gd")
@export_multiline var observation: String = ""
@export_multiline var keep_reason: String = ""
var notes := Observation.new()
var note_path: String = Observation.PATH
var note_message := "No note read."
var storage := PoseFile.new()
var record_path: String = PoseFile.PATH
var model = null
var selected := 6
var message := ""

func _ready() -> void:
    start("RETURN / THE SAME RECORD",["READ","JOINT","KEEP NOTE"],[reload_pose,next_joint,keep_note])
    reload_pose()

func reload_pose() -> void:
    if point.held(): return
    var loaded := storage.read(record_path)
    model = loaded.body if loaded.ok and not loaded.empty else null
    message = loaded.message
    var note := notes.read(note_path)
    note_message = "No valid note; pose still readable."
    if not note.is_empty():
        note_message = "Prediction awaits an observation." if not note.complete else ("Note matches this pose." if model!=null and notes.matches(note,model) else "Note belongs to another pose.")
    refresh()

func keep_note() -> void:
    if point.held() or model==null: return
    var current := storage.read(record_path)
    if not current.ok or current.empty or current.body.pack()!=model.pack():
        note_message = "Pose changed on disk. READ before attaching a note."
    elif notes.finish(model,observation,keep_reason,note_path):
        note_message = "Note kept for this pose; no claim of proof."
    else:
        note_message = "Need an open prediction, a changed pose and your two texts."
    refresh()

func next_joint() -> void:
    if point.held(): return
    selected = (selected+1)%13
    refresh()

func draw_body(points, edges, offset: Vector3, colour: Color) -> void:
    for p in points: dot(p*.4+offset,colour,.02)
    for edge in edges: segment(points[edge.x]*.4+offset,points[edge.y]*.4+offset)

func refresh() -> void:
    clear_drawing()
    draw_body(Body.START,Body.EDGES,Vector3(-.65,1.02,0),Color("9fc2db"))
    if model==null:
        point_home = Vector3(-.65,1.22,.35)
        readout.text = message+"
The second place is empty."
        return
    draw_body(model.graph.points,model.graph.edges,Vector3(.65,1.02,0),Color("ddbd88"))
    point_home = model.graph.points[selected]*.4+Vector3(.65,1.02,0)
    readout.text = "Edits %d / displaced %d / groups %d
%s
%s" % [model.edits,model.displaced(),model.graph.components(),Body.IDS[selected],note_message]
```

### `assert_synthesis.gd`

<!-- student-code:assert_synthesis.gd -->
```gdscript
extends "assertions.gd"
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
```

## Predict, run, change one thing

First visit with no file: the amber place must be empty. Then create a changed pose in Assembly, close that study and read here in another process. Compare all thirteen positions, all twelve edges and the edit count. Selecting another joint must not change the file bytes. A malformed copy must be refused rather than displayed as a plausible body. For the optional note, predict before editing, retain a wrong prediction if it occurs, then finish with your own observation and reason. Assert that later edits make the note a record of the earlier pose, and that saving the note does not rewrite the pose file.

The assertion file above runs against your model files. From the project directory, use your Godot executable with:

```text
Godot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_synthesis.gd --no-bridges
```

Adjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.

Return to an earlier artifact with a particular change and an observation to test. A record makes that return possible; it does not settle its consequences.
