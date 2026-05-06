extends Node

var text = '''[center][font_size=28][b]Markov Chains[/b][/font_size][/center]
[center][i]Probabilistic State Transitions, Memoryless Process[/i][/center]

**Markov chain: system transitions between states probabilistically.**

**Key property: Memoryless** - next state depends only on current state, not history.

[hr]

[b]Definition[/b]

**States:** S₁, S₂, S₃, ...
**Transition probabilities:** P(Sⱼ | Sᵢ) - probability of moving from state i to state j

[color=yellow][b]Example: Weather[/b][/color]
States: {Sunny, Rainy}
Transitions:
- P(Sunny | Sunny) = 0.8
- P(Rainy | Sunny) = 0.2
- P(Sunny | Rainy) = 0.4
- P(Rainy | Rainy) = 0.6

[color=yellow][b]Code:[/b][/color]
[code]
var states = ["Sunny", "Rainy"]
var transition_matrix = {
    "Sunny": {"Sunny": 0.8, "Rainy": 0.2},
    "Rainy": {"Sunny": 0.4, "Rainy": 0.6}
}

var current_state = "Sunny"

func next_state():
    var rand = randf()
    var cumulative = 0.0

    for next in transition_matrix[current_state]:
        cumulative += transition_matrix[current_state][next]
        if rand <= cumulative:
            current_state = next
            return

# Simulate
for i in range(100):
    print(current_state)
    next_state()
[/code]

**Stationary distribution:** Long-run probabilities of each state (if chain converges).

[hr]

[b]Applications[/b]

- **Text generation** (Markov text models - next word based on current word)
- **Music composition** (next note based on current chord)
- **Page rank** (Google's algorithm - random walk on web graph)
- **Game AI** (state-based behavior)

[hr]

[b]Queer Markov[/b]

**Markov chains are memoryless** - no history, only present determines future.

**This is queer anti-essentialism:**
- **No origin story needed** (past doesn't determine you)
- **Only current state matters** (who you are now, not who you were)
- **Probabilistic becoming** (not deterministic trajectory)

**But:** Real queer lives ARE historical. **We remember.** Markov erasure of history is violent.

**Tension:** Queer freedom from past vs queer need for archive/memory.

[hr]

[color=cyan][b]Summary:[/b][/color]
Markov chains: probabilistic state transitions. Memoryless (next depends only on current, not history). Transition matrix encodes probabilities. Applications: text generation, PageRank, music. Queer Markov: freedom from deterministic past, but also erasure of history/memory - tension between anti-essentialism and need for archive.

'''
