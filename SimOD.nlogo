globals [
  ;;COUNTERS for cumulative plots and pmp projection
  ACTUALS_COUNTER
  pmp
  TCcoordinates

  n-icus
  POSSIBLE_COUNTER
  POTENTIAL_COUNTER
  ELIGIBLE_COUNTER
  DeceasedNoDonation
]

;;TURTLES
breed [donors donor]
donors-own [state]                          ;;States: possible, potential, elegible, actual donor, (deceased) no-donation.
breed [dass das]
breed [tcs tc]
tcs-own [available]

;;PATCHES
patches-own [land icu staffed]

to setup
  ca                                        ;;CLEAR DATA
  set n-icus 81                             ;;Static number of ICUs, can be changed into Slider
  import-pcolors "map.png"                  ;;GENERATE environment from file
  create-infrastructure
  set TCcoordinates [[-128 -454] [-40 -343 ] [-188 -354] [54 -199] [-57 -143] [20 223]]
  make-staff                                ;;ASSIGN STAFF TO ICUS, create TCs at specified coordinates
  reset-ticks
end


to go
  ask links [die]                           ;;reset links
  ask donors [ die ]                        ;;Remove patients who donated or died with no donation in previous round
  make-donor-pool                           ;;CREATE DECEASED DONOR POOL
  assign_staff                              ;;connect them with STAFF if available, otherwise declare death no donation
  contact_coordinator                       ;;Staff contact TC according to chosen rate
  check-viability                           ;;TC checks medical viability and consent
  update-counters

  do-plots                                  ;;Plot graph
  year-pmp                                  ;;Plot yearly donor rate pmp

  tick                                      ;;In this model, tick = day
end


to create-infrastructure
  ask patches [                             ;;Processing map pixels to create the required number of ICUs, position is randomised
    if pcolor = 54.7 [ set icu 0.5 ]
    if pcolor != 9.9 [ set land 1 ]
    ]
  ask n-of n-icus patches with [icu = 0.5 ][ set icu 1 ]
  ask patches with [icu = 1 ] [set staffed False]
end


to make-staff
  ask n-of Staff patches with [ icu = 1 ][
    sprout-dass 1 [
      set shape "person"
      set color black
      set size 15
      set staffed True]]

  foreach TCcoordinates [ xy -> create-tcs 1 [ setxy item 0 xy item 1 xy ] ]
  ask tcs [
    set size 12
    set color orange
    set shape "target"]
end


to make-donor-pool
  let daily_possible total_population * bd_rate      ;;Percentage of deceased matching ICD-10 codes for brain death within the population
  let base_pool random-poisson daily_possible        ;;Defines the average number of donors to create

    create-donors base_pool [
    setxy random-xcor random-ycor
    move-to one-of patches with [ icu = 1 ]
    ask donors [
      set shape "person"
      set color blue
      set size 15
      set state "possible" ]]
end


to assign_staff
  ask donors [if [staffed] of patch-here = True [       ;;Check if ICU is Staffed
      set color red
      set state "potential"]]
end


to contact_coordinator
  let tc_contacted count donors with [state = "potential"] * contact_TC / 100
   ask n-of tc_contacted dass [
    create-link-to one-of tcs [set color green]          ;;OPTICS ONLY, will need to calculate TC workload
  ]
  if count donors with [state = "potential"] > tc_contacted [
    ask n-of ceiling tc_contacted donors with [state = "potential"] [
    set color yellow
    set shape "x"
    set state "elegible"]
  ]
end


to check-viability
  let viable count donors with [state = "elegible"] * consent_and_viability / 100

  if count donors with [state = "elegible"] > viable [
  ask n-of viable donors with [state = "elegible"] [
    set color green
    set shape "target"
    set state "actual-donor"
  ]]
end

to update-counters
  set POSSIBLE_COUNTER POSSIBLE_COUNTER + count donors with [state = "possible"]       ;;POSSIBLE DONOR DID NOT HAVE STAFF
  set POTENTIAL_COUNTER POTENTIAL_COUNTER + count donors with [state = "potential"]    ;;POTENTIAL DONOR'S STAFF DID NOT CONTACT TC
  set ELIGIBLE_COUNTER ELIGIBLE_COUNTER + count donors with [state = "elegible"]       ;;ELIGIBLE DONOR DID NOT CLEAR MEDICAL CHECKS OR DID NOT CONSENT TO DONATION
  set ACTUALS_COUNTER ACTUALS_COUNTER + count donors with [state = "actual-donor"]     ;;DONOR PROCEEDED TO DONATION
  set DeceasedNoDonation POSSIBLE_COUNTER + POTENTIAL_COUNTER + ELIGIBLE_COUNTER       ;;SUM ALL COUNTERS EXCEPT ACTUAL DONORS

