Init_hotkeys()
{
	local
	global vars, settings, db
	
	settings.hotkeys := {}
	settings.hotkeys.rebound_alt := LLK_IniRead("ini\hotkeys.ini", "Settings", "advanced item-info rebound", 0)
	settings.hotkeys.item_descriptions := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "item-descriptions key")
	If !settings.hotkeys.item_descriptions
		settings.hotkeys.rebound_alt := 0
	settings.hotkeys.rebound_c := LLK_IniRead("ini\hotkeys.ini", "Settings", "c-key rebound", 0)
	settings.hotkeys.movekey := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "move-key", "lbutton")
	settings.hotkeys.omniblock := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "block omnikey's native function", 0)
	settings.hotkeys.omnikey := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "omni-hotkey", "MButton")
	settings.hotkeys.omnikey2 := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "omni-hotkey2")
	
	If !settings.hotkeys.omnikey2
		settings.hotkeys.rebound_c := 0
	settings.hotkeys.tab := LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "tab replacement", "tab")
	settings.hotkeys.tabblock := (settings.hotkeys.tab = "capslock") ? 1 : LLK_IniRead("ini\hotkeys.ini", "Hotkeys", "block tab-key's native function", 0)

	Hotkey, If, settings.maptracker.kills && settings.features.maptracker && (vars.maptracker.refresh_kills = 1)
	Hotkey, % settings.hotkeys.omnikey, MapTrackerKills, On
	
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	If !settings.hotkeys.rebound_c
	{
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey, Omnikey, On
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey " UP", OmniRelease, On
	}
	Else
	{
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey2, Omnikey, On
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey2 " UP", OmniRelease, On
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey, Omnikey2, On
		Hotkey, % (!settings.hotkeys.omniblock ? "*~" : "*") settings.hotkeys.omnikey " UP", OmniRelease, On
	}

	Hotkey, If, (vars.cheatsheets.active.type = "image") && vars.hwnd.cheatsheet.main && !vars.cheatsheets.tab && WinExist("ahk_id " vars.hwnd.cheatsheet.main)
	Hotkey, % settings.hotkeys.tab, CheatsheetTAB, On
		
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	Hotkey, % settings.hotkeys.tab, HotkeysTab, On

	Hotkey, If, WinExist("ahk_id "vars.hwnd.horizons.main)
	Loop, Parse, % "abcdefghijklmnopqrstuvwxyz"
		Hotkey, % "*" A_LoopField, HorizonsTooltip, On

	Loop, Parse, % "*~!+#^"
		settings.hotkeys.tab := StrReplace(settings.hotkeys.tab, A_LoopField), settings.hotkeys.omnikey := StrReplace(settings.hotkeys.omnikey, A_LoopField), settings.hotkeys.omnikey2 := StrReplace(settings.hotkeys.omnikey2, A_LoopField)
}

