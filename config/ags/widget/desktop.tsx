import Cairo from "cairo"
import GLib from "gi://GLib?version=2.0"
import { Astal, Gtk } from "ags/gtk4"
import { With } from "ags"
import { createPoll } from "ags/time"
import app from "ags/gtk4/app"
import { exec } from "ags/process"
import { SCRIPTS, jsonPoll, numPoll, type Clock, type Weather } from "../lib"

const clock = jsonPoll<Clock>(
    { hms: "--:--", day: "", date: "" },
    1000,
    `"${SCRIPTS}/panel-clock.sh"`,
)
const weather = jsonPoll<Weather>(
    { icon: "☁", temp: "--", temp_c: "--", text: "", city: "" },
    60000,
    `python3 "${SCRIPTS}/panel-weather.py"`,
)
const cpu = numPoll(0, 3000, `"${SCRIPTS}/get-cpu.sh"`)
const memory = numPoll(0, 10000, `"${SCRIPTS}/get-memory.sh"`)
const disk = numPoll(0, 60000, `"${SCRIPTS}/get-disk.sh" /`)
const battery = numPoll(0, 15000, `cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1`)

type DeskDay = { n: number; today: boolean }
type DeskCal = { month: string; weekday: string; days: DeskDay[] }

function buildCalendar(): DeskCal {
    const now = new Date()
    const today = now.getDate()
    const count = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    const days: DeskDay[] = []
    for (let n = 1; n <= count; n++) days.push({ n, today: n === today })
    return {
        month: now.toLocaleString("en-US", { month: "short" }),
        weekday: now.toLocaleString("en-US", { weekday: "short" }),
        days,
    }
}

const deskWindows: Gtk.Window[] = []
let revealing = false

// Hyprland only fades the top layer back in after fullscreen. A bottom
// layer mapped during fullscreen stays at alpha 0, so remap once the
// fullscreen window is gone.
function revealAfterFullscreen() {
    if (revealing) return
    let covered = false
    try {
        covered = /hasfullscreen:\s*1/.test(exec(["hyprctl", "activeworkspace"]))
    } catch (err) {
        printerr(`desk fullscreen: ${err}`)
        return
    }
    if (!covered) return

    revealing = true
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 700, () => {
        try {
            if (/hasfullscreen:\s*1/.test(exec(["hyprctl", "activeworkspace"])))
                return GLib.SOURCE_CONTINUE
        } catch {
            return GLib.SOURCE_CONTINUE
        }
        revealing = false
        for (const win of deskWindows) win.set_visible(false)
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            for (const win of deskWindows) win.set_visible(true)
            return GLib.SOURCE_REMOVE
        })
        return GLib.SOURCE_REMOVE
    })
}

// Super+Ctrl hold. The clock lives under windows; lift it above them
// until either modifier is released.
export function setClockRaised(raised: boolean) {
    const win = app.get_window("desk-clock")
    if (!win) return
    // Layer is applied when the surface maps. Hide, retarget, then show.
    win.set_visible(false)
    win.set_layer(raised ? Astal.Layer.OVERLAY : Astal.Layer.BOTTOM)
    win.set_visible(true)
    if (!raised) revealAfterFullscreen()
}

function passClicks(win: Gtk.Window) {
    const apply = () => {
        const surface = win.get_surface()
        if (!surface) return
        try {
            surface.set_input_region(new Cairo.Region())
        } catch (err) {
            printerr(`desk input: ${err}`)
        }
    }
    win.connect("realize", apply)
    win.connect("map", apply)
}

function shell(name: string, anchor: number, margins: {
    top?: number
    bottom?: number
    left?: number
    right?: number
}) {
    return {
        name,
        namespace: "ags-desk",
        application: app,
        exclusivity: Astal.Exclusivity.IGNORE,
        // Bottom sits above the wallpaper and below application windows.
        layer: Astal.Layer.BOTTOM,
        keymode: Astal.Keymode.NONE,
        anchor,
        marginTop: margins.top ?? 0,
        marginBottom: margins.bottom ?? 0,
        marginLeft: margins.left ?? 0,
        marginRight: margins.right ?? 0,
        visible: false,
        $: (self: Gtk.Window) => {
            self.set_layer(Astal.Layer.BOTTOM)
            passClicks(self)
            deskWindows.push(self)
            self.set_visible(true)
        },
    }
}

export function Desktop() {
    const user = GLib.get_user_name()
    const cal = createPoll(buildCalendar(), 60 * 1000, () => buildCalendar())

    const windows = [
        <window {...shell("desk-cal", Astal.WindowAnchor.LEFT, { left: 28 })}>
            <With value={cal}>
                {(c) => (
                    <box cssClasses={["desk-cal"]} orientation={Gtk.Orientation.VERTICAL} spacing={2} halign={Gtk.Align.START}>
                        {c.days.map((day) => (
                            <box halign={Gtk.Align.START} spacing={8}>
                                <label
                                    cssClasses={day.today ? ["desk-date-num"] : ["desk-day"]}
                                    halign={Gtk.Align.CENTER}
                                    xalign={0.5}
                                    widthRequest={56}
                                    label={String(day.n)}
                                />
                                {day.today && (
                                    <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                                        <label cssClasses={["desk-date-text"]} halign={Gtk.Align.START} xalign={0} label={c.month} />
                                        <label cssClasses={["desk-date-text"]} halign={Gtk.Align.START} xalign={0} label={c.weekday} />
                                    </box>
                                )}
                            </box>
                        ))}
                    </box>
                )}
            </With>
        </window>,
        <window {...shell("desk-clock", Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT, { top: 22, right: 28 })}>
            <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.END} widthRequest={250}>
                <label cssClasses={["desk-user"]} halign={Gtk.Align.END} xalign={1} label={user} />
                <label
                    cssClasses={["desk-clock"]}
                    halign={Gtk.Align.END}
                    xalign={1}
                    label={clock((c) => c.hms.slice(0, 5))}
                />
            </box>
        </window>,
        <window {...shell("desk-info", Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.RIGHT, { bottom: 28, right: 28 })}>
            <box cssClasses={["desk-info"]} halign={Gtk.Align.END}>
                <box spacing={18} halign={Gtk.Align.END}>
                    <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.END}>
                        <label
                            cssClasses={["desk-temp"]}
                            halign={Gtk.Align.END}
                            label={weather((w) => w.temp_c)}
                        />
                        <label
                            cssClasses={["desk-muted"]}
                            halign={Gtk.Align.END}
                            label={weather((w) => w.text)}
                        />
                        <label
                            cssClasses={["desk-muted"]}
                            halign={Gtk.Align.END}
                            label={weather((w) => w.city)}
                        />
                    </box>
                    <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                        <label
                            cssClasses={["desk-stat", "desk-cpu"]}
                            halign={Gtk.Align.START}
                            label={cpu((v) => `CPU: ${v}%`)}
                        />
                        <label
                            cssClasses={["desk-stat", "desk-ram"]}
                            halign={Gtk.Align.START}
                            label={memory((v) => `RAM: ${v}%`)}
                        />
                        <label
                            cssClasses={["desk-stat", "desk-disk"]}
                            halign={Gtk.Align.START}
                            label={disk((v) => `Disk: ${v}%`)}
                        />
                        <label
                            cssClasses={["desk-stat", "desk-battery"]}
                            halign={Gtk.Align.START}
                            label={battery((v) => `Battery: ${v}%`)}
                        />
                    </box>
                </box>
            </box>
        </window>,
    ]
    revealAfterFullscreen()
    return windows
}
