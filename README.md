# Linux Drummer Boy

Scripts for configuring an electronic drumming environment in Linux:

* Connects a MIDI drum kit and virtual MIDI metronome to the qsynth
  synthesizer.
* Sends all desktop audio (including qsynth) to a `Default_Sink` that
  is connected to the speakers.
* Forwards `Default_Sink` and the microphone to a `Recording_Source`
  device that can be used in place of the microphone in
  recording/calling applications.

## Usage

* `./start.sh`
* `./stop.sh`

## TODO

* Consider switching out pulseaudio & ALSA for JACK to get better
  latency.
