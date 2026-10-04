import { Astal, Gtk } from "ags/gtk4"
import { With } from "ags"
import app from "ags/gtk4/app"
import { IconBtn } from "./icon"
import { Calendar } from "./calendar"
import {
    EMPTY_WORKSPACES,
    HOME,
    SCRIPTS,
    boolPoll,
    follow,
    jsonPoll,
    numPoll,
    run,
    script,
    strPoll,
    type Clock,
    type Uptime,
    type Weather,
    type WorkspaceState,
} from "../lib"

const clock = jsonPoll<Clock>(
    { hms: "--:--:--", day: "", date: "" },
    1000,
    `"${SCRIPTS}/panel-clock.sh"`,
)
const uptime = jsonPoll<Uptime>({ hours: 0, mins: 0 }, 15000, `"${SCRIPTS}/panel-uptime.sh"`)
const weather = jsonPoll<Weather>(
    { icon: "☁", temp: "--", temp_c: "--", text: "", city: "Baltimore" },
    300000,
    `"${SCRIPTS}/panel-weather.py"`,
)
const workspaces = follow(JSON.stringify(EMPTY_WORKSPACES), `"${SCRIPTS}/bar-workspaces.py"`)
const volume = numPoll(
    0,
    1000,
    `pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | sed 's/%//'`,
)
const brightness = numPoll(
    0,
    1000,
    `echo $(( $(brightnessctl get) * 100 / $(brightnessctl max) ))`,
)
const idle = boolPoll(false, 2000, `"${SCRIPTS}/get-hypridle-status.sh"`)
const warm = boolPoll(true, 1000, `"${SCRIPTS}/get-warm-light.sh"`)
const battery = numPoll(0, 3000, `"${SCRIPTS}/get-battery.sh"`)
const timeLeft = strPoll("0", 15000, `"${SCRIPTS}/get-time-left.sh"`)
const memory = numPoll(0, 10000, `"${SCRIPTS}/get-memory.sh"`)
const memoryDetail = strPoll("0", 10000, `"${SCRIPTS}/get-memory-detail.sh"`)
const temp = numPoll(0, 10000, `"${SCRIPTS}/get-temperature.sh"`)
const cpu = numPoll(0, 10000, `"${SCRIPTS}/get-cpu.sh"`)
const disk = numPoll(0, 60000, `"${SCRIPTS}/get-disk.sh"`)
const diskDetail = strPoll("0", 60000, `"${SCRIPTS}/get-disk-detail.sh"`)
const seek = numPoll(0, 1000, `"${SCRIPTS}/get-music-seek.sh"`)
const bluetooth = strPoll("󰂯", 5000, `"${SCRIPTS}/get-bluetooth-status.sh"`)
const wifi = strPoll("󰤨", 5000, `"${SCRIPTS}/get-network-strength.sh"`)
const volumeIcon = strPoll("󰕾", 1000, `"${SCRIPTS}/get-volume-icons.sh"`)
const music = follow("", `playerctl --follow metadata --format '{{ title }}' || true`)
const artist = follow("", `playerctl --follow metadata --format '{{ artist }}' || true`)
const cover = follow("", `playerctl --follow metadata --format '{{mpris:artUrl}}' || true`)
const status = follow("Stopped", `playerctl --follow status || true`)

const FOLDERS: Array<[string, string]> = [
    ["󰈙  Documents", `${HOME}/Documents`],
    ["󰇚  Downloads", `${HOME}/Downloads`],
    ["󰝚  Music", `${HOME}/Music`],
    ["󰈔  Pictures", `${HOME}/Pictures`],
    ["  ~/.config", `${HOME}/.config`],
    ["󰉋  ~/.local", `${HOME}/.local`],
]

function Meter({
    name,
    value,
    unit,
    tooltip,
}: {
    name: string
    value: ReturnType<typeof numPoll>
    unit: string
    tooltip: string | ReturnType<typeof strPoll>
}) {
    return (
        <box
            cssClasses={["meter"]}
            tooltipText={tooltip}
            hexpand
            vexpand
            valign={Gtk.Align.CENTER}
            spacing={10}
        >
            <label cssClasses={["meter-name"]} label={name} />
            <Gtk.ProgressBar
                cssClasses={["meter-bar", `meter-${name}`]}
                hexpand
                fraction={value((v) => Math.max(0, Math.min(1, v / 100)))}
            />
            <label cssClasses={["meter-val"]} label={value((v) => `${v}${unit}`)} />
        </box>
    )
}

