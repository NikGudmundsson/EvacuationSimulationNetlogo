;; Extension used for the matrix containing the locations of the exits
extensions [matrix]

;; Global variables for the tick count, location of the top left corner of the
;; emergency zone, and the matrix containing the matrix. These variables are
;; global so that they can be accessed from any of the program's procedures.
globals
[count-up evac-x evac-y exit-matrix]

;; Set up procedure for the program. Occurs when the user presses the setup button.
to setup
  ;; Clears the board of all lingering elements from a previous run and sets the
  ;; program to start at tick 0 (pretty much a time of 0).
  clear-all
  reset-ticks

  ;; Creates the turtles in the program. "people" is a variable representing the
  ;; number of turtles the user selected with the slider in the window view.
  create-turtles people [

    ;; Randomly places the turtle somewhere in the plane.
    setxy random-xcor random-ycor

    ;; Checks to see if a turtle is generated in a wall and moves it out if so.
    ask turtles with [
      ycor <= min-pycor + 2 ] [
      set ycor (ycor + 2)
    ]
    ask turtles with [
      ycor >= max-pycor - 2 ] [
      set ycor (ycor - 2)
    ]
    ask turtles with [
      xcor <= min-pxcor + 2 ] [
      set xcor (xcor + 2)
    ]
    ask turtles with [
      xcor >= max-pxcor - 2 ] [
      set xcor (xcor - 2)
    ]
  ]

  ;; Sets the appearance of all turtles to a happy face.
  ask turtles [ set shape "face happy"]

  ;; Sets the counter to start at 0. This variable is used to trigger the escape sequence.
  set count-up 0

  ;; Creates the grey border walls.
  ask patches with [ pycor < min-pycor + 1 or pycor > max-pycor - 1
  or pxcor < min-pxcor + 1 or pxcor > max-pycor - 1] [
    set pcolor grey
  ]

  ;; Creates the 4 red exits.
  ask patches with [ pycor < min-pycor + 1 and pxcor > -2 and pxcor < 2] [
    set pcolor red
  ]
  ask patches with [pycor > max-pycor - 1 and pxcor > -2 and pxcor < 2] [
    set pcolor red
  ]
  ask patches with [ pxcor < min-pxcor + 1 and pycor > -2 and pycor < 2] [
    set pcolor red
  ]
  ask patches with [pxcor > max-pxcor - 1 and pycor > -2 and pycor < 2] [
    set pcolor red
  ]

  ;; Presets the location of the emergency source to a random location somewhere in
  ;; the plane.
  set evac-x random-pxcor
  set evac-y random-pycor

  ;; If the emergency location is in a wall, then it is moved outside of the wall.
  if evac-x >= max-pxcor - 2  [
    set evac-x (evac-x - 2)
  ]
  if evac-x <= min-pxcor + 2  [
    set evac-x (evac-x + 2)
  ]
  if evac-y >= max-pycor - 2  [
    set evac-y (evac-y - 2)
  ]
  if evac-y <= min-pycor + 2  [
    set evac-y (evac-y + 2)
  ]

  ;; Creates a matrix representation of the center coordinates of the exits.
  set exit-matrix matrix:from-row-list [[-15.5 0] [15.5 0] [0 -15.5] [0 15.5]]

;; End of the procedure
end

;; "go" procedure. Runs a single loop if the single go button is pressed and
;; otherwise runs the entire program if the infinite go button is pressed.
to go
  ;; Used to track whether it is time to start the escape sequence procedure.
  ;; ticks-to-emergency is a variable given from the user from a text box.
  ;; Having user control of the ticks should allow for more precise control of the speed
  ;; of the program.
  if (count-up = ticks-to-emergency) [
    ;; Tells the program to start the escape procedure.
    escape
    ;; Ends the program.
    stop
  ]

  ;; Runs the bounce procedure.
  ask turtles [ bounce ]

  ;; Moves the turtles randomly through the plane.
  ask turtles [
    set heading (heading - 45 +  (random 90))
    forward 0.2
  ]

  ;; Counts up the number of times the loop has repeated.
  set count-up (count-up + 1)

  ;; End of the procedure
