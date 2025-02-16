#NoEnv
#SingleInstance Force
#Requires AutoHotkey >=1.1.36 <2
#MaxThreads 255
#MaxMem 1024
#Include %A_WorkingDir%
#Include data\External Functions.ahk
#Include data\JSON.ahk
#Persistent

vars := {"general": {}, "hwnd": {}, "log": {}, "sanctum": {}, "settings": {}}
settings := {}
If !(vars.general.Gdip := Gdip_Startup(1))
	ExitApp

DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
StringCaseSense, Locale
SetKeyDelay, 100
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetTitleMatchMode, 2
SetBatchLines, -1
Menu, Tray, Tip, Lailloken UI B-Thread
OnMessage(0x004A, "StringReceive")
OnMessage(0x8000, "Exit")
OnMessage(0x8001, "Cloneframes")

Gui, comms_window: New, -Caption +ToolWindow +LastFound +AlwaysOnTop HWNDhwnd_comms, LLK-UI: B-Thread
Gui, comms_window: Add, Text, % "cBlack HWNDhwnd w100 h100"
vars.hwnd.comms := hwnd
Gui, comms_window: Show, NA x2000 y0 w100 h100

vars.poe_version := CheckClient()
SetTimer, Loop, 1000
SetTimer, Loop_main, 50
Return

#Include modules\_functions.ahk
#Include modules\betrayal-info.ahk
#Include modules\cheat sheets.ahk
#Include modules\client log.ahk
#Include modules\clone-frames.ahk
#Include modules\GUI.ahk
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

Cloneframes(wParam, lParam)
{
	local
	global vars

	vars.cloneframes.wait := 1
	If (wParam + lParam = 0)
		Init_cloneframes()
	vars.cloneframes.wait := 0
}

Exit()
{
	local
	global vars

	Gdip_Shutdown(vars.general.Gdip)
	ExitApp
}

Loop()
{
	local
	global vars

	If vars.PID ;in case the main thread crashes without sending the 0x8000 message
	{
		Process, Exist, % vars.PID
		If !ErrorLevel
			ExitApp
	}
}

Loop_main()
{
	local
	global vars
	static cloneframes_hidden

	Critical
	If LLK_StringCompare(vars.log.areaID, ["Sanctum"]) && WinExist("LLK-UI: Sanctum Overlay")
		vars.sanctum.active := 1
	Else vars.sanctum.active := 0

	If (check := WinExist("LLK-UI: Settings Menu ("))
	{
		WinGetTitle, title, % "LLK-UI: Settings Menu ("
		title := SubStr(title, InStr(title, "(") + 1), vars.settings.active := SubStr(title, 1, -1)
	}
	Else vars.settings.active := ""

	start := A_TickCount
	If !vars.cloneframes.wait && IsObject(vars.cloneframes) && !vars.wait
		Cloneframes_Check(), cloneframes_hidden := 0
	If vars.wait && !cloneframes_hidden
		Cloneframes_Hide(), cloneframes_hidden := 1
}

Loop_screen()
{
	local
	global vars, settings

	
}

