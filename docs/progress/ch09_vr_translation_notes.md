# Chapter 9 (Genetic Algorithms) VR Translation Notes

## Example: 9_1_ga_shakespeare
- **2D focus**: Text-based GA evolving strings toward a Shakespeare quote.
- **VR fish tank layout**: Float semi-transparent volumetric text at eye level inside the tank; each generation briefly renders as layered pink glyphs drifting upward.
- **Light pink palette**: Primary pink highlights target characters, while candidates use lighter shades to denote fitness.
- **Line-derived controller**: Wall-mounted slider controls mutation rate; tapping the handle triggers a new generation.
- **Testing notes**: Ensure GA loop runs efficiently in GDScript, verify text billboards update without dropping below 90 FPS.

## Example: 9_2_smart_rockets_basic
- **2D focus**: Rockets with DNA sequences steering toward a target without obstacles.
- **VR fish tank layout**: Launch pad at tank base, target orb at top center; rockets leave pink vapor trails constrained within the cube.
- **Light pink palette**: Use medium pink for active rockets, fading to white as they exhaust thrust.
- **Line-derived controller**: Slider adjusts lifespan length; dial toggles mutation rate.
- **Testing notes**: Validate DNA-to-force mapping and confirm boundary collisions respect the fish tank walls.

## Example: 9_3_smart_rockets
- **2D focus**: Adds obstacles and more complex DNA to smart rockets example.
- **VR fish tank layout**: Introduce translucent obstacle prisms suspended mid-tank; target shifts toward back wall for depth.
- **Light pink palette**: Obstacles tinted desaturated magenta; successful rockets flare brighter pink on goal contact.
- **Line-derived controller**: Adjustable obstacle height slider plus mutation knob derived from line primitive.
- **Testing notes**: Confirm rockets detect obstacle collisions and mutation parameters remain stable over generations.

## Example: 9_4_interactive_selection
- **2D focus**: User selects flower creatures to breed; GA drives shape and animation.
- **VR fish tank layout**: Arrange flower-like organisms on a pink-lit lattice floor; user points to select via existing controller ray.
- **Light pink palette**: Each phenotype glows with variant pinks indicating fitness; selection feedback pulses accent hue.
- **Line-derived controller**: Slider sets population size; secondary control resets generation.
- **Testing notes**: Verify selection inputs interface smoothly with GA reproduction in 3D space.

## Example: 9_5_evolving_bloops
- **2D focus**: Bloop creatures eat food and evolve sensory traits.
- **VR fish tank layout**: Populate tank with swimming bloops, food orbs drift in from tank walls.
- **Light pink palette**: Bloop bodies gradient from light to medium pink; sensory ranges visualized as transparent pink domes.
- **Line-derived controller**: Panel of sliders adjusts metabolism, food spawn, mutation rate.
- **Testing notes**: Ensure Perlin noise locomotion behaves in 3D and that resource consumption is performant.

## Example: exercise_9_6_annotated_ga_shakespeare
- **2D focus**: Extended GA text evolution with annotations.
- **VR fish tank layout**: Similar to 9_1 but with additional floating annotation panels orbiting the main text column.
- **Light pink palette**: Highlight annotations with brighter accent pink to distinguish from candidate populations.
- **Line-derived controller**: Slider toggles between annotation layers; knob adjusts batch size per generation.
- **Testing notes**: Confirm logging overlays sync with GA progress and remain readable in 3D.
