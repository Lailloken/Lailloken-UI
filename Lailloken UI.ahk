#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
#Hotstring NoMouse
#Hotstring EndChars `n
#MaxThreads 255
#MaxMem 1024
#Include %A_ScriptDir%
#Include data\Class_CustomFont.ahk
#Include data\External Functions.ahk
#Include data\JSON.ahk

SetWorkingDir %A_ScriptDir%
SetControlDelay, -1
SetWinDelay, -1
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "RightClick")
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

vars := {}
If LLK_IniRead("ini\config.ini", "versions", "apply update", 0)
	UpdateCheck(2)
Else If LLK_IniRead("ini\config.ini", "settings", "update auto-check", 0)
	UpdateCheck()
IniDelete, ini\config.ini, versions, apply update
Init_vars()
Startup()
Init_screenchecks()
Init_general()
Init_betrayal()
Init_cheatsheets()
Init_cloneframes()
If WinExist("ahk_exe GeForceNOW.exe") || WinExist("ahk_exe boosteroid.exe")
	Init_geforce()
Init_hotkeys()
Init_iteminfo()
Init_legion()
Init_mapinfo()
Init_searchstrings()
Init_leveltracker()
Init_maptracker()
Init_qol()
Resolution_check()

SetTimer, Loop, 1000
SetTimer, Loop_main, 100

vars.system.timeout := 0
If !settings.general.dev
	WinWaitActive, ahk_group poe_window
Else
{
	WinWaitActive, ahk_group poe_ahk_window
	SoundBeep, 100
}

Init_GUI()
SetTimer, LogLoop, 1000

If LLK_IniRead("ini\config.ini", "Versions", "reload settings")
{
	Settings_menu(LLK_IniRead("ini\config.ini", "Versions", "reload settings"))
	IniDelete, ini\config.ini, Versions, reload settings
}
Return

#Include modules\betrayal-info.ahk
#Include modules\cheat sheets.ahk
#Include modules\client log.ahk
#Include modules\clone-frames.ahk
#Include modules\GUI.ahk
#Include modules\hotkeys.ahk
#Include *i modules\hotkeys custom.ahk
#Include modules\item-checker.ahk
#Include modules\leveling tracker.ahk
#Include modules\map-info.ahk
#Include modules\map tracker.ahk
#Include modules\omni-key.ahk
#Include modules\qol tools.ahk
#Include modules\search-strings.ahk
#Include modules\seed-explorer.ahk
#Include modules\settings menu.ahk
#Include modules\screen-checks.ahk


Blank(var)
{
	If (var = "")
		Return 1
}

ClipRGB()
{
	local

	If !(StrLen(Clipboard) = 6 || (StrLen(Clipboard) = 7 && SubStr(Clipboard, 1, 1) = "#"))
	{
		LLK_ToolTip("invalid rgb-code in clipboard", 1.5,,,, "red")
		Return
	}
	Return (StrLen(Clipboard) = 7) ? SubStr(Clipboard, 2) : Clipboard
}

CreateRegex(string, database)
{
	local

	If Blank(string) || !IsObject(database) || (StrLen(string) < 4)
		Return 0
	While (A_Index <= StrLen(string))
	{
		check := SubStr(string, 1, A_Index), matches := 0
		For index, val in database
			matches += StrMatch(val, check) ? 1 : 0
		If (matches < 2)
			Return check
	}
	Return string
}

DummyGUI(hwnd) ;used for A_Gui checks: "If (A_Gui = hwnd)" doesn't work reliably if the hwnd is blank, so this function returns -1 instead
{
	local

	If Blank(hwnd)
		Return -1
	Else Return hwnd
}

Exit()
{
	local
	global vars, settings, Json

	Gdip_Shutdown(pToken)
	vars.log.file.Close()
	
	If (vars.system.timeout != 0) ;script exited before completing startup routines: return here to prevent storing corrupt/incomplete data in ini-files
		Return
	If (Json.Dump(vars.betrayal.board) != "{}")
	{
		IniRead, ini, ini\betrayal info.ini, settings, board
		If (ini != Json.Dump(vars.betrayal.board))
			IniWrite, % """" Json.Dump(vars.betrayal.board) """", ini\betrayal info.ini, settings, board
	}
	
	If IsNumber(vars.leveltracker.timer.current_split) && (vars.leveltracker.timer.current_split != LLK_IniRead("ini\leveling tracker.ini", "current run", "time", 0))
		IniWrite, % vars.leveltracker.timer.current_split, ini\leveling tracker.ini, current run, time

	If vars.maptracker.map.date_time
		MaptrackerSave()
}

FormatSeconds(seconds, mode := 1)  ; Convert the specified number of seconds to hh:mm:ss format.
{
	local

	time := 19990101  ; *Midnight* of an arbitrary date.
	time += seconds, seconds
	FormatTime, time, %time%, HH:mm:ss
	While !mode && InStr("0:", SubStr(time, 1, 1)) && (StrLen(time) > 4) ;remove leading 0s and colons
		time := SubStr(time, 2)
	return time
    /*
    ; Unlike the method used above, this would not support more than 24 hours worth of seconds:
    FormatTime, hmmss, %time%, h:mm:ss
    return hmmss
    */
}

LLK_HasKey(object, value, InStr := 0, case_sensitive := 0, all_results := 0)
{
	local

	parse := []
	For key, val in object
	{
		If (key = value) || InStr && InStr(key, value, case_sensitive)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}
	}

	If all_results && parse.Count()
		Return parse
	Return
}

LLK_HasVal(object, value, InStr := 0, case_sensitive := 0, all_results := 0)
{
	local

	If !IsObject(object) || Blank(value)
		Return 0
	parse := []
	For key, val in object
	{
		If (val = value) || InStr && InStr(val, value, case_sensitive)
		{
			If !all_results
				Return key
			Else parse.Push(key)
		}
	}

	If all_results && parse.Count()
		Return parse
	Return 0
}

HelpToolTip(HWND_key)
{
	local
	global vars, settings

	WinGetPos,, y,, h, % "ahk_id "vars.hwnd.help_tooltips[HWND_key]
	HWND_key := StrReplace(HWND_key, "|"), check := SubStr(HWND_key, 1, InStr(HWND_key, "_") - 1), control := SubStr(HWND_key, InStr(HWND_key, "_") + 1)
	HWND_checks := {"cheatsheets": "cheatsheet_menu", "maptracker": "maptracker_logs", "notepad": 0, "leveltracker": "leveltracker_screencap", "snip": 0, "lab": 0, "searchstrings": "searchstrings_menu" ;cont
	, "updater": "update_notification", "geartracker": 0, "seed-explorer": "legion"}
	If (check != "settings")
		WinGetPos, xWin, yWin, wWin,, % "ahk_id "vars.hwnd[(HWND_checks[check] = 0) ? check : HWND_checks[check]].main
	tooltip_width := (check = "settings") ? vars.settings.w - vars.settings.wSelection : (wWin - 2) * (check = "cheatsheets" && vars.cheatsheet_menu.type = "advanced" || check = "seed-explorer" ? 0.5 : 1)
	If !tooltip_width
		Return
	Gui, New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDtooltip
	Gui, %tooltip%: Color, 202020
	Gui, %tooltip%: Margin, 0, 0
	Gui, %tooltip%: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.help_tooltips.main, vars.hwnd.help_tooltips.main := tooltip, vars.general.active_tooltip := vars.general.cMouse
	
	;LLK_PanelDimensions(vars.help[check][control], settings.general.fSize, width, height,,, 0)
	If (control = "update changelog")
		For index0, val in vars.updater.changelog
		{
			If (val.1.2 < vars.updater.version.1)
				Continue
			For index, text in val
			{
				If (A_Index = 1)
					log := ""
				log .= (A_Index = 1) ? text.1 ":" : "`n" text
			}
			Gui, %tooltip%: Add, Text, % "x0 y-1000 Hidden w"tooltip_width - settings.general.fWidth, % log
			Gui, %tooltip%: Add, Text, % (A_Index = 1 ? "Section x0 y0" : "Section xs") " Border BackgroundTrans hp+"settings.general.fWidth " w"tooltip_width, % ""
			Gui, %tooltip%: Add, Text, % "Center HWNDhwnd xp+"settings.general.fWidth/2 " yp+"settings.general.fWidth/2 " w"tooltip_width - settings.general.fWidth, % log
			ControlGetPos,, y0,, h0,, ahk_id %hwnd%
			If (y0 + h0 >= vars.monitor.h * 0.85)
				Break
		}
	Else
		For index, text in vars.help[check][control]
		{
			font := InStr(text, "(/bold)") ? "bold" : "", font .= InStr(text, "(/underline)") ? (font ? " " : "") "underline" : "", font := !font ? "norm" : font
			Gui, %tooltip%: Font, % font
			Gui, %tooltip%: Add, Text, % "x0 y-1000 Hidden w"tooltip_width - settings.general.fWidth, % StrReplace(text, "(/bold)")
			Gui, %tooltip%: Add, Text, % (A_Index = 1 ? "Section x0 y0" : "Section xs") " Border BackgroundTrans hp+"settings.general.fWidth " w"tooltip_width, % ""
			Gui, %tooltip%: Add, Text, % "Center xp+"settings.general.fWidth/2 " yp+"settings.general.fWidth/2 " w"tooltip_width - settings.general.fWidth, % StrReplace(text, "(/bold)")
		}
	Gui, %tooltip%: Show, NA AutoSize x10000 y10000
	WinGetPos,,, width, height, ahk_id %tooltip%
	xPos := (check = "settings") ? vars.settings.x + vars.settings.wSelection - 1 : xWin, yPos := (control = "update changelog") && (height > vars.monitor.h - (y + h)) ? "Center" : (y + h + height + 1 > vars.monitor.y + vars.monitor.h) ? y - height : y + h + 1
	Gui, %tooltip%: Show, % "NA x"xPos " y"(InStr("notepad, lab, leveltracker, snip, searchstrings", check) ? yWin : yPos)
	LLK_Overlay(hwnd_old, "destroy")
}

