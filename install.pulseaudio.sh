#!/bin/sh
apt-get install pulseaudio paprefs libpulse-mainloop-glib0 pulseaudio-module-jack pavucontrol pulseaudio-module-hal pulseaudio-module-x11 gstreamer0.10-pulseaudio pulseaudio-utils libasound2-plugins paman pulseaudio-module-gconf libgconfmm-2.6-1c2 libpulse-browse0 pavumeter libglademm-2.4-1c2a pulseaudio-esound-compat libpulse0 libpulse-dev pulseaudio-module-bluetooth pulseaudio-module-zeroconf
cat >> /etc/asound.conf << EOF
pcm.pulse {
    type pulse
}

ctl.pulse {
    type pulse
}

pcm.!default {
    type pulse
}

ctl.!default {
    type pulse
}
EOF
pulseaudio -D