A formula waits in the next room. After all those difficulties with certainty, it is almost a relief to see an equals sign.

Come closer. What would you need to know before you could trust it?

## A sentence with handles

<!-- @qfep_formula_3d -->

```
QFE = F − λE(S) + φΔE(S,t)
```

Three buttons beneath the formula let you light up a term. Begin with `F`. The small screen asks what is being predicted, and which discrepancies count. Press the next button: how much weight does variation receive? The third: for whom is change possible?

These are questions Ada brings to the mathematics we have walked through. The formula is the project's proposal for thinking with prediction, variation and change. The earlier rooms have not proved it. An equals sign can gather a desire before we know how to measure it.

Here `F` points toward a model's free-energy cost; `E(S)` names an entropy assigned to some specified states. To calculate either, we would have to say what the states are, how they are counted or assigned probabilities, and what the model expects. A population of cells, a walk through rooms and an argument between people do not arrive with a shared unit of freedom.

The last term, `ΔE(S,t)`, asks us to attend to a change in entropy over an interval. To call that a *rate*, we would also need the duration. Already the notation wants more than it says. A point needed an origin. This formula needs an account of its world.

<!-- @lambda_slider -->

Move λ along its rail. Its value changes on the screen and its term changes colour. The rail offers a reassuring green region. Look at the competing marks beside it: different schools propose different desirable settings. Even the control has an opinion.

<!-- @phi_slider -->

Move φ through zero. Purple gives way to a warmer colour; the particles around the handle change their behaviour. The display follows your hand. Your weight does not change. Nothing in this apparatus has measured the entropy of the room.

That small separation matters. We have built a vocabulary for a possible model, and dressed its values so that some attract us. A colour can make a proposition feel welcoming before its consequences have been tried.

Nor does the plus sign settle those consequences. If we were *minimising* this expression, a positive coefficient on increasing entropy would add to the cost. What welcomes change depends on the whole rule. Keep the handle, but keep the question with it.

## One number, another future

<!-- @bifurcation_diagram -->

Across the hall, another handle belongs to a diagram. It has its own parameter, `r`. Moving λ does not move it.

Set `r` near 3.2. Follow the yellow column: two heights. Move toward 3.5. Now four. Each new value is made from the last:

```gdscript
x = r * x * (1.0 - x)
``

The same instruction, again. Change the parameter and the repetition takes another form.

The coloured diagram spreads many such runs across the wall. The yellow column follows your chosen value, allowing the early steps to pass before showing a later sample. Turn back toward 2.9 and it gathers at one height. There is something restful about that return. A settled state can be shelter, a reliable signal, a place to stand.

Move farther through the branching. The thin order opens into a crowded region. Then, near 3.83, three heights appear again. Regularity returns where a story of ever-increasing disorder might have told you it was finished.[^1]

The sample is finite. Its counter reports a short repetition when it finds one; failing to find one does not prove chaos. You can see what this run has retained. You cannot see all its futures.

There is a precise mathematical surprise behind the branching: many maps in the same universality class share a scaling pattern in their period-doubling cascades.[^2] A resemblance can be much more than decoration. Still, this equation has not established the right amount of disorder for a life.

The quiet column and the crowded one offer different possibilities. Which would your body need to continue?

## Enter the description

<!-- @goedel_atrium -->

A doorway stands open into a smaller room. Walk through it. On the central plinth is a model of the room, including its plinth and another model.

Find the doorway you just used. It is there again, too small for you.

The construction repeats a room-making procedure at a tenth of the previous scale. Here it stops after two nested models. The source permits that stop; the image encourages your eye to carry on. We have met this bargain before, in recursion: the suggestion of more, paid for with a finite number of things.

A system can contain a description of itself. This atrium makes that relation approachable. Gödel's argument required something more specific: an effective arithmetic theory able to encode statements and proofs, together with the relevant consistency or soundness assumptions. A model on a plinth does not perform that proof.

But the difference in scale does something the sentence alone cannot. You can look into your description. You cannot enter it with this body.

## What returns with us

<!-- @russell_paradox_workbench -->

At the returning Russell workbench, try membership both ways again. The unrestricted definition of the set of all sets that do not contain themselves defeats either choice. Compare it with a definition that refers to itself without producing that contradiction. Looking back at oneself was never enough to explain the trouble.

<!-- @godel_statement_plaque -->

<!-- @russell_set_box -->

<!-- @escher_staircase -->

The plaque, the nested box and the staircase return as reminders. A sentence about proof, an impossible membership demand, a convincing view of steps: their likenesses invite us closer. Their differences keep the investigation open. No single dial measures these three difficulties.

<!-- @florensky_sphere -->

The sphere keeps both readings while its colours change. Recall the constructive bench in Brouwer's room, where another term waited for your choice. Those encounters ask different things of us: what can be built, what may be asserted, what can remain unresolved without licensing everything. Neither response fits neatly at one end of φ.

We have more ways to carry on than the rail has labels.

## A model that can be answered

There is a desire running through this museum: give the world another opening. Make a passage, another kind of body, a rule that does not already know what the body must become.

Yet someone has to live with the opening. A system can become easier for one inhabitant by shifting difficulty onto another. More variation is not automatically more freedom; compulsory change can also exhaust a life. Ada's question is becoming more demanding: whose possibilities does this arrangement sustain, and who can answer back when its terms fail them?[^3]

Leave the formula lit. We will meet it again in the laboratory, where particular implementations give its terms consequences. The seven rooms behind us have supplied ways to question that work. They have not excused it from being questioned.

An equals sign waits. So does the world it has not yet accounted for.

[^1]: The logistic-map examples are described in [Rutgers' nonlinear-dynamics teaching notes](https://www.physics.rutgers.edu/grad/509/Logistic%20map.html). This apparatus starts at `x = 0.5`, discards 512 steps and displays 128 further values at the selected parameter. Initial conditions and finite precision matter; the point cloud is a numerical encounter.

[^2]: Mitchell J. Feigenbaum, [“Quantitative Universality for a Class of Nonlinear Transformations”](https://doi.org/10.1007/BF01020332), 1978. The universality is conditional on a class of maps and their local properties; it is not a claim about every system that changes or oscillates.

[^3]: Ada's working argument in [“Entropic Morality”](../../../doc/research/qfep/entropic-morality.md) asks how a system preserves the capacity to respond, change and revise its terms. The formula here is a research proposal, not a deduction from Gödel's theorems.
