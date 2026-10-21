#!/usr/bin/env python3
"""Baltimore weather for Super+C. Open-Meteo first, NWS if that fails."""
import json
import os
import time
import urllib.request

CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ags-weather.json")
TTL = 10 * 60
LAT, LON = 39.2904, -76.6122
TIMEOUT = 12
UA = "pong-rice/1.0 (desktop; +https://forecast.weather.gov)"
OPEN_METEO = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}"
    "&current=temperature_2m,apparent_temperature,weather_code,is_day"
    "&temperature_unit=fahrenheit"
    "&timezone=America%2FNew_York"
)
NWS_POINTS = f"https://api.weather.gov/points/{LAT},{LON}"
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

ICON_WORDS = (
    ("thunder", "⛈️", "⛈️"),
    ("snow", "🌨️", "🌨️"),
    ("sleet", "🌨️", "🌨️"),
    ("freezing", "🌨️", "🌨️"),
    ("fog", "🌫️", "🌫️"),
    ("haze", "🌫️", "🌫️"),
    ("shower", "🌦️", "🌧️"),
    ("rain", "🌧️", "🌧️"),
    ("drizzle", "🌦️", "🌦️"),
    ("overcast", "☁️", "☁️"),
    ("cloud", "⛅", "☁️"),
    ("clear", "☀️", "🌙"),
    ("fair", "☀️", "🌙"),
    ("sun", "☀️", "🌙"),
)


def emit(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False), flush=True)


def get_json(url: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": UA, "Accept": "application/geo+json, application/json"},
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.loads(resp.read().decode())


def payload(icon: str, temp_f, text: str, feels: str = "") -> dict:
    temp_c = round((float(temp_f) - 32) * 5 / 9) if temp_f is not None else None
    return {
        "icon": icon,
        "temp": f"{int(round(float(temp_f)))}°F" if temp_f is not None else "--",
        "temp_c": f"{temp_c}°C" if temp_c is not None else "--",
        "feels": feels,
        "text": text,
        "city": "Baltimore",
    }


def icon_from_text(text: str, day: bool) -> str:
    low = text.lower()
    for word, day_icon, night_icon in ICON_WORDS:
        if word in low:
            return day_icon if day else night_icon
    return "☀️" if day else "🌙"


def fetch_open_meteo() -> dict:
    cur = get_json(OPEN_METEO).get("current") or {}
    f = cur.get("temperature_2m")
    feels = cur.get("apparent_temperature")
    code = int(cur.get("weather_code") or 0)
    day = bool(cur.get("is_day", 1))
    text, icon_day, icon_night = CODES.get(code, ("—", "☁️", "☁️"))
    feels_s = f"{round(float(feels))}°F" if feels is not None else ""
    return payload(icon_day if day else icon_night, f, text, feels_s)


def fetch_nws() -> dict:
    points = get_json(NWS_POINTS)
    hourly = (points.get("properties") or {}).get("forecastHourly")
    if not hourly:
        raise RuntimeError("nws points missing forecastHourly")
    periods = ((get_json(hourly).get("properties") or {}).get("periods")) or []
    if not periods:
        raise RuntimeError("nws hourly empty")
    period = periods[0]
    temp = period.get("temperature")
    unit = str(period.get("temperatureUnit") or "F").upper()
    if temp is not None and unit == "C":
        temp = float(temp) * 9 / 5 + 32
    text = period.get("shortForecast") or "—"
    day = bool(period.get("isDaytime", True))
    return payload(icon_from_text(text, day), temp, text)


def read_cache() -> dict | None:
    if not os.path.isfile(CACHE):
        return None
    try:
        with open(CACHE, encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        return None
    if not isinstance(data, dict) or data.get("text") == FALLBACK["text"]:
        return None
    return data


def write_cache(data: dict) -> None:
    tmp = CACHE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False)
    os.replace(tmp, CACHE)


def cache_is_fresh() -> bool:
    try:
        return time.time() - os.path.getmtime(CACHE) < TTL
    except OSError:
        return False


def main() -> None:
    cached = read_cache()
    if cached and cache_is_fresh():
        emit(cached)
        return
    for fetch in (fetch_open_meteo, fetch_nws):
        try:
            data = fetch()
            write_cache(data)
            emit(data)
            return
        except Exception:
            continue
    if cached:
        emit(cached)
        return
    emit(FALLBACK)


if __name__ == "__main__":
    main()
