#!/bin/bash

/usr/bin/ps aux | /usr/bin/grep postgres | /usr/bin/grep -E "(checkpointer|archiver|startup|walsender|walreceiver)" | awk '{print $2}' | xargs renice -n -20
