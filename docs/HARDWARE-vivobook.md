# Hardware — vivobook (ASUS VivoBook X712JA)

Personal laptop, dual-boot Arch Linux + Windows 11. Inspected 2026-09-05.

| Component | Spec |
|---|---|
| **Model** | ASUS VivoBook X712JA / S712JA |
| **BIOS** | American Megatrends Inc., version X712JA.303 (2021-01-29) |
| **Firmware** | UEFI, GPT partition table |
| **CPU** | Intel Core i5-1035G1 @ 1.00GHz (Ice Lake, 10th gen) — 4 cores / 8 threads |
| **RAM** | 8GB — 2×4GB dual-channel @ 3200MHz (Micron + SK Hynix). Both slots populated; max supported 32GB, so upgrade requires replacing both sticks. |
| **Storage** | Kingston OM8PCP3512F-AB, 512GB NVMe SSD. Reported over a **RAID bus (Intel RST)** in Windows — switch BIOS SATA mode to **AHCI** before/during Arch install. |
| **GPU** | Intel UHD Graphics (integrated), 1GB shared VRAM reported |
| **Display** | 1600×900 (17.3" panel, non-touch) |
| **WiFi** | Realtek RTL8821CE 802.11ac PCIe (MAC 00:E9:3A:C4:B3:07) — needs `rtl8821ce-dkms` (AUR), not in-kernel. Different chip from the RTL8723BU already handled via `upd72020x-fw` in base.yaml. Use USB WiFi or Ethernet during install. |
| **Battery** | Li-Ion, design capacity 32.08Wh, full-charge capacity 24.82Wh (~77% health), 6 charge cycles. Degradation is age-related (BIOS from 2021), not wear — TLP charge thresholds (`configs/tlp/10-battery-thresholds.conf`) recommended from day one to slow further loss. |

## Known gotchas for this specific machine

1. **RAID vs AHCI**: NVMe disk shows up as a RAID device in Windows (Intel RST), common ASUS default. Needs AHCI mode for a clean Linux install — check this before partitioning.
2. **WiFi driver**: RTL8821CE has no in-kernel driver; `rtl8821ce-dkms` must be built after first boot. Have a wired/USB fallback ready.
3. **RAM headroom**: 8GB is noticeably less than computersloeber (Ryzen 7 5700U, 24GB — 16GB+8GB DDR4-3200) or arch-workstation (Ryzen 7 5800X, 32GB) — the full `base.yaml` package set (Docker, JDK, JetBrains Toolbox, full DWM stack) may feel heavier here. Consider trimming via `exclude` in `hosts/vivobook.yaml`, or upgrading RAM first.
