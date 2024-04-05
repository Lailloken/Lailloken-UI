Init_leveltracker()
{
	local
	global vars, settings, db, Json

	settings.features.leveltracker := LLK_IniRead("ini\config.ini", "Features", "enable leveling guide", 0)

	If !FileExist("ini\leveling tracker.ini")
	{
		IniWrite, % "", ini\leveling tracker.ini, settings
		IniWrite, % "", ini\leveling tracker.ini, UI
	}

	settings.leveltracker := {}
	settings.leveltracker.profile := LLK_IniRead("ini\leveling tracker.ini", "Settings", "profile")

	If !InStr(LLK_IniRead("ini\leveling tracker.ini"), "current run" settings.leveltracker.profile)
	{
		IniWrite, % "", ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, name
		IniWrite, 0, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
		Loop 10
			IniWrite, % "", ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, act %A_Index%
	}

	If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile)
		FileCreateDir, % "img\GUI\skill-tree" settings.leveltracker.profile

	settings.leveltracker.timer := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable timer", 0)
	settings.leveltracker.pausetimer := LLK_IniRead("ini\leveling tracker.ini", "Settings", "hideout pause", 0)
	settings.leveltracker.fade := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable fading", 0)
	settings.leveltracker.fadetime := LLK_IniRead("ini\leveling tracker.ini", "Settings", "fade-time", 5000)
	settings.leveltracker.fade_hover := LLK_IniRead("ini\leveling tracker.ini", "Settings", "show on hover", 1)
	settings.leveltracker.geartracker := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable geartracker", 0)
	settings.leveltracker.expbar := LLK_IniRead("ini\leveling tracker.ini", "Settings", "exp-bar offset", 0)
	settings.leveltracker.layouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable zone-layout overlay", 0)
	settings.leveltracker.hints := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable additional hints", 1)
	settings.leveltracker.fSize := LLK_IniRead("ini\leveling tracker.ini", "Settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.leveltracker.fSize, font_height, font_width)
	settings.leveltracker.fHeight := font_height, settings.leveltracker.fWidth := font_width
	settings.leveltracker.pob := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable pob-screencap", 0)
	settings.leveltracker.trans := LLK_IniRead("ini\leveling tracker.ini", "Settings", "transparency", 5), settings.leveltracker.trans := (settings.leveltracker.trans > 5) ? 5 : settings.leveltracker.trans
	settings.leveltracker.xCoord := LLK_IniRead("ini\leveling tracker.ini", "Settings", "x-coordinate")
	settings.leveltracker.yCoord := LLK_IniRead("ini\leveling tracker.ini", "Settings", "y-coordinate")
	settings.leveltracker.xLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts x")
	settings.leveltracker.yLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts y")
	settings.leveltracker.sLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts size", 8)
	settings.leveltracker.aLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts arrangement", "vertical")

	vars.leveltracker.gearfilter := 1, vars.leveltracker.gear := []
	vars.leveltracker.character := LLK_IniRead("ini\leveling tracker.ini", "Settings", "character")
	iniread := LLK_IniRead("ini\leveling tracker.ini", "gear" settings.leveltracker.profile) "`n" LLK_IniRead("ini\leveling tracker.ini", "gems" settings.leveltracker.profile)
	StringLower, iniread, iniread
	Sort, iniread, D`n N P2
	Loop, Parse, iniread, `n
	{
		If Blank(A_LoopField) || !Blank(LLK_HasVal(vars.leveltracker.gear, SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)))
			Continue
		vars.leveltracker.gear.Push(SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1))
	}
	If settings.leveltracker.geartracker
		GeartrackerGUI("refresh")

	;settings.leveltracker.gear.x := LLK_IniRead("ini\leveling tracker.ini", "UI", "indicator xcoord", 0.3* vars.client.w)
	;settings.leveltracker.gear.y := LLK_IniRead("ini\leveling tracker.ini", "UI", "indicator ycoord", 0.91* vars.client.h)

	If !IsObject(vars.leveltracker.guide)
		vars.leveltracker.guide := {}

	vars.leveltracker.timer := {"name": LLK_IniRead("ini\leveling tracker.ini", "current run" settings.leveltracker.profile, "name"), "current_split": LLK_IniRead("ini\leveling tracker.ini", "current run" settings.leveltracker.profile, "time", 0), "current_act": 1, "total_time": 0, "pause": -1}
	Loop 11
	{
		iniread := LLK_IniRead("ini\leveling tracker.ini", "current run" settings.leveltracker.profile, "act " A_Index)
		vars.leveltracker.timer.current_act := A_Index
		If !iniread
			Break
		vars.leveltracker.timer.total_time += iniread
	}
	vars.leveltracker.skilltree := {"active": LLK_IniRead("ini\leveling tracker.ini", "Settings", "last skilltree-image" settings.leveltracker.profile, "00")}

	lang := settings.general.lang_client, db.leveltracker := {"areas": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] areas.json") ? lang : "english") "\[leveltracker] areas.json")), "gems": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] areas.json") ? lang : "english") "\[leveltracker] gems.json")), "quests": Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\[leveltracker] quests.json") ? lang : "english") "\[leveltracker] quests.json")), "regex": Json.Load(LLK_FileRead("data\global\[leveltracker] gem regex.json"))}
}

Geartracker(mode := "")
{
	local
	global vars, settings

	If (mode = "toggle")
	{
		GeartrackerGUI("toggle")
		WinActivate, ahk_group poe_window
		Return
	}
	check := LLK_HasVal(vars.hwnd.geartracker, mode), control := SubStr(check, InStr(check, "_") + 1)

	If (check = "filter")
		vars.leveltracker.gearfilter := LLK_ControlGet(mode)
	Else If (check = "clear")
	{
		If LLK_Progress(vars.hwnd.geartracker.delbar_clear, "LButton")
		{
			Loop, % vars.leveltracker.gear_ready
			{
				IniDelete, ini\leveling tracker.ini, % "gear" settings.leveltracker.profile, % vars.leveltracker.gear[A_Index]
				IniDelete, ini\leveling tracker.ini, % "gems" settings.leveltracker.profile, % vars.leveltracker.gear[A_Index]
				vars.leveltracker.gear.Delete(A_Index)
			}
		}
		Else Return
	}
	Else If InStr(check, "select_")
	{
		If (vars.system.click = 1)
		{
			KeyWait, LButton
			regex := SubStr(check, (InStr(check, ":") ? InStr(check, ": ") + 2 : InStr(check, " ") + 1)), regex := (StrLen(regex) > 48) ? SubStr(regex, 1, 48) : regex, Clipboard := """" regex """"
			WinActivate, ahk_group poe_window
			WinWaitActive, ahk_group poe_window
			SendInput, ^{f}
			Sleep 100
			SendInput, ^{v}{Enter}
			Return
		}
		Else If (vars.system.click = 2) && LLK_Progress(vars.hwnd.geartracker["delbar_"control], "RButton")
		{
			IniDelete, ini\leveling tracker.ini, % "gear" settings.leveltracker.profile, % control
			IniDelete, ini\leveling tracker.ini, % "gems" settings.leveltracker.profile, % control
			vars.leveltracker.gear.RemoveAt(LLK_HasVal(vars.leveltracker.gear, control))
		}
		Else Return
	}
	Else LLK_ToolTip("no action")
	GeartrackerGUI()
}

GeartrackerAdd()
{
	local
	global vars, settings

	item := vars.omnikey.item
	If (item.rarity != LangTrans("items_unique")) && !InStr(item.name, "Flask", 1)
		class := SubStr(vars.omnikey.item.class_copy, InStr(vars.omnikey.item.class_copy, " ",,, LLK_InStrCount(vars.omnikey.item.class_copy, " ")) + 1), class := (settings.general.lang_client = "english") ? (InStr("boots,gloves", class) ? class : SubStr(class, 1, -1)) : class, class := LLK_StringCase(class)

	If !vars.omnikey.item.lvl_req
		error := [LangTrans("lvltracker_gearadd", 4), 2, "red"]
	Else If (vars.omnikey.item.lvl_req < vars.log.level)
		error := [LangTrans("lvltracker_gearadd", 3), 2, "yellow"]
	Else If !Blank(LLK_HasVal(vars.leveltracker.gear, "("vars.omnikey.item.lvl_req ") " (class ? class ": " : "") vars.omnikey.item.name_copy))
		error := [LangTrans("lvltracker_gearadd", 2), 1.5, "red"]

	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3)
		Return
	}
	Else LLK_ToolTip(LangTrans("lvltracker_gearadd"), 1,,,, "lime")
	vars.leveltracker.gear.Push(LLK_StringCase("("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name_copy))
	vars.leveltracker.gear := LLK_ArraySort(vars.leveltracker.gear)
	IniWrite, 1, ini\leveling tracker.ini, % "gear" settings.leveltracker.profile, % "("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name_copy
	GeartrackerGUI()
}

