# Field note: four pairs on one floor

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which box is hard to find.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which of four pairs, a body's colour on the ground's colour,
                 is hardest to read when the still is turned to grey,
                 and what is left of it?
Baseline:        the_look.tscn dressed by look.gd: BODY c6ff3d on GROUND 32188a,
                 white ambient light of energy 0.25, a sun of energy 0.28
                 43 degrees up, with shadows.
Intervention:    two lines of the palette, const GROUND and const BODY:
                 lime on violet, hot pink on violet, red on green, grey on grey.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     red on green: all of the box is seen as rendered, 19.06% of it in grey.
                 Details below.
Another cause:   the light; the threshold of the measure; the one camera;
                 the arithmetic of the grey. One was tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `the_look.tscn`: a floor of 8 m by 5 m, a box of 0.6 m, a sphere of 0.6 m across, and the scene's own camera. `look.gd` dresses it.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels. For each pair: a still, a second still with the box in one flat colour, which says exactly which pixels are box, and a third with the box away. A box pixel is *seen* when it is more than 25 of 765 from the same pixel of the third still, the three channels added. *Apart* is the mean of that difference over the box.
- **The grey.** Each pixel becomes the grey that has its luminance: 0.2126 R + 0.7152 G + 0.0722 B of the linear values, written back as a screen value.
- **What I could not see.** An eye. "Hard to read" in this note is a count of pixels.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "red on green differs most in hue and least in grey, so it vibrates on screen and vanishes in grey; grey on grey is the lowest in both."
2. "the sun is added but the scene stays flat, because its rotation was left at zero and it shines along the floor."

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The finished look. `BODY` is rendered `#cbff39` on the face turned to the sun, `#bdf734` on the front and `#69891c` on the side in shade. `GROUND` is `#2d1388` in the sun and `#150547` in a shadow.

### T1. The sun that was not turned (parent T0, status: consolidate)

**Intervention.** A `DirectionalLight3D` added and left at rotation zero.
**Prediction.** The outline's second: the scene stays flat.
**Observed.** The front of the box went from `#474747` to `#a4a4a4`. Its top, its side and the floor stayed `#474747`. No shadow. Godot printed nothing.
**Concluded.** Half right. The light travels along (0, 0, −1), level: every face that looks up is untouched, and the faces turned to the camera are lit. The lesson is built on that.

### T2. The four pairs (parent T0, status: continue)

**Observed.** The box covers 6.33% of the still in all four.

| pair | hues apart | apart, as rendered | apart, made grey | seen as rendered | seen in grey |
|---|---|---|---|---|---|
| lime on violet | 176.1° | 428.1 | 490.2 | 100% | 100% |
| hot pink on violet | 77.3° | 212.8 | 222.8 | 100% | 100% |
| red on green | 120.0° | 362.6 | 41.4 | 100% | 19.06% |
| grey on grey | none | 121.0 | 121.0 | 81.18% | 81.18% |

**Observed.** In grey the red box's top is level 128, its front 123, the floor 125, its side in shade 65.
**Observed.** The grey box's side in shade is `#424242` on a floor of `#484848`: 18 of 765, under the threshold, in colour and in grey alike.
**Concluded.** The first prediction held in part. Red on green is the least in grey. It is not the most in hue: lime on violet is. Grey on grey is the lowest as rendered and the third of four in grey.

### T3. Without the sun (parent T2, status: consolidate)

**Another cause.** The 19.06% of the red box that survived the grey is the face the sun does not reach. The light may have given the pair a lightness difference that its two colours do not have.
**Intervention.** `sun.visible = false`, the hall's switch, on all four pairs. Nothing else changed.
**Prediction.** Red on green falls to nothing in grey. The other three stay.
**Observed.** Red on green: 214.0 apart as rendered, 0.0 in grey; 0.00% of the box seen. Every face of the box is level 65 and so is the floor. Lime on violet: 318.0 in grey. Hot pink on violet: 153.0. Grey on grey: 87.0, and now 100% of the box is seen, flat `#424242` on `#252525`.
**Concluded.** The prediction held. The two colours of the pair have luminance 0.2126 and 0.2118, and with light that has no direction nothing else separates them. In the look, the sun did.

### T4. The filter (parent T0, status: unresolved)

While this kit was being built the supplied look gained a filter for scenes that run: a gradient sky, a tinted ambient light, a weak second light, a softer shadow.
**Observed.** With it, on the course's pair: the still differs from the plain one on 91.68% of the picture; `BODY` is `#c8ff46` on top, 9.6 from its palette value, and `#628222` on the side in shade, 162.2 away. With the sun switched off under the filter the three faces of the box are `#61802b`, `#617b1d` and `#628222`.
**Not done.** The four pairs were not measured again under the filter.

### T5. A body (parent T0, status: consolidate)

**Observed.** The walker walked once round the two bodies ("arrived") and at the box ("blocked", its middle 0.30 m from the box's face). A marble dropped on the box rests at 0.70 m, with the sun shown or not. Where the box's shadow falls the walker stood at (0.15, 0, −0.66): a ray from its feet to the sun meets the box; a ray from 0.5 m up, and one from its eyes, do not. Through its eyes from behind the bodies, the box's two near walls are both `#69891c`.
**Observed.** A marble dropped exactly over the middle of the sphere stays on its top. Dropped 5 cm to the side it left the floor; after ten seconds it was 126 m below it.
**Guessed.** That a hand would never hit the exact middle. Not tested.

## What was observed, what was concluded, what is guessed

- **Observed.** Every colour quoted, read from stills. The share of the box's pixels that differ from the bare ground, in colour and in grey, with the sun and without. That a sun with shadows lit the floor `#c3c3c3` where the same sun without them lit it `#8c8c8c`.
- **Concluded.** A pair that differs only in hue is gone when the colour is taken away; what remained of it was made by the light. The course's pair is first in hue and first in lightness.
- **Guessed.** That a person would find the red box harder to see in the grey still than the pink one. That the grey still says anything about an eye that confuses red and green: it removes every hue, which no eye does. Neither was tested.

## Unresolved

- **No eye was asked.** Every "seen" above is pixels over a threshold.
- **The threshold decides the word "vanishes".** The red box's front is 2 grey levels from the floor and its top 3. A stricter measure would still call that a difference.
- **One camera.** The pairs were photographed from one standpoint. From behind the bodies every visible wall is in shade, and the red box would show more of itself in grey. Not rendered.
- **The stronger sun.** Why a sun that casts shadows lights more strongly in this renderer. The energy 0.28 exists because of it.
- **The filter.** T4.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the fault is real and silent; what it does is measured |
| T2 | follow | one fifth of the red box survived, and I could name a cause I had not ruled out |
| T3 | settle | the cause held: without the sun nothing of the box is left in grey |
| T4 | leave open | the filter arrived during the build; the plain look is what every sheet is measured in |

**The decision of this note: follow once, then settle.** I followed the light, because the one result that did not fit the outline's "vanishes" was made by it. With the sun off the red box is gone to the last pixel. I settle there: the kit claims that lightness is what survives the loss of colour, and shows that a light can lend a pair the lightness its palette lacks.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it photographs the nine states and the four pairs, with the sun and without, writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2 to T5. The second runs 56 checks, among them T1 and the walks and drops of T5, and exits 0.

## Evidence

- `sheet.json`: every colour, pair and share. `sheet.png`: the four pairs as rendered and made grey. `process.png`: the nine states.
- `verification.json`: the checks, with what each measured.
- `evidence/`: the room's trial of the guest, and the room with two roles changed, each run once in a copy of `my-room`.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
