#!/bin/sh 
killall alsa_in 
killall alsa_out 
sleep 1 
alsa_in -d hw:CARD=Device -r 44100 & 
alsa_out -d hw:CARD=K6 -r 44100 & 
sleep 1 
jack_connect alsa_in:capture_1 softcut:input_1 
jack_connect alsa_in:capture_2 softcut:input_2 
jack_connect alsa_in:capture_1 crone:input_1 
jack_connect alsa_in:capture_2 crone:input_2 
jack_connect softcut:output_1 alsa_out:playback_1 
jack_connect softcut:output_2 alsa_out:playback_2 
jack_connect crone:output_1 alsa_out:playback_1 
jack_connect crone:output_2 alsa_out:playback_2 
