# Learning from an opponent’s response

What changes when a learner’s critic is also learning?

<!-- @generative_adversarial_networks_gans_vr -->

Move between the generator and discriminator regions and follow the indicated exchange. First identify where a candidate is supposed to originate. Then trace where a judgement would return. Before watching the scores, say which part would need to change if the critic became better at distinguishing generated examples.

The two roles depend on one another. A generator attempts to produce candidates that a discriminator will accept as resembling the reference data. The discriminator attempts to distinguish the sources of the examples it receives. Improving one role can change the problem faced by the other, so the learning environment is partly made by another learner.

Read the exchange once from the generator’s side and once from the discriminator’s side. The same candidate can be useful to one participant as an attempted success and to the other as a training example to distinguish. The two roles therefore do not share a single meaning of improvement. Keeping their questions separate will matter when the room gains actual examples: a number moving in a favourable direction for one role may signal a changing difficulty for the other.

That relationship differs from descending a fixed surface. In the loss-landscape room, the scoring rule stayed in place while a point moved. Here the intended training process changes the evaluator as well as the evaluated model. A low score needs interpretation in relation to both participants and the examples they have seen.

This room currently illustrates those roles through animated zones, particles and progress displays. Its displayed losses are prescribed curves over time; no generator and discriminator are actually trained by the exhibit. The motion can help you remember the proposed exchange, but it cannot provide evidence that the generated candidates have improved.

Use that boundary to specify the experiment the room still needs: show a changing candidate, the discriminator’s response and the reference example involved in an actual update. Repeating one convincing candidate would then become distinguishable from producing a varied set. A beautiful average or a falling score alone would not settle the difference.

Ask also what the reference set treats as recognisable. Producing more of what an evaluator already accepts can leave unusual forms outside its reward, even when those forms matter to someone encountering the result.

<!-- @ -->

The synthesis room looks directly at that outside: how does a model decide that an observation is an anomaly?
