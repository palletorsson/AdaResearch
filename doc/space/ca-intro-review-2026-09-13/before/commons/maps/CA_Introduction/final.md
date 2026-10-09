# What will the next row do?

<!-- @ca_rule_explorer -->

Can you predict a whole pattern from what happens to three neighbouring cells?

Begin with the rule explorer. Select Rule 90 and reset it. Follow the single starting cell into the rows that appear beneath it. Before each new row, choose one position and predict whether it will be occupied. Look only at the three positions immediately above it: left, centre and right. Then check your prediction against the new row.

Try Rule 30 with the same reset. The starting mark has barely changed; the expanding pattern has. Follow an edge, then examine the less easily predicted interior. Changing the speed gives you more time to look, but does not select a different rule.

Choose a position well inside the row, where its three inputs are easy to distinguish. Say the three states in order and keep their order when you compare another occurrence. Left-occupied and right-occupied are different neighbourhoods even if both contain one occupied cell. This stops counting from silently replacing the rule's actual question. Once you have checked a few positions, follow one diagonal boundary through several generations. Its regularity can make some predictions easy while nearby interior positions remain harder to anticipate from a quick glance.

Here a cell holds one of two states. Three neighbouring states make eight possible neighbourhoods. The selected rule supplies one answer for each neighbourhood. Every position reads the old row before the new row replaces it, so a newly written answer cannot influence its neighbour prematurely. The two ends of the row wrap together: the apparent edge of the display is not the end of the neighbourhood.

The field you met in the noise rooms assigned values to positions. This system adds a different relation: a position receives its next state from nearby states. A large arrangement becomes the accumulated consequence of small, repeated decisions.

The picture alone does not reveal every rule entry. Some neighbourhoods may never occur from this particular starting cell. A useful extension would let you supply a second seed and ask whether two rules that looked identical now separate. That is a test of what the first experiment left unexamined.

<!-- @ -->

Carry one distinction forward: the state of a cell, its neighbourhood and its update rule are separate choices. The next room changes the state space and the neighbourhood of that arrangement.
