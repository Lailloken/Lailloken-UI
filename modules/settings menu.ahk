Settings_menu:
SetTimer, Settings_menu, Delete
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "LLK_panel")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		panel_xpos := panelXpos
		panel_ypos := panelYpos
		IniWrite, % panel_xpos, ini\config.ini, UI, button xcoord
		IniWrite, % panel_ypos, ini\config.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}
If (WinExist("ahk_id " hwnd_cheatsheets_menu) || WinExist("ahk_id " hwnd_searchstrings_menu)) && (A_Gui = "LLK_panel" || InStr(A_ThisHotkey, ".llk"))
{
	LLK_ToolTip("close the configuration window first", 2)
	Return
}
If (A_GuiControl = "LLK_panel") && (click = 2)
{
	KeyWait, RButton
	Reload
	ExitApp
}
If WinExist("ahk_id " hwnd_settings_menu)
	WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
If WinExist("ahk_id " hwnd_settings_menu) && (A_Gui = "LLK_panel")
{
	settings_menuGuiClose()
	WinActivate, ahk_group poe_window
	Return
}
settings_style := (InStr(A_GuiControl, "general") || (A_Gui = "LLK_panel")) || (restart_section = "general") || (A_Gui = "") && !restart_section ? "cAqua" : "cWhite"
If !ultrawide_warning && (poe_height_initial/poe_width_initial < (5/12))
	settings_style := "cWhite"
alarm_style := InStr(A_GuiControl, "alarm") || (restart_section = "alarm") ? "cAqua" : "cWhite"
betrayal_style := (InStr(A_GuiControl, "betrayal") && !InStr(A_GuiControl, "image") && !InStr(A_GuiControl, "cheatsheets")) || (restart_section = "betrayal") ? "cAqua" : "cWhite"
cheatsheets_style := InStr(A_GuiControl, "cheatsheets") || (restart_section = "cheat sheets") ? "cAqua" : "cWhite"
clone_frames_style := InStr(A_GuiControl, "clone") || (new_clone_menu_closed = 1) || (restart_section = "clone frames") ? "cAqua" : "cWhite"
delve_style := InStr(A_GuiControl, "delve") || (restart_section = "delve") ? "cAqua" : "cWhite"
itemchecker_style := InStr(A_GuiControl, "item-info") || InStr(A_GuiControl, "itemchecker") || (restart_section = "itemchecker") ? "cAqua" : "cWhite"
leveling_style := InStr(A_GuiControl, "leveling") || (restart_section = "leveling guide") ? "cAqua" : "cWhite"
map_tracker_style := InStr(A_GuiControl, "map") && InStr(A_GuiControl, "tracker") || (restart_section = "map tracker") ? "cAqua" : "cWhite"
map_mods_style := InStr(A_GuiControl, "map-info") || InStr(A_GuiControl, "map_info") || (restart_section = "map info") ? "cAqua" : "cWhite"
notepad_style := InStr(A_GuiControl, "notepad") || (restart_section = "notepad") ? "cAqua" : "cWhite"
omnikey_style := InStr(A_GuiControl, "hotkeys") || (restart_section = "hotkeys") ? "cAqua" : "cWhite"
pixelcheck_style := (InStr(A_GuiControl, "check") && !InStr(A_GuiControl, "checker") || InStr(A_GuiControl, "image") || InStr(A_GuiControl, "pixel")) && !InStr(A_GuiControl, "cheat") || (restart_section = "screenchecks") ? "cAqua" : "cWhite"
stash_style := InStr(A_GuiControl, "search-strings") || InStr(A_GuiControl, "stash_search") || InStr(A_GuiControl, "searchstrings") || (new_stash_search_menu_closed = 1) || (restart_section = "stash search") ? "cAqua" : "cWhite"
geforce_style := InStr(A_GuiControl, "geforce") ? "cAqua" : "cLime"
GuiControl_copy := A_GuiControl

If (A_Gui = "settings_menu")
{
	Gui, settings_menu: Submit, NoHide
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
}
Gui, settings_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_settings_menu, Lailloken UI: settings
Gui, settings_menu: Color, Black
Gui, settings_menu: Margin, % font_width*0.75, % font_height/4
WinSet, Transparent, % InStr(GuiControl_copy, "itemchecker") || InStr(GuiControl_copy, "item-info") ? 255 : trans
Gui, settings_menu: Font, s%fSize0% cWhite underline, Fontin SmallCaps

Gui, settings_menu: Add, Text, % "Section BackgroundTrans " settings_style " gSettings_menu HWNDhwnd_settings_general", % "general"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_general%
spacing_settings := width_settings


If !InStr(buggy_resolutions, poe_height) && (safe_mode != 1)
{
	Gui, settings_menu: Add, Text, xs BackgroundTrans %alarm_style% gSettings_menu HWNDhwnd_settings_alarm, % "alarm-timer"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_alarm%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %betrayal_style% gSettings_menu HWNDhwnd_settings_betrayal, % "betrayal-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_betrayal%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %cheatsheets_style% gSettings_menu vsettings_section_cheatsheets HWNDhwnd_settings_cheatsheets, % "cheat-sheets"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_cheatsheets%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %clone_frames_style% gSettings_menu HWNDhwnd_settings_clone_frames, % "clone-frames"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_clone_frames%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %delve_style% gSettings_menu HWNDhwnd_settings_delve, % "delve-helper"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_delve%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %omnikey_style% gSettings_menu HWNDhwnd_settings_omnikey, % "hotkeys"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_omnikey%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %itemchecker_style% gSettings_menu HWNDhwnd_settings_itemchecker, % "item-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_itemchecker%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	If (poe_log_file != 0)
	{
		Gui, settings_menu: Add, Text, xs BackgroundTrans %leveling_style% gSettings_menu HWNDhwnd_settings_leveling, % "leveling tracker"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_leveling%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
		
		Gui, settings_menu: Add, Text, xs BackgroundTrans %map_tracker_style% gSettings_menu HWNDhwnd_settings_map_tracker, % "mapping tracker"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_map_tracker%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	}
	Gui, settings_menu: Add, Text, xs BackgroundTrans %map_mods_style% gSettings_menu HWNDhwnd_settings_map_mods, % "map-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_map_mods%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %notepad_style% gSettings_menu HWNDhwnd_settings_notepad, % "notepad"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_notepad%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	If pixel_gamescreen_x1 is number
	{
		Gui, settings_menu: Add, Text, xs BackgroundTrans %pixelcheck_style% gSettings_menu HWNDhwnd_settings_pixelcheck, % "screen-checks"
		LLK_ScreenChecksValid()
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_pixelcheck%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	}
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %stash_style% gSettings_menu HWNDhwnd_settings_stashsearch, % "search-strings"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_stashsearch%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	If WinExist("ahk_exe GeForceNOW.exe") || WinExist("ahk_exe boosteroid.exe")
	{
		Gui, settings_menu: Add, Text, xs BackgroundTrans %geforce_style% gSettings_menu HWNDhwnd_settings_geforce, % "geforce now"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_geforce%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
		Gui, settings_menu: Font, cWhite
	}
}
Gui, settings_menu: Font, norm

If !InStr(GuiControl_copy, "notepad") && WinExist("ahk_id " hwnd_notepad_sample)
{
	Gui, notepad_sample: Destroy
	hwnd_notepad_sample := ""
}

If !InStr(GuiControl_copy, "alarm") && WinExist("ahk_id " hwnd_alarm_sample)
{
	Gui, alarm_sample: Destroy
	hwnd_alarm_sample := ""
}

If !InStr(GuiControl_copy, "delve") && WinExist("ahk_id " hwnd_delve_grid)
{
	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
}

If !ultrawide_warning && (poe_height_initial/poe_width_initial < (5/12))
{
	MsgBox, Giga-Ultrawide resolution detected. The settings section for screen-checks will now open`n`nIf your client has black bars on the sides, you need to locate the checkbox regarding black bars, read its instructions, and then click it.`n`nIf you don't have black bars, you can ignore this message.
	IniWrite, 1, ini\config.ini, Versions, ultrawide warning
	ultrawide_warning := 1
	pending_ultrawide := 1
	restart_section := "screenchecks"
	IniDelete, ini\config.ini, Versions, reload settings	
	;GoSub, Settings_menu
}

If (InStr(GuiControl_copy, "general") || (A_Gui = "LLK_panel")) && !pending_ultrawide || (restart_section = "general") || (A_Gui = "") && !restart_section
	GoSub, Settings_menu_general
Else If InStr(GuiControl_copy, "alarm") || (restart_section = "alarm")
	GoSub, Settings_menu_alarm
Else If InStr(GuiControl_copy, "betrayal") && !InStr(GuiControl_copy, "image") && !InStr(GuiControl_copy, "cheatsheets") || (restart_section = "betrayal")
	GoSub, Settings_menu_betrayal
Else If InStr(GuiControl_copy, "cheatsheets") || (restart_section = "cheat sheets")
	GoSub, Settings_menu_cheatsheets
Else If InStr(GuiControl_copy, "clone") || (new_clone_menu_closed = 1) || (restart_section = "clone frames")
	GoSub, Settings_menu_clone_frames
Else If InStr(GuiControl_copy, "delve") || (restart_section = "delve")
{
	If enable_delve
	{
		xsettings_menu := xScreenOffSet
		ysettings_menu := yScreenOffSet + poe_height/3
	}
	GoSub, Settings_menu_delve
}
Else If InStr(GuiControl_copy, "item-info") || InStr(GuiControl_copy, "itemchecker") || (restart_section = "itemchecker")
	GoSub, Settings_menu_itemchecker
Else If InStr(GuiControl_copy, "leveling") || (restart_section = "leveling guide")
	GoSub, Settings_menu_leveling_guide
Else If (InStr(GuiControl_copy, "map") && InStr(GuiControl_copy, "tracker")) || (restart_section = "map tracker")
{
	map_tracker_clicked := A_TickCount ;workaround for stupid UpDown behavior that leads to rare error message
	GoSub, Settings_menu_map_tracker
}
Else If InStr(GuiControl_copy, "map-info") || InStr(GuiControl_copy, "map_info") || (restart_section = "map info")
	GoSub, Settings_menu_map_info
