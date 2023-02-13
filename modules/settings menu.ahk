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
	GoSub, Settings_menuGuiClose
	WinActivate, ahk_group poe_window
	Return
}
settings_style := InStr(A_GuiControl, "general") || (A_Gui = "LLK_panel") || (A_Gui = "") ? "cAqua" : "cWhite"
If !ultrawide_warning && (poe_height_initial/poe_width_initial < (5/12))
	settings_style := "cWhite"
alarm_style := InStr(A_GuiControl, "alarm") ? "cAqua" : "cWhite"
betrayal_style := (InStr(A_GuiControl, "betrayal") && !InStr(A_GuiControl, "image")) ? "cAqua" : "cWhite"
clone_frames_style := InStr(A_GuiControl, "clone") || (new_clone_menu_closed = 1) ? "cAqua" : "cWhite"
delve_style := InStr(A_GuiControl, "delve") ? "cAqua" : "cWhite"
flask_style := InStr(A_GuiControl, "flask") ? "cAqua" : "cWhite"
itemchecker_style := InStr(A_GuiControl, "item-info") || InStr(A_GuiControl, "itemchecker") ? "cAqua" : "cWhite"
leveling_style := InStr(A_GuiControl, "leveling") ? "cAqua" : "cWhite"
map_tracker_style := InStr(A_GuiControl, "map") && InStr(A_GuiControl, "tracker") ? "cAqua" : "cWhite"
map_mods_style := InStr(A_GuiControl, "map-info") || InStr(A_GuiControl, "map_info") ? "cAqua" : "cWhite"
notepad_style := InStr(A_GuiControl, "notepad") ? "cAqua" : "cWhite"
omnikey_style := InStr(A_GuiControl, "omni-key") ? "cAqua" : "cWhite"
pixelcheck_style := (InStr(A_GuiControl, "check") && !InStr(A_GuiControl, "checker") || InStr(A_GuiControl, "image") || InStr(A_GuiControl, "pixel")) ? "cAqua" : "cWhite"
stash_style := InStr(A_GuiControl, "search-strings") || InStr(A_GuiControl, "stash_search") ||(new_stash_search_menu_closed = 1) ? "cAqua" : "cWhite"
geforce_style := InStr(A_GuiControl, "geforce") ? "cAqua" : "cLime"
GuiControl_copy := A_GuiControl
If (A_Gui = "settings_menu")
{
	Gui, settings_menu: Submit, NoHide
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
}
Gui, settings_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_settings_menu, Lailloken UI: settings
Gui, settings_menu: Color, Black
Gui, settings_menu: Margin, 12, 4
WinSet, Transparent, % InStr(GuiControl_copy, "itemchecker") || InStr(GuiControl_copy, "item-info") ? 255 : trans
Gui, settings_menu: Font, s%fSize0% cWhite underline, Fontin SmallCaps

Gui, settings_menu: Add, Text, % "Section BackgroundTrans " settings_style " gSettings_menu HWNDhwnd_settings_general", % "general"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_general%
spacing_settings := width_settings

If (pixel_gamescreen_color1 = "ERROR" || pixel_gamescreen_color1 = "")
	screenchecks_gamescreen_valid := 0
Else screenchecks_gamescreen_valid := 1

Loop, Parse, imagechecks_list, `,, `,
{
	screenchecks_%A_Loopfield%_valid := 1
	If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp") && (disable_imagecheck_%A_Loopfield% = 0)
		screenchecks_%A_Loopfield%_valid := 0
}

screenchecks_all_valid := 1
screenchecks_all_valid *= screenchecks_gamescreen_valid

Loop, Parse, imagechecks_list, `,, `,
	screenchecks_all_valid *= screenchecks_%A_Loopfield%_valid

