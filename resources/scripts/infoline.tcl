#!/usr/bin/tclsh

;# The voice synthesis parameters for this infoline:
;#
;# $ piper -m piper-voices/fr_FR-mls-medium.onnx -s0 --length-scale 1.6 --noise-scale 0.6 --noise-w 0.2 -s 17

set auto_path [linsert $auto_path 0 [file dirname $::argv0]]
package require ygi

::ygi::start_ivr
::ygi::set_dtmf_notify

::ygi::idle_timeout

::ygi::play_wait "le-temps-des-tempetes"
::ygi::play_wait "infoline/intro"

set tries 0

while { true } {
  ::ygi::play_wait "infoline/menu"
  set selected [::ygi::getdigit { 5000 }]

  if { $selected == "1" } {
    ::ygi::play_force "infoline/listen"

    ;# TODO: Ask for code and play
    ;#
  } elseif { $selected == "2" } {
    ::ygi::play_force "infoline/record"

    ;# TODO: Ask for code and password then access admin menu
    ;#
  } else {
    ::ygi::play_force "infoline/try-again"
    ::ygi::sleep 500

    incr tries 1
  }

  if { $tries > 2 } {
    break
  }
}

::ygi::quit
exit
