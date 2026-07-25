# Home Assistant

Runs on vigil as a Docker container. Config lives in `./config` beside the
compose file — that directory *is* the instance, so it is the thing to back up.

## Deploy

```sh
cd ~/code/dotfiles/services/homeassistant
docker compose up -d
```

First start takes a few minutes: it unpacks, builds its database, then listens
on **port 8123**.

## Everyday commands

| Task | Command |
|---|---|
| Watch logs | `docker compose logs -f` |
| Restart | `docker compose restart` |
| Update to latest | `docker compose pull && docker compose up -d` |
| Stop | `docker compose down` |
| Shell inside | `docker exec -it homeassistant bash` |

Run all of these from this directory.

## Why host networking

Home Assistant discovers smart plugs, cameras and most other devices with
mDNS/zeroconf, SSDP and DHCP sniffing. All three depend on broadcast and
multicast traffic, which does not cross Docker's default bridge NAT. On a
bridge network HA starts up perfectly and then never finds a single device —
which reads as broken devices rather than a networking decision.

`network_mode: host` puts HA directly on the LAN, in the same broadcast domain
as the devices. The trade-off is that it binds host port 8123 directly, so the
compose file has no `ports:` section (Compose rejects one in host mode).

## Backups

The whole instance is `./config`. Back it up before upgrades:

```sh
docker compose down
tar czf ~/ha-backup-$(date +%F).tar.gz config/
docker compose up -d
```

Home Assistant also has built-in snapshots under
**Settings → System → Backups**, which is the easier route day to day.

`config/` is gitignored — it holds credentials, device tokens and the state
database, and this repo is public.

## USB dongles (Zigbee / Z-Wave)

`privileged: true` is already set, so a plugged-in dongle is visible. Pass the
specific device through by adding to the compose file:

```yaml
    devices:
      - /dev/serial/by-id/<your-dongle>:/dev/ttyUSB0
```

Use the `by-id` path — `/dev/ttyUSB0` is assigned in enumeration order and
moves between reboots.
