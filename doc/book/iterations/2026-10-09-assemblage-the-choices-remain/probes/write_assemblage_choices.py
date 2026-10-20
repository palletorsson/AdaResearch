from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/lsystems-through-the-hands/Assemblage_Same_Desire'
O=R/'doc/book/iterations/2026-10-09-assemblage-the-choices-remain'
M=R/'commons/maps/Assemblage_Same_Desire'
def code(name): return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
t='''# Assemblage — the choices remain

## Learning elements

- A recorded sample, a threshold decision and its mark
- Changing interpretation without drawing again
- An independent witness, including its alphabet
- A fixed-size row queue
- Perceived paths, addresses and physical support

In Curves, one sentence passed through different readers. Living kept a design while editing continued. Shape Grammars selected which faces could receive the next operation. Here the earlier two-mark textile returns: keep its choices and change what they draw.

## Begin with the installed comparison

Press RESET and HOLD at the existing desk. Follow a few diagonals. ALPHABET changes them into horizontal and vertical bars, then large and small blocks. Compare the same cells with the witness. Their decisions have not changed; their marks have.

Return to diagonals and press ODDS. At 0.75, more of the same samples can choose A than at 0.5. ALPHABET changes representation. ODDS changes decisions. SEED changes the samples. None of these operations asks whether your eye can find a path.

## Reconstruct that separation

Keep the prepared Endless Museum, camera, floor, player and XRTools. Put these three files together and attach `assemblage.gd` to a unit-scale Node3D in your working copy. The small study fits beside the installed desk at hall-local (3.2,0,7.5), yaw 180 degrees. Its two sheets and floor drawing are smaller than the installed comparison; both use the same 12×12 address order. They add no surface collision.

The familiar point changes ALPHABET when its held trigger is pressed. The keyboard also provides A: alphabet, O: odds, H: hold, Space: one row, N: next seed and R: reset. Pickup and hand movement alone do not edit the sheet. Other keyboard actions can first be tried through the museum's existing six buttons; the small program does not rebuild that console.

### Keep what the choice came from

`sheet.gd` holds twelve rows of twelve cells. Each cell stores a sample and a tint. The source draws both, in that order. Omitting the tint draw would shift all later samples, even if we did not care about the colour variation.

`choices()` compares each sample with the current threshold using strict `<`. It draws nothing. `glyph()` then maps the Boolean result to a size and angle; it also draws nothing. Changing either interpretation leaves the random generator at the same state.

The record's row zero is the oldest row, displayed at the bottom. STEP removes that row and appends one new row at the top. The eleven surviving rows keep their cell values. Their current row addresses change.
'''+code('sheet.gd')+'''
### Keep the witness's interpretation too

`keep()` copies the nested record, including rows, odds and alphabet. A copy of only the outer dictionary would still share its rows. A copy of only the samples would not say which marks the witness used.

The display begins with a witness. HOLD replaces it. Later changes and RESET affect only the editing record. Repainting both sheets reads their separate records. This is a local snapshot of a visible result: it does not save to disk or capture the random generator state for resuming the held sheet's future rows.

On the wall, row zero appears lowest. On the floor, the same row/column address receives a fixed position, with row zero at the far edge. This follows the installed floor mapping; it is not a rigid rotation of the whole wall image. Each mark turns onto the floor individually. No neighbouring cell is consulted and no route is computed.
'''+code('assemblage.gd')+'''
### Carry the point

Use the same PointBody from the preceding halls. Its action signal selects another alphabet. Release returns the point to the front of this study.
'''+code('point_body.gd')+'''
## Predict, then change the reader

1. HOLD the diagonal sheet, then cycle all three alphabets. Samples, decisions and A count should stay fixed. Returning to diagonals should recover the same marks and tints.
2. Change odds from 0.5 to 0.75. Only samples in `[0.5,0.75)` change from B to A. A half-threshold does not demand exactly 72 of the 144 cells. A sample exactly equal to the threshold is B.
3. STEP once. The old second row becomes row zero; the oldest row disappears. Twelve new samples and twelve new tints enter. The witness stays. RESET restores the opening editable sheet, but keeps the witness you most recently held.
4. In `glyph()`, change only the blocks line from `0.9 if a else 0.3` to `0.3 if a else 0.9`. Now A draws the small block. Predict unchanged samples, choices, count, colour and addresses, with the large and small sizes exchanged. Run the complete edited program and compare it with the original.

The same seed reproduces the same draw sequence in this Godot version and call order. For the result itself, keep the actual samples. A seed alone is not a promise of identical output across engine versions.

## Leave room for the other works

Walk across the floor marks. The museum supports you whichever way they lean. Turning them into walls would require collision geometry and an explicit definition and test of connectivity. A maze-like picture has not supplied those things.

The loom, credited pattern galleries, dragon bench and formal-limit objects remain separate encounters. This tutorial reconstructs the two-mark comparison; it does not turn a weaving draft into an L-system or a displayed sentence into a proof.

The sequence has moved from rewriting symbols to reading, building, selecting and retaining results. Here we end by separating what the program chose from the connections we saw. Procedural generation will add another decision: a score used to compare what was made.
'''
(M/'tutorial.md').write_bytes(t.encode('utf-8'))
f=(O/'before/commons/maps/Assemblage_Same_Desire/final.md').read_text(encoding='utf-8')
needle='HOLD lets one resulting sheet remain beside these experiments.'
assert f.count(needle)==1
f=f.replace(needle,needle+' The witness keeps its alphabet as well as its choices; otherwise the same decisions could return wearing different marks.')
(M/'final.md').write_bytes(f.encode('utf-8'))
print('Assemblage tutorial and targeted reflection written.')
