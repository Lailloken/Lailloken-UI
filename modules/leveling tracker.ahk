Init_leveltracker()
{
	local
	global vars, settings
	
	settings.features.leveltracker := LLK_IniRead("ini\config.ini", "Features", "enable leveling guide", 0)
	
	If !FileExist("ini\leveling tracker.ini")
	{
		IniWrite, % "", ini\leveling tracker.ini, settings
		IniWrite, % "", ini\leveling tracker.ini, UI
	}

	If !InStr(LLK_IniRead("ini\leveling tracker.ini"), "current run")
	{
		IniWrite, % "", ini\leveling tracker.ini, current run, name
		IniWrite, 0, ini\leveling tracker.ini, current run, time
		Loop 10
			IniWrite, % "", ini\leveling tracker.ini, current run, act %A_Index%
	}

	settings.leveltracker := {}
	settings.leveltracker.timer := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable timer", 0)
	settings.leveltracker.pausetimer := LLK_IniRead("ini\leveling tracker.ini", "Settings", "hideout pause", 0)
	settings.leveltracker.fade := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable fading", 0)
	settings.leveltracker.fadetime := LLK_IniRead("ini\leveling tracker.ini", "Settings", "fade-time", 5000)
	settings.leveltracker.fade_hover := LLK_IniRead("ini\leveling tracker.ini", "Settings", "show on hover", 1)
	settings.leveltracker.geartracker := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable geartracker", 0)
	settings.leveltracker.layouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable zone-layout overlay", 0)
	settings.leveltracker.hints := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable additional hints", 0)
	settings.leveltracker.fSize := LLK_IniRead("ini\leveling tracker.ini", "Settings", "font-size", settings.general.fSize)
	LLK_FontDimensions(settings.leveltracker.fSize, font_height, font_width)
	settings.leveltracker.fHeight := font_height, settings.leveltracker.fWidth := font_width
	settings.leveltracker.pob := LLK_IniRead("ini\leveling tracker.ini", "Settings", "enable pob-screencap", 0)
	settings.leveltracker.trans := LLK_IniRead("ini\leveling tracker.ini", "Settings", "transparency", 250)
	settings.leveltracker.pos := LLK_IniRead("ini\leveling tracker.ini", "Settings", "overlay-position", "bottom")
	settings.leveltracker.oButton := LLK_IniRead("ini\leveling tracker.ini", "Settings", "button-offset", 1)
	settings.leveltracker.sButton := Floor(vars.monitor.w* 0.03* settings.leveltracker.oButton)
	settings.leveltracker.xButton := LLK_IniRead("ini\leveling tracker.ini", "UI", "button xcoord")
	settings.leveltracker.yButton := LLK_IniRead("ini\leveling tracker.ini", "UI", "button ycoord")
	settings.leveltracker.xLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts x", 0)
	settings.leveltracker.yLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts y")
	settings.leveltracker.sLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts size", 8)
	settings.leveltracker.aLayouts := LLK_IniRead("ini\leveling tracker.ini", "Settings", "zone-layouts arrangement", "vertical")

	vars.leveltracker.gearfilter := 1, vars.leveltracker.gear := []
	vars.leveltracker.character := LLK_IniRead("ini\leveling tracker.ini", "Settings", "character")
	iniread := LLK_IniRead("ini\leveling tracker.ini", "gear") "`n" LLK_IniRead("ini\leveling tracker.ini", "gems")
	StringLower, iniread, iniread
	Sort, iniread, D`n N P2
	Loop, Parse, iniread, `n
	{
		If Blank(A_LoopField) || LLK_HasVal(vars.leveltracker.gear, SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1))
			Continue
		vars.leveltracker.gear.Push(SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1))
	}
		
	;settings.leveltracker.gear.x := LLK_IniRead("ini\leveling tracker.ini", "UI", "indicator xcoord", 0.3* vars.client.w)
	;settings.leveltracker.gear.y := LLK_IniRead("ini\leveling tracker.ini", "UI", "indicator ycoord", 0.91* vars.client.h)
	
	If !IsObject(vars.leveltracker.guide)
		vars.leveltracker.guide := {}
	Loop, Parse, % LLK_IniRead("ini\leveling tracker.ini", "gem notes"), `n
		vars.leveltracker.guide.gem_notes[SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)] := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)

	If !IsObject(vars.leveltracker.timer)
	{
		vars.leveltracker.timer := {"name": LLK_IniRead("ini\leveling tracker.ini", "current run", "name"), "current_split": LLK_IniRead("ini\leveling tracker.ini", "current run", "time", 0), "current_act": 1, "total_time": 0, "pause": -1}
		Loop 11
		{
			iniread := LLK_IniRead("ini\leveling tracker.ini", "current run", "act " A_Index)
			vars.leveltracker.timer.current_act := A_Index
			If !iniread
				Break
			vars.leveltracker.timer.total_time += iniread
		}
	}
	
	vars.leveltracker.skilltree := {"active": LLK_IniRead("ini\leveling tracker.ini", "Settings", "last skilltree-image", "00")}
}

Geartracker(mode := "")
{
	local
	global vars, settings

	If (A_Gui = "leveltracker_button")
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
				IniDelete, ini\leveling tracker.ini, gear, % vars.leveltracker.gear[A_Index]
				IniDelete, ini\leveling tracker.ini, gems, % vars.leveltracker.gear[A_Index]
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
			Clipboard := """" SubStr(check, (InStr(check, ":") ? InStr(check, ": ") + 2 : InStr(check, " ") + 1)) """"
			WinActivate, ahk_group poe_window
			WinWaitActive, ahk_group poe_window
			SendInput, ^{f}
			Sleep 100
			SendInput, ^{v}{Enter}
			Return
		}
		Else If (vars.system.click = 2) && LLK_Progress(vars.hwnd.geartracker["delbar_"control], "RButton")
		{
			IniDelete, ini\leveling tracker.ini, gear, % control
			IniDelete, ini\leveling tracker.ini, gems, % control
			vars.leveltracker.gear.Delete(LLK_HasVal(vars.leveltracker.gear, control))
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

	If (vars.omnikey.item.rarity != "unique") && !InStr(vars.omnikey.item.name, "flask")
		class := SubStr(vars.omnikey.item.class, InStr(vars.omnikey.item.class, " ",,, LLK_InStrCount(vars.omnikey.item.class, " ")) + 1), class := InStr("boots,gloves", class) ? class : SubStr(class, 1, -1)

	If !vars.omnikey.item.lvl_req
		error := ["gear-tracker:`nno lvl requirement", 2, "red"]
	Else If (vars.omnikey.item.lvl_req < vars.log.level)
		error := ["gear-tracker:`nalready equippable", 2, "yellow"]
	Else If LLK_HasVal(vars.leveltracker.gear, "("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name)
		error := ["gear-tracker:`nitem already added", 2, "red"]

	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3)
		Return
	}
	Else LLK_ToolTip("gear-tracker:`nitem added", 1.5,,,, "lime")
	vars.leveltracker.gear.Push("("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name)
	vars.leveltracker.gear := LLK_ArraySort(vars.leveltracker.gear)
	IniWrite, 1, ini\leveling tracker.ini, gear, % "("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name
	GeartrackerGUI()
}

