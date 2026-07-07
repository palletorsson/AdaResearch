# They Were Never Two Things

Derivative and integral, rate and total — the Fundamental Theorem of Calculus says each undoes the other. Prove it with two loops.

```gdscript
func f(x: float) -> float:
    return 1.0 + 0.5 * sin(x)

# direction one: differentiate, then accumulate
func integral_of_derivative(a: float, b: float, n: int = 1000) -> float:
    var dx := (b - a) / n
    var total := 0.0
    for i in n:
        var x := a + (i + 0.5) * dx
        var fprime := (f(x + 0.001) - f(x - 0.001)) / 0.002
        total += fprime * dx
    return total    # ≈ f(b) − f(a)
```

Accumulate the rate and you recover the change in the original: the sum of all the little slopes is just where you ended minus where you began. Every intermediate value cancels — the telescoping at the heart of the theorem.

```gdscript
# direction two: accumulate, then differentiate
func F(x: float, n: int = 500) -> float:      # running area from 0 to x
    var dx := x / n
    var total := 0.0
    for i in n:
        total += f((i + 0.5) * dx) * dx
    return total

func derivative_of_integral(x: float) -> float:
    return (F(x + 0.001) - F(x - 0.001)) / 0.002    # ≈ f(x)
```

Differentiate the running total and the original curve comes back. Print `derivative_of_integral(x)` beside `f(x)` across the room's span: two columns of nearly identical numbers, disagreeing only in the far decimals where step size lives.

The bridge in this map renders both directions at once — walk one way and rates accumulate into totals, walk back and totals differentiate into rates.

Try: break it. Make `f` a step function (jump at x = 2). Direction one survives; direction two stutters at the jump — the theorem's fine print (continuity) located empirically, by a walker with a stick.
