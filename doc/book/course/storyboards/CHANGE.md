# Change: measure, accumulate, follow

4 October 2026. Two revised summary proposals. Preserve the existing halls, their full written tracks and code. The first hall supports two successive short lessons; the second supports one update rule. These plans select what a future tutorial teaches. They do not claim that a reduced learner editor or new experiment has been implemented.

## Entry and exit

Bring functions, position differences, loops and retained traces. Tiling has made the distinction between an input address and its sampled result useful. Change supplies a new smooth curve: the nearest-sampled repeating texture is not the curve being differentiated.

Carry finite rate and sum functions into later work, and a follower that repeatedly samples its own updated address. Forces then makes another change: velocity becomes retained state, changed by acceleration. Do not require an analytic calculus course before that distinction can be understood.

## Change_Intro

**First lesson: measure across an interval.** The student owns the finite-rate calculation. Supply the curve and the plot, so the task concerns two values and their separation. Name the inputs: callable function, starting position and nonzero signed interval. Both samples must be inside the stated domain. Compare smaller intervals at a fixed starting position before choosing another position and predicting the sign. The result describes height change per horizontal model unit; it is not the plotted line’s visual angle or the speed of moving a slider.

**Second lesson: accumulate contributions.** Reuse that callable curve. The student owns a loop that samples once in each interval and adds height times width. Name bounds, positive interval count and sample fraction. Keep count fixed while changing left/mid/right sampling; keep the rule fixed while changing count. Predict one contribution before reading the total. Carry two small functions, not the entire plotting machinery.

The workbenches use the same expression, `0.5 + 0.4*sin(2*x) + 0.15*cos(5*x)`, on `[0,5]`. Supply the expression; its trigonometric construction need not become a new lesson here. The slope workbench supplies its analytic derivative. STEP chooses finite intervals and samples backwards near the right boundary, displaying negative h. The accumulation reference is **4096 midpoint samples**, despite the source name `_true_integral`. More samples need not produce monotonically smaller error. HOLD keeps comparison geometry and its settings, not a saved callable function.

**Bridge return: what did the sum retain?** This is a different arch. Its installed rate is a small finite-difference estimate; the reported total uses 512 trapezoid intervals. The visible 40 strips are scaled for display and are not the reported calculation. Supply these calculations for the comparison. Summing heights estimates area; summing signed rates estimates net height change. A rise and fall can cancel in the latter. Recovering absolute height also needs its starting value. No third compulsory construction or proof is proposed.

## Flow_Field

Begin with FIELD HELD. The field clock stops while particles continue. Leave SCALE and SEED fixed too; holding the clock does not disable these controls. The learner owns one repeated update: sample a unit direction, multiply by speed and elapsed seconds, update the position, then sample there next time. Predict two updates from a different starting address before adding other concerns.

The existing `field_direction(point: Vector2)` accepts local canvas coordinates. The drawing maps canvas `(x,y)` to local 3D `(x, fixed elevation, y)`; canvas y is not the museum’s up axis. State local canvas distance units and seconds before applying the artifact’s display transform. The sampler, arrows, particle rendering and boundary policy are supplied. The returned direction comes from a noise value mapped to an angle, not from the gradient of that noise. Noise and angle construction belong to later studies.

The current record keeps a limited number of position samples, not a fixed duration or the complete path. Reuse Trace’s list-and-neighbour idea, without implying an earlier learner record was imported. The current renderer joins neighbouring entries even across a boundary wrap, producing a line through space the particle did not traverse. Inspect that consequence. A discontinuity marker and separate trail segments remain an optional future extension.

**Optional numerical return:** one step of dt versus two steps of dt/2, with identical start, field state, speed and total duration. Use a starting region away from a wrap and hold SCALE, SEED and field time constant. This is a proposed controlled calculation using the sampler. SPEED changes prescribed velocity; RESET chooses fresh starts. Neither is an existing time-step experiment. The full lesson must name where this calculation runs before claiming the comparison is available.

## Before expansion

Choose the exact learner script/edit location and the connection to the existing plot or particle display. The named source functions establish what the host can supply, but do not by themselves create that authoring connection. Do not rebuild the museum to avoid declaring it. Preserve the bridge as a comparison and keep Flow’s first task small.

The accompanying review has one before/after/why card and an earlier museum image per map. These are two separate proposals for acceptance. The previously accepted Shaders, Arrays, Colour and Tiling plans stay accepted.

**Compact AI brief:** Existing museum; summaries only. Change_Intro: finite rate, then finite sum; shared supplied smooth curve, explicit intervals/units, independent prediction. Tangent analytic; reference finite. Bridge different arch, finite slope/trapezoid sum; reflective return. Flow: supplied Vector2 canvas sampler → direction*speed*delta → new address. Distinguish canvas y from world up. Reuse Trace structure, no imported record claim. Held clock ≠ immutable field. Current wrap lines remain; optional repair only. dt comparison later under controlled identical conditions; SPEED/RESET do not provide it. Name learner edit host before expansion. Carry prescribed versus retained velocity into Forces.
