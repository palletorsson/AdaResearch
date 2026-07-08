# Tutorial — Random_Entropy

## Claim
Entropy measures surprise, not mess. A shuffled deck and a sorted deck weigh the same; they differ in how many bits it takes to say which one you have.

## Idea
Shannon's move: don't ask what a message *means*, ask how *unexpected* it is. If every symbol is certain, entropy is zero — nothing to learn. If every symbol is equally likely, entropy is maximal — each one costs a full log2(N) bits to name. Everything in this room is a probability distribution wearing a body: the jar (order decaying toward uniform), the hardware (physical noise harvested as bits), the PRNG (a short seed pretending to be surprise).

## Code
```python
import math
def entropy(probs):
    return -sum(p * math.log2(p) for p in probs if p > 0)

entropy([1.0])                  # 0.0    - certainty, no surprise
entropy([0.5, 0.5])             # 1.0    - one fair coin, one bit
entropy([1/6.0] * 6)            # 2.585  - one fair die
entropy([0.9, 0.1])             # 0.469  - a loaded coin tells you less
```

## Try
1. Read the Shannon meter, then look at what it is measuring. Low number: could you have guessed the next state? High number: could you?
2. Watch the jar and the hardware decay. Nobody is stirring them. Ask what "work" would mean here — what it would cost to put the order back.
3. Stand between the true and pseudo generators. One is harvested, one is grown from a seed you could write on a fingernail. Can you tell them apart? Can the meter?
4. End at the dark sphere. It is the room's honest object: the thing about which the meter can only say "maximal — I know nothing."