StringReceive(wParam, string) ;based on example #4 on https://www.autohotkey.com/docs/v1/lib/OnMessage.htm
{
	local
	global vars, json

	StringAddress := NumGet(string + 2*A_PtrSize), string := StrGet(StringAddress), editing := vars.cloneframes.editing
	If (SubStr(string, 1, 1) . SubStr(string, 0) = "{}")
		For key, val in json.load(string)
			vars[key] := IsObject(val) ? val.Clone() : val
	Else If InStr(string, "wait=")
		vars.wait := SubStr(string, InStr(string, "=") + 1)
	Else If InStr(string, "areaID=")
		vars.log.areaID := SubStr(string, InStr(string, "=") + 1)
	Else If InStr(string, "clone-edit=")
	{
		vars.cloneframes.wait := 1
		If RegExMatch(string, "\{.*\}")
			vars.cloneframes.list[editing] := json.load(SubStr(string, InStr(string, "=") + 1))
		Else vars.cloneframes.editing := SubStr(string, InStr(string, "=") + 1)
		vars.cloneframes.wait := 0
	}
	ToolTip, %A_ScriptName%`nReceived the following string:`n%string%`n%A_TickCount%, 0, 0

	If InStr(string, """client"":")
		Init_cloneframes()
	Return true
}

;dummy-hotkeys #############################################################
#If settings.maptracker.kills && settings.features.maptracker && (vars.maptracker.refresh_kills = 1) ;pre-defined context for hotkey command
#If WinExist("ahk_id "vars.hwnd.horizons.main) ;pre-defined context for hotkey command
#If WinActive("ahk_group poe_ahk_window") && vars.hwnd.leveltracker.main ;pre-defined context for hotkey command
#If (vars.log.areaID = vars.maptracker.map.id) && settings.features.maptracker && settings.maptracker.mechanics && settings.maptracker.portal_reminder && vars.maptracker.map.content.Count() && WinActive("ahk_id " vars.hwnd.poe_client) ;pre-defined context for hotkey command
#If vars.hwnd.stash.main && WinExist("ahk_id " vars.hwnd.stash.main) && InStr(vars.stash.hover, "tab_")
#If vars.hwnd.stash.main && WinExist("ahk_id " vars.hwnd.stash.main) && IsObject(vars.stash.regex)
&& LLK_IsBetween(vars.general.xMouse, vars.client.x + vars.stash.regex.x, vars.client.x + vars.stash.regex.x + vars.stash.regex.w)
&& LLK_IsBetween(vars.general.yMouse, vars.client.y + vars.stash.regex.y, vars.client.y + vars.stash.regex.y + vars.stash.regex.h)
#If vars.leveltracker.skilltree_schematics.GUI && WinExist("ahk_id " vars.hwnd.skilltree_schematics.main)
#If settings.features.sanctum && vars.sanctum.active && WinExist("ahk_id " vars.hwnd.sanctum.second) && !vars.sanctum.lock ;last condition needed to make the space-key usable again after initial lock
#If settings.features.sanctum && vars.sanctum.active && WinExist("ahk_id " vars.hwnd.sanctum.second)
#If settings.features.sanctum && vars.sanctum.active && WinExist("ahk_id " vars.hwnd.sanctum.main) && (vars.general.wMouse = vars.hwnd.sanctum.main) && vars.general.cMouse && (check := LLK_HasVal(vars.hwnd.sanctum, vars.general.cMouse))
#If vars.hwnd.stash_picker.main && vars.general.cMouse && WinExist("ahk_id " vars.hwnd.stash_picker.main) && LLK_PatternMatch(LLK_HasVal(vars.hwnd.stash_picker, vars.general.cMouse), "", ["confirm_", "bulk"])
#If vars.hwnd.stash.main && WinActive("ahk_id " vars.hwnd.poe_client) && WinExist("ahk_id " vars.hwnd.stash.main)
#If WinActive("ahk_id " vars.hwnd.poe_client) && vars.stash.enter
#If vars.general.wMouse && (vars.general.wMouse = vars.hwnd.ClientFiller) ;prevent clicking and activating the filler GUI
#If vars.OCR.GUI ;sending inputs for screen-reading
#If vars.hwnd.ocr_tooltip.main && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.ocr_tooltip.main) ;hovering over the ocr tooltip
#If vars.snipping_tool.GUI && WinActive("ahk_id " vars.hwnd.snipping_tool.main)
#If vars.hwnd.ocr_tooltip.main && WinExist("ahk_id " vars.hwnd.ocr_tooltip.main)
#If !vars.mapinfo.toggle && (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.poe_client) && WinExist("ahk_id "vars.hwnd.mapinfo.main) ;clicking the client to hide the map-info tooltip
#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.wMouse)) && vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.cMouse)) ;hovering the lab-layout button and clicking a room
#If (vars.system.timeout = 0) && vars.general.wMouse && (LLK_HasVal(vars.hwnd.lab, vars.general.wMouse) = "button") ;hovering the lab-layout button and clicking it
#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.wMouse)) && vars.general.cMouse && Blank(LLK_HasVal(vars.hwnd.lab, vars.general.cMouse))
#If vars.hwnd.notepad.main && (vars.general.cMouse = vars.hwnd.notepad.note) && WinActive("ahk_id " vars.hwnd.notepad.main)
#If (vars.system.timeout = 0) && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.LLK_panel.main)
#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse)) ;hovering a notepad-widget and dragging or deleting it
#If (vars.system.timeout = 0) && vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.leveltracker_zones, vars.general.cMouse)) ;hovering the leveling-guide layouts and dragging them
#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.maptracker.main) && !Blank(LLK_HasVal(vars.hwnd.maptracker, vars.general.cMouse)) ;hovering the maptracker-panel and clicking valid elements
#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.maptracker.main) ;prevent clicking the maptracker-panel (and losing focus of the game-client) if not hovering valid elements
#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.leveltracker.controls1) && !Blank(LLK_HasVal(vars.hwnd.leveltracker, vars.general.cMouse)) ;hovering the leveltracker-controls and clicking
#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.alarm.main) && !Blank(LLK_HasVal(vars.hwnd.alarm, vars.general.cMouse)) ;hovering the alarm-timer and clicking
#If (vars.system.timeout = 0) && ((vars.general.wMouse = vars.hwnd.mapinfo.main) && !Blank(LLK_HasVal(vars.hwnd.mapinfo, vars.general.cMouse)) || (vars.general.wMouse = vars.hwnd.settings.main) && InStr(LLK_HasVal(vars.hwnd.settings, vars.general.cMouse), "mapmod_")) ;ranking map-mods
#If (vars.system.timeout = 0) && settings.maptracker.loot && (vars.general.xMouse > vars.monitor.x + vars.monitor.w/2) ;ctrl-clicking loot into stash and logging it
#If !(vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse))) && vars.leveltracker.overlays ;resizing zone-layout images
#If settings.leveltracker.pobmanual && settings.leveltracker.pob && WinActive("ahk_exe Path of Building.exe") && !WinExist("ahk_id " vars.hwnd.leveltracker_screencap.main) ;opening the screen-cap menu via m-clicking in PoB
#If (vars.tooltip_mouse.name = "searchstring") ;scrolling through sub-strings in search-strings
#If (vars.system.timeout = 0) && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.iteminfo.main) && WinActive("ahk_group poe_ahk_window") ;applying highlighting to item-mods in the item-info tooltip
#If (settings.iteminfo.trigger || settings.mapinfo.trigger) && vars.general.shift_trigger && (vars.general.wMouse = vars.hwnd.poe_client) ;shift-clicking currency onto items and triggering certain features
#If (settings.iteminfo.trigger || settings.mapinfo.trigger) && !vars.general.shift_trigger && (vars.general.wMouse = vars.hwnd.poe_client) && Screenchecks_PixelSearch("inventory")
;shift-right-clicking currency to shift-click items after
#If vars.hwnd.searchstrings_context && WinExist("ahk_id " vars.hwnd.searchstrings_context) && (vars.general.wMouse = vars.hwnd.poe_client) ;closing the search-strings context menu when clicking into the client
#If vars.hwnd.omni_context.main && WinExist("ahk_id " vars.hwnd.omni_context.main) && (vars.general.wMouse = vars.hwnd.poe_client) ;closing the omni-key context menu when clicking into the client
#If (vars.hwnd.iteminfo.main && WinExist("ahk_id " vars.hwnd.iteminfo.main) || vars.hwnd.iteminfo_markers.1 && WinExist("ahk_id " vars.hwnd.iteminfo_markers.1)) && (vars.general.wMouse = vars.hwnd.poe_client)
;closing the item-info tooltip and its markers when clicking into the client
#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.iteminfo_comparison, vars.general.wMouse)) ;long-clicking the gear-update buttons on gear-slots in the inventory to update/remove selected gear
#If vars.cloneframes.editing && vars.general.cMouse && !Blank(LLK_HasVal(vars.cloneframes.scroll, vars.general.cMouse))
#If (vars.general.wMouse != vars.hwnd.settings.main) && WinExist("LLK-UI: Clone-Frames Borders") ;moving clone-frame borders via clicks
#If WinActive("ahk_id "vars.hwnd.snip.main) ;moving the snip-widget via arrow keys
#If vars.cheatsheets.tab && vars.hwnd.cheatsheet.main && WinExist("ahk_id " vars.hwnd.cheatsheet.main) ;clearing the cheatsheet quick-access (unused atm)
#If vars.general.wMouse && vars.hwnd.cheatsheet.main && (vars.general.wMouse = vars.hwnd.cheatsheet.main) && (vars.cheatsheets.active.type = "advanced") ;ranking things in advanced cheatsheets
#If vars.general.wMouse && vars.hwnd.betrayal_info.main && (vars.general.wMouse = vars.hwnd.betrayal_info.main) ;ranking betrayal rewards
#If (vars.cheatsheets.active.type = "image") && vars.hwnd.cheatsheet.main && !vars.cheatsheets.tab && WinExist("ahk_id " vars.hwnd.cheatsheet.main) ;image-cheatsheet hotkeys
#IfWinActive ahk_group poe_window
#IfWinActive ahk_group poe_ahk_window
#If

;dummy-functions ################################################
Hotkeys_RemoveModifiers(a := "", b := "", c := "", d := "")
{
	Return
}

Hotkeys_Convert(a := "", b := "", c := "", d := "")
{
	Return
}

Init_hotkeys(a := "", b := "", c := "", d := "")
{
	Return
}

/*
Geartracker_Add(a := "", b := "", c := "", d := "")
{
	Return
}

Geartracker_GUI(a := "", b := "", c := "", d := "")
{
	Return
}

Init_Leveltracker(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Experience(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_GuideEditor(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Hotkeys(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Import(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Load(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_PobGemLinks(a := "", b := "", c := "", d := "", e := "")
{
	Return
}

Leveltracker_PobSkilltree(a := "", b := "", c := "", d := "", e := "")
{
	Return
}

Leveltracker_Progress(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_ProgressReset(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_ScreencapMenu(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Skilltree(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Timer(a := "", b := "", c := "", d := "")
{
	Return
}

Leveltracker_Toggle(a := "", b := "", c := "", d := "")
{
	Return
}
*/