GeartrackerGUI(mode := "")
{
	local
	global vars, settings

	If (mode = "toggle") && WinExist("ahk_id "vars.hwnd.geartracker.main)
		LLK_Overlay(vars.hwnd.geartracker.main, "hide")
	Else
	{
		Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDgeartracker", geartracker
		Gui, %geartracker%: Color, Black
		Gui, %geartracker%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/8
		Gui, %geartracker%: Font, % "s" settings.leveltracker.fSize " cWhite", Fontin SmallCaps
		hwnd_old := vars.hwnd.geartracker.main, vars.hwnd.geartracker := {"main": geartracker}

		Gui, %geartracker%: Add, Text, % "Section"(Blank(settings.general.character) || !vars.log.level ? " cRed" : ""), % "char (lvl): "(Blank(settings.general.character) ? "unknown" : settings.general.character) " ("vars.log.level ")"
		Gui, %geartracker%: Font, % "s" settings.leveltracker.fSize - 2
		Gui, %geartracker%: Add, Pic, % "ys hp w-1 HWNDhwnd0", img\GUI\help.png
		Gui, %geartracker%: Add, Checkbox, % "xs Section gGeartracker HWNDhwnd checked"vars.leveltracker.gearfilter, only show next 5 lvls
		vars.hwnd.geartracker.filter := hwnd, vars.hwnd.help_tooltips["geartracker_about"] := hwnd0
		ControlGetPos, x0, y0, w0, h0,, % "ahk_id "hwnd
		Gui, %geartracker%: Font, % "s" settings.leveltracker.fSize

		;If !Blank(settings.general.character)
			For index, item in vars.leveltracker.gear
			{
				If vars.leveltracker.gearfilter && (SubStr(item, 2, 2) > vars.log.level + 5)
					Continue
				color := (SubStr(item, 2, 2) <= vars.log.level) ? " cLime" : ""
				count += color ? 1 : 0
				If (y + h >= vars.client.h*0.85)
					Continue
				Gui, %geartracker%: Add, Text, % "xs BackgroundTrans gGeartracker HWNDhwnd Section"(A_Index = 1 ? " y+"settings.leveltracker.fHeight*0.25 : "") color, % item
				vars.hwnd.geartracker["select_"item] := hwnd
				Gui, %geartracker%: Add, Progress, % "xp yp wp hp BackgroundBlack cRed Disabled HWNDhwnd range0-500", 0
				vars.hwnd.geartracker["delbar_"item] := hwnd
				ControlGetPos, x, y, w, h,, % "ahk_id "hwnd
			}
		count := !count ? 0 : count, vars.leveltracker.gear_ready := count
		If count
		{
			Gui, %geartracker%: Font, % "s" settings.leveltracker.fSize - 2
			Gui, %geartracker%: Add, Text, % "x"x0 + w0 " y"y0 " h"h0 " Border BackgroundTrans gGeartracker HWNDhwnd cLime", % " clear "
			vars.hwnd.geartracker["clear"] := hwnd
			Gui, %geartracker%: Add, Progress, % "xp yp wp hp Border BackgroundBlack cRed Disabled HWNDhwnd range0-500", 0
			vars.hwnd.geartracker["delbar_clear"] := hwnd
		}
		Gui, %geartracker%: Show, % "NA x10000 y10000"
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.geartracker.main
		Gui, %geartracker%: Show, % (mode = "refresh" ? "Hide" : "NA") " x"vars.client.xc - w//2 " y"vars.client.y + vars.client.h - h
		If (mode != "refresh")
			LLK_Overlay(vars.hwnd.geartracker.main, "show")
		LLK_Overlay(hwnd_old, "destroy")
	}
}

Leveltracker(cHWND := "")
{
	local
	global vars, settings, Json, db
	
	If vars.leveltracker.fast ;block any input during fast-forwarding
		Return
	check := LLK_HasVal(vars.hwnd.leveltracker, cHWND)
	If InStr(check, "dummy")
		Return

	If InStr("+-", cHWND) || check || (A_Gui = DummyGUI(vars.hwnd.settings.main))
	{
		guide := vars.leveltracker.guide ;short-cut variable
		If (check = "+" || cHWND = "+") ;clicking the forward button
		{
			If (guide.group1[guide.group1.Count()] = guide.import[guide.import.Count()]) ;end-of-guide reached, can't go further
			{
				Gui, % vars.hwnd.leveltracker.controls2 ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip("can't go further",, vars.client.xc, vars.leveltracker.y - settings.general.fHeight + 1,, "yellow",,,, 1)
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
				Gui, % vars.hwnd.leveltracker.controls2 ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip("can't fast-forward to current location", 2, vars.client.xc , vars.leveltracker.y - settings.general.fHeight + 1,, "red",,,, 1)
				vars.leveltracker.fast := 0
				KeyWait, LButton
				Return
			}
			Else If (loop = 1000)
				Gui, % vars.hwnd.leveltracker.controls1 ": Color", Red
			Loop, % loop
			{
				For step_index, step in guide.group1
				{
					guide.progress.Push(step)
					IniWrite, % step, ini\leveling guide.ini, progress, % "step_"guide.progress.MaxIndex()
				}
				LeveltrackerProgress()
				If LLK_HasVal(guide.group1, "an_end_to_hunger", 1) || (guide.target_area = vars.log.areaID)
					Break
			}
			vars.leveltracker.fast := 0, vars.leveltracker.last_manual := A_TickCount
			If (loop = 1000) ;band-aid fix to override the grace-period from manually switching guide pages
				vars.leveltracker.last_manual := A_TickCount - 30000
			If WinExist("ahk_id "vars.hwnd.settings.main) && (vars.settings.active = "leveling tracker")
				Settings_menu("leveling tracker")
			KeyWait, LButton
			Return
		}
		If (check = "-" || cHWND = "-") ;clicking the backward button
		{
			If !guide.progress.Count() ;guide-start reached, can't to further
			{
				Gui, % vars.hwnd.leveltracker.controls2 ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip("can't go further",, vars.client.xc, vars.leveltracker.y - settings.general.fHeight + 1,, "yellow",,,, 1)
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
				IniDelete, ini\leveling guide.ini, progress, % "step_"guide.progress.MaxIndex()
				vars.leveltracker.guide.progress.Pop()
			}
			LeveltrackerProgress()
			vars.leveltracker.last_manual := A_TickCount
			KeyWait, LButton
			Return
		}
		LeveltrackerProgress()
	}

	If (A_Gui != "leveltracker_button")
		Return
	
	If (vars.system.click = 2)
	{
		If settings.leveltracker.geartracker
			Geartracker()
		Return
	}
	If settings.leveltracker.geartracker && Blank(vars.leveltracker.gear_ready)
		GeartrackerGUI("refresh")
	start := A_TickCount
	While GetKeyState("LButton", "P") && (A_Gui = "leveltracker_button") ;dragging the button
	{
		If (A_TickCount >= start + 250)
		{
			WinGetPos,,, width, height, % "ahk_id " vars.hwnd.leveltracker_button.main
			While GetKeyState("LButton", "P")
			{
				LLK_Drag(width, height, xPos, yPos)
				sleep 1
			}
			KeyWait, LButton
			WinActivate, ahk_group poe_window
			settings.leveltracker.xButton := xPos, settings.leveltracker.yButton := yPos
			IniWrite, % settings.leveltracker.xButton, ini\leveling tracker.ini, UI, button xcoord
			IniWrite, % settings.leveltracker.yButton, ini\leveling tracker.ini, UI, button ycoord
			Return
		}
	}

	If !vars.hwnd.leveltracker.main
	{
		If !IsObject(vars.leveltracker.guide.import)
			LeveltrackerLoad()
		If !vars.leveltracker.guide.import.Count()
		{
			LLK_ToolTip("no import-data",,,,, "red")
			vars.leveltracker.Delete("guide")
			Return
		}
		LeveltrackerProgress()
		Init_GUI("leveltracker")
	}
	Else If !WinExist("ahk_id "vars.hwnd.leveltracker.main)
		LeveltrackerProgress()
	Else
	{
		LLK_Overlay(vars.hwnd.leveltracker.main, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker.background, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker.controls2, "destroy") ;destroy controls2 first because it's owned by controls1
		LLK_Overlay(vars.hwnd.leveltracker.controls1, "destroy")
		LLK_Overlay(vars.hwnd.leveltracker_timer.main, "destroy")
		LLK_Overlay(vars.hwnd.geartracker.main, "destroy")
	}
	WinActivate, ahk_group poe_window
}

