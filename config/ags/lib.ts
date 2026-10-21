import GLib from "gi://GLib?version=2.0"
import { createSubprocess, execAsync } from "ags/process"
import { createPoll } from "ags/time"

export const HOME = GLib.get_home_dir()
export const SCRIPTS = `${HOME}/.config/ags/scripts`
export const CONFIG = `${HOME}/.config/ags`

export type Workspace = {
    id: number
    label: string
    occupied: boolean
}

export type WorkspaceState = {
    active: number
    list: Workspace[]
}

export const EMPTY_WORKSPACES: WorkspaceState = {
    active: 1,
    list: Array.from({ length: 10 }, (_, i) => ({
        id: i + 1,
        label: i === 9 ? "0" : String(i + 1),
        occupied: false,
    })),
}

export type Clock = { hms: string; day: string; date: string }
export type Uptime = { hours: number; mins: number }
export type Weather = { icon: string; temp: string; temp_c: string; text: string; city: string }
export type Settings = {
    sensitivity: number
    sensitivity_i: number
    sensitivity_label: string
    scroll_factor: number
    scroll_i: number
    scroll_label: string
    gaps_in: number
    gaps_out: number
    rounding: number
    inactive_opacity: number
    opacity_i: number
    opacity_label: string
    animations: boolean
    animations_label: string
    accel_profile: string
    accel_label: string
}

export const DEFAULT_SETTINGS: Settings = {
    sensitivity: 0.5,
    sensitivity_i: 150,
    sensitivity_label: "+0.50",
    scroll_factor: 0.2,
    scroll_i: 20,
    scroll_label: "0.20",
    gaps_in: 8,
    gaps_out: 18,
    rounding: 14,
    inactive_opacity: 0.9,
    opacity_i: 90,
    opacity_label: "90%",
    animations: true,
    animations_label: "On",
    accel_profile: "flat",
    accel_label: "Flat",
}

export function parseJson<T>(out: string, fallback: T): T {
    try {
        return JSON.parse(out) as T
    } catch {
        return fallback
    }
}

export function numOf(out: string, fallback = 0): number {
    const n = Number(String(out).trim())
    return Number.isFinite(n) ? n : fallback
}

export function boolOf(out: string): boolean {
    return String(out).trim() === "true"
}

async function pollOut(cmd: string): Promise<string> {
    try {
        return await execAsync(["bash", "-c", cmd])
    } catch {
        return ""
    }
}

export function jsonPoll<T>(init: T, interval: number, cmd: string) {
    return createPoll(init, interval, async (prev) => {
        const out = await pollOut(cmd)
        return out ? parseJson(out, prev) : prev
    })
}

export function numPoll(init: number, interval: number, cmd: string) {
    return createPoll(init, interval, async (prev) => {
        const out = await pollOut(cmd)
        return out ? numOf(out, prev) : prev
    })
}

export function strPoll(init: string, interval: number, cmd: string) {
    return createPoll(init, interval, async (prev) => {
        const out = await pollOut(cmd)
        return out ? String(out).trim() : prev
    })
}

export function boolPoll(init: boolean, interval: number, cmd: string) {
    return createPoll(init, interval, async (prev) => {
        const out = await pollOut(cmd)
        return out ? boolOf(out) : prev
    })
}

export function follow(init: string, cmd: string) {
    return createSubprocess(init, ["bash", "-c", cmd])
}

export function run(cmd: string | string[]) {
    execAsync(typeof cmd === "string" ? ["bash", "-c", cmd] : cmd).catch((err) =>
        printerr(String(err)),
    )
}

export function script(name: string, ...args: string[]) {
    const extra = args.map((a) => `'${a.replace(/'/g, `'\\''`)}'`).join(" ")
    run(`${SCRIPTS}/${name}${extra ? ` ${extra}` : ""}`)
}
