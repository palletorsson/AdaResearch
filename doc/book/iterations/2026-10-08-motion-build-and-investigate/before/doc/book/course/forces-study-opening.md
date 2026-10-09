# Forces — one body gains responses

Walk through the existing Endless Museum. Try the artifact first, then reconstruct one operation with the point you built earlier. The room contains more than the tutorial asks you to make. Return to those larger experiments when you want to combine what you have learned.

The point gains motion, force, resistance and attachments. The cube returns when support and shape matter. In the last hall, the points move you.

## Set up once

Keep `point_body.gd`, `free_point.gd` and `study.gd` in one Forces study folder. Their [complete source](forces-shared-code.md) accompanies the lessons:

- `point_body.gd` is your unchanged Lines point: sphere, collider and pickup.
- `free_point.gd` extends it with physical release. Gravity and damping begin at zero; each lesson changes these settings when needed.
- `study.gd` supplies a caption, a button and a thin cylinder for drawing relations. Each lesson contains its own motion or force rule.

Use your existing `PointStudy` Node3D in a clear working bay inside each hall, with a floor-level origin and scale `(1, 1, 1)`. Save each lesson script and replace the script attached to `PointStudy` as you proceed. You carry the class and your saved code; a single physical sphere does not automatically travel between halls.

The museum supplies the floor, lighting, camera and XR hands. These scripts use its installed Godot XR Tools and the declared `push_button.tscn`. The flight lesson also uses the existing capability court’s player movement adapter.

## Compare, then combine

Predict one change before editing. Restart the study to compare from the same beginning. Use metres, kilograms and seconds throughout. After the comparison, return to the larger artifact: another body, a second push or a changed release can make the next event harder to predict.

Each lesson keeps the complete code visible. “Model notes” records the limits and implementation details you may want to revisit after the first experiment.
