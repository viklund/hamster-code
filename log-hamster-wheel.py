#!/usr/bin/env python2

import sys
from os import path
from signal import pause
import time

from gpiozero import Button
from datetime import datetime

button = Button(2)

filename_pattern = "logs/hamster-spinner-%Y%m%d%H%M%S.log"

filename = datetime.now().strftime(filename_pattern)
while path.isfile(filename):
    time.sleep(1)
    filename = datetime.now().strftime(filename_pattern)

# Open file without buffering, in case power gets cut for some reason.
fh = open(filename, 'w', buffering=0)

def count():
    if button.is_pressed:
        now = datetime.now()
        fh.write(now.strftime("%s.%f\n"))

button.when_pressed = count

pause()
