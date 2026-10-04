import app from "ags/gtk4/app"
import { exec } from "ags/process"
import { monitorFile } from "ags/file"
import { CONFIG } from "./lib"
import { ControlCenter } from "./widget/control-center"
import { Settings } from "./widget/settings"
import { Wallpaper } from "./widget/wallpaper"

function compileCss() {
    try {
        exec(["sass", `${CONFIG}/style.scss`, `${CONFIG}/style.css`])
        app.apply_css(`${CONFIG}/style.css`, true)
    } catch (err) {
        printerr(`ags css: ${err}`)
    }
}

app.start({
    css: `${CONFIG}/style.css`,
    main() {
        compileCss()
        monitorFile(`${CONFIG}/colors.scss`, () => compileCss())
        ControlCenter()
        Settings()
        Wallpaper()
    },
})
