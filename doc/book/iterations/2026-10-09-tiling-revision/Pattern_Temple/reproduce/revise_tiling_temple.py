"""Initial Temple pair: select a receiver, copy a recipe, retain independence."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Pattern_Temple'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Temple';S=R/'doc/book/studies/tiling-lineage'
O.mkdir(parents=True,exist_ok=True);(O/'before').mkdir(exist_ok=True)
if not (O/'before/state.json').exists():
 (O/'before/state.json').write_text(json.dumps({n:(M/n).exists() for n in ['tutorial.md','final.md']},indent=2))
 for n in ['map_data.json','intent.md','blurb.md']:shutil.copy2(M/n,O/'before'/n)
 (O/'before/plan-entry.json').write_text('{"absent": true}\n')
carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Symmetry_Seventeen/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
for n,p in carried.items():assert (S/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
(O/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
def block(n):return f'<!-- student-code:{n} -->\n```gdscript\n{(S/n).read_text(encoding="utf8").rstrip()}\n```\n'
t='''# Pattern Temple — the same, for now

## Learning elements

- Selecting a receiver by its index.
- Keeping separate settings for separate objects.
- Copying a recipe without linking later edits.
- Repainting the affected receiver.

## Read the room

At DRESS THE TEMPLE, TARGET moves the gold marker between eight surface groups: floor, far wall, east wall, west wall, entrance wall, columns, dome and frieze. Selecting a group does not change its pattern. SOURCE, GROUP, PALETTE and SEED change the selected group's settings. Start with one of the fixed sources, such as STARS; imported studio packages have their own settings.

Press ALL. The selected recipe is copied to the other seven groups. Now press PALETTE once. Only the selected group changes. ALL was an action taken once; it did not establish an ongoing connection.

Each group owns a material. The columns share their group's material with one another; a wall does not share that material with the columns. A recipe can agree across groups while the surfaces keep separate materials, orientations and texture coordinates. The same settings need not produce the same apparent spacing or silhouette.

## Carry the small construction

Keep our black point, palette, five-by-five receiver and the source from Symmetry. Keep its P1, PM and PG address operations. Make two receivers visible together: a table and a wall. Each gets its own source record and rule number. This is the small part of the temple that we will reconstruct.

Replace the previous entry script with **06_receivers.gd** on the same learner Node3D inside the museum. Keep its root at unit scale. Keep the three unchanged files printed below beside it. The museum supplies the player, camera, light and XR Tools. This replaces the small display; it does not replace the installed temple or add another player.

We rewrite the entry because it now manages two receivers. The familiar lookup accepts an extra `i`: whose source should it read? The supplied `GridSurface` still builds the same twenty-five cubes. The controls for changing the earlier receiver's width and orientation are no longer needed in this comparison: its two poses stay fixed.

Grip the point. Hold it above TARGET and trigger to change the selection. RULE cycles that receiver's reading. ALL copies its recipe to the other receiver. Hover the point over a selected cube and trigger to paint the source entry it reads. Hovering alone changes nothing. A point over the unselected surface cannot paint it; select that receiver first.

### 06_receivers.gd

'''+block('06_receivers.gd')+'''
## What is being copied?

`recipes[i]` is a dictionary: a record with the named entries `source` and `rule`. The source is still a list of rows. The rule is still a number. `target` selects one record and its corresponding receiver. Nothing about choosing another index requires rebuilding the cubes.

`duplicate(true)` copies the dictionary and its nested rows. Assigning `recipes[i] = recipes[target]` would make both entries refer to the same dictionary. A shallow `duplicate()` would separate the dictionaries but leave their source rows shared. Either could let a later paint edit reach a surface we meant to keep independent.

The local `data` in `choose()` deliberately refers to the selected recipe's rows: painting must reach that record. We copy when independence is needed, and refer to the existing record when editing it. The initial `source` remains a template; the two working copies change separately.

The installed temple stores scalar recipe values rather than our nested rows. Its ordinary dictionary copy is sufficient for those values; each material then renders from its copied settings. Our deeper copy answers the different shape of our data. Neither version copies the architectural geometry.

## Predict the next action

Both receivers begin with the familiar source and PG. Addresses here are `[row, column]`.

1. Keep TABLE selected. Hover at surface `[0,3]`. PG reads source `[1,2]`, value 1: pink. Trigger once: that source entry becomes 2, mint. Its copies change on the table; the wall stays pink at the corresponding address.
2. Use ALL. Both receivers now read mint there. The wall stays upright and the table stays horizontal.
3. Use TARGET to select WALL. Paint its surface `[0,3]`. Its value cycles from 2 to 0: navy. The table remains mint. Equal recipes have become different again.
4. Use RULE once. The wall goes from PG to P1; surface `[0,3]` now reads source `[0,0]`. Its source record is unchanged by the rule change. The table still uses PG.

Each paint action repaints all occurrences on the selected receiver, not just the cube touched. ALL repaints the other receiver after copying. TARGET only changes which receiver will receive the next edit.

## Make another case

Replace the template with `[[0, 1, 2, 0], [2, 0, 1, 2]]`. Keep two rows and all the other code. Predict before running: PG at surface `[0,4]` reads source `[1,3]`, value 2. Paint it and it cycles to 0. The other receiver retains 2 until ALL is used. After copying, change the wall's same entry once more: it becomes 1 while the table stays 0.

The source is now four columns wide. Its PG horizontal translation period is eight cells, beyond this small five-column display. Use `source_address()` to compare addresses farther apart, as in Symmetry. The ownership question can be tested on one visible occurrence without displaying the whole period.

Try copying in the opposite direction as well. Can you make the table agree with the wall, then change the table without changing the wall? Explain which record each action reaches before using it.

## Return to the temple

Compare floor, wall and dome with the same recipe. Their shapes, orientations and mappings remain different. Our two flat receivers isolate selection and ownership; they do not reconstruct the temple's curved mappings or seventeen shader groups.

AGE changes weathering parameters in the selected material. CLEAN sets that appearance back to age zero on every group; it does not restore the original sources and palettes. This is a generated surface treatment, not elapsed time or a record of earlier visitors.

Carry the source and the distinction between a record, its copies and its receivers into Ribbon Patterns. The next question is how a source gains another index and how a surface reads through it.

## Complete carried files

These are unchanged from Symmetry. The new entry uses their existing geometry, palette and pickable point; it does not rebuild the point's behaviour here.

'''
for n in carried:t+='### '+n+'\n\n'+block(n)+'\n'
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# Pattern Temple — the same, for now

The pattern meets you on the floor. Ahead, it stands upright. Around the court, narrow columns turn it away from your eye; above, the dome carries it beyond a single view. You have seen the mark before. You have to move to see what it has become here.

At the desk, a gold point names the surface you are about to change. Move it from the far wall to the columns. The rest of the room waits.

Press ALL. A decision made for one surface reaches the others. For a moment the court agrees. The floor is still underfoot, the column still round, the dome still above you. Agreement in the settings does not remove these differences.

Change the selected palette once more. The room stops agreeing. The earlier button copied a decision; it did not bind the surfaces to every decision that followed. What looked like a single order was a set of separate records that happened to match.

The distinction is harder to read from the entrance. Repetition, height and the space between columns give the pattern an authority that a small source tile did not have on its own. We arranged the approach as well as the ornament. How much of the order belongs to the mark, and how much to the room that teaches you where to stand?

AGE makes the surface look worn. CLEAN removes that treatment. Neither action recovers the people who might have made, maintained or inhabited such a place. The signs of time can be assigned in a moment. An appearance of history is not yet a history.

Keep one wall different. It remains part of the court. Walk back across the patterned floor and look up again. Which difference can you still see from here?
''',encoding='utf8')
intent=(O/'before/intent.md').read_text(encoding='utf8')
intent=intent.replace('Sequence role: proposed for Tiling (patterns), after Symmetry_Seventeen, where the sequence\'s notes ask for volume and appearance. Draft of 2026-10-09 (Palle: "a Moorish temple where we can control pattern on different walls"); not yet in the sequence file.','Sequence role: in Tiling, after Symmetry_Seventeen and before Ribbon_Patterns_01. Tutorial: select a surface, edit its recipe, copy it to other receivers, then observe that later edits remain local. ALL copies values; it does not establish a live link. Initial tutorial/reflection pair: 2026-10-09.')
(M/'intent.md').write_text(intent,encoding='utf8')
(O/'spec-student.json').write_text(json.dumps({'lesson':'res://'+O.relative_to(R).as_posix()+'/learner/printed/06_receivers.gd'},indent=2))
print('Temple pair written; production artifact and map unchanged.')