If !InStr(buggy_resolutions, poe_height) && (safe_mode != 1)
{
	Gui, settings_menu: Add, Text, xs BackgroundTrans %alarm_style% gSettings_menu HWNDhwnd_settings_alarm, % "alarm-timer"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_alarm%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %betrayal_style% gSettings_menu HWNDhwnd_settings_betrayal, % "betrayal-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_betrayal%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %clone_frames_style% gSettings_menu HWNDhwnd_settings_clone_frames, % "clone-frames"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_clone_frames%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %delve_style% gSettings_menu HWNDhwnd_settings_delve, % "delve-helper"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_delve%
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

	Gui, settings_menu: Add, Text, xs BackgroundTrans %omnikey_style% gSettings_menu HWNDhwnd_settings_omnikey, % "omni-key"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_omnikey%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	If pixel_gamescreen_x1 is number
	{
		If (screenchecks_all_valid = 0)
			pixelcheck_style := "cRed"
		Gui, settings_menu: Add, Text, xs BackgroundTrans %pixelcheck_style% gSettings_menu HWNDhwnd_settings_pixelcheck, % "screen-checks"
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
	GoSub, Settings_menu_screenchecks
}

If (InStr(GuiControl_copy, "general") || (A_Gui = "LLK_panel") || (A_Gui = "")) && !pending_ultrawide
	GoSub, Settings_menu_general
Else If InStr(GuiControl_copy, "alarm")
	GoSub, Settings_menu_alarm
Else If InStr(GuiControl_copy, "betrayal") && !InStr(GuiControl_copy, "image")
	GoSub, Settings_menu_betrayal
Else If InStr(GuiControl_copy, "clone") || (new_clone_menu_closed = 1)
	GoSub, Settings_menu_clone_frames
Else If InStr(GuiControl_copy, "delve")
{
	If enable_delve
	{
		xsettings_menu := xScreenOffSet
		ysettings_menu := yScreenOffSet + poe_height/3
	}
	GoSub, Settings_menu_delve
}
Else If InStr(GuiControl_copy, "item-info") || InStr(GuiControl_copy, "itemchecker")
	GoSub, Settings_menu_itemchecker
Else If InStr(GuiControl_copy, "leveling")
	GoSub, Settings_menu_leveling_guide
Else If (InStr(GuiControl_copy, "map") && InStr(GuiControl_copy, "tracker"))
{
	map_tracker_clicked := A_TickCount ;workaround for stupid UpDown behavior that leads to rare error message
	GoSub, Settings_menu_map_tracker
}
Else If InStr(GuiControl_copy, "map-info") || InStr(GuiControl_copy, "map_info")
	GoSub, Settings_menu_map_info
Else If InStr(GuiControl_copy, "notepad")
	GoSub, Settings_menu_notepad
Else If InStr(GuiControl_copy, "omni")
	GoSub, Settings_menu_omnikey
Else If InStr(GuiControl_copy, "image") || InStr(GuiControl_copy, "pixel") || InStr(GuiControl_copy, "screen")
	GoSub, Settings_menu_screenchecks
Else If InStr(GuiControl_copy, "search-strings") || InStr(GuiControl_copy, "stash_search") || (new_stash_search_menu_closed = 1)
	GoSub, Settings_menu_stash_search
Else If InStr(GuiControl_copy, "geforce")
	GoSub, Settings_menu_geforce_now

If !InStr(GuiControl_copy, "betrayal")
{
	ControlFocus,, ahk_id %hwnd_settings_general%
	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	LLK_Overlay("betrayal_info_members", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
		LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")
}
Else ControlFocus,, ahk_id %hwnd_betrayal_edit%

If ((xsettings_menu != "") && (ysettings_menu != ""))
	Gui, settings_menu: Show, Hide x%xsettings_menu% y%ysettings_menu%
Else Gui, settings_menu: Show, Hide

LLK_Overlay("settings_menu", "show", 1)
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
Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vBetrayal_enable_recognition BackgroundTrans y+"fSize0*1.2 " Checked"betrayal_enable_recognition, % "use image recognition"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vbetrayal_recognition_help hp w-1", img\GUI\help.png
If betrayal_enable_recognition
	Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vBetrayal_perma_table BackgroundTrans Checked"betrayal_perma_table, enable table in recognition-mode
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
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2 " c"color, % "prio-view settings"
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", % "frame dimensions: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys x+0 Center BackgroundTrans cBlack hp vbetrayal_info_prio_dimensions gBetrayal_apply", % (betrayal_info_prio_dimensions = 0) ? 100 : betrayal_info_prio_dimensions
Gui, settings_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 range0-1000", % betrayal_info_prio_dimensions
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys Center Border BackgroundTrans vbetrayal_info_prio_apply gBetrayal_apply", % " save "

GoSub, Betrayal_search
GoSub, GUI_betrayal_prioview
Return

Settings_menu_clone_frames:
settings_menu_section := "clone frames"
new_clone_menu_closed := 0
clone_frames_enabled := ""
IniRead, clone_frames_list, ini\clone frames.ini
Sort, clone_frames_list, D`n
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames">wiki page</a>
If (pixel_gamescreen_x1 != "") && (pixel_gamescreen_x1 != "ERROR") && (enable_pixelchecks = 1)
{
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply vClone_frames_pixelcheck_enable Checked" clone_frames_pixelcheck_enable " y+"fSize0*1.2, automatically hide clone-frames
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vpixelcheck_auto_trigger hp w-1", img\GUI\help.png
}
If (poe_log_file != 0)
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply vClone_frames_hideout_enable Checked"clone_frames_hideout_enable, hide clone-frames in hideouts/towns

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "list of clone-frames currently set up: "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vclone_frames_list_help hp w-1", img\GUI\help.png
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
Return

Settings_menu_help:
MouseGetPos, mouseXpos, mouseYpos
Gui, settings_menu_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_settings_menu_help
Gui, settings_menu_help: Color, Black
Gui, settings_menu_help: Margin, 12, 4
Gui, settings_menu_help: Font, s%fSize1% cWhite, Fontin SmallCaps

;//////////////////////////////////////////////////////////////////////////////
;//////////////// Betrayal

If (A_GuiControl = "betrayal_recognition_help")
{
text =
(
if enabled, the script will read the screen underneath the mouse-cursor to check for syndicate-member cards, then display the appropriate cheat-sheet.

this requires correctly setting up the 'betrayal' image-check in the settings menu, and the following:
- each member's card has to be screen-capped once (refer to wiki for instructions)
- each of the four divisions has to be screen-capped once (optional)
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
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
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

;//////////////////////////////////////////////////////////////////////////////
;//////////////// Leveling tracker

If (A_GuiControl = "leveling_guide_skilltree_help")
{
text =
(
opens the folder where skilltree-screenshots are stored.

these screenshots can be overlaid by holding the omni-key while viewing the in-game skilltree:
–> right-clicks will switch to the next screenshot
–> long right-clicks will switch to the previous screenshot
–> using number-keys 1 to 0 will jump to image 1 to 10

they are accessed in alphabetical order, so make sure to name them accordingly.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "leveling_guide_skilltree_cap_help")
{
text =
(
cropping:
–> left-click the preview image to set the top-left corner of the cropped area
–> right-click the preview image to set the bottom-right corner of the cropped area

captions:
–> enter a caption or choose an entry from the drop-down list to replace an existing screenshot (right-click an entry to delete it)
–> the [XX]-tag at the beginning is merely for sorting and will not be displayed in the actual caption of the overlay
–> if you don't want to add a caption, just leave the sample text as it is and press enter
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "leveling_guide_pob_help")
{
text =
(
if enabled, pressing the middle mouse-button in pob will initiate screen-capping via the windows snipping tool.
	
after screen-capping an area, a setup-window with a preview will open. if desired, a caption can be added to the image. this caption will be displayed in the skilltree-overlay in game.

press enter to save the screen-cap, or esc to abort.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "gear_tracker_help")
{
text =
(
the drop-down list contains the most recent characters found in the client-log.

items that are ready to be equipped are highlighted green. by default, the list only shows items up to 5 levels higher than your character.

clicking an item on the list will highlight it in game (stash and vendors). right-clicking will remove it from the list.

you can click the 'select character' label to highlight all green items at once.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_tracker_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to track and log your map runs.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_info_shiftclick_help")
{
text =
(
if enabled, the map-info panel will be triggered whenever currency-items are applied via shift-clicking.

hold shift -before- right-clicking currency-items for the first time.

while holding shift, left-click items to apply currency and trigger the map-info panel.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "clone_frames_list_help")
{
text =
(
long-click the underlined names to see a preview of the clone-frame

right-click the underlined names to open a context-menu with additional options
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_tracker_side_area_help")
{
text =
(
checking this option will also include side-areas (lab trials, vaal areas, abyss, etc.) in the map time and logs.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_tracker_loot_help")
{
text =
(
checking this option will also log items that are being ctrl-clicked from the inventory into the stash.

note: 'stash' image-check has to be set up in the screen-checks settings
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_tracker_kill_help")
{
text =
(
checking this option will also log the number of kills in a map.

note: the map-tracker panel will start flashing at the start of a map, and you have to click the timer once to set the starting point.

whenever you leave the map device, the panel will turn green, indicating the kill-count has to be updated by clicking the timer again. this only needs to be done if the map is completed and you want to open a new one.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "leveling_guide_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to track your character's current location and level.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "leveling_guide_help2")
{
text =
(
generate guide: opens exile-leveling created by HeartofPhos.

import guide: imports an exile-leveling guide from clipboard.

delete guide: deletes the imported guide and removes included gems from gear tracker.

reset progress: resets the campaign progress and starts over.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "delve_help")
{
text =
(
checking this option will enable scanning the client-log generated by the game-client in order to check whether your character is in the azurite mine.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_info")
{
text =
(
0 hides the mod from now on, and higher values have distinct text-colors.

it's up to you how to tier the mods and whether to use all tiers.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "browser_features_help")
{
text =
(
explanation
enables complementary features when accessing 3rd-party websites in your browser

examples
- chromatics calculator: auto-input of required stats
- cluster jewel crafting: F3 quick-search
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
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
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
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
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "geforce_now_help")
{
text =
(
explanation
since geforce now is a streaming-based client, its image quality can fluctuate significantly.
this results in screen-checks being inconsistent and the script behaving abnormally.
to counteract this, screen-checks can be 'loosened' in order to be less strict and adapt to changing image-quality.

instructions
if you have problems with screen-checks, increase variation by 15 and see if that fixes it.
repeat until the script's behavior becomes stable.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "pixelcheck_auto_trigger")
{
text =
(
by adapting to what's happening on screen, the script automatically hides/shows clone-frames to avoid blocking in-game interfaces.

requires the 'gamescreen' pixel-check to be set up correctly, as well as playing with the mini-map in the center of the screen.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "pixelcheck_help")
{
text =
(
explanation
click 'test' to verify if the pixel-check is working, click 'calibrate' to read the required pixel and save the color-value. long-click the underlined names to see specific instructions for that check.

game-patches sometimes include ui or texture updates, which leads to screen-checks failing. this is where you recalibrate the checks to ensure they function properly.

disclaimer
these screen-checks merely trigger actions within the script itself and will -never- result in any interaction with the client.

they are used to let the script adapt to what's happening on screen, emulating the use of an addon-api:
- automatically hide overlays to avoid blocking in-game interfaces
- make context-sensitive hotkeys possible
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "Pixelcheck_blackbars_help")
{
text =
(
if the game-client has black bars on each side, pixel-checks will constantly fail because they are reading black pixels.

this option will fix that by compensating for black bars. toggling this checkbox will restart the script.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "gamescreen_help")
{
text =
(
instructions
close the inventory and every menu until you're on the main screen (where you control your character). then, set the mini-map to overlay-mode on the center of the screen, and click 'calibrate'.

explanation
this check helps the script identify whether the user is in a menu or on the regular 'gamescreen', which enables it to hide overlays automatically in order to prevent obstructing full-screen menus.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\game_screen.jpg
	Gui, settings_menu_help: Add, Text, BackgroundTrans wp, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "inventory_help")
{
text =
(
open the inventory, then click 'calibrate'.

explanation
this check helps the script identify whether the inventory is open, which enables the item-info gear-tracker to function correctly.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "pixelcheck_enable_help")
{
text =
(
this should only be disabled when experiencing severe performance drops while running the script.

when disabled, overlays will not show/hide automatically (if the user navigates through in-game menus) and they have to be toggled manually.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}


If (A_GuiControl = "imagecheck_help")
{
text =
(
click 'test' to verify if the image-check is working, click 'calibrate' to screen-cap the required image.

same concept as pixel-checks (see top of this section) but with images instead of pixels. image-checks are used when pixel-checks are unreliable due to movement on screen.

individual checks can be disabled if you know you won't be using the connected feature and want to hide the red highlighting.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_bestiary")
{
text =
(
instructions
to recalibrate, open the beastcrafting window and screen-cap the plate displayed above.

explanation
this check helps the script identify whether the beastcrafting window is open or not, which enables the omni-key to trigger the beastcrafting context-menu.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\bestiary.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_bestiarydex")
{
text =
(
instructions
to recalibrate, open the challenge-menu (default-hotkey: h), and click the 'bestiary' tab. open the 'captured beasts' menu at the bottom, then screen-cap the area in the red box displayed above.

explanation
this check helps the script identify whether the bestiary index is open or not, which enables the omni-key to trigger the search-strings feature.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\bestiary-dex.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_skilltree")
{
text =
(
instructions
to recalibrate, open the skill-tree and screen-cap the area in the red box displayed above.

explanation
this check helps the script identify whether the skill-tree is open or not, which enables the omni-key to overlay skill-tree screenshots.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\skill-tree.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_betrayal")
{
text =
(
instructions
to recalibrate, open the syndicate board, do not zoom into or move it, and screen-cap the area displayed above.

explanation
this check helps the script identify whether the syndicate board is up or not, which enables the omni-key to trigger the betrayal-info feature.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\betrayal.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_gwennen")
{
text =
(
instructions
to recalibrate, open Gwennen's gamble window and screen-cap the plate displayed above.

explanation
this check helps the script identify whether Gwennen's gamble window is open or not, which enables the omni-key to trigger the regex-string features.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\gwennen.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_sanctum")
{
text =
(
instructions
to recalibrate, open your inventory and the sanctum map, then screen-cap the area displayed above.

explanation
this check helps the script identify whether the sanctum map is open or not, which enables the omni-key to trigger its cheat-sheet.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\sanctum.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_stash")
{
text =
(
instructions
to recalibrate, open your stash and screen-cap the plate displayed above.

explanation
this check helps the script identify whether your stash is open or not, which enables the omni-key to trigger the search-string features.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\stash.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "imagecheck_help_vendor")
{
text =
(
instructions
to recalibrate, open the purchase-window of a vendor and screen-cap the plate displayed above.

explanation
this check helps the script identify whether you are interacting with a vendor-npc, which enables the omni-key to trigger the search-string features.

limitation (leveling tracker)
campaign-lilly and hideout-lilly use different vendor windows. if you don't use search-strings with general vendors, you can calibrate this image-check with hideout-lilly's window. otherwise, you'll have to buy gems from lilly in Act 10 when using the tracker-gems string.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"font_width*35 " h-1", img\GUI\vendor.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans wp", % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}


If InStr(A_GuiControl, "omnikey")
{
text =
(
this hotkey is context-sensitive and used to access the majority of this script's features. it's meant to be the only hotkey you have to use while playing.

this feature does not block the key-press from being sent to the client, so you can still use skills bound to the middle mouse-button. if you still want/need to rebind it, bind it to a key that's not used for chatting.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_ID_help")
{
text =
(
if enabled, the tooltip will be triggered whenever currency-items are applied via shift-clicking.

hold shift -before- right-clicking currency-items for the first time.

while holding shift, left-click items to apply currency and trigger the item-info tooltip.
	
while holding shift, right-click items to place a red marker.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_profiles_help")
{
text =
(
the lists of (un)desired mods are stored in individual profiles that can be switched between.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
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
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_ilvl_help")
{
text =
(
this option caters to advanced users because it adds an additional column with a mod's ilvl-requirements, which may be overwhelming or confusing.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_colors_help")
{
text =
(
"tier x" = fractured mods
"tier —" = un-tiered mods (veiled, delve, incursion, etc.)

tier 1 is also the color that marks desired mods, tier 6 the one that marks undesired ones.

'tier x' always overrides ilvl colors, 'tier —' whenever ilvl is not a differentiating factor.

click a field to apply an rgb hex-code from the clipboard, right-click a field to reset it to the default color.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_override_help")
{
text =
(
if enabled, undesired mods will always have their tier && ilvl highlighted in the t6 color, regardless of the actual tier and ilvl.

hybrid mods will only be overridden if every aspect of the mod is undesired, and fractured mods will never be overridden.

note: when enabled, marking as undesired should be used carefully and only for mods that are inherently bad. you may otherwise dismiss an item as bad solely based on your own preferences.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
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
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_dps_help")
{
text =
(
shows an additional row at the top of the tooltip with dps information.

unchecked: dps will always be shown for weapons (league-start or leveling)

checked: dps will be shown on every unique weapon, and rare weapons with at least 3 damage mods (work in progress, will refine it at a later date)
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "itemchecker_gear_help")
{
text =
(
when enabled, equipped items are tracked and serve as a point of comparison for the item-info tooltip.

additionally, some minor features are disabled while this mode is active in order to not bloat the tooltip too much.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"font_width*35, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

WinGetPos, winx, winy, width, height, ahk_id %hwnd_settings_menu_help%
newxpos := (winx + width > xScreenOffSet + poe_width) ? xScreenOffSet + poe_width - width : winx
newypos := (winy + height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - height : winy
Gui, Settings_menu_help: Show, NA x%newxpos% y%newypos%
KeyWait, LButton
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
Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-700 vertical Disabled vitemchecker_reset_highlight_bar cRed",
Gui, settings_menu: Add, Text, % "ys x+0 Center Border BackgroundTrans vitemchecker_reset_blacklist gItemchecker", % " reset undesired mods "
Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-700 vertical Disabled vitemchecker_reset_blacklist_bar cRed",

Gui, settings_menu: Font, bold underline
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"font_height*0.75, % "general options:"
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", tooltip size:
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_itemchecker_minus gItemchecker Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center wp vfSize_itemchecker_reset gItemchecker Border x+2", % "r"
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center wp vfSize_itemchecker_plus gItemchecker Border x+2", % "+"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_ID Checked"enable_itemchecker_ID, % "shift-clicking triggers item-info"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_ID_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gItemchecker venable_itemchecker_gear Checked"enable_itemchecker_gear, % "enable league-start mode"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vitemchecker_gear_help hp w-1", img\GUI\help.png
If enable_itemchecker_gear
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gItemchecker vitemchecker_reset_gear", % " reset inventory boxes "
	Gui, settings_menu: Add, Progress, % "ys x+0 hp w"font_width " BackgroundBlack range0-700 vertical Disabled vitemchecker_reset_gear_bar cRed",
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
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gLeveling_guide y+"fSize0*1.2 " venable_leveling_guide Checked"enable_leveling_guide, % "enable leveling tracker"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_help hp w-1", img\GUI\help.png
If (enable_leveling_guide = 1)
{
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "feature settings: "
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gLeveling_guide venable_omnikey_pob Checked"enable_omnikey_pob, % "pob: middle mouse-button initiates screen-capping"
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_pob_help hp w-1", img\GUI\help.png
	Gui, settings_menu: Add, Text, % "xs Section gLeveling_guide vleveling_guide_skilltree_folder Border BackgroundTrans", % " open skilltree-folder "
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_skilltree_help hp w-1", img\GUI\help.png
	
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "guide settings: "
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_help2 hp w-1", img\GUI\help.png
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
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text color:
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans vfontcolor_white cWhite gLeveling_guide Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gLeveling_guide Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gLeveling_guide Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gLeveling_guide Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gLeveling_guide Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gLeveling_guide Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text-size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_reset gLeveling_guide Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_plus gLeveling_guide Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_plus gLeveling_guide Border x+2 wp", % "+"
	
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
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_info y+"font_height " venable_map_info Checked"enable_map_info, enable the map-info panel

If enable_map_info
{
	If (enable_pixelchecks = 1) && (pixel_gamescreen_x1 != "") && (pixel_gamescreen_x1 != "ERROR")
	{
		Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_info_settings_apply y+"fSize0*1.2 " vMap_info_pixelcheck_enable Checked"Map_info_pixelcheck_enable, toggle overlay automatically
		Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_auto_trigger hp w-1", img\GUI\help.png
	}
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_info_settings_apply y+"fSize0*1.2 " venable_map_info_shiftclick Checked"enable_map_info_shiftclick, shift-clicking triggers map-info
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vmap_info_shiftclick_help hp w-1", img\GUI\help.png
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size:
		
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_minus gMap_info_settings_apply Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_reset gMap_info_settings_apply Border x+2 wp", % "r"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_plus gMap_info_settings_apply Border x+2 wp", % "+"

	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vmap_info_opac_minus gMap_info_settings_apply Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vmap_info_opac_plus gMap_info_settings_apply Border x+2 wp", % "+"

	Gui, settings_menu: Add, Checkbox, % "xs Section Center gMap_info_settings_apply vMap_info_short BackgroundTrans Checked"map_info_short " y+"fSize0*1.2, % "short mod descriptions"

	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "search for mods: "
	Gui, settings_menu: Font, % "s"fSize0 - 4
	Gui, settings_menu: Add, Edit, % "ys x+0 cBlack BackgroundTrans Limit gMap_info_customization vMap_info_search wp"
	Gui, settings_menu: Font, % "s"fSize0

	;GoSub, Map_info
}
Return

Settings_menu_map_tracker:
settings_menu_section := "map tracker"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Mapping-tracker">wiki page</a>
Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gMap_tracker y+"fSize0*1.2 " venable_map_tracker Checked"enable_map_tracker, enable mapping tracker
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vmap_tracker_help hp w-1 x+0", img\GUI\help.png

If (enable_map_tracker = 1)
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
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color (widget):
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

Settings_menu_omnikey:
settings_menu_section := "omnikey"
If (A_GuiControl = "omnikey_apply")
{
	Gui, settings_menu: Submit, NoHide
	If GetKeyState("ALT", "P") || GetKeyState("CTRL", "P") || GetKeyState("Shift", "P")
		Return
	IniWrite, %omnikey_hotkey%, ini\config.ini, Settings, omni-hotkey
	Reload
	ExitApp
}
If (A_GuiControl = "omnikey_restart")
{
	Gui, settings_menu: Submit, NoHide
	If GetKeyState("ALT", "P") || GetKeyState("CTRL", "P") || GetKeyState("Shift", "P")
		Return
	IniWrite, % alt_modifier, ini\config.ini, Settings, highlight-key
	IniWrite, % omnikey_hotkey2, ini\config.ini, Settings, omni-hotkey2
	Reload
	ExitApp
	Return
}

Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Omni-key">wiki page</a>
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.2, replace middle mouse-button with:
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans vOmnikey_help gSettings_menu_help hp w-1", img\GUI\help.png
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, Hotkey, % "xs Section hp BackgroundTrans vomnikey_hotkey w"width//2, %omnikey_hotkey%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border vomnikey_apply gSettings_menu_omnikey", % " apply && restart "

Gui, settings_menu: Add, Text, % "xs Section cRed BackgroundTrans", % ""
Gui, settings_menu: Add, Text, % "xs Section cRed BackgroundTrans", % ""
Gui, settings_menu: Add, Text, % "xs Section cRed BackgroundTrans", % "only for custom alt && c in-game keybinds, read: "
Gui, settings_menu: Add, Link, % "ys x+0 hp", <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Known-Issues-&-Limitations#custom-poe-keybinds-alt--c">wiki</a>

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "highlight-key:"
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys hp valt_modifier BackgroundTrans cBlack w"width//2, % alt_modifier
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "omni-key (items):"
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Hotkey, % "ys hp vomnikey_hotkey2 BackgroundTrans w"width//2, % omnikey_hotkey2
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Add, Text, % "xs Border vomnikey_restart gSettings_menu_omnikey Section BackgroundTrans", % " apply && restart "
Return

Settings_menu_screenchecks:
settings_menu_section := "screenchecks"
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Screen-checks">wiki page</a>
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "list of integrated pixel-checks: "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_help hp w-1", img\GUI\help.png
Loop, Parse, pixelchecks_list, `,, `,
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans border gScreenchecks v" A_Loopfield "_pixel_test y+"fSize0*0.6, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//4 " border gScreenchecks v" A_Loopfield "_pixel_calibrate", % " calibrate "
	If (screenchecks_%A_Loopfield%_valid = 0)
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

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.5, % "list of integrated image-checks: "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vImagecheck_help hp w-1", img\GUI\help.png
Loop, Parse, imagechecks_list_copy, `,, `,
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans border gScreenchecks v" A_Loopfield "_image_test y+"fSize0*0.6, % " test "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//4 " border gScreenchecks v" A_Loopfield "_image_calibrate", % " calibrate "
	loopfield_copy := StrReplace(A_Loopfield, "-", "_")
	loopfield_copy := StrReplace(loopfield_copy, " ", "_")
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans gScreenchecks Checked" disable_imagecheck_%loopfield_copy% " vDisable_imagecheck_" loopfield_copy, % "disable: "
	If (screenchecks_%A_Loopfield%_valid = 0)
		Gui, settings_menu: Font, cRed underline
	Else Gui, settings_menu: Font, cWhite underline
	parse_imagechecks := StrReplace(A_LoopField, "dash", "-")
	parse_imagechecks := StrReplace(parse_imagechecks, "_", " ")
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gSettings_menu_help vimagecheck_help_"A_LoopField, % parse_imagechecks
	Gui, settings_menu: Font, norm cWhite
}
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Center Border gScreenchecks vImage_folder y+"fSize0*0.6, % " open img folder "
Return

Settings_menu_stash_search:
settings_menu_section := "stash search"
new_stash_search_menu_closed := 0
Gui, settings_menu: Add, Link, % "ys hp Section xp+"spacing_settings*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/wiki/Search-strings">wiki page</a>
Gui, settings_menu: Add, Link, % "ys hp x+"font_width*3, <a href="https://poe.re/">poe regex</a>
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, list of searches currently set up:
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
Gui, settings_menu: Add, Text, % "xs Section Border gStash_search_new vStash_add BackgroundTrans y+"fSize0*1.2, % " add string "
Return

Settings_menuGuiClose:
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
Return