HotkeysESC()
{
	local
	global vars, settings
	
	If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id "vars.hwnd.cloneframe_borders.main)
		CloneframesSettingsRefresh()
	Else If WinExist("LLK-UI: notepad reminder")
		WinActivate, ahk_group poe_window
	Else If WinExist("ahk_id "vars.hwnd.tooltipgem_notes)
	{
		Gui, tooltipgem_notes: Destroy
		vars.hwnd.Delete("tooltipgem_notes")
	}
	Else If WinExist("ahk_id " vars.hwnd.maptracker_logs.sum_tooltip)
		Gui, maptracker_tooltip: Destroy
	Else If WinExist("ahk_id "vars.hwnd.legion.main)
		LegionClose()
	Else If WinActive("ahk_id "vars.hwnd.alarm.alarm_set)
		Gui, alarm_set: Destroy
	Else If WinExist("ahk_id " vars.hwnd.maptracker_dates.main)
		LLK_Overlay(vars.hwnd.maptracker_dates.main, "destroy")
	Else If WinExist("ahk_id " vars.hwnd.maptracker_logs.maptracker_edit)
		Gui, maptracker_edit: Destroy
	Else If WinExist("ahk_id " vars.hwnd.maptrackernotes_edit.main)
		LLK_Overlay(vars.hwnd.maptrackernotes_edit.main, "destroy")
	Else If WinExist("ahk_id "vars.hwnd.mapinfo.main)
		LLK_Overlay(vars.hwnd.mapinfo.main, "destroy")
	Else If vars.maptracker.loot
		MaptrackerGUI()
	Else If WinExist("ahk_id "vars.hwnd.maptracker_logs.main)
	{
		LLK_Overlay(vars.hwnd.maptracker_logs.main, "destroy")
		WinActivate, ahk_group poe_window
	}
	Else If WinExist("ahk_id "vars.hwnd.geartracker.main)
		GeartrackerGUI("toggle")
	Else If WinExist("ahk_id " vars.hwnd.searchstrings_context)
	{
		Gui, searchstrings_context: Destroy
		vars.hwnd.Delete("searchstrings_context")
	}
	Else If WinExist("ahk_id " vars.hwnd.omni_context.main)
	{
		Gui, omni_context: Destroy
		vars.hwnd.Delete("omni_context")
	}
	Else If WinExist("ahk_id " vars.hwnd.cheatsheet_calibration.main)
	{
		Gui, cheatsheet_calibration: Destroy
		vars.hwnd.Delete("cheatsheet_calibration")
	}
	Else If WinExist("ahk_id " vars.hwnd.cheatsheet.main)
		CheatsheetClose()
	Else If WinExist("ahk_id " vars.hwnd.iteminfo.main) || WinExist("ahk_id " vars.hwnd.iteminfo_markers.1)
		IteminfoClose(1)
	Else
	{
		SendInput, {ESC down}
		KeyWait, ESC
		SendInput, {ESC up}
	}
}

HotkeysTab()
{
	local
	global vars, settings
		
	start := A_TickCount

	While settings.general.hide_toolbar && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			active .= " LLK-panel"
			LLK_Overlay(vars.hwnd.LLK_panel.main, "show")
			Break
		}

	While settings.qol.alarm && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			active .= " alarm", vars.alarm.toggle := 1, Alarm()
			Break
		}

	While settings.qol.notepad && vars.hwnd.notepad_widgets.Count() && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			active .= " notepad", vars.notepad.toggle := 1
			For key, val in vars.hwnd.notepad_widgets
			{
				Gui, % GuiName(val) ": -E0x20"
				WinSet, Transparent, Off, % "ahk_id "val
			}
			Break
		}

	If vars.hwnd.leveltracker.main
		leveltracker_check := LLK_Overlay(vars.hwnd.leveltracker.main, "check")
	
	While vars.leveltracker.toggle && !(settings.qol.lab && InStr(vars.log.areaID, "labyrinth") && !InStr(vars.log.areaID, "_trials_")) && leveltracker_check && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			active .= " leveltracker", vars.leveltracker.overlays := 1, LeveltrackerZoneLayouts(), LeveltrackerHints()
			Break
		}
	map := vars.mapinfo.active_map
	While settings.features.mapinfo && settings.mapinfo.tabtoggle && map.name && GetKeyState(settings.hotkeys.tab, "P")
	&& (LLK_HasVal(vars.mapinfo.categories, vars.log.areaname, 1) || InStr(map.name, vars.log.areaname) || InStr(vars.log.areaID, "hideout") || InStr(vars.log.areaID, "heisthub") || InStr(map.english, "invitation") && LLK_PatternMatch(vars.log.areaID, "", ["MavenHub", "PrimordialBoss"]))
		If (A_TickCount >= start + 200)
		{
			active .= " mapinfo", vars.mapinfo.toggle := 1, MapinfoGUI(2)
			Break
		}

	While settings.features.maptracker && !vars.maptracker.pause && MaptrackerCheck(2) && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			vars.maptracker.toggle := 1, active .= " maptracker", MaptrackerGUI()
			If settings.maptracker.mechanics
				SetTimer, MaptrackerMechanicsCheck, -1
			Break
		}

	While settings.qol.lab && InStr(vars.log.areaID, "labyrinth") && !InStr(vars.log.areaID, "_trials") && GetKeyState(settings.hotkeys.tab, "P")
		If (A_TickCount >= start + 200)
		{
			active .= " lab", vars.lab.toggle := 1, Lab()
			Break
		}
	
	If !settings.hotkeys.tabblock && !active
	{
		SendInput, % "{" settings.hotkeys.tab " DOWN}"
		KeyWait, % settings.hotkeys.tab
		SendInput, % "{" settings.hotkeys.tab " UP}"
	}
	Else KeyWait, % settings.hotkeys.tab
	
	If InStr(active, "LLK-panel")
		LLK_Overlay(vars.hwnd.LLK_panel.main, "hide")
	If InStr(active, "alarm")
	{
		vars.alarm.toggle := 0
		If !vars.alarm.timestamp || (vars.alarm.timestamp > A_Now)
			LLK_Overlay(vars.hwnd.alarm.main, "destroy")
	}
	If InStr(active, "notepad")
	{
		vars.notepad.toggle := 0
		For key, val in vars.hwnd.notepad_widgets
		{
			Gui, % GuiName(val) ": +E0x20"
			WinSet, Transparent, % (key = "notepad_reminder_feature") ? 250 : 50 * settings.notepad.trans, % "ahk_id "val
		}
	}
	If InStr(active, "leveltracker")
	{
		LLK_Overlay(vars.hwnd.leveltracker_zones.main, "destroy"), vars.leveltracker.overlays := 0
		If (settings.leveltracker.sLayouts != LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts size"))
			IniWrite, % settings.leveltracker.sLayouts, ini\leveling tracker.ini, Settings, zone-layouts size
	}
	If InStr(active, "mapinfo")
		LLK_Overlay(vars.hwnd.mapinfo.main, "destroy"), vars.mapinfo.toggle := 0
	If InStr(active, "maptracker")
		vars.maptracker.toggle := 0, LLK_Overlay(vars.hwnd.maptracker.main, "hide")
	If InStr(active, " lab") && WinExist("ahk_id "vars.hwnd.lab.main)
		LLK_Overlay(vars.hwnd.lab.main, "destroy"), LLK_Overlay(vars.hwnd.lab.button, "destroy"), vars.lab.toggle := 0
	If active
		WinActivate, ahk_group poe_window
}

