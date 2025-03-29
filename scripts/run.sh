#!/bin/bash

mkfifo output
cat output & 
bash -c "exec -a factorio_testing ../../bin/x64/factorio --cache-sprite-atlas -v --server-adminlist ./server-adminlist.json --server-settings ./server-settings.json --start-server-load-scenario survival-world/tester 2>&1 output" &
# ~/Software/factorio1/bin/x64/factorio --cache-sprite-atlas --mp-connect 0.0.0.0 2>&1 /dev/null &
~/Software/factorio2/bin/x64/factorio --cache-sprite-atlas --mp-connect 0.0.0.0 2>&1 /dev/null