Else If InStr(GuiControl_copy, "notepad") || (restart_section = "notepad")
	GoSub, Settings_menu_notepad
Else If InStr(GuiControl_copy, "hotkeys") || (restart_section = "hotkeys")
	GoSub, Settings_menu_hotkeys
Else If InStr(GuiControl_copy, "image") || InStr(GuiControl_copy, "pixel") || InStr(GuiControl_copy, "screen") || (restart_section = "screenchecks")
	GoSub, Settings_menu_screenchecks
Else If InStr(GuiControl_copy, "search-strings") || InStr(GuiControl_copy, "stash_search") || InStr(GuiControl_copy, "searchstrings") || (new_stash_search_menu_closed = 1) || (restart_section = "stash search")
	GoSub, Settings_menu_stash_search
Else If InStr(GuiControl_copy, "geforce")
	GoSub, Settings_menu_geforce_now

If !InStr(GuiControl_copy, "betrayal")
{
	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	LLK_Overlay("betrayal_info_members", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
		LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")
}
ControlFocus,, ahk_id %hwnd_settings_general%

If ((xsettings_menu != "") && (ysettings_menu != ""))
	Gui, settings_menu: Show, Hide x%xsettings_menu% y%ysettings_menu% AutoSize
Else Gui, settings_menu: Show, Hide AutoSize

LLK_Overlay("settings_menu", "show", 0)

If InStr(GuiControl_copy, "hotkeys") || (restart_section = "hotkeys")
	LLK_SettingsHotkeysRefresh()

restart_section := ""
;GuiControlGet, test, settings_menu: FocusV
;LLK_ToolTip(test)
If pending_ultrawide
	pending_ultrawide := ""
Return

Settings_menu_alarm:
settings_menu_section := "alarm"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Minor-Features">wiki page</a>
Gui, settings_menu: Add, Checkbox, % "xs BackgroundTrans venable_alarm gAlarm checked"enable_alarm " y+"fSize0*1.2, enable alarm-timer
If (enable_alarm = 1)
{
	GoSub, Alarm
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color:
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans vfontcolor_white cWhite gAlarm Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gAlarm Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gAlarm Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gAlarm Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gAlarm Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gAlarm Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_minus gAlarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_reset gAlarm Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_plus gAlarm Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center valarm_opac_minus gAlarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center valarm_opac_plus gAlarm Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_minus gAlarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_reset gAlarm Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_plus gAlarm Border x+2 wp", % "+"
}
Return

Settings_menu_betrayal:
settings_menu_section := "betrayal"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Betrayal-Info">wiki page</a>

Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vsettings_enable_betrayal BackgroundTrans y+"fSize0*1.2 " Checked"settings_enable_betrayal, % "enable the betrayal-info overlay"
If settings_enable_betrayal
{
	Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vBetrayal_enable_recognition BackgroundTrans Checked"betrayal_enable_recognition, % "use image recognition"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vbetrayal_recognition_help hp w-1", img\GUI\help.png
	If betrayal_enable_recognition
		Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vBetrayal_perma_table BackgroundTrans Checked"betrayal_perma_table, always show table with img-recognition
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gBetrayal_apply vImage_folder HWNDmain_text", % " open img folder "

	choice := (betrayal_info_table_pos = "left") ? 1 : 2
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.2, % "table position: "
	ControlGetPos,,, width,,, ahk_id %main_text%
	Gui, settings_menu: Font, % "s"fSize0 - 4
	Gui, settings_menu: Add, DDL, % "ys x+0 hp BackgroundTrans cBlack r2 vbetrayal_info_table_pos gBetrayal_apply Choose"choice " w"width/2, left||right
	Gui, settings_menu: Font, % "s"fSize0

	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_minus gBetrayal_apply Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_reset gBetrayal_apply Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_plus gBetrayal_apply Border x+2 wp", % "+"

	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbetrayal_opac_minus gBetrayal_apply Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbetrayal_opac_plus gBetrayal_apply Border x+2 wp", % "+"

	color := (betrayal_info_prio_dimensions = 0) || (betrayal_info_prio_transportation = "0,0") || (betrayal_info_prio_fortification = "0,0") || (betrayal_info_prio_research = "0,0") || (betrayal_info_prio_intervention = "0,0") ? "Red" : "White"
	Gui, settings_menu: Font, bold underline
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2 " c"color, % "prio-view settings"
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", % "frame dimensions: "
	Gui, settings_menu: Font, % "s"fSize0 - 4
	Gui, settings_menu: Add, Edit, % "ys x+0 Center BackgroundTrans cBlack hp vbetrayal_info_prio_dimensions gBetrayal_apply", % (betrayal_info_prio_dimensions = 0) ? 100 : betrayal_info_prio_dimensions
	Gui, settings_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 range0-1000", % betrayal_info_prio_dimensions
	Gui, settings_menu: Font, % "s"fSize0
	Gui, settings_menu: Add, Text, % "ys Center Border BackgroundTrans vbetrayal_info_prio_apply gBetrayal_apply", % " save "

	GoSub, Betrayal_search
	GoSub, GUI_betrayal_prioview	
}
Return

Settings_menu_cheatsheets:
settings_menu_section := "cheat sheets"
GoSub, Init_cheatsheets
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Cheat-sheet-Overlay-Toolkit">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"font_width*4, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb tools and tables</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans vfeatures_enable_cheatsheets gcheatsheets checked"features_enable_cheatsheets " y+"font_height, enable cheat-sheet toolkit
If !features_enable_cheatsheets
	Return
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "omni-key modifier: "
Gui, settings_menu: Add, Radio, % "ys x+0 hp vcheatsheets_omnikey_alt gCheatsheets checked"cheatsheets_omnikey_alt, alt
Gui, settings_menu: Add, Radio, % "ys x+0 hp vcheatsheets_omnikey_ctrl gCheatsheets checked"cheatsheets_omnikey_ctrl, ctrl
Gui, settings_menu: Add, Radio, % "ys x+0 hp vcheatsheets_omnikey_shift gCheatsheets checked"cheatsheets_omnikey_shift, % "shift"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vcheatsheets_modifier_help hp w-1", img\GUI\help.png

If cheatsheets_advanced_count
{
	Gui, settings_menu: Font, bold underline
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"font_height*0.8, % "customization: advanced sheets"
	Gui, settings_menu: Add, Picture, % "ys x+"font_width//2 " BackgroundTrans gSettings_menu_help vcheatsheets_colors_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Font, norm

	Loop 4
	{
		style := (A_Index = 1) ? "xs Section" : "ys x+"font_width//2
		Gui, settings_menu: Add, Text, % style " Center Border BackgroundBlack vcheatsheets_color_picker"A_Index " gCheatsheets c"cheatsheets_panel_colors[A_Index], % " "A_Index ": sample "
	}

	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "font size: "
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans Center Border gCheatsheets vcheatsheets_fontsize_minus", % " – "
	Gui, settings_menu: Add, Text, % "ys x+"font_width//4 " wp BackgroundTrans Center Border gCheatsheets vcheatsheets_fontsize_reset", % "r"
	Gui, settings_menu: Add, Text, % "ys x+"font_width//4 " wp BackgroundTrans Center Border gCheatsheets vcheatsheets_fontsize_plus", % "+"
}

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"font_height*0.8, % "create new sheet:"
Gui, settings_menu: Add, Picture, % "ys x+"font_width//2 " hp w-1 BackgroundTrans gSettings_menu_help vCheatsheets_type_help", img\GUI\help.png
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "name: "
Gui, settings_menu: Font, % "s"fsize0 - 4
Gui, settings_menu: Add, Edit, % "ys x+0 w"font_width*10 " cBlack vCheatsheets_new_name gCheatsheets HWNDhwnd_cheatsheets_new_name BackgroundTrans",
Gui, settings_menu: Font, % "s"fsize0
Gui, settings_menu: Add, Text, % "ys x+"font_width " BackgroundTrans", % "type: "
Gui, settings_menu: Font, % "s"fsize0 - 4
Gui, settings_menu: Add, DDL, % "ys hp x+0 w"font_width*8 " r10 cBlack BackgroundTrans vcheatsheets_type", % "images||app|advanced|"
Gui, settings_menu: Font, % "s"fsize0
Gui, settings_menu: Add, Text, % "ys hp Border 0x200 gCheatsheets vcheatsheets_new_save BackgroundTrans", % " add "

Loop, % cheatsheets_list.Length()
{
	If (A_Index = 1)
	{
		Gui, settings_menu: Font, bold underline
		Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"font_height*0.8, % "list of available cheat-sheets:"
		Gui, settings_menu: Font, norm
		Gui, settings_menu: Add, Picture, % "ys x+"font_width//2 " BackgroundTrans gSettings_menu_help vcheatsheets_list_help hp w-1", img\GUI\help.png
	}
	cheatsheets_parse := StrReplace(cheatsheets_list[A_Index], " ", "_")
	If cheatsheets_enable_%cheatsheets_parse% is not number
		IniRead, cheatsheets_enable_%cheatsheets_parse%, % "cheat-sheets\"cheatsheets_list[A_Index] "\info.ini", general, enable, 1
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans border gCheatsheets vcheatsheets_" cheatsheets_parse "_image_test y+"fSize0*0.4, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//4 " border gCheatsheets vcheatsheets_" cheatsheets_parse "_image_calibrate", % " calibrate "
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans gCheatsheets Checked" cheatsheets_enable_%cheatsheets_parse% " vcheatsheets_enable_" cheatsheets_parse, % "enable: "
	Gui, settings_menu: Font, underline
	cheatsheet_color := (!FileExist("cheat-sheets\"cheatsheets_list[A_Index] "\[check].*") || !cheatsheets_searchcoords_%cheatsheets_parse%) && (cheatsheets_enable_%cheatsheets_parse% = 1) ? "Red" : "White"
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans c"cheatsheet_color " gCheatsheets vcheatsheets_entry_"cheatsheets_parse, % cheatsheets_list[A_Index]
	Gui, settings_menu: Font, norm
}
Return

Settings_menu_clone_frames:
settings_menu_section := "clone frames"
new_clone_menu_closed := 0
clone_frames_enabled := ""
IniRead, clone_frames_list, ini\clone frames.ini,,, % A_Space
Sort, clone_frames_list, D`n
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames">wiki page</a>
If (pixel_gamescreen_x1 != "") && (pixel_gamescreen_x1 != "ERROR") && (enable_pixelchecks = 1)
{
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply vClone_frames_pixelcheck_enable Checked" clone_frames_pixelcheck_enable " y+"fSize0*1.2, automatically hide clone-frames
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vpixelcheck_auto_trigger hp w-1", img\GUI\help.png
}
If (poe_log_file != 0)
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply vClone_frames_hideout_enable Checked"clone_frames_hideout_enable, hide clone-frames in hideouts/towns

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "list of clone-frames currently set up:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vclone_frames_list_help hp w-1", img\GUI\help.png
Loop, Parse, clone_frames_list, `n, `n
{
	If (A_LoopField = "Settings")
		continue
	If clone_frame_%A_LoopField%_enable is not number
		IniRead, clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable, 1
	If (clone_frame_%A_LoopField%_enable = 1)
	{
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
		Gui, clone_frames_%A_Loopfield%: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_%A_Loopfield%
	}
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply Checked" clone_frame_%A_LoopField%_enable " vClone_frame_" A_LoopField "_enable", % "enable: "
	Gui, settings_menu: Font, underline
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gClone_frames_preview_list", % A_LoopField
	Gui, settings_menu: Font, norm
}
Gui, settings_menu: Add, Text, % "xs Section Border gClone_frames_new vClone_frames_add BackgroundTrans y+"fSize0*1.2, % " add frame "
Return

Settings_menu_delve:
settings_menu_section := "delve"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Delve-helper">wiki page</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans venable_delve gDelve checked"enable_delve " y+"fSize0*1.2, enable delve-helper
If (enable_delve = 1)
{
	GoSub, Delve
	GoSub, GUI
	Gui, settings_menu: Add, Checkbox, % "xs Section Center gDelve vdelve_enable_recognition BackgroundTrans Checked"delve_enable_recognition, use image recognition
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vdelve_recognition_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, grid size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_minus gDelve Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_reset gDelve Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_plus gDelve Border x+2 wp", % "+"
	
	If (poe_log_file != 0)
	{
		Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans venable_delvelog gDelve checked"enable_delvelog " y+"fSize0*1.2, % "only show button while delving"
		Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vdelve_help hp w-1", img\GUI\help.png
	}
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_minus gDelve Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_reset gDelve Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_plus gDelve Border x+2 wp", % "+"
}
Return

Settings_menu_geforce_now:
settings_menu_section := "geforce"
Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, % "pixel-check allowed variation: "
ControlGetPos,,,, controlheight,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gGeforce_now_apply Center Limit3 vPixelsearch_variation w"controlheight*1.6, %pixelsearch_variation%
Gui, settings_menu: Font, s%fSize0%
Gui, settings_menu: Add, Text, % "xs Section y+0 BackgroundTrans", % "(range: 0–255, default: 0) "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vGeForce_now_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.2, % "image-check allowed variation: "
ControlGetPos,,,, controlheight,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gGeforce_now_apply Center Limit3 vImagesearch_variation w"controlheight*1.6, %imagesearch_variation%
Gui, settings_menu: Font, s%fSize0%
Gui, settings_menu: Add, Text, % "xs BackgroundTrans", % "(range: 0–255, default: 25)"
Return

Settings_menu_general:
settings_menu_section := "general"

Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki">llk-ui wiki</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gApply_settings_general HWNDmain_text Checked" kill_script " vkill_script y+"fSize0*1.2, % "kill script after"
ControlGetPos,,,, controlheight,, ahk_id %main_text%

Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gApply_settings_general right Limit2 vkill_timeout w"controlheight*1.2, %kill_timeout%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//2, % "minute(s) w/o poe-client"

Gui, settings_menu: Add, Link, % "xs hp Section HWNDlink_text y+"fSize0*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/discussions/49">custom resolution:</a>
If (fullscreen = "true")	
	Gui, settings_menu: Add, Text, % "ys hp BackgroundTrans HWNDmain_text vcustom_width x+"fSize0//2, % poe_width_initial
Else
{
	Gui, settings_menu: Font, % "s"fSize0-4
	Gui, settings_menu: Add, Edit, % "ys hp Limit4 Number Right cBlack BackgroundTrans vcustom_width HWNDmain_text x+"fSize0//2, % width_native
	GuiControl, text, custom_width, % poe_width
	Gui, settings_menu: Font, % "s"fSize0
}
Gui, settings_menu: Add, Text, % "ys hp BackgroundTrans x+0", %  " x "
ControlGetPos,,,, height,, ahk_id %main_text%
ControlGetPos,,, width,,, ahk_id %main_text%
resolutionsDDL := ""
IniRead, resolutions_all, data\Resolutions.ini
choice := 0
Loop, Parse, resolutions_all, `n,`n
	If !(InStr(A_LoopField, "768") || InStr(A_LoopField, "1024") || InStr(A_LoopField, "1050")) && !(StrReplace(A_LoopField, "p", "") > height_native) && !((StrReplace(A_Loopfield, "p") >= height_native) && (fullscreen != "true"))
		resolutionsDDL := (resolutionsDDL = "") ? StrReplace(A_LoopField, "p", "") : StrReplace(A_LoopField, "p", "") "|" resolutionsDDL
resolutionsDDL := (resolutionsDDL = "") ? height_native : resolutionsDDL
Loop, Parse, resolutionsDDL, |, |
	If (A_LoopField = poe_height)
		choice := A_Index
choice := (choice = 0) ? 1 : choice
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, DDL, % "ys BackgroundTrans HWNDmain_text vcustom_resolution r10 Choose" choice " x+0 w"width*1.5 " hp", % resolutionsDDL
Gui, settings_menu: Font, % "s"fSize0
If (fullscreen = "false")
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans Checked" window_docking " vwindow_docking gApply_settings_general", % "top-docked"
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border vcustom_resolution_apply gApply_settings_general", % " apply && restart "
Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans HWNDmain_text Checked" custom_resolution_setting " vcustom_resolution_setting gApply_settings_general", % "apply on startup "

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "interface size:"
Gui, settings_menu: Add, Text, ys x+6 BackgroundTrans gApply_settings_general vinterface_size_minus Border Center, % " – "
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_reset Border Center, % "r"
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_plus Border Center, % "+"
Gui, settings_menu: Add, Checkbox, % "ys x+"font_width*1.5 " BackgroundTrans Checked" hide_panel " vhide_panel gApply_settings_general", % "hide llk-ui panel"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans y+"fSize0*1.2 " vEnable_browser_features gApply_settings_general Checked"enable_browser_features, % "enable browser features"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vBrowser_features_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans vEnable_caps_toggling gApply_settings_general Checked"enable_caps_toggling, % "enable capslock-toggling"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vCaps_toggling_help hp w-1", img\GUI\help.png

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "script write-permissions test:"
Gui, settings_menu: Add, Picture, % "ys x+"font_width//2 " BackgroundTrans gSettings_menu_help vwrite_test_help hp w-1", img\GUI\help.png
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gLLK_WriteTest", % " start test "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border vAdminStart gLLK_WriteTest", % " restart script as admin "

Return

Settings_menu_help:
MouseGetPos, mouseXpos, mouseYpos
Gui, settings_menu_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_settings_menu_help
Gui, settings_menu_help: Color, Black
Gui, settings_menu_help: Margin, % font_height//2, % font_width//2
Gui, settings_menu_help: Font, s%fSize1% cWhite, Fontin SmallCaps
help_image := ""
;//////////////////////////////////////////////////////////////////////////////
;//////////////// Betrayal

If (A_GuiControl = "betrayal_recognition_help")
{
text =
(
if enabled, the script will read the screen underneath the mouse-cursor to check for syndicate-member cards, then display the appropriate cheat-sheet.

this requires correctly setting up the <betrayal> image-check in the settings menu, and the following:
- each member's card has to be screen-capped once (refer to wiki for instructions)
- each of the four divisions has to be screen-capped once (optional)
)
}

;//////////////////////////////////////////////////////////////////////////////
;//////////////// Delve

If (A_GuiControl = "delve_recognition_help")
{
text =
(
if enabled, the script will read the screen underneath the grid-map overlay and copy the delve-passages displayed on the in-game delve-map.
	
this requires calibrating the scanner by screen-capping parts of the delve-map (refer to wiki for instructions)
)
}

;//////////////////////////////////////////////////////////////////////////////
;//////////////// Leveling tracker

If (A_GuiControl = "leveling_guide_skilltree_help")
{
text =
(
explanation
–> opens the folder where skilltree-screenshots are stored
–> file-name structure: refer to the <skilltree overlay: setup> section of the wiki page 
)
}

If (A_GuiControl = "skilltree_overlay_help")
{
text =
(
explanation
–> an optional feature to create overlays with pob screenshots
–> hold the omni-key while viewing the in-game skilltree to activate the overlays
–> right-clicks will switch to the next screenshot
–> long right-click will switch to the previous one
–> press keys 1-0 to access screenshot 1 to 10

requirement
–> the <skilltree> image-check has to be calibrated in the <screen-checks> section of the settings menu
)
}

If (A_GuiControl = "leveling_guide_skilltree_cap_help")
{
text =
(
cropping
–> left-click the preview image to set the top-left corner of the cropped area
–> right-click the preview image to set the bottom-right corner of the cropped area

captions
–> enter a caption or choose an entry from the drop-down list to replace an existing screenshot (right-click an entry to delete it)
–> the [xx]-tag at the beginning is merely for sorting and will not be displayed in the actual caption of the overlay
–> if you don't want to add a caption, just leave the sample text as it is and press enter
)
}

If (A_GuiControl = "leveling_guide_pob_help")
{
text =
(
if enabled, pressing the middle mouse-button in pob will initiate screen-capping via the windows snipping tool.
	
after screen-capping an area, a setup-window with a preview will open. if desired, a caption can be added to the image. this caption will be displayed in the skilltree-overlay in game.

press enter to save the screen-cap, or esc to abort.
)
}

If (A_GuiControl = "gear_tracker_help")
{
text =
(
the drop-down list contains the most recent characters found in the client-log.

items that are ready to be equipped are highlighted green. by default, the list only shows items up to 5 levels higher than your character.

clicking an item on the list will highlight it in game (stash and vendors). right-clicking will remove it from the list.

you can click the <select character> label to highlight all green items at once.
)
}

;//////////////////////////////////////////////////////////////////////////////
;//////////////// cheat-sheets

If (A_GuiControl = "cheatsheets_list_help")
{
text =
(
test && calibrate
–> each sheet has a "condition," i.e. a certain ui-element has to be on screen
–> if that condition is fulfilled while pressing the key-combination, a specific sheet will be activated
–> click <calibrate> to specify that condition by screen-capping a unique part of the in-game ui
–> click <test> to see if the screen-capped image works correctly

listed entries
–> cheat-sheets can be individually disabled
–> long-click the underlined names to display information about a sheet.
–> right-click the underlined names to open a context-menu with additional options.
–> entries are highlighted red as long as they have not returned a positive test yet
)
	help_image = img\GUI\skill-tree.jpg
}

If (A_GuiControl = "cheatsheets_colors_help")
{
text =
(
explanation
–> "advanced" cheat-sheets use text-panels that can be individually colored for highlighting/ranking purposes

customization
–> copy a hex rgb-code to clipboard and click a button below to apply that color
–> right-click a button below to reset its color to default

applying colors to text-panels
–> while hovering over a text-panel, press the corresponding number-key to apply a given font-color
–> pressing space while hovering over a panel will reset the font-color to white
)
}

If (A_GuiControl = "cheatsheets_type_help")
{
text =
(
instructions
–> to set up a new sheet: enter a name, choose a type, then click <add>

type: images
–> cheat-sheet with one or more images
–> images can be segmented, or switched between

type: app
–> uses a specific app-window as a cheat-sheet

type: advanced
–> overlays for individual objects that will be detected on screen
–> closer to an in-game tooltip than traditional cheat-sheet
)
}

If (A_GuiControl = "cheatsheets_snip_help")
{
text =
(
instructions
–> move and resize this widget so the colored area covers the screen-area you want to capture, then click <snip> again
–> use the arrow keys to move the widget by one pixel
–> use alt + arrow keys to resize the widget by one pixel
–> hold ctrl to use 10-pixel-steps instead

other overlays won't block the snip
–> other llk ui-elements will be hidden the moment you click <snip>
)
}

If (A_GuiControl = "cheatsheets_modifier_help")
{
text =
(
determines which key needs to be held down in order to activate cheat-sheets via the omni-key
–> the modifier is not part of the "hold" behavior if a sheet is set up that way
–> so it can be released once the cheat-sheet was activated
–> choose a modifier that you never (or very rarely) press in combination with the omni-key during regular play
)
}

If (A_GuiControl = "cheatsheets_apptitle_help")
{
text =
(
window title
–> (parts of) the text that is displayed when hovering over a window's taskbar icon
–> the title is case-sensitive, so make sure to copy it 1:1
–> pob-example: &Path of &Building
–> websites are only detectable if they are in the active tab in a browser-window

test button
–> long-clicking the button will switch to the window with the specified title
–> use this to check if the title is correct
)
}

If (A_GuiControl = "cheatsheets_applaunch_help")
{
text =
(
this is entirely optional
–> if the specified window doesn't exist when the sheet is activated, the script will launch the app instead
–> click <pick .exe/shortcut> to choose which file to launch
–> right-click the button to remove the file
–> click <test> to check if it launches correctly

launching websites
–> it's recommended to save a website as a "browser app" and pick its shortcut
–> the shortcut can be deleted after importing because the script will make a copy and save it internally
)
}

If (A_GuiControl = "cheatsheets_screencheck_help")
{
text =
(
explanation
–> determines how the screen will be checked to find the specific ui-element
–> this only refers to the screen-check that was calibrated in the settings menu to activate this sheet, not any others that will be set up in the future

static (default)
–> only the screen-area that previously returned a positive test will be checked

dynamic
–> a larger area around a previously-positive screen-area will be checked
–> a bit slower, so only use it if necessary (e.g. if a ui can be mouse-dragged)
)
}

If (A_GuiControl = "cheatsheets_activation_help")
{
text =
(
explanation
–> determines how the overlay and omni-key behave

toggle
–> overlay: stays on screen until esc is pressed
–> window: stays in the foreground

hold (default)
–> overlay/window will be displayed as long as the omni-key is held down
–> activating a sheet by holding two modifier-keys instead of one will use the toggle behavior (see above) for that specific activation
)
}

If (A_GuiControl = "cheatsheets_import_help")
{
text =
(
00 index
–> this is reserved for headers of a table or other type of illustration.
–> only load an image into this index if you want a segmented cheat-sheet
–> the 00 image will always be displayed in the overlay
–> it can either be displayed on the left or top of the overlay, depending on the layout of the sheet

other indexes
–> index-numbers can be long-clicked to see a preview of the image-file
)
	help_image = img\GUI\cheat-sheet header.jpg
}

If (A_GuiControl = "cheatsheets_import_help2")
{
text =
(
<paste>
–> loads an image from clipboard and saves it as the chosen number-index

<snip>: for any index above 00, as long as 00 itself is blank
–> activates the windows snipping tool with which screen-caps can be taken

<snip>: for 00, and if 00 is not blank
–> when first clicked, opens a snipping widget with further instructions

<del>
–> click and hold for 0.5s to delete an indexed image

white edit-field (optional)
–> enter a letter to tag an image, so it can additionally be accessed via that letter-key
)
}

If (A_GuiControl = "Cheatsheets_preview_help")
{
text =
(
<preview>
–> long-click to activate the sheet and access it without a positive screen-check

hotkeys (type: images)
–> number-keys: select/add image from that number-index
–> space: reset segmented sheet to only show 00
–> tab: display all segments until tab is released
–> right-click: switch to next image, or previous (hold)
–> f1 && f2: change overlay-size
–> f3: reset overlay-size
)
}

If (A_GuiControl = "cheatsheets_preview_help2")
{
text =
(
<preview>
–> long-click to activate the sheet and access it without a positive screen-check

hotkeys (type: advanced)
–> number-keys: applies a highlight color to the text-panel underneath the cursor
–> space: remove the highlight color from the text-panel underneath the cursor
)
}

If (A_GuiControl = "cheatsheets_objectadd_help")
{
text =
(
explanation
–> you have to create a list with names of "objects" that can appear on screen
–> these names don't have to match in-game names/text 1:1, so abbreviations may be used

examples
–> betrayal: vorici, aisling, leo, (thane) jorgin

conditions && calibration
–> these objects are the condition that activate the individual text-panels / tooltips
–> they behave the same as the sheet's own condition and thus need to be calibrated as well
–> to calibrate the screen-check of an object, open the in-game ui where they appear, hover over them, hold right-click and activate the cheat-sheet (modifier + omni-key)
)
}

If (A_GuiControl = "cheatsheets_objects_help")
{
text =
(
explanation
–> if a number is green, it means this object's screen-check has been calibrated
–> numbers can be long-clicked to display a preview of the screen-check image
–> long-click <del> to remove an object from the list
–> click an underlined name to edit the overlay of that object
)
}

If (A_GuiControl = "cheatsheets_textpanels_help")
{
text =
(
explanation
–> up to 4 text-panels may be displayed at once per object
–> text-panels will be overlaid above the cursor
–> texts are not limited to the height/width of the boxes below
–> use line-breaks to prevent text-panel overlays from becoming too wide
)
}




If (A_GuiControl = "map_tracker_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to track and log your map runs.
)
}

If (A_GuiControl = "map_info_shiftclick_help")
{
text =
(
if enabled, the map-info panel will be activated whenever currency-items are applied via shift-clicking.

hold shift -before- right-clicking currency-items for the first time.

while holding shift, left-click maps to apply currency and activate the map-info panel.
)
}

If (A_GuiControl = "mapinfo_colors_help")
{
text =
(
explanation
–> individual map-mods can be highlighted with different colors to indicate their difficulty
–> omni-click a map, long-click a mod in the panel, then press keys 1-4 to apply the corresponding colors shown below

instructions
–> copy an rgb hex-code into the clipboard and click a button below to apply that color
–> right-click a button below to reset that color to default
–> <headers> refers to the color of headers (player, monsters, bosses, etc.)
)
}

If (A_GuiControl = "searchstrings_list_help")
{
text =
(
test && calibrate
–> each search has a "condition," i.e. a certain ui-element has to be on screen
–> if that condition is fulfilled while pressing the omni-key, the search-strings feature will be activated
–> click <calibrate> to specify that condition by screen-capping a unique part of the in-game ui
–> click <test> to see if the screen-capped image works correctly

listed entries
–> searches can be individually disabled
–> click an underlined entry to edit it
–> long right-click an underlined entry to remove it
–> entries are highlighted red as long as they have not returned a positive test yet
)

	help_image = img\GUI\stash.jpg
}

If (A_GuiControl = "searchstrings_lilly_help")
{
text =
(
explanation
–> this search is specifically for gem-strings created when importing an exile leveling guide
–> lilly in your hideout has a different window compared to other vendors
)
}

If (A_GuiControl = "searchstrings_entrylist_help")
{
text =
(
instructions
–> long-click <del> to delete an entry
–> click an underlined entry to access the edit-field on the right
–> right-click an entry to rename it

edit-field
–> this is where to paste the strings for in-game searches
–> if multiple lines are used, the entry becomes a scrollable search where each individual line is a sub-string
–> to create a scrollable search involving numbers, enclose -one- number in semi-colons, e.g. "item level: ;69;"
)
}

If (A_GuiControl = "searchstrings_entryadd_help")
{
text =
(
explanation
–> these are the entries as they will be displayed in the pop-up menu
–> these are merely names, not the actual strings

instructions
–> to add a new entry, enter a name into the edit-field and press enter
)
}

If (A_GuiControl = "searchstrings_add_help")
{
text =
(
instructions
–> enter the name of an in-game ui with a search, then press enter
–> only latin letters and spaces are allowed
–> examples: vendor, gwennen, harvest, stash
)
}

If (A_GuiControl = "clone_frames_list_help")
{
text =
(
long-click the underlined names to see a preview of the clone-frame

right-click the underlined names to open a context-menu with additional options
)
}

If (A_GuiControl = "map_tracker_side_area_help")
{
text =
(
checking this option will also include side-areas (lab trials, vaal areas, abyss, etc.) in the map time and logs.
)
}

If (A_GuiControl = "map_tracker_loot_help")
{
text =
(
checking this option will also log items that are being ctrl-clicked from the inventory into the stash.

note: <stash> image-check has to be set up in the screen-checks settings
)
}

If (A_GuiControl = "map_tracker_kill_help")
{
text =
(
checking this option will also log the number of kills in a map.

note: the map-tracker panel will start flashing at the start of a map, and you have to click the timer once to set the starting point.

whenever you leave the map device, the panel will turn green, indicating the kill-count has to be updated by clicking the timer again. this only needs to be done if the map is completed and you want to open a new one.
)
}

If (A_GuiControl = "leveling_guide_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to track your character's current location and level.
)
}

If (A_GuiControl = "Leveling_guide_color_help")
{
text =
(
instructions
–> click the button to apply an rgb hex-code from the clipboard
–> right-click the button to reset the font-color to white
)
}

If (A_GuiControl = "leveling_guide_help2")
{
text =
(
generate guide: opens exile-leveling created by HeartofPhos.

import guide: imports an exile-leveling guide from clipboard.

delete guide: deletes the imported guide and removes included gems from the gear tracker.

reset progress: resets the campaign progress and starts over.
)
}

If (A_GuiControl = "delve_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to check whether your character is in the azurite mine.
)
}

If (A_GuiControl = "map_info")
{
text =
(
0 hides the mod from now on, and higher values have distinct text-colors.

it's up to you how to tier the mods and whether to use all tiers.
)
}

If (A_GuiControl = "browser_features_help")
{
text =
(
explanation
enables complementary features when accessing 3rd-party websites in your browser

examples
- chromatics calculator: auto-input of required stats
- poe.db cluster jewels: f3 quick-search
)
}

If (A_GuiControl = "caps_toggling_help")
{
text =
(
toggling this checkbox will restart the script due to code-limitations (and the settings menu will close).

if enabled, the script will toggle the state of capslock to off before sending key-presses in order to avoid case-inversions.

the system will handle this toggling as a capslock key-press, so anything bound to it will be activated.

uncheck this option if you have something bound to capslock (e.g. push-to-talk), but keep in mind unwanted case-inversion may occur as a consequence.
)
}

If (A_GuiControl = "stash_search_new_help")
{
text =
(
name: has to be unique, otherwise an existing search with the same name will be replaced. only use numbers and regular letters!

use-cases: select which search-fields the string will be used for.

string: has to be a valid string that works in game. it will not be corrected or checked for errors here, so make sure it works before saving it.

scrolling: if enabled, scrolling will adjust a number within the string, or switch between sub-strings. strings with number-scrolling can only contain -one- number.

string 2: an optional secondary string. this will be used when right-clicking the shortcut.
)
}

If (A_GuiControl = "geforce_now_help")
{
text =
(
explanation
since geforce now is a streaming-based client, its image quality can fluctuate significantly.
this results in screen-checks being inconsistent and the script behaving abnormally.
to counteract this, screen-checks can be "loosened" in order to be less strict and adapt to changing image-quality.

instructions
if you have problems with screen-checks, increase variation by 15 and see if that fixes it.
repeat until the script's behavior becomes stable.
)
}

If (A_GuiControl = "pixelcheck_auto_trigger")
{
text =
(
by adapting to what's happening on screen, the script automatically hides/shows clone-frames to avoid blocking in-game interfaces.

requires the <gamescreen> pixel-check to be set up correctly, as well as playing with the mini-map in the center of the screen.
)
}

If (A_GuiControl = "pixelcheck_help")
{
text =
(
disclaimer
–> these screen-checks merely trigger actions within the script itself and will -never- result in any interaction with the client.
–> they are used to let the script adapt to what's happening on screen, emulating the use of an addon-api:
  –> automatically hide overlays to avoid blocking in-game interfaces
  –> make context-sensitive hotkeys possible

explanation
–> this is where you (re)calibrate the checks to ensure connected features function properly
–> game-patches sometimes include ui or texture updates, which leads to screen-checks being outdated

instructions
–> click <test> to verify if the pixel-check is working
–> click <calibrate> to read the required pixel and save the color-value
–> long-click the underlined names to see specific instructions for that check.
)
}

If (A_GuiControl = "imagecheck_help")
{
text =
(
disclaimer
–> these screen-checks merely trigger actions within the script itself and will -never- result in any interaction with the client.
–> they are used to let the script adapt to what's happening on screen, emulating the use of an addon-api:
  –> automatically hide overlays to avoid blocking in-game interfaces
  –> make context-sensitive hotkeys possible

explanation
–> this is where you (re)calibrate the checks to ensure connected features function properly
–> game-patches sometimes include ui or texture updates, which leads to screen-checks being outdated

instructions
–> click <test> to verify if the image-check is working
–> click <calibrate> to screen-cap the required image
–> long-click the underlined names to see specific instructions for that check.
)
}

If (A_GuiControl = "Pixelcheck_blackbars_help")
{
text =
(
if the game-client has black bars on each side, pixel-checks will constantly fail because they are reading black pixels.

this option will fix that by compensating for black bars. toggling this checkbox will restart the script.
)
}

If (A_GuiControl = "gamescreen_help")
{
text =
(
instructions
–> close the inventory and every menu until you're on the main screen (where you control your character)
–> set the mini-map the center of the screen and click <calibrate>

explanation
–> this check helps the script identify whether the user is in a menu or on the regular "gamescreen"
–> this enables it to hide overlays automatically in order to prevent obstructing full-screen menus
–> this also helps determining the context of an omni-key press
)
	help_image = img\GUI\game_screen.jpg
}

If (A_GuiControl = "inventory_help")
{
text =
(
instructions
–> open the inventory, then click <calibrate>.

explanation
–> this check helps the script identify whether the inventory is open
–> it is required for the item-info gear-comparison feature
–> calibrating this also automatically hides the item-info tooltip whenever the inventory closes
)
}

If (A_GuiControl = "pixelcheck_enable_help")
{
text =
(
this should only be disabled when experiencing severe performance drops while running the script.

when disabled, overlays will not show/hide automatically (if the user navigates through in-game menus) and they have to be toggled manually.
)
}

If (A_GuiControl = "imagecheck_help_skilltree")
{
text =
(
instructions
–> to recalibrate, open the skill-tree
–> click <calibrate> and screen-cap the client-area as highlighted above

explanation
–> this check helps the script identify whether the skill-tree is open or not, which enables the omni-key to overlay skill-tree screenshots.

required for
–> leveling tracker: skill-tree overlays
)
	help_image = img\GUI\skill-tree.jpg
}

If (A_GuiControl = "imagecheck_help_betrayal")
{
text =
(
instructions
–> to recalibrate, open the syndicate board, do not zoom into or move it
–> click <calibrate> and screen-cap the client-area as highlighted above

explanation
–> this check helps the script identify whether the syndicate board is up or not, which enables the omni-key to activate the betrayal-info feature.

required for
–> betrayal-info overlay
)
	help_image = img\GUI\betrayal.jpg
}

If (A_GuiControl = "imagecheck_help_stash")
{
text =
(
instructions
–> to recalibrate, open your stash and screen-cap the highlighted area displayed above.

explanation
–> this check helps the script identify whether your stash is open or not, which enables loot-tracking for items being ctrl-clicked into the stash

required for
–> mapping tracker: loot tracking
)
	help_image = img\GUI\stash.jpg
}

If InStr(A_GuiControl, "omnikey")
{
text =
(
explanation
–> context-sensitive hotkey used to access the majority of this script's features.
–> the key-press itself will still be sent to the client, so you can still use skills bound to this key
–> if you still want/need to rebind it, bind it to a key that's not used for chatting.
)
}

If (A_GuiControl = "ingame_keys_help")
{
text =
(
explanation
–> specific in-game hotkey customizations can cause issues with the omni-key
–> please tick every option below that applies to your in-game settings

advanced item descriptions
–> if this is not bound to alt, you have to specify below which key you have rebound it to
–> click the <format> link to find out how special keys have to be formatted for autohotkey

rebinding the c-key
–> if the c-key has been rebound in game, the omni-key will not function correctly
–> a secondary omni-key has to be set up which will then be used to activate item-related features
)
}

If (A_GuiControl = "misc_keys_help")
{
text =
(
–> if you are actively using a hotkey below in game, you can rebind it for better compatibility
–> help tooltips, prompts, and official documentation (wiki && release notes) will continue to refer to the default hotkey
)
}

If (A_GuiControl = "itemchecker_ID_help")
{
text =
(
if enabled, the tooltip will be activated whenever currency-items are applied via shift-clicking.

hold shift -before- right-clicking currency-items for the first time.

while holding shift, left-click items to apply currency and activate the item-info tooltip.
	
while holding shift, right-click items to place a red marker.
)
}

If (A_GuiControl = "itemchecker_profiles_help")
{
text =
(
the lists of (un)desired mods are stored in individual profiles that can be switched between.
)
}

If (A_GuiControl = "itemchecker_bases_help")
{
text =
(
shows an additional row with information on base-stats and ilvl at the top of the tooltip.

this information comes in form of percentages and represents how close a given item is to the best-in-class item of that stat.

these stats are visualized by a bar in the background that turns green if a given item is the best-in-class item of that stat.

the ilvl maxes out dynamically depending on the item-class and is highlighted green if that value is reached.
)
}

If (A_GuiControl = "itemchecker_ilvl_help")
{
text =
(
this option caters to advanced users because it adds an additional column with a mod's ilvl-requirements, which may be overwhelming or confusing.
)
}

If (A_GuiControl = "itemchecker_colors_help")
{
text =
(
"tier x" = fractured mods
"tier —" = un-tiered mods (veiled, delve, incursion, etc.)

tier 1 is also the color that marks desired mods, tier 6 the one that marks undesired ones.

"tier x" always overrides ilvl colors, "tier —" whenever ilvl is not a differentiating factor.

click a field to apply an rgb hex-code from the clipboard, right-click a field to reset it to the default color.
)
}

If (A_GuiControl = "itemchecker_override_help")
{
text =
(
if enabled, undesired mods will always have their tier && ilvl highlighted in the t6 color, regardless of the actual tier and ilvl.

hybrid mods will only be overridden if every aspect of the mod is undesired, and fractured mods will never be overridden.

note: when enabled, marking as undesired should be used carefully and only for mods that are inherently bad. you may otherwise dismiss an item as bad solely based on your own preferences.
)
}

If (A_GuiControl = "itemchecker_rules_help")
{
text =
(
only affects explicit item-mods, not implicits or cluster-enchants.

the name indicates which stat(s) the rule affects, the color indicates what happens with the stat.

green: stat will be marked as desired
red: stat will be marked as undesired
)
}

If (A_GuiControl = "itemchecker_dps_help")
{
text =
(
shows an additional row at the top of the tooltip with dps information.

unchecked: dps will always be shown for weapons (league-start or leveling)

checked: dps will be shown on every unique weapon, and rare weapons with at least 3 damage mods (work in progress, will refine it at a later date)
)
}

If (A_GuiControl = "itemchecker_gear_help")
{
text =
(
when enabled, equipped items are tracked and serve as a point of comparison for the item-info tooltip.

however, some minor features are disabled while this mode is active in order to not bloat the tooltip too much.
)
}

If (A_GuiControl = "write_test_help")
{
text =
(
this runs a series of tests in order to determine if the script has sufficient file/folder write-permissions.

use this if certain features don't function or save their settings correctly.

optionally, you can restart the script with admin-rights and re-run the test to see if that fixes issues.
)
}

If help_image
{
	pHelp := Gdip_LoadImageFromFile(help_image)
	If (pHelp <= 0)
		Gui, settings_menu_help: Add, Text, % "Section BackgroundTrans w"font_width*35 " h"font_height*16, couldn't load image
	Else
	{
		Gdip_GetImageDimensions(pHelp, wHelp, hHelp)
		If (wHelp > font_width*35)
		{
			pHelp_copy := pHelp
			pHelp := Gdip_ResizeBitmap(pHelp_copy, font_width*35, 10000, 1, 7)
			Gdip_DisposeImage(pHelp_copy)
			Gdip_GetImageDimensions(pHelp, wHelp, hHelp)
		}
		hbmHelp := CreateDIBSection(wHelp, hHelp)
		hdcHelp := CreateCompatibleDC()
		obmHelp := SelectObject(hdcHelp, hbmHelp)
		gHelp := Gdip_GraphicsFromHDC(hdcHelp)
		Gdip_SetInterpolationMode(gHelp, 0)
		Gdip_DrawImage(gHelp, pHelp, 0, 0, wHelp, hHelp, 0, 0, wHelp, hHelp, 1)
		Gui, settings_menu_help: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmHelp%
		Gui, settings_menu_help: Add, Text, % "xs BackgroundTrans w"font_width*35, % text
		SelectObject(hdcHelp, obmHelp)
		DeleteObject(hbmHelp)
		DeleteDC(hdcHelp)
		Gdip_DeleteGraphics(gHelp)
		Gdip_DisposeImage(pHelp)
	}
}
Else Gui, settings_menu_help: Add, Text, % "Section BackgroundTrans w"font_width*35, % text

Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
WinGetPos, winx, winy, width, height, ahk_id %hwnd_settings_menu_help%
newxpos := (winx + width > xScreenOffSet + poe_width) ? xScreenOffSet + poe_width - width : winx
newypos := (winy + height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - height : winy
Gui, Settings_menu_help: Show, NA x%newxpos% y%newypos%
KeyWait, LButton
text := ""
Gui, settings_menu_help: Destroy
Return

Settings_menu_itemchecker:
settings_menu_section := "itemchecker"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Item-info">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"fSize0*2, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb tools and tables</a>

Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height*0.75, % "selected profile: "
Loop 5
{
	color_profile := InStr(itemchecker_profile, A_Index) ? "Fuchsia" : "White"
	Gui, settings_menu: Add, Text, % "ys Center Border gItemchecker c"color_profile " vitemchecker_profile"A_Index " BackgroundTrans x+2", % " "A_Index " "
}
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vitemchecker_profiles_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Text, % "xs Section Center Border BackgroundTrans vitemchecker_reset_highlight gItemchecker", % " reset desired mods "
Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-400 vertical Disabled vitemchecker_reset_highlight_bar cRed",
Gui, settings_menu: Add, Text, % "ys x+0 Center Border BackgroundTrans vitemchecker_reset_blacklist gItemchecker", % " reset undesired mods "
Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-400 vertical Disabled vitemchecker_reset_blacklist_bar cRed",

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height*0.75, % "general options:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", tooltip size:
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_itemchecker_minus gItemchecker Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center wp vfSize_itemchecker_reset gItemchecker Border x+2", % "r"
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center wp vfSize_itemchecker_plus gItemchecker Border x+2", % "+"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_ID Checked"enable_itemchecker_ID, % "shift-clicking activates item-info"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_ID_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_gear Checked"enable_itemchecker_gear, % "enable league-start mode"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_gear_help hp w-1", img\GUI\help.png
If enable_itemchecker_gear
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gItemchecker vitemchecker_reset_gear", % " reset inventory boxes "
	Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-400 vertical Disabled vitemchecker_reset_gear_bar cRed",
}

If !enable_itemchecker_gear
{
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_bases Checked"enable_itemchecker_bases, % "show information on base-stats"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_bases_help hp w-1", img\GUI\help.png

	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_dps Checked"enable_itemchecker_dps, % "only show dps on rares with meaningful mods"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_dps_help hp w-1", img\GUI\help.png
}

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_ilvl Checked"enable_itemchecker_ilvl, % "also display a mod's ilvl-requirements"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_ilvl_help hp w-1", img\GUI\help.png

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height*0.75, % "highlight options:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Picture, % "ys x+"fSize0//2 " BackgroundTrans gSettings_menu_help vitemchecker_colors_help hp w-1", img\GUI\help.png

Loop, 8
{
	value := (A_Index = 1) ? 7 : A_Index - 2
	
	If (A_Index = 1)
	{
		Gui, settings_menu: Add, Text, % "xs Section Center hp BackgroundTrans HWNDmain_text", % "tier"
		GuiControlGet, text_, Pos, % main_text
	}
	Gui, settings_menu: Add, Progress, % "ys hp wp BackgroundBlack Disabled Border vitemchecker_bar" value " c" itemchecker_t%value%_color, 100
	Gui, settings_menu: Add, Text, % "xp yp wp hp cBlack Center gItemchecker vitemchecker_t" value "_color BackgroundTrans", % (A_Index = 1) ? "x" : (A_Index = 2) ? "—" : value
}

Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans hp vitemchecker_apply_color gItemchecker Border", % " apply "

If enable_itemchecker_ilvl
{
	Loop, 8
	{
		If (A_Index = 1)
			Gui, settings_menu: Add, Text, % "xs Section w"text_w " Center BackgroundTrans", % "ilvl "
		Gui, settings_menu: Add, Progress, % "ys hp wp BackgroundBlack Disabled Border vitemchecker_bar_ilvl" A_Index " c" itemchecker_ilvl%A_Index%_color, 100
		color := (itemchecker_ilvl%A_Index%_color = "ffffff") && (A_Index = 1) ? "Red" : "Black"
		Gui, settings_menu: Add, Text, % "xp yp wp hp c"color " gItemchecker vitemchecker_ilvl" A_Index "_color Center BackgroundTrans", % itemchecker_default_ilvls[A_Index]
	}
}

Gui, settings_menu: Add, Checkbox, % "xs Section hp BackgroundTrans gItemchecker venable_itemchecker_override Checked"enable_itemchecker_override, % "blacklisting overrides tier && ilvl color"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_override_help hp w-1", img\GUI\help.png

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height*0.75, % "global rules/overrides:"
Gui, settings_menu: Add, Picture, % "ys x+"font_width " BackgroundTrans gSettings_menu_help vitemchecker_rules_help hp w-1", img\GUI\help.png
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_rule_weapon_res HWNDmain_text cRed Checked"enable_itemchecker_rule_weapon_res, % "res on weapons"
GuiControlGet, text_, Pos, % main_text
checkbox_spacing := text_w + font_width

;Gui, settings_menu: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gItemchecker venable_itemchecker_rule_suppression HWNDmain_text c"itemchecker_t1_color " Checked"enable_itemchecker_rule_suppression, % "suppression"
Gui, settings_menu: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gItemchecker venable_itemchecker_rule_attacks HWNDmain_text cRed Checked"enable_itemchecker_rule_attacks, % "attack dmg"
GuiControlGet, text_, Pos, % main_text
checkbox_spacing1 := text_w + font_width

Gui, settings_menu: Add, Checkbox, % "ys xp+"checkbox_spacing1 "BackgroundTrans gItemchecker venable_itemchecker_rule_spells HWNDmain_text cRed Checked"enable_itemchecker_rule_spells, % "spell dmg"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_rule_res HWNDmain_text cGreen Checked"enable_itemchecker_rule_res, % "resistances"

Gui, settings_menu: Add, Checkbox, % "ys xp+"checkbox_spacing " BackgroundTrans gItemchecker venable_itemchecker_rule_lifemana_gain HWNDmain_text cRed" " Checked"enable_itemchecker_rule_lifemana_gain, % "life && mana gain on hit/kill"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_rule_crit HWNDmain_text cRed Checked"enable_itemchecker_rule_crit, % "crit"
Return

Settings_menu_leveling_guide:
settings_menu_section := "leveling guide"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Leveling-Tracker">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"font_width*2, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb tools and tables</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gLeveling_guide y+"fSize0*1.2 " vsettings_enable_levelingtracker Checked"settings_enable_levelingtracker, % "enable leveling tracker"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_help hp w-1", img\GUI\help.png
If (settings_enable_levelingtracker = 1)
{
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gLeveling_guide vleveling_guide_enable_timer Checked"leveling_guide_enable_timer, % "enable timer"
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "skill-tree overlay settings:"
	Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vskilltree_overlay_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gLeveling_guide venable_omnikey_pob Checked"enable_omnikey_pob, % "pob: middle-click initiates screen-capping"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_pob_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Add, Text, % "xs Section gLeveling_guide vleveling_guide_skilltree_folder Border BackgroundTrans", % " open skilltree-folder "
	Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vLeveling_guide_skilltree_help hp w-1", img\GUI\help.png
	
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "guide settings:"
	Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vLeveling_guide_help2 hp w-1", img\GUI\help.png
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Text, % "xs Section Border Center gLeveling_guide vLeveling_guide_generate BackgroundTrans", % " generate guide "
	Gui, settings_menu: Add, Text, % "ys Center Border gLeveling_guide vLeveling_guide_import BackgroundTrans", % " import guide "
	Gui, settings_menu: Add, Text, % "ys Center Border gLeveling_guide vLeveling_guide_delete BackgroundTrans", % " delete guide "
	
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	guide_progress_percent := (guide_progress != "" && guide_text_original != "") ? Format("{:0.2f}", (LLK_InStrCount(guide_progress, "`n")/LLK_InStrCount(guide_text_original, "`n"))*100) : 0
	guide_progress_percent := (guide_progress_percent >= 99) ? 100 : guide_progress_percent
	Gui, settings_menu: Add, Text, % "xs Section vLeveling_guide_progress BackgroundTrans", % "current progress: " guide_progress_percent "%"
	Gui, settings_menu: Add, Text, % "ys Center Border gLeveling_guide vLeveling_guide_reset BackgroundTrans", % " reset progress "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", % "credit: "
	Gui, settings_menu: Add, Link, % "ys x+0 hp", <a href="https://github.com/HeartofPhos/exile-leveling">exile-leveling</a>
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans x+"fSize0//3, % "created by"
	Gui, settings_menu: Add, Link, % "ys hp x+"fSize0//3, <a href="https://github.com/HeartofPhos">HeartofPhos</a>
	
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "ui settings:"
	Gui, settings_menu: Font, norm
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_reset gLeveling_guide Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_plus gLeveling_guide Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_plus gLeveling_guide Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center c"leveling_guide_fontcolor " BackgroundTrans vleveling_guide_fontcolor_button gLeveling_guide Border", % " color "
	Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vLeveling_guide_color_help hp w-1", img\GUI\help.png
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", guide position:
	Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "top") ? "ys BackgroundTrans vleveling_guide_position_top gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_top gLeveling_guide", top
	;Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "right") ? "ys BackgroundTrans vleveling_guide_position_right gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_right gLeveling_guide", right
	Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "bottom") ? "ys BackgroundTrans vleveling_guide_position_bottom gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_bottom gLeveling_guide", bottom
	;Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "left") ? "ys BackgroundTrans vleveling_guide_position_left gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_left gLeveling_guide", left
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_reset gLeveling_guide Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_plus gLeveling_guide Border x+2 wp", % "+"
}
Return

Settings_menu_map_info:
settings_menu_section := "map info"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Map-info-panel">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"font_width*2, <a href="https://www.rapidtables.com/web/color/RGB_Color.html">rgb tools and tables</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_info y+"font_height " venable_map_info Checked"enable_map_info, enable the map-info panel

If enable_map_info
{
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_info venable_map_info_shiftclick Checked"enable_map_info_shiftclick, shift-clicking activates map-info
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vmap_info_shiftclick_help hp w-1", img\GUI\help.png
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height/2, text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_minus gMap_info Border x+"font_width/2, % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_reset gMap_info Border x+"font_width/4 " wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_plus gMap_info Border x+"font_width/4 " wp", % "+"
	
	;Gui, settings_menu: Font, bold underline
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", highlight colors:
	Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmapinfo_colors_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Font, norm
	Loop 5
	{
		loop := A_Index - 1, text := (A_Index = 1) ? " headers " : " diff " loop " "
		style := (A_Index = 1) ? "Section xs y+1 c"mapinfo_colors[loop] : "ys x+"font_width/4 " c"mapinfo_colors[loop]
		Gui, settings_menu: Add, Text, % style " Border Center BackgroundTrans gMap_info vmapinfo_settings_color"loop, % text
	}
}
Return

Settings_menu_map_tracker:
settings_menu_section := "map tracker"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Mapping-tracker">wiki page</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_tracker y+"fSize0*1.2 " vsettings_enable_maptracker Checked"settings_enable_maptracker, enable mapping tracker
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmap_tracker_help hp w-1 x+0", img\GUI\help.png

If settings_enable_maptracker
{
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_tracker_minus gMap_tracker Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_tracker_reset gMap_tracker Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_tracker_plus gMap_tracker Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_map_tracker_minus gMap_tracker Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_map_tracker_reset gMap_tracker Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_map_tracker_plus gMap_tracker Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans HWNDmain_text", panel offset (x/y):
	WinGetPos,,, width,, ahk_id %main_text%
	Gui, settings_menu: Font, % "s"fSize0 - 4
	Gui, settings_menu: Add, Edit, % "ys hp BackgroundTrans cBlack vxpos_offset_map_tracker gMap_tracker w"width/3,
	Gui, settings_menu: Add, UpDown, % "ys range-10000-10000", % xpos_offset_map_tracker
	
	Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans vypos_offset_map_tracker gMap_tracker cBlack w"width/3,
	Gui, settings_menu: Font, % "s"fSize0
	Gui, settings_menu: Add, UpDown, % "ys range-10000-10000", % ypos_offset_map_tracker
	
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_tracker vmap_tracker_enable_side_areas Checked"map_tracker_enable_side_areas " y+"fSize0*1.2, track side-areas in maps
	Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmap_tracker_side_area_help hp w-1 x+0", img\GUI\help.png
	
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_tracker venable_loottracker Checked"enable_loottracker, enable loot tracker
	Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmap_tracker_loot_help hp w-1 x+0", img\GUI\help.png
	
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_tracker venable_killtracker Checked"enable_killtracker, enable kill tracker
	Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmap_tracker_kill_help hp w-1 x+0", img\GUI\help.png
}
Return

Settings_menu_notepad:
settings_menu_section := "notepad"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Notepad-&-Text-widgets">wiki page</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gNotepad y+"fSize0*1.2 " venable_notepad Checked"enable_notepad, enable notepad
If (enable_notepad = 1)
{
	GoSub, Notepad
	;Gui, settings_menu: Font, bold underline
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color (widget):
	Gui, settings_menu: Font, norm
	;Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans vfontcolor c"notepad_fontcolor " gNotepad Border", % " apply rgb-hexcode "
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans vfontcolor_white cWhite gNotepad Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gNotepad Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gNotepad Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gNotepad Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gNotepad Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gNotepad Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_minus gNotepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_reset gNotepad Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_plus gNotepad Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vnotepad_opac_minus gNotepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vnotepad_opac_plus gNotepad Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_minus gNotepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_reset gNotepad Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_plus gNotepad Border x+2 wp", % "+"
}
Return

Settings_menu_hotkeys:
settings_menu_section := "hotkeys"

If (A_GuiControl = "settings_advanced_items_rebound") || (A_GuiControl = "settings_ckey_rebound")
{
	LLK_SettingsHotkeysRefresh()
	Return
}

If (A_GuiControl = "hotkeys_restart")
{
	Gui, settings_menu: Submit, NoHide
	If GetKeyState("ALT", "P") || GetKeyState("CTRL", "P") || GetKeyState("Shift", "P")
		Return
	
	If settings_advanced_items_rebound && !settings_alt_modifier
	{
		LLK_ToolTip("mod-descriptions checkbox is ticked`nbut custom key is not specified", 2.5)
		Return
	}
	
	If settings_ckey_rebound && !settings_omnikey_hotkey2
	{
		LLK_ToolTip("c-key checkbox is ticked but`nomni-key 2 is not specified", 2.5)
		Return
	}
	
	IniWrite, % settings_advanced_items_rebound, ini\hotkeys.ini, Settings, advanced item-info rebound
	IniWrite, % settings_ckey_rebound, ini\hotkeys.ini, Settings, c-key rebound
	IniWrite, % settings_alt_modifier, ini\hotkeys.ini, Hotkeys, item-descriptions key
	IniWrite, % settings_omnikey_hotkey, ini\hotkeys.ini, Hotkeys, omni-hotkey
	IniWrite, % settings_omnikey_hotkey2, ini\hotkeys.ini, Hotkeys, omni-hotkey2
	IniWrite, % settings_tab_hotkey, ini\hotkeys.ini, Hotkeys, tab replacement
	IniWrite, % settings_menu_section, ini\config.ini, Versions, reload settings
	Reload
	ExitApp
	Return
}

;some controls are prefixed with "settings_" in order to prevent global vars from being overwritten when GUI is submitted with incomplete/incorrect config
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Omni-key">wiki page</a>
Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"font_height*0.8, % "in-game keybind settings:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans vingame_keys_help gSettings_menu_help hp w-1", img\GUI\help.png
;Gui, settings_menu: Add, Link, % "ys hp", <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Known-Issues-&-Limitations#custom-poe-keybinds-alt--c">wiki</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gSettings_menu_hotkeys vSettings_advanced_items_rebound Checked"advanced_items_rebound, <show advanced item descriptions>`nis not bound to the alt-key

Gui, settings_menu: Add, Text, % "xs xp+"font_width*2 " BackgroundTrans vsettings_text_altkey", % "–> instead bound to: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "x+0 hp vsettings_alt_modifier BackgroundTrans cBlack w"font_width*10, % alt_modifier
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Link, % "x+"font_width*0.75 " hp vsettings_text_altkey_link", <a href="https://www.autohotkey.com/docs/v1/KeyList.htm">format</a>

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gSettings_menu_hotkeys vSettings_ckey_rebound Checked"ckey_rebound, the c-key is used for something`nother than <character screen>

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"font_height*0.8, omni-key settings:
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans vOmnikey_help gSettings_menu_help hp w-1", img\GUI\help.png
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "replace m-mouse with: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Hotkey, % "ys x+0 hp cWhite BackgroundTrans vsettings_omnikey_hotkey w"font_width*10, % (omnikey_hotkey = "MButton") ? "" : omnikey_hotkey
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans vsettings_text_omni2", % "omni-key 2 (for items): "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Hotkey, % "ys x+0 hp cWhite BackgroundTrans vsettings_omnikey_hotkey2 w"font_width*10, %omnikey_hotkey2%
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"font_height*0.8, miscellaneous keys:
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans vmisc_keys_help gSettings_menu_help hp w-1", img\GUI\help.png
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "replace tab with: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Hotkey, % "ys x+0 hp cWhite BackgroundTrans vsettings_tab_hotkey w"font_width*10, % (tab_hotkey = "TAB") ? "" : tab_hotkey
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Font, % "s"fSize0 + 4
Gui, settings_menu: Add, Text, % "xs y+"font_height " Border vhotkeys_restart gSettings_menu_hotkeys Section BackgroundTrans", % " apply && restart "
Gui, settings_menu: Font, % "s"fSize0
ControlGetPos,,, width,,, ahk_id %main_text%

/*
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border vomnikey_apply gSettings_menu_hotkeys", % " apply && restart "
Gui, settings_menu: Add, Text, % "xs Section cRed BackgroundTrans", % "only for custom alt && c in-game keybinds: "


Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "highlight-key:"
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys hp valt_modifier BackgroundTrans cBlack w"width//2, % alt_modifier
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "omni-key (items):"
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Hotkey, % "ys hp vomnikey_hotkey2 BackgroundTrans w"width//2, % omnikey_hotkey2
Gui, settings_menu: Font, % "s"fSize0
*/
Return

Settings_menu_screenchecks:
settings_menu_section := "screenchecks"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Screen-checks">wiki page</a>
Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "list of integrated pixel-checks:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vPixelcheck_help hp w-1", img\GUI\help.png
Loop, Parse, pixelchecks_list, `,, `,
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans border gScreenchecks v" A_Loopfield "_pixel_test y+"fSize0*0.6, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//4 " border gScreenchecks v" A_Loopfield "_pixel_calibrate", % " calibrate "
	If !pixel_%A_LoopField%_color1
		Gui, settings_menu: Font, cRed underline
	Else Gui, settings_menu: Font, cWhite underline
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans gSettings_menu_help v" A_Loopfield "_help", % A_Loopfield
	Gui, settings_menu: Font, norm cWhite
}
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Checkbox, % "hp xs Section BackgroundTrans gScreenchecks vEnable_pixelchecks Center Checked"enable_pixelchecks, % "enable background pixel-checks"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_enable_help hp w-1", img\GUI\help.png

