import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { DEFAULT_SETTINGS, SCRIPTS, jsonPoll, script, type Settings } from "../lib"

const settings = jsonPoll<Settings>(
    DEFAULT_SETTINGS,
    500,
    `"${SCRIPTS}/get-user-settings.py"`,
)

function Row({
    name,
    value,
    min,
    max,
    current,
    key,
}: {
    name: string
    value: ReturnType<typeof settings>
    min: number
    max: number
    current: (s: Settings) => number
    key: string
}) {
    return (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4} hexpand>
            <box hexpand>
                <label cssClasses={["settings-name"]} hexpand halign={Gtk.Align.START} label={name} />
                <label cssClasses={["settings-value"]} halign={Gtk.Align.END} label={value} />
            </box>
            <slider
                cssClasses={["settings-scale"]}
                hexpand
                min={min}
                max={max}
                step={1}
                value={settings(current)}
                onChangeValue={(_self, _scroll, v) => {
                    script("set-user-setting.py", key, String(Math.round(v)))
                    return false
                }}
            />
        </box>
    )
}

export function Settings() {
    const mon = app.get_monitors()[0]
    const geo = mon?.get_geometry()
    const height = 520
    const width = 420
    const marginTop = Math.max(0, Math.round(((geo?.height ?? 1200) - height) / 2))
    const marginLeft = Math.max(0, Math.round(((geo?.width ?? 1920) - width) / 2))

    return (
        <window
            name="settings"
            namespace="ags"
            application={app}
            visible={false}
            exclusivity={Astal.Exclusivity.IGNORE}
            layer={Astal.Layer.OVERLAY}
            keymode={Astal.Keymode.NONE}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT}
            marginTop={marginTop}
            marginLeft={marginLeft}
            widthRequest={width}
        >
            <box
                cssClasses={["settings-panel"]}
                orientation={Gtk.Orientation.VERTICAL}
                spacing={12}
            >
                <label cssClasses={["settings-title"]} halign={Gtk.Align.START} label="Settings" />
                <label
                    cssClasses={["settings-hint"]}
                    halign={Gtk.Align.START}
                    label="Saved automatically. Super+H closes."
                />
                <Row
                    name="Cursor sensitivity"
                    value={settings((s) => s.sensitivity_label)}
                    min={0}
                    max={200}
                    current={(s) => s.sensitivity_i}
                    key="sensitivity_i"
                />
                <Row
                    name="Touchpad scroll"
                    value={settings((s) => s.scroll_label)}
                    min={0}
                    max={100}
                    current={(s) => s.scroll_i}
                    key="scroll_i"
                />
                <Row
                    name="Inner gaps"
                    value={settings((s) => `${s.gaps_in}px`)}
                    min={0}
                    max={40}
                    current={(s) => s.gaps_in}
                    key="gaps_in"
                />
                <Row
                    name="Outer gaps"
                    value={settings((s) => `${s.gaps_out}px`)}
                    min={0}
                    max={48}
                    current={(s) => s.gaps_out}
                    key="gaps_out"
                />
                <Row
                    name="Rounding"
                    value={settings((s) => `${s.rounding}px`)}
                    min={0}
                    max={28}
                    current={(s) => s.rounding}
                    key="rounding"
                />
                <Row
                    name="Inactive opacity"
                    value={settings((s) => s.opacity_label)}
                    min={40}
                    max={100}
                    current={(s) => s.opacity_i}
                    key="opacity_i"
                />
                <box homogeneous spacing={8}>
                    <button
                        cssClasses={["settings-toggle"]}
                        tooltipText="Pointer acceleration"
                        onClicked={() => script("set-user-setting.py", "accel_profile", "toggle")}
                    >
                        <label label={settings((s) => `Accel  ${s.accel_label}`)} />
                    </button>
                    <button
                        cssClasses={["settings-toggle"]}
                        tooltipText="Window animations"
                        onClicked={() => script("set-user-setting.py", "animations", "toggle")}
                    >
                        <label label={settings((s) => `Anim  ${s.animations_label}`)} />
                    </button>
                </box>
            </box>
        </window>
    )
}
