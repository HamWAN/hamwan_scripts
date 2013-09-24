#!/usr/bin/env python
from datetime import datetime
import socket
import settings


class AprsObject:
    time = datetime.utcnow().strftime("%d%H%M")

    def __init__(self, name="", lat="", lon="", comment=""):
        self.name = name.ljust(9)
        self.lat = lat
        self.lon = lon
        self.comment = comment

    def __getitem__(self, key):
        return getattr(self, key)

    def __str__(self):
        return ";%(name)s*%(time)sz%(lat)sN/%(lon)sWr%(comment)s" % self


objs = [
    AprsObject(
        name="HamWANbld",
        lat="4713.14",
        lon="12150.60",
        comment="  5.890GHz 5.905GHz 5.920GHz nv2 data"
    ),
    AprsObject(
        name="HamWANcap",
        lat="4737.43",
        lon="12218.91",
        comment="  5.920GHz nv2 data"
    ),
    AprsObject(
        name="HamWANmir",
        lat="4727.75",
        lon="12158.44",
        comment="  5.890GHz nv2 data"
    ),
    AprsObject(
        name="HamWANpne",
        lat="4755.43",
        lon="12214.66",
        comment="  5.890GHz 5.905GHz 5.920GHz nv2 data"
    ),
]


# create socket and connect to server
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((settings.APRS_SERVER_HOST, settings.APRS_SERVER_PORT))
sock.send('user %s pass %s vers KD7LXL-Python 0.2\n' % (settings.APRS_USER, settings.APRS_PASSCODE) )

for obj in objs:
    packet = "%s>APRS:%s\n" % (settings.APRS_USER, obj)
    sock.send(packet)
    print packet,

# close socket -- must be closed to avoid buffer overflow
sock.shutdown(0)
sock.close()
