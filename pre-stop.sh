#!/bin/sh
# SIGINT triggers pgbouncer's "safe shutdown": stop accepting new connections,
# let in-flight transactions finish, then exit. Signal pgbouncer via its pidfile
# rather than PID 1 — PID 1 is the start.sh bash wrapper, not pgbouncer.
kill -s INT "$(cat /home/pgbouncer/pgbouncer.pid)"
# Hold the container open while pgbouncer drains. Stays within the pod's
# terminationGracePeriodSeconds (75s).
sleep 60
