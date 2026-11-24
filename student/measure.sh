#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

scenario=${1:?Expected baseline, delay or loss}
destination=${2:?Expected receiver hostname}
input=/input/payload.bin
metrics=/metrics

case "$scenario" in
  baseline) ;;
  delay)
    # TODO: додай 40 мс до вихідних пакетів на eth0.
    echo "Implement delay in measure.sh" >&2; exit 2
    ;;
  loss)
    # TODO: додай випадкову втрату 1% на eth0.
    echo "Implement loss in measure.sh" >&2; exit 2
    ;;
  *) echo "Unknown scenario: $scenario" >&2; exit 2 ;;
esac

/usr/bin/time -f '%e' -o "$metrics/seconds.txt" \
  timeout -k 3s 60s srt-file-transmit \
  -s 200 -pf csv -f -statsout "$metrics/srt.csv" \
  "file://$input" "srt://$destination:9000?mode=caller"

if [ "$scenario" != baseline ]; then
  tc -s qdisc show dev eth0 > "$metrics/netem.txt"
fi

bytes=$(wc -c < "$input")
seconds=$(cat "$metrics/seconds.txt")
mbps=$(awk -v bytes="$bytes" -v seconds="$seconds" 'BEGIN {
    if (seconds <= 0) exit 1
    # TODO: обчисли Мбіт/с та виведи число з трьома десятковими знаками.
    exit 2
}')
printf 'scenario,bytes,seconds,mbps\n%s,%d,%s,%s\n' \
  "$scenario" "$bytes" "$seconds" "$mbps" > "$metrics/result.csv"
