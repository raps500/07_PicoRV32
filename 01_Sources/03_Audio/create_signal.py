#!/usr/bin/env python

integrator = 0
old_value = 0

for i in range(2048):
    for j in range (64):
        integrator += (i >> 4) - old_value
        if (integrator > 0):
            old_value = 255
            print 1
        else:
            old_value = 0
            print 0
        