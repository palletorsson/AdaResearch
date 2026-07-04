# gaze_ride — Hangar_Fractals

```
# Hangar_Fractals  -  28x40 cells, cube 1.0m, 27 bodies

SIZES (real footprint, biggest first):
  inverted_tree_cloud                      base 14.56m  h 14.16m  @( 9.0,10.0)
  station_wall                             base 12.00m  h  4.50m  @( 4.5,31.0)  [estimated]
  box_counting_dimension                   base 11.01m  h  6.03m  @(22.0,21.0)
  station_wall                             base  4.00m  h  4.00m  @( 4.0,20.0)  [estimated]
  example_8_3_recursion_circles_vr         base  4.00m  h  3.18m  @( 6.5,26.8)
  fibonacci_pagoda                         base  3.87m  h  9.43m  @( 8.5,26.8)
  recursive_table                          base  2.50m  h  2.00m  @(14.5,26.8)
  cube_staircase                           base  2.00m  h  2.00m  @( 4.5,26.8)  [estimated]
  recursive_boolean_cube                   base  1.66m  h  2.00m  @(10.5,26.8)
  recursive_chair                          base  1.50m  h  1.50m  @(12.5,26.8)
  mandelbrot_dive                          base  1.33m  h  0.21m  @( 3.5,21.4)
  fractal_recursion_2                      base  1.06m  h  1.06m  @( 3.5,32.6)
  station_panel                            base  1.00m  h  1.00m  @( 4.0,20.1)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @( 3.5,21.4)  [estimated]
  station_panel                            base  1.00m  h  1.00m  @( 3.5,26.1)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @( 4.5,26.8)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @( 6.5,26.8)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @( 8.5,26.8)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @(10.5,26.8)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @(12.5,26.8)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @(14.5,26.8)  [estimated]
  station_panel                            base  1.00m  h  1.00m  @( 4.5,31.1)  [estimated]
  station_micropod                         base  1.00m  h  1.00m  @( 3.5,32.6)  [estimated]
  station_plinth                           base  1.00m  h  1.00m  @( 6.0,32.4)  [estimated]
  cube_subdivision                         base  1.00m  h  1.00m  @( 6.0,32.4)
  station_plinth                           base  1.00m  h  1.00m  @(22.0,32.0)  [estimated]
  example_8_4_cantor_set_vr                base  0.80m  h  0.25m  @(22.0,26.0)

CLEARANCE  (gaps that should be >= 1.2m to walk between):
  [tight  ] station_panel              <-> station_plinth             gap +0.36m (centers 1.36m)
  [tight  ] station_panel              <-> mandelbrot_dive            gap +0.20m (centers 1.36m)
  [OVERLAP] station_plinth             <-> mandelbrot_dive            gap -1.17m (centers 0.00m)
  [OVERLAP] box_counting_dimension     <-> example_8_4_cantor_set_vr  gap -0.91m (centers 5.00m)
  [tight  ] station_panel              <-> station_plinth             gap +0.24m (centers 1.24m)
  [OVERLAP] station_panel              <-> cube_staircase             gap -0.26m (centers 1.24m)
  [tight  ] station_panel              <-> example_8_3_recursion_circles_vr gap +0.59m (centers 3.09m)
  [OVERLAP] station_plinth             <-> cube_staircase             gap -1.50m (centers 0.00m)
  [tight  ] station_plinth             <-> station_plinth             gap +1.00m (centers 2.00m)
  [OVERLAP] station_plinth             <-> example_8_3_recursion_circles_vr gap -0.50m (centers 2.00m)
  [tight  ] cube_staircase             <-> station_plinth             gap +0.50m (centers 2.00m)
  [OVERLAP] cube_staircase             <-> example_8_3_recursion_circles_vr gap -1.00m (centers 2.00m)
  [tight  ] cube_staircase             <-> fibonacci_pagoda           gap +1.06m (centers 4.00m)
  [OVERLAP] station_plinth             <-> example_8_3_recursion_circles_vr gap -2.50m (centers 0.00m)
  [tight  ] station_plinth             <-> station_plinth             gap +1.00m (centers 2.00m)
  [OVERLAP] station_plinth             <-> fibonacci_pagoda           gap -0.44m (centers 2.00m)
  [OVERLAP] example_8_3_recursion_circles_vr <-> station_plinth             gap -0.50m (centers 2.00m)
  [OVERLAP] example_8_3_recursion_circles_vr <-> fibonacci_pagoda           gap -1.94m (centers 2.00m)
  [tight  ] example_8_3_recursion_circles_vr <-> recursive_boolean_cube     gap +1.17m (centers 4.00m)
  [OVERLAP] station_plinth             <-> fibonacci_pagoda           gap -2.44m (centers 0.00m)
  [tight  ] station_plinth             <-> station_plinth             gap +1.00m (centers 2.00m)
  [tight  ] station_plinth             <-> recursive_boolean_cube     gap +0.67m (centers 2.00m)
  [OVERLAP] fibonacci_pagoda           <-> station_plinth             gap -0.44m (centers 2.00m)
  [OVERLAP] fibonacci_pagoda           <-> recursive_boolean_cube     gap -0.77m (centers 2.00m)
  [OVERLAP] station_plinth             <-> recursive_boolean_cube     gap -1.33m (centers 0.00m)
  [tight  ] station_plinth             <-> station_plinth             gap +1.00m (centers 2.00m)
  [tight  ] station_plinth             <-> recursive_chair            gap +0.75m (centers 2.00m)
  [tight  ] recursive_boolean_cube     <-> station_plinth             gap +0.67m (centers 2.00m)
  [tight  ] recursive_boolean_cube     <-> recursive_chair            gap +0.42m (centers 2.00m)
  [OVERLAP] station_plinth             <-> recursive_chair            gap -1.25m (centers 0.00m)
  [tight  ] station_plinth             <-> station_plinth             gap +1.00m (centers 2.00m)
  [tight  ] station_plinth             <-> recursive_table            gap +0.25m (centers 2.00m)
  [tight  ] recursive_chair            <-> station_plinth             gap +0.75m (centers 2.00m)
  [tight  ] recursive_chair            <-> recursive_table            gap +0.00m (centers 2.00m)
  [OVERLAP] station_plinth             <-> recursive_table            gap -1.75m (centers 0.00m)
  [tight  ] station_panel              <-> station_micropod           gap +0.78m (centers 1.78m)
  [tight  ] station_panel              <-> fractal_recursion_2        gap +0.75m (centers 1.78m)
  [tight  ] station_panel              <-> station_plinth             gap +0.97m (centers 1.97m)
  [tight  ] station_panel              <-> cube_subdivision           gap +0.97m (centers 1.97m)
  [OVERLAP] station_micropod           <-> fractal_recursion_2        gap -1.03m (centers 0.00m)
  [OVERLAP] station_plinth             <-> cube_subdivision           gap -1.00m (centers 0.00m)

RIDE LOG  (gaze FOV 90deg) - what hits the cortex (dom = how much it FILLS view):

  step 0  @(14,38) ENTRY facing hero=fibonacci_pagoda  facing -116deg
    station_plinth                         small   6deg  left    9.8m
    station_plinth                         small   5deg  right  11.2m
    station_plinth                         small   5deg  right  11.3m
    station_plinth                         small   5deg  CENTER 11.7m
    station_micropod                       small   5deg  left   11.8m

  step 1  @(6,32) -> cube_subdivision  facing +0deg
    station_plinth                         small   7deg  left    8.6m
    station_plinth                         small   6deg  left   10.2m
    station_plinth                         small   4deg  CENTER 16.0m
    example_8_4_cantor_set_vr              small   3deg  left   17.2m

  step 2  @(6,32) -> station_panel  facing -140deg
    station_panel                          big    29deg  CENTER  2.0m
    station_micropod                       med    23deg  left    2.5m
    station_plinth                         small  10deg  right   5.8m
    station_panel                          small   8deg  right   6.8m
    station_panel                          small   5deg  right  12.4m

  step 3  @(4,31) -> station_micropod  facing +124deg
    station_micropod                       big    31deg  CENTER  1.8m

  step 4  @(4,33) -> fractal_recursion_2  facing +0deg
    station_plinth                         med    23deg  CENTER  2.5m
    station_plinth                         small   6deg  left    9.1m
    station_plinth                         small   5deg  left   10.7m
    station_plinth                         small   5deg  left   12.4m
    example_8_4_cantor_set_vr              small   2deg  left   19.6m

  step 5  @(4,33) -> station_plinth  facing -80deg
    station_panel                          big    31deg  right   1.8m
    station_plinth                         small  10deg  CENTER  5.9m
    station_panel                          small   9deg  CENTER  6.5m
    station_plinth                         small   6deg  right   9.1m

  step 6  @(4,27) -> cube_staircase  facing +0deg
    box_counting_dimension                 big    33deg  left   18.4m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   3deg  right  18.3m

  step 7  @(4,27) -> station_panel  facing -143deg
    station_panel                          big    44deg  CENTER  1.2m
    station_plinth                         small  10deg  right   5.5m

  step 8  @(4,26) -> station_plinth  facing +14deg
    station_plinth                         big    44deg  right   1.2m
    box_counting_dimension                 big    32deg  left   19.2m
    station_plinth                         med    18deg  CENTER  3.1m
    station_plinth                         small   5deg  CENTER 11.0m
    example_8_4_cantor_set_vr              small   2deg  left   18.5m

  step 9  @(6,27) -> example_8_3_recursion_circles_vr  facing +0deg
    box_counting_dimension                 big    37deg  left   16.5m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   4deg  right  16.3m

  step 10  @(6,27) -> station_plinth  facing +0deg
    box_counting_dimension                 big    37deg  left   16.5m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   4deg  right  16.3m

  step 11  @(8,27) -> fibonacci_pagoda  facing +0deg
    box_counting_dimension                 big    41deg  left   14.7m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   4deg  right  14.5m

  step 12  @(8,27) -> station_plinth  facing +0deg
    box_counting_dimension                 big    41deg  left   14.7m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   4deg  right  14.5m

  step 13  @(10,27) -> recursive_boolean_cube  facing +0deg
    box_counting_dimension                 big    46deg  left   12.9m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   5deg  right  12.6m

  step 14  @(10,27) -> station_plinth  facing +0deg
    box_counting_dimension                 big    46deg  left   12.9m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   5deg  right  12.6m

  step 15  @(12,27) -> recursive_chair  facing +0deg
    box_counting_dimension                 big    53deg  left   11.1m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   5deg  right  10.8m

  step 16  @(12,27) -> station_plinth  facing +0deg
    box_counting_dimension                 big    53deg  left   11.1m
    station_plinth                         big    28deg  CENTER  2.0m
    station_plinth                         small   5deg  right  10.8m

  step 17  @(14,27) -> recursive_table  facing +0deg
    box_counting_dimension                 HUGE   60deg  left    9.5m
    station_plinth                         small   6deg  right   9.1m
    example_8_4_cantor_set_vr              small   6deg  CENTER  7.5m

  step 18  @(14,27) -> example_8_4_cantor_set_vr  facing -6deg
    box_counting_dimension                 HUGE   60deg  left    9.5m
    station_plinth                         small   6deg  right   9.1m
    example_8_4_cantor_set_vr              small   6deg  CENTER  7.5m

  step 19  @(22,26) -> box_counting_dimension  facing -90deg
    box_counting_dimension                 HUGE   96deg  CENTER  5.0m

  step 20  @(22,21) -> station_plinth  facing +90deg
    example_8_4_cantor_set_vr              small   9deg  CENTER  5.0m

  step 21  @(22,32) -> station_plinth  facing -150deg
    inverted_tree_cloud                    big    32deg  right  25.6m
    station_plinth                         small   6deg  CENTER  9.1m
    station_plinth                         small   5deg  CENTER 10.8m
    station_plinth                         small   5deg  CENTER 12.6m
    station_plinth                         small   4deg  CENTER 14.5m

  step 22  @(4,21) -> mandelbrot_dive  facing +0deg
    box_counting_dimension                 big    33deg  CENTER 18.5m
    station_plinth                         small   6deg  right   8.8m
    station_plinth                         small   5deg  right  10.5m
    station_plinth                         small   5deg  right  12.3m

  step 23  @(4,21) -> station_panel  facing -69deg
    station_panel                          big    40deg  CENTER  1.4m

  step 24  @(4,20) -> inverted_tree_cloud  facing -64deg
    inverted_tree_cloud                    HUGE   66deg  CENTER 11.3m

  step 25  @(9,10) -> EXIT  facing -90deg
    (nothing in view - dead step)

```
