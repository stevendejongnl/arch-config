# Hardware — arch-workstation (ASUS ROG Strix X570-E Gaming build)

Desktop workstation, currently the active host (`config.yaml`). Inspected 2026-09-05.

| Component | Spec |
|---|---|
| **Motherboard** | ASUSTeK ROG STRIX X570-E GAMING, rev X.0x |
| **BIOS** | American Megatrends Inc., version 4021 (2021-08-09) |
| **Firmware** | UEFI, GPT partition table |
| **CPU** | AMD Ryzen 7 5800X — 8 cores / 16 threads, up to 3.8GHz |
| **RAM** | 32GB total. Exact module speed/manufacturer needs `sudo dmidecode -t memory` (not run here — no passwordless sudo in this session). |
| **GPU** | AMD Radeon RX 6600/6600 XT (Navi 23), 8GB VRAM — `amdgpu` in-kernel driver, no extra setup needed |
| **Display** | Dual monitor: DP-3 and HDMI-1, both 1920×1080 |
| **Network** | Intel Wi-Fi 6 AX200 (`iwlwifi`, in-kernel) · Realtek RTL8125 2.5GbE (`r8169`, in-kernel) · Intel I211 Gigabit (`igb`, in-kernel) — all three NICs work out of the box, no DKMS/AUR driver needed |
| **Boot disk** | Samsung SSD 970 EVO Plus 1TB (`nvme1n1`) — EFI + ext4 root, this is the active Arch install |

## Other drives present (not the Arch install)

This machine has several other disks attached, left over from previous builds/OS installs — worth knowing about so they aren't mistaken for install targets:

- `nvme0n1` — Samsung SSD 970 EVO Plus 500GB, NTFS partitions (Windows dual-boot)
- `sdd` — Samsung SSD 860 EVO 500GB, has a `bazzite-deck_archworkstation` btrfs partition (another OS install)
- `sdc` — Hitachi HTS727550A9E364 500GB HDD, has an old EFI + ext4 Linux install
- `sda` — Seagate ST500LT012 500GB HDD, NTFS
- `sdb` — Samsung HD154UI 1.4TB HDD, NTFS, labeled "HDD 1.5 TB" (bulk storage)
- `sde` — WDC WD3200BEVT 320GB, currently holds a Ventoy multiboot USB (likely an external/USB drive, not internal storage)

## Known gotchas for this specific machine

1. **No RAID/AHCI concern** — root is a plain NVMe GPT install already in AHCI/NVMe mode, unlike vivobook.
2. **Multiple bootable disks** — be careful which disk `bootctl`/GRUB targets during any reinstall; several drives here have their own EFI partitions from other OS installs.
3. **Network has three interfaces** — `enp6s0` (RTL8125 2.5GbE) was up/carrier-present at inspection time; `enp7s0` (Intel I211) and `wlp5s0` (AX200 Wi-Fi) were down. All drivers are in-kernel, so no AUR packages required regardless of which is used.
