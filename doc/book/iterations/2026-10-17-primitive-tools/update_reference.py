from pathlib import Path
import json,sys,shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
def read(p):return p.read_text(encoding='utf-8-sig')
def write(p,t):p.write_text(t.strip()+'\n',encoding='utf-8')
def save(p):
 dest=HERE/'before'/p.relative_to(ROOT)
 if not dest.exists():dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
maps=ROOT/'commons/maps'
p=maps/'Point_Trace/technical.md';t=read(p);old=t[t.index('## Retained development material'):]
write(p,'''# Point Trace — recording rules in the installed hall

Current arrangement, 17 October 2026: pens on transparent glass, three held spatial beads, the sampling monitor and ball ramp. The 24 × 24-cell map and its museum plan use the same placements. Older studies below are retained development history, not the current installation.

## Glass contact

`glass_paint_wall` extends the existing whiteboard with a 3.0 × 1.1 m clear pane. Its bottom is 0.75 m above the hall floor. The two supports and feet stand on the floor; a thin collision box occupies the pane. The four plain pens and eraser use the existing shelf and return behaviour.

`glass_surface` / `config_glass` is an opt-in flag. The body uses an alpha material; the dry-ink canvas starts with transparent pixels, draws opaque ink, and erases to alpha zero. Ink renders from both sides. Other whiteboards retain their white canvas and white eraser. At this aspect ratio the image is 1024 × 375 pixels; it is a bounded image, not a growing mesh archive.

The pen's nib must be within the writing rectangle and 0.035 m of its drawing plane. Leaving that range ends the stroke. Four pens use no positional grid, 10 mm, 40 mm and 80 mm respectively before mapping accepted contacts into image coordinates. The ungridded pen still produces a pixel image. Brush radius is three pixels; eraser radius is twenty-two.

Shelf tools are pickable through desktop and XRTools. On release they fall; leaving their dock by more than the return threshold invokes the existing delayed return. The glass image stays in this hall for this visit and is not published to TraceData.

## Beads in space

The three `draw_dot` placements opt into `#tool:bead`. A small pickable sphere replaces the former pen; its centre is the observed point. The held tool supports desktop pickup hooks and XRTools' snapped grip state. Recording waits for the pickup to settle and stops on release. Beads ignore nearby board planes, so proximity to the glass cannot flatten the spatial trace.

The recorder keeps its existing five-millimetre movement gate, 4096-position capacity, and 10/40/80 mm world-coordinate rounding. The movement gate compares against the last gate-passing reading; immediately repeated shaped positions are omitted. Returning to an earlier address after another retained position is allowed. A stationary pause does not encode its duration.

Adjacent retained positions become straight segments. Neither the samples nor these joins recover the whole motion. The plinth panels show the current count and last ten retained world positions. They stay fixed at the stations. The sampling monitor discovers the same recorder scripts after the tool replacement and can compare several spacings applied to a retained source gesture.

## Transfer and its limits

On release, at least two retained positions are copied into the `TraceData` autoload. This is session storage, not a disk save. Neither colour nor timestamps travel with the list. Grid reads existing lists and listens for later releases. It recentres and scales the positions for pink, and rounds their displayed coordinates for green; source positions remain unchanged.

The tutorial independently implements a small scene-file archive at `user://ada_student_trace.scn`. Its persistence belongs to that student program, not to the museum's session store. The ball ramp records its centre after release and retains its path locally; it also does not publish to TraceData.

## Arrangement

Entry is (12,0). Glass (7,5) precedes beads (4/6/8,11); the sampling monitor stands at (2,10). The ramp at (18,14) has a clear run toward the rear. Telemetry, science screen and film occupy row 21. Exit is (12,23). Coordinates refer to source cells.

'''+old)
p=maps/'Point_Line_Grid/technical.md';t=read(p)
t=t.replace("the whiteboard's painted image","the glass wall's painted image")
write(p,t+'''

## Selecting a source entry — 17 October 2026

The map's `grid_lines` opts into `#selection:1`. Each incoming trace receives an identity and retains a reference to its pink rendering. Selection stores that identity and a source-list index, not a rounded position. The marker uses the same bounding-box centre, scale, display transform and snap spacing as the two rendered traces. Snapped duplicates retain separate source identities even when the green polyline omits a consecutive duplicate.

Visible coordinate rows and small points on the displayed source page accept the common desktop/XR pointer PRESSED event. POINT − / POINT + changes the index and brings its page into view. PREVIOUS / NEXT changes only the visible page; NEXT TRACE replaces the old AUTO function for this opt-in placement. Selection does not edit the archive. New arrivals select their first entry; up to ten trace records remain selectable in the existing readout buffer.

The numbered pink point, smaller green point and connecting segment expose the selected correspondence. The readout distinguishes source coordinates from recentered/scaled display coordinates. Museum transfer remains in-memory; tutorial scene-file persistence is a separate implementation.
''')
p=maps/'Point_Animatedcube/technical.md';t=read(p);tail=t[t.index('## Folding changes another set of data'):]
write(p,'''# A cube compared, replayed and changed

The current primary route is a linked cube pair, the folding net, the prefab library, then the sorting conveyor. The outline, diagonal plate and other works remain side encounters. The two former independent builder placements have been replaced by one `paired_cube_diagonals` instrument.

## One displacement, two triangulations

`paired_cubes.gd` composes two existing builders with independent vertex and triangle arrays. Their default automatic reveal is disabled. Both begin complete at identical local vertex coordinates, with centres 1.9 m apart. A's positive-Z face uses [4,5,7] / [5,6,7]; B uses [4,5,6] / [4,6,7]. The remaining connections match.

Initially only A's corner 6 admits pickup. Moving it updates A's geometry and copies the corresponding positions into B. The seven other A positions remain fixed. Moving corner 6 outward by 0.25 m changes the front surface at its projected centre by 0.125 m on B while A's 5–7 midpoint stays at the original depth. This compares geometric surfaces, not just the drawn diagonal lines.

Amber diagonal cylinders and differently tinted front patches make the relation visible. The wrapper replaces the builder's reverse-copy meshes with one outward-normal triangle per patch. A worktable supports the encounter, but the displayed cube surfaces are not collision enclosures. Pickup handles are the interactive bodies.

## Three controls

- RESTORE returns both arrays and their handles to the initial positions.
- REPLAY reveals 8 vertices, 12 edges and 12 patches at 0.13-second intervals around the current positions. It preserves deformation and temporarily disables pickup.
- FREE / ONE permits all A handles to move, then returns to the controlled single-corner constraint. B remains linked. Returning to ONE fixes the seven control corners at their initial positions.

Restore and replay decline while an A handle is held. Controls use the existing physical/pointer push buttons on a compact upward-facing rail. There is no PAUSE or DIAGONALS control on this instrument; the old standalone builder still provides its existing controls elsewhere.

The workshop is 27 × 36 cells. The paired table is at (13,6); a five-cell opening at row 11 leads to the net (13,16), library (5,24) and conveyor (20,25). Source-cell placement and primary order are recorded with the map.

'''+tail)
p=maps/'Primitives_Melencolia/technical.md'
write(p,'''# Current tableau variation — 17 October 2026

The placed `durer_scene` opts into `#figure:skull`. Its scene builder replaces only the main seated figure with a small procedural skull on a block. The stone, smaller winged figure, dog, sphere, tools, architecture and instruments remain. Unconfigured copies of the scene keep their original figure.

The skull is an original stylised study, not a scan or anatomical specimen. CSG unions form the cranium, face and jaw; subtracted volumes make the eye sockets, nose opening and mouth gap. Small separate meshes form the teeth. A local label marks the substitution as an Ada variation on Dürer's engraving. The changed final describes this installed variation.

Native captures and the implementation receipt are in [the review](../../../doc/book/iterations/2026-10-17-primitive-tools/index.html). The following older research draft retains historical context; its placements and instructions are not a description of the current tableau.

'''+read(p))
p=maps/'Point_Line_Grid/summary.md'
write(p,read(p)+'''

## Selection update — 17 October 2026

Selecting a coordinate row or displayed point highlights the same source entry on pink and its rounded counterpart on green. The index survives coincident snapped addresses and page changes. POINT − / POINT + moves between entries; NEXT TRACE selects another drawing. Geometry, data and their correspondence can now be inspected together. The layout and other encounters are unchanged.
''')

