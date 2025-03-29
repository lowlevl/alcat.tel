#!/usr/bin/tclsh

set auto_path [linsert $auto_path 0 [file dirname $::argv0]]
package require ygi

::ygi::start_ivr
::ygi::set_dtmf_notify

::ygi::idle_timeout

::ygi::play_wait "intro"
::ygi::sleep 500

while { true } {
  set digit [::ygi::play_getdigit file "waiting/wii-shop"]

  if { $digit == "1" } { ::ygi::play_getdigit file "music/rick-roll" stopdigits { 3 } }
  if { $digit == "2" } { ::ygi::play_getdigit file "music/woop-woop" stopdigits { 3 } }
}
