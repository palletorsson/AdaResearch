# Random Definition — revision and editorial assessment

13 October 2026 · [Read the reflection](index.html) · [PDF](random-definition-illustrated.pdf) · [Paragraph tree and timeline](../../course/text-plans/Random_Definition/final.md)

## What changed

The reflection now begins with holding the ball and letting go. Two paragraphs allow a departure, a return and a possible change of the visitor's position before the colour bench enters. The writing does not prescribe enjoyment, surrender or discomfort. The installed sphere makes bounded excursions from a fixed centre; this is not an accumulating random walk.

The seed explanation remains exact. The seed supplies a starting state, and reproducing the picture also requires the same requests and assignments. “Nothing in a draw says that it is red” stays at the moment the discarded draw changes the picture.

RAND now enters through the need to make chance available for another calculation. The historical table, seeded calculation and museum's falling digits retain different ways of returning. The historical passage explains why the book existed, without claiming that repeating a sample guarantees its suitability or independence.

The imagined sleeve starts with pulling a square towards the wrist. Joined neighbours and bending are proposed additions. Their geometry, attachment and weight would require implementation: the current panel does not become cloth. The passage ends with a desire that replay alone cannot fulfil.

The next hall is Entropy. The 10 PRINT photograph is labelled as a later appendix: Definition → Entropy → Remove → 10 PRINT. The number-page photograph documents a place; the sphere pair documents two paused positions. Their captions no longer ask still images to prove temporal or bodily experience.

The canonical `final.md`, illustrated reading and PDF now contain the same reflective prose. The previous canonical final, review draft and plan are preserved in `before-ball-opening/`. This local revision is not an approved formula for every Ada chapter. `tutorial.md` retains its construction task and is unchanged by this pass.

## Provisional Ada score: 8/10

**Scope:** this reflection and its relation to the installed hall. **Confidence:** moderate. This is an editorial self-assessment after revision, not a student study, external review or judgement of the whole tutorial. The preceding estimate was 7/10; these scores are coarse judgements, not measured improvement.

| Dimension | Score | Evidence and limit |
| --- | ---: | --- |
| Subject and truth | 2/2 | Pseudorandom generation, assignment and bounded excursions are distinct. The history has a primary source; the sleeve is explicitly unbuilt. |
| Learning and agency | 1/2 | The reader can distinguish participation, replay and a change of rules, building on Cage and Colour. This reflection does not demonstrate that a student can explain or implement those distinctions; that requires the tutorial and a reading trial. |
| Situated encounter | 2/2 | Holding, release, an unchanged seed and a departing number change what can happen in the prose. The objects supply the argument. Headset experience remains untested. |
| Wider possibility | 2/2 | The historical labour of preparing chance leads back to retrieval; the sleeve asks for a different use of the same object. Both connections have consequences for this particular room. |
| Voice and desire | 1/2 | The appointment at the centre and the book's lost line give the objects memorable behaviour. The transition from the grid to RAND still becomes explanatory quickly. It needs a fresh reader's judgement before earning a stronger score. |

**Length:** 622 body words in 12 paragraphs, within the 450–700-word allowance. Title, footnote, captions, this assessment and the 10 PRINT appendix are separate. The paragraphs are not forced into equal lengths. No additional hall is indicated by this scope.

**Strongest improvement:** the opening gives participation time to become an experience, and the sleeve develops through a proposed physical action.

**Remaining weakness:** several changes of register occur in a short text. In particular, the RAND passage is clearer in purpose but still compressed in rhythm. Adding biography would not resolve that.

**Next reading question:** after “Perhaps you prefer it this way,” does the book feel like a place you want to follow the question, or an interruption? This is a question for the next reader, not an approval gate.

## Evidence and verification

- Sphere: `commons/artifacts/random_return/random_return.gd` chooses direction and distance, then uses an eased outward-and-return cycle; `ride_point.gd` and the recorded runtime probe cover carrying and release.
- Seed bench: `algorithms/randomness/seed_replay/seed_replay_demo.gd`; current map and museum plan start this instance at 4 × 4. Each cube receives three colour draws; discarding one changes their grouping.
- Number page: `algorithms/randomness/randomnumbergeneration/scripts/random_number_book_page_1995.gd`, `_on_cell_touched()` and `_cascade_step()`, preserve frozen cells while other values cascade. The script's filename does not date the historical book.
- History: [RAND's introduction and production account](https://www.rand.org/pubs/monograph_reports/MR1418.html), rechecked for this revision.
- Route: `commons/maps/sequences/randomness.json`, first four entries.
- Existing [runtime reports](checks.json) and [capture provenance](captures.json) are retained, not presented as fresh engine tests. No runtime code changed in this revision.
- Publication checks compare all 12 paragraphs across the canonical final, illustrated Markdown, HTML and extracted PDF, check the six image references, and check that the tutorial's SHA-256 has not changed. PDF pages receive visual inspection separately.
