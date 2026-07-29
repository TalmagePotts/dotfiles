# Matter Hub

Publishes Home Assistant entities as a **Matter bridge**, so Alexa and Google
Home can control them locally — no subscription, nothing exposed to the
internet.

Siri is not served from here. Apple Home comes from HA's own HomeKit bridges in
`../homeassistant/config/configuration.yaml`.

## Why Matter rather than the alternatives

| Route | Cost | Exposure | Capability |
|---|---|---|---|
| Nabu Casa | $7.50/mo | none | full |
| AWS Lambda + custom skill | free | **HA public on the internet** | full |
| Emulated Hue | free | none | on/off + brightness only |
| **Matter Hub** | free | none | full — colour, sensors, both ecosystems |

Emulated Hue was the other free option, and it only reaches Alexa, only as
Hue bulbs. This covers Google Home too and keeps colour.

## Prerequisites

- A **Matter controller** on the LAN. Confirmed working here: the onn 4K Pro
  (2026), which is a full Matter hub. The 2024 model of the same box is **not** —
  check `Settings -> System -> About` on the device if unsure.
- IPv6 on the LAN. Matter is IPv6-first; commissioning fails without it.
  Check with `ip -6 addr show <iface>`.
- Controllers must sit in the **same network segment** as this container. A
  guest network or VLAN will break discovery.

## Setup

### 1. Create the access token

In Home Assistant:

1. Click your **user avatar** (bottom left)
2. **Security** tab
3. Scroll to **Long-lived access tokens** → **Create token**
4. Name it `matter-hub`
5. Copy it — HA shows it **once**

### 2. Write it to `.env`

`.env` is untracked (gitignored) because it holds a credential:

```sh
cd services/matterhub
printf 'HAMH_HOME_ASSISTANT_ACCESS_TOKEN=%s\n' 'PASTE_TOKEN_HERE' > .env
```

### 3. Start it

```sh
docker compose up -d
docker compose logs -f
```

### 4. Create a bridge

Open <http://vigil:8482>, create a bridge, and filter which entities it
publishes.

**Filter deliberately.** Publishing everything floods Alexa and Google with
camera config switches and Echo entities that mean nothing there — the same
mistake made with the HomeKit bridges before they were filtered. Lights and
plugs are usually all you want.

### 5. Commission it

Each bridge shows a **pairing code / QR**. Add it in the Alexa app or Google
Home app as a Matter device.

A bridge can be commissioned into **multiple** ecosystems — unlike HomeKit,
where an accessory belongs to exactly one Home. Alexa and Google Home can share
one bridge.

## Gotchas

- **`network_mode: host` is required.** Matter needs IPv6 multicast and mDNS,
  neither of which crosses Docker's bridge NAT. On a bridge network it starts
  fine and is simply never discoverable.
- **`data/` is the fabric state** — the bridge identity and every controller
  pairing. Lose it and you re-commission everywhere. Back it up.
- **This is a community fork.** The original project was discontinued in
  January 2026. Nothing critical depends on it: the baby monitor, recording and
  cry detection are entirely separate.