If (poe_height_initial / poe_width_initial < (5/12))
{
	Gui, settings_menu: Add, Checkbox, % "hp xs Section BackgroundTrans gScreenchecks vEnable_blackbar_compensation Center Checked"enable_blackbar_compensation, % "the client has black bars on the sides"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_blackbars_help hp w-1", img\GUI\help.png
}

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.5, % "list of active image-checks:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vImagecheck_help hp w-1", img\GUI\help.png
Loop, Parse, imagechecks_list_copy, `,, `,
{
	If (settings_enable_%A_LoopField% = 0) || (A_LoopField = "skilltree" && !settings_enable_levelingtracker) || (A_LoopField = "stash" && (!settings_enable_maptracker || !enable_loottracker))
		continue
	
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans border gScreenchecks v" A_Loopfield "_image_test y+"fSize0*0.4, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//4 " border gScreenchecks v" A_Loopfield "_image_calibrate", % " calibrate "
	
	;Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans gScreenchecks Checked" disable_imagecheck_%loopfield_copy% " vDisable_imagecheck_" loopfield_copy, % "disable: "
	If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_LoopField ".bmp") || !imagechecks_coords_%A_LoopField% && (A_LoopField != "betrayal")
		Gui, settings_menu: Font, cRed underline
	Else Gui, settings_menu: Font, cWhite underline
	
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans gSettings_menu_help vimagecheck_help_"A_LoopField, % A_LoopField
	Gui, settings_menu: Font, norm cWhite
}
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Center Border gScreenchecks vImage_folder y+"fSize0*0.6, % " open img folder "
Return

