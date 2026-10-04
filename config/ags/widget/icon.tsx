import { Gtk } from "ags/gtk4"
import type { Accessor } from "ags"

type IconBtnProps = {
    class?: string | Accessor<string>
    tooltip?: string
    icon: string | Accessor<string>
    hexpand?: boolean
    vexpand?: boolean
    onClicked?: () => void
}

function classes(value: string) {
    return ["icon-btn", ...value.split(" ").filter(Boolean)]
}

export function IconBtn({
    class: cssClass = "",
    tooltip = "",
    icon,
    hexpand = false,
    vexpand = false,
    onClicked,
}: IconBtnProps) {
    const cssClasses =
        typeof cssClass === "string" ? classes(cssClass) : cssClass((value) => classes(value))

    return (
        <button
            cssClasses={cssClasses}
            tooltipText={tooltip}
            hexpand={hexpand}
            vexpand={vexpand}
            onClicked={onClicked}
        >
            <label
                cssClasses={["icon-glyph"]}
                hexpand
                vexpand
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                label={icon}
            />
        </button>
    )
}
