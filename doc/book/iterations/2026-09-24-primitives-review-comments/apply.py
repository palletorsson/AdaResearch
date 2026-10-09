from pathlib import Path
import json,hashlib,re,shutil
root=Path.cwd(); out=root/'doc/book/iterations/2026-09-24-primitives-review-comments'
base=json.loads((out/'baseline.json').read_text())
changed=[]
def update(rel, pairs=(), add=None):
 p=root/rel
 assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel], 'Changed concurrently: '+rel
 s=p.read_text(encoding='utf-8-sig')
 for old,new in pairs:
  assert s.count(old)==1,(rel,old[:90],s.count(old))
  s=s.replace(old,new)
 if add:s=s.rstrip()+'\n\n'+add.strip()+'\n'
 p.write_text(s,encoding='utf-8',newline='\n');changed.append(rel)
update('commons/maps/Point_One/final.md',[
 ("Alice's rabbit is already ahead. There are functions we would like to open, but we still have a point to find.","Like Alice after the White Rabbit, we could keep following one opening into another. But we still have a point to find."),
 ('One format leaves the body without a printed address.','One format leaves the body without a printed address. Writing a position differently is another change we can make without moving it.'),
 ('```gdscript\nvar p := Vector3(1.0, 0.5, 0.0)\n```',"The screen's example gives the position a name:\n\n```gdscript\nvar point_position := Vector3(1.0, 0.5, 0.0)\n```"),
 ("An earlier version confined the point to the arrows' span. A drawing made to explain movement had also been deciding where movement could end. The frame now keeps describing the point outside that span.","A drawing made to explain movement could also become a limit on movement. Here the guides keep following your hand."),
 ('Carry the point towards it without letting go. Watch for the falling balls.','Carry the point towards it without letting go, and watch what falls.')])
update('commons/maps/Point_One/technical.md', add='''## Secondary point and the shared entrance — review decision, 24 September 2026

The entrance window and Point One are read as one arrival, as the author requests. `folding_past` remains museum lobby furniture; the book anchor does not imply a token in the grid map. Loading only the grid hall omits that window.

The Fontana puncture at source cell `(12,11)` retains its embedded `interactive_point_origin_force` as a secondary encounter. The main reading follows the named `point_one_main` point between the cards and frame. It need not enumerate both bodies. The target accepts either eligible point, as described above; this is an additional way to play with the existing arrival, not an error requiring the secondary work's removal. A dedicated “move this point there” encounter at the puncture is an optional future development, not a control added in this pass.

The pickup label currently cycles plain coordinates, named X/Y/Z components, a `Vector3(...)` spelling, and no label. Older source-header shorthand describing integer/scientific/word formats is inaccurate; the executable match in `interactive_point_origin.gd` is the evidence.

The coloured frame previously confined the point to its displayed axis span. That implementation history belongs here; the current chapter asks the visitor to carry the point beyond an arrow's end and watch the guides continue.''')
update('commons/maps/Point_Lines/final.md',[
 ('but the player could not pass through it.','but you could not pass through it.'),
 ('Lines on monitors seem to meet;',"On the workshop's four monitors, lines turn, cross and pull apart;"),
 ('In VR, the X and Z come from the headset; the line is drawn near floor level. On desktop it follows the walker.','The X and Z come from your headset; the line is drawn near floor level.')])
update('commons/maps/Point_Lines/technical.md',add='''## Review clarification — 24 September 2026

The main reading's monitors are the four live camera studies in `line_space_workshop`, placed at source cell `(16,16)`. Their private three-dimensional line arrangements animate through crossings, separated joins and changes of plane. They are distinct from the secondary `sketch_monitor` with its parallel scan lines and from the three `perspective_lines` placements. See the [workshop source notes](../../artifacts/line_space_workshop/README.md).

The chapter follows a headset visit. `player_trace` reads the headset's horizontal position and the rig origin for height; on desktop its actual fallback follows the walker. The platform distinction remains here rather than interrupting the walking passage.''')
update('commons/maps/Point_Trace/final.md',[
 ('Four pens wait on the shelf beneath the whiteboard.','Four pens and an eraser wait on the shelf beneath the whiteboard.')])
update('commons/maps/Point_Line_Grid/final.md',[
 ('Here the table names each kept position in metres and in whole-number steps from the origin.','Here the table shows the last ten kept positions, naming each in metres and in whole-number steps from the origin.'),
 ("In VR, lean with your feet planted. The recorder can respond: it follows the headset horizontally, using the rig's origin for height. On desktop it follows the walking body.","Lean with your feet planted. The recorder can respond: it follows your headset across the floor."),
 ('An address lets us recognise a return. It does not tell us why we came back.','The address marks a return; your reason for coming back has stayed with you.'),
 ('Is it still your bend at this size? If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and let go. The whiteboard and walking recorder keep separate records.','Is it still your bend at this size?[^point-grid-carry]'),
 ('In VR, entering gives each hand a pen.','Entering gives each hand a pen.'),
 (' On desktop, follow the same addresses with your walk.',''),
 ('A shared address can help us repeat a placement, coordinate a meeting, begin a level. It cannot decide which of those things we should want.','A shared address can help us repeat a placement, coordinate a meeting, begin a level. Which of those uses would you want to take further?')],
 add='''[^point-grid-carry]: If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and release it. That release sends the record onward. The whiteboard and walking recorder keep separate records.''')