Settings_menu_stash_search:
settings_menu_section := "stash search"
GoSub, Init_searchstrings
new_stash_search_menu_closed := 0
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Search-strings">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"font_width*3, <a href="https://poe.re/">poe regex</a>

/*
IniRead, stash_search_list, ini\stash search.ini
Sort, stash_search_list, D`n
Loop, Parse, stash_search_list, `n, `n
{
	loopfield_copy := StrReplace(A_Loopfield, "|", "vertbar")
	If (A_LoopField = "Settings")
		continue
	If stash_search_%loopfield_copy%_enable is not number
		IniRead, stash_search_%loopfield_copy%_enable, ini\stash search.ini, %A_LoopField%, enable, 1
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gStash_search_apply Checked" stash_search_%loopfield_copy%_enable " vStash_search_" loopfield_copy "_enable", % "enable: "
	Gui, settings_menu: Font, underline
	text := StrReplace(A_Loopfield, "_", " ")
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gStash_search_preview_list", % text
	Gui, settings_menu: Font, norm
}
*/

Loop, % stash_search_list.Length()
{
	If (A_Index = 1)
	{
		Gui, settings_menu: Font, bold underline
		Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "list of searches currently set up:"
		Gui, settings_menu: Font, norm
		Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vsearchstrings_list_help hp w-1", img\GUI\help.png
	}
	pEntry := StrReplace(stash_search_list[A_Index], " ", "_")
	Gui, settings_menu: Add, Text, % "Section xs BackgroundTrans Border gStash_search vsettings_menu_searchstrings_test_"pEntry, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border x+"font_width/2 " gStash_search vsettings_menu_searchstrings_calibrate_"pEntry, % " calibrate "
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans x+"font_width " gStash_search vsearchstrings_enable_"pEntry " Checked"searchstrings_enable_%pEntry%, % "enable:"
	Gui, settings_menu: Add, Progress, % "ys hp BackgroundBlack x+"font_width/8 " w"font_width/2 " range0-400 cRed vertical vsettings_menu_searchstrings_delprogress_"pEntry
	Gui, settings_menu: Font, underline
	cEntry := searchstrings_enable_%pEntry% && !searchstrings_searchcoords_%pEntry% ? "Red" : "White"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+0 c"cEntry " gStash_search vsettings_menu_searchstrings_entry_"pEntry, % stash_search_list[A_Index]
	If (stash_search_list[A_Index] = "hideout lilly")
		Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vsearchstrings_lilly_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Font, % "norm"
}

