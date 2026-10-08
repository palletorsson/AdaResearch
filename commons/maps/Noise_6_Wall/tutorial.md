# Noise 6 Wall — hold, accumulate, dress

**Learning elements — proposed focus**

_The labels below set the revision focus; the existing lesson still needs alignment._

- Layered fields
- Colour composition
- Appearance and support

1. Enter through either side door. Look along the floor towards the other opening and notice the cloud finish on the room's sphere.
2. Turn to the panel on the inner wall and press FREEZE. Compare the current moment before and after the press; it should hold without jumping to time zero.
3. Press DRESS while staying inside the room. Compare greyscale cloud accumulation with the full pink material. Check the same doorway and floor; the controls change material parameters, not collision.
4. At the panel, compare the fixed 1/2/4/6 windows. Press LAYERS to carry each cumulative bound into the enclosure. Keep BASIS and the moment fixed for this comparison.
5. Read the loop below. Each term folds noise through abs, adds a weighted magnitude, halves amplitude and doubles frequency. The sine/cosine offsets are held by the same local clock.

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

The first weight is .5 and the frequency is 1. The cumulative weights are .5, .75, .9375 and .984375. These are not predicted brightness values: each term has its own sampled magnitude, followed by gain and clipping.

6. Change BASIS separately. The control cycles the implementations Perlin → Value → Cellular → Simplex → Perlin. Return to Perlin at the held moment. There is no exposed seed control.
7. Restore the dress. The complete finish adds an independent four-term turbulence calculation, density, smoothstep, colour, corner/edge shading, roughness and lighting-normal variation. Reducing LAYERS does not disable that second calculation.
8. Follow a cloud towards a door or corner. Each quad restarts its UV chart; the sphere has another chart. A shared procedure does not guarantee continuity between those surfaces.
9. Watch the independent dark orb while the room is held. Resume with FREEZE again. The room continues from its held phase; the orb has been advancing throughout.

Both shaders expose the same cloud term bound and sum-only mode. The comparison patches always show the sum at gain 2, while DRESS selects what the enclosure and its sphere wear. The actual desktop pointer operates all four controls in the accepted rendered run. The current panel is at (6,4), facing into the room; earlier entrance photographs describe the previous placement. Human VR reach and comfort remain for the deferred headset session.

Next: Noise_Inside_Noise. Keep the distinction between changing the value returned at a coordinate and changing the coordinate at which the question is asked.
