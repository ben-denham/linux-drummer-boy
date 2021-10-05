#!/bin/bash

METRONOME_NAME="Drumstick Metronome"
QSYNTH_NAME="FLUID Synth"
DRUMKIT_NAME="Alesis Surge"

function get_midi_id () {
    midi_name="$1"
    echo `aconnect -l | grep "$midi_name" | grep -o "client [[:digit:]]*" | sed 's/client //g'`
}

killall pavucontrol 2> /dev/null
killall -9 qsynth 2> /dev/null
killall kmetronome 2> /dev/null

# If stop argument is passed, then don't start everything.
if [ "$1" = "stop" ]; then
    exit 0
fi

pavucontrol &
# apt install qsynth
qsynth --option audio.pulseaudio.device=ldb_qsynth_sink --option synth.gain=1 &
# apt install kmetronome
kmetronome &
# Give midi devices time to launch
sleep 1

metronome_id=`get_midi_id $METRONOME_NAME`
if [ -z "$metronome_id" ]; then
    echo "Unable to find metronome device: $METRONOME_NAME"
    exit 1
fi
qsynth_id=`get_midi_id $QSYNTH_NAME`
if [ -z "$qsynth_id" ]; then
    echo "Unable to find qsynth device: $QSYNTH_NAME"
    exit 1
fi

# Connect midi metronome to qsynth
aconnect $metronome_id $qsynth_id


drumkit_id=`get_midi_id $DRUMKIT_NAME`
if [ -z "$drumkit_id" ]; then
    echo "Unable to find drumkit device: $DRUMKIT_NAME"
    exit 1
fi

# Connect midi drumkit to qsynth
aconnect $drumkit_id $qsynth_id
