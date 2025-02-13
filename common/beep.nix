# - Allow the system to beep happily
{...}: {
  users.groups.beep = {};
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="PC Speaker", ENV{DEVNAME}!="", GROUP="beep", MODE="0620"
  '';
}
