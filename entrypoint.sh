#!/bin/sh
# If command is the fancontrol binary, run it as-is (readme-format override).
# Otherwise build args from env (same parameter names as README).
set -e
trap 'echo "entrypoint: exiting with code $?" >&2' EXIT

echo "entrypoint: starting" >&2

if [ "$1" = "./fancontrol" ] || [ "$1" = "fancontrol" ]; then
  echo "entrypoint: running fancontrol (command override)" >&2
  exec stdbuf -oL -eL "$@"
fi

echo "entrypoint: running fancontrol (env)" >&2
exec stdbuf -oL -eL ./fancontrol \
  --drive_list="${DRIVE_LIST:?DRIVE_LIST is required, e.g. sda,sdb,sdc,sdd}" \
  --debug="${DEBUG:-0}" \
  --setpoint="${SETPOINT:-37}" \
  --pwminit="${PWMINIT:-128}" \
  --interval="${INTERVAL:-10}" \
  --overheat="${OVERHEAT:-45}" \
  --pwmmin="${PWMMIN:-80}" \
  --kp="${KP:-50.0}" \
  --ki="${KI:-0.5}" \
  --imax="${IMAX:-255.0}" \
  --kd="${KD:-0.0}" \
  --cpu_avg="${CPU_AVG:-10}" \
  ${GRAPHITE_SERVER:+--graphite_server="${GRAPHITE_SERVER}"} \
  "$@"