Init_client()
{
	local
	global vars, settings
	
	If !WinExist("ahk_exe GeForceNOW.exe") && !WinExist("ahk_exe boosteroid.exe") ;if client is not a streaming client
	{
		;load client-config location and double-check
		IniRead, poe_config_file, ini\config.ini, Settings, PoE config-file, %A_MyDocuments%\My Games\Path of Exile\production_Config.ini
		If !FileExist(poe_config_file)
		{
			FileSelectFile, poe_config_file, 3, %A_MyDocuments%\My Games\\production_Config.ini, Please locate the 'production_Config.ini' file which is stored in the same folder as loot-filters, config files (*.ini)
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
			IniWrite, "%poe_config_file%", ini\config.ini, Settings, PoE config-file
		}
		Else IniWrite, "%poe_config_file%", ini\config.ini, Settings, PoE config-file
		
		vars.system.config := poe_config_file
		
		;check the contents of the client-config
		FileRead, poe_config_check, % poe_config_file
		If (poe_config_check = "")
			LLK_Error("Cannot read the PoE config-file. Please restart the game-client and then the script. If you get this error repeatedly, please report the issue.`n`nError-message (for reporting): PoE-config returns empty")
		
		;check if the client is currently running in exclusive-fullscreen mode
		exclusive_fullscreen := InStr(poe_config_check, "`nfullscreen=true") ? "true" : InStr(poe_config_check, "fullscreen=false") ? "false" : ""
		If (exclusive_fullscreen = "")
		{
			IniDelete, ini\config.ini, Settings, PoE config-file
			LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of exclusive fullscreen", 1)
		}
		Else If (exclusive_fullscreen = "true")
			LLK_Error("The game-client is set to exclusive fullscreen.`nPlease set it to windowed fullscreen.")

		;check if the client is currently running in fullscreen or windowed mode
		vars.client.fullscreen := InStr(poe_config_check, "borderless_windowed_fullscreen=true") ? "true" : InStr(poe_config_check, "borderless_windowed_fullscreen=false") ? "false" : ""
		If (vars.client.fullscreen = "")
		{
			IniDelete, ini\config.ini, Settings, PoE config-file
			LLK_Error("Cannot read the PoE config-file.`n`nThe script will restart and reset the first-time setup. If you still get this error repeatedly, please report the issue.`n`nError-message (for reporting): Cannot read state of borderless fullscreen", 1)
		}
		
		;check if client's window settings have changed since the previous session
		IniRead, fullscreen_last, ini\config.ini, Settings, fullscreen, % A_Space
		If (fullscreen_last != vars.client.fullscreen)
		{
			IniWrite, % vars.client.fullscreen, ini\config.ini, Settings, fullscreen
			IniWrite, 0, ini\config.ini, Settings, remove window-borders
			IniDelete, ini\config.ini, Settings, custom-resolution
			IniDelete, ini\config.ini, Settings, custom-width
		}
	}
	Else IniWrite, 0, ini\config.ini, Settings, enable custom-resolution ;disable custom resolutions for streaming clients
	
	local xScreenOffset_monitor, yScreenOffSet_monitor, width_native, height_native, x, y
	;determine native resolution of the active monitor
	WinGetPos, x, y,,, ahk_group poe_window
	Gui, Test: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption
	WinSet, Trans, 0
	Gui, Test: Show, % "NA x" x " y" y " Maximize"
	WinGetPos, xScreenOffset_monitor, yScreenOffSet_monitor, width_native, height_native
	Gui, Test: Destroy
	;WinGetPos, x, y, w, h, ahk_class Shell_TrayWnd
	vars.monitor := {"x": xScreenOffset_monitor, "y": yScreenOffSet_monitor, "w": width_native, "h": height_native} ;, "hTask": h, "wTask": w, "xTask": x, "yTask": y}
	
	vars.client.docked := LLK_IniRead("ini\config.ini", "Settings", "window-position", "left")
	vars.client.borderless := (vars.client.fullscreen = "true") ? 0 : LLK_IniRead("ini\config.ini", "Settings", "remove window-borders", 0)
	vars.client.customres := [LLK_IniRead("ini\config.ini", "Settings", "custom-width"), LLK_IniRead("ini\config.ini", "Settings", "custom-resolution")]
	If IsNumber(vars.client.customres.1) && IsNumber(vars.client.customres.2)
	{
		If (vars.client.customres.1 > vars.monitor.w) || (vars.client.customres.2 > vars.monitor.h) ;check resolution in case of manual .ini edit
		{
			MsgBox, Incorrect settings for forced resolution detected.`nThe script will reset the settings and restart.
			IniWrite, % vars.monitor.h, ini\config.ini, Settings, custom-resolution
			IniWrite, % vars.monitor.w, ini\config.ini, Settings, custom-width
			Reload
			ExitApp
		}
		
		If (vars.client.fullscreen = "true")
			WinMove, ahk_group poe_window,, % vars.monitor.x, % vars.monitor.y, % vars.client.customres.1, % vars.client.customres.2
		Else
		{
			WinSet, Style, % (vars.client.borderless ? "-" : "+") "0x40000", ahk_group poe_window ;add resize-borders
			WinSet, Style, % (vars.client.borderless ? "-" : "+") "0xC00000", ahk_group poe_window ;add caption
			If !vars.client.borderless
				WinMove, ahk_group poe_window,,, % vars.monitor.y, % vars.client.customres.1 + 2* vars.system.xborder, % vars.client.customres.2 + vars.system.caption + 2* vars.system.yborder
			Else WinMove, ahk_group poe_window,,, % vars.monitor.y, % vars.client.customres.1, % vars.client.customres.2
		}
	}
	
	local x, y, w, h, xTarget

	WinGetPos, x, y, w, h, ahk_group poe_window ;get the initial offsets, widths, and heights (separately saved as x0, y0, etc. because of potential recalculation later on)
	vars.client.x_offset := (vars.client.fullscreen = "false" && !vars.client.borderless) ? vars.system.xborder : 0
	xTarget := (vars.client.docked = "left") ? vars.monitor.x - vars.client.x_offset : (vars.client.docked = "center") ? vars.monitor.x + (vars.monitor.w - w) / 2 : vars.monitor.x + vars.monitor.w - (w - vars.client.x_offset)
	If (vars.client.fullscreen = "false")
	{
		WinMove, ahk_group poe_window,, % xTarget, % vars.monitor.y
		WinGetPos, x, y, w, h, ahk_group poe_window
	}
	vars.client.x0 := x, vars.client.y0 := y, vars.client.x := x, vars.client.y := y
	vars.client.w0 := w, vars.client.h0 := h, vars.client.w := w, vars.client.h := h

	;apply overlay offsets if client is running in bordered windowed mode
	If (vars.client.fullscreen = "false") && !vars.client.borderless
	{
		vars.client.w -= 2* vars.system.xborder
		vars.client.h := vars.client.h - vars.system.caption - 2* vars.system.yborder
		vars.client.x += vars.system.xborder
		vars.client.y += vars.system.caption + vars.system.yborder
	}
	vars.client.xc := vars.client.x + vars.client.w//2 - 1, vars.client.yc := vars.client.y + vars.client.h//2 - 1 ;client's horizontal and vertical centers

	IniRead, iniread, data\Resolutions.ini
	Loop, Parse, iniread, `n
	{
		If (A_Index = 1)
		{
			vars.general.supported_resolutions := {}
			vars.general.available_resolutions := ""
		}
		vars.general.supported_resolutions[StrReplace(A_LoopField, "p")] := 1
		If (StrReplace(A_Loopfield, "p") <= vars.monitor.h && (vars.client.fullscreen = "true" || vars.client.borderless)) ;cont
		|| (StrReplace(A_LoopField, "p") < vars.monitor.h && (vars.client.fullscreen = "false") && !vars.client.borderless)
			vars.general.available_resolutions := !vars.general.available_resolutions ? StrReplace(A_Loopfield, "p") :  StrReplace(A_Loopfield, "p") "|" vars.general.available_resolutions
	}
	vars.general.available_resolutions .= "|"

	If (!IsNumber(vars.client.customres.1) || !IsNumber(vars.client.customres.2)) && vars.general.supported_resolutions.HasKey(vars.client.h)
	{
		IniWrite, % vars.client.w, ini\config.ini, settings, custom-width
		IniWrite, % vars.client.h, ini\config.ini, settings, custom-resolution
	}

	If vars.general.supported_resolutions.HasKey(vars.client.h)
	{
		If !FileExist("img\Recognition (" vars.client.h "p)\GUI\")
			FileCreateDir, % "img\Recognition (" vars.client.h "p)\GUI\"
		If !FileExist("img\Recognition (" vars.client.h "p)\Betrayal\")
			FileCreateDir, % "img\Recognition (" vars.client.h "p)\Betrayal\"
		If !FileExist("img\Recognition (" vars.client.h "p)\")
			LLK_FilePermissionError("create")
	}
}

Init_geforce()
{
	global
	
	vars.pixelsearch.variation := LLK_IniRead("ini\geforce now.ini", "Settings", "pixel-check variation", 0)
	vars.imagesearch.variation := LLK_IniRead("ini\geforce now.ini", "Settings", "image-check variation", 25)
}

Init_general()
{
	global
	local font_height, font_width
	
	legacy_version := LLK_IniRead("ini\config.ini", "versions", "ini-version")
	If IsNumber(legacy_version) && (legacy_version < 15000)
	{
		MsgBox,, Script updated incorrectly, Updating from legacy to v1.50+ requires a clean installation.`nThe script will now exit.
		ExitApp
	}
	ini_version := LLK_IniRead("ini\config.ini", "versions", "ini", 0)
	If !ini_version
		IniWrite, 15000, ini\config.ini, versions, ini

	settings.general.version := ini_version ? ini_version : 15000
	settings.general.trans := 230
	settings.general.blocked_hotkeys := {"!": 1, "^": 1, "+": 1}
	settings.general.character := LLK_IniRead("ini\config.ini", "Settings", "active character")
	settings.general.dev := LLK_IniRead("ini\config.ini", "Settings", "dev", 0)
	settings.general.xButton := LLK_IniRead("ini\config.ini", "UI", "button xcoord", 0)
	settings.general.yButton := LLK_IniRead("ini\config.ini", "UI", "button ycoord", 0)
	;settings.general.hide_button := LLK_IniRead("ini\config.ini", "UI", "hide panel", 0)
	settings.general.warning_ultrawide := LLK_IniRead("ini\config.ini", "Versions", "ultrawide warning", 0)
	
	settings.general.fSize := LLK_IniRead("ini\config.ini", "settings", "font-size", LLK_FontDefault())
	If (settings.general.fSize < 6)
		settings.general.fSize := 6
	LLK_FontDimensions(settings.general.fSize, font_height, font_width)
	settings.general.fHeight := font_height, settings.general.fWidth := font_width
	settings.features.browser := LLK_IniRead("ini\config.ini", "Settings", "enable browser features", 1)

	settings.updater := {"update_check": LLK_IniRead("ini\config.ini", "settings", "update auto-check", 0)}
}

Init_vars()
{
	local
	global vars, settings, CustomFont, db, Json
	
	db := {}
	;read databases for item-info tooltip
	db.item_mods := Json.Load(LLK_FileRead("data\item info\mods.json"))
	db.item_bases := Json.Load(LLK_FileRead("data\item info\base items.json"))
	db.leveltracker := {"areas": Json.Load(LLK_FileRead("data\leveling tracker\areas.json")), "gems": Json.Load(LLK_FileRead("data\leveling tracker\gems.json"))}
	db.mapinfo := {}

	db.mapinfo.maps := {}	
	Loop, Parse, % LLK_StringCase(LLK_IniRead("data\Atlas.ini", "Maps")), `n, `r
	{
		val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		maps .= StrReplace(val, ",", " (" A_Index "),") ;create a list of all maps
		Sort, val, D`,
		db.mapinfo.maps[A_Index] := StrReplace(SubStr(val, 1, -1), ",", "`n") ;store tier X maps here
	}
	Sort, maps, D`,
	Loop, Parse, maps, `,
	{
		If !A_LoopField
			continue
		db.mapinfo.maps[SubStr(A_LoopField, 1, 1)] .= !db.mapinfo.maps[SubStr(A_LoopField, 1, 1)] ? A_LoopField : "`n" A_LoopField ;store maps starting with a-z here
	}

	db.mapinfo.mods := {}
	Loop, Parse, % LLK_IniRead("data\Map mods.ini"), `n, `r
	{
		If (A_LoopField = "sample map")
			Continue
		key0 := A_LoopField, db.mapinfo.mods[key0] := {}
		Loop, Parse, % LLK_IniRead("data\Map mods.ini", A_LoopField), `n, `r
		{
			key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
			db.mapinfo.mods[key0][key] := val
		}
	}

	settings := {}
	settings.features := {}
	settings.geforce := {}

	vars.betrayal := {}
	vars.button_destroy := {}
	vars.cheatsheets := {}
	vars.client := {}
	vars.leveltracker := {}
	vars.log := {} ;store data related to the game's log here
	vars.mapinfo := {}
	vars.hwnd := {"help_tooltips": {}}
	vars.help := Json.Load(LLK_FileRead("data\help tooltips.json"))
	vars.snip := {}
	vars.system := {"timeout": 1, "font1": New CustomFont("data\Fontin-SmallCaps.ttf"), "click": 1}
	vars.tooltip := {}
	vars.general := {"buggy_resolutions": {768: 1, 1024: 1, 1050: 1}, "inactive": 0, "startup": A_TickCount, "updatetick": 0}
	If !IsObject(vars.updater)
	{
		version := Json.Load(LLK_FileRead("data\versions.json")), version := version._release.1
		vars.updater := {"version": [version]}, vars.updater.version.2 := UpdateParseVersion(version)
	}
	
	vars.recombinators := {"classes": "shield, sword, quiver, bow, claw, dagger, mace, ring, amulet, helmet, glove, boot, belt, wand,staves,axe,sceptre,body,sentinel"}
}

Loop()
{
	local
	global vars, settings
	
	If !WinExist("ahk_group poe_window")
		vars.client.closed := 1, vars.hwnd.poe_client := ""

	If !WinExist("ahk_group poe_window") && (A_TickCount >= vars.general.runcheck + settings.general.kill[2]* 60000) && settings.general.kill[1] && !vars.alarm.timestamp
		ExitApp

	If WinExist("ahk_group poe_window")
	{
		vars.general.runcheck := A_TickCount
		If !vars.hwnd.poe_client
			vars.hwnd.poe_client := WinExist("ahk_group poe_window")

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
}

Loop_main()
{
	local
	global vars, settings, Json

	Critical
	If vars.cloneframes.editing && (vars.settings.active != "clone-frames") ;in case the user closes the settings menu without saving changes, reset clone-frames settings to previous state
	{
		vars.cloneframes.editing := "", vars.cloneframes.active_corner := ""
		Init_cloneframes()
	}
	
	If WinExist("ahk_id "vars.hwnd.searchstrings_context) && !WinActive("ahk_group poe_window") && !WinActive("ahk_id "vars.hwnd.searchstrings_context)
	{
		Gui, searchstrings_context: Destroy
		vars.hwnd.Delete("searchstrings_context")
	}
	If WinExist("ahk_id "vars.hwnd.omni_context) && !WinActive("ahk_group poe_window") && !WinActive("ahk_id "vars.hwnd.omni_context)
	{
		Gui, omni_context: destroy
		vars.hwnd.Delete("omni_context")
	}

	If !WinActive("ahk_group poe_ahk_window") && !(settings.general.dev && WinActive("ahk_exe code.exe"))
	{
		vars.general.inactive += 1
		If (vars.general.inactive = 3)
		{
			;Gui, notepad_contextmenu: Destroy
			Gui, omni_context: Destroy
			vars.hwnd.Delete("omni_context")
			Gui, bestiary_menu: Destroy
			Gui, map_info_menu: Destroy
			hwnd_map_info_menu := ""
			Gui, legion_help: Destroy
			LLK_Overlay("hide")
			CloneframesHide()
		}
	}
	MouseHover()
	IteminfoOverlays()
	
	If vars.general.cMouse
		check_help := LLK_HasVal(vars.hwnd.help_tooltips, vars.general.cMouse), check := (SubStr(check_help, 1, InStr(check_help, "_") - 1)), control := StrReplace(SubStr(check_help, InStr(check_help, "_") + 1), "|")
	If check_help && (vars.general.active_tooltip != vars.general.cMouse) && (vars.help[check][control].Count() || control = "update changelog") && !WinExist("ahk_id "vars.hwnd.screencheck_info.main)
		HelpTooltip(check_help)
	Else If (!check_help || WinExist("ahk_id "vars.hwnd.screencheck_info.main)) && WinExist("ahk_id "vars.hwnd.help_tooltips.main)
		LLK_Overlay(vars.hwnd.help_tooltips.main, "destroy"), vars.general.active_tooltip := "", vars.hwnd.help_tooltips.main := ""

	If WinExist("ahk_id "vars.hwnd.legion.main)
		LegionHover()
	Else If !WinExist("ahk_id "vars.hwnd.legion.main) && WinExist("ahk_id "vars.hwnd.legion.tooltip)
		LLK_Overlay(vars.hwnd.legion.tooltip, "destroy"), vars.legion.tooltip := ""

	If !vars.tooltip.wait
	{
		For key, val in vars.tooltip ;timed tooltips are stored in this object and destroyed via this loop
			If val && (val <= A_TickCount)
			{
				LLK_Overlay(key, "destroy")
				remove_tooltips .= !remove_tooltips ? key : ";" key
			}
	
		Loop, Parse, remove_tooltips, `; ;separate loop to delete entries from the vars.tooltip object without interfering with the for-loop above
			vars.tooltip.Delete(A_LoopField)
		remove_tooltips := ""
	}

	If !vars.general.gui_hide && (WinActive("ahk_group poe_ahk_window") || (settings.general.dev && WinActive("ahk_exe code.exe"))) && !vars.client.closed && !WinActive("ahk_id "vars.hwnd.leveltracker_screencap.main) ;cont
	&& !WinActive("ahk_id "vars.hwnd.snip.main) && !WinActive("ahk_id "vars.hwnd.cheatsheet_menu.main) && !WinActive("ahk_id "vars.hwnd.searchstrings_menu.main) && !(vars.general.inactive && WinActive("ahk_id "vars.hwnd.settings.main))
	{
		If vars.general.inactive
		{
			vars.general.inactive := 0
			LLK_Overlay("show")
		}
		
		If settings.features.pixelchecks
		{
			For key in vars.pixelsearch.list
				Screenchecks_PixelSearch(key)
		}

		LeveltrackerFade()
		location := vars.log.areaID ;short-cut variable
		If (vars.cloneframes.enabled
		&& ((settings.cloneframes.pixelchecks && vars.pixelsearch.gamescreen.check) || !settings.cloneframes.pixelchecks)) ;user is on gamescreen, or auto-toggle is disabled
		&& (!settings.cloneframes.hide || (settings.cloneframes.hide && !InStr(location, "hideout") && !InStr(location, "_town") && (location != "login"))) ;outside hideout/town/login, or auto-toggle is disabled
		|| (vars.settings.active = "clone-frames") ;accessing the clone-frames section of the settings
			CloneframesShow()
		Else CloneframesHide()
	}
}

MouseHover()
{
	global
	local win_hover, control_hover, xPos, yPos

	MouseGetPos, xPos, yPos, win_hover, control_hover, 2
	vars.general.xMouse := xPos, vars.general.yMouse := yPos
	vars.general.wMouse := Blank(win_hover) ? 0 : win_hover, vars.general.cMouse := Blank(control_hover) ? 0 : control_hover
}

Resolution_check()
{
	global
	local text, poe_height := vars.client.h
	
	If vars.general.buggy_resolutions.HasKey(vars.client.h) || !vars.general.supported_resolutions.HasKey(vars.client.h) ;&& !vars.general.supported_resolutions.HasKey(vars.client.h + vars.system.caption + vars.system.yborder* 2)
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
	global

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
	global vars

	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.snip.main
	vars.snip := {"x": x, "y": y, "w": w, "h": h}
	Gui, snip: Destroy
	vars.hwnd.Delete("snip")
}

SnippingTool(mode := 0)
{
	local
	global vars, settings

	KeyWait, LButton
	If mode && !WinExist("ahk_id " vars.hwnd.snip.main)
	{
		Gui, snip: New, -DPIScale +LastFound +ToolWindow +AlwaysOnTop +Resize HWNDhwnd, Lailloken UI: snipping widget
		Gui, snip: Color, Aqua
		WinSet, trans, 100
		vars.hwnd.snip := {"main": hwnd}
		
		Gui, snip: Add, Picture, % "x"settings.general.fWidth*5 " y"settings.general.fHeight*2 " h"settings.general.fHeight " w-1 BackgroundTrans HWNDhwnd", img\GUI\help.png
		vars.hwnd.snip.help := vars.hwnd.help_tooltips["snip_about"] := hwnd
		If vars.snip.w
			Gui, snip: Show, % "x"vars.snip.x " y"vars.snip.y " w"vars.snip.w - vars.system.xBorder*2 " h"vars.snip.h - vars.system.caption - vars.system.yBorder*2
		Else Gui, snip: Show, % "w"settings.general.fWidth*31 " h"settings.general.fHeight*11
		Return 0
	}
	Else If !mode && WinExist("ahk_id " vars.hwnd.snip.main)
		SnipGuiClose()
	
	vars.general.gui_hide := 1
	LLK_Overlay("hide")
	Gui, %A_Gui%: Hide

	If mode
	{
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.snip.main
		Gui, snip: Hide
		sleep 100
		pBitmap := Gdip_BitmapFromScreen(x + vars.system.xborder "|" y + vars.system.yborder + vars.system.caption "|" w - vars.system.xborder*2 "|" h - vars.system.yborder*2 - vars.system.caption)
		Gui, snip: Show
	}
	Else
	{
		Clipboard := ""
		SendInput, #+{s}
		WinWaitActive, ahk_exe ScreenClippingHost.exe,, 2
		WinWaitNotActive, ahk_exe ScreenClippingHost.exe
		pBitmap := Gdip_CreateBitmapFromClipboard()
	}

	vars.general.gui_hide := 0
	Gui, %A_Gui%: Show, NA
	If (pBitmap <= 0)
	{
		LLK_ToolTip("screen-cap failed",,,,, "red")
		Return 0
	}
	If WinExist("ahk_id "vars.hwnd.snip.main)
		WinActivate, % "ahk_id "vars.hwnd.snip.main

	Return pBitmap
}

SnippingToolMove()
{
	local
	global vars

	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.snip.main
	Switch A_ThisHotkey
	{
		Case "*up":
			If GetKeyState("Alt", "P")
				h -= GetKeyState("Ctrl", "P") ? 10 : 1
			Else y -= GetKeyState("Ctrl", "P") ? 10 : 1
		Case "*down":
			If GetKeyState("Alt", "P")
				h += GetKeyState("Ctrl", "P") ? 10 : 1
			Else y += GetKeyState("Ctrl", "P") ? 10 : 1
		Case "*left":
			If GetKeyState("Alt", "P")
				w -= GetKeyState("Ctrl", "P") ? 10 : 1
			Else x -= GetKeyState("Ctrl", "P") ? 10 : 1
		Case "*right":
			If GetKeyState("Alt", "P")
				w += GetKeyState("Ctrl", "P") ? 10 : 1
			Else x += GetKeyState("Ctrl", "P") ? 10 : 1
	}
	WinMove, % "ahk_id "vars.hwnd.snip.main,, %x%, %y%, %w%, %h%
}

Startup()
{
	local
	global vars, settings
	
	SetStoreCapsLockMode, % LLK_IniRead("ini\config.ini", "Settings", "enable CapsLock-toggling", 1) ;for people who have something bound to CapsLock
	
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}

	;get widths/heights of window-borders to correctly offset overlays in windowed mode
	SysGet, xborder, 32
	SysGet, yborder, 33
	SysGet, caption, 4
	vars.system.xborder := xborder, vars.system.yborder := yborder, vars.system.caption := caption

	settings.general := {"kill": [LLK_IniRead("ini\config.ini", "Settings", "kill script", 1), LLK_IniRead("ini\config.ini", "Settings", "kill-timeout", 1)]}
	settings.general.dev := LLK_IniRead("ini\config.ini", "Settings", "dev", 0)

	;create window-groups for easier window detection
	GroupAdd, poe_window, ahk_exe GeForceNOW.exe
	GroupAdd, poe_window, ahk_exe boosteroid.exe
	GroupAdd, poe_window, ahk_class POEWindowClass
	GroupAdd, poe_ahk_window, ahk_class POEWindowClass
	GroupAdd, poe_ahk_window, ahk_exe GeForceNOW.exe
	GroupAdd, poe_ahk_window, ahk_exe boosteroid.exe
	GroupAdd, poe_ahk_window, ahk_class AutoHotkeyGUI
	If settings.general.dev
		GroupAdd, poe_ahk_window, ahk_exe code.exe ;treat VS Code's window as a client

	If !LLK_FileCheck() ;check if important files are missing
		LLK_Error("Critical files are missing. Make sure you have installed the script correctly.")

	Loop, Parse, % "ini, exports, img\GUI\skill-tree, cheat-sheets", `,, %A_Space%
	{
		If !FileExist(A_LoopField "\") ;create folder
			FileCreateDir, % A_LoopField "\"
		If !FileExist(A_LoopField "\") && !file_error ;check if the folder was created successfully
			file_error := 1, LLK_FilePermissionError("create")
	}
	
	vars.general.runcheck := A_TickCount ;save when the client was last running (for purposes of killing the script after X minutes)
	While !WinExist("ahk_group poe_window") ;wait for game-client window
	{
		If settings.general.kill.1 && (A_TickCount >= vars.general.runcheck + settings.general.kill.2* 60000) ;kill script after X minutes
			ExitApp
		win_not_exist := 1
		sleep, 100
	}

	;band-aid fix for situations in which the client was launched after the script, and the script detected an unsupported resolution because the PoE-client window was being resized during window-detection
	If WinExist("ahk_group poe_window") && win_not_exist
		sleep 4000
	
	Init_client()
	
	vars.hwnd.poe_client := WinExist("ahk_group poe_window") ;save the client's handle
	vars.general.runcheck := A_TickCount ;save when the client was last running (for purposes of killing the script after X minutes)	
	
	;get the location of the client.txt file
	WinGet, poe_log_file, ProcessPath, ahk_group poe_window
	If FileExist(SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\client.txt")
		poe_log_file := SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\client.txt"
	Else poe_log_file := SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\kakaoclient.txt"
	
	If FileExist(poe_log_file) ;parse client.txt at startup to get basic location info
	{
		vars.log.file_location := poe_log_file
		Init_log()
	}
	Else vars.log.file_location := 0
}

StrMatch(string, check)
{
	local

	If (SubStr(string, 1, StrLen(check)) = check)
		Return 1
}

ToolTip_Mouse(mode := "", timeout := 0)
{
	local
	static name, start
	global vars, settings

	If mode
	{
		If (mode = "reset")
			name := "", start := ""
		Else
		{
			vars.tooltip_mouse := {"name": mode, "timeout": timeout}
			SetTimer, ToolTip_Mouse, 10
		}
		Return
	}

	Switch vars.tooltip_mouse.name
	{
		Case "chromatics":
			text := "click into the socket-number`nfield and press space`n(esc to exit)"
			If GetKeyState("Space", "P") ;GetKeyState("Ctrl", "P") && GetKeyState("v", "P")
			{
				SetTimer, ToolTip_Mouse, Delete
				KeyWait, Space
				Sleep, 100
				SendInput, % "^{a}{BS}" vars.omnikey.item.sockets "{TAB}" vars.omnikey.item.str "{TAB}" vars.omnikey.item.dex "{TAB}" vars.omnikey.item.int "{TAB}{TAB}"
				vars.tooltip_mouse := ""
			}
		Case "cluster":
			text := "press ctrl-f to highlight`nthe selected jewel type`n(esc to exit)"
			If GetKeyState("Control", "P") && GetKeyState("F", "P")
			{
				SetTimer, ToolTip_Mouse, Delete
				Clipboard := vars.omnikey.item.cluster_enchant
				KeyWait, F
				Sleep, 100
				SendInput, ^{a}^{v}
				Sleep, 100
				vars.tooltip_mouse := ""
			}
		Case "searchstring":
			text := "scrolling... "(InStr(vars.searchstrings.clipboard, ";") ? "" : vars.searchstrings.active.3 "/" vars.searchstrings.active.4) "`n(esc to exit)"
		Case "killtracker":
			text := "press the omni-key to`nstart the kill-tracker"
		Case "lab":
			text := "-> select lab difficulty`n-> right-click layout image`n-> click <copy image>`noptional:`n-> right-click <lab compass file>`n-> click <copy link address>"
	}

	If vars.tooltip_mouse.timeout && WinActive("ahk_group poe_window") && IsNumber(start) && (A_TickCount >= start + 1000) || GetKeyState("ESC", "P") && (name != "killtracker") || !vars.tooltip_mouse
	{
		Gui, tooltip_mouse: Destroy
		vars.hwnd.Delete("tooltip_mouse"), name := "", start := "", vars.tooltip_mouse := ""
		SetTimer, ToolTip_Mouse, Delete
		Return
	}
	
	If vars.hwnd.tooltip_mouse.main && !WinExist("ahk_id " vars.hwnd.tooltip_mouse.main) || (name != vars.tooltip_mouse.name)
	{
		start := A_TickCount
		Gui, tooltip_mouse: New, % "-DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd +E0x02000000 +E0x00080000"
		Gui, tooltip_mouse: Color, Black
		Gui, tooltip_mouse: Margin, % settings.general.fwidth / 2, 0
		WinSet, Transparent, 255
		Gui, tooltip_mouse: Font, % "s"settings.general.fSize " cWhite", Fontin SmallCaps
		Gui, tooltip_mouse: Add, Text, % "HWNDhwnd1"(vars.tooltip_mouse.name = "searchstring" ? " w"settings.general.fWidth*14 : ""), % text
		vars.hwnd.tooltip_mouse := {"main": hwnd, "text": hwnd1}
	}

	name := vars.tooltip_mouse.name
	MouseGetPos, xPos, yPos
	Gui, tooltip_mouse: Show, % "NA x"xPos + settings.general.fWidth*3 " y"yPos
}

UpdateCheck(timer := 0) ;checks for updates: timer refers to whether this function was called via the timer or during script-start
{
	local
	global Json, vars

	vars.update := [0], update := vars.update
	If !FileExist("update\")
		FileCreateDir, update\
	update.1 := !FileExist("update\") ? -2 : update.1
	FileDelete, update\update.* ;delete any leftover files
	update.1 := FileExist("update\update.*") ? -1 : update.1 ;error code -1 = delete-permission
	FileAppend, 1, update\update.test
	update.1 := !FileExist("update\update.test") ? -2 : update.1 ;error code -2 = write-permission
	FileDelete, update\update.test
	update.1 := FileExist("update\update.test") ? -1 : !FileExist("data\versions.json") ? -3 : update.1 ;error code -3 = bricked install (version-file not found)
	If (update.1 < 0)
	{
		If InStr("2", timer)
			IniWrite, updater, ini\config.ini, versions, reload settings
		Return
	}
	versions_local := Json.Load(LLK_FileRead("data\versions.json")) ;load local versions
	Loop, Files, % "update\update_*.zip"
	{
		version := SubStr(A_LoopFileName, InStr(A_LoopFileName, "_") + 1), version := StrReplace(version, ".zip")
		If Blank(version) || (version <= versions_local["_release"].1)
			FileDelete, % A_LoopFileName
	}
	
	FileDelete, data\version_check.json
	UrlDownloadToFile, % "https://raw.githubusercontent.com/Lailloken/Lailloken-UI/main/data/versions.json", data\version_check.json
	update.1 := ErrorLevel ? -4 : update.1 ;error-code -4 = version-list download failed
	If (update.1 = -4)
	{
		If InStr("2", timer)
			IniWrite, updater, ini\config.ini, versions, reload settings
		Return
	}
	versions_live := Json.Load(LLK_FileRead("data\version_check.json")) ;load version-list into object
	vars.updater := {"version": [versions_local._release.1, UpdateParseVersion(versions_local._release.1)], "latest": [versions_live._release.1, UpdateParseVersion(versions_live._release.1)]}
	vars.updater.skip := LLK_IniRead("ini\config.ini", "versions", "skip", 0)
	If (vars.updater.skip = vars.updater.latest.1)
		Return
	If !InStr(LLK_FileRead("data\changelog.json"), vars.updater.latest.1)
	{
		FileDelete, data\changelog.json
		UrlDownloadToFile, % "https://raw.githubusercontent.com/Lailloken/Lailloken-UI/main/data/changelog.json", data\changelog.json
	}
	If FileExist("data\changelog.json")
		vars.updater.changelog := Json.Load(LLK_FileRead("data\changelog.json"))
	Else vars.updater.changelog := [[[vars.updater.version.2, vars.updater.version.1], "couldn't load changelog"]]
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
		For key, val in versions_live
		{
			If (key = "_release") || (versions_local[key].1 = val.1)
				Continue
			extension := SubStr(key, InStr(key, ".",,, LLK_InStrCount(key, "."))), branch := InStr(val.2, "/main/") ? "main" : "beta"
			UrlDownloadToFile, % val.2, % "update\update" extension ;download the new file into the root folder first (w/o replacing the target file) in order to check write-permissions first (and to prevent bricking the target)
			If ErrorLevel
			{
				vars.update := [-5, branch] ;error-code -5 = download of an individual file failed 
				Break
			}
			FileMove, % "update\update" extension, % key, 1 ;move downloaded file to target destination
			If ErrorLevel
			{
				vars.update := [-6, branch] ;error-code -6 = file couldn't be moved
				Break
			}
		}
		If (vars.update.1 >= 0)
		{
			FileDelete, data\versions.json
			FileMove, data\version_check.json, data\versions.json, 1
			IniDelete, ini\config.ini, versions, apply update
			Reload
			ExitApp
		}
		If (vars.update.1 < 0)
		{
			SetTimer, UpdateDownload, Delete
			Gui, update_download: Destroy
			IniWrite, updater, ini\config.ini, versions, reload settings
			Return
		}
	}
}

UpdateDownload(mode := "")
{
	local
	global vars
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
		SetTimer, UpdateDownload, 50
	}

	dl_bar += (dl_bar = 10) ? -10 : 1
	GuiControl,, % HWND_bar, % dl_bar
	;GuiControl, movedraw, % vars.hwnd.update_notification.dl_bar
}

/*
UpdateCheck(timer := 0) ;checks for updates: timer refers to whether this function was called via the timer or during script-start
{
	local
	global Json, update := [0]

	If (timer = 1) && !LLK_IniRead("ini\config.ini", "settings", "update auto-check", 1)
		Return
	FileDelete, update.* ;delete any leftover files
	If FileExist("update.*")
	{
		If !timer
			LLK_FilePermissionError("delete")
		Return
	}
	versions_local := Json.Load(LLK_FileRead("data\versions.json")) ;load local versions
	If !IsObject(versions_local)
		Return
	Loop, Files, % "update_*.zip"
	{
		version := SubStr(A_LoopFileName, InStr(A_LoopFileName, "_") + 1), version := StrReplace(version, ".zip")
		If (version <= versions_local["_release"].1)
			FileDelete, % A_LoopFileName
	}
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET", "https://raw.githubusercontent.com/Lailloken/Lailloken-UI/main/data/versions.json", true) ;get version-list from GitHub
	whr.Send(), whr.WaitForResponse()
	If !InStr(whr.ResponseText, "{")
		Return
	versions_live := Json.Load(whr.ResponseText) ;load version-list into object
	For key, val in versions_live ;parse online version-list and compare versions between each file
	{
		If !versions_local[key].1 || (val.1 > versions_local[key].1) ;newer version is listed online
		{
			If (key = "_release") && !timer ;if new release-version is online, and updatecheck was called on script-start
			{
				update := [], update.0 := ["", val.1] ;create array with versions (to display them in the notification)
				Loop, Parse, % val.1 ;parse the version-number from the file to create a more readable one (e.g. 15000.1 = v1.50.0-hotfix1)
					update.1 .= InStr("13", A_Index) ? A_LoopField "." : (A_LoopField = ".") ? "-hotfix" : (A_Index = 4 && A_LoopField = "0") ? "" : A_LoopField
				Loop, Parse, % versions_local[key].1
					update.0.1 .= InStr("13", A_Index) ? A_LoopField "." : (A_LoopField = ".") ? "-hotfix" : (A_Index = 4 && A_LoopField = "0") ? "" : A_LoopField
				update.2 := val.2.Clone(), update.3 := val.3  ;[2] includes a short summary of what the update contains, [3] the direct-download link
				Return ;if there's a new release, skip the remaining file-update checks: it's likely that the new releas is required to make use of the updated files
			}
			Else If (key = "_release") && timer ;new release-version, but updatecheck was called via the timer (no update notification, only the llk-ui panel turning green)
			{
				update := [1]
				Break ;if there's a new release, skip the remaining file-update checks: it's likely that the new releas is required to make use of the updated files
			}
			extension := SubStr(key, InStr(key, ".",,, LLK_InStrCount(key, "."))), branch := InStr(val.2, "/main/") ? "main" : "beta"
			UrlDownloadToFile, % val.2, % "update" extension ;download the new file into the root folder first (w/o replacing the target file) in order to check write-permissions first (and to prevent bricking the target)
			If ErrorLevel || !FileExist("update" extension) ;check for errors
			{
				update := [!FileExist("update" extension) ? -1 : -2, branch] ;error codes: -1 (file couldn't be written), -2 download failed ;split these two just in case a download can error out AND still create a file
				Break
			}
			FileMove, % "update" extension, % key, 1 ;move downloaded file to target destination
			If ErrorLevel
			{
				update := [-3, branch] ;error code -3: some write error
				Break
			}
			If (key = "lailloken ui.ahk") && !timer
				restart := 1
			update.1 += 10
		}
	}
	If (update.1 < 10) && timer
	{
		Gui, LLK_panel: Color, % !IsNumber(update.1) ? "Black" : (update.1 > 0) ? "Green" : (update.1 < 0) ? "Maroon" : "Black" ;update the color of the llk-ui panel
		Return
	}
	If (update.1 = 0) || (update.1 < 0) && !timer ;no update, or there was an error while updating on script-start
		Return
	FileDelete, data\versions.json
	If FileExist("data\versions.json")
	{
		update := [-4, branch]
		Gui, LLK_panel: Color, % !IsNumber(update.1) ? "Black" : (update.1 > 0) ? "Green" : (update.1 < 0) ? "Maroon" : "Black"
		Return
	}
	FileAppend, % Json.Dump(versions_live), % "data\versions.json"
	If restart
	{
		Reload
		ExitApp
	}
	update := timer ? [1] : [0]
	If timer
		Gui, LLK_panel: Color, % !IsNumber(update.1) ? "Black" : (update.1 > 0) ? "Green" : (update.1 < 0) ? "Maroon" : "Black"
}
*/

/*
UpdateDownload(mode := "")
{
	local
	global vars
	static dl_bar := 0

	If (mode = "reset")
	{
		dl_bar := 0
		GuiControl,, % vars.hwnd.update_notification.dl_bar, % dl_bar
		GuiControl, movedraw, % vars.hwnd.update_notification.dl_bar
		Return
	}

	dl_bar += (dl_bar = 10) ? -10 : 1
	GuiControl,, % vars.hwnd.update_notification.dl_bar, % dl_bar
	GuiControl, movedraw, % vars.hwnd.update_notification.dl_bar
}
*/

/*
UpdateNotification(code)
{
	local
	global vars, settings, update
	static in_progress
	
	If in_progress || IsObject(code) && !code.1
		Return
	
	If (code.0.2 = LLK_IniRead("ini\config.ini", "versions", "skip", 6969)) ;check if user wants to skip this new version
	{
		update := 0
		Return
	}
	check := LLK_HasVal(vars.hwnd.update_notification, code)
	If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos,,, Width, Height, % "ahk_id "vars.hwnd.update_notification.main
		While GetKeyState("LButton", "P")
			If (A_TickCount >= start + 250)
			{
				LLK_Drag(width, height, xPos, yPos, 1)
				Sleep 1
			}
	}
	Else If (check = "download")
	{
		SetTimer, UpdateDownload, 50
		in_progress := 1
		UrlDownloadToFile, % update.3, % "update_" update.0.2 ".zip"
		SetTimer, UpdateDownload, Delete
		in_progress := 0, UpdateDownload("reset")
		If !FileExist("update_" update.0.2 ".zip") || ErrorLevel
		{
			Gui, update_notification: Hide
			MsgBox, 4096, download failed, An error occurred while downloading or saving the update-file.`n`nIf this keeps happening, run the write-permissions test in the <general> section of the settings menu.
		}
		UpdateNotification("refresh")
	}
	Else If (check = "open")
	{
		Run, explore %A_ScriptDir%
		Run, % "update_" update.0.2 ".zip"
		ExitApp
	}
	Else If (check = "notes")
		Run, https://github.com/Lailloken/Lailloken-UI/releases
	Else If (check = "later")
	{
		KeyWait, LButton
		LLK_Overlay(vars.hwnd.update_notification.main, "destroy"), update := ["later"]
	}
	Else If (check = "skip") && LLK_Progress(vars.hwnd.update_notification.skip_bar, "LButton")
	{
		IniWrite, % update.0.2, ini\config.ini, versions, skip
		LLK_Overlay(vars.hwnd.update_notification.main, "destroy"), update := 0
		KeyWait, LButton
	}
	Else If (check = "restart")
	{
		Reload
		ExitApp
	}
	Else If (check = "write_test")
	{
		in_progress := 1, Settings_menu("general")
		WinWaitActive, % "ahk_id "vars.hwnd.settings.main
		Settings_WriteTest(), in_progress := 0
	}
	Else If (check = "manual_update")
	{
		Run, % "https://github.com/Lailloken/Lailloken-UI/archive/refs/heads/"update.2 ".zip" ;branch stored in update.2
		Run, explore %A_ScriptDir%
		ExitApp
	}
	If check
		Return

	Gui, update_notification: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDupdate_notification
	Gui, update_notification: Color, Black
	Gui, update_notification: Margin, % settings.general.fWidth, % settings.general.fWidth/4
	Gui, update_notification: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	vars.hwnd.update_notification := {"main": update_notification}

	Gui, update_notification: Add, Text, % "x-1 y-1 Center Border HWNDhwnd gUpdateNotification", % " lailloken ui: update checker "
	vars.hwnd.update_notification.winbar := hwnd
	Gui, update_notification: Font, % "s"settings.general.fSize

	If IsObject(code.0) || (code = "refresh")
	{
		code := (code = "refresh") ? update : code
		Gui, update_notification: Add, Text, % "Section xs HWNDhwnd xp+"settings.general.fWidth " y+"settings.general.fWidth/2, % "currently running: " code.0.1
		ControlGetPos,,, cWidth0,,, ahk_id %hwnd%
		Gui, update_notification: Add, Text, % "xs HWNDhwnd y+0", % "latest version: " code.1
		ControlGetPos,,, cWidth,,, ahk_id %hwnd%
		cWidth := Max(cWidth0, cWidth)
		Gui, update_notification: Font, underline
		Gui, update_notification: Add, Text, % "xs y+"settings.general.fWidth/2, % "summary of changes:"
		Gui, update_notification: Font, norm
		For index, text in code.2
			Gui, update_notification: Add, Text, % "xs y+0 w"cWidth, % "-> " text

		Gui, update_notification: Font, % "s"settings.general.fSize - 2
		If !FileExist("update_" update.0.2 ".zip")
		{
			Gui, update_notification: Add, Text, % "Section xs Border Center BackgroundTrans HWNDhwnd0 gUpdateNotification y+"settings.general.fWidth, % "download zip-file"
			Gui, update_notification: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd range0-10 BackgroundBlack cGreen", 0
			vars.hwnd.update_notification.download := hwnd0, vars.hwnd.update_notification.dl_bar := hwnd
		}
		Else
		{
			Gui, update_notification: Add, Text, % "Section xs Border Center HWNDhwnd gUpdateNotification y+"settings.general.fWidth, % "open zip && close script"
			vars.hwnd.update_notification.open := hwnd, vars.hwnd.help_tooltips["updater_open file"] := hwnd
		}
		Gui, update_notification: Add, Text, % "xs Border Center HWNDhwnd gUpdateNotification", % "release notes (github)"
		vars.hwnd.update_notification.notes := hwnd
		Gui, update_notification: Add, Text, % "xs Border Center HWNDhwnd gUpdateNotification", % "update later"
		vars.hwnd.update_notification.later := hwnd
		Gui, update_notification: Add, Text, % "xs Border Center BackgroundTrans HWNDhwnd0 gUpdateNotification", % "skip this version"
		Gui, update_notification: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd range0-500 BackgroundBlack cRed", 0
		vars.hwnd.update_notification.skip := hwnd0, vars.hwnd.update_notification.skip_bar := vars.hwnd.help_tooltips["updater_skip release"] := hwnd
		
	}
	Else If (code.1 < 0) && (code.1 != -2)
	{
		Gui, update_notification: Font, underline
		Gui, update_notification: Add, Text, % "Section xs HWNDhwnd xp+"settings.general.fWidth " y+"settings.general.fWidth/2, % "file-error detected during update"
		Gui, update_notification: Font, norm
		ControlGetPos,,, cWidth,,, ahk_id %hwnd%
		Gui, update_notification: Add, Text, % "xs HWNDhwnd w"cWidth, -> the updater has encountered errors while trying to save downloaded files.
		;Gui, update_notification: Add, Text, % "xs HWNDhwnd w"cWidth, -> the script may not have the required write permissions in its current location on your system.
		Gui, update_notification: Add, Text, % "xs HWNDhwnd w"cWidth, -> you have the following options to troubleshoot this:

		Gui, update_notification: Add, Text, % "Section xs Center Border HWNDhwnd gUpdateNotification y+"settings.general.fWidth/2, % "re-try update"
		vars.hwnd.update_notification.restart := vars.hwnd.help_tooltips["updater_retry update"] := hwnd
		Gui, update_notification: Add, Text, % "Section xs Center Border BackgroundTrans HWNDhwnd0 gUpdateNotification y+"settings.general.fWidth/2, % "run write-permissions test"
		Gui, update_notification: Add, Progress, % "xp yp wp hp HWNDhwnd Disabled Range0-700 BackgroundBlack cGreen", 0
		vars.hwnd.update_notification.write_test := hwnd0, vars.hwnd.update_notification.write_test_bar := vars.hwnd.help_tooltips["updater_write permissions"] := hwnd
		Gui, update_notification: Add, Text, % "Section xs Center Border BackgroundTrans HWNDhwnd gUpdateNotification y+"settings.general.fWidth/2, % "download && apply manually"
		vars.hwnd.update_notification.manual_update := vars.hwnd.help_tooltips["updater_manual update"] := hwnd
	}

	Gui, update_notification: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %update_notification%
	ControlMove,,,, w,, % "ahk_id "vars.hwnd.update_notification.winbar
	For key in vars.hwnd.update_notification
	{
		If InStr("winbar, main", key)
			Continue
		ControlMove,,,, w - settings.general.fWidth*2,, % "ahk_id "vars.hwnd.update_notification[key]
	}
	Gui, update_notification: Show, NA Center
}
*/

UpdateParseVersion(string)
{
	local
	
	Loop, Parse, string
	{
		If (A_Index = 1)
			string := ""
		string .= (A_Index = 1) ? "1." : (A_Index = 3) ? A_LoopField "." : (InStr("47", A_Index) && A_LoopField = "0") ? "" : A_LoopField
	}
	Return string
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

LLK_CheckClipImages()
{
	local

	check := 0
	Loop, Parse, Clipboard, `n, `r
		check += InStr(".jpg.png.bmp", SubStr(A_LoopField, -3)) ? 0 : 1

	If !check
		Return 1
}

LLK_ControlGet(cHWND, GUI_name := "", subcommand := "")
{
	local
	
	If GUI_name
		GUI_name := GUI_name ": "
	GuiControlGet, parse, % GUI_name subcommand, % cHWND
	Return parse
}

LLK_ControlGetPos(cHWND, return_val)
{
	local

	ControlGetPos, x, y, width, height,, ahk_id %cHWND%
	Switch return_val
	{
		Case "x":
			Return x
		Case "y":
			Return y
		Case "w":
			Return width
		Case "h":
			Return height
	}
}

LLK_Drag(width, height, ByRef xPos, ByRef yPos, raw := 0, gui_name := "") ; raw parameter: 1 for GUIs with a static size that require raw coordinates
{
	local
	global vars
	
	protect := (vars.pixelsearch.gamescreen.x1 < 8) ? 8 : vars.pixelsearch.gamescreen.x1 + 1
	MouseGetPos, xPos, yPos
	If !gui_name
		gui_name := A_Gui

	If !gui_name
	{
		LLK_ToolTip("missing gui-name",,,,, "red")
		sleep 100
		Return
	}

	xPos -= vars.monitor.x, yPos -= vars.monitor.y
	If (xPos >= vars.monitor.w - 1)
		xPos := vars.monitor.w - 1

	If (xPos > vars.monitor.w / 2 - 1) && !raw
		xTarget := xPos - (width - 1)
	Else xTarget := xPos
	
	If (yPos >= vars.monitor.h - 1)
		yPos := vars.monitor.h - 1
	
	If (yPos > vars.monitor.h / 2 - 1) && !raw
		yTarget := yPos - (height - 1)
	Else yTarget := yPos
	
	;ToolTip, % xTarget ", " yTarget "`n" vars.client.x + vars.client.w - protect - 1 ", " vars.client.x + vars.client.w
	;If IsBetween(xTarget, vars.client.x + vars.client.w - protect - 1, vars.client.x + vars.client.w) && IsBetween(yTarget, vars.client.y, vars.pixelsearch.gamescreen.y1 + 1)
	If !raw && (xPos >= vars.client.x + vars.client.w - protect - 1) && (yTarget <= vars.client.y + vars.pixelsearch.gamescreen.y1 + 1)
		yTarget := vars.client.y + vars.pixelsearch.gamescreen.y1 + 1, yPos := yTarget

	If raw && (xTarget + width > vars.monitor.w)
		xTarget := vars.monitor.w - width, xPos := xTarget
	If raw && (yTarget + height > vars.monitor.h)
		yTarget := vars.monitor.h - height, yPos := yTarget

	Gui, %gui_name%: Show, % "NA x"vars.monitor.x + xTarget " y"vars.monitor.y + yTarget
	;WinMove, % "ahk_id "vars.hwnd.settings.main,, % vars.monitor.x + xTarget, % vars.monitor.y + yTarget
	
	If InStr(A_Gui, "notepad_drag") ;notepad and alarm have secondary squares with which to drag the main GUI
	{
		local notepad_gui := "notepad" StrReplace(A_Gui, "notepad_drag")
		Gui, %notepad_gui%: Show, NA x10000 x10000
		WinGetPos,,, w, h, % "ahk_id " vars.hwnd[notepad_gui]
		x := (xPos > vars.client.w / 2 - 1) ? xTarget - (w - 1) : xTarget
		y := (yPos > vars.client.h / 2 - 1) ? yTarget - (h - 1) : yTarget
		Gui, %notepad_gui%: Show, % "NA x"xScreenOffSet + x " y"yScreenOffSet + y
	}
	
	If (A_Gui = "alarm_drag")
	{
		Gui, alarm: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id " vars.hwnd.alarm
		x := (xPos > vars.client.w / 2 - 1) ? xTarget - (w - 1) : xTarget
		y := (yPos > vars.client.h / 2 - 1) ? yTarget - (h - 1) : yTarget
		Gui, alarm: Show, % "NA x"xScreenOffSet + x " y"yScreenOffSet + y
	}
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
	If !FileExist("data\Resolutions.ini") || !FileExist("data\Class_CustomFont.ahk") || !FileExist("data\Fontin-SmallCaps.ttf") || !FileExist("data\JSON.ahk") || !FileExist("data\External Functions.ahk") || !FileExist("data\Map mods.ini") || !FileExist("data\Betrayal.ini") || !FileExist("data\Atlas.ini") || !FileExist("data\timeless jewels\") || !FileExist("data\leveling tracker\")
		Return 0
	Else Return 1
}

LLK_FilePermissionError(issue)
{
	local

	text = 
	(LTrim
	The script couldn't %issue% a file/folder.

	There seem to be write-permission issues in the current folder location.
	Try moving the script to another location or running it as administrator.

	There is a write-permissions test in the settings menu that you can use to troubleshoot this issue.

	It's highly recommended to fix this issue as many features will not work correctly otherwise.
	)
	MsgBox, % text
}

LLK_FileRead(file)
{
	local

	FileRead, read, % file
	StringLower, read, read
	Return read
}

LLK_FindHWND(object, HWND)
{
	local

	For key, val in object
	{
		If IsObject(val)
		{
			result := LLK_FindHWND(val, HWND)
			If result
				Return [key, result]
		}
		Else If (val = HWND)
			Return key
	}
	Return
}

LLK_FontDefault()
{
	local
	global vars

	Return LLK_IniRead("data\Resolutions.ini", vars.monitor.h "p", "font", 16)
}

LLK_FontDimensions(size, ByRef font_height_x, ByRef font_width_x)
{
	local

	Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border
	Gui, font_size: Margin, 0, 0
	Gui, font_size: Color, Black
	Gui, font_size: Font, % "cWhite s"size, Fontin SmallCaps
	Gui, font_size: Add, Text, % "Border HWNDhwnd", % "7"
	GuiControlGet, font_check_, Pos, % hwnd
	font_height_x := font_check_h
	font_width_x := font_check_w
	Gui, font_size: Destroy
}

LLK_FontSizeGet(height, ByRef font_width) ;returns a font-size that's about the height passed to the function
{
	local

	Gui, font_size: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow
	Gui, font_size: Margin, 0, 0
	Gui, font_size: Color, Black
	Loop
	{
		Gui, font_size: Font, % "cWhite s"A_Index, Fontin SmallCaps
		Gui, font_size: Add, Text, % "Border HWNDhwnd", % "7"
		ControlGetPos,,, font_width, font_height,, % "ahk_id "hwnd
		check += (font_height > height) ? 1 : 0
		If check
		{
			Gui, font_size: Destroy ;it would be technically correct to return A_Index - 1 (i.e. the last index where font_height was still lower than height), but there is a lot of leeway with font-heights ;cont
			Return A_Index + 2 ;because every text exclusively uses lower-case letters
		}
	}
}

LLK_IniRead(file, section := "", key := "", default := "")
{
	IniRead, iniread, % file, % section, % key, % !default ? A_Space : default
	If (default != "") && (iniread = "") ;IniRead's 'default' is only read if the key cannot be found in the ini-file
		Return default ;if the key in the ini-file is blank, the target-variable will also be blank (instead of storing 'default')
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
	{
		If (A_Loopfield = character)
			count += 1
	}
	Return count
}

LLK_IsBetween(var, x, y)
{
	If var between %x% and %y%
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

LLK_Overlay(guiHWND, mode := "show", NA := 1)
{
	local
	global vars, settings, Json
	
	If Blank(guiHWND)
		Return

	check := 0
	For index, val in vars.GUI
		If LLK_HasVal(val, guiHWND)
			check := index

	If (guiHWND = "hide")
	{
		For index, val in vars.GUI
		{
			If (val.1 = vars.hwnd.settings.main) && (vars.settings.active = "betrayal-info") || !WinExist("ahk_id "val.1)
				Continue
			Gui, % val.1 ": Hide"
		}
	}
	Else If (guiHWND = "show")
	{
		For index, val in vars.GUI
		{
			ControlGetPos, x,,,,, % "ahk_id "val.3
			If !val.2 || Blank(x)
				Continue
			Gui, % val.1 ": Show", NA
		}
	}
	Else If (mode="show")
	{
		If !check
		{
			Gui, %guiHWND%: Add, Text, Hidden x0 y0 HWNDhwnd, % "" ;add a dummy text-control to the GUI with which to check later on if it has been destroyed already (via ControlGetPos)
			vars.GUI.Push([guiHWND, 1, hwnd])
		}
		Else vars.GUI[check].2 := 1
		Gui, %guiHWND%: Show, % (NA ? "NA" : "")
	}
	Else If (mode="hide")
	{
		If WinExist("ahk_id "guiHWND)
			Gui, %guiHWND%: Hide
		vars.GUI[check].2 := 0
	}
	Else If (mode = "destroy")
	{
		If check
			ControlGetPos, x,,,,, % "ahk_id "vars.GUI[check].3
		If WinExist("ahk_id "guiHWND) || !Blank(x)
			Gui, %guiHWND%: Destroy
	}
	For index, array in vars.GUI
	{
		ControlGetPos, x,,,,, % "ahk_id "array.3
		If Blank(x)
			remove .= index ";"
	}
	Loop, Parse, remove, `;
		If IsNumber(A_LoopField)
			vars.GUI.RemoveAt(A_LoopField)
}

LLK_PanelDimensions(array, fSize, ByRef width, ByRef height, align := "left", header_offset := 0, margins := 1)
{
	Gui, panel_dimensions: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow
	Gui, panel_dimensions: Margin, 0, 0
	Gui, panel_dimensions: Color, Black
	Gui, panel_dimensions: Font, % "s"fSize + header_offset " cWhite", Fontin SmallCaps
	width := 0, height := 0
	
	For key, val in array
	{
		font := InStr(val, "(/bold)") ? "bold" : "", font .= InStr(val, "(/underline)") ? (font ? " " : "") "underline" : "", font := !font ? "norm" : font
		Gui, panel_dimensions: Font, % font
		val := StrReplace(StrReplace(val, "(/bold)"), "(/underline)")
		Gui, panel_dimensions: Add, Text, % align " HWNDhwnd Border", % header_offset && (A_Index = 1) ? " " val : margins ? " " val " " : val
		Gui, panel_dimensions: Font, % "norm s"fSize
		WinGetPos,,, w, h, ahk_id %hwnd%
		height := (h > height) ? h : height
		width := (w > width) ? w : width
	}
	
	Gui, panel_dimensions: Destroy
	;width := Format("{:0.0f}", width* 1.25)
	While Mod(width, 2)
		width += 1
	While Mod(height, 2)
		height += 1
}

LLK_Progress(HWND_bar, key, HWND_control := "") ;HWND_bar = HWND of the progress bar, key = key that is held down to fill the progress bar, HWND_control = HWND of the button (to undo clipping)
{
	global
	local start := A_TickCount, wMouse := vars.general.wMouse
	
	While GetKeyState(key, "P")
	{
		GuiControl,, %HWND_bar%, % A_TickCount - start
		If (A_TickCount >= start + 600)
		{
			GuiControl,, %HWND_bar%, 0 ;reset the progress bar to 0
			If HWND_control
				GuiControl, movedraw, %HWND_control% ;redraw the button that was held down (otherwise the progress bar will remain on top of it)
			Return 1
		}
		Sleep 5
	}
	GuiControl,, %HWND_bar%, 0
	If HWND_control
		GuiControl, movedraw, %HWND_control%
	Return 0
}

LLK_StringCase(string, mode := 0, title := 0)
{
	If mode
		StringUpper, string, % string, % title ? "T" : ""
	Else StringLower, string, % string, % title ? "T" : ""
	Return string
}

LLK_StringRemove(string, characters)
{
	Loop, Parse, characters, `,
	{
		If (A_LoopField = "")
			Continue
		string := StrReplace(string, A_LoopField)
	}
	Return string
}

LLK_ToolTip(message, duration := 1, x := "", y := "", name := "", color := "White", size := "", align := "", trans := "", center := 0)
{
	local
	global vars, settings

	If !name
		name := 1

	vars.tooltip.wait := 1

	If !size
		size := settings.general.fSize

	If !trans
		trans := 255

	If align
		align := " " align
	
	xPos := InStr(x, "+") || InStr(x, "-") ? vars.general.xMouse + x : (x != "") ? x : vars.general.xMouse
	yPos := InStr(y, "+") || InStr(y, "-") ? vars.general.yMouse + y : (y != "") ? y : vars.general.yMouse
	
	Gui, tooltip%name%: New, % "-DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border +E0x02000000 +E0x00080000 HWNDhwnd"
	Gui, tooltip%name%: Color, Black
	Gui, tooltip%name%: Margin, % settings.general.fwidth / 2, 0
	WinSet, Transparent, % trans
	Gui, tooltip%name%: Font, % "s" size* (name = "update" ? 1.4 : 1) " cWhite", Fontin SmallCaps
	vars.hwnd["tooltip"name] := hwnd
	
	Gui, tooltip%name%: Add, Text, % "c"color align , % message
	Gui, tooltip%name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h
	
	If center
		xPos -= w//2
	xPos := (xPos + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos
	If IsNumber(y)
		yPos := (yPos + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : yPos
	Else yPos := (yPos - h < vars.monitor.y) ? vars.monitor.y + h : yPos

	If (name = "update")
		Gui, tooltip%name%: Show, % "NA xCenter" " y"vars.client.y
	Else Gui, tooltip%name%: Show, % "NA x"xPos " y"yPos - (y = "" || InStr(y, "+") || InStr(y, "-") ? h : 0)

	If duration
		vars.tooltip[vars.hwnd["tooltip"name]] := A_TickCount + duration* 1000
	Else LLK_Overlay(vars.hwnd["tooltip"name], "show")
	vars.tooltip.wait := 0
}
