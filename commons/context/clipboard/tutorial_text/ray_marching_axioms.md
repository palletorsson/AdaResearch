**Ray Marching**
Signed Distance Fields, Iterative Rendering

**Ray marching renders implicit surfaces by stepping along rays.**

**Unlike ray tracing (intersect geometry), ray marching uses distance fields.**

**SDF (Signed Distance Function):** distance to nearest surface (negative inside).

---

## Algorithm

**Steps:**
1. Cast ray from camera
2. Sample SDF at current position
3. Step forward by distance (safe - won