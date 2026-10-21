// Rice theme: load userChrome and activate the wallpaper color theme.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("extensions.autoDisableScopes", 0);
user_pref("extensions.enabledScopes", 15);
user_pref("extensions.startupScanScopes", 15);
user_pref("xpinstall.signatures.required", false);
user_pref("browser.display.background_color", "{{base16.base00.default.hex}}");
user_pref("browser.display.foreground_color", "{{base16.base07.default.hex}}");
user_pref("browser.display.background_color.dark", "{{base16.base00.default.hex}}");
user_pref("browser.display.foreground_color.dark", "{{base16.base07.default.hex}}");
