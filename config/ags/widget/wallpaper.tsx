import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import { Astal, Gtk } from "ags/gtk4"
import { With } from "ags"
import app from "ags/gtk4/app"
import { HOME, jsonPoll, script } from "../lib"

const live = jsonPoll<string[]>([], 10000, `"${HOME}/.config/ags/scripts/get-live-wallpapers.sh"`)
const stills = jsonPoll<string[]>([], 10000, `"${HOME}/.config/ags/scripts/get-wallpapers.sh"`)

function previewPath(kind: "live" | "static", name: string) {
    const dir = kind === "live" ? `${HOME}/.config/live-wallpapers` : `${HOME}/.config/wallpapers`
    return `${dir}/preview-${name}.jpg`
}

function Tile({ name, kind }: { name: string; kind: "live" | "static" }) {
    const preview = previewPath(kind, name)
    const exists = GLib.file_test(preview, GLib.FileTest.EXISTS)
    return (
        <button
            cssClasses={["image-container"]}
            onClicked={() =>
                script("change-wallpaper.sh", kind === "live" ? `live:${name}` : name)
            }
        >
            {exists ? (
                <Gtk.Picture
                    file={Gio.File.new_for_path(preview)}
                    contentFit={Gtk.ContentFit.COVER}
                    widthRequest={286}
                    heightRequest={180}
                    cssClasses={["image-list-preview"]}
                />
            ) : (
                <label label={name} />
            )}
        </button>
    )
}

export function Wallpaper() {
    const mon = app.get_monitors()[0]
    const height = Math.round((mon?.get_geometry().height ?? 1200) * 0.9)

    return (
        <window
            name="wallpaper"
            namespace="ags"
            application={app}
            visible={false}
            exclusivity={Astal.Exclusivity.IGNORE}
            layer={Astal.Layer.OVERLAY}
            keymode={Astal.Keymode.NONE}
            anchor={Astal.WindowAnchor.LEFT}
            marginLeft={64}
            widthRequest={310}
            heightRequest={height}
        >
            <box cssClasses={["window"]} orientation={Gtk.Orientation.VERTICAL}>
                <scrolledwindow hexpand vexpand>
                    <box orientation={Gtk.Orientation.VERTICAL}>
                        <box cssClasses={["wp-section-head"]} hexpand>
                            <label
                                cssClasses={["wp-section-title"]}
                                halign={Gtk.Align.START}
                                label="Live"
                            />
                        </box>
                        <With value={live}>
                            {(names) => (
                                <box orientation={Gtk.Orientation.VERTICAL}>
                                    {names.map((name) => (
                                        <Tile name={name} kind="live" />
                                    ))}
                                </box>
                            )}
                        </With>
                        <box cssClasses={["wp-section-head"]} hexpand>
                            <label
                                cssClasses={["wp-section-title"]}
                                halign={Gtk.Align.START}
                                label="Static"
                            />
                        </box>
                        <With value={stills}>
                            {(names) => (
                                <box orientation={Gtk.Orientation.VERTICAL}>
                                    {names.map((name) => (
                                        <Tile name={name} kind="static" />
                                    ))}
                                </box>
                            )}
                        </With>
                    </box>
                </scrolledwindow>
            </box>
        </window>
    )
}
