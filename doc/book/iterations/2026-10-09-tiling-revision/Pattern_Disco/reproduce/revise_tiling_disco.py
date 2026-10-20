"""Continue at Tiling without repeating Noise's earlier encounter review."""
from pathlib import Path
import hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Disco'
MAP=ROOT/'commons/maps/Pattern_Disco'
STUDY=ROOT/'doc/book/studies/tiling-lineage'

def block(name):return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8").rstrip()}\n```\n'
def main():
    before=OUT/'before';before.mkdir(parents=True,exist_ok=True)
    for n in ['tutorial.md','final.md','map_data.json']:
        if not (before/n).exists():shutil.copy2(MAP/n,before/n)
    carried={
      'palette.gd':'doc/book/iterations/2026-10-06-colour-complete-drafts/Color_Grid_Pallet/palette.gd',
      'grid_surface.gd':'doc/book/iterations/2026-10-06-colour-complete-drafts/Color_Grid_Pallet/grid_surface.gd',
      'point_body.gd':'doc/book/studies/noise-lineage/point_body.gd'}
    for name,source in carried.items():shutil.copy2(ROOT/source,STUDY/name)
    (OUT/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
    if not (before/'plan-entry.json').exists():(before/'plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Pattern_Disco'),indent=2)+'\n')
    text='''# Pattern Disco — keep the pattern, change its colours

## Learning elements

- Pattern values and displayed colours.
- Two-stage lookup: choose a palette, then an entry.
- Phase as an input to a repeating rule.
- A local clock and a held comparison.

## The floor we already know

Step onto the museum's checker. Its colours can move without carrying your feet. Stop the musical sequencer, then HOLD the visual pattern. Choose CHECKER. Press COLOUR and watch one square. Now leave the palette alone and press ONE STEP. The two operations can produce a different picture for different reasons.

Arrays gave us addresses. Colour gave us an assigned colour and the small `Palette` class. We keep that class and the same 5 × 5 cube-tile receiver from the Colour review draft. The new work is the separation between a calculated zero or one and the colour used to display it.

## A small continuation inside the museum

Attach `01_palette_return.gd` to one empty Node3D in your existing learner space, at floor level with unit scale. Put `palette.gd`, `grid_surface.gd` and `point_body.gd` beside it. All four files are printed here. The museum still provides the player, camera, lights, XR Tools and grip/trigger actions. This small grid is a display at table height, with no supporting collider; the installed 12 × 12 dance floor remains the place to walk.

The point is the familiar grabbable sphere. Hold it and move it left of the study's centre, then press the trigger to change palette. In the middle, trigger advances one step. On the right, it toggles PLAY/HOLD. These regions use the host's local X coordinate: left below −0.3 metres, middle from −0.3 to +0.3, right above +0.3. Move to a region before pressing; carrying the point alone changes nothing.

We begin held, with navy and pink. The grid helper is carried unchanged, including its earlier address marker and readout; this script hides those two and supplies the new instruction label.

### The new rule and its controls

'''+block('01_palette_return.gd')+'''
In the grid's `Vector2i`, `x` is the column and `y` is the row along local Z. Adding the two coordinates gives neighbouring squares opposite parity. `posmod(..., 2)` returns zero or one. Adding `phase` makes one step exchange them; a second step restores the visible arrangement even though the counter has advanced to two.

`palettes[palette_index]` selects a Palette object. Its `colours` list supplies the pair; `pair[value_at(address)]` selects the colour for this address. Changing the pair leaves the address and calculated value intact. This is a shared assignment: every zero receives one colour, every one the other. The earlier Grid lesson could leave one address changed; this rule repaints all addresses.

`cycle_palette()` changes neither phase nor elapsed time. `step()` advances phase and starts a fresh interval. PLAY counts elapsed seconds; the loop consumes every completed half-second and keeps the remainder. HOLD preserves that remainder. This small study has one clock and no audio. In the installed hall the score has its own clock, so hold both instruments for a still comparison. The installed console also offers other patterns and a shader-drawn triangle mode; they remain encounters outside this checker reconstruction.

### The Palette class, carried unchanged

Colour introduced owned state and methods here. We use its `colours` list without advancing its `index`: the pattern value chooses an entry, not `next_colour()`. Each instance copies the supplied choices into its own list.

'''+block('palette.gd')+'''
### The addressed cube grid, carried unchanged

This supplied renderer retains the earlier BoxMesh, 25 fixed transforms and dictionary from address to instance index. `write()` changes only an instance colour. Its unshaded material makes the assigned colours easier to compare; it does not model illumination or claim how they will feel to every viewer. The old `mark()` method remains available for the earlier lesson but is not called here.

'''+block('grid_surface.gd')+'''
### The inherited point

The body supplies pickup and its action signal. The new lesson connects that signal to `choose()`. We set its starting position before adding it to the physics tree, as in the earlier point lessons.

'''+block('point_body.gd')+'''
## Make the distinction disappear

First predict the values at (0, 0), (1, 0) and (1, 1) at phase zero. Check them against 0, 1 and 0. Advance once: they become 1, 0 and 1. Advance again: the arrangement returns. Follow one fixed cube throughout.

Now edit only the navy/pink pair in the script: replace both entries with `Color(0.4, 0.4, 0.4)`. Predict before running: all 25 tiles should be grey. ONE STEP should still exchange the underlying zero/one values while leaving the displayed colours unchanged. Change to another palette and the checker should become visible again, at the current phase. Its geometry should never move.

Explain why a still-looking surface does not establish that its input has stopped. Then choose your own two different colours and keep the phase fixed while comparing them. A test can verify the assignment; you decide which relations the colours make easier to see.

## Carry a source onward

This hall calculates its motif. Foundry will let us edit and retain a small source, then read it repeatedly onto different receivers. Carry the distinction between the source values, the rule that reads them and the surface that displays them. The rest of the disco remains available to dance with.
'''
    (MAP/'tutorial.md').write_text(text,encoding='utf8')
    final=(before/'final.md').read_text(encoding='utf8')
    start=final.index('The separation is small enough to find in the code:')
    end=final.index('![Two palettes',start)
    final=final[:start]+'''For the square-cell patterns, each address produces a zero or a one. One choice selects a palette; the value selects one of its two colours. A square can keep its value and receive another colour because we have changed the pair it draws from.

'''+final[end:]
    (MAP/'final.md').write_text(final,encoding='utf8')
    print('Wrote Pattern_Disco; preserved installed scene and museum configuration.')
if __name__=='__main__':main()