LeveltrackerExperience(arealevel := "")
{
	local
	global vars, settings
	
	If (vars.log.level = 0)
		Return ""

	arealevel := !arealevel ? vars.log.arealevel : arealevel, exp_penalty := {95: 1.069518717, 96: 1.129943503, 97: 1.2300123, 98: 1.393728223, 99: 1.666666667}
	If (vars.log.level > 94)
		exp_penalty := (1/(1 + 0.1 * (vars.log.level - 94))) * (1/exp_penalty[vars.log.level])
	Else exp_penalty := 1

	If (arealevel > 70)
		arealevel := (-0.03) * (arealevel**2) + (5.17 * arealevel) - 144.9

	safezone := Floor(3 + (vars.log.level/16))
	effective_difference := Max(Abs(vars.log.level - arealevel) - safezone, 0), effective_difference := effective_difference**2.5
	exp_multi := (vars.log.level + 5) / (vars.log.level + 5 + effective_difference), exp_multi := exp_multi**1.5
	exp_multi := Max(exp_multi * exp_penalty, 0.01)
	Return Format("{:0." . (exp_multi = 1 ? "0" : "1") . "f}", exp_multi*100) "%"
}

LeveltrackerFade()
{
	local
	global vars, settings

	If settings.leveltracker.fade && (WinGet("transparent", "ahk_id "vars.hwnd.leveltracker.main) != 25) && (vars.leveltracker.last + settings.leveltracker.fadetime <= A_TickCount) && WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& (!LLK_IsBetween(vars.general.xMouse, vars.leveltracker.x, vars.leveltracker.x + vars.leveltracker.w) || !LLK_IsBetween(vars.general.yMouse, vars.leveltracker.y, vars.leveltracker.y + vars.leveltracker.h + vars.leveltracker.h2))
	&& !vars.leveltracker.overlays && !InStr(vars.log.areaID, "_town")
	{
		WinSet, Trans, 25, % "ahk_id "vars.hwnd.leveltracker.main
		WinSet, Trans, 25, % "ahk_id "vars.hwnd.leveltracker.background
		WinSet, Trans, 25, % "ahk_id "vars.hwnd.leveltracker.controls1
		WinSet, Trans, 25, % "ahk_id "vars.hwnd.leveltracker.controls2
		vars.leveltracker.fade := 1
	}
	Else If settings.leveltracker.fade && (WinGet("transparent", "ahk_id "vars.hwnd.leveltracker.main) = 25) && WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& ((settings.leveltracker.fade_hover && LLK_IsBetween(vars.general.xMouse, vars.leveltracker.x, vars.leveltracker.x + vars.leveltracker.w) && LLK_IsBetween(vars.general.yMouse, vars.leveltracker.y, vars.leveltracker.y + vars.leveltracker.h + vars.leveltracker.h2)
	&& !GetKeyState(settings.hotkeys.movekey, "P")) || vars.leveltracker.overlays || InStr(vars.log.areaID, "_town"))
	{
		WinSet, Trans, Off, % "ahk_id "vars.hwnd.leveltracker.main
		WinSet, TransColor, Black, % "ahk_id "vars.hwnd.leveltracker.main
		WinSet, Trans, % settings.leveltracker.trans, % "ahk_id "vars.hwnd.leveltracker.background
		WinSet, Trans, 140, % "ahk_id "vars.hwnd.leveltracker.controls1
		WinSet, Trans, Off, % "ahk_id "vars.hwnd.leveltracker.controls2
		WinSet, TransColor, Black, % "ahk_id "vars.hwnd.leveltracker.controls2
		vars.leveltracker.fade := 0
	}
}

LeveltrackerHints()
{
	local
	global vars, settings

	If !settings.leveltracker.hints || !LLK_HasVal(vars.leveltracker.guide.group1, "(hint)", 1)
		Return
	Gui, New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDleveltracker_hints
	Gui, %leveltracker_hints%: Color, Black
	Gui, %leveltracker_hints%: Margin, 0, 0
	Gui, %leveltracker_hints%: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps

	Loop, Files, img\GUI\leveling tracker\hints\*.jpg
		If LLK_HasVal(vars.leveltracker.guide.group1, StrReplace(A_LoopFileName, ".jpg"), 1)
		{
			Gui, %leveltracker_hints%: Add, Pic, % "w"vars.leveltracker.w - 2 " h-1", % A_LoopFileLongPath
			Break
		}

	Gui, %leveltracker_hints%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %leveltracker_hints%
	Gui, %leveltracker_hints%: Show, % "NA x"vars.leveltracker.x " y"vars.leveltracker.y - h + 1
	KeyWait, % settings.hotkeys.tab
	Gui, %leveltracker_hints%: Destroy
}

