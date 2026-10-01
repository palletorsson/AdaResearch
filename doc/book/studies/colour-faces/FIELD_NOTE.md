# Field note: four walls between lime and its opposite

1 October 2026. Observer: Claude, the session that built this kit, working from the repository and from stills; a second session ran both commands again the same day and got the same numbers. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two walls look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Mixed in four spaces, which two walls between the same two
                 colours look most alike, and which of them reach a grey?
Baseline:        wall.gd of this kit: nine steps from BODY (#c6ff3d) to its
                 complement in RGB (#3900c2), mixed in RGB. Middle step #808080.
Intervention:    one field, space: rgb, hsv, linear, oklab. Nothing else changes.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     closest pair rgb and oklab; rgb and linear third of six.
                 Only RGB reaches grey for this pair. Details below.
Another cause:   the ruler; the pair; what "opposite" means; the renderer.
                 All four were tried.
Decision:        follow three times, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `wall.gd`, one wall alone in the sheet's studio, its nine steps 0.4 m wide and drawn 1.8 m high, the eye level and 4.4 m away, no shadow. The studio is the look without its filter: flat sky, white ambient light.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could see.** Stills of 960 by 720 pixels. The colour of a step is the mean of the still inside its face, shrunk to 0.7. Two walls are compared step against step: the mean distance in red, green and blue together, each of 255 ("RGB distance"), and the mean distance in OKLab times 100 ("OKLab distance").
- **What I could not see.** An eye. "Look alike" in this note is a distance between pixels, and one of the two rulers is the space the fourth wall was built in.

## The predictions, as the outline stated them

1. "RGB and linear-light RGB will look most alike: both pass through a grey middle, Klee's central grey, and differ only in where the grey falls. HSV swings round through the hues in between and never reaches grey."
2. "planted bug: hue lerped from 0.9 to 0.1 goes the long way round, through green, instead of across red: wrap the difference"

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

Observed. Nine steps in RGB: `c6ff3d b4df4e a3bf5e 919f6f 808080 6e6090 5c40a1 4b20b1 3900c2`. The middle has saturation 0.

### T1. The long way round (parent T0, status: consolidate)

**Intervention.** The pair changed to SKY (hue 0.919) and THIRD (hue 0.080), the hue lerped with `lerpf()`.
**Prediction.** The outline's second.
**Observed.** `ff2e93 e72cff 612aff 2878ff 26ffff 25ff75 5cff23 e6ff21 ff8b1f`. Seven of nine steps lie between yellow and violet; the middle is a cyan. Godot printed no error and no warning.
**Observed.** With the difference wrapped: `ff2e93 ff2c79 ff2a5e ff2842 ff2627 ff3f25 ff5823 ff7121 ff8b1f`. None lies between yellow and violet.
**Concluded.** The prediction held. The fault is silent, and the repair is the one the outline names.

### T2. The tie (parent T1, status: branch)

**Intervention.** The wrapped rule, back on the first pair.
**Prediction.** None. I expected the HSV wall to stay as it was.
**Observed.** Before the wrap the HSV middle was `1be1b8`, hue 0.466: the wall went by green and cyan. With the wrap it is `e11b44`, hue 0.966: the wall goes by yellow, red and magenta. The difference of the two hues read 0.500000044703484.
**Observed.** Between red and cyan the difference is exactly 0.5, the wrap does not fire, and the HSV middle is `80ff00`.
**Concluded.** Complements are half a turn apart and both ways round are equally long. For lime and its complement a rounding error in the eighth decimal decides, and it decides for red.
**Decision.** Follow. **Reason.** It contradicts what I expected and it changes which wall the sheet compares.

### T3. The sheet (parent T2, status: continue)

**Observed.** The kits' usual measure, the share of the still on which two stills differ, is 38.57% for every one of the six pairs: the seven inner steps. It cannot rank them.
**Observed.** RGB distance, then OKLab distance: rgb and oklab 36.1, 5.4; linear and oklab 37.0, 7.6; rgb and linear 45.2, 11.0; rgb and hsv 88.8, 13.8; hsv and linear 109.0, 17.3; hsv and oklab 116.8, 16.4.
**Observed.** Rendered middles: rgb `#777777`, saturation 0; hsv `#d8153c`, 0.902; linear `#8db38a`, 0.229; oklab `#61939f`, 0.388. The least saturated step of each wall: 0, 0.781, 0.199, 0.313.
**Concluded.** The first prediction is false in its first part: RGB and linear light are the third closest pair, and linear light does not pass through a grey between these two colours. Its last part held: HSV never comes near grey.

### T4. The ruler (parent T3, status: consolidate)

**Another cause.** The closest pair might be made by the ruler.
**Observed.** Both rulers name rgb and oklab as the closest and put rgb and linear third. They disagree lower down: by RGB distance hsv and oklab are the farthest, by OKLab distance hsv and linear.
**Observed.** The largest of a wall's eight gaps divided by the smallest: by RGB distance 1.00 for the RGB wall, 1.55 for HSV, 3.79 for linear, 2.06 for OKLab; by OKLab distance 2.13, 2.95, 3.64 and 1.00.
**Concluded.** The ranking of the first three pairs does not depend on which of these two rulers is used. Each ruler finds the wall built in its own space perfectly even, so "even" cannot be read off either of them.

### T5. The renderer (parent T3, status: consolidate)

**Another cause.** The light of the studio.
**Observed.** Each rendered middle is 13.0 to 15.4 from its painted colour. The same distances taken on the colours `mix()` returned, before any light: rgb and oklab 36.4, linear and oklab 37.1, rgb and linear 45.5.
**Concluded.** The studio darkens every step by about the same amount and does not change the order.

### T6. The pair (parent T3, status: branch)

**Another cause.** Lime and its complement may be a special pair.
**Intervention.** The same four spaces between red and cyan.
**Observed.** RGB and linear light both reach a grey, rendered `#777777` and `#b3b3b3`. OKLab's least saturated step has 0.098, HSV's 0.955. The closest pair is linear and oklab, 33.9 and 3.9; rgb and oklab 67.2 and 10.1; rgb and linear 73.9 and 11.4.
**Concluded.** For this pair the outline's sentence about the grey is true word for word, and its sentence about the closest pair is still false. Whether linear light reaches grey depends on the pair.
**Decision.** Follow. **Reason.** Two pairs, two answers about the grey: the description is missing something.

### T7. What "opposite" means (parent T6, status: consolidate)

**Intervention.** The complement of lime taken in linear light, `#b000fa`, in place of `inverted()`.
**Prediction.** The linear wall reaches grey and the RGB wall misses it.
**Observed.** Linear middle `bcbcbc`. RGB middle `bb809b`, saturation 0.319.
**Concluded.** A space reaches grey between two colours when they are opposite in that space. `inverted()` is RGB's opposite. Red and cyan are opposite in RGB and in linear light at once.
**Not done.** This was computed from `mix()`. The wall was not photographed.

### T8. The lamp and the ray (parent T0, status: consolidate)

**Observed.** The middle step of the RGB wall, painted `808080`, in the studio with `faces.gd` and its lamp: lamp off `#767676`, white `#bcbcbc`, lime `#a4bc7b`, violet `#7b76a3`. Lime against violet: 90.7 in RGB distance, 23.6 in OKLab distance.
**Observed.** The lime step at the wall's left end: `#bdf734` with the lamp off, `#ffff5a` under the white lamp.
**Concluded.** One paint is rendered as two colours under two lights. Under the white lamp the lime step turns yellow because its green channel is at 255 and cannot rise.
**Observed.** The ray: `e11b44` became `d38d40`, then `cdc63f`. The other 35 steps kept their colour. The walker was stopped 0.3 m from the wall's face; a marble came to rest on the top wall at 1.90 m.

### T9. How two lights add (parent T8, status: branch)

**Prediction.** Mine, before the run: the renderer adds the sun and the lamp as amounts of light and turns the sum back for the screen. The outline calls sRGB against linear "the engine's hidden correction".
**Intervention.** A wall painted `808080` all over; four stills: the ambient light alone, with the sun, with the lamp, with both.
**Observed.** With the lamp at energy 3: 66.0 of 255, 119.0, 191.3 and 244.8. The sun and the lamp added as numbers, the ambient light taken off once: 244.3. Added as light: 211.2. With the lamp at energy 1: 179.8 with both, 179.4 as numbers, 157.6 as light.
**Concluded.** The prediction was false. In the Compatibility renderer of Godot 4.6 a second light is added on the numbers the screen gets, not as light.
**Guessed.** That each light is drawn in a pass of its own onto a picture that is already in screen numbers. I did not read the renderer.

## What was observed, what was concluded, what is guessed

- **Observed.** The colours of every step, painted and rendered. The distances between the walls by two rulers. The hue difference 0.500000044703484. What the lamp did to four middle steps. What Godot printed, and that it printed nothing for the long way round.
- **Concluded.** RGB and OKLab are the closest pair between lime and its complement, linear and OKLab between red and cyan; RGB and linear light are third both times. A space reaches grey when the pair is opposite in that space. For exact complements HSV has two ways round, and here arithmetic picked one.
- **Guessed.** That a person would rank the walls as the rulers do. That the lime-lit and the violet-lit grey would be called two colours by someone who did not know they are one paint. That the rounding error falls the same way on another machine; the arithmetic is IEEE and should, but only one machine ran it.

## Unresolved

- **No eye was asked.** Every "alike" above is pixels.
- **OKLab as a ruler.** It ranks the OKLab wall close to its neighbours and perfectly even. I have no third ruler that was not also one of the walls.
- **Nine steps.** With more steps the usual measure might stop tying; I did not try another count.
- **The leaked texture.** The windowed run ends with two lines, `ERROR: Texture with GL ID of … leaked 349524 bytes`, and exit code 0. They appeared when the look got its gradient sky. I did not find the texture.
- **The other half of T7.** A sheet of four walls between lime and its linear-light complement was not rendered. That is the difference the lesson offers the learner to follow.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | follow | the repair of one pair silently changed another |
| T3 | follow | the prediction failed, and one sheet from one ruler is one test |
| T4, T5 | settle | two rulers and the unlit colours give the same first three pairs |
| T6 | follow | a second pair gave a second answer about the grey |
| T7 | settle | one sentence now covers both pairs |
| T8 | leave open | whether one paint under two lamps reads as two colours needs an eye |
| T9 | leave open | the sum is measured; why the renderer sums that way is not |

**The decision of this note: follow three times, then settle.** I followed the ruler, the pair and the meaning of "opposite", because each could have explained the failed prediction away. None did. I settle on this: the middle between two colours is in the space they are mixed in, RGB and linear light are not the closest pair for either pair I tried, and a wall reaches grey only when its two ends are opposite in its own space.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

The first runs 63 checks, among them T0, T1, T2 and T7, and exits 0. The second needs a window: it photographs the walls, writes `sheet.json`, `sheet.png`, `lamp.png` and `process.png`, and prints every number of T3 to T6, T8 and T9.

## Evidence

- `sheet.json`: every pair of walls for both pairs of colours, each step painted and rendered, the lamp's four lights. `sheet.png`, `lamp.png`.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
