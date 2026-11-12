"""Case tab: pick the colour of the PC case. The dot in the bar, the case lights and the mouse get it."""
from gi.repository import Gdk, GLib, Gtk

from .case_color import apply_lighting, read_case_color, write_case_color
from .theme import label, margins, run_async

LIGHT_DELAY_MS = 400  # dragging in the picker changes the colour many times a second, OpenRGB needs a moment per call


def to_hex(rgba):
    return "#{:02X}{:02X}{:02X}".format(round(rgba.red * 255), round(rgba.green * 255), round(rgba.blue * 255))


class CasePanel(Gtk.Box):
    name = "case"
    title = "Case"

    def __init__(self):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10, valign=Gtk.Align.START)
        self.visible = False
        self.light_timer = None
        self.chooser = Gtk.ColorChooserWidget()
        self.chooser.set_use_alpha(False)
        self.chooser.set_property("show-editor", True)  # the editor has the hex field
        self.set_chooser_color(read_case_color())
        self.chooser.connect("notify::rgba", self.on_color_changed)

        heading = label("PC CASE COLOUR", "section")
        note = label("The dot in the bar, the case lights and the mouse follow this colour. Type a hex value or drag in the picker.", "muted")
        for child, before in ((heading, 0), (note, 0), (self.chooser, 6)):
            margins(child, before, 0, 4, 4)
            self.pack_start(child, False, False, 0)

    @staticmethod
    def available():
        return True

    def set_chooser_color(self, hexcolor):
        rgba = Gdk.RGBA()
        rgba.parse(hexcolor)
        self.chooser.set_rgba(rgba)

    def on_color_changed(self, *_):
        write_case_color(to_hex(self.chooser.get_rgba()))
        if self.light_timer:
            GLib.source_remove(self.light_timer)
        self.light_timer = GLib.timeout_add(LIGHT_DELAY_MS, self.update_lighting)

    def update_lighting(self):
        self.light_timer = None
        run_async(lambda: apply_lighting(read_case_color()), lambda _done: None)
        return False

    def tick(self, _seconds):
        pass

    def load(self):
        return None

    def hint(self):
        return read_case_color()
