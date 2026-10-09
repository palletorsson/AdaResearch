# CA Agents Circuits — Summary

CA_AgentsCircuits is the twelfth and final map in the Cellular Automata sequence. It stages Wireworld — a four-state cellular automaton designed to simulate digital logic — and hands the learner an open editor for defining their own rules.

A Wireworld circuit takes up the main floor. Cells can be empty, conductor, electron head, or electron tail. Electrons travel along conductor paths according to a short rule: a head becomes a tail, a tail becomes a conductor, and a conductor becomes a head when exactly one or two of its neighbours are heads. That short rule supports logic gates, delay lines, and clocks; a small demonstration builds an AND, an OR, and a clocked ring, and wires them into a visible binary counter.

Along one wall, a Wolfram CA explorer lets the learner define any rule over any neighbourhood. Sliders set the state count, the neighbourhood size, and the individual rule entries. Running the rule on a small canvas shows its behaviour in real time, and the learner can save configurations to a small gallery.

Within the sequence, this map is the synthesis and the sandbox. The sequence has argued that simple local rules can compute anything; Wireworld makes that argument concrete, and the explorer invites the learner to find the next example.
