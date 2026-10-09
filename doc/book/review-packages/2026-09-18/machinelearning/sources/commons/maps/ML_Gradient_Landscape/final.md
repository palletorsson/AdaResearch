# Three meanings of error

Can the same observations lead a learner downhill in different directions?

<!-- @loss_function_comparator -->

Find the moving point on each of the three landscapes. Each landscape scores a straight-line fit to the same set of observations. Keep OUTLIERS low for a first comparison, then raise it and reset. Look for a difference between the responses rather than asking which point arrives first.

The two horizontal coordinates represent the line’s slope and intercept. Height represents the error assigned to that candidate line. Moving across the surface therefore changes the proposed model, while moving down means improving the score under that particular definition of error.

Choose one candidate slope and intercept in your imagination and compare what the three surfaces would say about that same candidate. The candidate line is unchanged; only the rule assigning its height differs. This makes a useful distinction between moving within one landscape and comparing landscapes. An apparent hill on one surface is not a physical obstacle in the observations. It is a way the chosen error calculation rates a set of model parameters.

The squared-error surface punishes a large residual much more heavily than a small one. Huber loss is quadratic near zero and becomes linear for sufficiently large residuals. An unusual observation can therefore pull the two fitted lines differently. The outlier control helps make that difference visible while the basic task remains the same.

The third surface has a deliberately wavy error rule: a sine term is added to a quadratic term. Its label uses the word “adversarial”, but this exhibit is not training a generative adversarial network. It offers a rougher landscape on which local downhill movement can encounter a different arrangement of rises and hollows.

At each step the points estimate a gradient from nearby samples of the surface and move against it. Their allowed slope and intercept are bounded. A final position can therefore reflect the starting point, the local terrain and the allowed region as well as the underlying observations.

Return to an outlying observation in your imagination. Is it a measurement mistake, a rare event or a person whose case the majority fit neglects? The loss function cannot answer that question. Reducing its influence may be sensible in one situation and erase important evidence in another.

<!-- @ -->

The classification room will exchange a fitted line for groups. The same question remains: which differences does the chosen measure treat as important?
