"""Print every new student file, with explicit earlier dependencies and room launchers."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'doc/book/studies/postcrisis-lineage'
OUT=ROOT/'doc/book/iterations/2026-10-12-postcrisis-reconstruction'
HALLS=json.loads((ROOT/'commons/maps/sequences/postfoundationscrisis.json').read_text())['sequences']['postfoundationscrisis']['maps']
KEYS=['bias','ethics','conflict','situated','collective','rhizome','assembly','synthesis']
TITLES=['Room for a distinction','Arrange the same seats','Keep the two accounts','A claim has an address','Count contributions and revisions','Connections before passages','Change a position, change a neighbour','The body that crosses the threshold']
MODELS=['distinctions.gd','seating.gd','claims.gd','viewpoints.gd','contributions.gd','network.gd','body.gd','']
ELEMENTS=[
['Authored interpolation','Stable identities','Measurement versus interpretation'],
['Controlled comparison','Arrays of positions','Whole-object placement','Authored acceptance criterion'],
['Source-tagged records','Selection versus deletion','Four-valued support reused'],
['Subject and predicate','Provenance','Presentation versus stored data'],
['Events versus distinct sources','Version boundaries','Revision without addition'],
['Seeded positions','Nearest earlier neighbours','Adjacency and connected components'],
['Local coordinates','Indexed connectivity','Changed releases','Validated persistence','Prediction before editing'],
['Reconstruction from a file','Counts versus state','Missing and invalid records','Observation tied to a saved pose']]
INTRO=[
'''We are inside the existing bias hall. Move COMPRESSION on its labelled sculpture; then build a smaller working copy beside it. The PointBody from the early point lessons and Foundations becomes a handle. Its position controls one interpolation amount. The labels keep their identities while their positions change. We reuse `lerp` from Transformation and arrays from the earlier sequences.

Our six labels are authored examples, as are their two arrangements. The three warm words receive less space; the three grey words receive more. This is not a trained embedding or a measurement of any social group. The program can measure separation in this representation. Whether the grouping or the representation is appropriate requires further evidence.

`layout` returns a fresh array. Its index continues to identify the same word; drawing the arrangement never sorts or renames it. At amount 0, neighbouring labels in either row are 0.52 metres apart. At amount 1, the warm gap is 0.12 and the grey gap 0.80. HALF must produce the midpoint of those distances. Taking another viewpoint changes the image, not these coordinates.

The inherited bench builds its labels before assigning their text. `study_base.gd` adds one shared pickup/release adapter and a small visible dot. It retains the last held local coordinate so that a physics tick cannot erase the intended release. After physics, it also places the released marker at the current selection so that the visible sphere agrees with the readout. Later halls reuse this adapter. Only the point handle is pickable in this working copy; the displayed labels remain its subject.''',
'''Walk around the installed HEAD and CIRCLE models. They change chair count and relative size as well as arrangement. Our working copy isolates position: the same six cube-built seats retain their count, dimensions, colour and order in both layouts. This uses the whole meshes we learned to transform, without transforming their faces separately.

ROWS places two rows of three. RING places six centres at equal angles on a circle. The earlier sine and cosine operations return as a way to arrange positions. Each cube is drawn at one array entry. SEAT moves the carried point to another entry; dropping it near another seat selects that entry without relocating the seats.

The cylinder joins the selected seat to the next index, and the readout measures that distance. The index order is not a claim about who speaks next. In rows, the wrap between indices can be long; around the ring, every adjacent gap is equal within float tolerance. Comparing these exact distances still does not establish equal participation, sightlines or comfort. Those require a different test with people.

Now leave the ring still and press RULE. It changes an authored minimum centre-to-centre distance from 0.50 m to 0.90 m. The same positions pass the first rule and fail the second. `accepts` checks every distinct pair; the cylinder still shows only the next indexed pair. Change the threshold in code and predict the result before pressing it. You are now editing a criterion for acceptance, not only choosing a supplied arrangement. This is not chair-edge clearance, a route test or an accessibility standard. Who needed this constraint, and what evidence would justify choosing it?''',
'''At the existing conflict sculpture, try OVERLAP and RESOLVED. Its shorter branch makes a selection visible. Our working copy keeps both source records even when one column is shortened. The carried sphere can choose A or B; BOTH restores the two visible heights. The displayed selection never deletes the rejected account.

Bring `reports.gd` from Florensky. Its pair records support for and against a proposition separately. `claims.gd` now gives each report a subject, predicate, value, source and evidence description. The toy reports refer to the same door at the same time. Only matching subjects and predicates contribute to a support pair. Different predicates or different times must not accidentally become a contradiction.

Choosing A or B is a presentation decision stored in `selected`. `support` reads the retained records, so the pair remains BOTH after either selection. Q still has no support. This reuses the earlier formal distinction without pretending the museum sculpture executes a proof system. A source label is provenance; an evidence string is not automatically good evidence.''',
'''Continue from the retained claims to the four installed situated readouts. Their verdicts and percentages are supplied by their configuration. They do not measure the approaching player. Our working copy reuses `Claims`, with the same subject identifier and four different predicates and sources. The sphere chooses which record is displayed; it does not alter that record's judgement. The selected pad turns amber and a short cylinder links it to the raised sphere, making the selection legible from different viewpoints.

`read` makes a deep copy for presentation. COVER replaces the source only in that returned copy. REVEAL can therefore recover it, and another view still has its original provenance. The source, predicate and confidence remain separate fields. A 92% label is not a calibrated probability simply because it is numeric.

The four verdicts answer different questions; they are not automatically logical negations. The existing camera witnesses extend the inquiry into viewpoint and time. They remain another encounter in this hall. This small lesson concentrates on retaining the address of a claim when its presentation changes.''',
'''Watch the installed peer tool, then keep the same distinction between a displayed choice and its retained source. In this working copy an arrival is a cube record: source, original position, current position, dispute flag and revision count. The carried sphere edits the first piece only after DISPUTE. Earlier position work now changes a contribution without counting it as a new arrival.

ADD follows a declared A, A, B sequence. Repeating A increases additions but not distinct sources in the current version. VERSION saves one deep copy of the preceding pieces and empties the current list and source set. `ever` and the lifetime totals remain. When A returns in another version it contributes another participation, but no new lifetime source.

REVISE changes a disputed piece's pose and retains its source and original position. The dispute stays open. Attribution to VISITOR reports who used this local control; it does not authenticate an identity or settle an argument. The first piece can also be moved with the sphere. This simulation cannot decide whether the revision is warranted. Another person contesting its reason would require a collaborative process beyond these counters. Capacity is six displayed pieces so the whole example remains inspectable; the installed exhibit supports more. Neither is a networked collaborative editor or a permanent archive.''',
'''Enter the composed cave and find a return that does not retrace every passage. Then inspect the separate grower near its entrance. The cave is not generated by that tabletop graph. Our working copy isolates the grower's rule using the carried point and finite cylinders from Lines. We bring deterministic sampling from Randomness and indexed lists from Arrays.

The example prepares 24 seeded positions. Two initial points have no connecting edge. STEP adds one point and links it to the nearest earlier points. The neighbour search excludes the arriving point itself. With one link, each arrival extends exactly one component: two trees remain. With three links, the third point connects both seeds; later arrivals add circuits. The smaller sample layout is our declared construction, not an exact replay of the installed grower's 40 points.

LINKS rebuilds edges at the same positions. NODE or the sphere selects a point; CUT toggles whether that point participates. Edges remain stored so restoring a point can restore its old relations. `components` visits active neighbours, counting isolated active points too. Growth refuses while a point is cut, keeping the comparison fixed. REPLAY returns to the same two starting samples and retains the link setting.

`rewire` sorts only earlier indices by squared distance; the first entries supply the neighbours. Squared distance keeps the same order without a square root. In `components`, `todo` is a stack of indices still to visit. Pop one, skip it if `seen` already contains it, mark it, then add its active neighbours. The inner loop exhausts everything reachable from that starting index. The outer loop begins a new component only at an active, unvisited point. `seen` is what makes a circuit safe to traverse without looping forever.

Graph adjacency says which indices are joined. It does not guarantee that a body can enter the corresponding cave passage. A crossing of drawn cylinders does not add an edge. A degree counts neighbours; it does not measure influence. LINK changes one supplied parameter; it does not let a node revise the nearest-earlier rule. Name what is still fixed: boundary, arrival order, distance metric and authority to edit. Decentralized adjacency does not imply shared control over those choices. Assembly next reuses this graph representation to distinguish moving a joint from changing its neighbour.''',
'''Find the installed gold body and its turquoise collars. Move a joint, then reroute one connection without moving a joint. Our working copy uses the same thirteen named positions and twelve connections from the VRBody assembly. `Body` composes the graph from Rhizome; it does not run its growth rule. The same PointBody is the editing handle, and LineSkin shows the indexed connections.

To keep the new code small, JOINT selects which position the single sphere edits. MODE switches from position editing to one endpoint of the left forearm connection; END selects its other endpoint. This is a reduced interface to the same distinction, not a replacement of the installed body's thirteen handles. The model is drawn at 0.48 scale above the bench. `body_position` reverses that display transform after `to_local` has removed the hall transform. Stored positions stay in the body's own frame.

In POSITION mode, release changes the selected joint if it moved more than 0.01 m in body coordinates. Bounds are explicit. In RELATION mode, release within 0.18 m of a joint proposes its index. Self-links, duplicate links and empty-space releases are refused; eleven other edges stay authored. Neither operation enforces anatomical proportions. The gold lines remain visual relations, distinct from the physical ragdoll elsewhere in the hall.

After a changed release, `PoseFile` validates and writes one latest record through a temporary file. Its schema retains coordinates, edge indices and completed edit count under an explicit model version; that version fixes names and starting geometry. Like the Foundations journal, loading checks structure before trusting data. JSON integers reload as floats, so valid indices are checked and converted. Invalid existing files are preserved and saving refuses to overwrite them.

The student file is `user://ada_postcrisis_pose_v1.json`. The installed gold body uses its separate Assembly record. Our two student halls share the student file; they do not overwrite the visitor's installed-workshop pose. This compact schema has no timestamps, identity, path or history. A save failure leaves the new body only in this working copy. Synthesis can read only the last successful file.

For one optional investigation, fill the empty `prediction` string in `assembly_study.gd` with your expectation before running the lesson. Press PREDICT before your next edit. `Observation.begin` saves that exact starting pose and prediction in a separate file. It refuses an empty prediction and refuses to replace an existing file. Keep the resulting changed pose, then continue to Synthesis. Use another `note_path` for a new experiment so the earlier one remains available. No prediction is supplied on your behalf.''',
'''Bring the file made by the preceding student lesson into the existing Synthesis hall. The installed amber body and ledger already demonstrate the workshop's separate record. Our working copy reconstructs the student's record beside its starting body. No live point node travels between scenes: the data supplies positions and connections to new instances of familiar renderers.

READ validates the file using the same `PoseFile`; it does not silently repair or invent data. With no record, the second place stays empty. With an invalid record, the error remains visible and the file remains unchanged. A valid read produces a `Body` whose coordinates, connectivity and edit count match the saved version.

Edits count changed releases. Displaced joints compare the current positions with the starting positions. Moving a joint away and back can therefore raise edits while reducing displacement. A rerouted connection can change the number of connected groups without moving any joint. These are different questions answered from the same record.

JOINT changes the displayed selection without rewriting the file. Taking and releasing the sphere also leaves the record intact: this is a reader, not another editor. The complete code is short because validation, graph traversal and rendering were written earlier. To investigate accountability, keep the next question separate: what activity did a change enable or obstruct, what observation supports that judgement, and who can revisit it? The pose schema alone supplies none of those answers.

An optional note makes one investigation inspectable. Fill the empty `observation` and `keep_reason` strings in `synthesis_study.gd` with what you noticed and why you choose to keep this change, then run the lesson and press KEEP NOTE. This completes the separate prediction record begun in Assembly. It retains the before and after poses, your original prediction (even if wrong), observation and reason. READ can tell whether the completed note still matches the current pose. If another edit replaced the pose on disk, KEEP NOTE requires READ first; it will not silently attach your note to that newer body.

These are text values you write in the two student scripts; there is no new VR keyboard or automatic interpretation of your intention. Open the JSON under Godot's user data folder to read the complete note. The program checks structure and pose identity, not the truth of your explanation, whether the prediction was sincere, or whether anybody else agrees. It saves no participant identity, gesture path or full revision history. This is evidence for revisiting one decision, not a finished accountability system. Keeping a before snapshot also does not implement an Undo command.'''
]
PREDICT=[
'Before HALF, predict warm gap 0.32 m and grey gap 0.66 m. Change the authored finish gap in code, predict its midpoint, and check a fresh layout. Drag beyond the control range: the amount must remain between 0 and 1. Keep the sphere instance and word order unchanged.',
'Predict equal neighbouring gaps around the ring, but not around the indexed rows. Change only the radius in code and predict how every ring gap scales. Keep seat count, mesh size and colour unchanged. Freeze the ring and predict PASS at 0.50 m and FAIL at 0.90 m; assert that every position is unchanged after evaluating both rules. Explain why a geometric equality is insufficient evidence of equal access.',
'Choose A: both original records must remain, the support pair must remain (1,1), and Q must remain (0,0). Add a report about another time: it must not affect this subject. Then reopen the comparison without constructing replacement reports.',
'Cover the source, then reveal it. Predict that the underlying dictionary remains unchanged. Modify the returned copy in a test; a fresh read must still return the original. Explain what evidence would be needed before treating an authored confidence as a measured probability.',
'Add A, A, B: expect three additions, two current sources and two participations. Begin another version and add A: expect four additions, one current source, two lifetime sources and three participations. Dispute and move a piece: its source and original pose remain, piece count stays fixed, revision rises.',
'At 24 points with all active, one-link growth has 22 edges and two components; three-link growth is connected and has circuits. Cut node 0, restore it, and verify the same edges return. Replay and regrow: positions must match exactly in this run. Do not interpret a restored edge as a newly invented repair.',
'Move the left hand away and back in two releases: edits rise twice and displacement returns to zero. Reroute the second endpoint of edge 5 from hand to head: the hand is isolated and the rest contains a cycle. Move the other endpoint from elbow to that hand: every joint reconnects. Save and reload without losing the relation.',
'First visit with no file: the amber place must be empty. Then create a changed pose in Assembly, close that study and read here in another process. Compare all thirteen positions, all twelve edges and the edit count. Selecting another joint must not change the file bytes. A malformed copy must be refused rather than displayed as a plausible body. For the optional note, predict before editing, retain a wrong prediction if it occurs, then finish with your own observation and reason. Assert that later edits make the note a record of the earlier pose, and that saving the note does not rewrite the pose file.'
]

def code(name):
    return f'### `{name}`\n\n<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8").rstrip()}\n```\n\n'

def main():
    for i,(hall,key) in enumerate(zip(HALLS,KEYS)):
        new=[]
        if i==0:new+=['study_base.gd','assertions.gd','check.gd']
        if MODELS[i]:new.append(MODELS[i])
        if key=='assembly':new+=['pose_file.gd','observation.gd']
        new += [key+'_study.gd','assert_'+key+'.gd']
        previous='Foundations Crisis' if i==0 else TITLES[i-1]
        s=f'# {TITLES[i]}\n\n**Learning elements**\n\n'+''.join('- '+x+'\n' for x in ELEMENTS[i])+'\n'+INTRO[i]+'\n\n'
        s+='## Continue the student folder\n\n'
        if i==0:
            s+='Use Godot 4.6 in this museum project. Create `res://doc/book/studies/postcrisis-lineage/` (or your own folder). Carry `point_body.gd` and `line_skin.gd` unchanged from [Euclid](../Euclid_Parallel/tutorial.md), `bench.gd` from [Russell](../Russell_Paradox/tutorial.md), and `reports.gd` from [Florensky](../Florensky_Paraconsistent/tutorial.md). Those complete printed files supply the frozen XR/desktop point, finite cylinder, initialized labels/buttons and support-pair operations. Their relative filenames must stay together. No other student dependency is hidden.\n\n'
        else:
            s+=f'Keep the files from **{previous}** in the same student folder. Add the complete files below; their relative preloads use that carried folder. The sphere, cylinder renderer, bench and pickup adapter are reused without being explained or rebuilt again.\n\n'
        s+=f'The supplied [`{key}.tscn`](../../../doc/book/studies/postcrisis-lineage/{key}.tscn) opens this actual hall and mounts your working copy beside its existing exhibits. It supplies the museum player, lighting and room. In [`{key}_museum.gd`](../../../doc/book/studies/postcrisis-lineage/{key}_museum.gd), set the `LESSON` preload to your `{key}_study.gd` if you used another folder, then run the scene with F6. Grip the point in VR; on desktop use the existing right-click carry/release interaction. Buttons are the museum\'s supplied `push_button.tscn`.\n\n'
        s+='## Complete new code\n\n'+''.join(code(n) for n in new)
        s+='## Predict, run, change one thing\n\n'+PREDICT[i]+'\n\n'
        s+=f'The assertion file above runs against your model files. From the project directory, use your Godot executable with:\n\n```text\nGodot --headless --path . --xr-mode off --audio-driver Dummy --script res://doc/book/studies/postcrisis-lineage/check.gd -- res://doc/book/studies/postcrisis-lineage/assert_{key}.gd --no-bridges\n```\n\nAdjust the two script paths if your student folder differs. A failed assertion is a failed lesson check; `PASS` must be printed and the process must exit successfully. This headless check does not establish headset readability. Also exercise the visible controls in the supplied museum launcher.\n\n'
        s+=f'Carry onward: **{TITLES[i+1]}** will reuse these operations.\n' if i<7 else 'Return to an earlier artifact with a particular change and an observation to test. A record makes that return possible; it does not settle its consequences.\n'
        (ROOT/'commons/maps'/hall/'tutorial.md').write_text(s,encoding='utf8')
    (OUT/'lesson-manifest.json').write_text(json.dumps([{'hall':h,'key':k,'title':t} for h,k,t in zip(HALLS,KEYS,TITLES)],indent=2))
    print('Printed eight complete tutorials')
if __name__=='__main__':main()
