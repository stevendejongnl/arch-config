"""The colour of the PC case, one "#RRGGBB" line in ~/.config/case-color. The file belongs to this machine and is not
in the dotfiles. dwm reads it every second to colour the dot in the bar. The case lights (board LEDs and the two addressable
headers) get the same colour through OpenRGB, the Redragon mouse through its own HID reports. No GTK here, the status bar
scripts import it too.

  case_color.py apply   set the lights to the saved colour (autostart runs this, the lights forget it at power off)
"""
import fcntl
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

COLOR_FILE = Path.home() / ".config" / "case-color"
DEFAULT_COLOR = "#7A7F99"
HEX_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}$")


def read_case_color():
    try:
        text = COLOR_FILE.read_text().strip()
    except OSError:
        return DEFAULT_COLOR
    return text if HEX_COLOR.match(text) else DEFAULT_COLOR


def write_case_color(hexcolor):
    if not HEX_COLOR.match(hexcolor):
        raise ValueError(f"not a #RRGGBB colour: {hexcolor!r}")
    COLOR_FILE.parent.mkdir(parents=True, exist_ok=True)
    COLOR_FILE.write_text(hexcolor.upper() + "\n")


RING_LEDS = 60  # OpenRGB lists the addressable headers with 0 LEDs; more than the rings have is harmless
BOARD = "ASUS ROG STRIX"


def lighting_command(hexcolor):
    """One OpenRGB call: the board (found by name, the device number can change) with its two addressable headers
    (zones 1 and 2) sized and set in Direct mode. OpenRGB cannot drive the mouse, see apply_mouse().
    OpenRGB.json has only the 'ASUS Aura Motherboard' detector on: the full detection takes 8 seconds."""
    color = hexcolor.lstrip("#")
    ring = [str(RING_LEDS)]
    return ["openrgb", "--noautoconnect",
            "--device", BOARD, "--zone", "1", "--size", *ring, "--zone", "2", "--size", *ring,
            "--mode", "Direct", "--color", color]


MOUSE_VENDOR, MOUSE_PRODUCT, MOUSE_INTERFACE = "04d9", "fc38", "02"  # Redragon M602-RGB "Griffin", the interface with the light reports
HID_SET_FEATURE_16 = 0xC0104806  # HIDIOCSFEATURE for a 16 byte report
MOUSE_BRIGHTNESS = 2  # 0 to 2
LIGHT_BLOCKS = ["02f3510407000000ff00000204000200", "02f3590407000000ff00000204000200",
                "02f3610407000000ff00000204000200", "02f3690407000000ff00000204000200"]  # the other light entries, as the Windows software sends them


def mouse_device_path():
    """The /dev/hidraw node of the light interface of the mouse, None when the mouse is not connected."""
    for node in sorted(Path("/sys/class/hidraw").glob("hidraw*")):
        parent = (node / "device").resolve()
        interface = (parent.parent / "bInterfaceNumber")
        if not interface.exists() or interface.read_text().strip() != MOUSE_INTERFACE:
            continue
        if (parent.parent.parent / "idVendor").read_text().strip() == MOUSE_VENDOR \
                and (parent.parent.parent / "idProduct").read_text().strip() == MOUSE_PRODUCT:
            return Path("/dev") / node.name
    return None


def mouse_reports(hexcolor):
    """The reports of one apply of the Windows software, found by capturing its USB traffic: begin, the light block
    (red, green, blue, 01 = full lighted, speed 0, 02 = full lighted, brightness), the other light blocks, commit, sync."""
    red, green, blue = (int(hexcolor[i:i + 2], 16) for i in (1, 3, 5))
    light = bytes([0x02, 0xf3, 0x49, 0x04, 0x07, 0, 0, 0, red, green, blue, 0x01, 0x00, 0x02, MOUSE_BRIGHTNESS, 0])
    begin, commit, sync = "02f34604020000000000000000000000", "02f10204000000000000000000000000", "02f32c00020000000000000000000000"
    return [bytes.fromhex(begin), light, *map(bytes.fromhex, LIGHT_BLOCKS), bytes.fromhex(commit), bytes.fromhex(sync)]


def apply_mouse(hexcolor):
    """Set the mouse light to a static colour. False when the mouse is missing or refuses the reports."""
    path = mouse_device_path()
    if path is None:
        return False
    try:
        with open(path, "wb", buffering=0) as device:
            for report in mouse_reports(hexcolor):
                fcntl.ioctl(device, HID_SET_FEATURE_16, bytearray(report))
                time.sleep(0.05)
    except OSError:
        return False
    return True


def lights_present():
    """True on a machine with case lights: the ASUS board or the mouse. The bar uses the same script."""
    script = Path(__file__).resolve().parent.parent / "case-lights.sh"
    return subprocess.run([str(script)], capture_output=True).returncode == 0


def apply_case(hexcolor):
    if not shutil.which("openrgb"):
        return False
    return subprocess.run(lighting_command(hexcolor), capture_output=True, timeout=60).returncode == 0


def apply_lighting(hexcolor):
    """Set the case lights and the mouse to the colour. True when both worked."""
    case_done = apply_case(hexcolor)
    mouse_done = apply_mouse(hexcolor)
    return case_done and mouse_done


if __name__ == "__main__":
    if sys.argv[1:] == ["apply"] and not lights_present():
        sys.exit(0)  # nothing to light on this machine
    if sys.argv[1:] == ["apply"]:
        sys.exit(0 if apply_lighting(read_case_color()) else 1)
    sys.exit(__doc__)