GeartrackerGUI(mode := "")
{
	local
	global vars, settings
	static toggle := 0

	toggle := !toggle, GUI_name := "geartracker" toggle
	If (mode = "toggle") && WinExist("ahk_id "vars.hwnd.geartracker.main)
		LLK_Overlay(vars.hwnd.geartracker.main, "destroy")
	Else
	{
		Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDgeartracker", geartracker
		Gui, %GUI_name%: Color, Black
		Gui, %GUI_name%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/8
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize " cWhite", % vars.system.font
		hwnd_old := vars.hwnd.geartracker.main, vars.hwnd.geartracker := {"main": geartracker}

		Gui, %GUI_name%: Add, Text, % "Section"(Blank(settings.general.character) || !vars.log.level ? " cRed" : ""), % LangTrans("lvltracker_gearlist") " " (Blank(settings.general.character) ? "unknown" : settings.general.character) " (" vars.log.level ")"
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize - 2
		Gui, %GUI_name%: Add, Pic, % "ys hp w-1 HWNDhwnd0", img\GUI\help.png
		Gui, %GUI_name%: Add, Checkbox, % "xs Section gGeartracker HWNDhwnd checked"vars.leveltracker.gearfilter, % LangTrans("lvltracker_gear5levels")
		vars.hwnd.geartracker.filter := hwnd, vars.hwnd.help_tooltips["geartracker_about"] := hwnd0
		ControlGetPos, x0, y0, w0, h0,, % "ahk_id "hwnd
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize

		;If !Blank(settings.general.character)
			For index, item in vars.leveltracker.gear
			{
				If vars.leveltracker.gearfilter && (SubStr(item, 2, 2) > vars.log.level + 5)
					Continue
				color := (SubStr(item, 2, 2) <= vars.log.level) ? " cLime" : ""
				count += color ? 1 : 0
				If (y + h >= vars.client.h*0.85)
				{
					If !ellipsis
					{
						Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans", % "[...]"
						ellipsis := 1
					}
					Continue
				}
				Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans gGeartracker HWNDhwnd Section"(A_Index = 1 ? " y+"settings.leveltracker.fHeight*0.25 : "") color, % (StrLen(item) > 35) ? SubStr(item, 1, 35) : item
				vars.hwnd.geartracker["select_"item] := hwnd
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack cRed Disabled HWNDhwnd range0-500", 0
				vars.hwnd.geartracker["delbar_"item] := hwnd
				If (StrLen(item) > 35)
					Gui, %GUI_name%: Add, Text, % "ys BackgroundTrans" color, % "[...]"
				ControlGetPos, x, y, w, h,, % "ahk_id "hwnd
			}
		count := !count ? 0 : count, vars.leveltracker.gear_ready := count
		If count
		{
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize - 2
			Gui, %GUI_name%: Add, Text, % "x"x0 + w0 " y"y0 " h"h0 " Border BackgroundTrans gGeartracker HWNDhwnd cLime", % " clear "
			vars.hwnd.geartracker["clear"] := hwnd
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack cRed Disabled HWNDhwnd range0-500", 0
			vars.hwnd.geartracker["delbar_clear"] := hwnd
		}
		Gui, %GUI_name%: Show, % "NA x10000 y10000"
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.geartracker.main
		Gui, %GUI_name%: Show, % (mode = "refresh" ? "Hide" : "NA") " x" vars.monitor.x + vars.client.xc - w//2 " y" vars.monitor.y + vars.client.yc - h / 2
		LLK_Overlay(vars.hwnd.geartracker.main, (mode = "refresh") ? "hide" : "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	}
}

Leveltracker(cHWND := "", hotkey := "")
{
	local
	global vars, settings, Json, db

	If vars.leveltracker.fast ;block any input during fast-forwarding
		Return
	check := LLK_HasVal(vars.hwnd.leveltracker, cHWND)
	If InStr(check, "dummy")
		Return

	If InStr("+-", cHWND) || check || InStr(A_Gui, "settings_menu")
	{
		yTooltip := vars.leveltracker.coords.y1 - settings.general.fHeight + 1, yTooltip := (yTooltip < vars.monitor.y) ? vars.leveltracker.coords.y2 - 1 : yTooltip
		guide := vars.leveltracker.guide ;short-cut variable
		If (hotkey = 1 && check = "+") || (cHWND = "+") ;clicking the forward button
		{
			If (guide.group1[guide.group1.Count()] = guide.import[guide.import.Count()]) ;end-of-guide reached, can't go further
			{
				;Gui, % GuiName(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(LangTrans("lvltracker_endreached"),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "yellow",,,, 1)
				KeyWait, LButton
				Return
			}
			start := A_TickCount, loop := 1
			While GetKeyState("LButton", "P") && (cHWND = vars.hwnd.leveltracker["+"]) && (loop = 1)
				If (A_TickCount >= start + 1000)
					loop := 1000, vars.leveltracker.fast := 1, area_check := !db.leveltracker.areas.HasKey(vars.log.areaID) || InStr(vars.log.areaID, "labyrinth") ? 0 : 1

			If (loop = 1000) && area_check ;check the remainder of the guide to see if there's a step involving the current location
			{
				area_check := 0
				For key, val in vars.leveltracker.guide.text_raw ;text_raw is the imported guide minus already completed steps
				{
					Loop, Parse, val, %A_Space%
						If InStr(A_LoopField, "areaid")
							target_area := StrReplace(A_LoopField, "areaid")
					If (target_area = vars.log.areaID)
					{
						area_check := 1
						Break
					}
				}
			}

			If (loop = 1000) && !area_check
			{
				;Gui, % GuiName(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(LangTrans("lvltracker_fastforwarderror"), 3, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "red",,,, 1)
				vars.leveltracker.fast := 0
				KeyWait, LButton
				Return
			}
			Else If (loop = 1000)
				Gui, % GuiName(vars.hwnd.leveltracker.controls1) ": Color", Red
			Loop, % loop
			{
				For step_index, step in guide.group1
				{
					guide.progress.Push(step)
					IniWrite, % step, % "ini\leveling guide" settings.leveltracker.profile ".ini", progress, % "step_" guide.progress.MaxIndex()
				}
				LeveltrackerProgress(1)
				If !Blank(LLK_HasVal(guide.group1, "an_end_to_hunger", 1)) || (guide.target_area = vars.log.areaID)
					Break
			}
			vars.leveltracker.fast := 0, vars.leveltracker.last_manual := A_TickCount
			If (loop = 1000) ;band-aid fix to override the grace-period from manually switching guide pages
				vars.leveltracker.last_manual := A_TickCount - 30000
			KeyWait, LButton
			Return
		}
		If (hotkey = 1 && check = "-") || (cHWND = "-") ;clicking the backward button
		{
			If !guide.progress.Count() ;guide-start reached, can't to further
			{
				;Gui, % GuiName(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(LangTrans("lvltracker_endreached"),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "yellow",,,, 1)
				KeyWait, LButton
				Return
			}
			start := A_TickCount, loop := 0
			While GetKeyState("LButton", "P") && (cHWND = vars.hwnd.leveltracker["-"]) && !loop
				If (A_TickCount >= start + 1000)
					loop := 1

			If loop
			{
				LeveltrackerProgressReset()
				KeyWait, LButton
				Return
			}

			Loop, % vars.leveltracker.guide.group0.Count()
			{
				IniDelete, % "ini\leveling guide" settings.leveltracker.profile ".ini", progress, % "step_" guide.progress.MaxIndex()
				vars.leveltracker.guide.progress.Pop()
			}
			LeveltrackerProgress()
			vars.leveltracker.last_manual := A_TickCount
			KeyWait, LButton
			Return
		}
		If (check = "drag")
		{
			If (hotkey = 2)
				settings.leveltracker.xCoord := "", settings.leveltracker.yCoord := "", write := 1
			start := A_TickCount
			While (hotkey = 1) && GetKEyState("LButton", "P")
				If (A_TickCount >= start + 500)
				{
					If !dummy_gui
					{
						Gui, dummy_gui: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20
						Gui, dummy_gui: Margin, 0, 0
						Gui, dummy_gui: Color, Black
						WinSet, Transparent, % 100 + settings.leveltracker.trans * 30
						Gui, dummy_gui: Add, Text, % "Border w" vars.leveltracker.coords.w + 2 " h" vars.leveltracker.coords.h - 1
						Gui, dummy_gui: Show, % "NA x10000 y10000"
						vars.leveltracker.drag := dummy_gui := 1, vars.leveltracker.fade := 0
					}
					LLK_Drag(vars.leveltracker.coords.w + 2, vars.leveltracker.coords.h - 1, xDummy, yDummy, 0, "dummy_gui", 1)
					Sleep 1
				}
			vars.leveltracker.drag := 0
			If !Blank(xDummy) || !Blank(yDummy)
			{
				settings.leveltracker.xCoord := xDummy - (xDummy >= vars.monitor.w / 2 ? 1 : 0), settings.leveltracker.yCoord := yDummy + (yDummy >= vars.monitor.h / 2 ? 2 : 0), write := 1
				Gui, dummy_gui: Destroy
			}
			If write
			{
				IniWrite, % settings.leveltracker.xCoord, ini\leveling tracker.ini, Settings, x-coordinate
				IniWrite, % settings.leveltracker.yCoord, ini\leveling tracker.ini, Settings, y-coordinate
			}
		}
		If (check = "reset_bar")
		{
			If (hotkey = 1)
				LeveltrackerTimer("pause")
			Else LeveltrackerTimer("reset")
		}
		Else LeveltrackerProgress(1)
	}

	If !InStr(vars.hwnd.LLK_panel.leveltracker ", " vars.hwnd.LLK_panel.leveltracker_text, cHWND) || InStr(A_Gui, "settings_menu")
		Return

	If (hotkey = 2)
	{
		If settings.leveltracker.geartracker
			Geartracker("toggle")
		Return
	}
	If settings.leveltracker.geartracker && Blank(vars.leveltracker.gear_ready)
		GeartrackerGUI("refresh")

	If !vars.hwnd.leveltracker.main
	{
		If !IsObject(vars.leveltracker.guide.import)
			LeveltrackerLoad()
		If !vars.leveltracker.guide.import.Count()
		{
			LLK_ToolTip(LangTrans("lvltracker_guidemissing"), 2,,,, "red")
			vars.leveltracker.Delete("guide")
			Return
		}
		LeveltrackerProgress(1)
	}
	Else If !WinExist("ahk_id " vars.hwnd.leveltracker.main) && !vars.leveltracker.toggle
		LeveltrackerProgress(1)
	Else
	{
		LeveltrackerToggle("hide"), vars.leveltracker.toggle := 0
		GuiControl,, % vars.hwnd.LLK_panel.leveltracker, img\GUI\leveltracker0.png
	}
	;WinActivate, ahk_group poe_window
}

LeveltrackerExperience(arealevel := "", safe := 0, feature := "")
{
	local
	global vars, settings

	If (vars.log.level = 0)
		Return

	arealevel := !arealevel ? vars.log.arealevel : arealevel, exp_penalty := {95: 1.069518717, 96: 1.129943503, 97: 1.2300123, 98: 1.393728223, 99: 1.666666667}
	If (vars.log.level > 94)
		exp_penalty := (1/(1 + 0.1 * (vars.log.level - 94))) * (1/exp_penalty[vars.log.level])
	Else exp_penalty := 1

	If (arealevel > 70)
		arealevel := (-0.03) * (arealevel**2) + (5.17 * arealevel) - 144.9
	If (feature != "horizon") && (InStr(vars.log.areaID, "_town") || (SubStr(vars.log.areaID, 1, 7) = "hideout"))
		arealevel := vars.log.level, hideout := 1

	safezone := Floor(3 + (vars.log.level/16)), safezone_min := vars.log.level - safezone, safezone_max := vars.log.level + safezone
	safezone_diff := LLK_IsBetween(arealevel, safezone_min, safezone_max) ? 0 : arealevel - (vars.log.level + safezone * (arealevel > vars.log.level ? 1 : -1))
	;safe := (Abs(safezone_diff) > 9) ? 0 : safe
	effective_difference := Max(Abs(vars.log.level - arealevel) - safezone, 0), effective_difference := effective_difference**2.5
	exp_multi := (vars.log.level + 5) / (vars.log.level + 5 + effective_difference), exp_multi := exp_multi**1.5
	exp_multi := Max(exp_multi * exp_penalty, 0.01)
	text := (safe || exp_multi = 1 ? Round(exp_multi*100) : Format("{:0.1f}", exp_multi * 100)) "%", text := hideout ? "100%" : text
	If safe
		text .= safezone_diff ? " (" (safezone_diff > 0 ? "+" : "") safezone_diff ")" : !safezone_diff ? Max(safezone_min, 1) " | " arealevel " | " safezone_max : ""
	Return text
}

LeveltrackerFade()
{
	local
	global vars, settings

	If !settings.leveltracker.fade || vars.leveltracker.drag || !vars.hwnd.leveltracker.main || (vars.leveltracker.last > A_TickCount) || !LLK_Overlay(vars.hwnd.leveltracker.main, "check") || !vars.leveltracker.toggle
		Return
	If (vars.leveltracker.last + settings.leveltracker.fadetime <= A_TickCount) && WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& !(settings.leveltracker.fade_hover && LLK_IsBetween(vars.general.xMouse, vars.leveltracker.coords.x1, vars.leveltracker.coords.x2) && LLK_IsBetween(vars.general.yMouse, vars.leveltracker.coords.y1, vars.leveltracker.coords.y2))
	&& !vars.leveltracker.overlays && !InStr(vars.log.areaID, "_town")
		vars.leveltracker.fade := 1, LeveltrackerToggle("hide")
	Else If vars.hwnd.leveltracker.main && !WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& ((settings.leveltracker.fade_hover && LLK_IsBetween(vars.general.xMouse, vars.leveltracker.coords.x1, vars.leveltracker.coords.x2) && LLK_IsBetween(vars.general.yMouse, vars.leveltracker.coords.y1, vars.leveltracker.coords.y2)
	&& !GetKeyState(settings.hotkeys.movekey, "P")) || vars.leveltracker.overlays || InStr(vars.log.areaID, "_town"))
		vars.leveltracker.fade := 0, LeveltrackerToggle("show")
}

LeveltrackerHints()
{
	local
	global vars, settings

	Loop, Files, img\GUI\leveling tracker\hints\*.jpg
		If !Blank(LLK_HasVal(vars.leveltracker.guide.group1, StrReplace(A_LoopFileName, ".jpg"), 1))
			valid := 1

	If !settings.leveltracker.hints || !valid
		Return
	Gui, leveltracker_hints: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDleveltracker_hints
	Gui, leveltracker_hints: Color, Black
	Gui, leveltracker_hints: Margin, 0, 0
	Gui, leveltracker_hints: Font, % "s"settings.general.fSize - 2 " cWhite", % vars.system.font

	Loop, Files, img\GUI\leveling tracker\hints\*.jpg
		If !Blank(LLK_HasVal(vars.leveltracker.guide.group1, StrReplace(A_LoopFileName, ".jpg"), 1))
		{
			Gui, leveltracker_hints: Add, Pic, % "w"vars.leveltracker.coords.w " h-1", % A_LoopFileLongPath
			added := 1
			Break
		}

	If added
	{
		Gui, leveltracker_hints: Show, NA x10000 y10000
		WinGetPos,,, w, h, ahk_id %leveltracker_hints%
		yPos := (Blank(settings.leveltracker.yCoord) || settings.leveltracker.yCoord >= vars.monitor.h / 2) ? vars.leveltracker.coords.y1 - h + 1 : vars.leveltracker.coords.y2 - 1
		Gui, leveltracker_hints: Show, % "NA x" vars.monitor.x + vars.leveltracker.coords.x1 " y" yPos
	}
	KeyWait, % settings.hotkeys.tab
	Gui, leveltracker_hints: Destroy
}

LeveltrackerImport(profile := "")
{
	local
	global vars, settings, Json, db

	KeyWait, LButton
	If (SubStr(Clipboard, 1, 2) != "[{") || !InStr(Clipboard, """enter""")
	{
		If (SubStr(Clipboard, 1, 2) = "[{") && !InStr(Clipboard, """enter""")
			LLK_ToolTip(LangTrans("lvltracker_importerror"), 2,,,, "red")
		Else LLK_ToolTip(LangTrans("lvltracker_importerror", 2), 1.5,,,, "red")
		Return
	}

	import := Json.Load(Clipboard), areas := db.leveltracker.areas, gems := db.leveltracker.gems, quests := db.leveltracker.quests

	For act_index, act in import ;parse all acts
	{
		For step_index, step in act.steps ;parse steps in nth act
		{
			step_text := ""
			If (step.type = "fragment_step")
			{
				For part_index, part in step.parts ;parse the parts of the step
				{
					If !IsObject(part)
					{
						If (SubStr(part, -3) = "get ")
							text := StrReplace(part, "get ", "activate the ")
						;Else If InStr(part, "take") && InStr(step_text, "kill") ;omit quest-items related to killing bosses
						;	text := ""
						Else text := InStr(part, " ➞ ") ? StrReplace(part, " ➞", ", enter") : StrReplace(part, "➞", "enter")
						step_text .= text
					}
					Else
					{
						value := part.value, quest := part.questID
						Switch part.type
						{
							Case "enter":
								step_text .= "areaID" part.areaId . (InStr(part.AreaId, "_town") ? " (img:town) " : " ")
							Case "kill":
								value := InStr(value, ",") ? SubStr(part.value, 1, InStr(part.value, ",") - 1) : StrReplace(value, "alira darktongue", "alira") ;trim boss names
								step_text .= StrReplace(value, " ", "_") " "
							Case "quest":
								npc := quests[quest]["reward_offers"][quest]["quest_npc"]
								npc := (npc = "lady dialla") ? "dialla" : (npc = "captain fairgraves") ? "fairgraves" : (npc = "commander kirac") ? "kirac" : InStr(npc, " ") ? SubStr(npc, 1, InStr(npc, " ") - 1) : npc
								step_text := npc ? StrReplace(step_text, "hand in ", npc ": ") "<" StrReplace(quests[quest].name, " ", "_") "> " : step_text "<" StrReplace(quests[quest].name, " ", "_") "> "
							Case "quest_text":
								value := " (quest:" StrReplace(value, " ", "_") ") "
								step_text .= value ;!InStr(step_text, "kill") ? value : "" ;omit quest-items related to killing bosses
							Case "waypoint_get":
								step_text .= "(img:waypoint) "
							Case "waypoint_use":
								step_text .= "(img:waypoint) to areaID" part.dstAreaId . (InStr(part.dstAreaId, "_town") ? " (img:town) " : "")
							Case "waypoint":
								step_text .= InStr(step_text, "broken ") ? "(img:waypoint) " : "the (img:waypoint) " . (InStr(step_text, "2 pillars") ? "`n" : "")
							Case "logout":
								step_text .= "relog, enter areaID" part.areaId . (InStr(part.AreaId, "_town") ? " (img:town) " : "")
							Case "portal_use":
								step_text .= "(img:portal) to areaID" part.dstAreaId
							Case "portal_set":
								step_text .= "(img:portal) "
							Case "trial":
								step_text .= "the (img:lab) trial"
							Case "arena":
								step_text .= "(img:arena) arena:"StrReplace(value, " ", "_") " " ;StrReplace(value, " ", "_") " "
							Case "area":
								step_text .= "areaID" part.areaId " "
							Case "dir":
								step_text .= "(img:"part.dirIndex ") " (!InStr(step_text, "follow") && !InStr(step_text, "search") ? "," : "")
								;step_text .= !InStr(step_text, "follow") && !InStr(step_text, "search") ? "(img:"part.dirIndex ") ," : "(img:"part.dirIndex ") "
							Case "crafting":
								step_text .= "(img:craft) "
							Case "generic":
								step_text .= value
							Case "ascend":
								step_text .= "complete the (img:lab) " part.version "_lab"
							Case "reward_vendor":
								step_text .= "buy item: " StrReplace(part.item, " ", "_")
							Case "reward_quest":
								step_text .= "take reward: " StrReplace(part.item, " ", "_")
							Default:
								If settings.general.dev
									MsgBox, % "unknown type: " part.type
								Continue 2
						}
					}
				}
			}
			If (step.type = "gem_step")
			{
				gemID := step.requiredGem.id
				If !gems[gemID].name
					continue

				attr := (gems[gemID].primary_attribute = "none") ? "none" : SubStr(gems[gemID].primary_attribute, 1, 3), type := InStr(gems[gemID].name, "support") || InStr(gems[gemID].name, "arcanist brand") ? "supp" : "skill"
				If (attr = "none")
					build_gems_none .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
				Else build_gems_%type%_%attr% .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","

				color := (attr = "str") ? "D81C1C" : (attr = "dex") ? "00BF40" : (attr = "int") ? "0077FF" : "White"
				step_text .= (step.rewardType = "vendor" ? "buy gem: " : "take reward: ") . (color ? "(color:"color ")" : "") StrReplace(gems[gemID].name, " ", "_")

				If step.requiredGem.note
					gem_notes .= gems[gemID].name "=" step.requiredGem.note "`n"
			}
			If (SubStr(step_text, 0) = ",")
				step_text := SubStr(step_text, 1, -1)
			If (step_text = "talk to lady dialla") && (act_index = 3)
				Continue
			guide_text .= StrReplace(step_text, ",,", ",") "`n"

			For ss_index, ss_array in step.subSteps
			{
				ss_text := "(hint)_______"
				For ss_part_index, ss_parts in ss_array.parts
				{
					If !IsObject(ss_parts)
					{
						text := (SubStr(ss_parts, 1, 1) = " ") ? SubStr(ss_parts, 2) : ss_parts ;, text := (SubStr(text, 0) = " ") ? SubStr(text, 1, -1) : text
						ss_text .= ((ss_text != "(hint)") ? "" : "_______") StrReplace(text, " ", "_")
					}
					Else
					{
						Switch ss_parts.type
						{
							Case "dir":
								ss_text .= " (img:"ss_parts.dirIndex ") "
							Case "waypoint":
								ss_text .= (InStr(ss_text, "broken") ? "" : "the_") " (img:waypoint) "
							Case "quest_text":
								ss_text .= " (quest:" StrReplace(ss_parts.value, " ", "_") ") "
							Case "generic":
								ss_text .= """" ss_parts.value """ "
							Default:
								If settings.general.dev
									MsgBox, % "unknown type: " ss_parts.type
						}
					}
				}
				If (SubStr(ss_text, 0) = ",")
					ss_text := SubStr(ss_text, 1, -1)
				guide_text .= StrReplace(ss_text, ",,", ",") "`n"
			}
		}
	}

	While (SubStr(gem_notes, 0) = "`n")
		gem_notes := SubStr(gem_notes, 1, -1)
	IniDelete, ini\leveling tracker.ini, Gem notes%profile%
	If gem_notes
	{
		StringLower, gem_notes, gem_notes
		gem_notes := StrReplace(gem_notes, "&", "&&")
		IniWrite, % gem_notes, ini\leveling tracker.ini, Gem notes%profile%
	}
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int build_gems_none ;create single gem-string for gear tracker feature

	IniDelete, ini\leveling tracker.ini, Gems%profile%
	IniDelete, ini\search-strings.ini, 00-exile leveling gems%profile%
	IniDelete, ini\search-strings.ini, searches, hideout lilly
	vars.searchstrings["hideout lilly"].enable := 0

	If build_gems_all
	{
		Sort, build_gems_all, D`, P2 N
		Sort, build_gems_skill_str, D`, P2 N
		Sort, build_gems_supp_str, D`, P2 N
		Sort, build_gems_skill_dex, D`, P2 N
		Sort, build_gems_supp_dex, D`, P2 N
		Sort, build_gems_skill_int, D`, P2 N
		Sort, build_gems_supp_int, D`, P2 N
		Sort, build_gems_none, D`, P2 N

		build_gems_all := StrReplace(build_gems_all, ")", ") gem: "), build_gems_all := StrReplace(build_gems_all, " support", ""), build_gems_all := StrReplace(build_gems_all, ",", "=1`n")
		IniWrite, % SubStr(build_gems_all, 1, -1), ini\leveling tracker.ini, Gems%profile% ;save gems for gear tracker feature
	}

	parse := "skill_str,supp_str,skill_dex,supp_dex,skill_int,supp_int,none"

	search_string_skill_str := ""
	search_string_supp_str := ""
	search_string_skill_dex := ""
	search_string_supp_dex := ""
	search_string_skill_int := ""
	search_string_supp_int := ""
	search_string_none := ""
	search_string_all := ""

	Loop, Parse, parse, `,, `, ;create advanced search-string
	{
		loop := A_Loopfield
		parse_string := ""
		If (build_gems_%A_Loopfield% = "")
			continue
		Loop, Parse, build_gems_%A_Loopfield%, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse_gem := SubStr(A_Loopfield, 5), gem_regex := db.leveltracker.regex[parse_gem].1
			If !gem_regex
				gem_regex := parse_gem
			gem_regex := StrReplace(gem_regex, " ", ".")

			If (StrLen(parse_string . gem_regex) <= 46)
				parse_string .= gem_regex "|"
			Else
			{
				search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ")$;"
				parse_string := gem_regex "|"
			}
		}
		search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ")$"
	}

	Loop, Parse, parse, `,, `,
	{
		If (search_string_%A_Loopfield% != "")
			search_string_all .= search_string_%A_Loopfield% ";"
	}

	If search_string_all
	{
		search_string_all := SubStr(search_string_all, 1, -1)
		IniWrite, 1, ini\search-strings.ini, searches, hideout lilly
		IniWrite, % """" StrReplace(search_string_all, ";", " " ";`;`;" " ") """", ini\search-strings.ini, hideout lilly, 00-exile leveling gems%profile% ;escaped semi-colons to prevent VScode from list this line as a module
	}
	Init_searchstrings()

	guide_text := StrReplace(guide_text, "&", "&&"), guide_text := StrReplace(guide_text, "`nenter areaid1_3_1 `n", ", enter areaid1_3_1 `n")
	guide_text := StrReplace(guide_text, "remaining floors will have the exit diagonally across from the entrance", "remaining exits are diagonally opposite to the entrances")
	guide_text := StrReplace(guide_text, "follow the trail in the direction of the torch", "follow the path under the torch")
	guide_text := StrReplace(guide_text, "find and kill doedre_darktongue , take  (quest:malachai's_lungs) `nfind and kill maligaro , take  (quest:malachai's_heart) `nfind and kill shavronne_of_umbra , take  (quest:malachai's_entrails) "
	, "find and kill doedre , (color:FF8111)maligaro , (color:FF8111)shavronne")
	guide_text := StrReplace(guide_text, " , search in the corners of the map", " near the map-corners"), guide_text := StrReplace(guide_text, "kill shavronne_the_returned  && reassembled_brutus", " kill shavronne_&&_brutus")
	guide_text := StrReplace(guide_text, "`nenter (img:arena) arena:caldera_of_the_king , ", ", enter (img:arena) arena:caldera_of_the_king`n")
	guide_text := StrReplace(guide_text, "`nenter areaid1_4_6_3 ", ", enter areaid1_4_6_3 "), guide_text := StrReplace(guide_text, "`nenter areaid2_6_8 ", ", enter areaid2_6_8 ")
	guide_text := StrReplace(guide_text, "trial`nactivate ", "trial , activate "), guide_text := StrReplace(guide_text, "activate the (img:craft) `nactivate the (img:waypoint)", "activate the (img:craft) , activate the (img:waypoint)")
	guide_text := StrReplace(guide_text, "sewer_outlet `n", "sewer_outlet , "), guide_text := StrReplace(guide_text, "kill lunaris  && solaris ", "kill lunaris_&&_solaris")
	guide_text := StrReplace(guide_text, "statue of the sisters", "the statue"), guide_text := StrReplace(guide_text, "farm till lvl ~62", "farm until around lvl 62") ;tilde looks crap in Fontin SmallCaps
	guide_text := StrReplace(guide_text, "head (img:7) , activate the (img:waypoint) `nactivate the (img:craft) ", "head (img:7) , activate the (img:waypoint) , activate the (img:craft) ")
	guide_text := StrReplace(guide_text, "the_black_core `ntalk to sin", "the_black_core , talk to sin")
	guide_text := StrReplace(guide_text, "enter (img:arena) arena:doedre's_despair , kill doedre `n"), guide_text := StrReplace(guide_text, "enter (img:arena) arena:maligaro's_misery , kill maligaro `n")
	guide_text := StrReplace(guide_text, "enter (img:arena) arena:shavronne's_sorrow , kill shavronne `n", "kill doedre , (color:FF8111)maligaro , (color:FF8111)shavronne`n")
	guide_text := StrReplace(guide_text, "talk to sin, enter (img:arena)", "enter (img:arena)"), guide_text := StrReplace(guide_text, "activate the (img:craft) `ntalk", "activate the (img:craft) , talk")
	StringLower, guide_text, guide_text
	IniDelete, ini\leveling guide%profile%.ini, Steps
	IniDelete, ini\leveling guide%profile%.ini, Info
	IniWrite, % guide_text, ini\leveling guide%profile%.ini, Steps

	Settings_menu("leveling tracker")
	LLK_ToolTip(LangTrans("global_success"),,,,, "Lime")
	Init_leveltracker()
	If settings.leveltracker.geartracker
		GeartrackerGUI("refresh")
	If (settings.leveltracker.profile = profile)
		LeveltrackerLoad()
	Return 1
}

LeveltrackerLoad()
{
	local
	global vars, settings

	If !IsObject(vars.leveltracker.guide)
		vars.leveltracker.guide := {}
	vars.leveltracker.guide.import := [], vars.leveltracker.guide.progress := [], vars.leveltracker.guide.gem_notes := {}
	Loop, Parse, % LLK_IniRead("ini\leveling guide" settings.leveltracker.profile ".ini", "steps"), `n
		vars.leveltracker.guide.import.Push(A_LoopField)

	Loop, Parse, % LLK_IniRead("ini\leveling guide" settings.leveltracker.profile ".ini", "progress"), `n
	{
		vars.leveltracker.guide.progress.Push(SubStr(A_LoopField, InStr(A_LoopField, "=") + 1))
		check += !InStr(A_LoopField, "=") ? 1 : 0
	}

	Loop, Parse, % LLK_IniRead("ini\leveling tracker.ini", "gem notes" settings.leveltracker.profile), `n
		vars.leveltracker.guide.gem_notes[SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)] := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)

	If check
		MsgBox, % "Old progress-data detected.`n`nThere is a high chance this data is incompatible with the current version of the tracker.`n`nYou should go to the settings-menu and reset your progress."
}

LeveltrackerScreencapMenu2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.leveltracker_screencap, cHWND), control := SubStr(check, InStr(check, "_") + 1), active := vars.leveltracker.screencap_active
	If InStr(check, "select_")
	{
		vars.leveltracker.screencap_active := control
		LeveltrackerScreencapMenu()
		Return
	}
	Else If InStr(check, "paste_")
	{
		If !LeveltrackerScreencapPaste(control)
			Return
	}
	Else If InStr(check, "snip_")
	{
		pBitmap := SnippingTool(1)
		If (pBitmap <= 0)
			Return
		vars.leveltracker.screencap_active := control
		FileDelete, % "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "].png", 100)
		Gdip_DisposeImage(pBitmap)
		;SnipGuiClose()
	}
	Else If InStr(check, "preview_")
	{
		LeveltrackerSkilltree(StrReplace(control, "-", "lab"))
		Return
	}
	Else If InStr(check, "del_")
	{
		If LLK_Progress(vars.hwnd.leveltracker_screencap["delbar_"control], "LButton")
		{
			FileDelete, % "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
			vars.leveltracker.screencap_active := (vars.leveltracker.screencap_active = control) ? "" : vars.leveltracker.screencap_active
		}
		Else Return
	}
	Else If (check = "delall")
	{
		If LLK_Progress(vars.hwnd.leveltracker_screencap.delbarall, "LButton")
		{
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\[*"
				If (SubStr(A_LoopFileName, 1, 1) = "[" && SubStr(A_LoopFileName, 4, 1) = "]" && IsNumber(SubStr(A_LoopFileName, 2, 2)))
					FileDelete, % A_LoopFilePath
			vars.leveltracker.screencap_active := !InStr(vars.leveltracker.screencap_active, "-") ? "" : vars.leveltracker.screencap_active
		}
		Else Return
	}
	Else If (check = "caption")
	{
		GuiControl, +cRed, % vars.hwnd.leveltracker_screencap.caption
		GuiControl, movedraw, % vars.hwnd.leveltracker_screencap.caption
		Return
	}
	Else If (check = "add") && !Blank(vars.leveltracker.screencap_active)
	{
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_screencap.caption
		caption := LLK_ControlGet(vars.hwnd.leveltracker_screencap.caption)
		While (SubStr(caption, 1, 1) = " ")
			caption := SubStr(caption, 2)
		While (SubStr(caption, 0) = " ")
			caption := SubStr(caption, 1, -1)
		Loop, Parse, % "\/:*?""<>|"
			If InStr(caption, A_LoopField)
			{
				LLK_ToolTip(LangTrans("global_errorname", 5) A_LoopField, 2, x, y + h,, "red")
				Return
			}
		GuiControl, +cBlack, % vars.hwnd.leveltracker_screencap.caption
		GuiControl, movedraw, % vars.hwnd.leveltracker_screencap.caption
		FileMove, % "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]*", % "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]"(Blank(caption) ? "" : " ") caption ".*", 1
	}
	Else If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_screencap.main
		While GetKeyState("LButton", "P")
			If (A_TickCount >= start + 100)
			{
				LLK_Drag(w, h, xPos, yPos, 1, A_Gui)
				Sleep 1
			}
		Return
	}
	Else LLK_ToolTip("no action")
	LeveltrackerScreencapMenu()
}

LeveltrackerScreencapMenuClose()
{
	local
	global vars, settings

	LLK_Overlay(vars.hwnd.leveltracker_screencap.main, "destroy"), vars.leveltracker.Delete("screencap_active")
	If !Blank(vars.hwnd.settings.main)
		LLK_Overlay(vars.hwnd.settings.main, "show")
	If WinExist("ahk_id "vars.hwnd.snip.main)
		SnipGuiClose()
}

LeveltrackerScreencapMenu()
{
	local
	global vars, settings
	static toggle := 0

	active := vars.leveltracker.screencap_active
	If WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main)
		WinGetPos, xPos, yPos, Width, Height, % "ahk_id "vars.hwnd.leveltracker_screencap.main
	If !Blank(vars.hwnd.settings.main)
		LLK_Overlay(vars.hwnd.settings.main, "hide")

	toggle := !toggle, GUI_name := "leveltracker_screencap" toggle
	Gui, %GUI_name%: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_screencap
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/8
	Gui, %GUI_name%: Font, % "s"settings.general.fSize - 2 " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.leveltracker_screencap.main, vars.hwnd.leveltracker_screencap := {"main": leveltracker_screencap}

	Gui, %GUI_name%: Add, Text, % "x-1 y-1 Border Hidden Center Section gLeveltrackerScreencapMenu2 HWNDhwnd", % LangTrans("lvltracker_header")
	vars.hwnd.leveltracker_screencap.winbar := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+-1 Border Hidden Center gLeveltrackerScreencapMenuClose HWNDhwnd w"settings.general.fWidth*2, % "x"
	vars.hwnd.leveltracker_screencap.winx := hwnd

	files := 0
	Loop, 99
	{
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\[0" A_Index "]*") || FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["A_Index "]*")
			files := (A_Index < 10 ? "0" : "") A_Index
	}

	Gui, %GUI_name%: Font, % "bold underline s"settings.general.fSize
	Gui, %GUI_name%: Add, Text, % "xs Section HWNDanchor x"settings.general.fWidth/2, % LangTrans("global_skilltree")
	Gui, %GUI_name%: Font, norm
	Gui, %GUI_name%: Add, Picture, % "ys hp w-1 HWNDhwnd", img\GUI\help.png
	vars.hwnd.help_tooltips["leveltracker_skilltree-cap about"] := hwnd

	Loop, % files + 1
	{
		index := (A_Index < 10) ? "0" . A_Index : A_Index, wButtons := (A_Index = active) ? 0 : wButtons
		color := (index = vars.leveltracker.screencap_active) ? " cFuchsia" : !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["index "]*") ? " cGray" : ""
		Gui, %GUI_name%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["index "]*") ? "" : " Border gLeveltrackerScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 (A_Index = files + 1 ? " cLime" : color), % index
		vars.hwnd.leveltracker_screencap["select_"index] := hwnd
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " " LangTrans("global_paste") " "
		vars.hwnd.leveltracker_screencap["paste_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " " LangTrans("global_snip") " "
		vars.hwnd.leveltracker_screencap["snip_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (A_Index = files + 1) && (A_Index != 1)
		{
			Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2 Center w"wButtons2 + settings.general.fWidth/4, % " " LangTrans("lvltracker_deleteall") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
			vars.hwnd.leveltracker_screencap.delall := hwnd0, vars.hwnd.leveltracker_screencap.delbarall := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete-all"] := hwnd
		}

		If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["index "]*")
			Continue
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " " LangTrans("global_show") " "
		vars.hwnd.leveltracker_screencap["preview_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 := LLK_ControlGetPos(hwnd, "w")
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2", % " " LangTrans("global_delete", 2) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_"index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 += LLK_ControlGetPos(hwnd, "w"), handle .= "|"
		If (active = index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %GUI_name%: Font, % "s"settings.general.fSize - 4
			Gui, %GUI_name%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltrackerScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %GUI_name%: Font, % "s"settings.general.fSize
		}
	}

	Gui, %GUI_name%: Font, bold underline
	Gui, %GUI_name%: Add, Text, % "xs Section y+"settings.general.fHeight*0.8, % LangTrans("global_ascendancy")
	Gui, %GUI_name%: Add, Picture, % "ys hp w-1 HWNDhwnd69", img\GUI\help.png
	Gui, %GUI_name%: Font, norm
	Loop 5
	{
		vars.hwnd.help_tooltips["leveltracker_skilltree-cap ascend"] := hwnd69, index := "0"A_Index, color := (active = -A_Index) ? " cFuchsia" : !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\[lab"A_Index "]*") ? " cGray" : "", wButtons := (-A_Index = active) ? 0 : wButtons
		Gui, %GUI_name%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\[lab"A_Index "]*") ? " " : " Border gLeveltrackerScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 color, % index
		vars.hwnd.leveltracker_screencap["select_-"A_Index] := hwnd, handle .= "|"
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\[lab"A_Index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " " LangTrans("global_paste") " "
		vars.hwnd.leveltracker_screencap["paste_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " " LangTrans("global_snip") " "
		vars.hwnd.leveltracker_screencap["snip_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\[lab"A_Index "]*")
			Continue
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " " LangTrans("global_show") " "
		vars.hwnd.leveltracker_screencap["preview_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2", % " " LangTrans("global_delete", 2) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_-"A_Index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (active = -A_Index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %GUI_name%: Font, % "s"settings.general.fSize - 4
			Gui, %GUI_name%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltrackerScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %GUI_name%: Font, % "s"settings.general.fSize
		}
	}
	Gui, %GUI_name%: Add, Button, % "x0 y0 wp hp "(Blank(active) ? "" : " gLeveltrackerScreencapMenu2") " Hidden Default HWNDhwnd", % ok
	vars.hwnd.leveltracker_screencap.add := hwnd
	ControlFocus,, % "ahk_id " anchor
	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_screencap.main
	ControlMove,,,, w - settings.general.fWidth*2 + 1,, % "ahk_id "vars.hwnd.leveltracker_screencap.winbar
	GuiControl, -Hidden, % vars.hwnd.leveltracker_screencap.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.leveltracker_screencap.winx
	GuiControl, -Hidden, % vars.hwnd.leveltracker_screencap.winx
	Sleep 50
	If !Blank(xPos)
		xPos := (xPos + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos, yPos := (yPos + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : yPos
	Gui, %GUI_name%: Show, % "x"(Blank(xPos) ? (A_Gui ? vars.client.x : vars.monitor.x) : xPos) " y"(Blank(xPos) ? vars.monitor.y + vars.client.yc - h//2 : yPos)
	LLK_Overlay(leveltracker_screencap, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	KeyWait, MButton
}

LeveltrackerProgress(mode := 0) ;advances the guide and redraws the overlay
{
	local
	global vars, settings, db
	static in_progress, toggle := 0

	If in_progress
		Return

	vars.leveltracker.guide.text_raw := vars.leveltracker.guide.import.Clone(), in_progress := 1, vars.leveltracker.last := A_TickCount*100 ;dummy-value to prevent Loop_main() from prematurely fading the overlay
	guide := vars.leveltracker.guide, areas := db.leveltracker.areas, timer := vars.leveltracker.timer ;short-cut variables
	vars.leveltracker.fade := mode ? 0 : vars.leveltracker.fade, vars.leveltracker.toggle := mode ? 1 : vars.leveltracker.toggle
	If (mode = 1)
		GuiControl,, % vars.hwnd.LLK_panel.leveltracker, img\GUI\leveltracker.png
	For progress_index, step in guide.progress
	{
		If !Blank(LLK_HasVal(guide.text_raw, step))
			guide.text_raw.Delete(LLK_HasVal(guide.text_raw, step))
	}

	guide.group1 := []
	For raw_index, step in guide.text_raw
	{
		guide.group1.Push(step)
		If (InStr(step, "enter") || InStr(step, "(img:waypoint) to") || (InStr(step, "sail to ") && !InStr(step, "wraeclast")) || InStr(step, "(img:portal) to"))
		&& !InStr(step, "arena:") ;&& !InStr(step, "the warden's_chambers") && !InStr(step, "sewer_outlet") && !InStr(step, "resurrection_site") && !InStr(step, "the_black_core")
		&& !(InStr(step, "enter") < InStr(step, "kill")) && !(InStr(step, "enter") < InStr(step, "activate") && !InStr(step, "airlock")) && !InStr(step, "complete the")
		{
			Loop
			{
				If InStr(guide.text_raw[raw_index + A_Index], "(hint)")
					guide.group1.Push(guide.text_raw[raw_index + A_Index])
				Else Break
			}
			Break
		}
	}
	guide.target_area := ""
	For index, val in guide.group1
		If InStr(val, "areaid")
			Loop, Parse, val, %A_Space%
				If InStr(A_LoopField, "areaid")
					guide.target_area := StrReplace(A_LoopField, "areaid")

	guide.group0 := [], steps := []
	For progress_index, step in guide.progress
	{
		If !guide.group0.Count() && InStr(step, "(hint)")
			Continue
		guide.group0.Push(step)

		If (InStr(step, "enter") || InStr(step, "(img:waypoint) to") || (InStr(step, "sail to ") && !InStr(step, "wraeclast")) || InStr(step, "(img:portal) to"))
		&& !InStr(step, "arena:") ;&& !InStr(step, "the warden's_chambers") && !InStr(step, "sewer_outlet") && !InStr(step, "resurrection site") && !InStr(step, "the black core")
		&& !(InStr(step, "enter") < InStr(step, "kill")) && !(InStr(step, "enter") < InStr(step, "activate") && !InStr(step, "airlock")) && !InStr(step, "complete the")
		{
			If (progress_index = guide.progress.MaxIndex())
				Continue
			Loop
				{
					If InStr(guide.progress[progress_index + A_Index], "(hint)")
						guide.group0.Push(guide.progress[progress_index + A_Index])
					Else Break
					If (progress_index + A_Index = guide.progress.MaxIndex())
						Break 2
				}
			guide.group0 := []
		}
	}

	If vars.leveltracker.fast ;skip redrawing the GUIs during fast-forwarding
	{
		in_progress := 0
		Return
	}

	toggle := !toggle, GUI_name_back := "leveltracker_back" toggle, GUI_name_main := "leveltracker_main" toggle
	Loop 2 ;create guide panel twice to check its width and correct it if necessary
	{
		outer := A_Index, width_comp := Floor(width / settings.leveltracker.fWidth)
		Gui, %GUI_name_back%: New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_back"
		Gui, %GUI_name_back%: Color, Black
		;Gui, %GUI_name_back%: Margin, % settings.general.fWidth * (outer = 2 && width <= settings.leveltracker.fWidth * 20 ? (19 - width_comp) / 2 : 1), 0
		WinSet, Transparent, % 100 + settings.leveltracker.trans * 30

		Gui, %GUI_name_main%: New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_main +Owner" GUI_name_back
		Gui, %GUI_name_main%: Color, Black
		Gui, %GUI_name_main%: Margin, % settings.general.fWidth  * (outer = 2 && width <= settings.leveltracker.fWidth * 24 ? Max((24 - width_comp) / 2, 1) : 1), 0
		WinSet, TransColor, Black
		Gui, %GUI_name_main%: Font, % "s"settings.leveltracker.fSize " cWhite", % vars.system.font
		If (outer = 2)
			hwnd_old := vars.hwnd.leveltracker.main, hwnd_old1 := vars.hwnd.leveltracker.background, hwnd_old2 := vars.hwnd.leveltracker.controls2, hwnd_old3 := vars.hwnd.leveltracker.controls1, vars.hwnd.leveltracker := {"background": leveltracker_back}, vars.hwnd.leveltracker.main := leveltracker_main

		guide.gems := [], guide.items := []
		For index_raw, step in guide.group1
		{
			If InStr(step, "(hint)") && !settings.leveltracker.hints
				Continue

			style := "Section xs", line := step, kill := 0, text_parts := []
			Loop, Parse, step, %A_Space%
			{
				If !A_LoopField || (A_Index = 1 && A_LoopField = ",")
					Continue
				text_parts.Push(A_LoopField) ;push parts into an array so the next and previous parts can be checked/predicted
			}

			If (InStr(step, "buy gem:") || InStr(step, "buy item:")) && !guide.gems.Count() && !guide.items.Count()
			{
				add := SubStr(step, InStr(step, ":") + 2), add := InStr(add, "(") ? SubStr(add, InStr(add, ")") + 1) : add, add := StrReplace(add, "_", " ")
				guide[InStr(step, "buy item:") ? "items" : "gems"].Push(add)
				Gui, %GUI_name_main%: Add, Text, % style, % "buy " (LLK_HasVal(guide.group1, "buy item", 1) ? "items" : "gems") " (highlight: hold omni-key)"
				Continue
			}
			Else If (InStr(step, "buy gem:") || InStr(step, "buy item:")) && (guide.gems.Count() || guide.items.Count())
			{
				add := SubStr(step, InStr(step, ":") + 2), add := InStr(add, "(") ? SubStr(add, InStr(add, ")") + 1) : add, add := StrReplace(add, "_", " ")
				guide[InStr(step, "buy item:") ? "items" : "gems"].Push(add)
				Continue
			}

			For index, part in text_parts
			{
				If InStr(part, "(img:")
				{
					img := SubStr(part, InStr(part, "(img:") + 5), img := SubStr(img, 1, InStr(img, ")") - 1)
					Gui, %GUI_name_main%: Add, Picture, % style (A_Index = 1 ? "" : " x+"(InStr(step, "(hint)") ? 0 : settings.leveltracker.fWidth/2)) " BackgroundTrans "(InStr(step, "(hint)") ? "hp-2" : "h" settings.leveltracker.fHeight - 2) " w-1", % "img\GUI\leveling tracker\"img ".png"
				}
				Else
				{
					text := LLK_StringRemove(part, "<,>,arena:,(hint)"), area := StrReplace(text, "areaid")
					If InStr(text, "areaid") ;translate ID to location-name (and add potential act-clarification)
						text := ((areas[area].act != vars.log.act) && !InStr(text, "labyrinth") || InStr(vars.log.areaID, "hideout") ? (areas[area].act = 11 ? "epilogue" : "a" areas[area].act) " | " : "") . areas[StrReplace(text, "areaid")][InStr(line, "to areaid") && areas[area].map_name ? "map_name" : "name"]
					text := StrReplace(text, "_", " "), text := StrReplace(text, "(a11)", "(epilogue)")
					If InStr(part, "(quest:")
						replace := SubStr(text, InStr(text, "(quest:")), replace := SubStr(replace, 1, InStr(replace, ")")), item := StrReplace(SubStr(replace, InStr(replace, ":") + 1), ")"), text := StrReplace(text, replace, item)
					color := InStr(part, "areaid") ? "FEC076" : kill && (part != "everything") || InStr(part, "arena:") ? "FF8111" : InStr(part, "<") ? "FFDB1F" : InStr(part, "(quest:") ? "Lime" : InStr(part, "trial") || InStr(part, "_lab") ? "569777" : "White"
					If InStr(part, "(color:")
						color := SubStr(part, InStr(part, "(color:") + 7), color := SubStr(color, 1, InStr(color, ")") - 1), text := StrReplace(text, "(color:"color ")")
					If InStr(step, "(hint)")
						Gui, %GUI_name_main%: Font, % "s"settings.leveltracker.fSize - 2
					Gui, %GUI_name_main%: Add, Text, % style " c"color, % (index = text_parts.MaxIndex()) || (text_parts[index + 1] = ",") || InStr(text_parts[index + 1], "(img:") ? text : text " "
					Gui, %GUI_name_main%: Font, % "s"settings.leveltracker.fSize
					kill := (part = "kill") ? 1 : 0
				}
				style := InStr(part, "(img:") ? "ys x+"settings.leveltracker.fWidth/4 : "ys x+0"
			}
			If InStr(step, "(hint)")
				Loop, Files, img\GUI\leveling tracker\hints\*.jpg
					If InStr(step, StrReplace(A_LoopFileName, ".jpg"))
					{
						Gui, %GUI_name_main%: Add, Picture, % "ys hp w-1 x+" settings.leveltracker.fWidth, img\GUI\help.png
						Break
					}
		}
		If (outer = 2) && (guide.gems.Count() || guide.items.Count())
			LeveltrackerStrings()

		vars.leveltracker.wait := 1 ;this stops the timer-GUI from being created before the main overlay has finished drawing
		Gui, %GUI_name_main%: Show, NA x10000 y10000
		Gui, %GUI_name_back%: Show, NA x10000 y10000
		WinGetPos, x, y, width, height, % "ahk_id " leveltracker_main
	}
	
	While Mod(width, 2)
		width += 1
	wButtons := Round(settings.leveltracker.fWidth*2)
	While Mod(wButtons, 2)
		wButtons += 1
	wPanels := (width - wButtons*2)/2

	Gui, %GUI_name_back%: Show, % "NA w"width - 2 " h"height
	Gui, %GUI_name_main%: Show, % "NA w"width - 2 " h"height
	WinGetPos, x, y, width, height, % "ahk_id " vars.hwnd.leveltracker.main

	GUI_name_controls1 := "leveltracker_controls1" toggle, GUI_name_controls2 := "leveltracker_controls2" toggle
	Gui, %GUI_name_controls1%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_controls1"
	Gui, %GUI_name_controls1%: Color, Black
	Gui, %GUI_name_controls1%: Margin, 0, 0
	WinSet, Transparent, % (settings.leveltracker.trans = 5) ? "Off" : 100 + settings.leveltracker.trans * 30
	Gui, %GUI_name_controls1%: Font, % "s"settings.leveltracker.fSize " cWhite", % vars.system.font
	vars.hwnd.leveltracker.controls1 := leveltracker_controls1
	If settings.leveltracker.timer
	{
		Gui, %GUI_name_controls1%: Add, Text, % "Section 0x200 Border HWNDhwnd Center w"wPanels, % ""
		vars.hwnd.leveltracker.dummy01 := hwnd
		Gui, %GUI_name_controls1%: Add, Text, % "ys hp 0x200 BackgroundTrans Border HWNDhwnd Center w"wButtons * 2, % ""
		Gui, %GUI_name_controls1%: Add, Progress, % "xp yp hp wp Disabled HWNDhwnd BackgroundBlack cRed range0-500", 0
		vars.hwnd.leveltracker.reset_bar := hwnd
		Gui, %GUI_name_controls1%: Add, Text, % "ys wp hp 0x200 Border HWNDhwnd Center w"wPanels, % ""
		vars.hwnd.leveltracker.dummy02 := hwnd
	}
	Gui, %GUI_name_controls1%: Add, Progress, % "Section " (settings.leveltracker.timer ? "xs y+-1" : "") " BackgroundWhite HWNDhwnd0 w" settings.leveltracker.fWidth * 0.6 " h" settings.leveltracker.fWidth * 0.6, 0
	Gui, %GUI_name_controls1%: Add, Text, % "Section xp yp 0x200 Border BackgroundTrans HWNDhwnd Center w" wPanels, % ""
	vars.hwnd.leveltracker.drag := hwnd0, vars.hwnd.leveltracker.dummy1 := hwnd
	Gui, %GUI_name_controls1%: Add, Text, % "ys hp 0x200 Border HWNDhwnd Center w"wButtons, % ""
	vars.hwnd.leveltracker["-"] := hwnd
	Gui, %GUI_name_controls1%: Add, Text, % "ys hp 0x200 Border HWNDhwnd Center w"wButtons, % ""
	vars.hwnd.leveltracker["+"] := hwnd, check := 0
	Gui, %GUI_name_controls1%: Add, Text, % "ys wp hp 0x200 Border HWNDhwnd Center w"wPanels, % ""
	vars.hwnd.leveltracker.dummy2 := hwnd

	If settings.leveltracker.layouts
		Loop, Files, % "img\GUI\leveling tracker\zones\" vars.log.areaID " *"
			check += 1

	Gui, %GUI_name_controls2%: New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_controls2 +Owner" GUI_name_controls1
	Gui, %GUI_name_controls2%: Color, Black
	Gui, %GUI_name_controls2%: Margin, 0, 0
	WinSet, TransColor, Black
	Gui, %GUI_name_controls2%: Font, % "s" settings.leveltracker.fSize " cWhite", % vars.system.font
	vars.hwnd.leveltracker.controls2 := leveltracker_controls2
	If settings.leveltracker.timer
	{
		Gui, %GUI_name_controls2%: Add, Text, % "Section Border 0x200 BackgroundTrans HWNDhwnd Center w" wPanels (timer.current_act = 11 ? " cLime" : (timer.pause = -1) ? " cGray" : ""), % FormatSeconds(timer.total_time + (timer.current_act = 11 ? 0 : timer.current_split), 0)
		vars.hwnd.leveltracker.timer_total := hwnd
		Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w" wButtons * 2, % "a" (timer.current_act = 11 ? 10 : timer.current_act)
		vars.hwnd.leveltracker.timer_button := hwnd
		Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w" wPanels (timer.current_act = 11 ? " cLime" : (timer.pause = -1) ? " cGray" : ""), % FormatSeconds(timer.current_split, 0)
		vars.hwnd.leveltracker.timer_act := hwnd
	}
	Gui, %GUI_name_controls2%: Add, Text, % "Section xs " (settings.leveltracker.timer ? "xs y+-1" : "") " Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels, % settings.leveltracker.layouts ? check " zl" : ""
	vars.hwnd.leveltracker.layouts := hwnd, exp_info := LeveltrackerExperience("", 1)
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w" wButtons, % "<"
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w" wButtons, % ">"
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels " c" (!InStr(exp_info, "100%") ? "Red" : "Lime"), % StrReplace(exp_info, (exp_info = "100%") ? "" : "100%")
	vars.hwnd.leveltracker.experience := hwnd

	Gui, %GUI_name_controls2%: Show, % "NA x10000 y10000"
	Gui, %GUI_name_controls1%: Show, % "NA x10000 y10000"
	WinGetPos,,, wControls, hControls, % "ahk_id " vars.hwnd.leveltracker.controls1

	width -= 2, height -= 2, height_total := height + hControls + 2
	xPos := Blank(settings.leveltracker.xCoord) ? vars.client.xc - width / 2 : settings.leveltracker.xCoord, xPos := (xPos >= vars.monitor.w / 2) ? xPos - width : xPos
	yPos := Blank(settings.leveltracker.yCoord) ? vars.client.y - vars.monitor.y + vars.client.h + 1 : settings.leveltracker.yCoord, yPos := (yPos >= vars.monitor.h / 2) ? yPos - height_total : yPos
	;Msgbox, % xPos ", " yPos "`n" vars.client.xc
	;vars.monitor.x + settings.leveltracker.xCoord - (settings.leveltracker.xCoord >= vars.monitor.x + vars.monitor.w / 2 ? width/2 : 0)
	;yPos := Blank(settings.leveltracker.yCoord) ? vars.client.y + vars.client.h - height - hControls + (settings.leveltracker.timer ? 1 : 0) : vars.monitor.y + settings.leveltracker.yCoord - (settings.leveltracker.yCoord >= vars.monitor.y + vars.monitor.h / 2 ? height : 0)

	Gui, %GUI_name_controls2%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos + height + 1
	Gui, %GUI_name_controls1%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos + height + 1

	Gui, %GUI_name_back%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	Gui, %GUI_name_main%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	vars.leveltracker.coords := {"x1": xPos, "x2": xPos + width, "y1": yPos, "y2": yPos + height_total - 1, "w": width, "h": height_total}
	LLK_Overlay(vars.hwnd.leveltracker.background, vars.leveltracker.fade ? "hide" : "show",, GUI_name_back), LLK_Overlay(vars.hwnd.leveltracker.main, vars.leveltracker.fade ? "hide" : "show",, GUI_name_main)
	LLK_Overlay(hwnd_old, "destroy"), LLK_Overlay(hwnd_old1, "destroy")

	LLK_Overlay(vars.hwnd.leveltracker.controls1, vars.leveltracker.fade ? "hide" : "show",, GUI_name_controls1), LLK_Overlay(vars.hwnd.leveltracker.controls2, vars.leveltracker.fade ? "hide" : "show",, GUI_name_controls2)
	LLK_Overlay(hwnd_old2, "destroy"), LLK_Overlay(hwnd_old3, "destroy")
	vars.leveltracker.last := A_TickCount
	vars.leveltracker.wait := 0, in_progress := 0
}

LeveltrackerProgressReset(profile := "")
{
	local
	global vars, settings

	IniDelete, ini\leveling guide%profile%.ini, Progress
	vars.leveltracker.guide.progress := []
	If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
		LeveltrackerProgress(1)
	If WinExist("ahk_id " vars.hwnd.settings.main)
		Settings_menu("leveling tracker")
	KeyWait, LButton
}

LeveltrackerScreencapPaste(index)
{
	local
	global vars, settings

	active := vars.leveltracker.screencap_active
	If InStr(Clipboard, ":\")
	{
		If !LLK_CheckClipImages()
		{
			LLK_ToolTip(LangTrans("lvltracker_multipaste"), 2,,,, "red")
			Return
		}
		If InStr(Clipboard, ":\",,, 2)
		{
			If InStr(index, "-")
			{
				LLK_ToolTip(LangTrans("lvltracker_multipaste", 2), 2,,,, "red")
				Return
			}
			MsgBox, 4, Clipboard multi-paste, % LangTrans("lvltracker_multipaste", 3, [LLK_InStrCount(Clipboard, ":"), index])
			IfMsgBox No
				Return
		}
		Loop, Parse, Clipboard, `n, `r
			FileCopy, % A_LoopField, % "img\GUI\skill-tree" settings.leveltracker.profile "\["(index + A_Index - 1 < 10 ? "0" : "") index + A_Index - 1 "].*", 1
	}
	Else
	{
		pBitmap := Gdip_CreateBitmapFromClipboard()
		If (pBitmap < 0)
		{
			LLK_ToolTip(LangTrans("global_imageinvalid"), 1.5,,,, "red")
			Return
		}
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree" settings.leveltracker.profile "\["(InStr(index, "-") ? "lab" : "") StrReplace(index, "-") "].png", 100)
		Gdip_DisposeImage(pBitmap)
	}
	Return 1
}

LeveltrackerSkilltree(index := 0)
{
	local
	global vars, settings
	static toggle := 0

	skilltree := vars.leveltracker.skilltree ;short-cut variable
	If !IsNumber(skilltree.active) || !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["skilltree.active "]*")
		skilltree.active := "00"
	index := index ? index : skilltree.active, skilltree.files := [], skilltree.files_lab := []

	Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\[*]*"
	{
		If (SubStr(A_LoopFileName, 1, 4) = "[lab")
			skilltree.files_lab.Push(SubStr(A_LoopFileName, 1, 5))
		Else If (SubStr(A_LoopFileName, 1, 1) = "[" && SubStr(A_LoopFileName, 4, 1) = "]" && IsNumber(SubStr(A_LoopFileName, 2, 2)))
			skilltree.files.Push(SubStr(A_LoopFileName, 1, 4))
		If !InStr("jpg,bmp,png", A_LoopFileExt) || (A_LoopFileExt = "")
			continue
	}

	If skilltree.files.Count() || skilltree.files_lab.Count()
	{
		toggle := !toggle, GUI_name_skilltree := "leveltracker_skilltree" toggle
		Gui, %GUI_name_skilltree%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree
		Gui, %GUI_name_skilltree%: Margin, 0, 0
		Gui, %GUI_name_skilltree%: Color, Black
		Gui, %GUI_name_skilltree%: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
		hwnd_old := vars.hwnd.leveltracker_skilltree.main, hwnd_old1 := vars.hwnd.leveltracker_skilltree.labs
		vars.hwnd.leveltracker_skilltree := {"main": leveltracker_skilltree}, count := 0

		Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\[*]*"
		{
			If InStr(A_LoopFileName, "[lab") && !InStr(index, "lab")
				Continue
			count += 1
			If (index = "00" || SubStr(A_LoopFileName, 2, StrLen(index)) = index) && InStr("jpg,png,bmp", A_LoopFileExt) && (!InStr(A_LoopFileName, "[lab") || InStr(index, "lab"))
			{
				img := A_LoopFilePath, caption := StrReplace(A_LoopFileName, "."A_LoopFileExt), caption := SubStr(caption, InStr(caption, "]") + (InStr(caption, "] ") ? 2 : 1))
				skilltree.active := SubStr(A_LoopFileName, 2, (SubStr(A_LoopFileName, 1, 4) = "[lab") ? 4 : 2)
				Break
			}
		}

		If img
			Gui, %GUI_name_skilltree%: Add, Picture, Border Section HWNDhwnd, % img
		Else Gui, %GUI_name_skilltree%: Add, Text, % "Section Center Border HWNDhwnd w"vars.monitor.h/4 " h"vars.monitor.h/4, couldn't find skill tree image-files
		Gui, %GUI_name_skilltree%: Add, Text, % "xs Section y+-1 wp Border BackgroundTrans Center"(!caption ? " h"settings.general.fHeight//2 : ""), % caption
		Gui, %GUI_name_skilltree%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack c404040 Center range0-"skilltree.files.Count(), % count
		Gui, %GUI_name_skilltree%: Show, % "NA x10000 y10000"
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.main
		Gui, %GUI_name_skilltree%: Show, % "NA x"vars.client.x " y" vars.monitor.y + vars.client.yc - h//2
          skilltree.x := x, skilltree.y := y, skilltree.w := w, skilltree.h := h
		LLK_Overlay(leveltracker_skilltree, "show",, GUI_name_skilltree), LLK_Overlay(hwnd_old, "destroy")

		If Blank(A_Gui) && skilltree.files_lab.Count()
		{
			GUI_name_labs := "leveltracker_skilltree_labs" toggle
			Gui, %GUI_name_labs%: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree_labs
			Gui, %GUI_name_labs%: Margin, 0, 0
			Gui, %GUI_name_labs%: Color, Black
			vars.hwnd.leveltracker_skilltree.labs := leveltracker_skilltree_labs
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\[lab*]*"
			{
				parse := SubStr(A_LoopFileName, InStr(A_LoopFileName, "[lab") + 4, 1)
				Gui, %GUI_name_labs%: Add, Picture, % (A_Index = 1 ? "Section" : "xs") " BackgroundTrans w"vars.monitor.h//25 " h-1 HWNDhwnd", % "img\GUI\lab"parse ".png"
				vars.hwnd.leveltracker_skilltree["lab"parse] := hwnd
			}
			If skilltree.files_lab.Count()
			{
				;Gui, %GUI_name_labs%: Show, % "NA x"vars.client.x + vars.client.w//2 - (skilltree.files_lab.Count()* vars.monitor.h//25)//2 " y"vars.client.y + vars.client.h - vars.monitor.h//25 - vars.client.h*0.0215
				Gui, %GUI_name_labs%: Show, % "NA x10000 y10000"
				WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.labs
				Gui, %GUI_name_labs%: Show, % "NA x"vars.client.x + skilltree.w + vars.client.w//250 " y" vars.monitor.y + vars.client.yc - h//2
				LLK_Overlay(leveltracker_skilltree_labs, "show",, GUI_name_labs), LLK_Overlay(hwnd_old1, "destroy")
			}
		}
		If Blank(A_Gui) && !LeveltrackerSkilltreeHover()
			Return
		If !Blank(A_Gui)
			KeyWait, LButton
		KeyWait, % vars.omnikey.hotkey
		LLK_Overlay(leveltracker_skilltree, "destroy"), LLK_Overlay(leveltracker_skilltree_labs, "destroy")
	}
	Else LLK_ToolTip(LangTrans("lvltracker_noimages"), 1.5,,,, "red")
	vars.hwnd.Delete("leveltracker_skilltree")
}

LeveltrackerSkilltreeHover()
{
	local
	global vars, settings

	skilltree := vars.leveltracker.skilltree
	KeyWait, RButton
	While GetKeyState(vars.omnikey.hotkey, "P")
	{
		KeyWait, RButton, D T0.1
		If !ErrorLevel
		{
			start := A_TickCount
			While GetKeyState("RButton", "P")
			{
				If (A_TickCount >= start + 300)
				{
					check := skilltree.active - 1, check := (check < 10 ? "0" : "") check
					Break
				}
			}
			If Blank(check)
				check := skilltree.active + 1, check := (check < 10 ? "0" : "") check
			If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\["check "]*")
			{
				WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.main
				LLK_ToolTip(LangTrans("lvltracker_endreached"),, x, y,, "yellow")
				KeyWait, RButton
				check := ""
				Continue
			}
			Else Break
		}

		If WinExist("ahk_id " vars.hwnd.leveltracker_skilltree.labs) && WinExist("ahk_id " vars.hwnd.leveltracker_skilltree.lab) && (vars.general.wMouse != DummyGUI(vars.hwnd.leveltracker_skilltree.labs))
			LLK_Overlay(vars.hwnd.leveltracker_skilltree.lab, "destroy")
		HWNDcheck := LLK_HasVal(vars.hwnd.leveltracker_skilltree, vars.general.cMouse)
		If HWNDcheck && (!WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab) || lab_active != HWNDcheck)
		{
			LeveltrackerSkilltreeLab(HWNDcheck)
			lab_active := HWNDcheck
		}
	}
	LLK_Overlay(vars.hwnd.leveltracker_skilltree.lab, "destroy")
	If !Blank(check)
	{
		skilltree.active := check
		IniWrite, % skilltree.active, ini\leveling tracker.ini, settings, % "last skilltree-image" settings.leveltracker.profile
		SetTimer, LeveltrackerSkilltree, -100
		Return 0
	}
	Return 1
}

LeveltrackerSkilltreeLab(file)
{
	local
	global vars, settings
	static toggle := 0

	skilltree := vars.leveltracker.skilltree, toggle := !toggle, GUI_name := "leveltracker_skilltree_lab" toggle
	Gui, %GUI_name%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree_lab
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.leveltracker_skilltree.lab, vars.hwnd.leveltracker_skilltree.lab := leveltracker_skilltree_lab

	Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile "\[lab*]*"
		If (SubStr(A_LoopFileName, 2, 4) = file)
			image := A_LoopFilePath, caption := SubStr(StrReplace(A_LoopFileName, "."A_LoopFileExt), InStr(A_LoopFileName, "]") + 1), caption := StrReplace(caption, " ",,, 1)
	Gui, %GUI_name%: Add, Picture, % "Section BackgroundTrans Border", % image
	Gui, %GUI_name%: Add, Text, % "xs y+-1 wp Center BackgroundTrans Border"(!caption ? " h"settings.general.fHeight/2 : ""), % caption
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack c404040 Border", 0
	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.lab
	Gui, %GUI_name%: Show, % "NA x"vars.client.x + skilltree.w + 2*vars.client.w//250 + vars.monitor.h//25 " y" vars.monitor.y + vars.client.yc - h//2
	LLK_Overlay(leveltracker_skilltree_lab, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

LeveltrackerStrings()
{
	local
	global vars, settings, db

	strings := [], string := "", attr_check := ["str", "dex", "int"], attr_check.0 := "none"
	For key, val in vars.leveltracker.guide.items
	{
		If (StrLen(string "|" StrReplace(val, " ", "\s")) > 47)
			strings.Push(string), string := StrReplace(val, " ", "\s")
		Else string .= (Blank(string) ? "" : "|") StrReplace(val, " ", "\s")
	}
	If !Blank(string)
		strings.Push(string)

	Loop, Parse, % "str,str_supp,dex,dex_supp,int,int_supp,none", `,
		strings_%A_LoopField% := [], strings_gems := []

	For key, val in vars.leveltracker.guide.gems
	{
		regex := StrReplace(db.leveltracker.regex[val].1, " ", "."), regex := !regex ? val : regex
		If !Blank(LLK_HasVal(vars.leveltracker.guide.group1, "fixture_of_fate", 1))
		{
			attr := attr_check[db.leveltracker.regex[val].2], type := InStr(val, " support") ? "_supp" : ""
			If (StrLen(string_%attr%%type% "|" regex) > 46)
				strings_%attr%%type%.Push(string_%attr%%type%), string_%attr%%type% := regex
			Else string_%attr%%type% .= (Blank(string_%attr%%type%) ? "" : "|") regex
		}
		Else
		{
			If (StrLen(string_gems "|" regex) > 46)
				strings_gems.Push(string_gems), string_gems := regex
			Else string_gems .= (Blank(string_gems) ? "" : "|") regex
		}
	}
	If !Blank(string_gems)
		strings_gems.Push(string_gems)

	vars.leveltracker.string := []
	For key, val in strings
		vars.leveltracker.string.Push("^(" val ")$")

	If !Blank(LLK_HasVal(vars.leveltracker.guide.group1, "fixture_of_fate", 1))
	{
		Loop, Parse, % "str,str_supp,dex,dex_supp,int,int_supp,none", `,
		{
			If !Blank(string_%A_LoopField%)
				strings_%A_LoopField%.Push(string_%A_LoopField%)
			For key, val in strings_%A_LoopField%
				vars.leveltracker.string.Push("^("val ")$")
		}
	}
	Else
	{
		For key, val in strings_gems
			vars.leveltracker.string.Push("^("val ")$")
	}
}

LeveltrackerTimer(mode := "")
{
	local
	global vars, settings, db

	timer := vars.leveltracker.timer
	If mode && InStr("pause,reset", mode)
	{
		If (mode = "pause") && (timer.current_act = 11)
			error := [LangTrans("lvltracker_timererror", 1), 1.5, "yellow"]
		Else If (mode = "reset") && (vars.log.areaID != "1_1_1")
			error := [LangTrans("lvltracker_timererror", 2), 2, "red"]
		Else If (mode = "reset") && !timer.pause
			error := [LangTrans("lvltracker_timererror", 3), 1, "red"]
		Else If (mode = "pause") && settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")
			error := [LangTrans("lvltracker_timererror", 4), 2, "red"]

		yTooltip := vars.leveltracker.coords.y1 - settings.general.fHeight + 1, yTooltip := (yTooltip < vars.monitor.y) ? vars.leveltracker.coords.y2 - 1 : yTooltip
		If error
		{
			LLK_ToolTip(error.1, error.2, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, error.3,,,, 1)
			WinActivate, ahk_group poe_window
			Return
		}

		If (mode = "reset")
		{
			If LLK_Progress(vars.hwnd.leveltracker.reset_bar, "RButton")
			{
				LeveltrackerProgressReset()
				IniWrite, % "", ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, name
				IniWrite, 0, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
				Loop 10
					IniWrite, % "", ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, act %A_Index%
				vars.leveltracker.Delete("timer")
				Init_leveltracker(), LeveltrackerProgress(1)
				KeyWait, RButton
				Return
			}
			Else Return
		}
		Else If (mode = "pause") && (timer.current_act != 11)
		{
			If !InStr(timer.name, ",") && (vars.log.areaID = "1_1_1")
			{
				FormatTime, date,, ShortDate
				FormatTime, time,, Time
				timer.name := date ", " time
				IniWrite, % """"timer.name """", ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, name
				new_run := 1
			}
			LLK_ToolTip(new_run ? LangTrans("lvltracker_timermessage", 1) : (timer.pause != 0) ? LangTrans("lvltracker_timermessage", 2) : LangTrans("lvltracker_timermessage", 3),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "lime",,,, 1)
			timer.pause := !timer.pause ? -1 : 0 ;-1 specifies a manual pause by the user (as opposed to automatic pause after logging in or -- if set up this way -- entering a hideout)
			GuiControl, % "+c" (timer.pause ? "Gray" : "White"), % vars.hwnd.leveltracker.timer_total
			GuiControl, movedraw, % vars.hwnd.leveltracker.timer_total
			GuiControl, % "+c" (timer.pause ? "Gray" : "White"), % vars.hwnd.leveltracker.timer_act
			GuiControl, movedraw, % vars.hwnd.leveltracker.timer_act
		}
		Return
	}

	If !settings.leveltracker.timer
		Return

	If vars.hwnd.leveltracker.main && (timer.pause = 1) && (db.leveltracker.areas.HasKey(vars.log.areaID) || InStr(vars.log.areaID, "labyrinth")) && (timer.current_act != 11) ;resume the timer after leaving a hideout (if it wasn't paused manually by the user)
		timer.pause := 0

	If vars.hwnd.leveltracker.main && (timer.pause = 0) ;advance the timer
	{
		timer.current_split += (timer.current_act = 11) ? 0 : 1, timer.pause := (settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")) || (timer.current_act = 11) ? 1 : 0
		If vars.log.act && (timer.current_act + 1 = vars.log.act) ;player enters the next act: save previous act's time, add it to total time, then reset it
		{
			IniWrite, % timer.current_split, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, % "act "timer.current_act
			If InStr(timer.name, ",")
				LeveltrackerTimerCSV()
			timer.total_time += timer.current_split, timer.current_act += 1, timer.current_split := (timer.current_act = 11) ? timer.current_split : 0
			GuiControl, Text, % vars.hwnd.leveltracker.timer_button, % "a" (timer.current_act = 11 ? 10 : timer.current_act)
			IniWrite, % timer.current_split, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
			If (timer.current_act = 11)
				LeveltrackerProgress(1)
		}
		Else If timer.current_split && !Mod(timer.current_split, 60) && (timer.current_split != LLK_IniRead("ini\leveling tracker.ini", "current run" settings.leveltracker.profile, "time", 0)) ;save current time every minute as backup for potential crashes
			IniWrite, % timer.current_split, ini\leveling tracker.ini, % "current run" settings.leveltracker.profile, time
		If !vars.leveltracker.wait ;update the timer every cycle
		{
			GuiControl, Text, % vars.hwnd.leveltracker.timer_total, % FormatSeconds(timer.total_time + (timer.current_act = 11 ? 0 : timer.current_split), 0)
			GuiControl, Text, % vars.hwnd.leveltracker.timer_act, % FormatSeconds(timer.current_split, 0)
		}
	}
}

LeveltrackerTimerCSV()
{
	local
	global vars, settings

	If !FileExist("exports\campaign runs.csv")
		FileAppend, % """date, time"",act 1,act 2,act 3,act 4,act 5,act 6,act 7,act 8,act 9,act 10", exports\campaign runs.csv

	FileRead, csv, exports\campaign runs.csv
	If InStr(csv, vars.leveltracker.timer.name)
		FileAppend, % ","""FormatSeconds(vars.leveltracker.timer.current_split) ".00""", exports\campaign runs.csv
	Else FileAppend, % "`n"""vars.leveltracker.timer.name ""","""FormatSeconds(vars.leveltracker.timer.current_split) ".00""", exports\campaign runs.csv
}

LeveltrackerToggle(mode)
{
	local
	global vars

	LLK_Overlay(vars.hwnd.leveltracker.main, mode), LLK_Overlay(vars.hwnd.leveltracker.background, mode), LLK_Overlay(vars.hwnd.leveltracker.controls2, mode), LLK_Overlay(vars.hwnd.leveltracker.controls1, mode)
}

LeveltrackerZoneLayouts(mode := 0, drag := 0, cHWND := "")
{
	local
	global vars, settings
	static toggle := 0

	If !settings.leveltracker.layouts
		Return

	start := A_TickCount
	If (drag = 1)
		WinGetPos,,, width, height, % "ahk_id "vars.hwnd.leveltracker_zones.main
	While cHWND && (drag = 1) && GetKeyState("LButton", "P")
		If (A_TickCount >= start + 200)
		{
			longpress := 1
			LLK_Drag(width, height, x, y,, "leveltracker_zones" toggle, (settings.leveltracker.aLayouts = "horizontal") ? 1 : 0)
			Sleep 1
		}

	If cHWND && !longpress && (drag = 1)
	{
		settings.leveltracker.aLayouts := (settings.leveltracker.aLayouts = "vertical") ? "horizontal" : "vertical"
		IniWrite, % settings.leveltracker.aLayouts, ini\leveling tracker.ini, settings, zone-layouts arrangement
	}
	Else If cHWND && !longpress && (drag = 2)
		x := (settings.leveltracker.aLayouts = "vertical") ? vars.client.x - vars.monitor.x : "", y := (settings.leveltracker.aLayouts = "vertical") ? "" : vars.client.y - vars.monitor.y

	If !Blank(x) || !Blank(y)
	{
		settings.leveltracker.xLayouts := x, settings.leveltracker.yLayouts := y
		IniWrite, % settings.leveltracker.xLayouts, ini\leveling tracker.ini, settings, zone-layouts x
		IniWrite, % settings.leveltracker.yLayouts, ini\leveling tracker.ini, settings, zone-layouts y
		If (drag = 1)
			Return
	}

	Loop, Files, % "img\GUI\leveling tracker\zones\" vars.log.areaID " *"
		check += 1

	If !check
	{
		LLK_Overlay(vars.hwnd.leveltracker_zones.main, "destroy")
		Return
	}

	toggle := !toggle, GUI_name := "leveltracker_zones" toggle
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_zones"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % Floor(vars.monitor.h/200), % Floor(vars.monitor.h/200)
	WinSet, TransColor, Black
	hwnd_old := vars.hwnd.leveltracker_zones.main, vars.hwnd.leveltracker_zones := {"main": leveltracker_zones}

	Loop, Files, % "img\GUI\leveling tracker\zones\" vars.log.areaID " *"
	{
		If (settings.leveltracker.aLayouts = "vertical")
			style := (vars.log.areaID = "2_7_4" && A_Index = 4) ? " ys Section" : (A_Index = 1) ? " Section" : " xs"
		Else style := (vars.log.areaID = "2_7_4" && A_Index = 4) ? " xs Section" : (A_Index = 1) ? " Section" : " ys"
		Gui, %GUI_name%: Add, Picture, % "Border HWNDhwnd" style " w"vars.monitor.w/settings.leveltracker.sLayouts " h-1", % A_LoopFilePath
		vars.hwnd.leveltracker_zones[vars.log.areaID A_Index] := hwnd
	}
	If mode
		Gui, %GUI_name%: Add, Picture, % "Border " (settings.leveltracker.aLayouts = "horizontal" ? "xs" : "ys") " w"vars.monitor.w/Ceil(settings.leveltracker.sLayouts/2) " h-1", % "img\GUI\leveling tracker\zones\explanation.png"
	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_zones.main
	xPos := Blank(settings.leveltracker.xLayouts) ? (settings.leveltracker.aLayouts = "horizontal" ? vars.client.xc - w/2 : vars.client.x - vars.monitor.x) : settings.leveltracker.xLayouts
	yPos := Blank(settings.leveltracker.yLayouts) ? (settings.leveltracker.aLayouts = "vertical" ? vars.client.yc - h/2 : vars.client.y - vars.monitor.y) : settings.leveltracker.yLayouts
	xPos := (xPos >= vars.monitor.w / 2) ? xPos - w + 1 : xPos, yPos := (yPos >= vars.monitor.h / 2) ? yPos - h + 1 : yPos
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	LLK_Overlay(leveltracker_zones, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

LeveltrackerZoneLayoutsSize(hotkey)
{
	local
	global vars, settings
	static resizing

	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_zones.main
	If (hotkey = "WheelUp") && (settings.leveltracker.aLayouts = "vertical" && h >= vars.monitor.h * 0.7 || settings.leveltracker.aLayouts = "horizontal" && w >= vars.monitor.w * 0.7) ;cont
	|| (hotkey = "WheelDown" && settings.leveltracker.sLayouts = 20) || resizing
		Return

	If (hotkey != "MButton")
		settings.leveltracker.sLayouts += (hotkey = "WheelUp") ? -1 : 1, resizing := 1
	LeveltrackerZoneLayouts((hotkey = "MButton") ? 1 : 0)
	If (hotkey = "MButton")
	{
		KeyWait, MButton
		LeveltrackerZoneLayouts()
	}
	resizing := 0
}
