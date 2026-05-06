A narrow entry opens into a branching space. The first steps are shared — everyone walks the same corridor. Then the path forks, and forks again, and the room widens into a canopy of alcoves.

A trie stores strings by their shared prefixes. The root is the empty string. Each edge is a character. "cat" and "car" share a path for two edges before diverging at the third. Lookup is proportional only to the query's length. The shared prefix is not wasted space — it is the structure's compression.

The narrow entry is the shared prefix. The wide exploration space is the suffix explosion. Words that begin the same way share the same descent. The trie does not sort — it descends, character by character, into increasing specificity. Identity in a trie is not a node. It is a path.