LeveltrackerImport()
{
	local
	global vars, settings, Json

	KeyWait, LButton
	If (SubStr(Clipboard, 1, 2) != "[{") || !InStr(Clipboard, """enter""")
	{
		LLK_ToolTip("invalid import data",,,,, "red")
		Return
	}

	import := Json.Load(Clipboard), areas := LLK_FileRead("data\leveling tracker\areas.json"), gems := LLK_FileRead("data\leveling tracker\gems.json"), quests := LLK_FileRead("data\leveling tracker\quests.json")
	areas := Json.Load(areas), gems := Json.Load(gems), quests := Json.Load(quests)

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
									MsgBox, % "unknown type: "part.type
								Else
								{
									LLK_ToolTip("incompatible guide-data,`nupdate required", 2,,,, "red")
									Return
								}
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
								ss_text .= """" ss_parts.value """"
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
	IniDelete, ini\leveling tracker.ini, Gem notes
	If gem_notes
	{
		StringLower, gem_notes, gem_notes
		gem_notes := StrReplace(gem_notes, "&", "&&")
		IniWrite, % gem_notes, ini\leveling tracker.ini, Gem notes
	}
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int build_gems_none ;create single gem-string for gear tracker feature
	
	IniDelete, ini\leveling tracker.ini, Gems
	IniDelete, ini\search-strings.ini, 00-exile leveling gems
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
		IniWrite, % SubStr(build_gems_all, 1, -1), ini\leveling tracker.ini, Gems ;save gems for gear tracker feature
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
			parse_gem := SubStr(A_Loopfield, 5)
			IniRead, gem_regex, data\leveling tracker\gems.ini, % parse_gem, regex, % A_Space
			If !gem_regex
				gem_regex := parse_gem
			gem_regex := StrReplace(gem_regex, " ", "\s")
			
			If (StrLen(parse_string gem_regex) <= 47)
				parse_string .= gem_regex "|"
			Else
			{
				search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ");"
				parse_string := gem_regex "|"
			}
		}
		search_string_%loop% .= "^(" SubStr(parse_string, 1, -1) ")"
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
		IniWrite, % """" StrReplace(search_string_all, ";", " " ";`;`;" " ") """", ini\search-strings.ini, hideout lilly, 00-exile leveling gems ;escaped semi-colons to prevent VScode from list this line as a module
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
	IniDelete, ini\leveling guide.ini, Steps
	IniWrite, % guide_text, ini\leveling guide.ini, Steps
	
	Settings_menu("leveling tracker")
	LLK_ToolTip("success",,,,, "Lime")
	Init_leveltracker()
	If settings.leveltracker.geartracker
		GeartrackerGUI("refresh")
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
	Loop, Parse, % LLK_IniRead("ini\leveling guide.ini", "steps"), `n
		vars.leveltracker.guide.import.Push(A_LoopField)

	Loop, Parse, % LLK_IniRead("ini\leveling guide.ini", "progress"), `n
	{
		vars.leveltracker.guide.progress.Push(SubStr(A_LoopField, InStr(A_LoopField, "=") + 1))
		check += !InStr(A_LoopField, "=") ? 1 : 0
	}

	Loop, Parse, % LLK_IniRead("ini\leveling tracker.ini", "gem notes"), `n
		vars.leveltracker.guide.gem_notes[SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)] := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)

	If check
		MsgBox, % "Old progress-data detected.`n`nThere is a high chance this data is incompatible with the current version of the tracker.`n`nYou should go to the settings-menu and reset your progress."
}

LeveltrackerOverlays()
{
	local
	global vars, settings

	vars.leveltracker.overlays := 1
	If settings.leveltracker.timer && !vars.leveltracker.wait
		LeveltrackerTimerGUI()
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
		FileDelete, % "img\GUI\skill-tree\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "].png", 100)
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
			FileDelete, % "img\GUI\skill-tree\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
			vars.leveltracker.screencap_active := (vars.leveltracker.screencap_active = control) ? "" : vars.leveltracker.screencap_active
		}
		Else Return
	}
	Else If (check = "delall")
	{
		If LLK_Progress(vars.hwnd.leveltracker_screencap.delbarall, "LButton")
		{
			Loop, Files, % "img\GUI\skill-tree\[*"
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
				LLK_ToolTip("invalid character: " A_LoopField, 2, x, y + h,, "red")
				Return
			}
		GuiControl, +cBlack, % vars.hwnd.leveltracker_screencap.caption
		GuiControl, movedraw, % vars.hwnd.leveltracker_screencap.caption
		FileMove, % "img\GUI\skill-tree\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]*", % "img\GUI\skill-tree\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]"(Blank(caption) ? "" : " ") caption ".*", 1
	}
	Else If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_screencap.main
		While GetKeyState("LButton", "P")
		{
			If (A_TickCount >= start + 100)
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
	
	Gui, % vars.hwnd.leveltracker_screencap.main ": Destroy"
	vars.leveltracker.Delete("screencap_active")
	If !Blank(vars.hwnd.settings.main)
		LLK_Overlay(vars.hwnd.settings.main, "show")
	If WinExist("ahk_id "vars.hwnd.snip.main)
		SnipGuiClose()
}

LeveltrackerScreencapMenu()
{
	local
	global vars, settings
	
	active := vars.leveltracker.screencap_active
	If WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main)
		WinGetPos, xPos, yPos, Width, Height, % "ahk_id "vars.hwnd.leveltracker_screencap.main
	If !Blank(vars.hwnd.settings.main)
		LLK_Overlay(vars.hwnd.settings.main, "hide")
	Gui, New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_screencap
	Gui, %leveltracker_screencap%: Color, Black
	Gui, %leveltracker_screencap%: Margin, % settings.general.fWidth/2, % settings.general.fHeight/8
	Gui, %leveltracker_screencap%: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	hwnd_old := WinExist("ahk_id "vars.hwnd.leveltracker_screencap.main) ? vars.hwnd.leveltracker_screencap.main : "", vars.hwnd.leveltracker_screencap := {"main": leveltracker_screencap}

	Gui, %leveltracker_screencap%: Add, Text, % "x-1 y-1 Border Hidden Center Section gLeveltrackerScreencapMenu2 HWNDhwnd", % "skilltree-overlay config"
	vars.hwnd.leveltracker_screencap.winbar := hwnd
	Gui, %leveltracker_screencap%: Add, Text, % "ys x+-1 Border Hidden Center gLeveltrackerScreencapMenuClose HWNDhwnd w"settings.general.fWidth*2, % "x"
	vars.hwnd.leveltracker_screencap.winx := hwnd

	files := 0
	Loop, 99
	{
		If FileExist("img\GUI\skill-tree\[0" A_Index "]*") || FileExist("img\GUI\skill-tree\["A_Index "]*")
			files := (A_Index < 10 ? "0" : "") A_Index
	}
	
	Gui, %leveltracker_screencap%: Font, % "bold underline s"settings.general.fSize
	Gui, %leveltracker_screencap%: Add, Text, % "xs Section HWNDanchor x"settings.general.fWidth/2, % "skill-tree:"
	Gui, %leveltracker_screencap%: Font, norm
	Gui, %leveltracker_screencap%: Add, Picture, % "ys hp w-1 HWNDhwnd", img\GUI\help.png
	vars.hwnd.help_tooltips["leveltracker_skilltree-cap about"] := hwnd

	Loop, % files + 1
	{
		index := (A_Index < 10) ? "0" . A_Index : A_Index, wButtons := (A_Index = active) ? 0 : wButtons
		color := (index = vars.leveltracker.screencap_active) ? " cFuchsia" : !FileExist("img\GUI\skill-tree\["index "]*") ? " cGray" : ""
		Gui, %leveltracker_screencap%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree\["index "]*") ? "" : " Border gLeveltrackerScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 (A_Index = files + 1 ? " cLime" : color), % index
		vars.hwnd.leveltracker_screencap["select_"index] := hwnd
		If FileExist("img\GUI\skill-tree\["index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " paste "
		vars.hwnd.leveltracker_screencap["paste_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " snip "
		vars.hwnd.leveltracker_screencap["snip_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (A_Index = files + 1) && (A_Index != 1)
		{
			Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2 Center w"wButtons2 + settings.general.fWidth/4, % " del all "
			Gui, %leveltracker_screencap%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
			vars.hwnd.leveltracker_screencap.delall := hwnd0, vars.hwnd.leveltracker_screencap.delbarall := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete-all"] := hwnd
		}

		If !FileExist("img\GUI\skill-tree\["index "]*")
			Continue
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " show "
		vars.hwnd.leveltracker_screencap["preview_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 := LLK_ControlGetPos(hwnd, "w")
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2", % " del "
		Gui, %leveltracker_screencap%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_"index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 += LLK_ControlGetPos(hwnd, "w"), handle .= "|"
		If (active = index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %leveltracker_screencap%: Font, % "s"settings.general.fSize - 4
			Gui, %leveltracker_screencap%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltrackerScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %leveltracker_screencap%: Font, % "s"settings.general.fSize
		}
	}

	Gui, %leveltracker_screencap%: Font, bold underline
	Gui, %leveltracker_screencap%: Add, Text, % "xs Section y+"settings.general.fHeight*0.8, % "ascendancy-tree:"
	Gui, %leveltracker_screencap%: Add, Picture, % "ys hp w-1 HWNDhwnd69", img\GUI\help.png
	Gui, %leveltracker_screencap%: Font, norm
	Loop 5
	{
		vars.hwnd.help_tooltips["leveltracker_skilltree-cap ascend"] := hwnd69, index := "0"A_Index, color := (active = -A_Index) ? " cFuchsia" : !FileExist("img\GUI\skill-tree\[lab"A_Index "]*") ? " cGray" : "", wButtons := (-A_Index = active) ? 0 : wButtons
		Gui, %leveltracker_screencap%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree\[lab"A_Index "]*") ? " " : " Border gLeveltrackerScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 color, % index
		vars.hwnd.leveltracker_screencap["select_-"A_Index] := hwnd, handle .= "|"
		If FileExist("img\GUI\skill-tree\[lab"A_Index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " paste "
		vars.hwnd.leveltracker_screencap["paste_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " snip "
		vars.hwnd.leveltracker_screencap["snip_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If !FileExist("img\GUI\skill-tree\[lab"A_Index "]*")
			Continue
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltrackerScreencapMenu2 HWNDhwnd", % " show "
		vars.hwnd.leveltracker_screencap["preview_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %leveltracker_screencap%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltrackerScreencapMenu2", % " del "
		Gui, %leveltracker_screencap%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_-"A_Index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (active = -A_Index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %leveltracker_screencap%: Font, % "s"settings.general.fSize - 4
			Gui, %leveltracker_screencap%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltrackerScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %leveltracker_screencap%: Font, % "s"settings.general.fSize
		}
	}
	Gui, %leveltracker_screencap%: Add, Button, % "x0 y0 wp hp "(Blank(active) ? "" : " gLeveltrackerScreencapMenu2") " Hidden Default HWNDhwnd", % ok
	vars.hwnd.leveltracker_screencap.add := hwnd
	ControlFocus,, % "ahk_id " anchor
	Gui, %leveltracker_screencap%: Show, NA x10000 y10000
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_screencap.main
	ControlMove,,,, w - settings.general.fWidth*2 + 1,, % "ahk_id "vars.hwnd.leveltracker_screencap.winbar
	GuiControl, -Hidden, % vars.hwnd.leveltracker_screencap.winbar
	ControlMove,, w - settings.general.fWidth*2,,,, % "ahk_id "vars.hwnd.leveltracker_screencap.winx
	GuiControl, -Hidden, % vars.hwnd.leveltracker_screencap.winx
	Sleep 50
	If !Blank(xPos)
		xPos := (xPos + w > vars.monitor.x + vars.monitor.w) ? vars.monitor.x + vars.monitor.w - w : xPos, yPos := (yPos + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : yPos
	Gui, %leveltracker_screencap%: Show, % "x"(Blank(xPos) ? (A_Gui ? vars.client.x : vars.monitor.x) : xPos) " y"(Blank(xPos) ? vars.client.yc - h//2 : yPos)
	If hwnd_old
		Gui, %hwnd_old%: Destroy

	KeyWait, MButton
}

LeveltrackerProgress(mode := 0) ;advances the guide and redraws the overlay
{
	local
	global vars, settings, db
	static in_progress
	
	If in_progress
		Return

	vars.leveltracker.guide.text_raw := vars.leveltracker.guide.import.Clone(), in_progress := 1, vars.leveltracker.last := A_TickCount*100 ;dummy-value to prevent Loop_main() from prematurely fading the overlay
	guide := vars.leveltracker.guide, areas := db.leveltracker.areas ;short-cut variables
	For progress_index, step in guide.progress
	{
		If LLK_HasVal(guide.text_raw, step)
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

	Gui, New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_back"
	Gui, %leveltracker_back%: Color, Black
	Gui, %leveltracker_back%: Margin, % settings.general.fWidth, 0
	WinSet, Transparent, % mode && vars.leveltracker.fade ? 25 : settings.leveltracker.trans
	hwnd_old := vars.hwnd.leveltracker.main, hwnd_old1 := vars.hwnd.leveltracker.background, hwnd_old2 := vars.hwnd.leveltracker.controls2, hwnd_old3 := vars.hwnd.leveltracker.controls1
	vars.hwnd.leveltracker := {"background": leveltracker_back}

	Gui, New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_main +Owner"vars.hwnd.leveltracker.background
	Gui, %leveltracker_main%: Color, Black
	Gui, %leveltracker_main%: Margin, % settings.general.fWidth, 0
	If mode && vars.leveltracker.fade
		WinSet, Transparent, 25
	Else WinSet, TransColor, Black
	Gui, %leveltracker_main%: Font, % "s"settings.leveltracker.fSize " cWhite", Fontin SmallCaps
	vars.hwnd.leveltracker.main := leveltracker_main
	
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
			Gui, %leveltracker_main%: Add, Text, % style, % "buy " (LLK_HasVal(guide.group1, "buy item", 1) ? "items" : "gems") " (highlight: hold omni-key)"
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
				Gui, %leveltracker_main%: Add, Picture, % style (A_Index = 1 ? "" : " x+"(InStr(step, "(hint)") ? 0 : settings.leveltracker.fWidth/2)) " BackgroundTrans "(InStr(step, "(hint)") ? "hp-2" : "h" settings.leveltracker.fHeight - 2) " w-1", % "img\GUI\leveling tracker\"img ".png"
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
					Gui, %leveltracker_main%: Font, % "s"settings.leveltracker.fSize - 2
				Gui, %leveltracker_main%: Add, Text, % style " c"color, % (index = text_parts.MaxIndex()) || (text_parts[index + 1] = ",") || InStr(text_parts[index + 1], "(img:") ? text : text " "
				Gui, %leveltracker_main%: Font, % "s"settings.leveltracker.fSize
				kill := (part = "kill") ? 1 : 0
			}
			style := InStr(part, "(img:") ? "ys x+"settings.leveltracker.fWidth/4 : "ys x+0"
		}
		If InStr(step, "(hint)")
			Loop, Files, img\GUI\leveling tracker\hints\*.jpg
				If InStr(step, StrReplace(A_LoopFileName, ".jpg"))
				{
					Gui, %leveltracker_main%: Add, Picture, % "ys hp w-1", img\GUI\help.png
					Break
				}
	}
	If (guide.gems.Count() || guide.items.Count())
		LeveltrackerStrings()

	vars.leveltracker.wait := 1 ;this stops the timer-GUI from being created before the main overlay has finished drawing
	Gui, %leveltracker_main%: Show, NA x10000 y10000
	WinGetPos, x, y, width, height, % "ahk_id "vars.hwnd.leveltracker.main
	While Mod(width, 2)
		width += 1
	height1 := vars.leveltracker.h2 := Floor(vars.client.h*0.022), wButtons := settings.leveltracker.fWidth*2
	While Mod(wButtons, 2)
		wButtons += 1
	wPanels := (width - wButtons*2)/2
	xPos := vars.client.xc - width/2, yPos := vars.client.y + vars.client.h
	
	Gui, %leveltracker_back%: Show, % "NA x"xPos " y"yPos - height - height1 - 1 " w"width - 2 " h"height
	Gui, %leveltracker_main%: Show, % "NA x"xPos " y"yPos - height - height1 - 1 " w"width - 2 " h"height
	WinGetPos, x, y, width, height, % "ahk_id " vars.hwnd.leveltracker.main
	vars.leveltracker.x := x, vars.leveltracker.y := y, vars.leveltracker.w := width, vars.leveltracker.h := height
	LLK_Overlay(vars.hwnd.leveltracker.background, "show"), LLK_Overlay(vars.hwnd.leveltracker.main, "show")
	LLK_Overlay(hwnd_old, "destroy"), LLK_Overlay(hwnd_old1, "destroy")

	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_controls1"
	Gui, %leveltracker_controls1%: Color, Black
	Gui, %leveltracker_controls1%: Margin, 0, 0
	WinSet, Transparent, % mode && vars.leveltracker.fade ? 25 : 140
	Gui, %leveltracker_controls1%: Font, % "s"settings.leveltracker.fSize " cWhite", Fontin SmallCaps
	vars.hwnd.leveltracker.controls1 := leveltracker_controls1
	Gui, %leveltracker_controls1%: Add, Text, % "Section 0x200 Border HWNDhwnd Center w"wPanels " h"height1, % ""
	vars.hwnd.leveltracker.dummy1 := hwnd
	Gui, %leveltracker_controls1%: Add, Text, % "ys hp 0x200 Border HWNDhwnd Center w"wButtons, % ""
	vars.hwnd.leveltracker["-"] := hwnd
	Gui, %leveltracker_controls1%: Add, Text, % "ys hp 0x200 Border HWNDhwnd Center w"wButtons, % ""
	vars.hwnd.leveltracker["+"] := hwnd, check := 0
	Gui, %leveltracker_controls1%: Add, Text, % "ys wp hp 0x200 Border HWNDhwnd Center w"wPanels, % ""
	vars.hwnd.leveltracker.dummy2 := hwnd

	If settings.leveltracker.layouts
		Loop, Files, % "img\GUI\leveling tracker\zones\" vars.log.areaID " *"
			check += 1

	Gui, New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_controls2 +Owner"vars.hwnd.leveltracker.controls1
	Gui, %leveltracker_controls2%: Color, Black
	Gui, %leveltracker_controls2%: Margin, 0, 0
	If mode && vars.leveltracker.fade
		WinSet, Transparent, 25
	Else WinSet, TransColor, Black
	vars.leveltracker.custom_font := !vars.leveltracker.custom_font ? LLK_FontSizeGet(height1, custom_fontwidth) : vars.leveltracker.custom_font
	vars.leveltracker.custom_fontwidth := custom_fontwidth ? custom_fontwidth : vars.leveltracker.custom_fontwidth
	Gui, %leveltracker_controls2%: Font, % "s"Min(settings.leveltracker.fSize, vars.leveltracker.custom_font) " cWhite", Fontin SmallCaps
	vars.hwnd.leveltracker.controls2 := leveltracker_controls2
	Gui, %leveltracker_controls2%: Add, Text, % "Section Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels " h"height1, % settings.leveltracker.layouts ? check " zl" : ""
	vars.hwnd.leveltracker.layouts := hwnd
	Gui, %leveltracker_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w"wButtons, % "<"
	Gui, %leveltracker_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w"wButtons, % ">"
	Gui, %leveltracker_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels, % LeveltrackerExperience()
	vars.hwnd.leveltracker.experience := hwnd

	Gui, %leveltracker_controls2%: Show, % "NA x"xPos " y"yPos - height1
	Gui, %leveltracker_controls1%: Show, % "NA x"xPos " y"yPos - height1
	LLK_Overlay(vars.hwnd.leveltracker.controls1, "show"), LLK_Overlay(vars.hwnd.leveltracker.controls2, "show")
	LLK_Overlay(hwnd_old2, "destroy"), LLK_Overlay(hwnd_old3, "destroy")
	vars.leveltracker.last := A_TickCount
	If settings.leveltracker.timer && (vars.leveltracker.timer.pause != 0)
		LeveltrackerTimerGUI()
	vars.leveltracker.wait := 0, in_progress := 0
}

LeveltrackerProgressReset()
{
	local
	global vars, settings

	IniDelete, ini\leveling guide.ini, Progress
	vars.leveltracker.guide.progress := []
	If WinExist("ahk_id "vars.hwnd.leveltracker.main)
		LeveltrackerProgress()
	If WinExist("ahk_id "vars.hwnd.settings.main)
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
			LLK_ToolTip("some of the clipboard-`nfiles are not supported", 2,,,, "red")
			Return
		}
		If InStr(Clipboard, ":\",,, 2)
		{
			If InStr(index, "-")
			{
				LLK_ToolTip("multi-paste not supported`nfor ascendancy-trees", 2,,,, "red")
				Return
			}
			MsgBox, 4, Clipboard multi-paste, % LLK_InStrCount(Clipboard, ":") " entries starting from "index " will potentially be overwritten.`nContinue?"
			IfMsgBox No
				Return
		}
		Loop, Parse, Clipboard, `n, `r
			FileCopy, % A_LoopField, % "img\GUI\skill-tree\["(index + A_Index - 1 < 10 ? "0" : "") index + A_Index - 1 "].*", 1
	}
	Else
	{
		pBitmap := Gdip_CreateBitmapFromClipboard()
		If (pBitmap < 0)
		{
			LLK_ToolTip("couldn't find image-`ndata in clipboard", 1.5,,,, "red")
			Return
		}
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree\["(InStr(index, "-") ? "lab" : "") StrReplace(index, "-") "].png", 100)
		Gdip_DisposeImage(pBitmap)
	}
	Return 1
}