#If settings.maptracker.kills && settings.features.maptracker && (vars.maptracker.refresh_kills = 1) ;pre-defined context for hotkey command
#If WinExist("ahk_id "vars.hwnd.horizons.main) ;pre-defined context for hotkey command

#If vars.general.wMouse && (vars.general.wMouse = vars.hwnd.ClientFiller) ;prevent clicking and activating the filler GUI
*MButton::
*LButton::
*RButton::Return

#If (vars.log.areaID = vars.maptracker.map.id) && settings.features.maptracker && settings.maptracker.mechanics && settings.maptracker.portal_reminder && vars.pixelsearch.inventory.check && vars.maptracker.map.content.Count() && (vars.general.xMouse > vars.monitor.x + vars.client.xc)

~RButton UP::MaptrackerReminder()

#If !vars.mapinfo.toggle && (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.poe_client) && WinExist("ahk_id "vars.hwnd.mapinfo.main) ;clicking the client to hide the map-info tooltip

LButton::LLK_Overlay(vars.hwnd.mapinfo.main, "destroy")

#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.wMouse)) && vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.cMouse)) ;hovering the lab-layout button and clicking a room

*LButton::Lab("override")
*RButton::Return

#If (vars.system.timeout = 0) && vars.general.wMouse && (LLK_HasVal(vars.hwnd.lab, vars.general.wMouse) = "button") ;hovering the lab-layout button and clicking it

*LButton::Lab("link")
*RButton::Return

#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.lab, vars.general.wMouse)) && vars.general.cMouse && Blank(LLK_HasVal(vars.hwnd.lab, vars.general.cMouse))

*LButton::Return
*RButton::Return

#If (vars.system.timeout = 0) && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.LLK_panel.main)

*LButton::GuiToolbarButtons(vars.general.cMouse, 1)
*RButton::GuiToolbarButtons(vars.general.cMouse, 2)

