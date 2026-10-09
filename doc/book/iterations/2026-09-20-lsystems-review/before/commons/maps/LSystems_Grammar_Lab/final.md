# The same sentence, another body

<!-- @lsystem_editor -->

Two upright lines meet us. Below each, the same letter: `F`. Can one sentence have two bodies?

Press NEXT once. The live line acquires turns; the held line stays where it was. Count the live segments before looking at the counter. Then press HOLD. Both drawings now share this sentence:

```text
F+F-F-F+F
```

Leave NEXT alone. Press TURN. Follow the first bend across the two drawings. The letters below them have not changed. One reading turns through ninety degrees; the other now turns through a hundred and twenty. Five drawn segments in each, yet the same route through the symbols takes another route through space. Some segments may overlap. Count the instructions as well as the lines you can distinguish.

We brought a construction out of the fractal halls. Here we can separate two moments within it: making a sentence, and reading that sentence as movement. HOLD gives us time beside a previous reading. TURN changes the live interpreter's angle. NEXT rewrites the sentence from which it draws.

Keep the new angle and press NEXT again. The held drawing remains. The live sentence has forty-nine symbols and twenty-five drawing instructions. The turning signs also take up space in the string; they do not each leave a segment. What has multiplied, and what has merely been carried forward?

RULE opens the replacement used by this preset: each `F` becomes `F+F-F-F+F`. In `lsystem_editor.gd`, the next sentence is assembled from the old one:

```gdscript
var new_string = ""
for c in _current_string:
    new_string += str(_rules.get(c, c))
_current_string = new_string
```

A symbol without a replacement passes through as itself. The newly written letters wait for the next generation; they are not rewritten again during this pass. First one `F`, then five, then twenty-five. The small loop has a rhythm, and a place where its repetition must wait.

Another pass through the resulting string gives it geometry. `F` and `G` advance the turtle and draw. `+` and `-` turn its heading. The turtle is a travelling state: position, direction and a sideways axis. A line does not tell us all of that state by looking like a line.

Try RESET, then PRESET three times to reach PLANT. There is an `X`, and no line above the live plinth. We have encountered an invisible point before. This absence has a different cause: `X` belongs to the rewriting rules, but this interpreter gives it no drawing action. Press NEXT. Drawing instructions appear around the `X` symbols. What was undrawn was still capable of contributing to the next sentence.

The brackets now matter. `[` saves the travelling state; `]` restores it. A branch can end without forcing every later segment to continue from its tip. The next hall will let length enter that inheritance too.

Look again at the two outlines. Each is fitted to its display. More instructions need not make a taller body here. That apparent continuity of size is another operation, performed after the turtle has travelled. Our eyes receive a composed result: rewriting, interpretation, fitting, thickness, light. None is the untouched original behind the others.

This desk stops at four requested generations, with a budget of 4,096 symbols. If a replacement would exceed that budget, the last complete generation remains. Its readout distinguishes the generation shown from the one requested. A long printed sentence also declares that only its first 120 symbols are visible. Two different limits, two different kinds of remainder.

Seven presets give us places to begin. They do not exhaust the bodies that a grammar could permit; the physical desk does not yet let us type a new rule. Nor does a changed outline automatically make another space habitable: these thin drawings have no collision surfaces. The desire to inhabit them brings another body, another requirement, into the question. Which operation would we have to open next?

<!-- @ -->

The earlier trees, string study and city grammar remain beyond the desk. Their resemblance can invite a comparison without proving that they share its live sentence. Carry the bracket into the next room: what must a branch remember so that another branch can begin?