LeveltrackerSkilltree(index := 0)
{
	local
	global vars, settings
	
	skilltree := vars.leveltracker.skilltree ;short-cut variable
	skilltree.files := [], skilltree.files_lab := []
	If !IsNumber(skilltree.active) || !FileExist("img\GUI\skill-tree\["skilltree.active "]*")
		skilltree.active := "00"
	index := index ? index : skilltree.active
	
	Loop, Files, img\GUI\skill-tree\[*]*
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
		Gui, New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree
		Gui, %leveltracker_skilltree%: Margin, 0, 0
		Gui, %leveltracker_skilltree%: Color, Black
		Gui, %leveltracker_skilltree%: Font, % "s"settings.general.fSize " cWhite", Fontin SmallCaps
		hwnd_old := WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.main) ? vars.hwnd.leveltracker_skilltree.main : "", hwnd_old1 := WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.labs) ? vars.hwnd.leveltracker_skilltree.labs : ""
		vars.hwnd.leveltracker_skilltree := {"main": leveltracker_skilltree}, count := 0

		Loop, Files, img\GUI\skill-tree\[*]*
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
			Gui, %leveltracker_skilltree%: Add, Picture, Border Section HWNDhwnd, % img
		Else Gui, %leveltracker_skilltree%: Add, Text, % "Section Center Border HWNDhwnd w"vars.monitor.h/4 " h"vars.monitor.h/4, couldn't find skill tree image-files
		Gui, %leveltracker_skilltree%: Add, Text, % "xs Section y+-1 wp Border BackgroundTrans Center"(!caption ? " h"settings.general.fHeight//2 : ""), % caption
		Gui, %leveltracker_skilltree%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack c404040 Center range0-"skilltree.files.Count(), % count
		Gui, %leveltracker_skilltree%: Show, % "NA x10000 y10000"
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.main
		Gui, %leveltracker_skilltree%: Show, % "NA x"vars.client.x " y"vars.client.yc - h//2
          skilltree.x := x, skilltree.y := y, skilltree.w := w, skilltree.h := h
		If hwnd_old
			Gui, %hwnd_old%: Destroy
		
		If Blank(A_Gui) && skilltree.files_lab.Count()
		{
			Gui, New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree_labs
			Gui, %leveltracker_skilltree_labs%: Margin, 0, 0
			Gui, %leveltracker_skilltree_labs%: Color, Black
			;WinSet, Transparent, 255
			vars.hwnd.leveltracker_skilltree.labs := leveltracker_skilltree_labs
			Loop, Files, img\GUI\skill-tree\[lab*]*
			{
				parse := SubStr(A_LoopFileName, InStr(A_LoopFileName, "[lab") + 4, 1)
				Gui, %leveltracker_skilltree_labs%: Add, Picture, % (A_Index = 1 ? "Section" : "xs") " BackgroundTrans w"vars.monitor.h//25 " h-1 HWNDhwnd", % "img\GUI\lab"parse ".png"
				vars.hwnd.leveltracker_skilltree["lab"parse] := hwnd
			}
			If skilltree.files_lab.Count()
			{
				;Gui, %leveltracker_skilltree_labs%: Show, % "NA x"vars.client.x + vars.client.w//2 - (skilltree.files_lab.Count()* vars.monitor.h//25)//2 " y"vars.client.y + vars.client.h - vars.monitor.h//25 - vars.client.h*0.0215
				Gui, %leveltracker_skilltree_labs%: Show, % "NA x10000 y10000"
				WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.labs
				Gui, %leveltracker_skilltree_labs%: Show, % "NA x"vars.client.x + skilltree.w + vars.client.w//250 " y"vars.client.yc - h//2
				If hwnd_old1
					Gui, %hwnd_old1%: Destroy
			}
		}
		If Blank(A_Gui) && !LeveltrackerSkilltreeHover()
			Return
		If !Blank(A_Gui)
			KeyWait, LButton
		KeyWait, % vars.omnikey.hotkey
		Gui, %leveltracker_skilltree%: Destroy
		If WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.labs)
			Gui, %leveltracker_skilltree_labs%: Destroy
		vars.hwnd.Delete("leveltracker_skilltree")
	}
	Else LLK_ToolTip("couldn't find image-files", 1.5,,,, "red")
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
				If (A_TickCount >= start + 200)
				{
					check := skilltree.active - 1, check := (check < 10 ? "0" : "") check
					Break
				}
			}
			If Blank(check)
				check := skilltree.active + 1, check := (check < 10 ? "0" : "") check
			If !FileExist("img\GUI\skill-tree\["check "]*")
			{
				WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.main
				LLK_ToolTip("can't go further",, x, y,, "yellow")
				KeyWait, RButton
				check := ""
				Continue
			}
			Else Break
		}

		If WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.labs) && WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab) && (vars.general.wMouse != DummyGUI(vars.hwnd.leveltracker_skilltree.labs))
			Gui, % vars.hwnd.leveltracker_skilltree.lab ": Destroy"
		HWNDcheck := LLK_HasVal(vars.hwnd.leveltracker_skilltree, vars.general.cMouse)
		If HWNDcheck && (!WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab) || lab_active != HWNDcheck)
		{
			LeveltrackerSkilltreeLab(HWNDcheck)
			lab_active := HWNDcheck
		}
	}
	If WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab)
		Gui, % vars.hwnd.leveltracker_skilltree.lab ": Destroy"
	If !Blank(check)
	{
		skilltree.active := check
		IniWrite, % skilltree.active, ini\leveling tracker.ini, settings, last skilltree-image
		SetTimer, LeveltrackerSkilltree, -100
		Return 0
	}
	Return 1
}

