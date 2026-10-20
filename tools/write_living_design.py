from pathlib import Path
R=Path(__file__).resolve().parents[1];S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Living';O=R/'doc/book/iterations/2026-10-09-living-a-design-kept'
def code(n):return '\n<!-- student-code:'+n+' -->\n```gdscript\n'+(S/n).read_text(encoding='utf-8').rstrip()+'\n```\n'
t='''# Living — a design kept

## Learning elements

- Design records and parameter ranges
- Rounding and clamping a requested value
- A generated rule and a generated body
- Independent retained specimens

Competition kept the instructions fixed while their conditions changed. Living lets us change the values from which instructions are made. You bring rewriting, a saved turtle state, the point in your hand, and the distinction between an editable record and its copy.

## Start with the existing sculptor

Press RESET, then HOLD. The editing tree now has a witness beside it. Depth starts at 4.000. Press MORE four times. The value reaches 4.800, but both trees still agree. One more press reaches 5.000: the editing tree adds a generation.

The generator halves Depth, rounds, then clamps the result between two and five. At 4.8 it reads 2.4 and selects two generations. At 5 it reads 2.5 and selects three. A changed input does not always make a changed instruction.

The black point on the front rail edits the selected gene through horizontal hand movement. Its held trigger performs HOLD. GENE selects another gene; PLANT keeps a floor specimen. Release before choosing another gene. The original sliders remain at the side. All act on the same editing design.

## Build a small version in the museum

Put these four files together and attach `living.gd` to an empty, unit-scale Node3D in a clear working bay of the prepared museum. The project already supplies the floor, camera, player and XRTools. Keep your existing `point_body.gd` and `line_skin.gd`; their copies below are unchanged. No prepared mesh or named scene child is needed.

The study makes three display positions: editing at (−2,0.78,−2.5), held at (2,0.78,−2.5), planted at (0,0.035,−8). Leave a clear bay around them and a bypass. In a working copy, the original sculptor can be hidden for comparison at its host; this does not require replacing the museum's primary artifact. The small drawing has no branch colliders and does not change the floor.

We keep three inputs: Depth, Forks and Angle. Arrange stays on the source's opposite-branch recipe; taper stays 0.7; the starting step is 1.2 metres. Leaves, roots, twist and droop stay off. The cylinders retain the line's familiar thickness rather than reconstructing the source's tapered bark. This is the same parameter-to-rule relation with a smaller presentation, not every feature of the sculptor.

### The design becomes instructions

In `design.gd`, `parameters()` converts the record to counts and an angle. `rules_for()` makes F become S followed by the requested forks. S becomes FF on the next rewrite. The opposite-branch recipe alternates + and −; later pairs also roll the turtle's frame. The slash is a roll instruction, not division in the sentence.

The rewrite function is unchanged from the earlier lessons. Its symbol budget is raised explicitly to 32,768 so this bounded three-gene range can be generated before the separate 200-command drawing limit is applied. These are different limits: one bounds sentence construction, the other bounds its display.
'''+code('design.gd')+'''
Read `parameters()` and `rules_for()` first. Those are the new connection between a design and its grammar. The reader continues the saved-state pattern. F advances and shortens the next step; S advances sixty percent of a step without shortening it. A bracket saves position, direction, orientation and current length. Returning restores them all.

This reader handles only sentences made by `rules_for()`. It is not a parser for arbitrary user text. Its added S and roll operations reproduce the bare, opposite-arranged subset of the museum turtle. They do not require a new general grammar language. The readout separates requested commands, commands read, and visible cylinders: a command can be counted even when its segment is too short to draw.

### Keep the record when the design changes

`living.gd` holds three records: the editable one and two optional copies. HOLD replaces the witness; PLANT replaces the floor specimen. Neither edits the other. RESET restores only the editing design.

`keep()` uses `duplicate(true)` to store a separate dictionary. This study rebuilds a specimen from its retained recipe whenever the display refreshes. The installed sculptor instead copies its built geometry and its larger DNA resource. Both preserve the design at the moment of the action. A reproducible record depends on the builder too: these records are recipes for this version of `design.gd`, not a promise that future algorithms will produce identical bodies.
'''+code('living.gd')+'''
G selects a gene; the arrow keys decrease or increase it on the same normalized 0.025 grid as the museum buttons. H holds, P plants, R resets. In VR, move the point along the rail and use its held trigger to keep a witness. Picking it up without moving leaves the value alone, including values between hand detents. Release parks it at the current setting. The small program rebuilds immediately; the museum waits 0.3 seconds after an edit and flushes that pending rebuild before HOLD or PLANT.

### Carry the known point and line

These two files are unchanged from Competition. The action connection and the design record give them their new job.
'''+code('point_body.gd')+code('line_skin.gd')+'''
## Make a prediction you can check

1. Hold the opening design. Increase Depth through 4.2,4.4,4.6,4.8. Confirm that the sentence and segment endpoints remain equal to the witness. At 5.0, confirm that the generation count and sentence change while the witness remains at 4.0.
2. Select Angle. Change it and predict which record changes: the sentence, the generation count, or the segment endpoints? Angle changes the interpretation; the sentence and its counts stay fixed.
3. Plant, then edit again. RESET must restore the opening editing design without changing either retained recipe. A later PLANT replaces only the planted recipe.
4. In the START dictionary, change only `"angle": 30.0` to `"angle": 45.0`. Run the complete edited program. Predict the same sentence and number of commands, but different endpoints. Hold this version, change its angle again, then rebuild directly from the held record to verify that the retained body returns.

These snapshots live in this running scene. The small program does not save to disk, export catalyst DNA or move its specimens into the next hall. The installed PLANT also exports an independent DNA resource for an older catalyst consumer, which can mutate and rescale it; that is a separate operation.

## Which changes remain unavailable?

At maximum Depth and Forks the source recipe requests 4,964 F/S commands. This study, like the installed preview at its current detail level, reads at most 200. A complete-looking tree may be a partial reading. Three controls also cannot request a branch reconnecting to an earlier branch, a new alphabet, or a body that remakes the floor. Those need another operation or another builder.

Keep the difference between raw values, compiled instructions and a displayed body. Next, Shape Grammars returns to the cube and makes its face operations available to a design record.
'''
(R/'commons/maps/LSystems_Living/tutorial.md').write_bytes(t.encode())
f=(O/'before/commons/maps/LSystems_Living/final.md').read_text(encoding='utf-8')
f=f.replace('Press HOLD. Now there are two:', 'Press HOLD, or hold the black point on the front rail and press its trigger. Now there are two:')
a=f.index('The tree generator reads that value through this line:');b=f.index('First halve the raw number.',a)
f=f[:a]+'The tree generator converts it to a rewriting count.\n\n'+f[b:]
a=f.index('Now the export begins by making a copy:');b=f.index('The hall also copies',a)
f=f[:a]+'The export now keeps an independent copy of the design at the press.\n\n'+f[b:]
(R/'commons/maps/LSystems_Living/final.md').write_bytes(f.encode())
print('Wrote Living tutorial and reflection.')
