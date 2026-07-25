# Frigate NVR

Local recording for the nursery camera. Nothing leaves the house.

## What it does here

- **Continuous recording** with a scrub-back timeline (default: last 1 day)
- **Cry detection** via audio classification, raising an event Home Assistant can alert on
- **Clip export** — mark a section of the timeline and save it permanently
- **Live view**, also surfaced inside Home Assistant

Object detection is deliberately disabled — see `config/config.yml`.

## Setup

```sh
cd ~/code/dotfiles/services/frigate
cp .env.example .env
$EDITOR .env          # camera IP, username, password
docker compose up -d
docker compose logs -f
```

UI at `http://<host>:5000`.

## Everyday commands

| Task | Command |
|---|---|
| Logs | `docker compose logs -f` |
| Restart after a config change | `docker compose restart` |
| Update | `docker compose pull && docker compose up -d` |
| Disk used by recordings | `du -sh media/` |

## Tuning cry detection

`config/config.yml` → `cameras.nursery.audio.filters.crying.threshold`.

Lower catches more but false-alarms on similar sounds; higher is quieter but
can miss a soft cry. Tune it against real recordings rather than guessing —
Frigate logs every audio detection with its score, so watch the log overnight
and pick a number that sits below the real cries and above the noise:

```sh
docker compose logs -f | grep -i audio
```

`min_volume` (RMS) gates whether the model runs at all. Raise it if a quiet
room keeps triggering; lower it if cries from across the room are missed.

## Retention and disk

`record.continuous.days` accepts decimals: `0.042` ≈ 1 hour, `1` = a day,
`7` = a week. Roughly 10–20GB per day for one 1080p camera.

Detected events are kept separately for 14 days, so a cry stays available after
the continuous buffer has rolled past it.

Check headroom before increasing:

```sh
df -h /
du -sh media/
```

## Hardware decode

The compose file passes `/dev/dri/renderD128` — the **Intel** iGPU. On a box
with two GPUs, `renderD129` is the discrete card; on this machine that is an
NVIDIA Kepler card with no usable driver, so passing the wrong node gets you
software decoding and a busy CPU with no obvious error.

Confirm the mapping on any new machine:

```sh
for n in /dev/dri/renderD*; do
  echo "$n -> $(lspci -s "$(basename "$(readlink -f /sys/class/drm/$(basename $n)/device)")")"
done
```

## Not a safety device

Audio classification is best-effort. It misses sounds, fires on false ones, and
depends on the camera's microphone, room acoustics and distance. Treat it as a
convenience that saves you checking the app, never as the thing keeping a child
safe.
