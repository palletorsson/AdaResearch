# Colour: independent fresh-reader report

Date: 2026-09-21

## Reading boundary

I read `commons/maps/sequences/color.json` to establish the order, then read these nine current manuscripts, in full and in this order:

1. `commons/maps/Color_Context_Placed/final.md` — “Before we ask what colour is”
2. `commons/maps/Color_Flashlight/final.md` — “What reaches the surface”
3. `commons/maps/Color_Nails/final.md` — opening question: “What changes when a colour becomes part of the body you act through?”
4. `commons/maps/Color_Rainbow/final.md` — “More colour, another rainbow”
5. `commons/maps/Color_Pillar/final.md` — “The colour between the pillars”
6. `commons/maps/Color_Grid_Pallet/final.md` — “Find the colour again”
7. `commons/maps/Color_Paint/final.md` — “Before the hand”
8. `commons/maps/Color_Walls/final.md` — “The view has partitions”
9. `commons/maps/Chamber_Color/final.md` — “The colour lands”

I did not read earlier reviews, author notes, iteration summaries, other agents’ reports, or source implementations. I did not run the rooms. Accordingly, implementation descriptions below are manuscript claims, not independently verified findings. No manuscript was edited.

## Overall reading

The sequence has a coherent argument a beginner can feel: a stored colour does not decide an encounter alone. A lamp, a material, a position, a neighbour, a time-dependent image, and finally a receiver each do something with it. The argument grows through objects rather than arriving as a thesis followed by examples. The most successful passages ask for a small action, preserve one condition, and let the reader notice the consequence before naming an operation.

The sequence also makes a promising progression in agency. First I compare choices someone else has made; then I move a lamp, choose a bodily surface, repartition a rainbow, sample a field, write an exception, join another painter, change visibility, and trigger an operation whose consequences exceed my gesture. This is more substantial than a tour of colour effects.

The principal weakness is uneven support for reading code. The prose often helps me observe an operation more readily than it helps me predict its next result. RGB gains an embodied introduction, while HSV arrives inside executable notation before its components and ranges have a comparable handhold. Pillar, the chapter most dependent on that transition, is unusually compressed. A few brief additions there would do more than expanding every code block.

The poetry is strongest when it makes an observable discrepancy memorable. It becomes less persuasive when the text immediately interprets every discrepancy for me, or repeats that another implementation would have been possible without offering a fresh place to test that possibility.

## Progression and missing handholds

### 1. The opening establishes the right method, but spends a long time inventorying the room

“The geometry has stayed still. Colour gives you another way to gather it, or take it apart” names a comparison I have just been asked to make. The short array loop and “here, *next* becomes *above*” also connect familiar code to spatial arrangement economically.

The latter part becomes crowded: artistic references, two blues, a striped shaft, thirty stripes, six array entries, 6.2 metres, a former table-sized cap, and two further compositions of 7.2 and 7.4 metres. Some of this earns its place, especially the cap moving above my reach and whole configurations becoming parts. The exact three heights and internal name `ps07_kras_rainbow` do little for my next observation. A beginner can lose the comparison while trying to keep track of which column is now under discussion.

Keep the encounters that change the relation to my body, and reduce identification detail that does not orient me or explain a rule. This chapter should establish confidence for the next room; it need not exhaust its gallery.

### 2. Flashlight is an effective model for the later chapters

“If the middle grows too pale to distinguish, separate the pools again. Their edges give you somewhere to begin” is excellent pedagogical care. It gives me a recovery action when the exhibit stops being legible. The subsequent explanation of a light cone answers a question produced by my movement.

The RGB tuple is introduced here, but neither the 0–1 channel range nor the practical meaning of alpha receives a handhold. It is reasonable to leave alpha for Walls, provided the text clearly permits me to set the last number aside for now. Naming an unfamiliar fourth component and then moving on creates a small unnecessary loose end.

### 3. Nails makes coordinates bodily; Rainbow changes coordinate systems too abruptly

Nails asks me to move mainly along one axis, predict, and return. That is one of the sequence’s clearest learning loops. The line “Equal distances in the box need not feel like equal changes in the preview” makes a valuable distinction without pretending the exhibit settles perceptual colour science.

But a beginner still has no explicit numeric bridge from one edge of this box to the other. A sentence connecting the bounded position to a channel between zero and one would prepare the code that follows elsewhere.

Rainbow then introduces `Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0)`. The prose identifies HSV as something converted to RGB, but does not yet explain hue, saturation, or value. “Hue circle” was mentioned in the opening; saturation is used in Pillar; the cylindrical organisation arrives in Walls. Those later returns can deepen an introduction, but currently they have to supply it retrospectively.

