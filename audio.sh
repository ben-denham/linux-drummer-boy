#!/bin/bash

DEVICE_KEY="alsa"
QSYNTH_SINK="ldb_qsynth_sink"
RECORDING_SINK="ldb_recording_sink"
DEFAULT_SINK="ldb_default_sink"
MIC_LOOPBACK="module-loopback"
RECORDING_SOURCE="ldb_recording_source"

function get_module_id_for_sink_name () {
    sink_name="$1"
    module_id_prefix="Owner Module: "
    module_line=`pactl list sinks | grep -x -A 5 "[[:space:]]Name: $sink_name" | grep "$module_id_prefix"`
    echo `echo $module_line | sed "s/$module_id_prefix//g"`
}

function remove_sink_by_name () {
    sink_name="$1"
    module_id=`get_module_id_for_sink_name $sink_name`
    if [ ! -z "$module_id" ]; then
        pactl unload-module "$module_id"
    fi
}

function get_module_id_for_source_name () {
    source_name="$1"
    module_id_prefix="Owner Module: "
    module_line=`pactl list sources | grep -x -A 5 "[[:space:]]Name: $source_name" | grep "$module_id_prefix"`
    echo `echo $module_line | sed "s/$module_id_prefix//g"`
}

function remove_source_by_name () {
    source_name="$1"
    module_id=`get_module_id_for_source_name $source_name`
    if [ ! -z "$module_id" ]; then
        pactl unload-module "$module_id"
    fi
}

function get_module_id_for_module_name () {
    module_name="$1"
    echo `pactl list short modules | grep "$module_name" | awk '{print $1}'`
}

function remove_module_by_name () {
    module_name="$1"
    module_id=`get_module_id_for_module_name $module_name`
    if [ ! -z "$module_id" ]; then
        pactl unload-module "$module_id"
    fi
}

# Remove any sinks/modules managed by this script that may already exist.
remove_sink_by_name $QSYNTH_SINK
remove_sink_by_name $RECORDING_SINK
remove_sink_by_name $DEFAULT_SINK
remove_module_by_name $MIC_LOOPBACK
remove_source_by_name $RECORDING_SOURCE

# If stop argument is passed, then don't start everything.
if [ "$1" = "stop" ]; then
    exit 0
fi

device_sink=`pactl list short sinks | grep "$DEVICE_KEY" | awk '{print $2}'`
if [ -z "$device_sink" ]; then
    echo "Unable to find device sink with key: $DEVICE_KEY"
    exit 1
fi
device_source=`pactl list short sources | grep "$DEVICE_KEY" | grep -v ".monitor" | awk '{print $2}'`
if [ -z "$device_source" ]; then
    echo "Unable to find device source with key: $DEVICE_KEY"
    exit 1
fi

# Set up a $RECORDING_SINK to capture desktop sound and microphone.
pactl load-module module-null-sink sink_name="$RECORDING_SINK" \
      sink_properties=device.description=Recording_Sink \
      > /dev/null
# Forward microphone to $RECORDING_SINK
pactl load-module module-loopback source="$device_source" \
      sink="$RECORDING_SINK" latency_msec=1 \
      > /dev/null
# Create a DEFAULT_SINK that will forward everything it receives to
# the RECORDING_SINK and speakers.
pactl load-module module-combine-sink sink_name="$DEFAULT_SINK" \
      sink_properties=device.description=Default_Sink \
      slaves="${RECORDING_SINK},${device_sink}" \
      > /dev/null
# Set all apps to forward to the DEFAULT_SINK by default.
pactl set-default-sink "$DEFAULT_SINK"
# Create a $QSYNTH_SINK that forwards to $DEFAULT_SINGK (allows
# controlling qsynth volume separately).
pactl load-module module-combine-sink sink_name="$QSYNTH_SINK" \
      sink_properties=device.description=Qsynth_Sink \
      slaves="${DEFAULT_SINK}" \
      > /dev/null
pactl set-sink-volume ldb_qsynth_sink 7.0
# Create a source that exposes $RECORDING_SINK as an input device
# (e.g. to voice call software).
pactl load-module module-remap-source source_name="$RECORDING_SOURCE" \
      source_properties=device.description=Recording_Source \
      master="${RECORDING_SINK}.monitor" \
      > /dev/null
