# Rotation Spectacle — exhibition gallery

A 37 by 55 museum hall with a continuous floor, one central boolean tunnel and six full-scale carousel cakes, arranged three on either side. No simulation declaration, basin, embedded GridSystem or crossing utilities.

The tunnel has fourteen three-metre segments. Its static angular rule is `i * 10` degrees, from zero to 130. Its hollow geometry is seated to allow passage at the museum floor.

The six cakes use the existing cake, ziggurat, column, spindle and flare profiles, with the original cake repeated as a reference. Their eight layer heights and angular speeds are identical: `0.5 * pow(1.2, i)` radians per second. The profile radii differ. Each gallery instance uses one live stack and collision matching its visible radii.

Book/primary order: `boolean_tunnel`, then `carousel_cake`. `final.md` introduces the tunnel's spatial repetition before comparing the stacks' motion and silhouettes. The following hall is Trans_Scale.