Give HSV a short sensory introduction at its first operational use: going around a hue ordering, moving toward a paler colour at fixed value, and changing the value coordinate. Explain the normalized hue range and what portion `0.78` chooses. This need not become a complete theory of colour spaces.

### 4. Pillar needs one worked crossing between the walk and the equation

“The gaps between columns contain possibilities that the collection has not put into a body” is a strong reason to care about sampling. But the chapter moves directly from a field into `clampf`, `lerpf`, local coordinates, two divisors, and three HSV arguments. “One coordinate chooses a place along the hue range; another chooses saturation” describes the whole rule without showing how I can read one instance of it.

Add one small prediction: choose a row, hold hue still, compare its near and far samples, and explain which input changed from 0 toward 1. Identify `u` and `v` as normalized coordinates and show what the fixed `0.95` is holding. One endpoint calculation would make the formula usable while preserving the room’s pace.

“The field is larger than its former arrangement” also addresses a reader who knows an earlier version. I do not. Remove the comparison to the former arrangement or explain a visible reference that makes it meaningful in this encounter.

### 5. Grid builds the best bridge from rule to consequence

The address can be revisited; the mark stays when the selection moves; RULE overwrites it; the floor still supports me. Each distinction has a bodily or visible test. The explanation that `address.y` names the room’s z direction anticipates precisely the sort of notation confusion a beginner could have.

“The diagonal relationships were already inside that addition” would benefit from one pair of equal-sum addresses. For example, `(1, 0)` and `(0, 1)` make the relationship inspectable before it becomes a sentence to admire. This is a very small handhold, not a reason for a longer modulo tutorial.

### 6. Paint sustains the encounter, but asks me to absorb several kinds of code at once

The transition from replacement to accumulation is clear. The automatic gesture gives the reader something to observe before acting, and “Your gesture reaches a surface that has other business” makes the question of authorship materially available.

Then I meet two oscillations, normalized UV coordinates, ray hits, canvas proportions, pixel brush sizes, snapping, previous-frame sampling, GLSL, dissipation, and differing clocks. Most belong to the experience; their concentration is the concern. Keep the shared destination of the two input routes and the image’s changing memory as the main thread. Explain UV as an address on the canvas before showing it in the first expression, or let the equation follow that explanation.

“As in Trace” assumes a previous encounter this sequence has not established. I cannot assess whether that prerequisite exists. A few words recalling the relevant action would let the sentence work even if the name is unfamiliar.

### 7. Walls contains two strong lessons whose hinge could be more explicit

The glass/opaque experiment is particularly legible. The view/body disagreement is available before the material code arrives. The RGB cube and HSV cylinder finally supply spatial structures for both colour descriptions. Interpolation then makes the difference consequential: fixed endpoints do not specify one route.

There is substantial material here after the very short Pillar chapter. Keep the models and interpolation together, but prepare HSV earlier so Walls can become a return rather than an overdue definition. The existing contrast between coloured space and colour values arranged in space is useful; let the reader take a breath at that turn.

### 8. Chamber is a convincing provisional ending, with one distracting status sentence

The receiver reintroduces colour assignment, distance, a hue rule, geometry, collision, and persistence through one event. This earns its density because the chapter repeatedly separates what the eye received together.

“It does not put a bracelet on your wrist” refers to a possibility I have not been offered in these nine chapters. It reads as a reply to an absent design discussion. Keep the question of what can travel with a body, but establish its relevance through the mounted instrument and what remains after the reset.

The final invitation into the next hall is clear enough, although the ending could give me one explicit act of transfer first: name a colour value, the operation receiving it, and one condition I would change to test my account. That would gather the sequence’s method without turning it into a quiz with one aesthetic answer.

## Repetitions: earned returns and excess explanation

The following returns earn their place:

- **Address:** an array index becomes height; RGB becomes a reachable point; a field yields a sample; a grid address stores a change; a canvas address receives marks; models give values positions. The word develops rather than merely recurring.
- **Neighbour:** a previous stack element supplies an input; lamps contribute to a meeting; other colours alter a comparison; image neighbours enter a shader; panes overlap; distance decides participation. These are usefully different operations. Preserve those differences rather than treating all adjacency as the same mechanism.
- **Memory:** an exception persists until replacement, an image keeps altered traces, and a target resets while the surrounding floor stays changed. This progression is exceptionally clear.
- **Seeing versus entering:** the non-climbable arch is an early limit; glass makes the contrast central; Chamber brings it underfoot. The final return changes the stakes because support and trust become involved.