export function ControlCenter() {
    return (
        <window
            name="control-center"
            namespace="ags"
            application={app}
            visible={false}
            exclusivity={Astal.Exclusivity.IGNORE}
            layer={Astal.Layer.OVERLAY}
            keymode={Astal.Keymode.NONE}
            anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
            marginTop={12}
            marginRight={12}
            widthRequest={720}
        >
            <box
                cssClasses={["control-center"]}
                orientation={Gtk.Orientation.VERTICAL}
                spacing={10}
            >
                <box spacing={10} hexpand>
                    <box
                        cssClasses={["dash-card", "dash-clock"]}
                        orientation={Gtk.Orientation.VERTICAL}
                        hexpand
                        vexpand
                    >
                        <label
                            cssClasses={["dash-clock-time"]}
                            halign={Gtk.Align.START}
                            label={clock((c) => c.hms)}
                        />
                        <label
                            cssClasses={["dash-clock-day"]}
                            halign={Gtk.Align.START}
                            label={clock((c) => c.day)}
                        />
                        <label
                            cssClasses={["dash-clock-date"]}
                            halign={Gtk.Align.START}
                            label={clock((c) => c.date)}
                        />
                        <box
                            cssClasses={["dash-uptime-inline"]}
                            spacing={8}
                            valign={Gtk.Align.END}
                            vexpand
                        >
                            <label cssClasses={["dash-uptime-icon"]} label="󰔛" />
                            <label
                                cssClasses={["dash-uptime-h"]}
                                label={uptime((u) => `${u.hours}h ${u.mins}m`)}
                            />
                        </box>
                    </box>
                    <button
                        hexpand
                        vexpand
                        tooltipText="Baltimore forecast"
                        onClicked={() => script("open-weather.sh")}
                    >
                        <box
                            cssClasses={["dash-card", "dash-weather"]}
                            orientation={Gtk.Orientation.VERTICAL}
                            hexpand
                            vexpand
                        >
                            <box>
                                <label cssClasses={["dash-weather-icon"]} label={weather((w) => w.icon)} />
                                <label
                                    cssClasses={["dash-weather-temp"]}
                                    hexpand
                                    halign={Gtk.Align.END}
                                    label={weather((w) => w.temp)}
                                />
                            </box>
                            <label
                                cssClasses={["dash-weather-city"]}
                                halign={Gtk.Align.START}
                                label={weather((w) => w.city)}
                            />
                            <label
                                cssClasses={["dash-weather-text"]}
                                halign={Gtk.Align.START}
                                ellipsize={3}
                                label={weather((w) => w.text)}
                            />
                            <label
                                cssClasses={["dash-weather-c"]}
                                halign={Gtk.Align.START}
                                vexpand
                                valign={Gtk.Align.END}
                                label={weather((w) => w.temp_c)}
                            />
                        </box>
                    </button>
                    <box
                        cssClasses={["dash-card", "dash-power"]}
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={8}
                    >
                        <box spacing={8} hexpand vexpand>
                            <IconBtn
                                class="dash-power-btn dash-power-lock"
                                tooltip="Lock"
                                icon=""
                                hexpand
                                vexpand
                                onClicked={() => script("lock.sh")}
                            />
                            <IconBtn
                                class="dash-power-btn dash-power-sleep"
                                tooltip="Sleep"
                                icon="󰒲"
                                hexpand
                                vexpand
                                onClicked={() => run(["systemctl", "suspend"])}
                            />
                        </box>
                        <box spacing={8} hexpand vexpand>
                            <IconBtn
                                class="dash-power-btn dash-power-reboot"
                                tooltip="Reboot"
                                icon="󰜉"
                                hexpand
                                vexpand
                                onClicked={() => run(["systemctl", "reboot"])}
                            />
                            <IconBtn
                                class="dash-power-btn dash-power-off"
                                tooltip="Shut down"
                                icon="󰐥"
                                hexpand
                                vexpand
                                onClicked={() => run(["systemctl", "poweroff"])}
                            />
                        </box>
                    </box>
                </box>

                <With
                    value={workspaces((raw) => {
                        try {
                            return JSON.parse(raw) as WorkspaceState
                        } catch {
                            return EMPTY_WORKSPACES
                        }
                    })}
                >
                    {(state) => (
                        <box
                            cssClasses={["dash-card", "dash-workspaces"]}
                            homogeneous
                            spacing={4}
                            hexpand
                            $={(self) => {
                                const c = new Gtk.EventControllerScroll({
                                    flags: Gtk.EventControllerScrollFlags.VERTICAL,
                                })
                                c.connect("scroll", (_ctrl, _dx, dy) => {
                                    script("bar-workspace.sh", "scroll", dy > 0 ? "down" : "up")
                                    return true
                                })
                                self.add_controller(c)
                            }}
                        >
                            {state.list.map((ws) => (
                                <button
                                    cssClasses={[
                                        "dash-ws",
                                        ws.occupied ? "occupied" : "empty",
                                        state.active === ws.id ? "active" : "",
                                    ].filter(Boolean)}
                                    tooltipText={`Super+${ws.label}`}
                                    hexpand
                                    onClicked={() => script("bar-workspace.sh", String(ws.id))}
                                >
                                    <label
                                        halign={Gtk.Align.CENTER}
                                        valign={Gtk.Align.CENTER}
                                        label={ws.label}
                                    />
                                </button>
                            ))}
                        </box>
                    )}
                </With>

                <box spacing={10} hexpand>
                    <box cssClasses={["dash-mid-col"]} hexpand vexpand>
                        <box
                            cssClasses={["controls"]}
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={10}
                            hexpand
                            vexpand
                            valign={Gtk.Align.CENTER}
                        >
                            <box orientation={Gtk.Orientation.VERTICAL} spacing={8} hexpand>
                                <box cssClasses={["slider-row"]} spacing={10} hexpand valign={Gtk.Align.CENTER}>
                                    <IconBtn
                                        class="slider-icon"
                                        tooltip="Volume"
                                        icon={volumeIcon}
                                        onClicked={() => script("pavucontrol.sh")}
                                    />
                                    <slider
                                        cssClasses={["slider-bar", "volume-control-bar"]}
                                        hexpand
                                        min={0}
                                        max={101}
                                        step={1}
                                        value={volume}
                                        onChangeValue={(_self, _scroll, value) => {
                                            const v = Math.round(value)
                                            run(
                                                `pactl set-sink-volume @DEFAULT_SINK@ ${v}%; "${SCRIPTS}/notify.sh" --throttle volume Volume Volume ${v}%`,
                                            )
                                            return false
                                        }}
                                    />
                                </box>
                                <box cssClasses={["slider-row"]} spacing={10} hexpand valign={Gtk.Align.CENTER}>
                                    <IconBtn class="slider-icon" tooltip="Brightness" icon="󰖨" />
                                    <slider
                                        cssClasses={["slider-bar", "brightness-control-bar"]}
                                        hexpand
                                        min={0}
                                        max={101}
                                        step={1}
                                        value={brightness}
                                        onChangeValue={(_self, _scroll, value) => {
                                            const v = Math.round(value)
                                            run(
                                                `brightnessctl s ${v}%; "${SCRIPTS}/notify.sh" --throttle brightness Brightness Brightness ${v}%`,
                                            )
                                            return false
                                        }}
                                    />
                                </box>
                            </box>
                            <box homogeneous spacing={8} hexpand>
                                <IconBtn
                                    class="quick-tile"
                                    tooltip="Wi-Fi"
                                    icon={wifi}
                                    hexpand
                                    vexpand
                                    onClicked={() => script("wifi-menu.sh")}
                                />
                                <IconBtn
                                    class="quick-tile"
                                    tooltip="Bluetooth"
                                    icon={bluetooth}
                                    hexpand
                                    vexpand
                                    onClicked={() => script("bluetuith.sh")}
                                />
                                <IconBtn
                                    class="quick-tile"
                                    tooltip="Idle lock"
                                    icon={idle((on) => (on ? "" : ""))}
                                    hexpand
                                    vexpand
                                    onClicked={() => script("toggle-idle.sh")}
                                />
                                <IconBtn
                                    class={warm((on) => (on ? "quick-tile quick-tile-on" : "quick-tile"))}
                                    tooltip="Warm light"
                                    icon={warm((on) => (on ? "󰖔" : "󰖙"))}
                                    hexpand
                                    vexpand
                                    onClicked={() => script("toggle-warm-light.sh")}
                                />
                                <IconBtn
                                    class="quick-tile"
                                    tooltip="Screenshot"
                                    icon=""
                                    hexpand
                                    vexpand
                                    onClicked={() => script("screenshot.sh")}
                                />
                            </box>
                        </box>
                    </box>
                    <box cssClasses={["dash-mid-col"]} hexpand vexpand>
                        <box cssClasses={["music-widget"]} hexpand vexpand valign={Gtk.Align.CENTER}>
                            <box
                                cssClasses={["song-cover-art-widget"]}
                                css={cover((c) => (c ? `background-image: url('${c}');` : ""))}
                                valign={Gtk.Align.CENTER}
                            >
                                <label
                                    cssClasses={["icon-glyph", "song-cover-glyph"]}
                                    hexpand
                                    vexpand
                                    halign={Gtk.Align.CENTER}
                                    valign={Gtk.Align.CENTER}
                                    label={cover((c) => (c ? "" : "󰝚"))}
                                />
                            </box>
                            <box
                                orientation={Gtk.Orientation.VERTICAL}
                                spacing={2}
                                hexpand
                                valign={Gtk.Align.CENTER}
                            >
                                <label
                                    cssClasses={["music-title"]}
                                    halign={Gtk.Align.START}
                                    ellipsize={3}
                                    label={music((t) => t || "Not playing")}
                                />
                                <label
                                    cssClasses={["artist-widget"]}
                                    halign={Gtk.Align.START}
                                    ellipsize={3}
                                    label={artist((t) => t || " ")}
                                />
                                <slider
                                    cssClasses={["musicbar-widget"]}
                                    hexpand
                                    min={0}
                                    max={101}
                                    step={1}
                                    value={seek}
                                    onChangeValue={(_self, _scroll, value) => {
                                        script("set-music-seek.sh", String(Math.round(value)))
                                        return false
                                    }}
                                />
                                <box spacing={18} halign={Gtk.Align.CENTER} hexpand>
                                    <IconBtn
                                        class="prev-widget"
                                        tooltip="Previous"
                                        icon=""
                                        onClicked={() => run(["playerctl", "previous"])}
                                    />
                                    <IconBtn
                                        class="pause-widget"
                                        tooltip="Play / pause"
                                        icon={status((s) => (s === "Playing" ? "" : ""))}
                                        onClicked={() => run(["playerctl", "play-pause"])}
                                    />
                                    <IconBtn
                                        class="next-widget"
                                        tooltip="Next"
                                        icon=""
                                        onClicked={() => run(["playerctl", "next"])}
                                    />
                                </box>
                            </box>
                        </box>
                    </box>
                </box>

                <box spacing={10} hexpand>
                    <box
                        cssClasses={["dash-card", "dash-folders"]}
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={2}
                        vexpand
                    >
                        {FOLDERS.map(([label, path]) => (
                            <button
                                cssClasses={["dash-folder"]}
                                halign={Gtk.Align.START}
                                onClicked={() => script("open.sh", "nemo", path)}
                            >
                                <label label={label} halign={Gtk.Align.START} />
                            </button>
                        ))}
                    </box>
                    <box cssClasses={["dash-mid-col"]} hexpand vexpand>
                        <box
                            cssClasses={["resources"]}
                            orientation={Gtk.Orientation.VERTICAL}
                            spacing={8}
                            hexpand
                            vexpand
                        >
                            <Meter name="CPU" value={cpu} unit="%" tooltip={cpu((v) => `CPU usage: ${v}%`)} />
                            <Meter
                                name="TEMP"
                                value={temp}
                                unit="°"
                                tooltip={temp((v) => `CPU temperature: ${v}°C`)}
                            />
                            <Meter name="MEM" value={memory} unit="%" tooltip={memoryDetail} />
                            <Meter name="DSK" value={disk} unit="%" tooltip={diskDetail} />
                            <Meter name="BAT" value={battery} unit="%" tooltip={timeLeft} />
                        </box>
                    </box>
                </box>
                <Calendar />
            </box>
        </window>
    )
}
