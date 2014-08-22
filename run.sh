#!/usr/bin/env bash

# Touch Sensor First
find data -name '*touchsensor.txt' -print0 | xargs -0 -I file ruby timer.rb -f touch -i file

# Sensor Touch
find data -name '*sensortouch.txt' -print0 | xargs -0 -I file ruby timer.rb -f sensor -i file