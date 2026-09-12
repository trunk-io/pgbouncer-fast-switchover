#!/bin/sh
# Kubernetes runs this hook before it sends SIGTERM to the container.

# Wait for the endpoint controllers to drop this pod from the Service. Until
# that propagates the clients still reach this pod, thus pgbouncer must keep
# accepting them.
sleep 15

PID="$(cat /home/pgbouncer/pgbouncer.pid)"

# SIGINT is the pgbouncer safe shutdown: stop the listener, release the server
# connections, let the in-flight transactions finish, then exit. Signal through
# the pidfile and not PID 1, because PID 1 is the start.sh wrapper shell.
kill -s INT "$PID"

# Wait for the drain to finish. Poll instead of a flat sleep, so the hook
# returns as soon as pgbouncer exits. start.sh stays alive for a few seconds
# after pgbouncer exits, thus the container does not stop below this loop.
# 15s + 50s stays below the pod terminationGracePeriodSeconds (75s).
i=0
while [ "$i" -lt 50 ] && kill -0 "$PID" 2>/dev/null; do
  i=$((i + 1))
  sleep 1
done
