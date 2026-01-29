[b]F: Free Energy — The Drive Toward Order[/b]

[i]Systems minimize surprise.[/i]

Free Energy is the prediction error — the gap between 
what you expected and what you got.

[b]The Drive:[/b]
Every adaptive system tries to minimize F.
Find the pattern. Reduce surprise. Predict better.
This is learning. This is homeostasis. This is survival.

[color=cyan][b]Code: Pattern Completion[/b][/color]
[code]
func minimize_free_energy(observation, prediction):
    error = observation - prediction
    
    # Two ways to reduce error:
    # 1. Update your model (perception)
    prediction = prediction + learning_rate * error
    
    # 2. Change the world (action)
    act_to_make_observation_match_prediction()
    
    return error  # This IS free energy
[/code]

[b]The Trap:[/b]
But pure F-minimization leads to the [color=red]dark room[/color].

If you minimize all surprise, you stop moving.
You stop learning. You crystallize. You die.

The dark room has zero surprise.
And zero life.

[b]QFEP adds λE(S) — the entropy drive — to escape this trap.[/b]
