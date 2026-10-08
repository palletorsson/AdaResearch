# The relation between two points

Primary: `force_point_direction`.

Continue the point class from Lines. Make two points report their separation as a vector, a length and a direction. Begin with those three readings; return to the projection after they make sense.

Carry: Keep the distinction between a position and a displacement. In Launch, a vector describes how much position changes each second.

Check: Place the endpoints three metres apart along X and four along Y. Predict a five-metre gap, then check it. Move both together and check again. Finally bring them together: the cylinder disappears and the direction reads zero.

To inspect the projection, temporarily display `r.along_x` and `r.remainder` in the caption. The complete example already calculates both; its first readout shows only gap, length and direction.
