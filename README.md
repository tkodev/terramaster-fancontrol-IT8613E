# TerraMaster fan control (IT8613E)

User-space fan control for TerraMaster NAS with the IT8613E Super I/O chipset (e.g. F4-424). Uses a PID loop driven by drive and CPU temperatures; optionally reports metrics to Graphite for Grafana.

**Tested:** TrueNAS Scale 25.04, TerraMaster F4-424 Max.

### Origin and credits

This project builds on the following work (chronological order):

| Who | Contribution |
|-----|--------------|
| **Eudean** | Original Xpenology fancontrol script for TerraMaster F4-220 (IT8772E chipset). [Forum post](https://xpenology.com/forum/topic/14007-terramaster-f4-220-fan-control/?ct=1559481439) |
| **@Nikotine1** | Port to IT8613E and adaptations for F4-424 Pro: drive list argument (no `/opt/disks`), Graphite reporting, PID controller. Tested on OMV/Debian and TrueNAS 24.10.1. [Nikotine1/terramaster-fancontrol-IT8613E](https://github.com/Nikotine1/terramaster-fancontrol-IT8613E) |
| **@rcarmo** | Tested for F4-424 Max on Proxmox VE 9. [rcarmo/terramaster-fancontrol-IT8613E](https://github.com/rcarmo/terramaster-fancontrol-IT8613E) |
| **@sbogomolov** | Various fixes on **@Nikotine1**'s repo [#1](https://github.com/Nikotine1/terramaster-fancontrol-IT8613E/pull/1) [#2](https://github.com/Nikotine1/terramaster-fancontrol-IT8613E/pull/2) [#3](https://github.com/Nikotine1/terramaster-fancontrol-IT8613E/pull/3) [#4](https://github.com/Nikotine1/terramaster-fancontrol-IT8613E/pull/4) |
| **@tkodev** | Dockerfile: Docker Build, `entrypoint.sh` (env-to-CLI mapping, loggin to stdout), and `compose.yaml` (running). Tested for F4-424 Max on TrueNAS 25.04.2.6 |

---

## Prerequisites

- **Docker** (for Compose) or **GCC** (for manual build).
- **Privileged** access and `/dev` for hardware I/O.
- On TrueNAS Scale 25.04, place the project on a data pool (not the root dataset or user directory); [home is not executable](https://forums.truenas.com/t/shell-script-permission-denied-with-24-10-1/27941) for scripts.

---

## Docker Compose (recommended)

1. **Copy** the compose.yaml into a path on your data pool (e.g. `/mnt/pool/apps/terramaster-fancontrol-IT8613E`).

2. **Configure** `compose.yaml`:
   - Set `DRIVE_LIST` to your comma-separated drive names (e.g. `sda,sdb,sdc,sdd`).
   - Uncomment and set any optional env vars (`SETPOINT`, `DEBUG`, `INTERVAL`, `GRAPHITE_SERVER`, etc.) as needed.
   - Create the external network if you keep the default, or change/remove `networks` in the file:
     ```bash
     docker network create proxy-network
     ```

3. **Build and run:**
   ```bash
   docker compose up -d
   ```

4. **Logs / stop:**
   ```bash
   docker compose logs -f fancontrol
   docker compose down
   ```

The container runs with `privileged: true` and mounts `/dev` read-only so the binary can access the IT8613E hardware.

If you wish to build locally with docker instead (development)

1. **Clone** the repo into a path on your data pool (e.g. `/mnt/pool/apps/terramaster-fancontrol-IT8613E`).
2. **Edit** the `compose.yaml` file, replace the `build` property block (3 lines ~) with `build: .`
3. Follow steps 2-4 above

---

## Manual build and execution

If you prefer not to use Docker for the running process, build the binary and run it (or use the systemd unit) on the host.

### Build

Using a GCC image (no local toolchain required):

```bash
docker run --rm -v "$PWD":/build -w /build gcc:latest gcc -o fancontrol fancontrol.cpp
```

### Run once

```bash
sudo ./fancontrol --drive_list="sda,sdb,sdc,sdd" --setpoint=37
```

Example with debug and optional Graphite:

```bash
sudo ./fancontrol --drive_list="sda,sdb,sdc,sdd" --debug=1 --setpoint=37 --graphite_server=192.168.1.1:2003
```

### Run as a service

Use the included systemd unit:

1. Copy `fancontrol.service` to `/etc/systemd/system/`.
2. Edit the unit: set the path to the `fancontrol` binary and the `--drive_list=...` (and any other) arguments.
3. Start and enable:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now fancontrol.service
   ```
4. After TrueNAS updates, reinstall or re-enable the unit as needed; `install_service.sh` can automate this.

---

## Parameters

| Parameter         | Env var (Compose) | Description |
|-------------------|-------------------|-------------|
| `--drive_list=`   | `DRIVE_LIST`      | Comma-separated drive names (e.g. `sda,sdb,sdc`). **Required.** |
| `--debug=`        | `DEBUG`           | `1` = debug logs, `0` = quiet (default: `0`). |
| `--setpoint=`     | `SETPOINT`        | Target max drive temp °C (default: `37`). |
| `--pwminit=`      | `PWMINIT`         | Initial PWM 0–255 (default: `128`). |
| `--interval=`     | `INTERVAL`        | Poll interval in seconds (default: `10`). |
| `--overheat=`     | `OVERHEAT`        | °C above which fans run at 100% (default: `45`). |
| `--pwmmin=`       | `PWMMIN`          | Minimum PWM; never go below (default: `80`). |
| `--kp=`           | `KP`              | Proportional gain (default: `50.0`). |
| `--ki=`           | `KI`              | Integral gain (default: `0.5`). |
| `--imax=`         | `IMAX`            | Integral clamp (default: `255.0`). |
| `--kd=`           | `KD`              | Derivative gain (default: `0.0`). |
| `--cpu_avg=`      | `CPU_AVG`         | CPU temp rolling average sample count (default: `10`). |
| `--graphite_server=` | `GRAPHITE_SERVER` | Optional; `<ip>:<port>` for Graphite (e.g. Grafana). |

CLI usage:

```text
fancontrol --drive_list=<list> [--debug=0|1] [--setpoint=<n>] [--pwminit=<n>] ...
```

When using Docker Compose, the entrypoint maps these env vars to the same CLI options; see `compose.yaml` and `entrypoint.sh`.

---

## License

MIT. See [LICENSE](LICENSE).
