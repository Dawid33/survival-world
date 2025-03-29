#!/bin/sh

PREVIOUS=$(xdotool getactivewindow)
FAC_PID=$(ps axf | grep factorio_testing | grep -G -v 'grep\|bash' | awk '{ print $1 }')
FAC_WINDOW=$(xdotool search --pid $FAC_PID)
eval $(xdotool getwindowgeometry --shell --prefix FAC_ $FAC_WINDOW)

# Pause Menu
xdotool windowactivate $FAC_WINDOW
xdotool type --window $FAC_WINDOW 

sleep 0.1

# Quit Game
xdotool mousemove $(echo "$FAC_WIDTH / 2 + $FAC_X" | bc) $(echo "$FAC_HEIGHT / 1.78 + $FAC_Y" | bc)
sleep 0.1
xdotool click --window $FAC_WINDOW 1
xdotool type --delay 1000 --window $FAC_WINDOW EE
xdotool windowactivate $PREVIOUS
