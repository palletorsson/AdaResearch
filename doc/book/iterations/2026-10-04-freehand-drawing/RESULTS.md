# Freehand drawing test

4 October 2026. Native Godot 4.6, Forward+, desktop mouse input.

The brush can make a new drawing independently of the preset knot or spherical boundary. The same drawing survives switching between soft colour, transparent shells and small luminous points.

Two tests were used:

- An actual desktop interaction drew three pink strokes into a triangle, then a separate cyan stroke closer to the camera. The mouse wheel changed depth; B changed representation. The drawing contained 269 stored marks. See `manual-session.json` and the manual captures.
- A repeatable input replay drew an irregular face, hair and shoulders using eight separate mouse strokes. It produced 584 marks at four depths spanning 0.9 metres. All 32 checks passed. This is an authored test path sent through the drawing input handler, not a portrait drawn by a person's hand and not a reconstructed Mona Lisa.

The test found and fixed a focus-loss bug: switching away during a held stroke could leave the brush depositing marks. The study now ends the stroke when its window loses focus. Both failing checks in `before-fix.json` pass in `verification.json`. Native stderr is empty after the fix.

The useful result is visible from the side: the eyes and nose separate from the outline. Depth belongs to the drawing. It was deliberately assigned through the wheel, rather than inferred from the face.

## How it feels to control

Separate strokes, colour changes and material switches are straightforward. The small luminous points preserve the drawing most clearly. Shells give it a thicker body and expose overlap. Soft colour makes broad marks legible but loses fine detail sooner.

Depth requires a second action: wheel movement or drawing after moving the camera. The floor guide helps locate a stroke, but this remains a desktop drawing plane that can move through space. A headset and tracked hand would supply depth differently and have not been tested.

Holding still intentionally adds more marks and can make a bright bead. Fast strokes receive intermediate samples; the brush does not automatically smooth or correct their shape. At 900 marks it recycles the oldest, so the current study is suitable for small drawings, not unlimited work.

## Try it

Open the updated project in Godot 4.6 and run it. Press **5**, then **C** for an empty drawing. Press **[** two or three times for a narrower brush. Draw with the left mouse button; release to lift the pen. Use the wheel to change depth, **X** for the next colour, **B** to change representation and **Shift + left-drag** to orbit. **Z** undoes a stroke. **F5** saves locally and **F9** reloads that save.

The test writes its own `manual-drawing.save` and `portrait.save` here. It does not change the user's F5 save.