LeveltrackerSkilltreeLab(file)
{
	local
	global vars, settings

	skilltree := vars.leveltracker.skilltree
	Gui, New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_skilltree_lab
	Gui, %leveltracker_skilltree_lab%: Margin, 0, 0
	Gui, %leveltracker_skilltree_lab%: Color, Black
	Gui, %leveltracker_skilltree_lab%: Font, % "s"settings.general.fSize " cWhite", Fontin SmallCaps
	hwnd_old := WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab) ? vars.hwnd.leveltracker_skilltree.lab : "", vars.hwnd.leveltracker_skilltree.lab := leveltracker_skilltree_lab

	Loop, Files, % "img\GUI\skill-tree\[lab*]*"
		If (SubStr(A_LoopFileName, 2, 4) = file)
			image := A_LoopFilePath, caption := SubStr(StrReplace(A_LoopFileName, "."A_LoopFileExt), InStr(A_LoopFileName, "]") + 1), caption := StrReplace(caption, " ",,, 1)
	Gui, %leveltracker_skilltree_lab%: Add, Picture, % "Section BackgroundTrans Border", % image
	Gui, %leveltracker_skilltree_lab%: Add, Text, % "xs y+-1 wp Center BackgroundTrans Border"(!caption ? " h"settings.general.fHeight/2 : ""), % caption
	Gui, %leveltracker_skilltree_lab%: Add, Progress, % "xp yp wp hp BackgroundBlack c404040 Border", 0
	Gui, %leveltracker_skilltree_lab%: Show, % "NA x10000 y10000"
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.lab
	Gui, %leveltracker_skilltree_lab%: Show, % "NA x"vars.client.x + skilltree.w + 2*vars.client.w//250 + vars.monitor.h//25 " y"vars.client.yc - h//2
	If hwnd_old
		Gui, %hwnd_old%: Destroy
}

