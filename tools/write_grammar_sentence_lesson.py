"""Authoring snapshot. Re-running intentionally replaces this hall's tutorial."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab'
M=R/'commons/maps/LSystems_Grammar_Lab'
opening='''# A sentence and a reading

**Learning elements**

- A string, an axiom and a dictionary of replacement rules.
- Parallel rewriting: read the old sentence, build a separate next sentence.
- Interpret symbols as forward movement and turns.
- Keep a reading while changing its angle.
- Distinguish construction, interpretation and display fitting.

## In the museum

At the editor desk, two upright lines begin with the same letter, `F`. Press NEXT once. Count the live segments before reading its counter. HOLD keeps that reading on the right. Now take the small black point and move it along the four angle positions. What changes when the sentence stays the same?

The point is the one we have carried through earlier lessons. Here its held trigger means NEXT: rewrite once. HOLD remains a nearby button. TURN offers the same angles without picking up the point. The cyan drawing is live; the rose drawing keeps its sentence and angle until you press HOLD again. This comparison lasts for the current visit, not between runs.

Start with RESET. The first rewrite has five `F` commands and four turning signs: nine symbols. Another rewrite has twenty-five drawing commands and forty-nine symbols. The turns take places in the sentence without drawing additional segments. A line can overlap another, so the visible outline alone cannot tell us the command count.

The desk's preset called **Koch** uses `F → F+F-F-F+F`. It is a different replacement from the four-piece, sixty-degree Koch construction we explored earlier. Read the production before assuming what the familiar name means.

## Continue from the recipe

In Fractal Synthesis, a recipe named the seed, operation and stopping depth. Here a **string** records the intermediate result. A **dictionary** says which string replaces each symbol. We reuse loops, functions, independent old/next data, PointBody and the cylinder that gives a line its thickness.

Use the prepared Endless Museum workspace. Place the four complete files below together. Attach `sentence.gd` to an empty, unit-scale Node3D on its floor, facing local +Z. The museum supplies the player, camera, lighting and installed XRTools. The script creates its own point, drawings and labels; there are no named scene children to prepare. This is a compact reconstruction of the existing desk's opening interaction, beside which you can compare your result.

Move the held point to choose 30, 60, 90 or 120 degrees. Trigger or Enter rewrites once; H keeps a reading; R resets only the live sentence and generation. C switches the live rules between the turning curve and Cantor, restarting from `F`. H is the desktop equivalent of the museum's HOLD button. The museum desk also includes other presets, rule readouts and furniture, supplied by its existing interface. The learner program has no virtual keyboard or hidden button helpers.

## Write first; read afterwards

Read `rewrite()` first. `rules.get(symbol, symbol)` looks up a replacement; the second argument keeps the symbol itself when no rule names it. The first loop checks the length of the proposed result against a 4,096-symbol budget. The second loop writes `next`. Only after the function returns does `advance()` replace the live sentence and increment its generation. New letters are never processed during the pass that produced them. This is a logical parallel replacement; it does not require multiple threads.

Read `read()` next. The turtle starts at zero, heading up. Each `F` or `G` stores two endpoints and advances one model unit. Lowercase `f` advances without storing a segment. `+` and `-` turn around the plane's normal, Godot's negative Z direction. These are planar drawings inside our three-dimensional room.

A symbol such as `X` can remain in the sentence without a drawing action. Brackets are deliberately rejected in this small reader: saving and restoring a branch state is the next hall's lesson. The full museum editor already supports them.

<!-- MODEL -->

## Keep one reading; change another

`keep()` constructs a fresh dictionary containing the text, angle and generation. These values are sufficient to reconstruct this reader's output. Later LIVE edits do not change HELD. We do not store mesh nodes as the record. The installed desk also keeps a copy of its already fitted endpoints; our smaller example redraws the saved sentence with its saved angle.

`choose()` changes the live angle without calling `rewrite()`. `_physics_process()` reads the held point in the study's **local frame**, so turning or moving the entire study does not change what the hand positions mean. Release parks the point by the current angle. Pressing the trigger calls `advance()`, which is a separate operation.

Each drawing is independently fitted to a 1.4-metre span. `draw_reading()` finds the endpoint bounds, centres the drawing and gives both axes the same scale. It changes neither the sentence nor its model endpoints. Thus the pictures are useful for comparing bends, but their apparent height does not measure growth. The cylinder thickness is also a display choice. The drawing has no collision surface.

The sentence readout shows at most forty symbols and names that truncation. The 4,096-symbol construction budget and four-generation limit are separate. Reaching the budget retains the previous complete generation. The full museum desk shows a longer, labelled 120-symbol prefix.

<!-- STUDY -->

## The carried parts

These two files are unchanged from our Fractals studies. Keep them available, but concentrate this reading on the new `rewrite()` and `read()` functions. PointBody supplies pickup, the action signal and the desktop-held query. LineSkin places a finite cylinder between the endpoints. Neither supplies a camera or rebuilds the museum.

<!-- POINT -->

<!-- LINE -->

## Predict, run, then change the rule

1. Start with the printed curve. Advance once, press H, then move the point from 90 to 120. Predict which values and endpoints can change. Verify that both sentences and segment counts stay equal, while HELD retains 90 degrees.
2. Advance again. Explain why the live sentence now contains forty-nine symbols rather than forty-five. The four turning signs from the previous generation pass through unchanged.
3. Change only `CURVE` in your own file to `{"F": "F+F"}`. Before running, predict the generation-two sentence, drawn count and path at 90 degrees. Keep the reader and renderer unchanged. The supplied test executes this edited file, not just the function from the original.

After making your prediction: the changed rule gives `F+F+F+F`, four segments and seven symbols. At 90 degrees its endpoint returns to the origin. Its bounds contain a square; at another angle the same sentence need not close. Closure is a property of this interpretation, not of the string alone.

## Return to the thirds

Press C for Cantor. The rules are `F → FfF` and `f → fff`. All symbols advance the turtle, but only uppercase F draws. After three rewrites, the twenty-seven advances contain eight drawn intervals. Divide every endpoint by twenty-seven: the positions and lengths match the third-cut, unit-normalized thirds construction from Fractal Synthesis. After four rewrites there are sixteen drawn intervals in eighty-one advances. The turn angle has no effect because this sentence has no turning commands.

Find the same preset at the museum desk: RESET, then PRESET seven times. The first seven named presets still occupy their previous positions; Cantor is now reachable as the eighth. This connects two implementations of one construction. The table's quarters and two-fifths recipes require different rules or step lengths; they are not produced by these F/f rules.

Carry the sentence and reader into **Growth**. At present the turtle has one position and one heading. A branch needs somewhere to keep those values while another line continues.
'''
for marker,name in [('MODEL','grammar.gd'),('STUDY','sentence.gd'),('POINT','point_body.gd'),('LINE','line_skin.gd')]:
    opening=opening.replace('<!-- '+marker+' -->',f'`{name}`\n\n<!-- student-code:{name} -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```')
(M/'tutorial.md').write_text(opening,encoding='utf-8')
# Keep the reflection's encounter; move its small implementation excerpt to the tutorial.
final=(M/'final.md').read_text(encoding='utf-8')
start=final.index('In `lsystem_editor.gd`,')
end=final.index('A symbol without a replacement',start)
final=final[:start]+'The next sentence is assembled from the old one, one symbol at a time.\n\n'+final[end:]
final=final.replace('Leave NEXT alone. Press TURN.', 'Leave NEXT alone. Take the small black point and move it to the next angle, or press TURN.')
final=final.replace('TURN changes the live interpreter\'s angle.', 'The hand changes the live interpreter\'s angle. Its trigger advances the sentence; the point has acquired another task.')
final=final.replace('Seven presets give us places to begin.', 'Eight presets give us places to begin. Cantor carries the thirds from the previous hall into letters: one symbol leaves a line, another crosses the gap without leaving one.')
(M/'final.md').write_text(final,encoding='utf-8')
# Fix the already-observed blocked onward portal at the authored rear opening.
path=M/'map_data.json'; data=json.loads(path.read_text(encoding='utf-8'))
assert data['layers']['utilities'][23][8]=='t'
data['layers']['utilities'][23][8]=''
assert data['layers']['utilities'][25][9]==''
data['layers']['utilities'][25][9]='t'
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Opening lesson written; generator unchanged; existing exit moved to rear opening.')