end

to year-pmp
  let not-year ticks mod 365                                                           ;;ONLY RUNS AT THE END OF EACH YEAR
  if ticks > 1 and not-year = 0 [
    let n-years ticks / 365
    output-type n-years
    output-type "° Year PMP: "
    output-print floor pmp ]
end


to do-plots
  set-current-plot "Actual donors (pmp)"                                                ;;PLOT ESTIMATED PMP
  set-current-plot-pen "Sweden pmp 2023"
  plot 25
  set-current-plot-pen "Spain pmp 2023"
  plot 50
  set-current-plot-pen "current pmp"
  if ticks > 0 [
    let current_rate ACTUALS_COUNTER / ticks
    let projected_total_volume current_rate * 365
    let projected_pmp projected_total_volume / total_population
    plot projected_pmp

    let year ticks mod 365
    if year = 0 [
    set pmp projected_pmp                                                                ;;UPDATE VALUE OF GLOBAL PMP TO THIS YEAR'S VALUE
    ]
  ]


  let total DeceasedNoDonation + ACTUALS_COUNTER                                         ;;PLOT DAILY DONOR STATES
  if total > 0 [
    let psd_percentage (POSSIBLE_COUNTER / total)
    let pd_percentage ((POTENTIAL_COUNTER + POSSIBLE_COUNTER) / total)
    let ed_percentage ((ELIGIBLE_COUNTER + POSSIBLE_COUNTER + POTENTIAL_COUNTER) / total)
    let ad_percentage ((ACTUALS_COUNTER + ELIGIBLE_COUNTER + POSSIBLE_COUNTER + POTENTIAL_COUNTER) / total)

  set-current-plot "Daily Donor State Probabilities"
  set-current-plot-pen "possible donors"
  plot psd_percentage
  set-current-plot-pen "potential donors"
  plot pd_percentage
  set-current-plot-pen "eligible donors"
  plot ed_percentage
  set-current-plot-pen "actual donors"
  plot ad_percentage]
end
@#$#@#$#@
GRAPHICS-WINDOW
247
10
788
1074
-1
-1
0.046211
1
10
1
1
1
0
0
0
1
-270
270
-527
527
0
0
1
ticks
30.0

BUTTON
30
417
99
451
setup
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
30
464
198
497
go
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

BUTTON
105
417
198
451
go once
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
19
265
213
298
CurrentPolicy
;;INFRASTRUCTURE\nset contact_TC 64 ;TC contacted 64% of cases\nset consent_and_viability 62.17 ;62% of contacts lead to donation\nset Staff 33\n;;POPULATION\nset total_population 10.54 ;swedish population 2024\nset bd_rate 0.49
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
19
310
215
343
Expand Donor Pool - ICOD
set bd_rate 0.89
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
1056
303
1250
336
contact_TC
contact_TC
0
100
64.0
1
1
%
HORIZONTAL

SLIDER
1056
343
1250
376
consent_and_viability
consent_and_viability
0
100
62.17
1
1
%
HORIZONTAL

TEXTBOX
840
268
1012
288
Interventions
19
0.0
1

SLIDER
24
157
228
190
bd_rate
bd_rate
0
10
0.49
0.1
1
deceased pmp
HORIZONTAL

TEXTBOX
22
227
172
250
Policy
19
0.0
1

BUTTON
838
303
977
336
Best practices TC
set contact_TC 87.5
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
273
29
593
85
THIS MODEL IS A PROOF OF CONCEPT AND SHOULD NOT BE USED FOR DECISION-MAKING
11
15.0
1

BUTTON
838
343
976
376
Best practices Donation
\nset consent_and_viability 82
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
831
416
1250
650
Actual donors (pmp)
donors pmp
ticks
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"current pmp" 1.0 0 -14730904 true ";DAY 1: if the rate of donors is that of today for the rest of the year,\n;what would be our pmp rate?\n;DAY 2 if the donor rate was today's+yesterday's for the rest of the year\n;current_rate = actual_donor_count / the n days elapsed\n;projected_pmp = current rate * remaining days in the year\n;daily actual donors * 365 - ticks / 10.54\n" ""
"Spain pmp 2023" 1.0 0 -15040220 true "" ""
"Sweden pmp 2023" 1.0 0 -4079321 true "" ""

OUTPUT
17
525
217
760
13