LeveltrackerStrings()
{
	local
	global vars, settings

	strings := [], string := ""
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
		regex := StrReplace(LLK_IniRead("data\leveling tracker\gems.ini", val, "regex"), " ", "\s")
		If LLK_HasVal(vars.leveltracker.guide.group1, "fixture_of_fate", 1)
		{
			attr := LLK_IniRead("data\leveling tracker\gems.ini", val, "attribute"), type := InStr(val, " support") ? "_supp" : ""
			If (StrLen(string_%attr%%type% "|" regex) > 47)
				strings_%attr%%type%.Push(string_%attr%%type%), string_%attr%%type% := regex
			Else string_%attr%%type% .= (Blank(string_%attr%%type%) ? "" : "|") regex
		}
		Else
		{
			If (StrLen(string_gems "|" regex) > 47)
				strings_gems.Push(string_gems), string_gems := regex
			Else string_gems .= (Blank(string_gems) ? "" : "|") regex
		}
	}
	If !Blank(string_gems)
		strings_gems.Push(string_gems)

	vars.leveltracker.string := []
	For key, val in strings
		vars.leveltracker.string.Push("^("val ")")

	If LLK_HasVal(vars.leveltracker.guide.group1, "fixture_of_fate", 1)
	{
		Loop, Parse, % "str,str_supp,dex,dex_supp,int,int_supp,none", `,
		{
			If !Blank(string_%A_LoopField%)
				strings_%A_LoopField%.Push(string_%A_LoopField%)
			For key, val in strings_%A_LoopField%
				vars.leveltracker.string.Push("^("val ")")
		}
	}
	Else
	{
		For key, val in strings_gems
			vars.leveltracker.string.Push("^("val ")")
	}
}

LeveltrackerTimer(cHWND := "")
{
	local
	global vars, settings, db
	
	timer := vars.leveltracker.timer
	If cHWND
	{
		check := LLK_HasVal(vars.hwnd.leveltracker_timer, cHWND), control := SubStr(check, InStr(check, "_") + 1)
		If InStr(check, "dummy")
			Return
		If (check = "pause") && (timer.current_act = 11)
			error := ["can't resume: run complete", 1.5, "yellow"]
		Else If (check = "resetbar") && (vars.log.areaID != "1_1_1")
			error := ["enter <twilight strand> to reset", 2, "red"]
		Else If (check = "resetbar") && !timer.pause
			error := ["pause timer first", 1, "red"]
		Else If (check = "pause") && settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")
			error := ["blocked by hideout-pause option", 2, "red"]

		If error
		{
			LLK_ToolTip(error.1, error.2, vars.client.xc, vars.leveltracker.y - settings.general.fHeight + 1,, error.3,,,, 1)
			WinActivate, ahk_group poe_window
			Return
		}

		If (check = "resetbar")
		{
			If LLK_Progress(vars.hwnd.leveltracker_timer.resetbar, "LButton")
			{
				LeveltrackerProgressReset()
				IniWrite, % "", ini\leveling tracker.ini, current run, name
				IniWrite, 0, ini\leveling tracker.ini, current run, time
				Loop 10
					IniWrite, % "", ini\leveling tracker.ini, current run, act %A_Index%
				vars.leveltracker.Delete("timer")
				Init_leveltracker()
				LeveltrackerTimerGUI()
				Return
			}
			Else Return
		}
		Else If (check = "pause") && (timer.current_act != 11)
		{
			If !InStr(timer.name, ",") && (vars.log.areaID = "1_1_1")
			{
				FormatTime, date,, ShortDate
				FormatTime, time,, Time
				timer.name := date ", " time
				IniWrite, % """"timer.name """", ini\leveling tracker.ini, current run, name
				new_run := 1
			}
			LLK_ToolTip(new_run ? "run started" : (timer.pause != 0) ? "timer resumed" : "timer paused",, "Center", vars.leveltracker.y - settings.general.fHeight + 1,, "lime")
			timer.pause := !timer.pause ? -1 : 0 ;-1 specifies a manual pause by the user (as opposed to automatic pause after logging in or -- if set up this way -- entering a hideout)
		}
		LeveltrackerTimerGUI()
		Return
	}

	If !settings.leveltracker.timer
		Return

	If vars.hwnd.leveltracker.main && (timer.pause = 1) && (db.leveltracker.areas.HasKey(vars.log.areaID) || InStr(vars.log.areaID, "labyrinth")) && (timer.current_act != 11) ;resume the timer after leaving a hideout (if it wasn't paused manually by the user)
		timer.pause := 0

	If WinExist("ahk_id "vars.hwnd.leveltracker.main) && (timer.pause != 0) && !WinExist("ahk_id "vars.hwnd.leveltracker_timer.main) && !vars.leveltracker.wait ;show the timer whenever it's paused
		LeveltrackerTimerGUI()
	Else If vars.hwnd.leveltracker.main && (timer.pause = 0) && WinExist("ahk_id "vars.hwnd.leveltracker_timer.main) && !vars.leveltracker.overlays ;hide it after unpausing
		LLK_Overlay(vars.hwnd.leveltracker_timer.main, "destroy")

	If vars.hwnd.leveltracker.main && (timer.pause = 0) ;advance the timer
	{
		timer.current_split += (timer.current_act = 11) ? 0 : 1, timer.pause := (settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")) || (timer.current_act = 11) ? 1 : 0
		If vars.log.act && (timer.current_act + 1 = vars.log.act) ;player enters the next act: save previous act's time, add it to total time, then reset it
		{
			IniWrite, % timer.current_split, ini\leveling tracker.ini, current run, % "act "timer.current_act
			If InStr(timer.name, ",")
				LeveltrackerTimerCSV()
			timer.total_time += timer.current_split, timer.current_act += 1, timer.current_split := (timer.current_act = 11) ? timer.current_split : 0
			IniWrite, % timer.current_split, ini\leveling tracker.ini, current run, time
		}
		Else If timer.current_split && !Mod(timer.current_split, 60) && (timer.current_split != LLK_IniRead("ini\leveling tracker.ini", "current run", "time", 0)) ;save current time every minute as backup for potential crashes
			IniWrite, % timer.current_split, ini\leveling tracker.ini, current run, time
		If vars.leveltracker.overlays && !vars.leveltracker.wait ;tab-hotkey is being held down: refresh the timer GUI every cycle
			LeveltrackerTimerGUI()
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

LeveltrackerTimerGUI()	
{
	local
	global vars, settings

	timer := vars.leveltracker.timer
	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_timer"
	Gui, %leveltracker_timer%: Color, Black
	Gui, %leveltracker_timer%: Margin, 0, 0
	;WinSet, TransColor, Black
	vars.leveltracker.custom_font := !vars.leveltracker.custom_font ? LLK_FontSizeGet(height1, custom_fontwidth) : vars.leveltracker.custom_font
	vars.leveltracker.custom_fontwidth := custom_fontwidth ? custom_fontwidth : vars.leveltracker.custom_fontwidth
	Gui, %leveltracker_timer%: Font, % "s"vars.leveltracker.custom_font " cWhite", Fontin SmallCaps	
	hwnd_old := vars.hwnd.leveltracker_timer.main, vars.hwnd.leveltracker_timer := {"main": leveltracker_timer}

	Gui, %leveltracker_timer%: Add, Text, % "Section BackgroundTrans Border Center 0x200 HWNDhwnd w"vars.leveltracker.custom_fontwidth*7 " h"vars.leveltracker.h2, total
	vars.hwnd.leveltracker_timer.reset := hwnd
	Gui, %leveltracker_timer%: Add, Progress, % "xp yp wp hp Border BackgroundBlack cRed HWNDhwnd Disabled range0-500", 0
	vars.hwnd.leveltracker_timer.resetbar := hwnd
	Gui, %leveltracker_timer%: Add, Text, % "ys Border Center 0x200 x+-1 HWNDhwnd hp w"vars.leveltracker.custom_fontwidth*8 . (timer.current_act = 11 ? " cLime" : timer.pause = -1 ? " cGray"  : ""), % FormatSeconds(timer.total_time + (timer.current_act = 11 ? 0 : timer.current_split), 0)
	vars.hwnd.leveltracker_timer.dummy1 := hwnd
	Gui, %leveltracker_timer%: Add, Text, % "ys wp hp Border Center 0x200 HWNDhwnd"(Mod(vars.leveltracker.w, 2) ? " x+-1" : "") . (timer.current_act = 11 ? " cLime" : timer.pause = -1 ? " cGray" : "") ;cont
	, % !timer.current_split ? "0:00" : FormatSeconds(timer.current_split, 0)
	vars.hwnd.leveltracker_timer.dummy2 := hwnd
	Gui, %leveltracker_timer%: Add, Text, % "ys Border Center 0x200 x+-1 HWNDhwnd hp w"vars.leveltracker.custom_fontwidth*7, % "act "(timer.current_act = 11 ? 10 : timer.current_act)
	vars.hwnd.leveltracker_timer.pause	:= hwnd

	Gui, %leveltracker_timer%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, ahk_id %leveltracker_timer%
	Gui, %leveltracker_timer%: Show, % "NA x"vars.client.xc - w/2 " y"vars.client.y + vars.client.h - vars.leveltracker.h2
	LLK_Overlay(vars.hwnd.leveltracker_timer.main, "show")
	LLK_Overlay(hwnd_old, "destroy")
}

LeveltrackerZoneLayouts(mode := 0, drag := 0, cHWND := "")
{
	local
	global vars, settings
	
	If !settings.leveltracker.layouts
		Return

	start := A_TickCount
	If (drag = 1)
		WinGetPos,,, width, height, % "ahk_id "vars.hwnd.leveltracker_zones.main
	While cHWND && (drag = 1) && GetKeyState("LButton", "P")
		If (A_TickCount >= start + 200)
		{
			longpress := 1
			LLK_Drag(width, height, x, y,, vars.hwnd.leveltracker_zones.main)
			Sleep 1
		}

	If cHWND && !longpress && (drag = 1)
	{
		settings.leveltracker.aLayouts := (settings.leveltracker.aLayouts = "vertical") ? "horizontal" : "vertical"
		IniWrite, % settings.leveltracker.aLayouts, ini\leveling tracker.ini, settings, zone-layouts arrangement
	}
	Else If cHWND && !longpress && (drag = 2)
		x := (settings.leveltracker.aLayouts = "vertical") ? 0 : "", y := (settings.leveltracker.aLayouts = "vertical") ? "" : 0
	
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
		If WinExist("ahk_id "vars.hwnd.leveltracker_zones.main)
			Gui, % vars.hwnd.leveltracker_zones.main ": Destroy"
		Return
	}

	Gui, New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_zones"
	Gui, %leveltracker_zones%: Color, Black
	Gui, %leveltracker_zones%: Margin, % Floor(vars.monitor.h/200), % Floor(vars.monitor.h/200)
	WinSet, TransColor, Black
	hwnd_old := vars.hwnd.leveltracker_zones.main, vars.hwnd.leveltracker_zones := {"main": leveltracker_zones}

	Loop, Files, % "img\GUI\leveling tracker\zones\" vars.log.areaID " *"
	{
		If (settings.leveltracker.aLayouts = "vertical")
			style := (vars.log.areaID = "2_7_4" && A_Index = 4) ? " ys Section" : (A_Index = 1) ? " Section" : " xs"
		Else style := (vars.log.areaID = "2_7_4" && A_Index = 4) ? " xs Section" : (A_Index = 1) ? " Section" : " ys"
		Gui, %leveltracker_zones%: Add, Picture, % "Border HWNDhwnd"style " w"vars.monitor.w/settings.leveltracker.sLayouts " h-1", % A_LoopFilePath
		vars.hwnd.leveltracker_zones[vars.log.areaID A_Index] := hwnd
	}
	If mode
		Gui, %leveltracker_zones%: Add, Picture, % "Border ys w"vars.monitor.w/Ceil(settings.leveltracker.sLayouts/2) " h-1", % "img\GUI\leveling tracker\zones\explanation.png"
	Gui, %leveltracker_zones%: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id "vars.hwnd.leveltracker_zones.main
	If IsNumber(settings.leveltracker.xLayouts)
		x := (settings.leveltracker.xLayouts > vars.monitor.w/2 - 1) ? settings.leveltracker.xLayouts - w + 1 : settings.leveltracker.xLayouts
	If IsNumber(settings.leveltracker.yLayouts)
		y := (settings.leveltracker.yLayouts > vars.monitor.h/2 - 1) ? settings.leveltracker.yLayouts - h + 1 : settings.leveltracker.yLayouts
	Gui, %leveltracker_zones%: Show, % "NA x"(IsNumber(x) ? vars.monitor.x + x : vars.client.xc - w/2) " y"(IsNumber(y) ? vars.monitor.y + y : vars.client.yc - h/2)
	LLK_Overlay(hwnd_old, "destroy")
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
	LeveltrackerZoneLayouts(hotkey = "MButton" ? 1 : 0)
	If (hotkey = "MButton")
	{
		KeyWait, MButton
		LeveltrackerZoneLayouts()
	}
	resizing := 0
}
