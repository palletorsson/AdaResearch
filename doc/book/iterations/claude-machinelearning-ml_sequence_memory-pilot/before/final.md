# What should survive the next input?

How can a learner use the past without keeping every past event equally active?

<!-- @lstms_vr -->

Walk around the gate diagram and trace the route from incoming information towards the cell-state stream and the outgoing path. Choose one gate and predict what withholding information there would change. Keep that prediction separate from the movement of the decorative particles.

The diagram distinguishes three kinds of decision: what previous state to retain, what new material to admit and what part of the current state to expose as output. These are useful distinctions even when the same stream appears continuous from a distance. A memory has to preserve something while permitting something else to change.

Trace the cell-state route separately from the output route. Imagine retaining a detail for later without displaying it now; then imagine producing an immediate response without keeping every detail of the current input. These are different jobs. The spatial separation helps you ask which job a gate is meant to regulate. It also prevents the stream’s continuity from becoming a vague claim that all information simply passes unchanged from the beginning to the end.

In a working long short-term memory network, learned gates scale numerical contributions to the cell state and output. A gate can take an intermediate value; it is not necessarily a literal door that is either fully open or fully shut. Repeated updates let earlier information influence later predictions through an evolving internal state.

The present arrangement is a spatial diagram of that arrangement. Its particles follow an animation, and it does not yet carry an input sequence through a computed recurrent memory. The gate bodies therefore support tracing the proposed relationships, but their appearance cannot demonstrate that a particular earlier input has been remembered or forgotten.

Take the sentence “the key beside the cabinets is missing”. Which earlier distinction matters when choosing “is” rather than “are”? This thought experiment asks memory to retain the relevant subject across intervening words. It does not imply that a gate comes with an explicit grammatical label or that every trained network solves the problem reliably.

The next useful addition would make an input sequence and cell-state values visible, then compare two sequences differing at one earlier step. That would turn your prediction about a gate into an observable test.

<!-- @ -->

Generative learning next changes the task again: a model produces candidates, while another source of feedback judges them.
