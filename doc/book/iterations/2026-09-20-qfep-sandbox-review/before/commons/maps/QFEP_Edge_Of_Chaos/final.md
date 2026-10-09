# A pattern and the way we drive it

Which changes belong to the model, and which belong to the way its calculation is run?

<!-- @edge_of_chaos_unlocked -->

Keep SIM SPEED steady and move LAMBDA slowly. Give the image time to respond before choosing another value. Use RESTART to repeat the same start, or NEW SEED to choose another. Describe what persists, spreads or disappears before giving the whole picture a name.

The display updates two concentrations on a grid. Local reaction terms change their amounts, while diffusion exchanges concentration with neighbouring cells. The resulting image comes from repeated local updates rather than from replaying a finished picture.

Choose a visible feature small enough to follow, such as the boundary between two coloured regions. Compare its persistence through several updates with the overall impression of activity across the field. A rapidly changing picture can contain local features that last, while a nearly uniform picture can still undergo numerical updates. Describing both scales gives you a better observation than declaring the whole image ordered or chaotic from one glance at its most conspicuous movement.

LAMBDA follows one authored route through several reaction-diffusion parameters. It changes feed, removal and diffusion coefficients together. If the picture changes, the comparison establishes a response to that combined adjustment; it does not isolate the effect of one chemical parameter or discover a universal balance point.

Initial conditions matter too. NEW SEED changes the starting concentrations while leaving the chosen parameter setting available for comparison. RESTART returns that numbered seed to its beginning. A pattern that survives one start may not appear in the same way from another. Keep a record in words: what feature are you comparing, and over how much observed time?

There are two images in front of you. They begin with the same concentrations and reach the same model time, but the right-hand calculation takes twice as many smaller steps. Follow the boundary you chose in both. Does it still turn in the same place? Press HOLD / RUN when there is something you want to look at for longer.

DT .3 / .15 starts the comparison again with a different step size. The smaller number gives the calculation more occasions to respond along the way. SIM SPEED instead changes how quickly the model clock advances while you stand here. Those are different ways of changing time. Making the picture run faster does not make its calculation more precise.

The small difference reading compares the two B concentration fields cell by cell. A low value means these calculations are close in that particular respect. It does not tell you whether the pattern is alive, beautiful or worth keeping. Look back at your boundary. Does the number register what you were watching?

The earlier calculation could produce a pattern largely through overshooting and clipping its values. That was still something code had made. It answered a different question from the one the display claimed to ask. Repairing the calculation gives us another way to investigate the image; it does not make the image explain itself.

The hall’s recommended middle was an architectural choice. Here a measured transition would require a stable numerical experiment and a defined observable, such as persistence or spatial correlation, examined across controlled settings. An evocative label cannot perform that work.

Repeat the comparison at another LAMBDA setting, or from another seed. Agreement across smaller steps gives us a reason to trust a feature more. Disagreement gives us somewhere to look. The question remains open long enough to become an experiment.


The sandbox extends the question of control across several objects. First we must establish which objects actually receive each change.
