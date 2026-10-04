#!/usr/bin/env python3
"""Baltimore weather for the dashboard. Open-Meteo, Inner Harbor coords."""
import json
import os
import time
import urllib.request

CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ags-weather.json")
TTL = 10 * 60
LAT, LON = 39.2904, -76.6122
URL = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}"
    "&current=temperature_2m,apparent_temperature,weather_code,is_day"
    "&temperature_unit=fahrenheit"
    "&timezone=America%2FNew_York"
)
FALLBACK = {
    "icon": "☁",
    "temp": "--",
    "temp_c": "--",
    "text": "Weather unavailable",
    "city": "Baltimore",
}

# WMO weather interpretation codes.
CODES = {
    0: ("Clear sky", "☀️", "🌙"),
    1: ("Mostly clear", "🌤️", "🌙"),
    2: ("Partly cloudy", "⛅", "☁️"),
    3: ("Overcast", "☁️", "☁️"),
    45: ("Fog", "🌫️", "🌫️"),
    48: ("Icy fog", "🌫️", "🌫️"),
    51: ("Light drizzle", "🌦️", "🌦️"),
    53: ("Drizzle", "🌦️", "🌦️"),
    55: ("Heavy drizzle", "🌧️", "🌧️"),
    61: ("Light rain", "🌧️", "🌧️"),
    63: ("Rain", "🌧️", "🌧️"),
    65: ("Heavy rain", "🌧️", "🌧️"),
    71: ("Light snow", "🌨️", "🌨️"),
    73: ("Snow", "🌨️", "🌨️"),
    75: ("Heavy snow", "❄️", "❄️"),
    80: ("Rain showers", "🌦️", "🌦️"),
    81: ("Rain showers", "🌧️", "🌧️"),
    82: ("Heavy showers", "🌧️", "🌧️"),
    95: ("Thunderstorm", "⛈️", "⛈️"),
    96: ("Thunderstorm", "⛈️", "⛈️"),
    99: ("Thunderstorm", "⛈️", "⛈️"),
}


def emit(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False), flush=True)


def fetch() -> dict:
    req = urllib.request.Request(URL, headers={"User-Agent": "pong-dashboard/1.0"})
    with urllib.request.urlopen(req, timeout=5) as resp:
        cur = json.loads(resp.read().decode()).get("current") or {}
    f = cur.get("temperature_2m")
    feels = cur.get("apparent_temperature")
    code = int(cur.get("weather_code") or 0)
    day = bool(cur.get("is_day", 1))
    text, icon_day, icon_night = CODES.get(code, ("—", "☁️", "☁️"))
    icon = icon_day if day else icon_night
    temp_f = round(float(f)) if f is not None else None
    temp_c = round((float(f) - 32) * 5 / 9) if f is not None else None
    feels_s = f"{round(float(feels))}°F" if feels is not None else ""
    return {
        "icon": icon,
        "temp": f"{temp_f}°F" if temp_f is not None else "--",
        "temp_c": f"{temp_c}°C" if temp_c is not None else "--",
        "feels": feels_s,
        "text": text,
        "city": "Baltimore",
    }


def main() -> None:
    if os.path.isfile(CACHE) and time.time() - os.path.getmtime(CACHE) < TTL:
        print(open(CACHE, encoding="utf-8").read(), end="")
        return
    try:
        data = fetch()
        with open(CACHE, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False)
        emit(data)
    except Exception:
        if os.path.isfile(CACHE):
            print(open(CACHE, encoding="utf-8").read(), end="")
        else:
            emit(FALLBACK)


if __name__ == "__main__":
    main()
