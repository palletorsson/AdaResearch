"""halving_door_bench.py - the halving door's rule, benched before it is built (the pass, 2026-11-15).

The picture: a funnel D metres long with a door at D, qD, qqD ... from its tip. The walker is not made smaller;
the funnel is made larger about its tip by exactly the walker's steps. State: L (log of the scale) and X (the
walker's distance from the funnel's axis, as shown). One step (dl sideways, da toward the tip):
    L += da / D            X = (X + dl) * exp(da / D)
and the tip is shown D ahead of the walker, X to the side.

Read here:
  1. the floor under the feet does not slide (the shown place of the picture point under the walker stays put);
  2. a door is passed every D ln(1/q) metres, each as far as the last and as large when reached;
  3. the tip stays D ahead; on the picture the walker is D q^doors from it, never at it;
  4. walking straight beside the axis, the wall comes to the walker;
  5. out and back the same way, the funnel is where it was.
"""
import math

D = 6.0
HALF = 1.6


def step(L, X, dl, da):
    return L + da / D, (X + dl) * math.exp(da / D)


def shown(L, X, body, pic):
    """Where the picture point `pic` (sideways, metres from the tip) is shown, the walker standing at `body`."""
    s = math.exp(L)
    tip = (body[0] - X, body[1] + D)
    return (tip[0] + s * pic[0], tip[1] - s * pic[1])


def under(L, X):
    s = math.exp(L)
    return (X / s, D / s)


print('1. the floor under the feet')
L, X, body = 0.9, 0.7, (0.3, 5.0)
pic = under(L, X)
worst = 0.0
for dl, da in ((0.0, 0.01), (0.01, 0.0), (0.007, 0.007), (-0.01, -0.004)):
    L2, X2 = step(L, X, dl, da)
    b2 = (body[0] + dl, body[1] + da)
    a, b = shown(L, X, body, pic), shown(L2, X2, b2, pic)
    slide = math.hypot(b[0] - a[0], b[1] - a[1])
    worst = max(worst, slide / math.hypot(dl, da))
    print('   step (%+.3f, %+.3f): the ground slides %.6f m (%.2f %% of the step)' % (dl, da, slide, 100 * slide / math.hypot(dl, da)))
assert worst < 0.01

for name, q in (('half', 0.5), ('two_thirds', 2 / 3), ('three_quarters', 0.75)):
    a = D * math.log(1 / q)
    print('2. %s: a door every %.3f m; the next one stands %.2f m ahead at %.0f %% of its size when one is passed' % (name, a, D * (1 - q), 100 * q))
    back = D * (1 / q - 1) - a
    print('   the door behind, one door on: %.2f m further back than it was built, %.2f times the size (%.1f m high)' % (back, 1 / q, 2.6 / q))

print('3. the tip')
L = X = 0.0
walked = 0.0
for metres in (4.159, 41.59, 100.0, 1000.0):
    while walked < metres - 1e-9:
        L, X = step(L, X, 0.0, 0.01)
        walked += 0.01
    doors = L / math.log(2)
    print('   %7.2f m walked: %6.2f doors; the tip is shown %.2f m ahead; on the picture %.3g m from it, the walker %.3g m tall' % (walked, doors, D, D * math.exp(-L), 1.7 * math.exp(-L)))

print('4. straight on, half a metre beside the axis')
L, X, u = 0.0, 0.5, 0.0
while X < HALF - 0.3:
    L, X = step(L, X, 0.0, 0.01)
    u += 0.01
print('   the wall is at the shoulder after %.2f m (D ln(%.1f) = %.2f)' % (u, (HALF - 0.3) / 0.5, D * math.log((HALF - 0.3) / 0.5)))

print('5. out and back')
L, X = 0.0, 0.2
for i in range(2000): L, X = step(L, X, 0.0, 0.01)
for i in range(2000): L, X = step(L, X, 0.0, -0.01)
print('   20 m in, 20 m out: L = %.2e, X = %.6f (began 0.2)' % (L, X))
assert abs(L) < 1e-9 and abs(X - 0.2) < 1e-6
L, X = 0.0, 0.0
for i in range(1000): L, X = step(L, X, 0.0, 0.01)
for i in range(50): L, X = step(L, X, 0.01, 0.0)
for i in range(1000): L, X = step(L, X, 0.0, -0.01)
print('   10 m in, half a metre to the side, 10 m out: the funnel\'s mouth is shown %.3f m from where the walker stands; the walker is 0.5 m from the plank\'s middle' % X)
print('   so on the way out the body is set sideways by %.3f m, with all it can see, before the paper' % (0.5 - X))