end

;; "bounce" procedure. Checks to see if a turtle has collided with a wall and bounces if so.
to bounce
  ;; Checks if a collision has occurred in the x direction
  if [pcolor] of patch-at dx 0 = grey or [pcolor] of patch-at dx 0 = red [
    set heading (- heading)
  ]
  ;; Checks if a collision has occurred in the y direction
  if [pcolor] of patch-at 0 dy = grey or [pcolor] of patch-at 0 dy = red [
    set heading (180 - heading)
  ]
  ;; End of the procedure.
end

;; "escape" procedure. "Spawns" in the emergency source, changes the turtle's appearance
;; then runs the escape sequence.
to escape
  ;; Makes the emergency source appear and sets the color to orange
  ask patches with [ pxcor > evac-x and pxcor < evac-x + 2 and pycor > evac-y and pycor < evac-y + 2] [
    set pcolor orange
  ]

  ;; Changes the appearance of the turtles.
  ask turtles [set shape "face sad"]

  ;; Tells the turtles to run the escape sequence.
  ask turtles [seek-bias-entrance]
  ;; End of procedure.
end

;; "flee" procedure. Pretty much has the turtle seek the closest viable exit and try
;; to get away from "block offs" by the source of the emergency.
to flee
  ;; List containing the distances to the exits. Set initially to invalid distances.
  ;; 50.0 is larger than the largest possible distance.
  let distance-list [50.0 50.0 50.0 50.0]

  ;; Sets looping variable to 0.
  let n 0

  ;; While loop used to move through the entire distance list.
  while [n < 4] [
    ;; Calculates the distance from the turtle to each exit in the matrix.
    let v (distancexy (matrix:get exit-matrix n 0) (matrix:get exit-matrix n 1))

    ;; Sets the distance from the exit to the given index in the list of distances.
    set distance-list replace-item n distance-list v

    ;; Increments the loop variable.
    set n (n + 1)
  ]

  ;; Variable used to check the number of current viable exits for the turtle.
  let true-count 0

  ;; Sets looping variable to 0.
  let j 0

  ;; Calculates the distance from the turtle to the center of the emergency source.
  let distance-to-source distancexy (evac-x + 1) (evac-y + 1)

  ;; Creates a list with the viability statuses for each exit. False means an exit is not
  ;; viable and true mean it is. Initially all exits are set to false and are updated in
  ;; the loop.
  let approach-list [false false false false]

  ;; Sets the heading away from the source.
  let approach-heading towardsxy (evac-x + 1) (evac-y + 1) + 180

  ;; Loop used to check whether an exit is viable for the turtle. A preference is given
  ;; here such that the turtle will try to avoid directions facing towards the source of
  ;; the emergency.
  while [j < 4] [
    ;; Calculates the heading for the turtle that faces the current exit being looked at.
    let exit-heading towardsxy (matrix:get exit-matrix j 0) (matrix:get exit-matrix j 1)

    ;; Calculates the heading difference between that of the exit and approach heading
    let diff subtract-headings exit-heading approach-heading

    ;; If the heading is within 180 degrees away from the emergency source (facing it) or
    ;; the exit is closer to the turtle than the emergency source is, then the exit is
    ;; considered valid.
    if (diff > -90 and diff < 90) or (item j distance-list < distance-to-source) [
      set approach-list replace-item j approach-list true

      ;; Increments the count of exits considered valid.
      set true-count (true-count + 1)
    ]

    ;; Increments the loop variable.
    set j (j + 1)
  ]

  ;; If the true count is 0, then there are no immediately valid exits. This means that
  ;; the emergency source stands roughly between the turtle and all other exits. Pretty much
  ;; the exits and the emergency source are all contained within a 180 degree heading from
  ;; the turtle.
  if true-count = 0 [
    ;; Variable for the heading of from the turtle to the emergency source.
    let head towardsxy (evac-x + 1) (evac-y + 1)

    ;; Horizontal distance from the turtle to the x file of the center of the emergency source.
    let dis-horizontal distancexy (evac-x + 1) ycor

    ;; Vertical distance from the turtle to the y file of the center of the emergency source.
    let dis-vertical distancexy xcor (evac-y + 1)

    ;; Checks if horizontal distance is shorter than the vertical distance.
    if dis-horizontal < dis-vertical [
      ;; Pretty much just heads to the nearest circumvention point for the emergency source
      ;; in the x direction. If you are on the left side of the plane, then you just have to
      ;; reach the natural edge file and if you are on the right, then the same, but + 2 to get
      ;; to the opposite edge. Draws this movement out (unfortunately because we do not yet know
      ;; the specific exit the turtle will go to, the color is randomized.
      if head > 180 and head < 360 [
        pen-down
        while [dis-horizontal > 0.0] [
          set heading towardsxy evac-x ycor
          forward 0.2
          set dis-horizontal (dis-horizontal - 0.2)
        ]
        pen-up
      ]
      if head > 0 and head < 180 [
        pen-down
        while [dis-horizontal > 0.0] [
          set heading towardsxy (evac-x + 2) ycor
          forward 0.2
          set dis-horizontal (dis-horizontal - 0.2)
        ]
        pen-up
      ]
    ]
    ;; Same thing as the above, but for the y direction.
    if dis-horizontal >= dis-vertical [
      if head > 90 and head < 270 [
        pen-down
        while [dis-vertical > 0.0] [
          set heading towardsxy xcor evac-y
          forward 0.2
          set dis-vertical (dis-vertical - 0.2)
        ]
        pen-up
      ]
      if head > 270 or head < 90 [
        pen-down
        while [dis-vertical > 0.0] [
          set heading towardsxy xcor (evac-y + 2)
          forward 0.2
          set dis-vertical (dis-vertical - 0.2)
        ]
        pen-up
      ]
    ]

    ;; Recalculates the distance list.
    let q 0
    while [q < 4] [
      let val (distancexy (matrix:get exit-matrix q 0) (matrix:get exit-matrix q 1))
      set distance-list replace-item q distance-list val

      set q (q + 1)
    ]

    ;; Recalculates the viable heading list.
    let w 0
    set distance-to-source distancexy (evac-x + 1) (evac-y + 1)
    set approach-heading towardsxy (evac-x + 1) (evac-y + 1) + 180
    while [w < 4] [
      let exit-heading towardsxy (matrix:get exit-matrix w 0) (matrix:get exit-matrix w 1)
      let diff subtract-headings exit-heading approach-heading
      if (diff > -90 and diff < 90) or (item w distance-list < distance-to-source) [
        set approach-list replace-item w approach-list true
        set true-count (true-count + 1)
      ]
      set w (w + 1)
    ]
  ]

  ;; Sets looping variable to 0.
  let i 0
  ;; Creates the min index local variable and initializes it to an invalid index.
  ;; I wasn't quite sure how to get this set up as just declaring the variable and
  ;; not initializing it, but made sure that the index would never be -1.
  let min-index -1

  ;; Creates a local variable for the distance to the exit
  let min-val 50.0

  ;; Loop used to locate the index of the viable exit with the smallest distance to the
  ;; turtle.
  while [i < 4] [

    ;; Special case for the first value. Checks if the first value is valid and if so, sets
    ;; the local variables accordingly.
    if i = 0 and item i approach-list = true [
      set min-index i
      set min-val item 0 distance-list
    ]

    if i != 0 [
      ;; Checks to see if a value is valid and whether the distance is shorter than the
      ;; current shortest distance. If so, then the local variables are set accordingly.
      if item i approach-list = true and item i distance-list < min-val [
        set min-index i
        set min-val item i distance-list
      ]
    ]

    ;; Increments the loop variable.
    set i (i + 1)
  ]

  ;; Sets the color of the turtle depending on the exit it will be approaching.
  if min-index = 0 [
    set color red
  ]
  if min-index = 1 [
    set color blue
  ]
  if min-index = 2 [
    set color green
  ]
  if min-index = 3 [
    set color yellow
  ]

  ;; Sets the heading towards the exit of choice.
  set heading (towardsxy (matrix:get exit-matrix min-index 0) (matrix:get exit-matrix min-index 1))

  ;; Starts drawing the trail.
  pen-down

  ;; Has the turtle travel to the exit.
  while [min-val > 0.0] [
    forward 0.2
    set min-val (min-val - 0.2)
  ]

  ;; Once the turtle has reached the exit, then it disappears.
  die

  ;; End of procedure.
end

;; "seek-bias-entrance" procedure. Does two things, it first checks whether the bias is an
;; acceptable exit location. This occurs largely through randomness, but also if the turtle
;; would come too close to the emergency source.
to seek-bias-entrance
  ;; Random number generator used to determine whether to continue immediately. Entrance
  ;; bias is given via user input.
  if random 101 > entrance-bias [
    flee
    stop
  ]

  ;; Randomly selects one of the four exits
  let entrance random 4

  ;; Sets up the bias list. This could actually have been done with just direct values.
  let bias-distance-list [50.0 50.0 50.0 50.0]

  ;; Calculates the distance from the turtle to the exit of choice.
  let bias-exit-val (distancexy (matrix:get exit-matrix entrance 0) (matrix:get exit-matrix entrance 1))

  ;; Sets the distance in the distance list to the exit of choice.
  set bias-distance-list replace-item entrance bias-distance-list bias-exit-val

  ;; Gets the distance from the list. This is actually unnecessary, but a previous version
  ;; of the code was a little more involved.
  let bias-distance item entrance bias-distance-list

  ;; Sets the the heading of the turtle to the exit of choice.
  set heading (towardsxy (matrix:get exit-matrix entrance 0) (matrix:get exit-matrix entrance 1))

  ;; Creates a local variable for the heading from the turtle to the center of the
  ;; emergency source.
  let bi-head towardsxy (evac-x + 1) (evac-y + 1)

  ;; Calculates the heading difference between the heading to the exit and to the emergency source.
  let diff subtract-headings heading bi-head

  ;; Finds the distance from the turtle to the center of the emergency source.
  let check-distance distancexy (evac-x + 1) (evac-y + 1)

  ;; Tiered conditionals with a degree of randomness. If the the heading of the turtle would
  ;; pass within 30 degrees of the emergency source, then the turtle follows the shortest
  ;; distance procedure. If the the turtle would pass withing 105 degrees of the emergency
  ;; source, then there is 50% chance that the turtle follows the shortest distance procedure.
  ;; If the turtle passes within 180 degrees (In truth within 37.5 degrees to the edges of 180
  ;; degrees, then the turtle has a 25% chance that it follows the shortest distance procedure.
  if diff > -15 and diff < 15 and check-distance < bias-distance + 1 [
    flee
    stop
  ]
  if diff > -52.5 and diff < 52.5 and check-distance < bias-distance + 1 [
    if random 101 < 51 [
      flee
      stop
    ]
  ]
  if diff > -90 and diff < 90 and check-distance < bias-distance + 1 [
    if random 101 < 26 [
      flee
      stop
    ]
  ]

  ;; Sets the color of the turtle depending on the exit it will be approaching.
  if entrance = 0 [
    set color red
  ]
  if entrance = 1 [
    set color blue
  ]
  if entrance = 2 [
    set color green
  ]
  if entrance = 3 [
    set color yellow
  ]

  ;; Starts drawing the trail.
  pen-down

  ;; Has the turtle travel to the exit.
  while [bias-distance > 0.0] [
    forward 0.2
    set bias-distance (bias-distance - 0.2)
  ]

  ;; Once the turtle has reached the exit, then it disappears.
  die

  ;; End of procedure.
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
6
10
69
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
48
69
81
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
85
69
118
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
130
192
163
people
people
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
77
10
148
43
NIL
escape
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
169
192
202
entrance-bias
entrance-bias
0
100
0.0
1
1
NIL
HORIZONTAL

INPUTBOX
29
209
184
269
ticks-to-emergency
100000.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