# Update only these two maps' ruled thread; preserve all other map decisions.
roles_path=ROOT/'commons/data/artifact_roles.json';save(roles_path)
roles=json.loads(read(roles_path))
for name,primary,secondary in [
 ('Point_Trace',['glass_paint_wall','draw_dot','trace_ball_ramp'],['trace_sampling_monitor','hand_telemetry_diptych','science_screen','film_foundation_trace']),
 ('Point_Animatedcube',['paired_cube_diagonals','polyhedron_nets_cube','prefab_box_library','cube_sorting_line'],['cube_lines','cube_diagonal_plate','film_cube_corner','first_shadow','first_phosphor','wooden_pallet','hangar_supply_pile','crate','station_crates','glove_box','pyramid'])]:
 for token in primary:roles['roles'][name][token]='primary'
 for token in secondary:roles['roles'][name][token]='secondary'
 roles['order'][name]['primary']=primary
 roles['order'][name]['secondary']=secondary
write(roles_path,json.dumps(roles,indent=2,ensure_ascii=False))
# Reuse the producer's thread function for a scoped refresh, not a whole-spine regeneration.
sys.path.insert(0,str(ROOT/'tools'));import build_spine_artifact_order as producer
producer.ROLES=roles
spine_path=ROOT/'commons/data/spine_artifact_order.json';save(spine_path)
spine=json.loads(read(spine_path));names={'Point_Trace','Point_Animatedcube'}
outside={r['lookup'] for r in spine['order'] if r.get('map') not in names}
out=[];done=set()
for row in spine['order']:
 name=row.get('map')
 if name not in names:out.append(row);continue
 if name in done:continue
 done.add(name)
 for token,role,by in producer.thread(name):
  if token not in outside:out.append({'lookup':token,'sequence':'primitives','map':name,'role':role,'by':by})
spine['order']=out
spine['_meta']['scoped_refresh']={'date':'2026-10-17','maps':sorted(names),'producer':'build_spine_artifact_order.thread','note':'Other map rows retained verbatim; aggregate metadata below refreshed.'}
spine['_meta']['artifacts']=len(out)
spine['_meta']['primary']=sum(r.get('role')=='primary' for r in out)
spine['_meta']['unruled']=sum(r.get('role')=='unruled' for r in out)
spine['_meta']['ordered_by']={b:sum(r.get('by')==b for r in out) for b in ['ruled','floor','file']}
write(spine_path,json.dumps(spine,indent=2,ensure_ascii=False))
print('References and two scoped reading orders updated.')
