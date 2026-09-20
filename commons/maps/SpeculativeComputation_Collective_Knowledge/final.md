# More contributions than contributors

When many marks accumulate, what makes the result knowledge rather than a pile?

<!-- @peer_production_tool -->

Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. The form grows to a fixed capacity and starts again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

The source makes the operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the edit count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. A number labelled CONTRIBUTORS can therefore outgrow the twelve source positions. The code tells us what was counted more precisely than the label does.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Follow a facet and ask what you can still recover about its origin after it joins the whole. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

For a proposed extension, mark one contribution as disputed and keep its source visible. Let revision change an existing piece instead of always adding another. The comparison would show how maintaining knowledge differs from celebrating uninterrupted growth.

<!-- @ -->

The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.
