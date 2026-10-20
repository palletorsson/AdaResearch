"""Revise the fifth Randomness pair without changing the museum's dice."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HALL=ROOT/'commons/maps/Random_Cubes'
STUDY=ROOT/'doc/book/studies/randomness-lineage'
BEFORE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Cubes/before/commons/maps/Random_Cubes'

def main():
    code=(STUDY/'05_a_continuing_die.gd').read_text(encoding='utf8').rstrip()
    point=(STUDY/'point_body.gd').read_text(encoding='utf8').rstrip()
    text='''# A six permits another draw

## Learning elements

- Six discrete outcomes.
- An ordered history and a running total.
- A continuation rule.
- A closed chain versus a display limit.
- Separating the source of a result from what the result does.

Find the single die beside the column marked SIX / THROW AGAIN. A three adds three blocks and ends the chain. A six adds six blocks and permits another throw. The die has not changed its number of faces. The rule has changed what a face can do.

In 10 PRINT, one draw chose between two marks. Here it chooses an integer from one to six. We keep the local generator and familiar PointBody action, then return to the cube as a unit of height. Trace taught us to keep a list; Arrays taught us to visit its entries. Now the list grows until its latest value closes a rule.

## Reconstruct the rule in the museum

Work in your copy of the prepared Endless Museum. Add an empty `Node3D` under Random Cubes and attach `05_a_continuing_die.gd`. Keep `point_body.gd` beside it. The player, lighting, camera and XR Tools are already supplied by Day Zero. A tested temporary bay is hall-local `(1.3, 0, 11.8)`, Y rotation **90 degrees**, facing into the room. This small column and its plinth are visual; they add no physical obstacle.

Hold the point above **DRAW** and press the trigger. One action requests one result. **REPLAY** clears the record and restarts the same seed; press DRAW to reproduce its outcomes. **NEXT SEED** clears the record and prepares another stream. These controls use the point's local position, as in the previous lesson.

The label says **CODED DRAW**. Our generator supplies the number directly. The installed die gets its number from a settled physical orientation. Both can feed the same continuation rule, but a seeded number is not a reconstruction of your hand's throw. We are isolating the rule before rebuilding a whole dice simulation.

<!-- student-code:05_a_continuing_die.gd -->
```gdscript
__CODE__
```

## Read one event

`draw_face()` first checks whether the chain is closed or limited. If so, it returns zero without asking the generator for another number. Zero means **no draw** here; it is not a seventh face. Otherwise `randi_range(1, 6)` includes both endpoints and returns one of the six integers. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

`accept_face()` is the boundary between an outcome and its consequences. It rejects values outside one through six. For an accepted value, it appends to `history`, adds to `total`, then asks `continues(face)`. Six leaves the chain open; any other face closes it. This function also lets us test the rule with known inputs without pretending those inputs were random throws.

Follow six, six, three on paper. The record becomes `[6, 6, 3]`; the running total becomes six, twelve, fifteen. The third event closes the chain. Fifteen alone cannot tell you how it was made. Keeping the ordered values lets the column show its sections and the label retain its equation.

`draw_record()` makes that record visible. The cubes are already built, so it only changes visibility and colour. `offset` locates the first free unit after each section. Alternating colours and dark joins distinguish successive events, including two sixes in a row. Redrawing consumes no random numbers and adds nothing to the total.

## Two different reasons to stop

The display has room for five draws. Five sixes occupy thirty units, but the continuation rule still says again. The label therefore reads **DISPLAY LIMIT / UNFINISHED**. If the fifth result is three instead, the chain is **CLOSED**. Reaching the apparatus's budget is not the same event as satisfying the stopping rule.

The order of the assignments matters: determine `closed` first, then set `limited` only if the chain remains open. The next press must leave the record and generator unchanged in either terminal state. Nothing waits inside a long `while` loop; another draw needs another action.

## Change one decision

First change only `continues(face)` to return `face >= 5`. Five and six now permit another draw. Keep the seed and replay. The outcomes agree up to the first place where the old rule would have stopped; the changed rule may reveal more of the same stream. This gives more opportunities to continue, not a promise that every run becomes longer. With known inputs six, five, two, the original rule closes at eleven; the changed rule reaches thirteen and then closes.

Next restore the six-only rule and set `max_draws` to `3`. Three sixes now leave an unfinished chain of eighteen units. Six, six, three closes at fifteen even though it uses the final place. The script builds the corresponding number of units and moves the amber limit with it. Explain these two endings before increasing the display again.

For a direct rule check in the running scene, call `reset_run()`, then `accept_face(6)`, `accept_face(6)` and `accept_face(3)` in that order. The expected record is exactly `[6, 6, 3]`, total fifteen, closed true and limited false. A following `accept_face(4)` must return false. These are supplied test inputs. Use `draw_face()` for the generator experiment.

The physical exhibit has one further responsibility: only a fresh release followed by a settled result may enter its record. It ignores repeated readings of the same landing and distinguishes RETURN DIE from NEW CHAIN. That event handling stays with the existing exhibit in this lesson; our point action provides one clearly identified request at a time.

## The inherited point

Keep the same file from the previous hall. It builds its own sphere and collider; XR Tools supplies its pickup, release and action signal. The complete dependency is printed here so no mesh or helper is hidden in a scene.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

You leave with a small procedure: request an outcome, retain it, add its contribution, decide whether another event is allowed. Next, the retained change becomes a turn. A cube's orientation can accumulate increments even when no column remains to show their order.
'''.replace('__CODE__',code).replace('__POINT__',point)
    (HALL/'tutorial.md').write_text(text,encoding='utf8')
    final=(BEFORE/'final.md').read_text(encoding='utf8')
    final=final.replace('How much can one throw tell you about a die?','Two diagonal marks filled the previous room. Here six faces wait on a body you can lift. How much can one throw tell you about a die?')
    final=final.replace('Nothing inside the cube knows that six means again:\n\n```gdscript\ntotal += face\nclosed = face != 6\n```','Nothing inside the cube knows that six means again. We add its value to the height, then use that same value to decide whether another throw is allowed.')
    final=final.replace('The number enters twice:', 'The tutorial beside this encounter lets us change that permission while keeping a coded stream of outcomes. It cannot replay the movement of your hand.\n\nThe number enters twice:')
    (HALL/'final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
