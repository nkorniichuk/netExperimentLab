#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

scenario=${1:?Usage: bash run.sh baseline|delay|loss}
case "$scenario" in
  baseline) capability=() ;;
  delay|loss) capability=(--cap-add NET_ADMIN) ;;
  *) echo "Unknown scenario: $scenario" >&2; exit 2 ;;
esac

image=${SRT_LAB_IMAGE:-srt-lab:1.5.4}
if [ ! -s input/payload.bin ]; then
  echo 'Create input/payload.bin first; see LAB.md.' >&2
  exit 1
fi

mkdir -p runs
run=$(mktemp -d "$PWD/runs/$scenario.XXXXXX")
mkdir "$run/output" "$run/metrics"

suffix=${run##*.}
network="srt-lab-$suffix"
receiver="srt-receiver-$suffix"
sender="srt-sender-$suffix"
network_created=false
receiver_created=false
sender_started=false

cleanup() {
  if "$sender_started"; then docker rm -f "$sender" >/dev/null 2>&1 || true; fi
  if "$receiver_created"; then docker rm -f "$receiver" >/dev/null 2>&1 || true; fi
  if "$network_created"; then docker network rm "$network" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf 'Run files: %s\n' "$run"
# TODO: створи внутрішню bridge-мережу "$network".
echo 'Implement network creation in run.sh' >&2
exit 2
network_created=true

# TODO: запусти приймач у фоновому режимі.
echo 'Implement receiver startup in run.sh' >&2
exit 2
receiver_created=true

ready=false
for attempt in {1..40}; do
  if docker exec "$receiver" sh -c 'ss -H -lun "sport = :9000" | grep -q .' 2>/dev/null; then
    ready=true
    break
  fi
  sleep 0.25
done
if ! "$ready"; then
  docker logs "$receiver" >&2
  echo 'Receiver did not bind UDP port 9000.' >&2
  exit 1
fi

sender_started=true
if ! (
  # TODO: запусти відправник з аргументами Docker нижче, монтуваннями й командою контейнера.
  # ${capability[@]+"${capability[@]}"}
  echo 'Implement sender startup in run.sh' >&2
  exit 2
) > "$run/sender.log" 2>&1; then
  cat "$run/sender.log" >&2
  docker logs "$receiver" > "$run/receiver.log" 2>&1 || true
  exit 1
fi

receiver_status=$(docker wait "$receiver")
docker logs "$receiver" > "$run/receiver.log" 2>&1
if [ "$receiver_status" != 0 ]; then
  cat "$run/receiver.log" >&2
  exit 1
fi
bash verify.sh input/payload.bin "$run/output/payload.bin" | tee "$run/hashes.txt"
cat "$run/metrics/result.csv"
if [ -f "$run/metrics/netem.txt" ]; then cat "$run/metrics/netem.txt"; fi