#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse)) ;hovering a notepad-widget and dragging or deleting it

*LButton::NotepadWidget(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse), 1)
*RButton::NotepadWidget(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse), 2)
*WheelUp::NotepadWidget(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse), 3)
*WheelDown::NotepadWidget(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse), 4)

#If (vars.system.timeout = 0) && vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.leveltracker_zones, vars.general.cMouse)) ;hovering the leveling-guide layouts and dragging them

*LButton::LeveltrackerZoneLayouts(0, 1, vars.general.cMouse)
*RButton::LeveltrackerZoneLayouts(0, 2, vars.general.cMouse)

#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.maptracker.main) && !Blank(LLK_HasVal(vars.hwnd.maptracker, vars.general.cMouse)) ;hovering the maptracker-panel and clicking valid elements

*LButton::Maptracker(vars.general.cMouse, 1)
*RButton::Maptracker(vars.general.cMouse, 2)

#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.maptracker.main) ;prevent clicking the maptracker-panel (and losing focus of the game-client) if not hovering valid elements
*LButton::
*RButton::Return

#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.leveltracker.controls1) && !Blank(LLK_HasVal(vars.hwnd.leveltracker, vars.general.cMouse)) ;hovering the leveltracker-controls and clicking

*LButton::Leveltracker(vars.general.cMouse, 1)
*RButton::Leveltracker(vars.general.cMouse, 2)

#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.alarm.main) && !Blank(LLK_HasVal(vars.hwnd.alarm, vars.general.cMouse)) ;hovering the alarm-timer and clicking

*LButton::Alarm(1)
*RButton::Alarm(2)

#If (vars.system.timeout = 0) && (vars.general.wMouse = vars.hwnd.mapinfo.main) && !Blank(LLK_HasVal(vars.hwnd.mapinfo, vars.general.cMouse)) ;ranking map-mods

*1::
*2::
*3::
*4::
*Space::MapinfoRank(A_ThisHotkey)

#If (vars.system.timeout = 0) && settings.maptracker.loot && (vars.general.xMouse > vars.monitor.x + vars.monitor.w/2) ;ctrl-clicking loot into stash and logging it

~*^LButton::MaptrackerLoot()
^RButton::MaptrackerLoot("back")

#If !(vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.notepad_widgets, vars.general.wMouse))) && vars.leveltracker.overlays ;resizing zone-layout images

MButton::
WheelUp::
WheelDown::LeveltrackerZoneLayoutsSize(A_ThisHotkey)

#If settings.leveltracker.pob && WinActive("ahk_exe Path of Building.exe") && !WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main) ;opening the screen-cap menu via m-clicking in PoB

MButton::LeveltrackerScreencapMenu()

#If (vars.tooltip_mouse.name = "searchstring") ;scrolling through sub-strings in search-strings

ESC::
WheelUp::
WheelDown::StringScroll(A_ThisHotkey)

#If (vars.system.timeout = 0) && vars.general.wMouse && (vars.general.wMouse = vars.hwnd.iteminfo.main) && WinActive("ahk_group poe_ahk_window") ;applying highlighting to item-mods in the item-info tooltip

*LButton::
*RButton::
If vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.iteminfo, vars.general.cMouse)) ;this check prevents the tooltip from being clicked/activated (since the L/RButton press is not sent to the client)
	IteminfoHighlightApply(vars.general.cMouse)
Else If vars.general.cMouse && !Blank(LLK_HasVal(vars.hwnd.iteminfo.inverted_mods, vars.general.cMouse))
	IteminfoModInvert(vars.general.cMouse)
Return

#If (settings.iteminfo.trigger || settings.mapinfo.trigger) && vars.general.shift_trigger && (vars.general.wMouse = vars.hwnd.poe_client) ;shift-clicking currency onto items and triggering certain features

~+LButton UP::IteminfoTrigger(1)
+RButton::IteminfoMarker()

#If vars.pixelsearch.inventory.check && (settings.iteminfo.trigger || settings.mapinfo.trigger) && !vars.general.shift_trigger && (vars.general.wMouse = vars.hwnd.poe_client) ;shift-right-clicking currency to shift-click items after

