# Collective Knowledge — Technical

Four reasoning agents run side-by-side, each with its own inference engine. A mediation station collects their outputs and computes a shared-commons report.

```gdscript
class_name ClassicalAgent extends Node

func reason(claim: String, kb: KnowledgeBase) -> String:
    # Classical two-valued logic, crashes on contradiction
    if has_contradiction(kb): return "INCONSISTENT"
    var value: bool = evaluate_classical(claim, kb)
    return "TRUE" if value else "FALSE"

class_name ParaconsistentAgent extends Node

func reason(claim: String, kb: KnowledgeBase) -> String:
    # Four-valued Belnap logic, tolerates contradiction
    var value: int = evaluate_paraconsistent(claim, kb)
    return ["NEITHER", "TRUE", "FALSE", "BOTH"][value]

class_name ProbabilisticAgent extends Node

func reason(claim: String, evidence: Array) -> String:
    var prior: float = 0.5
    var posterior: float = bayesian_update(prior, evidence)
    if posterior > 0.9: return "LIKELY_TRUE"
    elif posterior < 0.1: return "LIKELY_FALSE"
    else: return "UNCERTAIN"

class_name ConstraintAgent extends Node

func reason(claim: String, constraints: Array) -> String:
    var solution := constraint_solver(constraints)
    if solution == null: return "UNSATISFIABLE"
    return "CONSISTENT_WITH_SOLUTION"
```

## Mediation

The central mediator collects the agents' outputs and combines them without requiring consensus.

```gdscript
class_name Mediator extends Node

@export var agents: Array  # list of agent nodes

func query_all(claim: String) -> Dictionary:
    var responses: Dictionary = {}
    for agent in agents:
        responses[agent.name] = agent.reason(claim, shared_kb)
    return responses

func commons_support(claim: String) -> String:
    var responses := query_all(claim)
    var positive_count := 0
    var negative_count := 0
    for agent_name in responses:
        var r: String = responses[agent_name]
        if r in ["TRUE", "LIKELY_TRUE", "CONSISTENT_WITH_SOLUTION"]:
            positive_count += 1
        elif r in ["FALSE", "LIKELY_FALSE", "UNSATISFIABLE"]:
            negative_count += 1
    if positive_count > negative_count and positive_count > 0:
        return "COMMONS_SUPPORTS"
    elif negative_count > positive_count and negative_count > 0:
        return "COMMONS_REJECTS"
    else:
        return "COMMONS_DIVIDED"
```

## Agreement and Disagreement

The display shows per-claim agreement patterns. Some claims are unanimous; others split the agents. The splits are the interesting data — they identify where the different logics produce genuinely different answers.

```gdscript
func find_informative_claims(claim_set: Array) -> Array:
    var informative: Array = []
    for claim in claim_set:
        var responses := query_all(claim)
        var unique_values := {}
        for r in responses.values():
            unique_values[r] = true
        if unique_values.size() > 1:
            informative.append({"claim": claim, "responses": responses})
    return informative
```

## Coverage Measurement

A coverage panel tracks which claims each agent can settle and which the commons can settle. Claims unreachable by any single agent but reachable by the commons are highlighted as additive gains.

```gdscript
func compute_coverage(claim_set: Array) -> Dictionary:
    var coverage: Dictionary = {}
    for claim in claim_set:
        var settled_by: Array = []
        for agent in agents:
            if agent.reason(claim, shared_kb) not in ["UNKNOWN", "NEITHER", "UNCERTAIN"]:
                settled_by.append(agent.name)
        coverage[claim] = settled_by
    return coverage
```

## Complexity

Each agent's cost is specific to its inference method. Classical logic: O(|kb|) to check consistency, O(|claim|) to evaluate. Paraconsistent: same. Probabilistic: O(|evidence|) for Bayesian update. Constraint: depends on the solver, typically O(exp(variables)) worst case but practical instances run in milliseconds.

The mediator's cost is the sum of its agents' costs plus O(agents) for aggregation.

Within the sequence, Collective_Knowledge implements the commons-of-incomplete-systems argument. PostCrisis_Synthesis will next close the sequence with a handoff.

## Agent Communication

Agents in the commons do not communicate directly; the mediator is the only interface. Each agent receives the same query, runs its own inference, and returns a response. This keeps the agents' logics truly independent.

```gdscript
func mediator_broadcast(claim: String) -> Dictionary:
    var responses: Dictionary = {}
    for agent in agents:
        responses[agent.name] = agent.reason(claim, shared_kb)
    return responses
```

## Consensus Algorithms

If a commons does need to reach consensus — for downstream decision-making — a separate aggregation step can apply. Majority rule, weighted voting, and iterative deliberation are common options.

```gdscript
func weighted_majority(responses: Dictionary, weights: Dictionary) -> String:
    var vote_totals: Dictionary = {}
    for agent_name in responses:
        var weight: float = weights.get(agent_name, 1.0)
        var response: String = responses[agent_name]
        vote_totals[response] = vote_totals.get(response, 0.0) + weight
    var best: String = ""
    var best_total: float = -INF
    for response in vote_totals:
        if vote_totals[response] > best_total:
            best_total = vote_totals[response]
            best = response
    return best
```

## Disagreement as Signal

When agents disagree systematically on a class of claims, the disagreement pattern itself is informative. A claim that is TRUE under classical logic, UNCERTAIN under probability, and UNSATISFIABLE under constraints reveals something about the claim's structure that no single agent could have identified.