SLIDER
24
114
227
147
total_population
total_population
1
60
10.54
1
1
million
HORIZONTAL

TEXTBOX
25
82
175
105
Population
19
0.0
1

TEXTBOX
841
209
991
232
Infrastructure
19
0.0
1

SLIDER
1061
204
1253
237
Staff
Staff
0
81
33.0
1
1
NIL
HORIZONTAL

PLOT
833
673
1252
922
Daily Donor State Probabilities
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"actual donors" 1.0 1 -10899396 true "" ""
"eligible donors" 1.0 1 -4079321 true "" ""
"potential donors" 1.0 1 -817084 true "" ""
"possible donors" 1.0 1 -2674135 true "" ""

@#$#@#$#@
# SIMSWEDOD

A model for assessing the impact of policy change in organ donation systems; case study: Sweden.

## AGENTS
* Patients: here called donors since only patients who die are considered in the model.
Donors have different states, describing them with respect to organ donation.
    * States are: possible, potential, elegible, actual, and deceased without donation (no-donation).

* STAFF: Hospital staff responsible for donation procedures.
They are tasked with discovering potential donors, contacting the TCs when death is inevitable and guiding the donation process.

* TC: Transplant Coordinators. They coordinate the process from donation (ICU) to transplantation (Transplant Hospitals) according to supply and demand. They are responsible for:
    * contacting Transplant Surgeons (not modeled), who establish the medical viability and
    * investigating consent via the registry and families of the deceased (Potential Donors).

* Patches: ICUs, Intensive Care Units, generated via the map and according to the number of public ICU in the country.

## SLIDERS AND INTERFACE

* Population
    * total_population: the total population of the country
    * bd_rate: the rate of brain death, obtained via ICD-10 codes explaining actual donor diagnosis

* Infrastructure
    * Staff: the amount of specialised Organ Donation Staff which is distributed across ICUs
    * n-icus: the amount of ICUs active in the country

* Interventions
  * Best Practice TC: sets the average TC contact rate from the national average (2015-2023) to the local best performers.
  * Best Practices Donation: sets the average Medical Viability and Consent rate from the national average (2015-2023) to the local best performer hospitals.

* Policy
  * Current Policy: sets all inputs to 2023's values.
  * ICOD: simulates donor pool expansion.

## THINGS TO NOTICE

Notice the plot of yearly pmp and its reaction to slider value changes.
Notice the Donor state plot for insights into the effect of policies and interventions on the functioning of the donation system as a whole.

## THINGS TO TRY

Modify the value of Staff, hit Setup and run the simulation, compare Donor States to previous runs.

## EXTENDING THE MODEL

This model can be expanded with more agents e.g. ORGAN TYPES, DONOR DEMOGRAPHICS, POPULATION CHANGES etc.

## NETLOGO FEATURES

The function _random-poisson_ is used to simulate fluctuations in donor pool.


## CREDITS AND REFERENCES

Developed 2025 by Bertilla Fabris, Malmö University, Department of Computer Science and Media Technology. Supervisors: Fabian Lorig and Jason Tucker.
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Scenario1-Baseline" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9125 ;;25 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2bSTAFFINCREASE" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62.17"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Staff" first="33" step="6" last="81"/>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2bSTAFFINCREASE (1)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62.17"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Staff" first="33" step="6" last="81"/>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2b-OptimalStaff" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2a+2b" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 4015 ;;11 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <metric>STAFF_ESTIMATE</metric>
    <runMetricsCondition>ticks mod 365 = 0</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="87.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-icus">
      <value value="81"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Staff" first="65" step="4" last="81"/>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario3-bestCV" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 4015 ;;11 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <metric>STAFF_ESTIMATE</metric>
    <runMetricsCondition>ticks mod 365 = 0</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-icus">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario4-ICOD" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="62.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2b-OptimalMVC" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario2a+2b+2c" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="87.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Scenario4-ALL_BEST" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 9490 ;;26 years</exitCondition>
    <metric>PMP_per_year</metric>
    <metric>POSSIBLE_COUNTER</metric>
    <metric>POTENTIAL_COUNTER</metric>
    <metric>ELIGIBLE_COUNTER</metric>
    <metric>ACTUALS_COUNTER</metric>
    <runMetricsCondition>ticks &gt; 365</runMetricsCondition>
    <enumeratedValueSet variable="contact_TC">
      <value value="87"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consent_and_viability">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Staff">
      <value value="81"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bd_rate">
      <value value="0.89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total_population">
      <value value="10.54"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
