# Point One — what comes down from the roof

The current chapter already has its necessary beginning: **I land.** Point Zero entrusts its weight to construction it cannot fully account for; Point One discovers that visible construction does not always support or obstruct that weight. This is the strongest connection between the chapters. It is already enacted by the landing and the white sphere, so it does not need an explanatory paragraph.

## What to carry forward

| Older text | Current encounter | Editorial judgement |
| --- | --- | --- |
| The name arrives before its object. | A floor label directs attention towards an empty place. No hidden sphere waits to appear. | Keep the failed inspection and sideways movement. Do not explain the absence as something broken or unfinished. |
| A point has no extent; making it visible adds a surface. | Two little white spheres give a position a body. | Keep the distinction and its difficulty. The sphere does not become the mathematical point merely because the label calls it one. The tutorial supplies the construction. |
| Appearance and collision are made separately and could disagree. | One white sphere can be crossed; the other has a matching spherical boundary. | The current text preserves the first half. The possibility of a boundary extending beyond the visible body is the strongest missing invitation. It belongs as a question or a later experiment, not a claim that this mismatch already occurs. |
| Light contributes to seeing without supplying the physical boundary. | The local rod lamps switch off while the solid sphere's collider remains. | Keep the changed foot placement in reduced light. It makes the relation bodily. The former removal of the sun and its long shadows should not be restored as current behaviour. |
| Making the point larger changes what it conceals and where a body can go. | The large black sphere and its pedestal occupy more floor and interrupt the view. | Keep both sphere and support. The same three-number centre cannot describe their extent, the detour, or the observer's interest. |
| Knowing how something was constructed need not finish our interest in it. | Model B tries to hold a moving highlight and attends to a well-lit empty station. | Essential. Protect this apparently unproductive attention. It need not become a repair, reward, or allegory of Model B. |
| The next room puts the point into the hand. | Coordinates begins with the inherited habit of walking around things, then offers a small black point that carries light. | Preserve the bodily handoff. The tutorial carries the same student point.gd forward; the fiction need not assert that the large pedestal sphere has literally travelled downstairs. |

## What the older versions still offer

An earlier combined chapter, preserved under `2026-09-30-point-one-companions/committed-before/`, says that a position has nowhere to keep hesitation or the reason a place was chosen. That is worth preserving as a constraint on our writing: coordinates are useful without exhausting the encounter. The present sentence, “The same short address leaves a great deal unsaid,” and the subsequent wish to hold a highlight already do that work.

That earlier version also had an invisible point located by arrows and intersecting lines. Its valuable idea is that a location can become available through surrounding relations without acquiring its own surface. The current empty station offers a weaker localisation: its label directs attention but does not uniquely establish a height. Keep Model B's refusal to invent that height. Do not describe the former glass case and arrows as installed on this floor.

The old Alice reference protected curiosity that runs ahead of a syllabus. The present return to the switch and the highlight can carry that impulse without restoring the reference by name.

## One small candidate, not yet installed

After the solid sphere's collision paragraph, before “For a while I go between them”:

> If the boundary extended beyond the white surface, I might have to stop in what looked like empty space. I look at the gap I have left between us. Some of it is mine.

This would recover the older invitation to separate visible extent, collision and bodily caution. It is proposed fiction; the current installation uses matching radii. “Some of it is mine” may be too neatly conclusive. The existing early-turning sentence already carries the habit well, so this addition should earn its place in an encounter reading rather than be added automatically.

## Source check and its limits

- The saved Point One floor contains absent, visible, solid and pedestal artifacts. All three small stations request `study_plinth: false`.
- `point_condition.gd` returns without creating a sphere for the absent station. Visible and solid use radius 0.14 m and centre height 1.12 m; only the solid variant creates the spherical collider. Configuration removes the absent station's default support.
- The pedestal variant uses radius 0.65 m, a dark glossy material, and a separately colliding support.
- `floor_content.gd` attaches lamps to the four point artifacts. `point_light_switch.gd` changes those lamps on its floor; it does not disable the sphere colliders or the world lighting.
- The tutorial creates one solid point, changes radius and height, then independently disables collision and visibility. It passes that same script into Coordinates.

These are source findings. No new native or headset capture was made for this reading. Exact highlights, shadow lengths, successful body passage and the landing sightline still require runtime observation. The old review's praise is literary feedback, not evidence of those behaviours.

## Next encounter comparison

1. Landing: look back towards the roof, then towards the three labels. Check whether the spatial invitation supports this beginning.
2. Equal-looking white spheres: traverse each with the same player rig. Record the actual passage and stopping point.
3. Switch: hold one camera pose and compare on/off, then test the same solid boundary. Avoid treating general darkness as proof of collision.
4. Large black sphere: move around it, retaining the pedestal in frame; observe what occludes the view and how the highlight changes.

The canonical final.md and tutorial.md are unchanged in this pass. The decision is to protect the existing chapter and expose the one missing possibility for review, rather than replace a working passage merely to make it new.
