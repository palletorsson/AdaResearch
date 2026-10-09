from pathlib import Path
import json,sys,shutil,hashlib
sys.stdout.reconfigure(encoding='utf-8')
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-arrays-review-comments';changed=[]
def edit(rel,pairs):
 p=root/rel;s=p.read_text(encoding='utf-8-sig')
 for a,b in pairs:
  assert s.count(a)==1,(rel,a,s.count(a));s=s.replace(a,b)
 p.write_text(s,encoding='utf-8');changed.append(rel)
edit('commons/maps/Array/final.md',[(
'Find the four numbered positions.',
'Find the row of four cubes with labels above them. A second line across the hall counts another direction, with its numbers on plates at the cubes’ feet. Begin with the row whose labels hang above.'),(
'Select one layer and reset the changes.',
'The frames arrive already displaced. Press DEPTH until it reads 1 / 4, then RESET.'),(
'then four layers seen from the side.', 'then all four layers seen at an angle.')])
edit('commons/maps/Tutorial_3D/final.md',[(
'On desktop, look and use WASD, with Space to rise and Ctrl to descend. In VR, the left stick follows the tilted left controller.',
'Push the left stick forward to travel where the left controller points: aim upwards to climb, downwards to descend, level to cross the enclosure. Push the stick sideways to move across that aim.'),(
'Choose an address, approach its cube and collect it by contact. Return to the console and select that address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:',
'Find the cube at the address you selected before entering. Approach and collect it by contact.\n\nHover where the cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The array records cubes, not everything that could exist there. What would have to change for it to notice you?\n\nDescend and leave through the ground-level opening. Back at the console, read the same selected address. Its value is now zero. The other cubes have not slid into the vacancy. This small record writes collection as an absence:'),(
'The console reads zero while the visitor hovers at that place. Native views of the working museum.',
'The console inset is a separate view of the readout outside the enclosure; it is read on returning to the doorway.'),(
'Hover where a cube used to be. For a moment, your body occupies the neighbourhood of a recorded absence. The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?\n\n', ''),(
'Keep those changes separate as you descend.', 'Keep those changes separate as you leave.')])
edit('commons/maps/Tutorial_Tiling_Walls/final.md',[(
'Near the far end, on the right, the same pattern reaches a narrow part of the museum wall.',
'Near the far end, beyond ONE EXCEPTION, the same image reaches a narrow part of the museum wall. It stretches across the tall sheet: each triangle is now more than twice as tall as it is wide.'),(
'/book-review/doc/book/iterations/2026-09-23-tiling-wall-and-outside/two-turns.png',
'/book-review/doc/book/figures/Tutorial_Tiling_Walls/two-turns.png')])
edit('commons/maps/Tutorial_Disco/final.md',[(
'The console controls this visual clock. Beside it, the sequencer has another.',
'The console controls this visual clock. The sequencer stands near the entrance, six metres to the right of the console as you enter. It has another clock.'),(
'Choose the empty pattern and turn on one cell.',
'The sequencer starts with an empty pattern. Turn on one cell.'),(
'The remainder returns here as `step % 12`:','The bridge uses `step % disco_floor.grid_width`, taking the remainder by this floor’s width:'),(
'/book-review/doc/book/iterations/2026-09-23-disco-separate-clocks/fixed-addresses-changing-values.png',
'/book-review/doc/book/figures/Tutorial_Disco/fixed-addresses-changing-values.png'),(
'/book-review/doc/book/iterations/2026-09-23-disco-super-triangle/triangle-combinations.png',
'/book-review/doc/book/figures/Tutorial_Disco/triangle-combinations.png')])
# Preserve evidence of the autonomous floor mutation before any later agent development.
for m,stem in [('Array','agent-diagnostic'),('Tutorial_Tiling_Walls','wall'),('Tutorial_Disco','disco')]:
 run=root/'ada_run/encounter_pilot'/m;dest=out/stem;dest.mkdir(exist_ok=True)
 for f in ['report.json','source_manifest.json','stdout.log','spec.json']:shutil.copy2(run/f,dest/f)
 if m=='Array':shutil.copy2(run/'grid-agent-current.png',dest/'grid-agent-current.png')
figs=[]
for m,name in [('Tutorial_Tiling_Walls','two-turns.png'),('Tutorial_Disco','fixed-addresses-changing-values.png'),('Tutorial_Disco','triangle-combinations.png')]:
 src=root/'ada_run/encounter_pilot'/m/name;dst=root/'doc/book/figures'/m/name;dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copy2(src,dst)
 evidence=out/name;shutil.copy2(src,evidence)
 figs.append({'map':m,'source':evidence.relative_to(root).as_posix(),'canonical':dst.relative_to(root).as_posix(),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'capture':'Native Godot viewport frames assembled by the capture probe, with MushroomHand desktop overlay hidden. Geometry and controls unchanged.'})
(out/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Updated four manuscripts; unchanged floor chapter retained; three fresh native figures published.')
