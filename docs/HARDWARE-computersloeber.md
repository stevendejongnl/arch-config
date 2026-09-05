# Hardware — computersloeber (Lenovo ThinkPad E15 Gen 3)

Personal laptop, dual-boot Arch Linux + Windows. Inspected 2026-09-05.

| Component | Spec |
|---|---|
| **Model** | Lenovo ThinkPad E15 Gen 3 (20YG, LENOVO_MT_20YG_BU_Think_FM) |
| **BIOS** | Lenovo, version R1OET46W (1.25), date 2026-02-11 |
| **Firmware** | UEFI |
| **CPU** | AMD Ryzen 7 5700U with Radeon Graphics — 8 cores / 16 threads (SMT), up to 1.8GHz reported max |
| **RAM** | 24GB — 16GB + 8GB DDR4 @ 3200MHz (dual-channel, mismatched sticks: one unknown-manufacturer, one Hynix). Only one slot has headroom to grow without replacing a stick |
| **Storage** | Two NVMe drives. `nvme0n1` (476.9GB, Toshiba KBG40ZNT512G) is the active Arch install: `/efi` (vfat) + `/boot` (ext4) + LUKS-encrypted `crypto_LUKS` partition holding an LVM volume group (`vg0-swap` 32G, `vg0-root` 444.3G ext4 root). `nvme1n1` (238.5GB, Samsung MZVLB256HBHQ-000H1) holds Windows (NTFS partitions) plus an ext4 data partition mounted at `/mnt/data` |
| **GPU** | AMD Radeon Graphics (Lucienne, integrated in the 5700U) — `amdgpu` in-kernel driver, no extra setup needed |
| **Display** | Internal panel `eDP-1`, 1920×1080 (344mm x 194mm) |
| **WiFi** | MediaTek MT7921 802.11ax PCIe (Filogic 330) — `mt7921e`, in-kernel driver, no DKMS/AUR needed |
| **Ethernet** | Onboard NIC present (`enp2s0`), no carrier at inspection time |
| **Battery** | Sunwoda 5B11C732, design capacity 57Wh, full-charge capacity 49.47Wh (~87% health), 510 charge cycles. Charge thresholds already configured in firmware/OS (75%–80% start/end) |

## Known gotchas for this specific machine

1. **Encrypted root**: unlike vivobook/arch-workstation, root here is LUKS + LVM (`cryptroot` -> `vg0-root`/`vg0-swap`), not a plain partition — any recovery/rescue work needs the LUKS passphrase and `cryptsetup`/`lvm` tooling, not just a bare mount.
2. **Second NVMe is Windows + shared data**: `nvme1n1` carries the Windows dual-boot install and an ext4 partition mounted at `/mnt/data` — don't target it during any Arch reinstall/repartition.
3. **WiFi and GPU are both fully in-kernel** (`mt7921e`, `amdgpu`) — no AUR/DKMS packages required for this machine, unlike vivobook's RTL8821CE.
4. **High charge-cycle count (510)** relative to battery age — health is still good (~87%) but worth monitoring; charge thresholds (75/80%) are already active.