Gui, settings_menu: Add, Text, % "Section xs BackgroundTrans y+"font_height*0.8, % "add search: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys cBlack x+0 hp w"font_width*15 " HWNDhwnd_settings_menu_searchstrings_edit vsettings_menu_searchstrings_newname"
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Picture, % "ys x+"font_width/2 " BackgroundTrans gSettings_menu_help vsearchstrings_add_help hp w-1", img\GUI\help.png
Gui, settings_menu: Add, Button, % "x0 y0 Hidden default gStash_search vsettings_menu_searchstrings_add BackgroundTrans", ok
Return

LLK_ScreenChecksValid()
{
	global
	local valid := 1
	Loop, Parse, pixelchecks_list, `,
		valid *= pixel_%A_LoopField%_color1 ? 1 : 0

	Loop, Parse, imagechecks_list_copy, `,
	{
		If (settings_enable_%A_LoopField% = 0) || (A_LoopField = "skilltree" && !settings_enable_levelingtracker) || (A_LoopField = "stash" && (!settings_enable_maptracker || !enable_loottracker))
			continue
		valid *= FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp") && (imagechecks_coords_%A_LoopField% || A_LoopField = "betrayal") ? 1 : 0
	}
	
	If valid
		GuiControl, settings_menu: +%pixelcheck_style%, screen-checks
	Else GuiControl, settings_menu: +cRed, screen-checks
	GuiControl, settings_menu: movedraw, screen-checks
}

