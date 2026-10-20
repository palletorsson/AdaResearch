# Swarm Intelligence — Review of the revised edition

Ada Research · 11 October 2026 · Second review package

I've compared the new edition against the earlier Swarm material. The revision addresses several of my main criticisms without changing the seven-hall structure or the underlying programs. I think this is the right editorial direction.

The improvements concern how students enter each experiment, how the small reconstructions relate to the museum, and how much explanation the reflections carry.

## 1. What actually changed

| Revision                                                 | My assessment                                       |
| -------------------------------------------------------- | --------------------------------------------------- |
| Boids tutorial shortened from 1,699 to 1,173 prose words | Substantial improvement in focus                    |
| Boids reflection shortened from 1,083 to 716 words       | Reduces interpretive overload                       |
| Opening experiments clarified in all seven tutorials     | Stronger practical orientation                      |
| Hand-control instructions made more explicit             | Especially important in VR                          |
| Small studies distinguished from installed exhibits      | Resolves a significant earlier ambiguity            |
| Physarum and Flow Fields reflections revised             | Better connection between action and interpretation |
| Population Support accounting clarified                  | Prevents a conceptual misunderstanding              |
| Optional Particle Swarm investigation included           | Strengthens independent experimentation             |

All 22 printed GDScript blocks are preserved. This is primarily an editorial and instructional revision, not a redesign of the computational models.

## 2. The most important improvement is Boids

Previously, I considered Boids one of the strongest spatial encounters but also a chapter at risk of excessive explanation.

The revised text removes approximately 31% of the tutorial prose and 34% of the reflection while retaining the underlying experiment.

This matters because the Boids encounter is intrinsically rich. Students can already observe several kinds of relationships: separation, alignment, cohesion, neighbourhood membership and boundary wrapping.

The writing does not need to explain every possible interpretation immediately.

I would now regard Boids as a stronger model for editing other long chapters: preserve the experiment and its necessary technical distinctions, but reduce the amount of interpretation that precedes the student's observation.

## 3. The optional Particle Swarm investigation is particularly valuable

The new package includes Open Study — A Good Score, a Scattered Group.

The central question is whether weaker shared attraction in the RIDGE objective preserves a more dispersed population, and what happens to the population's scores.

It asks the student to compare runs at steps 0, 20 and 100, preserve the initial conditions, document the observations and consider a second seed.

Crucially, the assignment does not dictate what the outcome should be.

That is a meaningful improvement over an exercise that simply asks the learner to change a coefficient and confirm an expected result.

The proposed measure—largest pairwise distance—also makes the student confront the difference between a measurable definition of spread and more ambiguous ideas such as diversity or fairness.

This is exactly the kind of independent investigation I wanted to see at this stage of the curriculum.

The included earlier ghost-student investigation supplies evidence of feasibility, but it is not a new independent student evaluation of this edition.

## 4. Population Support now makes its central distinction clearer

The revision clarifies that omitted supply in the counterfactual accounting represents cumulative supplied history, not necessarily the number of currently living gold-ring agents.

That distinction matters.

A supplied individual may subsequently die, reproduce or interact. Removing its historical addition from an accounting equation is not equivalent to rerunning the ecosystem without that individual.

The tutorial's conceptual strength depends on preserving that difference.

It demonstrates that an alternative account of an observed system is not automatically a simulation of an alternative history.

I would retain this clarification.

## 5. What remains unresolved

The primary limitations are now less editorial and more empirical.

The archive reports:

# 265

Godot checks passed

# 70

Protected hashes preserved

# 144

Links and anchors checked

These are documented checks from the package, not tests I independently reran. The package explicitly reports no new physical headset test or independent learner session.

I would prioritize observing whether someone who did not develop the project can move successfully between an installed exhibit and its focused reconstruction, and then formulate a meaningful variation without relying on the supplied answer.

## 6. My revised judgment

The first edition already had a strong conceptual sequence:

Environmental trace → Supplied direction → Neighbour response → Internal state → Shared trail → Collective search → Population support.

The second edition improves the student's ability to follow this progression without being overwhelmed by the apparatus or the text.

It also introduces a more explicit distinction between a completed curriculum and an open research environment. The seven primary lessons establish mechanisms; the optional study asks the student to formulate and investigate a question whose outcome is not prescribed.

This is a good balance.

I would not recommend further substantial rewriting at present. Additional editorial changes risk producing diminishing returns before the material has been tested with learners.

My overall assessment has improved: Swarm now has strong conceptual continuity, explicit reconstruction instructions, carefully differentiated computational models, and a credible independent research exercise.

Its next major improvement should come from observing how people actually work with it, rather than another round of prose refinement.

And this raises a larger point about Ada Research: with each revised sequence, the production process is beginning to include not only algorithms, artistic encounters and reflective writing, but also systematic verification of what has been built. That growing capacity to inspect and revise a world at scale is itself an important part of the research methodology.