update('commons/maps/Point_Line_Grid/technical.md',add='''## Recording and platform scope — review clarification, 24 September 2026

The snapping sphere's table displays the latest ten retained positions while the count can be larger. Both table columns describe retained positions, one in metres and one in lattice indices.

The walking recorder takes X/Z from the headset and height from the rig's origin; its desktop fallback follows the walking body. The book follows the headset visit. The plan's controller-mounted pen pair requires active tracked controllers; on desktop the numbered plan remains available to walk across, without those pens.''')
update('commons/maps/Point_Triangle_Context/final.md',[
 ('![Three identical sets of points A, B and C:', 'The wall plate places the same three corners side by side: first as points, then as a boundary, then as a face.\n\n![Three identical sets of points A, B and C:'),
 ('unclosed: green corners joined into an open path.','unclosed: pale corners joined into an open path.'),
 ('The side instrument distinguishes **filled loops** from **triangles**.','The side instrument counts **loops** and **triangles** separately.'),
 ('If your bend turned back on itself anywhere, the fill has just reached into somewhere your hand never went.','If your bend turned back on itself, the fill may have reached into somewhere your hand never went. Look for a patch beyond the boundary.'),
 ('Next, faces meet at a corner. What must we add to enclose a volume?', 'Try the four-edge puzzle too. Its closed outline still has no face. Nearby, the quad joins two triangular patches along a diagonal. Move a corner away from that diagonal: one patch follows while the other stays. Move an end of the diagonal and both change. Four corners have given us two faces that can tilt differently. Remember their shared edge when a cube offers you what looks like a single square.\n\nNext, faces meet at a corner. What must we add to enclose a volume?')])
update('commons/maps/Primitives_Polythedra/final.md',[
 ('Turn the tetrahedron beside it.','Turn the tetrahedron a few steps on.'),
 ("Approach it through the game's movement controls.",'Walk up to it.'),
 ('Read one blue arrow,','Read one arrow on its blue disc,')])
update('commons/maps/Primitives_Polythedra/technical.md',add='''## Museum corner construction — review clarification, 24 September 2026

The chapter follows the endless museum build. Its pink architectural corners are created by `endless_museum.gd` through `em_simplex_corners.gd`, reading the map's `museum.simplex_corners` configuration. They are part of the room, not independently placed artifact tokens. A grid-only load does not construct those corners. The chapter's small held polyhedra and the architectural corner therefore need separate source lookup paths.''')
update('commons/maps/Primitives_Portals/final.md',[
 ('There are twenty members in this family.','These are portals for looking through: rings that frame the space beyond. There are twenty members in this family.')])
update('commons/maps/Primitives_Melencolia/final.md',[
 ('Ten rooms ago we said','In the first room we said')])
# Keep JSON formatting intact; this is a ledger correction, not a reserialization.
update('commons/maps/sequences/primitives.json',[
 ('\t\t"Point_Triangle: Three Points Close a Boundary",\n',''),
 ('Point_Triangle_Context: Triangles Applied','Point_Triangle_Context: Closing a boundary, adding a face'),
 ('"Primitives_Melencolia: Melancholy of Finitude",\n\t\t"Chamber_Primitives: Catalyst chamber \\u2014 first mark. Receive the bracelet, fire at targets, meet the FOE."','"Primitives_Melencolia: Melancholy of Finitude"')])
update('commons/grid/GridInteractablesComponent.gd',[
 ('\t"hits", # target hit threshold; never a tutorial rotation shorthand','\t"discovery", # numeric encounter opt-in, not tutorial yaw shorthand\n\t"hits", # target hit threshold; never a tutorial rotation shorthand')])
# Give live book figures stable publication paths without breaking old review pages.
figures=[]
for m in json.loads((root/'commons/maps/sequences/primitives.json').read_text())['sequences']['primitives']['maps']:
 p=root/'commons/maps'/m/'final.md'; s=p.read_text(encoding='utf-8-sig')
 matches=list(re.finditer(r'/book-review/(doc/book/iterations/[^)]+/figures/[^)]+\.png)',s))
 for match in matches:
  source=root/match[1]; rel=f'doc/book/figures/{m}/{source.name}'; dest=root/rel
  dest.parent.mkdir(parents=True,exist_ok=True)
  assert not dest.exists(),str(dest)
  shutil.copy2(source,dest)
  figures.append({'map':m,'source':match[1],'canonical':rel,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
  s=s.replace(match[0],'/book-review/'+rel)
 if matches:
  p.write_text(s,encoding='utf-8',newline='\n')
  if p.relative_to(root).as_posix() not in changed:changed.append(p.relative_to(root).as_posix())
(out/'figure-provenance.json').write_text(json.dumps(figures,indent=2)+'\n',encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Applied targeted changes:',len(changed),'files; stable figure copies:',len(figures))
