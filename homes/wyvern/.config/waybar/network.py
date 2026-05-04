#!/usr/bin/env python3
import subprocess
import json
import time
import re
import sys

MAX_HANDSHAKE_AGE = 180


def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
    except subprocess.CalledProcessError:
        return None


def output(alt, text=None):
    data = {"alt": alt}
    if text:
        data["text"] = text
    print(json.dumps(data))
    sys.exit(0)


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def clean(s):
    return ANSI_RE.sub("", s)

output("disabled", "(todo)")

# 1. We have to check whether there is a wired connection
# -> if we do then we do vpn checks, otherwises show wired(unprotected) END OF SCRIPT
# -> if we dont, we do RFKILL check output disabled if it is. otherwise continue with the script 
#   

# we must now look for a wireless interface, it should be unblocked because we checked with rfkill if there was no wired connection
# 3 we have to check if there is an active wireless connection or whether its disconnected
# -> if disconnected we output disconnected (disconnected)
# -> if there is a connection we do vpn checks otherwise we show wireless(unprotected)

