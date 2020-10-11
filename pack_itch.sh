#!/bin/bash

rm -rf bin_itch bin_itch.zip
mkdir -p bin_itch
cp bin/game.js bin/howler.min.js bin/png.glw bin/wav.glw bin/logo.png bin_itch
cp bin/index_itch.html bin_itch/index.html
zip -r bin_itch bin_itch