~+RButton UP::IteminfoTrigger()

#If vars.hwnd.searchstrings_context && WinExist("ahk_id " vars.hwnd.searchstrings_context) && (vars.general.wMouse = vars.hwnd.poe_client) ;closing the search-strings context menu when clicking into the client

~LButton::
Gui, searchstrings_context: Destroy
vars.hwnd.Delete("searchstrings_context")
Return

#If vars.hwnd.omni_context.main && WinExist("ahk_id " vars.hwnd.omni_context.main) && (vars.general.wMouse = vars.hwnd.poe_client) ;closing the omni-key context menu when clicking into the client

~LButton::
Gui, omni_context: destroy
vars.hwnd.Delete("omni_context")
Return

#If (vars.hwnd.iteminfo.main && WinExist("ahk_id " vars.hwnd.iteminfo.main) || vars.hwnd.iteminfo_markers.1 && WinExist("ahk_id " vars.hwnd.iteminfo_markers.1)) && (vars.general.wMouse = vars.hwnd.poe_client)
;closing the item-info tooltip and its markers when clicking into the client
~LButton::IteminfoClose(1)

#If (vars.system.timeout = 0) && vars.general.wMouse && !Blank(LLK_HasVal(vars.hwnd.iteminfo_comparison, vars.general.wMouse)) ;long-clicking the gear-update buttons on gear-slots in the inventory to update/remove selected gear

LButton::
RButton::IteminfoGearParse(LLK_HasVal(vars.hwnd.iteminfo_comparison, vars.general.wMouse))

#If vars.cloneframes.editing && vars.general.cMouse && !Blank(LLK_HasVal(vars.cloneframes.scroll, vars.general.cMouse))

WheelUp::
WheelDown::CloneframesSettingsApply(vars.general.cMouse, A_ThisHotkey)

#If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id "vars.hwnd.cloneframe_borders.main) ;moving clone-frame borders via f-keys

F1::
F2::
F3::CloneframesSnap(A_ThisHotkey)

F1 UP::
F2 UP::
F3 UP::vars.cloneframes.last := ""

#If WinActive("ahk_id "vars.hwnd.snip.main) ;moving the snip-widget via arrow keys

ESC::snipGuiClose()
*Up::
*Down::
*Left::
*Right::SnippingToolMove()

#If vars.cheatsheets.tab && vars.hwnd.cheatsheet.main && WinExist("ahk_id " vars.hwnd.cheatsheet.main) ;clearing the cheatsheet quick-access (unused atm)

Space::
Gui, cheatsheet: Destroy
vars.hwnd.Delete("cheatsheet")
vars.cheatsheets.active := ""
KeyWait, Space
Return

#If vars.general.wMouse && vars.hwnd.cheatsheet.main && (vars.general.wMouse = vars.hwnd.cheatsheet.main) && (vars.cheatsheets.active.type = "advanced") ;ranking things in advanced cheatsheets

1::
2::
3::
4::
Space::CheatsheetRank()

#If vars.general.wMouse && vars.hwnd.betrayal_info.main && (vars.general.wMouse = vars.hwnd.betrayal_info.main) ;ranking betrayal rewards

1::
2::
3::
Space::BetrayalRank(A_ThisHotkey)

#If (vars.cheatsheets.active.type = "image") && vars.hwnd.cheatsheet.main && !vars.cheatsheets.tab && WinExist("ahk_id " vars.hwnd.cheatsheet.main) ;image-cheatsheet hotkeys

Up::
Down::
Left::
Right::
F1::
F2::
F3::
RButton::
Space::
1::
2::
3::
4::
5::
6::
7::
8::
9::
0::
a::
b::
c::
d::
e::
f::
g::
h::
i::
j::
k::
l::
m::
n::
o::
p::
q::
r::
s::
t::
u::
v::
w::
x::
y::
z::
CheatsheetImage("", A_ThisHotkey)
KeyWait, % A_ThisHotkey
Return

#IfWinActive ahk_group poe_ahk_window

ESC::HotkeysESC()

#If

RWin & Space::
LWin & Space::
Reload
ExitApp
