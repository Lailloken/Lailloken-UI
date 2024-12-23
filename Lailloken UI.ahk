#NoEnv
#SingleInstance, Force
#Requires AutoHotkey >=1.1.36 <2
#InstallKeybdHook
#InstallMouseHook
#Hotstring NoMouse
#UseHook
#MaxThreads 255
#MaxMem 1024
#Include %A_ScriptDir%
#Include data\Class_CustomFont.ahk
#Include data\External Functions.ahk
#Include data\JSON.ahk

SetWorkingDir %A_ScriptDir%
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "RightClick")
StringCaseSense, Locale
SetKeyDelay, 100
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetTitleMatchMode, 2
SetBatchLines, -1
OnExit("Exit")
Menu, Tray, Tip, Lailloken UI
Menu, Tray, Icon, img\GUI\tray.ico

vars := {"general": {"runcheck": A_TickCount}, "logging": FileExist("data\log.txt")}, LLK_Log("waiting for valid game-clients...")
While !WinExist("ahk_class POEWindowClass") && !WinExist("ahk_exe GeForceNOW.exe") ;wait for game-client window
{
	If (A_TickCount >= vars.general.runcheck + 60000)
		ExitApp
	win_not_exist := 1
	Sleep, 100
}

;band-aid fix for situations in which the client was launched after the script, and the script detected an unsupported resolution because the PoE-client window was being resized during window-detection
If (WinExist("ahk_class POEWindowClass") || WinExist("ahk_exe GeForceNOW.exe")) && win_not_exist
	Sleep, 4000
LLK_Log("found game-client")
vars.poe_version := CheckClient(), LLK_Log("--- tool launched" (vars.poe_version ? " (PoE 2)" : "") " ---")

