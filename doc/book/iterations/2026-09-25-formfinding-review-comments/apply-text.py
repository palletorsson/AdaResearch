from pathlib import Path
r=Path.cwd()
def edit(m,changes,title=None):
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8-sig')
 for a,b in changes:
  assert s.count(a)==1,(m,a,s.count(a));s=s.replace(a,b)
 if title:s='# '+title+'\n\n'+s
 p.write_text(s,encoding='utf-8')
edit('FormFinding_Descent',[
 ("one quarter of x squared plus z squared", "a quarter of the sum of x squared and z squared"),
 ("In the recorded desktop comparison", "In a recorded comparison with these settings"),
 (" Behind this experiment, the retained marble toy carries velocity and receives periodic programmed kicks. Its motion may resemble searching, but it uses another update. The resemblance gives us a comparison to investigate.", ""),
 ("There is room for a different body in these small changes.", """## Comparisons

<!-- @descent_marble_toy -->

In the small swaying bowl, the marble carries motion from one moment into the next. Damping reduces it; a programmed kick every five seconds starts a new disturbance. Watch it pass a place the gold point would approach in shrinking steps. Looking downhill has not given these two bodies the same way to move.

<!-- @gradient_descent -->

The terrain station takes the local comparison onto seeded Perlin ground. Here too, samples to either side give a direction, and a threshold or a budget of 160 steps ends the search. The surface has become less orderly; the rule still knows only its neighbourhood.

<!-- @gradient_descent_well -->

At the glowing well, marbles descend, settle, pulse and begin again. Its title says that falling is how it learns. The marbles combine the local slope with retained motion; the LOSS readout follows the first marble on this authored landscape. A return to the top gives it another beginning, not a memory of the previous lesson. What does the falling let us understand about learning, and what does that resemblance leave out?

<!-- @settling_tremble -->

The small inset holds an amber curve beside blue points, then magnifies their differences eight times. Nothing trembles. These are fixed, seeded offsets from a sampled catenary, as its plaque says, rather than the residue of a solver. Magnification makes a small disagreement hard to overlook. Whether it matters is still a question for whoever accepts the result.

<!-- @science_screen -->

The nearby screen is another receiver: being visible in the room does not, by itself, make any of these histories a measurement it can read.

<!-- @ -->

There is room for a different body in these small changes.""")])
edit('FormFinding_Catenary',[(" It is a further encounter to build, not a movement to imagine that you have already seen.","")], 'Drawn, evaluated, settled')
edit('FormFinding_Relaxation',[
 ("Switch WIND off to compare the corrections under gravity alone. Try one pass, then four.", "Switch WIND off to compare the corrections under gravity alone. The bench begins at four passes. Press PASSES through eight and twelve until the readout says nudged: one pass. The next press returns to worked: four passes."),
 ("In a matched desktop calculation after 420 total undriven steps—sixty preliminary steps and 360 more—one pass leaves a mean absolute error of about 1.409% and a worst spring error of 34.276%. Four passes reduce both, to about 0.359% and 8.936%.", "With WIND off, compare the readings as the step count reaches 420—about six seconds after each restart, which already includes sixty preliminary steps. At one pass, the mean absolute error is about 1.4% and the worst spring error about 34%. At four passes, they fall to about 0.36% and 8.9%."),
 ("The glass does not contain you: it has no collider, so your body can walk through its wall.", "The glass lets you see an inside that its closed collision surface keeps your moving body outside. Transparency offers a view, not an entrance. The falling has finished; the boundary it left can still meet you."),
 ("the amphora is what those choose.","the amphora is what those choices left.")], 'What a budget leaves')
edit('FormFinding_Equilibrium',[
 ("this is frozen sculpture, and the room's own older notes claiming it turns on a breath are describing something else.", "this is frozen sculpture."),
 ("Gaudí's hanging models offered another way to approach this problem:", "The hanging models we met at the laundry lines offered another way to approach this problem:"),
 ("Those encounters are still to be built.", "None of those experiments stands in this room.")], 'Where forces cancel')
edit('FormFinding_Annealing',[], 'Willing to get worse')
edit('FormFinding_Forge',[
 ("<!-- @gradient_descent_optimizer -->", """<!-- @self_shaping_forge -->

The small glass forge gathers a cloud into something with a head, a torso and two limbs. One hundred and eighty points drift into place while a bar rises and the display announces MAX Q. Stay through another cycle. The body loosens, then returns. What makes its arrival convincing?

The destination was written before the journey began. The points move toward an arrangement chosen by the maker; the bar and percentage follow a clock, reaching their maximum about every eight seconds. They do not measure how well the parts have learned to hold one another. Here, becoming a body means approaching one particular picture of a body.

The gathering can still be beautiful. Its beauty need not settle the question on the banner: has the matter found a shape, or have we recognised the shape it was sent toward? Carry that distinction to the moving point nearby.

<!-- @gradient_descent_optimizer -->"""),
 ("The next sequence begins with oscillation.", """Look back through the forms we have met. A cable followed the hand that drew it. A formula supplied a curve; repeated corrections left a vessel. The mobile's balance was calculated before it appeared. A search was allowed to get worse, while the forge already knew which body it would become. Similar-looking arrivals can conceal very different freedoms. The low stack you made can stand among them even when the display refuses to recognise it.

The next sequence begins with oscillation.""")])
print('Revised six canonical chapters')
