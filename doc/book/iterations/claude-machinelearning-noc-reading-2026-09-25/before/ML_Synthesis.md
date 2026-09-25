# The point outside the rule

When a point is flagged as unusual, what exactly has been discovered?

<!-- @anomaly_detection -->

Find one raised, enlarged point and compare its position with a nearby unflagged point. Read the active detection mode. Before interpreting the raised point as an error, ask which numerical comparison could have put it above the threshold.

In the default view, the exhibit measures displacement from the sample’s mean along each coordinate, scaled by the spread on that coordinate. It adds the two absolute standardised displacements and compares the result with a threshold. Points meeting the threshold are lifted and enlarged, making a numerical decision into a spatial distinction.

Compare a point displaced mainly along one coordinate with a point displaced along both. The default score adds coordinate contributions, so the shape of its decision boundary comes from that addition as well as from the sample’s spread. Do not rely only on the impression of being far from the centre. The exhibit gives you a chance to connect the position of a raised point with the particular arithmetic that made its distance count.

The score depends on the sample used to compute the mean and spread. Here the generated outer points are included in those statistics along with the central cloud. The population helping define normality therefore includes the very observations that may later be called abnormal.

This is a specific coordinate-based rule. It is not a complete judgement about an observation’s origin or importance. A point might be an error, a rare valid case, an emerging pattern or a case the representation describes poorly. The raised position tells you what the score did; it does not choose among those explanations.

The machine-learning sequence has repeatedly separated the operation from the interpretation: a cluster from a named class, an edge from an object, and a training curve from demonstrated generalisation. The same care applies here. A detector’s name cannot supply evidence that its flags are useful.

Choose one flagged point you would investigate rather than discard. State what additional observation would help you decide. For a future version, exposing the threshold and allowing the reference population to change would make the cost of a decision visible: which rare cases become ordinary, and which ordinary cases become suspect?

<!-- @ -->

Graph theory will give us another representation of relations. Instead of asking how far points lie from a centre, we will ask which points are connected and what those connections permit.
