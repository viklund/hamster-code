#!/usr/bin/env python

import sys
from gpiozero import Button
from signal import pause
from datetime import datetime

button = Button(2)

num = 0
def count():
    global num
    if button.is_pressed:
        num += 1
        now = datetime.now()
        print("{}  {:5}".format(now, num))
        sys.stdout.flush()


button.when_pressed = count

sys.stderr.write("READY\n")
sys.stdout.flush()
pause()
