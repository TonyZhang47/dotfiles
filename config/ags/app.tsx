import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import app from "ags/gtk4/app"
import { exec } from "ags/process"
import { monitorFile, readFile, writeFile } from "ags/file"
import { CONFIG } from "./lib"
import { ControlCenter } from "./widget/control-center"
import { Settings } from "./widget/settings"
import { Wallpaper } from "./widget/wallpaper"

const WINDOWS = ["control-center", "settings", "wallpaper"] as const
const RUN = GLib.get_user_runtime_dir()
const TOGGLE = `${RUN}/ags-toggle`
const READY = `${RUN}/ags-ready`

function compileCss() {
    try {
        exec(["sass", `${CONFIG}/style.scss`, `${CONFIG}/style.css`])
        app.apply_css(`${CONFIG}/style.css`, true)
    } catch (err) {
        printerr(`ags css: ${err}`)
    }
}

function toggleNamed(name: string) {
    if (!WINDOWS.includes(name as (typeof WINDOWS)[number])) return
    const win = app.get_window(name)
    if (!win) return
    const next = !win.visible
    win.visible = next
    if (next) {
        for (const other of WINDOWS) {
            if (other === name) continue
            const w = app.get_window(other)
            if (w) w.visible = false
        }
    }
}

let lastToken = ""

function applyToggleFile() {
    try {
        const raw = readFile(TOGGLE).trim()
        const [name, token] = raw.split(/\s+/, 2)
        if (!name) return
        if (token && token === lastToken) return
        lastToken = token || raw
        toggleNamed(name)
    } catch {
        // file missing on first boot
    }
}

app.start({
    css: `${CONFIG}/style.css`,
    requestHandler(argv, res) {
        const name = argv.find((a) => WINDOWS.includes(a as (typeof WINDOWS)[number]))
        if (name) toggleNamed(name)
        res("ok")
    },
    main() {
        compileCss()
        monitorFile(`${CONFIG}/colors.scss`, () => compileCss())
        ControlCenter()
        Settings()
        Wallpaper()
        try {
            writeFile(TOGGLE, ".\n")
        } catch {
            // runtime dir should exist
        }
        monitorFile(TOGGLE, (_file, event) => {
            if (
                event === Gio.FileMonitorEvent.CHANGES_DONE_HINT ||
                event === Gio.FileMonitorEvent.CHANGES
            ) {
                applyToggleFile()
            }
        })
        try {
            writeFile(READY, "1")
        } catch {
            // Super+C waits for this file
        }
    },
})