LLK_SettingsHotkeysRefresh()
{
	global
	Gui, settings_menu: Submit, NoHide
	If InStr(A_GuiControl, "_rebound")
		local style := settings_advanced_items_rebound ? "-" : "+"
	Else local style := advanced_items_rebound ? "-" : "+"
	GuiControl, settings_menu: %style%hidden, settings_text_altkey
	GuiControl, settings_menu: movedraw, settings_text_altkey
	GuiControl, settings_menu: %style%hidden, settings_alt_modifier
	GuiControl, settings_menu: movedraw, settings_alt_modifier
	GuiControl, settings_menu: %style%hidden, settings_text_altkey_link
	GuiControl, settings_menu: movedraw, settings_text_altkey_link
	
	If InStr(A_GuiControl, "_rebound")
		style := settings_ckey_rebound ? "-" : "+"
	Else style := ckey_rebound ? "-" : "+"
	GuiControl, settings_menu: %style%hidden, settings_text_omni2
	GuiControl, settings_menu: movedraw, settings_text_omni2
	GuiControl, settings_menu: %style%hidden, settings_omnikey_hotkey2
	GuiControl, settings_menu: movedraw, settings_omnikey_hotkey2
}

settings_menuGuiClose()
{
	global
	WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
	Gui, settings_menu: Submit
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
	Gui, settings_menu: Destroy
	hwnd_settings_menu := ""
	settings_menu_section := ""

	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	LLK_Overlay("betrayal_info_members", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
		LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")

	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
	Gui, loottracker: Destroy
	hwnd_loottracker := ""

	If WinExist("ahk_id " hwnd_notepad_sample)
	{
		Gui, notepad_sample: Destroy
		hwnd_notepad_sample := ""
	}

	If WinExist("ahk_id " hwnd_alarm_sample)
	{
		Gui, alarm_sample: Destroy
		hwnd_alarm_sample := ""
	}
	WinActivate, ahk_group poe_window
}