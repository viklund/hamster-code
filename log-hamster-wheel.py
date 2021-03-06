#!/usr/bin/env python

import sys
from gpiozero import Button
from signal import pause
from datetime import datetime

button = Button(2)

def count():
    if button.is_pressed:
        now = datetime.now()
        print(now.timestamp())
        sys.stdout.flush()


button.when_pressed = count

sys.stderr.write("READY\n")
sys.stdout.flush()
pause()
