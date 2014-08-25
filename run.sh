#!/usr/bin/env bash

# Do not calculate Touch Sensor For Now
# Touch Sensor First
# find data -name '*touchsensor.txt' -print0 | xargs -0 -I file ruby timer.rb -f touch -i file

# Sensor Touch
find data -name '*ST*.txt' -print0 | xargs -0 -I file ruby timer.rb -f sensor -i file

# Remove Old Data
find data -name "*.txt" | grep -v "time.txt" | xargs rm -f

# Rename & Clean up
cp README.txt data/
rm -rf 无字母结果/
mv data/ 无字母结果/
cp -r data_bak/ data/