The recurring “this is chosen code, not the whole world” qualification is justified but approaches a house cadence. Examples include “These lamps offer RGB values to a renderer,” “No droplets, sunlight or wavelength calculation produce this particular rainbow,” “These limits are choices in this lesson’s code,” “None is the natural behaviour of code,” and “This glass does not calculate the wavelengths a real pane would absorb.” Keep distinctions that prevent a specific mistaken inference. Trim repetitions that simply announce constructedness after the action already established it.

Likewise, the frequent closing question is effective when it gives the next room a task. It is weaker when the paragraph has already supplied its preferred answer. Leave a little more room for a reader to find an unanticipated significance in the comparison.

## Passages worth protecting

- **Opening:** “The turns are already over. The movement is yours.” It locates transformation in a fixed object and a moving observer without a lecture.
- **Opening:** “An array has an order. The builder makes that order climb.” A precise bridge between code and space.
- **Flashlight:** “You cannot pick it up separately from the meeting that produces it.” The preceding experiment earns the patch’s provisional status as a body.
- **Nails:** “Name one choice the box gives you and another it does not.” A critical question grounded in an interface the reader has just used; it does not substitute editable colour for an account of identity.
- **Rainbow:** “Stay a moment with the possibility that the room is pleased you arrived.” This changes the reader’s relation to programmed celebration before its politics is discussed. Protect its generosity from added explanation.
- **Grid:** “The white outline has travelled. Your exception has not followed it.” Memorable and operationally discriminating.
- **Paint:** “White enters the work again. It is the direction of forgetting in this particular simulation.” The shader gives this image a specific material cause; the qualification belongs here.
- **Walls:** “Your view took a route your body could not.” The later floor encounter strengthens rather than uses up this sentence.
- **Walls:** “The agreement about where to begin and end did not decide how to travel.” An exact account of the observed interpolation choice with interpretive room around it.
- **Chamber:** “A return can reset one part of an encounter while leaving another part altered.” It gathers the sequence’s concern with persistence while remaining attached to a testable event.

## Literary questions versus factual claims

“Does the colour feel equally delicate on both?”, “Which part of the image can you still call yours?”, and “how you learn to trust a floor” are literary or critical invitations. They do not need a factual answer from the author. Their quality depends on whether the described encounter makes disagreement or surprise possible.

By contrast, the following are concrete claims a separate implementation or runtime review should verify. I have not verified them:

- The lamps remain aimed where released; their colour is assigned at startup; other illumination remains when they are turned away.
- Both display hands receive the signals described, with tracked-player hands explicitly contingent on connection.
- RE-DIVIDE preserves total arch width and opening geometry across the four choices; arch collision and step collision differ as stated.
- Pillar positions, displayed field, and labelled samples implement the same described coordinate rule.
- Grid changes target one stored instance, RULE reaches beyond the selectable area, and no history survives replacement or room reload.
- The wet canvas uses previous-frame image feedback, and frame rate affects fading over equal elapsed time. This is consequential enough to deserve runtime evidence, not merely inspection of a formula excerpt.
- The colour-space displays contain the stated sample counts and alter the black corner as described; the interpolator uses the stated hue path.
- Chamber uses the stored projectile colour independently of its changing glow, a 1.5-metre centre-distance test, unchanged collision bodies, and separate crate/floor reset behaviour.

Scientific assertions also need care: RGB and HSV are descriptions, equal coordinate distances need not be equal perceptual differences, and the stated renderers are not spectral simulations. None of the poetic questions should be “verified” as though it were a scientific proposition. Conversely, attractive wording should not shelter an incorrect account of what the controls do.

## Prioritized revision list

1. **Repair the colour-coordinate handoff.** Add the RGB range handhold in Nails and a brief HSV introduction in Rainbow; give Pillar one worked relation between a physical crossing and its formula. This addresses the largest obstacle to a beginner reading the code.
2. **Remove references to unseen revision history and absent features.** In particular, reconsider “former arrangement,” the bracelet sentence, and the unexplained Trace reference. Keep only the context that helps a first encounter.
3. **Reduce the opening’s inventory and Paint’s parameter density.** Preserve scale relative to reach, repeated arrays, shared drawing destinations, and changing memory. Cut or relocate exact identifiers and measurements that do not support a prediction or comparison.
4. **Keep specific model limits; trim the repeated announcement that choices were authored.** Protect the critical questions tied to actual permissions, overwrites, entrances, and resets. Trust those experiments to carry more of the argument.
5. **End with a small transfer action.** Let the reader use the acquired distinction between value, receiver, and condition once, in their own words or prediction, before moving to the next hall.

The sequence already has a recognisable voice and a strong structure of encounters. The best revision would give the beginner a few more footholds while leaving the most vivid sentences room to work.