If !vars.poe_version && FileExist("ini\") && !FileExist("ini\file check.ini") ;check ini-files for incorrect file-encoding
	IniIntegrityCheck()
If LLK_IniRead("ini\config.ini", "versions", "apply update")
{
	UpdateCheck(2)
	IniDelete, % "ini\config.ini", versions, apply update
}
Else If LLK_IniRead("ini\config.ini", "versions", "update auto-check")
	LLK_Log("checking for updates"), UpdateCheck()
Init_vars()
Startup()
Init_screenchecks(), LLK_Log("initialized screenchecks settings")
Init_general(), LLK_Log("initialized general settings")
Init_betrayal(), LLK_Log("initialized betrayal settings")
Init_cheatsheets(), LLK_Log("initialized cheat-sheet settings")
Init_cloneframes(), LLK_Log("initialized clone-frames settings")
If WinExist("ahk_exe GeForceNOW.exe")
	Init_geforce(), LLK_Log("initialized geforce now settings")
Init_iteminfo(), LLK_Log("initialized item-info settings")
Init_legion(), LLK_Log("initialized seed-explorer settings")
Init_mapinfo(), LLK_Log("initialized map-info settings")
Init_OCR(), LLK_Log("initialized ocr settings")
Init_searchstrings(), LLK_Log("initialized search-strings settings")
Init_leveltracker(), LLK_Log("initialized act-tracker settings")
Init_maptracker(), LLK_Log("initialized map-tracker settings")
Init_qol(), LLK_Log("initialized minor qol settings")
Init_recombination(), LLK_Log("initialized recombination settings")
Init_sanctum(), LLK_Log("initialized sanctum planner settings")
Init_stash(), LLK_Log("initialized stash-ninja settings")
Init_hotkeys(), LLK_Log("initialized hotkey settings")
Resolution_check()

SetTimer, Loop, 1000
SetTimer, Loop_main, 50

vars.system.timeout := 0
LLK_Log("waiting for focus on client-window...")
If !settings.general.dev
	WinWaitActive, ahk_group poe_window
Else
{
	WinWaitActive, ahk_group poe_ahk_window
	SoundBeep, 100
}
LLK_Log("client is focused")

Init_GUI(), LLK_Log("GUIs initialized")
SetTimer, Log_Loop, 1000

If (check := LLK_IniRead("ini" vars.poe_version "\config.ini", "versions", "reload settings"))
{
	Settings_menu(check,, 0)
	IniDelete, % "ini" vars.poe_version "\config.ini", Versions, reload settings
}
If vars.ini_integrity
{
	MsgBox, % "The tool tried to fix misconfigured config-files in order to resolve an AHK bug, but there was an error.`n`nTo fix this manually, you have to open the files listed below (left) in a text-editor and copy their contents into the fixed files (right), replacing everything inside:`n`n" vars.ini_integrity "`n`nThis list is also stored in ""ini\file check.ini"" in case you want to do it later.`nIf you skip this manual fix, you'll have to reconfigure those features that rely on the files listed above."
	Reload
	ExitApp
}
LLK_Log("+++ tool is running +++")
Return

#Include modules\betrayal-info.ahk
#Include modules\cheat sheets.ahk
#Include modules\client log.ahk
#Include modules\clone-frames.ahk
#Include modules\GUI.ahk
#Include modules\hotkeys.ahk
#Include *i modules\hotkeys custom.ahk
#Include modules\item-checker.ahk
#Include modules\languages.ahk
#Include modules\leveling tracker.ahk
#Include modules\lootfilter.ahk
#Include modules\map-info.ahk
#Include modules\map tracker.ahk
#Include modules\ocr.ahk
#Include modules\omni-key.ahk
#Include modules\qol tools.ahk
#Include modules\recombination.ahk
#Include modules\sanctum.ahk
#Include modules\screen-checks.ahk
#Include modules\search-strings.ahk
#Include modules\seed-explorer.ahk
#Include modules\settings menu.ahk
#Include modules\stash-ninja.ahk

Blank(var)
{
	If (var = "")
		Return 1
}

CheckClient()
{
	local
	global vars

	WinGet, clients, List, % WinExist("ahk_exe GeForceNOW.exe") ? "ahk_exe GeForceNOW.exe" : "ahk_class POEWindowClass"
	If (clients > 1)
		LLK_Error("Multiple game-clients detected. Tool will exit.")

	If WinExist("ahk_exe GeForceNOW.exe")
		WinGetTitle, title, ahk_exe GeForceNOW.exe
	Else WinGet, title, ProcessPath, ahk_class POEWindowClass

	If LLK_PatternMatch(title, "", [" 2", " ii"],,, 0)
		Return " 2"
}

Exit()
{
	local
	global vars, settings, Json

	Gdip_Shutdown(pToken)
	vars.log.file.Close()

	If (vars.system.timeout != 0) ;script exited before completing startup routines: return here to prevent storing corrupt/incomplete data in ini-files
		Return
	If !vars.poe_version && IsObject(vars.betrayal.board) && (vars.betrayal.board0 != Json.Dump(vars.betrayal.board))
		IniWrite, % """" Json.Dump(vars.betrayal.board) """", ini\betrayal info.ini, settings, board
	timer := vars.leveltracker.timer
	If !vars.poe_version && IsNumber(timer.current_split) && (timer.current_split != timer.current_split0)
		IniWrite, % vars.leveltracker.timer.current_split, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time

	If vars.maptracker.map.date_time
		Maptracker_Save()
}

FormatSeconds(seconds, leading_zeroes := 1)  ; Convert the specified number of seconds to hh:mm:ss format.
{
	local

	days := 0, time := 19990101  ; *Midnight* of an arbitrary date.
	While (seconds >= 86400)
		days += 1, seconds -= 86400
	time += seconds, seconds
	FormatTime, time, %time%, HH:mm:ss
	If days
		time := (days < 10 ? "0" : "") days ":" time
	While !leading_zeroes && InStr("0:", SubStr(time, 1, 1)) && (StrLen(time) > 4) ;remove leading 0s and colons
		time := SubStr(time, 2)
	return time
}

HTTPtoVar(URL, mode := "URL", currency := "") ; taken from the AHK-wiki, adapted to also fetch data from bulk-exchange
{
	local
	global vars, settings, json

	If (mode = "exchange")
		item := URL, URL := "https://www.pathofexile.com/api/trade/exchange/" StrReplace(settings.stash.league, " ", "%20"), array := []
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open((mode = "exchange") ? "POST" : "GET", URL, true)
	If (mode = "exchange")
		whr.SetRequestHeader("Content-Type", "application/json")
	whr.Send((mode = "exchange") ? "{""query"":{""status"":{""option"":""onlineleague""},""have"":[""" currency """],""want"":[""" item """]},""sort"":{""have"":""asc""},""engine"":""new""}" : "")
	; Using 'true' above and the call below allows the script to remain responsive.
	whr.WaitForResponse()

	If (mode = "exchange")
	{
		limits_max := StrSplit(whr.GetResponseHeader("X-Rate-Limit-Ip"), ",", A_Space), limits_current := StrSplit(whr.GetResponseHeader("X-Rate-Limit-Ip-State"), ",", A_Space)
		status := whr.Status(), limits := {}
		Loop, % limits_max.Count()
		{
			pCurrent := StrSplit(limits_current[A_Index], ":", A_Space), pMax := StrSplit(limits_max[A_Index], ":", A_Space)
			limits[pCurrent.2] := [pCurrent.1, pMax.1, pMax.3]
		}
		array.1 := (SubStr(whr.ResponseText, 1, 1) . SubStr(whr.ResponseText, 0) != "{}") || InStr(whr.ResponseText, """error""") ? "" : json.Load(whr.ResponseText)
		array.2 := limits, array.3 := status, array.4 := (status = 429) ? whr.GetResponseHeader("Retry-After") : ""
	}
	Return (mode = "URL" ? whr.ResponseText : array)
}

Init_client()
{
	local
	global vars, settings

	If !FileExist("ini\config.ini") ;ini\config.ini is required regardless of which PoE-version is being played
		IniWrite, % "", % "ini\config.ini", settings

	If !FileExist("ini" vars.poe_version "\config.ini")
		IniWrite, % "", % "ini" vars.poe_version "\config.ini", settings

	If !WinExist("ahk_exe GeForceNOW.exe") ;if client is not a streaming client
	{
		LLK_Log("game-client is local client")
		;load client-config location and double-check
		ini := IniBatchRead("ini" vars.poe_version "\config.ini")
		poe_config_file := !Blank(check := ini.settings["poe config-file"]) ? check : A_MyDocuments "\My Games\Path of Exile" (vars.poe_version ? " 2\poe2_" : "\") "production_Config.ini"
		If !FileExist(poe_config_file)
		{
			FileSelectFile, poe_config_file, 3, %A_MyDocuments%\My Games\\production_Config.ini, % "Please locate the '" (vars.poe_version ? "poe2_" : "") "production_Config.ini' file which is stored in the same folder as loot-filters", config files (*.ini)
			If (ErrorLevel = 1) || !InStr(poe_config_file, "production_Config")
			{
				Reload
				ExitApp
			}
			FileRead, poe_config_check, % poe_config_file
			If !InStr(poe_config_check, "[Display]")
			{
				Reload
				ExitApp
			}
		}
		IniWrite, % """" poe_config_file """", % "ini" vars.poe_version "\config.ini", Settings, PoE config-file
		vars.system.config := poe_config_file, vars.client.stream := 0
		LLK_Log("found game's config-file")

		;check the contents of the client-config
		FileRead, poe_config_check, % poe_config_file
		If (poe_config_check = "")
			LLK_Error("Cannot read the PoE config-file. Please restart the game-client and then the script. If you get this error repeatedly, please report the issue.`n`nError-message (for reporting): PoE-config returns empty")

		;check if the client is currently running in exclusive-fullscreen mode
		exclusive_fullscreen := InStr(poe_config_check, "`nfullscreen=true") ? "true" : InStr(poe_config_check, "fullscreen=false") ? "false" : ""
		If (exclusive_fullscreen = "")
		{
			IniDelete, % "ini" vars.poe_version "\config.ini", Settings, PoE config-file
			LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of exclusive fullscreen", 1)
		}
		Else If (exclusive_fullscreen = "true")
			LLK_Error("The game-client is set to exclusive fullscreen.`nPlease set it to windowed fullscreen.")

		;check if the client is currently running in fullscreen or windowed mode
		vars.client.fullscreen := InStr(poe_config_check, "borderless_windowed_fullscreen=true") ? "true" : InStr(poe_config_check, "borderless_windowed_fullscreen=false") ? "false" : ""
		If (vars.client.fullscreen = "")
		{
			IniDelete, % "ini" vars.poe_version "\config.ini", Settings, PoE config-file
			LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of borderless fullscreen", 1)
		}
		LLK_Log("recognized current window settings")

		;check if client's window settings have changed since the previous session
		If ini.settings.fullscreen && (ini.settings.fullscreen != vars.client.fullscreen)
		{
			IniWrite, % vars.client.fullscreen, % "ini" vars.poe_version "\config.ini", Settings, fullscreen
			IniWrite, 0, % "ini" vars.poe_version "\config.ini", Settings, remove window-borders
			IniDelete, % "ini" vars.poe_version "\config.ini", Settings, custom-resolution
			IniDelete, % "ini" vars.poe_version "\config.ini", Settings, custom-width
			ini.settings["custom-width"] := ini.settings["custom-resolution"] := "", ini.settings["remove window-borders"] := 0
		}
	}
	Else vars.client.stream := 1, vars.client.fullscreen := "true"

	;determine native resolution of the active monitor
	WinGet, minmax, MinMax, ahk_group poe_window
	If (minmax = -1)
	{
		WinRestore, ahk_group poe_window
		Sleep, 2000
	}
	WinGetPos, x, y, w, h, ahk_group poe_window
	Gui, Screen_Test: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption
	WinSet, Trans, 0
	Gui, Screen_Test: Show, % "NA x" x + w//2 " y" y + h//2 " Maximize"
	WinGetPos, xScreenOffset_monitor, yScreenOffSet_monitor, width_native, height_native
	Gui, Screen_Test: Destroy
	;WinGetPos, x, y, w, h, ahk_class Shell_TrayWnd
	vars.monitor := {"x": xScreenOffset_monitor, "y": yScreenOffSet_monitor, "w": width_native, "h": height_native, "xc": xScreenOffset_monitor + width_native / 2, "yc": yScreenOffSet_monitor + height_native / 2}
	LLK_Log("measured monitor resolution and position: " width_native "x" height_native ", " xScreenOffset_monitor ", " yScreenOffSet_monitor)

	If !vars.client.stream
	{
		vars.client.docked := !Blank(check := ini.settings["window-position"]) ? check : "center", vars.client.docked2 := !Blank(check := ini.settings["window-position vertical"]) ? check : "center"
		vars.client.borderless := (vars.client.fullscreen = "true") ? 1 : !Blank(check := ini.settings["remove window-borders"]) ? check : 0
		vars.client.customres := [ini.settings["custom-width"], ini.settings["custom-resolution"]]
	}
	If IsNumber(vars.client.customres.1) && IsNumber(vars.client.customres.2)
	{
		If (vars.client.customres.1 > vars.monitor.w) || (vars.client.customres.2 > vars.monitor.h) ;check resolution in case of manual .ini edit
		{
			MsgBox, Incorrect settings for forced resolution detected.`nThe script will reset the settings and restart.
			IniWrite, % vars.monitor.h, % "ini" vars.poe_version "\config.ini", Settings, custom-resolution
			IniWrite, % vars.monitor.w, % "ini" vars.poe_version "\config.ini", Settings, custom-width
			Reload
			ExitApp
		}

		If (vars.client.fullscreen = "true")
			WinMove, ahk_group poe_window,, % vars.monitor.x, % vars.monitor.y, % (vars.client.customres.1 := vars.monitor.w), % vars.client.customres.2
		Else
		{
			WinSet, Style, % (vars.client.borderless ? "-" : "+") "0x40000", ahk_group poe_window ;add resize-borders
			WinSet, Style, % (vars.client.borderless ? "-" : "+") "0xC00000", ahk_group poe_window ;add caption
			If !vars.client.borderless
				WinMove, ahk_group poe_window,,,, % vars.client.customres.1 + 2* vars.system.xborder, % vars.client.customres.2 + vars.system.caption + 2* vars.system.yborder
			Else WinMove, ahk_group poe_window,,,, % vars.client.customres.1, % vars.client.customres.2
		}
		LLK_Log("applied custom resolution")
	}

	WinGetPos, x, y, w, h, ahk_group poe_window
	vars.client.x_offset := (vars.client.fullscreen = "false" && !vars.client.borderless) ? vars.system.xborder : 0
	xTarget := (vars.client.docked = "left") ? vars.monitor.x - vars.client.x_offset : (vars.client.docked = "center") ? vars.monitor.x + (vars.monitor.w - w) / 2 : vars.monitor.x + vars.monitor.w - (w - vars.client.x_offset)
	yTarget := (vars.client.docked2 = "top") ? vars.monitor.y : (vars.client.docked2 = "center") ? vars.monitor.y + (vars.monitor.h - h)/2 : vars.monitor.y + vars.monitor.h - (h - (vars.client.borderless ? 0 : vars.system.yBorder))
	If !vars.client.stream && ((vars.client.fullscreen = "false") || (vars.client.w < vars.monitor.w) || (vars.client.h < vars.monitor.h))
	{
		WinMove, ahk_group poe_window,, % xTarget, % yTarget
		WinGetPos, x, y, w, h, ahk_group poe_window
		LLK_Log("repositioned game-client")
	}
	vars.client.x := vars.client.x0 := x, vars.client.y := vars.client.y0 := y
	vars.client.w := vars.client.w0 := w, vars.client.h := vars.client.h0 := h

	;apply overlay offsets if client is running in bordered windowed mode
	If (vars.client.fullscreen = "false") && !vars.client.borderless
	{
		vars.client.w0 := vars.client.w -= 2* vars.system.xborder
		vars.client.h0 := vars.client.h := vars.client.h - vars.system.caption - 2* vars.system.yborder
		vars.client.x0 := vars.client.x += vars.system.xborder
		vars.client.y0 := vars.client.y += vars.system.caption + vars.system.yborder
		LLK_Log("applied offsets for windowed mode")
	}
	vars.client.xc := vars.client.x - vars.monitor.x + vars.client.w/2, vars.client.yc := vars.client.y - vars.monitor.y + vars.client.h/2 ;client's horizontal and vertical centers (RELATIVE TO monitor.x and monitor.y)
	settings.general.FillerAvailable := (vars.client.fullscreen = "false" && vars.client.borderless || vars.client.fullscreen = "true" && vars.client.h < vars.monitor.h) ? 1 : 0

	IniRead, iniread, data\Resolutions.ini
	Loop, Parse, iniread, `n
	{
		If (A_Index = 1)
			vars.general.supported_resolutions := {}, vars.general.available_resolutions := ""
		vars.general.supported_resolutions[StrReplace(A_LoopField, "p")] := 1
		If (StrReplace(A_Loopfield, "p") <= vars.monitor.h && (vars.client.fullscreen = "true" || vars.client.borderless)) || (StrReplace(A_LoopField, "p") < vars.monitor.h && (vars.client.fullscreen = "false") && !vars.client.borderless)
			vars.general.available_resolutions := !vars.general.available_resolutions ? StrReplace(A_Loopfield, "p") :  StrReplace(A_Loopfield, "p") "|" vars.general.available_resolutions
	}
	vars.general.available_resolutions .= "|"

	If (!IsNumber(vars.client.customres.1) || !IsNumber(vars.client.customres.2)) && vars.general.supported_resolutions.HasKey(vars.client.h)
	{
		IniWrite, % vars.client.w, % "ini" vars.poe_version "\config.ini", settings, custom-width
		IniWrite, % vars.client.h, % "ini" vars.poe_version "\config.ini", settings, custom-resolution
	}

	If vars.general.supported_resolutions.HasKey(vars.client.h)
	{
		Loop, Parse, % "GUI, Betrayal, Mapping Tracker", `,, %A_Space%
			If !FileExist("img\Recognition (" vars.client.h "p)\" A_LoopField "\")
				FileCreateDir, % "img\Recognition (" vars.client.h "p)\" A_LoopField "\"
		If !FileExist("img\Recognition (" vars.client.h "p)\")
			LLK_FilePermissionError("create", A_ScriptDir "\img\Recognition ("vars.client.h "p)")
	}
}

Init_geforce()
{
	local
	global vars, settings

	If !FileExist("ini" vars.poe_version "\geforce now.ini")
		IniWrite, % "", % "ini" vars.poe_version "\geforce now.ini", settings
	vars.pixelsearch.variation := LLK_IniRead("ini" vars.poe_version "\geforce now.ini", "Settings", "pixel-check variation", 10)
	vars.imagesearch.variation := LLK_IniRead("ini" vars.poe_version "\geforce now.ini", "Settings", "image-check variation", 25)
}

Init_general()
{
	local
	global vars, settings

	ini := IniBatchRead("ini" vars.poe_version "\config.ini"), legacy_version := ini.versions["ini-version"], new_version := 15407
	If IsNumber(legacy_version) && (legacy_version < 15000) || FileExist("modules\alarm-timer.ahk") ;|| FileExist("modules\delve-helper.ahk")
	{
		MsgBox,, Script updated incorrectly, Updating from legacy to v1.50+ requires a clean installation.`nThe script will now exit.
		ExitApp
	}
	ini_version := LLK_IniRead("ini\config.ini", "versions", "ini") ;ini-version is stored here regardless of which PoE-version is being played
	If !ini_version
		IniWrite, % new_version, ini\config.ini, versions, ini

	If (ini_version < 15303)
	{
		FileDelete, % "img\Recognition (" vars.client.h "p)\GUI\betrayal.bmp"
		If ini.features["enable betrayal-info"]
			MsgBox, % "The betrayal image-check was changed in v1.53.3 and needs to be recalibrated."
	}
	If (ini_version < 15304)
	{
		FileDelete, data\global\[stash-ninja] prices.ini
		IniWrite, % new_version, ini\config.ini, versions, ini
	}
	settings.general.version := new_version
	settings.general.trans := 230
	settings.general.blocked_hotkeys := {"!": 1, "^": 1, "+": 1}
	settings.general.character := ini.settings["active character"]
	settings.general.build := !Blank(settings.general.character) ? ini.settings["active build"] : ""
	settings.general.dev := !Blank(check := ini.settings["dev"]) ? check : 0
	settings.general.dev_env := settings.general.dev * (!Blank(check := ini.settings["dev env"]) ? check : 0)
	settings.general.xButton := !Blank(check := ini.UI["button xcoord"]) ? check : 0
	settings.general.yButton := !Blank(check := ini.UI["button ycoord"]) ? check : 0
	settings.general.warning_ultrawide := !Blank(check := ini.versions["ultrawide warning"]) ? check : 0
	settings.general.hide_toolbar := !Blank(check := ini.UI["hide toolbar"]) ? check : 0
	settings.general.ClientFiller := !settings.general.FillerAvailable ? 0 : !Blank(check := ini.settings["client background filler"]) ? check : 0

	settings.general.fSize := !Blank(check := ini.settings["font-size"]) ? check : LLK_FontDefault()
	If (settings.general.fSize < 6)
		settings.general.fSize := 6
	LLK_FontDimensions(settings.general.fSize, font_height, font_width), settings.general.fHeight := font_height, settings.general.fWidth := font_width
	LLK_FontDimensions(settings.general.fSize - 4, font_height, font_width), settings.general.fHeight2 := font_height, settings.general.fWidth2 := font_width
	settings.features.browser := !Blank(check := ini.settings["enable browser features"]) ? check : 1
	settings.features.sanctum := !Blank(check := ini.features["enable sanctum planner"]) ? check : 0
	settings.features.lootfilter := !Blank(check := ini.features["enable filterspoon"]) ? check : 0
	settings.updater := {"update_check": LLK_IniRead("ini\config.ini", "settings", "update auto-check", 0)}

	vars.pics := {"global": {"close": LLK_ImageCache("img\GUI\close.png"), "help": LLK_ImageCache("img\GUI\help.png"), "reload": LLK_ImageCache("img\GUI\restart.png")}, "iteminfo": {}, "legion": {}, "leveltracker": {}, "maptracker": {}, "stashninja": {}}
}

Init_vars()
{
	local
	global vars, settings, CustomFont, db, Json

	db := {}
	;read databases for item-info tooltip
	db.item_mods := Json.Load(LLK_FileRead("data\global\item mods" vars.poe_version ".json"))
	db.item_bases := Json.Load(LLK_FileRead("data\global\item bases" vars.poe_version ".json", 1))
	db.item_drops := Json.Load(LLK_FileRead("data\global\item drop-tiers" vars.poe_version ".json"))

	settings := {}
	settings.features := {}
	settings.geforce := {}

	vars.betrayal := {}
	vars.cheatsheets := {}
	vars.client := {}
	vars.GUI := []
	vars.omnikey := {}
	vars.omnikey.poedb := {"Claws": 1,"Daggers": 1, "Wands": 1, "One Hand Swords": 1, "One Hand Axes": 1, "One Hand Maces": 1, "Sceptres": 1, "Spears": 1, "Flails": 1
	, "Bows": 1, "Staves": 1, "Two Hand Swords": 1, "Two Hand Axes": 1, "Two Hand Maces": 1, "Quarterstaves": 1, "Crossbows": 1, "Traps": 1
	, "Amulets": 1, "Rings": 1, "Belts": 1, "Gloves": 2, "Boots": 2, "Body Armours": 2, "Helmets": 2
	, "Quivers": 1, "Foci": 1, "Shields": 2, "Jewels": 1, "Life Flasks": 1, "Mana Flasks": 1, "Charms": 1}
	vars.leveltracker := {}
	vars.lang := {}, vars.lang2 := {}
	vars.log := {} ;store data related to the game's log here
	vars.mapinfo := {}
	vars.hwnd := {"help_tooltips": {}}
	vars.help := Json.Load(LLK_FileRead("data\english\help tooltips.json",, "65001"))
	vars.recombination := {"classes": ["shield", "sword", "quiver", "bow", "claw", "dagger", "mace", "ring", "amulet", "helmet", "glove", "boot", "belt", "wand", "staves", "axe", "sceptre", "body"]}
	vars.snip := {}
	Loop, Files, data\alt_font*
		alt_font := A_LoopFileName
	vars.system := {"timeout": 1, "font1": New CustomFont("data\" (!Blank(alt_font) ? alt_font : "Fontin-SmallCaps.ttf")), "click": 1}
	vars.tooltip := {}
	vars.general := {"buggy_resolutions": {768: 1, 1024: 1, 1050: 1}, "inactive": 0, "startup": A_TickCount, "updatetick": 0}
	If !IsObject(vars.updater)
	{
		version := Json.Load(LLK_FileRead("data\versions.json")), version := version._release.1 . (version.hotfix ? "." (version.hotfix < 10 ? "0" : "") version.hotfix : "")
		vars.updater := {"version": [version, UpdateParseVersion(version)]}
	}

	LLK_Log("initialized global objects")
}

IniBatchRead(file, section := "", encoding := "1200")
{
	local

	ini := {}, file := Blank(section) ? LLK_FileRead(file, 1, encoding) : LLK_IniRead(file, section)
	If !Blank(section)
		ini[section] := {}
	If Blank(section) && !InStr(file, "[") && !InStr(file, "]") || !Blank(section) && (file = " " || file = "")
		Return ini

	Loop, Parse, file, `n, `r
	{
		If Blank(A_LoopField)
			Continue
		If (SubStr(A_LoopField, 1, 1) = "[")
		{
			section := SubStr(A_LoopField, 2, -1), ini[section] := {}
			Continue
		}
		If InStr(A_LoopField, "=")
			key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		Else key := A_LoopField, val := ""

		val := (SubStr(val, 1, 1) = """" && SubStr(val, 0, 1) = """") ? SubStr(val, 2, -1) : val
		ini[section][key] := val
	}
	Return ini
}

IniIntegrityCheck()
{
	local
	global vars

	LLK_Log("starting ini integrity-check")

	If !FileExist("ini" vars.poe_version " backup\")
		FileCopyDir, % "ini" vars.poe_version, % "ini" vars.poe_version " backup", 1
	Loop, Files, % "ini" vars.poe_version "\*.ini"
	{
		If InStr(A_LoopFileName, " backup")
			Continue
		FileRead, check, *P1200 %A_LoopFilePath%
		If !InStr(check, "[") || !InStr(check, "]")
		{
			FileRead, check, *P65001 %A_LoopFilePath%
			If (StrLen(check) > 0) && (!InStr(check, "[") || !InStr(check, "]"))
			{
				FileMove, % A_LoopFilePath, % StrReplace(A_LoopFilePath, ".ini", " backup.ini"), 1
				vars.ini_integrity .= (Blank(vars.ini_integrity) ? "" : "`n") "`t" StrReplace(A_LoopFilePath, ".ini", " backup.ini") " -> " A_LoopFilePath
			}
			Else
			{
				FileDelete, % A_LoopFilePath
				If InStr(check, "[") && InStr(check, "]")
					FileAppend, % check, % A_LoopFilePath, CP1200
			}
		}
	}
	IniWrite, % A_Now, % "ini" vars.poe_version "\file check.ini", check, timestamp
	If vars.ini_integrity
		IniWrite, % StrReplace(vars.ini_integrity, "`t"), % "ini" vars.poe_version "\file check.ini", errors

	LLK_Log("finished ini integrity-check")
}

LLK_ArraySort(array)
{
	local

	parse := {}, parse2 := []
	For index, val in array
		parse[val] := 1

	For key in parse
		parse2.Push(key)

	Return parse2
}

LLK_CloneObject(object)
{
	local

	For key, val in object
		If !IsNumber(key)
			is_array := 1

	If is_array
		new_object := []
	Else new_object := {}

	For key, val in object
		If !IsObject(val)
			new_object[key] := val
		Else new_object[key] := LLK_CloneObject(val)
	Return new_object
}

LLK_Error(ErrorMessage, restart := 0)
{
	MsgBox, % ErrorMessage
	If restart
		Reload
	ExitApp
}

LLK_FileCheck()
{
	For index, val in ["Atlas.ini", "Betrayal.json", "essences.json", "help tooltips.json", "lang_english.txt", "Map mods.ini", "Betrayal.ini", "timeless jewels\", "item info\", "leveling tracker\", "english\eldritch altars.json"]
		If FileExist("data\" val) ;delete old files (or ones that have been moved elsewhere)
		{
			FileDelete, data\%val%
			FileRemoveDir, data\%val%, 1
		}
	For index, val in ["necropolis.ahk"]
		If FileExist("modules\" val)
			FileDelete, modules\%val%
	If FileExist("data\english\necropolis.json")
		FileDelete, data\english\necropolis.json
	If FileExist("ini\altars.ini")
		FileMove, ini\altars.ini, ini\ocr - altars.ini, 1
	If !FileExist("data\") || !FileExist("data\global\") || !FileExist("data\english\") || !FileExist("data\english\UI.txt") || !FileExist("data\english\client.txt")
		Return 0
	Else Return 1
}

LLK_FilePermissionError(issue, folder)
{
	local

	MsgBox, % Lang_Trans("m_permission_error1", (issue = "create") ? 1 : 2) " " folder "`n`n" Lang_Trans("m_permission_error1", 3) "`n" Lang_Trans("m_permission_error1", 4) "`n`n" Lang_Trans("m_permission_error1", 5) "`n`n" Lang_Trans("m_permission_error1", 6)
}

LLK_FileRead(file, keep_case := 0, encoding := "65001")
{
	local

	FileRead, read, % (!Blank(encoding) ? "*P" encoding " " : "") file
	If !keep_case
		StringLower, read, read
	Return read
}

LLK_HasKey(object, value, InStr := 0, case_sensitive := 0, all_results := 0, recurse := 0)
{
	local

	If !IsObject(object) || Blank(value)
		Return
	parse := []
	For key, val in object
	{
		If (key = value) || InStr && InStr(key, value, case_sensitive) || recurse && IsObject(val) && LLK_HasKey(val, value, InStr, case_sensitive, all_results, recurse)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}
	}

	If all_results
		Return (parse.Count() ? parse : "")
	Return
}

LLK_HasRegex(object, regex, all_results := 0, check_key := 0)
{
	local

	If !IsObject(object)
		Return
	parse := []
	For key, val in object
		If RegExMatch(!check_key ? val : key, regex)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}

	If all_results && parse.Count()
		Return parse
}

LLK_HasVal(object, value, InStr := 0, case_sensitive := 0, all_results := 0, recurse := 0, check_decimals := 0) ; check_decimals is a band-aid fix for very specific use-cases where X and X.000[...] need to be distinguished
{
	local

	If !IsObject(object) || Blank(value)
		Return
	parse := []
	For key, val in object
		If (val = value) && !check_decimals || (val = value) && InStr(val, ".") && InStr(value, ".") && check_decimals || InStr && InStr(val, value, case_sensitive) || recurse && IsObject(val) && LLK_HasVal(val, value, InStr, case_sensitive, all_results, recurse, check_decimals)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}

	If all_results && parse.Count()
		Return parse
	Return
}

LLK_IniRead(file, section := "", key := "", default := "")
{
	IniRead, iniread, % file, % section, % key, % Blank(default) ? A_Space : default
	iniread := (iniread = " ") ? "" : iniread 	;work-around for situations where A_Space is taken literally instead of "blank" (blank return is hard-coded as %A_Space%, so % "" doesn't work)
	If !Blank(default) && Blank(iniread)		;IniRead's 'default' is only used if the key cannot be found in the ini-file
		Return default 					;if the key in the ini-file is blank, the target-variable will also be blank (instead of storing 'default')
	Else Return iniread
}

LLK_InRange(x, y, range)
{
	If (y >= x - range) && (y <= x + range)
		Return 1
	Else Return 0
}

LLK_InStrCount(string, character, delimiter := "")
{
	count := 0
	Loop, Parse, string, % delimiter
		If (A_Loopfield = character)
			count += 1
	Return count
}

LLK_IsBetween(var, x, y)
{
	If Blank(x) || Blank(y)
		Return
	x += 0, y += 0
	If (x > y)
		z := x, x := y, y := z
	If (x <= var) && (var <= y)
		Return 1
	Else Return 0
}

LLK_IsType(character, type)
{
	If (character = "")
		Return 0
	If (character = " ") && (type = "alpha" || type = "alnum")
		Return 1
	Else If character is %type%
		Return 1
}

LLK_Log(message)
{
	local
	global vars

	If !vars.logging
		Return

	FormatTime, logstamp, A_Now, yyyy-MM-dd`, HH:mm:ss
	FileAppend, % (InStr(message, "---") ? "`r`n" : "") "[" logstamp "] " message "`r`n", data\log.txt
}

LLK_PatternMatch(text, string, object, swap := 0, value := 1, case := 1) ;swap param switches the order around, val param determines if values or keys of the object are used
{
	local

	For index, val in object
	{
		val := value ? val : index
		check := swap ? val . string : string . val
		If InStr(text, check, case)
		{
			While (SubStr(val, 1, 1) = " ")
				val := SubStr(val, 2)
			Return InStr(val, " ") ? SubStr(val, 1, InStr(val, " ") - 1) : val
		}
	}
}

LLK_StringCase(string, mode := 0, title := 0)
{
	local

	If mode
		StringUpper, string, % string, % title ? "T" : ""
	Else StringLower, string, % string, % title ? "T" : ""
	Return string
}

LLK_StringCompare(string, needles)
{
	local

	For index, needle in needles
		If !Blank(needle) && (SubStr(string, 1, StrLen(needle)) = needle)
			Return 1
}

LLK_StringRemove(string, characters)
{
	local

	Loop, Parse, characters, `,
	{
		If (A_LoopField = "")
			Continue
		string := StrReplace(string, A_LoopField)
	}
	Return string
}

LLK_TrimDecimals(string)
{
	local

	If !InStr(string, ".")
		Return string
	While InStr("0.", (check := SubStr(string, 0))) && !Blank(check)
	{
		string := SubStr(string, 1, -1)
		If (check = ".")
			Break
	}
	Return string
}

LLK_Restart()
{
	Reload
	ExitApp
}

Loop()
{
	local
	global vars, settings

	If !WinExist("ahk_group poe_window")
		vars.client.closed := 1, vars.hwnd.poe_client := ""

	If WinExist("ahk_group poe_window")
	{
		vars.general.runcheck := A_TickCount
		If !vars.hwnd.poe_client
			If (vars.poe_version != CheckClient())
			{
				MsgBox, The wrong game-client is running. Start the correct game, then close this message.
				Return
			}
			Else vars.hwnd.poe_client := WinExist("ahk_class POEWindowClass")

		If vars.client.closed
		{
			If (vars.client.fullscreen = "true")
			{
				WinWaitActive, ahk_group poe_window
				Sleep, 4000
			}
			Init_client(), Init_GUI(), Init_screenchecks()
		}
		vars.client.closed := 0

		If settings.updater.update_check && (vars.update.1 = 0) && (A_TickCount - vars.general.startup >= vars.general.updatetick + 1200000)
		{
			UpdateCheck(1), vars.general.updatetick := A_TickCount - vars.general.startup
			If (vars.update.1 != 0)
				Gui, LLK_Panel: Color, % (vars.update.1 < 0) ? "Maroon" : "Green"
		}
	}

	If !WinExist("ahk_group poe_window") && (A_TickCount >= vars.general.runcheck + settings.general.kill[2]* 60000) && settings.general.kill[1]
		ExitApp
}

Loop_main()
{
	local
	global vars, settings
	static tick_helptooltips := 0, ClientFiller_count := 0, priceindex_count := 0, tick_recombination := 0, stashhover := {}, tick := 0

	Critical
	tick += 1

	MouseHover()
	If vars.leveltracker.skilltree_schematics.GUI && vars.leveltracker.skilltree_schematics.offsets
		Gui, skilltree_schematics: Show, % "NA x" (vars.leveltracker.skilltree_schematics.xPos := vars.general.xMouse - vars.leveltracker.skilltree_schematics.offsets.1) " y" (vars.leveltracker.skilltree_schematics.yPos := vars.general.yMouse - vars.leveltracker.skilltree_schematics.offsets.2)
	If Mod(tick, 2)
		Return

	If !vars.general.drag && vars.hwnd.lootfilter.main && WinActive("ahk_id " vars.hwnd.lootfilter.main) && (vars.general.wMouse = vars.hwnd.poe_client)
		&& !LLK_IsBetween(vars.general.xMouse, vars.lootfilter.xPos, vars.lootfilter.xPos + vars.lootfilter.width)
		WinActivate, % "ahk_id " vars.hwnd.poe_client

	If vars.cloneframes.editing && (vars.settings.active != "clone-frames") ;in case the user closes the settings menu without saving changes, reset clone-frames settings to previous state
	{
		vars.cloneframes.editing := ""
		Init_cloneframes()
	}

	If vars.hwnd.leveltracker_gemlinks.main && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.leveltracker_gemlinks.main)
	&& vars.general.cMouse && (check := LLK_HasVal(vars.hwnd.leveltracker_gemlinks, vars.general.cMouse)) && (vars.leveltracker.gemlinks.hover != SubStr(check, 0))
		LevelTracker_PobGemLinks("", SubStr(check, 0))

	If vars.hwnd.recombination.main && WinActive("ahk_id " vars.hwnd.recombination.main) && (vars.general.wMouse = vars.hwnd.poe_client)
	{
		tick_recombination += 1
		If (tick_recombination >= 3)
		{
			WinActivate, % "ahk_id " vars.hwnd.poe_client
			tick_recombination := 0
		}
	}

	If vars.hwnd.stash_index.main && WinExist("ahk_id " vars.hwnd.stash_index.main) && !WinActive("ahk_id " vars.hwnd.stash_index.main) && !WinActive("ahk_id " vars.hwnd.stash_picker.main)
	{
		priceindex_count += 1
		If (priceindex_count >= 3)
			Stash_PriceIndex("destroy"), priceindex_count := 0
	}
	Else priceindex_count := 0

	If settings.general.ClientFiller
	{
		If vars.hwnd.ClientFiller && !WinExist("ahk_id " vars.hwnd.ClientFiller) && !WinActive("ahk_exe code.exe") && WinActive("ahk_group poe_window")
			Gui_ClientFiller("show"), ClientFiller_count := 0
		Else If (ClientFiller_count = 3)
			Gui, ClientFiller: Hide
		Else If vars.hwnd.ClientFiller && WinExist("ahk_id " vars.hwnd.ClientFiller) && (!WinActive("ahk_group poe_ahk_window") || !WinExist("ahk_group poe_window")) && !WinActive("ahk_group snipping_tools")
			ClientFiller_count += 1
		Else ClientFiller_count := 0

		If vars.hwnd.poe_client && WinExist("ahk_id " vars.hwnd.poe_client) && WinActive("ahk_id " vars.hwnd.ClientFiller)
			WinActivate, % "ahk_id " vars.hwnd.poe_client
	}

	If vars.hwnd.maptracker_logs.sum_tooltip && WinExist("ahk_id " vars.hwnd.maptracker_logs.sum_tooltip) && !WinActive("ahk_id " vars.hwnd.maptracker_logs.sum_tooltip)
	{
		Gui, maptracker_tooltip: Destroy
		vars.hwnd.maptracker_logs.sum_tooltip := ""
	}

	If vars.hwnd.maptrackernotes_edit.main && WinExist("ahk_id " vars.hwnd.maptrackernotes_edit.main) && (WinActive("ahk_id " vars.hwnd.maptracker_logs.main) || WinActive("ahk_id " vars.hwnd.maptracker_dates.main))
		LLK_Overlay(vars.hwnd.maptrackernotes_edit.main, "destroy"), vars.hwnd.maptrackernotes_edit.main := ""

	If vars.hwnd.searchstrings_context && WinExist("ahk_id " vars.hwnd.searchstrings_context) && !WinActive("ahk_group poe_window") && !WinActive("ahk_id "vars.hwnd.searchstrings_context)
	{
		Gui, searchstrings_context: Destroy
		vars.hwnd.Delete("searchstrings_context")
	}
	If vars.hwnd.omni_context.main && WinExist("ahk_id "vars.hwnd.omni_context.main) && !WinActive("ahk_group poe_window") && !WinActive("ahk_id "vars.hwnd.omni_context.main)
	{
		Gui, omni_context: destroy
		vars.hwnd.Delete("omni_context")
	}

	If !WinActive("ahk_group poe_ahk_window") && !(settings.general.dev && WinActive("ahk_exe code.exe"))
	{
		vars.general.inactive += 1
		If (vars.general.inactive = 3)
		{
			Gui, omni_context: Destroy
			vars.hwnd.Delete("omni_context"), LLK_Overlay("hide"), LLK_Overlay(vars.hwnd.maptracker.main, "destroy"), Cloneframes_Hide()
		}
	}
	Iteminfo_Overlays()

	If vars.client.stream && !vars.general.drag && !WinExist("LLK-UI: notepad reminder") && !WinExist("LLK-UI: alarm set") && !WinExist("ahk_id " vars.hwnd.betrayal_setup.main) && WinActive("ahk_group poe_ahk_window") && vars.general.wMouse && LLK_HasVal(vars.hwnd, vars.general.wMouse,,,, 1) && !WinActive("ahk_id " vars.general.wMouse)
		WinActivate, % "ahk_id " vars.general.wMouse

	If !vars.general.drag && (vars.general.wMouse != vars.hwnd.settings.main) && vars.hwnd.stash.main && !vars.stash.wait && !vars.stash.enter && (vars.stash.GUI || WinExist("ahk_id " vars.hwnd.stash.main)) && WinActive("ahk_group poe_ahk_window") && LLK_IsBetween(vars.general.xMouse, vars.client.x, vars.client.x + vars.stash.width) && LLK_IsBetween(vars.general.yMouse, vars.client.y, vars.client.y + vars.client.h)
	{
		tab := vars.stash.active
		If !stashhover.exact || (vars.general.xMouse "," vars.general.yMouse != stashhover.exact)
		&& !(LLK_IsBetween(vars.general.xMouse, stashhover.x1, stashhover.x2) && LLK_IsBetween(vars.general.yMouse, stashhover.y1, stashhover.y2))
		{
			stashhover := {}
			For item, val in vars.stash[tab]
			{
				If !IsObject(val)
					Continue
				box := InStr(item, "tab_") ? vars.stash.buttons : vars.stash[tab].box
				exception1 := LLK_PatternMatch(item, "", ["potent", "powerful", "prime"]) ? 1 : 0, exception2 := LLK_PatternMatch(item, "", ["powerful", "prime"]) ? 1 : 0
				x1 := vars.client.x + val.coords.1, x2 := vars.client.x + val.coords.1 + (exception2 ? vars.client.h * (1/12) : box * (InStr(item, "tab_") ? 4.5 : 1))
				y1 := vars.client.y + val.coords.2, y2 := vars.client.y + val.coords.2 + (exception1 ? vars.client.h * (1/12) : box)
				If LLK_IsBetween(vars.general.xMouse, x1, x2) && LLK_IsBetween(vars.general.yMouse, y1, y2)
				{
					stashhover := {"x1": x1, "x2": x2, "y1": y1, "y2": y2}
					vars.stash.hover := item, Stash("refresh")
					Break
				}
			}
			If Blank(stashhover.x1) && vars.stash.hover
					vars.stash.hover := "", Stash("refresh")
			stashhover.exact := vars.general.xMouse "," vars.general.yMouse
		}
	}
	Else If IsObject(stashhover) && !vars.hwnd.stash.main
		stashhover := ""
	Else If WinActive("ahk_group poe_ahk_window") && vars.stash.hover && !vars.stash.enter && !LLK_IsBetween(vars.general.xMouse, vars.client.x, vars.client.x + vars.stash.width)
		vars.stash.hover := "", Stash("refresh")

	If settings.general.hide_toolbar && WinActive("ahk_group poe_ahk_window")
	{
		If vars.general.wMouse && vars.hwnd.LLK_panel.main && !WinExist("ahk_id " vars.hwnd.LLK_panel.main) && LLK_IsBetween(vars.general.xMouse, vars.toolbar.x, vars.toolbar.x2) && LLK_IsBetween(vars.general.yMouse, vars.toolbar.y, vars.toolbar.y2)
			LLK_Overlay(vars.hwnd.LLK_panel.main, "show")
		Else If !vars.toolbar.drag && !GetKeyState(vars.hotkeys.tab, "P") && WinExist("ahk_id " vars.hwnd.LLK_panel.main) && !(LLK_IsBetween(vars.general.xMouse, vars.toolbar.x, vars.toolbar.x2) && LLK_IsBetween(vars.general.yMouse, vars.toolbar.y, vars.toolbar.y2))
			LLK_Overlay(vars.hwnd.LLK_panel.main, "hide")
	}

	If vars.general.cMouse
		check_help := LLK_HasVal(vars.hwnd.help_tooltips, vars.general.cMouse), check := (SubStr(check_help, 1, InStr(check_help, "_") - 1)), control := StrReplace(SubStr(check_help, InStr(check_help, "_") + 1), "|"), database := IsObject(vars.help[check][control]) ? vars.help : vars.help2

	tick_helptooltips += 1
	If !Mod(tick_helptooltips, 3) || check_help
	{
		If check_help && (vars.general.active_tooltip != vars.general.cMouse) && (database[check][control].Count() || InStr(control, "update changelog") || check = "lab" && !(vars.lab.mismatch || vars.lab.outdated) && InStr(control, "square") || check = "donation" && vars.settings.donations[control].2.Count() || check = "lootfilter" && InStr(control, "tooltip")) && !WinExist("ahk_id "vars.hwnd.screencheck_info.main)
			Gui_HelpToolTip(check_help)
		Else If (vars.general.drag || !check_help || WinExist("ahk_id "vars.hwnd.screencheck_info.main)) && WinExist("ahk_id "vars.hwnd.help_tooltips.main)
			LLK_Overlay(vars.hwnd.help_tooltips.main, "destroy"), vars.general.active_tooltip := "", vars.hwnd.help_tooltips.main := ""
		tick_helptooltips := 0
	}

	If WinExist("ahk_id "vars.hwnd.legion.main)
		Legion_Hover()
	Else If !WinExist("ahk_id "vars.hwnd.legion.main) && WinExist("ahk_id "vars.hwnd.legion.tooltip)
		LLK_Overlay(vars.hwnd.legion.tooltip, "destroy"), vars.legion.tooltip := ""

	If !vars.tooltip.wait
	{
		For key, val in vars.tooltip ;timed tooltips are stored in this object and destroyed via this loop
			If val && (val <= A_TickCount)
				LLK_Overlay(key, "destroy"), remove_tooltips .= !remove_tooltips ? key : ";" key

		Loop, Parse, remove_tooltips, `; ;separate loop to delete entries from the vars.tooltip object without interfering with the for-loop above
			vars.tooltip.Delete(A_LoopField)
		remove_tooltips := ""
	}

	If !vars.general.gui_hide && (WinActive("ahk_group poe_ahk_window") || (settings.general.dev && WinActive("ahk_exe code.exe"))) && !vars.client.closed && !WinActive("ahk_id "vars.hwnd.leveltracker_screencap.main) && !WinActive("ahk_id "vars.hwnd.snip.main) && !WinActive("ahk_id "vars.hwnd.cheatsheet_menu.main) && !WinActive("ahk_id "vars.hwnd.searchstrings_menu.main) && !WinActive("ahk_id "vars.hwnd.notepad.main) && !WinActive("ahk_id " vars.hwnd.alarm.main) && !(vars.general.inactive && WinActive("ahk_id "vars.hwnd.settings.main))
	{
		If vars.general.inactive
		{
			vars.general.inactive := 0
			LLK_Overlay("show")
		}
		Leveltracker_Fade()
		location := vars.log.areaID ;short-cut variable
		If (vars.cloneframes.enabled
		&& ((settings.cloneframes.pixelchecks && Screenchecks_PixelSearch("gamescreen")) || !settings.cloneframes.pixelchecks)) ;user is on gamescreen, or auto-toggle is disabled
		&& (!settings.cloneframes.hide || (settings.cloneframes.hide && !LLK_StringCompare(location, ["hideout"]) && !InStr(location, "_town") && !InStr(location, "heisthub") && (location != "login"))) ;outside hideout/town/login, or auto-toggle is disabled
		&& !vars.sanctum.active
		|| (vars.settings.active = "clone-frames") ;accessing the clone-frames section of the settings
			Cloneframes_Show()
		Else Cloneframes_Hide()
	}
}

MouseHover()
{
	local
	global vars, settings

	MouseGetPos, xPos, yPos, win_hover, control_hover, 2
	vars.general.xMouse := xPos, vars.general.yMouse := yPos
	vars.general.wMouse := Blank(win_hover) ? 0 : win_hover, vars.general.cMouse := Blank(control_hover) ? 0 : control_hover
}

Resolution_check()
{
	local
	global vars, settings
	poe_height := vars.client.h

	If vars.general.buggy_resolutions.HasKey(vars.client.h) || !vars.general.supported_resolutions.HasKey(vars.client.h)
	{
		If vars.general.buggy_resolutions.HasKey(poe_height)
		{
			text =
			(LTrim
			Unsupported resolution detected!

			The script has detected a vertical screen-resolution of %poe_height% pixels which has caused issues with the game-client and the script in the past.

			I have decided to end support for this resolution.
			You have to run the client with a custom resolution, which you can set up in the following window.
			)
		}
		Else If !vars.general.supported_resolutions.HasKey(vars.client.h)
		{
			text =
			(LTrim
			Unsupported resolution detected!

			The script has detected a vertical screen-resolution of %poe_height% pixels which is not supported.

			You have to run the client with a custom resolution, which you can set up in the following window.
			)
		}
		MsgBox, % text
		vars.general.safe_mode := 1
		settings_menu("general")
		sleep, 2000
		Loop
		{
			If !WinExist("ahk_id " vars.hwnd.settings.main)
			{
				MsgBox, The script will now shut down.
				ExitApp
			}
			Sleep, 100
		}
	}
}

RightClick()
{
	local
	global vars, settings

	If GetKeyState("LButton", "P")
		Return
	vars.system.click := 2
	SendInput, {LButton}
	KeyWait, RButton
	vars.system.click := 1
}

SnipGuiClose()
{
	local
	global vars, settings

	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.snip.main
	vars.snip := {"x": x, "y": y, "w": w, "h": h}
	Gui, snip: Destroy
	vars.hwnd.Delete("snip")
}

Startup()
{
	local
	global vars, settings

	ini := IniBatchRead("ini" vars.poe_version "\config.ini", "settings")
	settings.general := {"kill": [!Blank(check := ini.settings["kill script"]) ? check : 1, !Blank(check1 := ini.settings["kill script"]) ? check1 : 1]}
	settings.general.dev := !Blank(check := ini.settings["dev"]) ? check : 0, settings.general.capslock := !Blank(check := ini.settings["enable capslock-toggling"]) ? check : 1
	SetStoreCapsLockMode, % settings.general.capslock ;for people who have something bound to CapsLock
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
	LLK_Log("initialized GDI+")

	;get widths/heights of window-borders to correctly offset overlays in windowed mode
	SysGet, xborder, 32
	SysGet, yborder, 33
	SysGet, caption, 4
	vars.system.xborder := xborder, vars.system.yborder := yborder, vars.system.caption := caption

	;create window-groups for easier window detection
	GroupAdd, snipping_tools, ahk_exe ScreenClippingHost.exe
	GroupAdd, snipping_tools, ahk_exe ShellExperienceHost.exe
	GroupAdd, snipping_tools, ahk_exe SnippingTool.exe

	GroupAdd, poe_window, ahk_class POEWindowClass
	GroupAdd, poe_window, ahk_exe GeForceNOW.exe

	GroupAdd, poe_ahk_window, ahk_class POEWindowClass
	GroupAdd, poe_ahk_window, ahk_class AutoHotkeyGUI
	GroupAdd, poe_ahk_window, ahk_exe GeForceNOW.exe

	If settings.general.dev
		GroupAdd, poe_ahk_window, ahk_exe code.exe ;treat VS Code's window as a client

	LLK_Log("set up window-groups, measured window-borders: " xborder ", " yborder ", " caption)

	If !LLK_FileCheck() ;check if important files are missing
		LLK_Error("Critical files are missing. Make sure you have installed the script correctly.")

	If !FileExist("ini\") ;ini-folder is required regardless of which PoE-version is being played
		FileCreateDir, ini\

	Loop, Parse, % "ini" vars.poe_version ", exports, img\GUI\skill-tree, cheat-sheets" vars.poe_version, `,, %A_Space%
	{
		If !FileExist(A_LoopField "\") ;create folder
			FileCreateDir, % A_LoopField "\"
		If !FileExist(A_LoopField "\") && !file_error ;check if the folder was created successfully
			file_error := 1, LLK_FilePermissionError("create", A_ScriptDir "\" A_LoopField)
	}

	Init_client()
	Init_lang()

	vars.hwnd.poe_client := WinExist("ahk_group poe_window") ;save the client's handle
	vars.general.runcheck := A_TickCount ;save when the client was last running (for purposes of killing the script after X minutes)

	;get the location of the client.txt file
	WinGet, poe_log_file, ProcessPath, ahk_group poe_window
	If FileExist(SubStr(poe_log_file, 1, InStr(poe_log_file, "\",, 0)) "logs\Client.txt")
		poe_log_file := SubStr(poe_log_file, 1, InStr(poe_log_file, "\",, 0)) "logs\Client.txt"
	Else poe_log_file := SubStr(poe_log_file, 1, InStr(poe_log_file, "\",, 0)) "logs\Kakaoclient.txt"
	LLK_Log("game's log-file: " poe_log_file)

	If FileExist(poe_log_file) ;parse client.txt at startup to get basic location info
		vars.log.file_location := poe_log_file, LLK_Log("found game's log-file"), Init_log(), LLK_Log("accessed required information from log-file")
	Else vars.log.file_location := 0, LLK_Log("couldn't find game's log-file")

	Gui_ClientFiller()
}

StrMatch(string, check, match_length := 0)
{
	local

	If (SubStr(string, 1, StrLen(check)) = check) && (match_length && StrLen(string) = StrLen(check) || !match_length)
		Return 1
}

UpdateCheck(timer := 0) ;checks for updates: timer param refers to whether this function was called via the timer or during script-start
{
	local
	global vars, settings, Json

	vars.update := [0], update := vars.update

	If !FileExist("update\")
		FileCreateDir, update\
	update.1 := !FileExist("update\") ? -2 : update.1
	FileDelete, update\update.* ;delete any leftover files
	update.1 := FileExist("update\update.*") ? -1 : update.1 ;error code -1 = delete-permission
	Loop, Files, update\lailloken-ui-*, D
		FileRemoveDir, % A_LoopFileLongPath, 1 ;delete any leftover folders
	update.1 := FileExist("update\lailloken-ui-*") ? -1 : update.1 ;error code -1 = delete-permission
	FileAppend, 1, update\update.test
	update.1 := !FileExist("update\update.test") ? -2 : update.1 ;error code -2 = write-permission
	FileDelete, update\update.test
	update.1 := FileExist("update\update.test") ? -1 : !FileExist("data\versions.json") ? -3 : update.1 ;error code -3 = bricked install (version-file not found)
	If (update.1 < 0)
	{
		If InStr("2", timer)
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
		Return
	}
	versions_local := Json.Load(LLK_FileRead("data\versions.json")) ;load local versions
	If versions_local.HasKey("hotfix")
		versions_local._release.1 .= "." . (versions_local.hotfix < 10 ? "0" : "") . versions_local.hotfix
	Loop, Files, % "update\update_*.zip"
	{
		version := SubStr(A_LoopFileName, InStr(A_LoopFileName, "_") + 1), version := StrReplace(version, ".zip")
		If Blank(version) || (version <= versions_local["_release"].1)
			FileDelete, % A_LoopFileLongPath
	}

	FileDelete, data\version_check.json
	Try version_check := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/versions.json")
	update.1 := !InStr(version_check, """_release""") ? -4 : update.1 ;error-code -4 = version-list download failed
	If (update.1 = -4)
	{
		If InStr("2", timer)
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
		Return
	}
	versions_live := Json.Load(version_check) ;load version-list into object
	If versions_live.HasKey("hotfix")
		versions_live._release.1 .= "." . (versions_live.hotfix < 10 ? "0" : "") . versions_live.hotfix
	vars.updater := {"version": [versions_local._release.1, UpdateParseVersion(versions_local._release.1)], "latest": [versions_live._release.1, UpdateParseVersion(versions_live._release.1)]}
	vars.updater.skip := LLK_IniRead("ini" vars.poe_version "\config.ini", "versions", "skip", 0)

	Try changelog_check := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/changelog.json")
	If (SubStr(changelog_check, 1, 1) . SubStr(changelog_check, 0) = "[]")
	{
		vars.updater.changelog := Json.Load(changelog_check)
		FileDelete, data\changelog.json
		If !FileExist("data\changelog.json")
			FileAppend, % changelog_check, data\changelog.json
	}
	Else
	{
		vars.updater.changelog := Json.Load(LLK_FileRead("data\changelog.json"))
		If !LLK_HasVal(vars.updater.changelog, vars.updater.version.1,,,, 1)
			vars.updater.changelog.InsertAt(1, [[vars.updater.version.2, vars.updater.version.1], "changelog download failed"])
	}

	If (timer != 2) && (vars.updater.skip = vars.updater.latest.1)
		Return

	If InStr("01", timer) && (versions_live._release.1 > versions_local._release.1)
	{
		vars.update := [1]
		Return
	}
	Else If (timer = 2)
	{
		Gui, update_download: New, -Caption -DPIScale +LastFound +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDdownload
		Gui, update_download: Color, Black
		Gui, update_download: Add, Progress, range0-10 HWNDhwnd BackgroundBlack cGreen, 0
		Gui, update_download: Show
		UpdateDownload(hwnd)
		branch := InStr(versions_live._release.2, "/main.zip") ? "main" : "beta"
		vars.updater.target_version := [LLK_IniRead("ini\config.ini", "versions", "apply update")]
		Loop, Parse, % vars.updater.target_version.1, % "."
			vars.updater.target_version.2 .= (A_Index = 3) ? (A_LoopField < 10 ? "0" : "") A_LoopField : A_LoopField

		LLK_Log("starting update to " vars.updater.target_version.1)

		If !FileExist("update\update_" vars.updater.target_version.2 ".zip")
			UrlDownloadToFile, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/tags/v" vars.updater.target_version.1 ".zip", % "update\update_" vars.updater.target_version.2 ".zip"
		If ErrorLevel || !FileExist("update\update_" vars.updater.target_version.2 ".zip")
			vars.update := [-5, vars.updater.target_version.1] ;error-code -5 = download of zip-file failed
		If (vars.update.1 >= 0)
		{
			FileCopyDir, % "update\update_" vars.updater.target_version.2 ".zip", update, 1
			If ErrorLevel || !FileExist("update\lailloken-ui-*")
				vars.update := [-6, vars.updater.target_version.1] ;error-code -6 = zip-file couldn't be extracted
		}
		If (vars.update.1 >= 0)
		{
			SplitPath, A_ScriptFullPath,, path
			Loop, Files, update\Lailloken-ui-*, D
				Loop, Files, % A_LoopFilePath "\*", FD
				{
					If InStr(FileExist(A_LoopFileLongPath), "D")
						FileMoveDir, % A_LoopFileLongPath, % path "\" A_LoopFileName, 2
					Else FileMove, % A_LoopFileLongPath, % path "\" A_LoopFileName, 1
					If ErrorLevel
						vars.update := [-6, vars.updater.target_version.1]
				}
		}

		If (vars.update.1 >= 0)
		{
			FileDelete, data\version_check.json
			IniDelete, % "ini\config.ini", versions, apply update
			LLK_Log("finished update to " vars.updater.target_version.1)
			Reload
			ExitApp
		}
		If (vars.update.1 < 0)
		{
			SetTimer, UpdateDownload, Delete
			Gui, update_download: Destroy
			IniWrite, updater, % "ini" vars.poe_version "\config.ini", versions, reload settings
			LLK_Log("failed update to " vars.updater.target_version.1)
			Return
		}
	}
}

UpdateDownload(mode := "")
{
	local
	static dl_bar := 0, HWND_bar

	If (mode = "reset")
	{
		dl_bar := 0
		GuiControl,, % HWND_bar, % dl_bar
		GuiControl, movedraw, % HWND_bar
		Return
	}
	If (mode)
	{
		HWND_bar := mode
		SetTimer, UpdateDownload, 500
	}

	dl_bar += (dl_bar = 10) ? -10 : 1
	GuiControl,, % HWND_bar, % dl_bar
}

UpdateParseVersion(string)
{
	local

	Loop, Parse, string
	{
		If (A_Index = 1)
			string := ""
		string .= (A_Index = 1) ? "1." : (A_Index = 3) ? A_LoopField "." : (InStr("47", A_Index) && A_LoopField = "0") ? "" : (A_LoopField = ".") ? " (hotfix " : A_LoopField
	}
	string .= InStr(string, "(hotfix") ? ")" : ""
	Return string
}
