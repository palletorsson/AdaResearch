# A pattern and the way we drive it

Which changes belong to the model, and which belong to the way its calculation is run?

<!-- @edge_of_chaos_unlocked -->

Keep SIM SPEED steady and move LAMBDA slowly. Give the image time to respond before choosing another value. Use RESEED to compare a fresh start at the same setting. Describe what persists, spreads or disappears without relying on the regime name supplied by the display.

The display updates two concentrations on a grid. Local reaction terms change their amounts, while diffusion exchanges concentration with neighbouring cells. The resulting image comes from repeated local updates rather than from replaying a finished picture.

Choose a visible feature small enough to follow, such as the boundary between two coloured regions. Compare its persistence through several updates with the overall impression of activity across the field. A rapidly changing picture can contain local features that last, while a nearly uniform picture can still undergo numerical updates. Describing both scales gives you a better observation than declaring the whole image ordered or chaotic from one glance at its most conspicuous movement.

LAMBDA follows one authored route through several reaction-diffusion parameters. It changes feed, removal and diffusion coefficients together. If the picture changes, the comparison establishes a response to that combined adjustment; it does not isolate the effect of one chemical parameter or discover a universal balance point.

Initial conditions matter too. Reseeding changes the starting concentrations while leaving the chosen parameter setting available for comparison. A pattern that survives one start may not appear in the same way from another. Keep a record in words: what feature are you comparing, and over how much observed time?

The present numerical update has a further limitation: some settings can be dominated by the size of its computational step and by values reaching their allowed bounds. The picture therefore cannot currently certify physical chaos, criticality or a privileged region for life. This is a specific repair needed before stronger claims can be tested reliably.

The hall’s recommended middle was an architectural choice. Here a measured transition would require a stable numerical experiment and a defined observable, such as persistence or spatial correlation, examined across controlled settings. An evocative label cannot perform that work.

As the next development, compare the same starting field under a smaller, controlled timestep while keeping the physical duration comparable. Agreement would give more confidence that the visible difference belongs to the model.

<!-- @ -->

The sandbox extends the question of control across several objects. First we must establish which objects actually receive each change.
