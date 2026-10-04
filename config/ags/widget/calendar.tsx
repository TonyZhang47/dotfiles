import { Gtk } from "ags/gtk4"
import { With } from "ags"
import { createPoll } from "ags/time"

type Cell = { text: string; today: boolean }
type CalendarData = { title: string; rows: Cell[][] }

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

function buildCalendar(): CalendarData {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    const today = now.getDate()
    const title = now.toLocaleString("en-US", { month: "long", year: "numeric" })
    const first = new Date(year, month, 1)
    // Monday-first: JS Sunday=0
    const pad = (first.getDay() + 6) % 7
    const days = new Date(year, month + 1, 0).getDate()
    const cells: Cell[] = []
    for (let i = 0; i < pad; i++) cells.push({ text: " ", today: false })
    for (let d = 1; d <= days; d++) {
        cells.push({ text: String(d).padStart(2, " "), today: d === today })
    }
    while (cells.length % 7 !== 0) cells.push({ text: " ", today: false })
    const rows: Cell[][] = []
    for (let i = 0; i < cells.length; i += 7) rows.push(cells.slice(i, i + 7))
    return { title, rows }
}

export function Calendar() {
    const cal = createPoll(buildCalendar(), 60 * 60 * 1000, () => buildCalendar())
    return (
        <With value={cal}>
            {(c) => (
                <box
                    cssClasses={["calendar-container"]}
                    orientation={Gtk.Orientation.VERTICAL}
                >
                    <box
                        cssClasses={["calendar-grid"]}
                        orientation={Gtk.Orientation.VERTICAL}
                    >
                        <label cssClasses={["calendar-title"]} label={c.title} />
                        <box cssClasses={["weekdays"]} homogeneous>
                            {WEEKDAYS.map((day) => (
                                <label label={day} />
                            ))}
                        </box>
                        {c.rows.map((row) => (
                            <box homogeneous>
                                {row.map((cell) => (
                                    <label
                                        cssClasses={cell.today ? ["day", "today"] : ["day"]}
                                        label={cell.text}
                                    />
                                ))}
                            </box>
                        ))}
                    </box>
                </box>
            )}
        </With>
    )
}
