#!/bin/sh
# SIGINT is pgbouncer's "safe shutdown": stop accepting new connections, let the
# in-flight transactions finish, then exit. Signal pgbouncer through its pidfile
# and not PID 1, because PID 1 is the start.sh wrapper shell.
kill -s INT "$(cat /home/pgbouncer/pgbouncer.pid)"
# Hold the container open while pgbouncer drains. Keep this below the pod
# terminationGracePeriodSeconds (75s) set in postgres.ts.
sleep 60
