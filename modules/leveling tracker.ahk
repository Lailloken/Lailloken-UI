Init_leveltracker()
{
	local
	global vars, settings, db, Json

	If !FileExist("ini" vars.poe_version "\leveling tracker.ini")
		IniWrite, % "", % "ini" vars.poe_version "\leveling tracker.ini", settings

	If !IsObject(vars.hwnd.leveltracker)
		vars.hwnd.leveltracker := {}

	settings.features.leveltracker := LLK_IniRead("ini" vars.poe_version "\config.ini", "Features", "enable leveling guide", 0)
	settings.leveltracker := {}, ini := IniBatchRead("ini" vars.poe_version "\leveling tracker.ini")
	settings.leveltracker.profile := !Blank(check := ini.settings["profile"]) ? check : ""

	If !LLK_HasKey(ini, "current run" settings.leveltracker.profile)
	{
		IniWrite, % "", % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, name
		IniWrite, 0, % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, time
		Loop, % vars.poe_version ? 6 : 10
			IniWrite, % "", % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, act %A_Index%
	}

	If vars.poe_version
		vars.leveltracker.acts := ["1", "2", "3", "1c", "2c", "3c"]
	If !vars.leveltracker.hints
	{
		vars.leveltracker.hints := {}
		Loop, Files, % "img\GUI\leveling tracker\hints" vars.poe_version "\*.jpg"
			vars.leveltracker.hints[StrReplace(StrReplace(A_LoopFileName, "_", " "), ".jpg")] := 1
	}

	For index0, profile in ["", 2, 3]
	{
		If !FileExist("ini" vars.poe_version "\leveling guide" profile ".ini")
			Continue
		ini2 := IniBatchRead("ini" vars.poe_version "\leveling guide" profile ".ini")
		vars.leveltracker["PoB" profile] := {}
		For index, category in ["class", "ascendancies", (!vars.poe_version ? "bandit" : ""), "gems", "trees", "active tree"]
		{
			If !category
				Continue
			string := ini2.PoB[category]
			If StrLen(string)
				vars.leveltracker["pob" profile][category] := InStr("{}[]", SubStr(string, 1, 1) . SubStr(string, 0)) ? json.Load(string) : string
			Else If (category = "active tree") && vars.leveltracker["pob" profile].Count() && !StrLen(string)
				vars.leveltracker["pob" profile][category] := 1
		}
		
		settings.leveltracker["guide" profile] := {"info": ini2.info.Clone()}
		settings.leveltracker["guide" profile].info.leaguestart .= Blank(settings.leveltracker["guide" profile].info.leaguestart) ? 1 : ""
		settings.leveltracker["guide" profile].info.bandit .= Blank(settings.leveltracker["guide" profile].info.bandit) ? "none" : ""
	}

	If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile)
		FileCreateDir, % "img\GUI\skill-tree" settings.leveltracker.profile

	If vars.poe_version && !FileExist("img\GUI\skill-tree" settings.leveltracker.profile "\PoE 2\")
		FileCreateDir, % "img\GUI\skill-tree" settings.leveltracker.profile "\PoE 2\"

	settings.leveltracker.timer := vars.client.stream ? 0 : !Blank(check := ini.settings["enable timer"]) ? check : 0
	settings.leveltracker.pausetimer := !Blank(check := ini.settings["hideout pause"]) ? check : 0
	settings.leveltracker.fade := !Blank(check := ini.settings["enable fading"]) ? check : 0
	settings.leveltracker.fadetime := !Blank(check := ini.settings["fade-time"]) ? check : 5000
	settings.leveltracker.fade_hover := !Blank(check := ini.settings["show on hover"]) ? check : 1
	settings.leveltracker.geartracker := vars.client.stream || vars.poe_version ? 0 : !Blank(check := ini.settings["enable geartracker"]) ? check : 0
	settings.leveltracker.layouts := vars.client.stream || vars.poe_version ? 0 : !Blank(check := ini.settings["enable zone-layout overlay"]) ? check : 0
	settings.leveltracker.recommend := !vars.poe_version && !Blank(check := ini.settings["enable level recommendations"]) ? check : 0
	settings.leveltracker.hotkeys := !Blank(check := ini.settings["enable page hotkeys"]) ? check : vars.client.stream
	settings.leveltracker.hotkey_1 := !Blank(check := ini.settings["hotkey 1"]) ? check : "F3"
	settings.leveltracker.hotkey_2 := !Blank(check := ini.settings["hotkey 2"]) ? check : "F4"
	settings.leveltracker.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.leveltracker.fSize, font_height, font_width), settings.leveltracker.fHeight := font_height, settings.leveltracker.fWidth := font_width
	settings.leveltracker.fSize_editor := !Blank(check := ini.settings["font-size editor"]) ? check : settings.leveltracker.fSize
	LLK_FontDimensions(settings.leveltracker.fSize_editor, font_height, font_width), settings.leveltracker.fHeight_editor := font_height, settings.leveltracker.fWidth_editor := font_width
	settings.leveltracker.fSize_editor1 := !Blank(check := ini.settings["font-size editor text"]) ? check : settings.leveltracker.fSize
	settings.leveltracker.pobmanual := !Blank(check := ini.settings["manual pob-screencap"]) ? check : 0
	settings.leveltracker.pob := !Blank(check := ini.settings["enable pob-screencap"]) ? check : 0
	settings.leveltracker.trans := !Blank(check := ini.settings["transparency"]) ? check : 5
	settings.leveltracker.trans := (settings.leveltracker.trans > 5) ? 5 : settings.leveltracker.trans
	settings.leveltracker.xCoord := !Blank(check := ini.settings["x-coordinate"]) ? check : ""
	settings.leveltracker.yCoord := !Blank(check := ini.settings["y-coordinate"]) ? check : ""
	settings.leveltracker.xLayouts := !Blank(check := ini.settings["zone-layouts x"]) ? check : ""
	settings.leveltracker.yLayouts := !Blank(check := ini.settings["zone-layouts y"]) ? check : ""
	settings.leveltracker.sLayouts0 := settings.leveltracker.sLayouts := !Blank(check := ini.settings["zone-layouts size"]) ? check : 8
	settings.leveltracker.aLayouts := !Blank(check := ini.settings["zone-layouts arrangement"]) ? check : "vertical"

	If settings.leveltracker.hotkeys
	{
		Hotkey, If, WinActive("ahk_group poe_ahk_window") && vars.hwnd.leveltracker.main
		Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_1), Leveltracker_Hotkeys, On
		Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_2), Leveltracker_Hotkeys, On
	}

	vars.leveltracker.gearfilter := 1, vars.leveltracker.gear := []
	For key in ini["gear" settings.leveltracker.profile]
		parse .= (Blank(parse) ? "" : "`n") key
	For key in ini["gems" settings.leveltracker.profile]
		parse .= (Blank(parse) ? "" : "`n") key
	StringLower, parse, parse
	Sort, parse, D`n N P2
	Loop, Parse, parse, `n
	{
		If Blank(A_LoopField) || LLK_HasVal(vars.leveltracker.gear, A_LoopField)
			Continue
		vars.leveltracker.gear.Push(A_LoopField)
	}
	If settings.leveltracker.geartracker
		Geartracker_GUI("refresh")

	If !IsObject(vars.leveltracker.guide)
		vars.leveltracker.guide := {}

	vars.leveltracker.timer := {"name": ini["current run" settings.leveltracker.profile].name, "current_split": !Blank(check := ini["current run" settings.leveltracker.profile].time) ? check : 0, "current_act": 1, "total_time": 0, "pause": -1}, vars.leveltracker.timer.current_split0 := vars.leveltracker.timer.current_split
	Loop, % vars.poe_version ? 7 : 11
	{
		vars.leveltracker.timer.current_act := A_Index
		If Blank(check := ini["current run" settings.leveltracker.profile]["act " A_Index])
		{
			If vars.poe_version && (A_Index = 7)
				vars.leveltracker.timer.current_act := 11
			Break
		}
		vars.leveltracker.timer.total_time += check
	}
	vars.leveltracker.skilltree := {"active": !Blank(check := ini.settings["last skilltree-image" settings.leveltracker.profile]) ? check : "00"}
	vars.leveltracker.skilltree_schematics := {"active": !Blank(check := ini.settings["last skilltree-schematic" settings.leveltracker.profile]) ? check : "1"
		, "scale": !Blank(check2 := ini.settings["schematic scaling"]) ? check2 : 0}
}

Geartracker(mode := "")
{
	local
	global vars, settings

	If (mode = "toggle")
	{
		Geartracker_GUI("toggle")
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
				IniDelete, % "ini" vars.poe_version "\leveling tracker.ini", % "gear" settings.leveltracker.profile, % vars.leveltracker.gear[A_Index]
				IniDelete, % "ini" vars.poe_version "\leveling tracker.ini", % "gems" settings.leveltracker.profile, % vars.leveltracker.gear[A_Index]
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
			IniDelete, % "ini" vars.poe_version "\leveling tracker.ini", % "gear" settings.leveltracker.profile, % control
			IniDelete, % "ini" vars.poe_version "\leveling tracker.ini", % "gems" settings.leveltracker.profile, % control
			vars.leveltracker.gear.RemoveAt(LLK_HasVal(vars.leveltracker.gear, control))
		}
		Else Return
	}
	Else LLK_ToolTip("no action")
	Geartracker_GUI()
}

Geartracker_Add()
{
	local
	global vars, settings

	item := vars.omnikey.item
	If (item.rarity != Lang_Trans("items_unique")) && !InStr(item.name, "Flask", 1)
		class := SubStr(vars.omnikey.item.class_copy, InStr(vars.omnikey.item.class_copy, " ",,, LLK_InStrCount(vars.omnikey.item.class_copy, " ")) + 1), class := (settings.general.lang_client = "english") ? (InStr("boots,gloves", class) ? class : SubStr(class, 1, -1)) : class, class := LLK_StringCase(class)

	If !vars.omnikey.item.lvl_req
		error := [Lang_Trans("lvltracker_gearadd", 4), 2, "red"]
	Else If (vars.omnikey.item.lvl_req < vars.log.level)
		error := [Lang_Trans("lvltracker_gearadd", 3), 2, "yellow"]
	Else If !Blank(LLK_HasVal(vars.leveltracker.gear, "("vars.omnikey.item.lvl_req ") " (class ? class ": " : "") vars.omnikey.item.name_copy))
		error := [Lang_Trans("lvltracker_gearadd", 2), 1.5, "red"]

	If error
	{
		LLK_ToolTip(error.1, error.2,,,, error.3)
		Return
	}
	Else LLK_ToolTip(Lang_Trans("lvltracker_gearadd"), 1,,,, "lime")
	vars.leveltracker.gear.Push(LLK_StringCase("("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name_copy))
	vars.leveltracker.gear := LLK_ArraySort(vars.leveltracker.gear)
	IniWrite, 1, % "ini" vars.poe_version "\leveling tracker.ini", % "gear" settings.leveltracker.profile, % "("vars.omnikey.item.lvl_req ") "(class ? class ": " : "") vars.omnikey.item.name_copy
	Geartracker_GUI()
}

Geartracker_GUI(mode := "")
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

		Gui, %GUI_name%: Add, Text, % "Section"(Blank(settings.general.character) || !vars.log.level ? " cRed" : ""), % Lang_Trans("lvltracker_gearlist") " " (Blank(settings.general.character) ? "unknown" : settings.general.character) " (" vars.log.level ")"
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize - 2
		Gui, %GUI_name%: Add, Pic, % "ys hp w-1 HWNDhwnd0", % "HBitmap:*" vars.pics.global.help
		Gui, %GUI_name%: Add, Checkbox, % "xs Section gGeartracker HWNDhwnd checked"vars.leveltracker.gearfilter, % Lang_Trans("lvltracker_gear5levels")
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
	static yesno := {"0": "no", "1": "yes"}, bandits := ["none", "alira", "kraityn", "oak"]

	If (cHWND = "condition")
	{
		bandit := settings.leveltracker["guide" settings.leveltracker.profile].info.bandit
		If !(condition := vars.leveltracker.guide.import[hotkey].condition) || condition
		&& ((condition.1 = "league-start") && (LLK_HasVal(yesno, condition.2) = settings.leveltracker["guide" settings.leveltracker.profile].info.leaguestart)
			|| (condition.1 = "bandit") && LLK_HasVal(condition.2, bandit))
			Return 1
		Else Return 0
	}

	If vars.leveltracker.fast ;block any input during fast-forwarding
		Return

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	check := LLK_HasVal(vars.hwnd.leveltracker, cHWND), profile := settings.leveltracker.profile
	If InStr(check, "dummy")
		Return

	If InStr("+-", cHWND) || check || InStr(A_Gui, "settings_menu")
	{
		yTooltip := vars.leveltracker.coords.y1 - settings.general.fHeight + 1, yTooltip := (yTooltip < vars.monitor.y) ? vars.leveltracker.coords.y2 - 1 : yTooltip
		guide := vars.leveltracker.guide
		If (hotkey = 1 && check = "+") || (cHWND = "+") ;clicking the forward button
		{
			If (guide.group1[guide.group1.Count()] = guide.import[guide.import.Count()][guide.import[guide.import.Count()].Count()]) ;end-of-guide reached, can't go further
			{
				;Gui, % Gui_Name(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(Lang_Trans("lvltracker_endreached"),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "yellow",,,, 1)
				KeyWait, LButton
				Return
			}
			start := A_TickCount, loop := 1
			While (loop = 1) && (GetKeyState("LButton", "P") && (cHWND = vars.hwnd.leveltracker["+"]) || settings.leveltracker.hotkeys && settings.leveltracker.hotkey_2 && GetKeyState(settings.leveltracker.hotkey_2, "P"))
				If (A_TickCount >= start + 1000)
					loop := 1000, vars.leveltracker.fast := 1, area_check := db.leveltracker.areaIDs.HasKey(vars.log.areaID)

			If (loop = 1000) && area_check ;check the remainder of the guide to see if there's a step involving the current location
			{
				area_check := 0
				For index, val in vars.leveltracker.guide.import
				{
					If (index <= vars.leveltracker.guide.progress) || val.condition && !Leveltracker("condition", index)
						Continue
					For index, line in (val.condition ? val.lines : val)
						Loop, Parse, line, %A_Space%
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
				;Gui, % Gui_Name(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(Lang_Trans("lvltracker_fastforwarderror"), 3, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "red",,,, 1)
				vars.leveltracker.fast := 0
				KeyWait, LButton
				Return
			}
			Else If (loop = 1000)
				Gui, % Gui_Name(vars.hwnd.leveltracker.controls1) ": Color", Red

			Loop, % loop
			{
				guide.progress += 1
				While !Leveltracker("condition", guide.progress + 1)
					guide.progress += 1

				Leveltracker_Progress(1)
				If LLK_HasVal(guide.group1, "an_end_to_hunger", 1) || LLK_HasVal(guide.group1, "act-tracker", 1) || (guide.target_area = vars.log.areaID)
					Break
			}
			IniWrite, % guide.progress, % "ini" vars.poe_version "\leveling guide" settings.leveltracker.profile ".ini", progress, pages
			vars.leveltracker.fast := 0, vars.leveltracker.last_manual := A_TickCount
			If (loop = 1000) ;band-aid fix to override the grace-period from manually switching guide pages
				vars.leveltracker.last_manual := A_TickCount - 30000
			KeyWait, LButton
			Return
		}
		If (hotkey = 1 && check = "-") || (cHWND = "-") ;clicking the backward button
		{
			If !guide.progress ;guide-start reached, can't to further
			{
				;Gui, % Gui_Name(vars.hwnd.leveltracker.controls2) ": Show", NA ;bring the dummy-panel back to the top
				LLK_ToolTip(Lang_Trans("lvltracker_endreached"),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "yellow",,,, 1)
				KeyWait, LButton
				Return
			}
			start := A_TickCount, loop := 0
			While !loop && (GetKeyState("LButton", "P") && (cHWND = vars.hwnd.leveltracker["-"]) || settings.leveltracker.hotkeys && settings.leveltracker.hotkey_1 && GetKeyState(settings.leveltracker.hotkey_1, "P"))
				If (A_TickCount >= start + 1000)
					loop := 1

			If loop
			{
				Leveltracker_ProgressReset(settings.leveltracker.profile)
				Return
			}

			While !Leveltracker("condition", guide.progress) && guide.progress
				guide.progress -= 1

			IniWrite, % (vars.leveltracker.guide.progress := Max(vars.leveltracker.guide.progress - 1, 0)), % "ini" vars.poe_version "\leveling guide" settings.leveltracker.profile ".ini", progress, pages
			If !guide.progress && !Leveltracker("condition", 1)
				LLK_ToolTip(Lang_Trans("lvltracker_endreached"),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "yellow",,,, 1)
			Else Leveltracker_Progress(1)
			vars.leveltracker.last_manual := A_TickCount
			KeyWait, LButton
			Return
		}
		If (check = "drag")
		{
			If (hotkey = 2)
				settings.leveltracker.xCoord := "", settings.leveltracker.yCoord := "", write := 1
			start := A_TickCount
			While (hotkey = 1) && GetKeyState("LButton", "P")
				If (A_TickCount >= start + 250)
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
			vars.leveltracker.drag := 0, vars.general.drag := 0
			If !Blank(xDummy) || !Blank(yDummy)
			{
				settings.leveltracker.xCoord := xDummy - (xDummy >= vars.monitor.w / 2 ? 1 : 0), settings.leveltracker.yCoord := yDummy + (yDummy >= vars.monitor.h / 2 ? 2 : 0), write := 1
				Gui, dummy_gui: Destroy
			}
			If write
			{
				IniWrite, % settings.leveltracker.xCoord, % "ini" vars.poe_version "\leveling tracker.ini", Settings, x-coordinate
				IniWrite, % settings.leveltracker.yCoord, % "ini" vars.poe_version "\leveling tracker.ini", Settings, y-coordinate
			}
		}
		If (check = "reset_bar")
		{
			If (hotkey = 1)
				Leveltracker_Timer("pause")
			Else Leveltracker_Timer("reset")
		}
		Else Leveltracker_Progress(1)
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
		Geartracker_GUI("refresh")

	If !vars.hwnd.leveltracker.main
	{
		If !IsObject(vars.leveltracker.guide.import)
			Leveltracker_Load()
		If !vars.leveltracker.guide.import.Count()
		{
			LLK_ToolTip(Lang_Trans("lvltracker_guidemissing"), 2,,,, "red")
			vars.leveltracker.Delete("guide")
			Return
		}
		Leveltracker_Progress("init")
	}
	Else If !WinExist("ahk_id " vars.hwnd.leveltracker.main) && !vars.leveltracker.toggle
		Leveltracker_Progress("init")
	Else
	{
		Leveltracker_Toggle("hide"), vars.leveltracker.toggle := 0
		GuiControl,, % vars.hwnd.LLK_panel.leveltracker, img\GUI\leveltracker0.png
	}
	;WinActivate, ahk_group poe_window
}

Leveltracker_Experience(arealevel := "", safe := 0, feature := "")
{
	local
	global vars, settings

	If !vars.log.level
		Return
	Else If vars.poe_version
		Return "???"

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

Leveltracker_Fade()
{
	local
	global vars, settings

	If !settings.leveltracker.fade || vars.leveltracker.drag || !vars.hwnd.leveltracker.main || (vars.leveltracker.last > A_TickCount) || !LLK_Overlay(vars.hwnd.leveltracker.main, "check") || !vars.leveltracker.toggle
		Return
	If (vars.leveltracker.last + settings.leveltracker.fadetime <= A_TickCount) && WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& !(settings.leveltracker.fade_hover && LLK_IsBetween(vars.general.xMouse, vars.leveltracker.coords.x1, vars.leveltracker.coords.x2) && LLK_IsBetween(vars.general.yMouse, vars.leveltracker.coords.y1, vars.leveltracker.coords.y2))
	&& !vars.leveltracker.overlays && !InStr(vars.log.areaID, "_town")
		vars.leveltracker.fade := 1, Leveltracker_Toggle("hide")
	Else If vars.hwnd.leveltracker.main && !WinExist("ahk_id "vars.hwnd.leveltracker.main)
	&& ((settings.leveltracker.fade_hover && LLK_IsBetween(vars.general.xMouse, vars.leveltracker.coords.x1, vars.leveltracker.coords.x2) && LLK_IsBetween(vars.general.yMouse, vars.leveltracker.coords.y1, vars.leveltracker.coords.y2)
	&& !GetKeyState(settings.hotkeys.movekey, "P")) || vars.leveltracker.overlays || InStr(vars.log.areaID, "_town"))
		vars.leveltracker.fade := 0, Leveltracker_Toggle("show")
}

Leveltracker_GuideEditor(cHWND)
{
	local
	global vars, settings, db, json
	static wait, toggle := 0, profile := 0, icons, bandits := ["none", "alira", "kraityn", "oak"]

	If wait
		Return

	If !icons
		If vars.poe_version
			icons := ["checkpoint", "waypoint", "portal", "arena", "quest_2", "help", 0, 1, 2, 3, 4, 5, 6, 7]
		Else icons := ["waypoint", "portal", "arena", "quest", "help", "craft", "lab", 0, 1, 2, 3, 4, 5, 6, 7]

	If !vars.leveltracker_editor.act
		vars.leveltracker_editor := {"act": 1, "default_guide": json.load(Trim(LLK_FileRead("data\" settings.general.lang "\[leveltracker] default guide" vars.poe_version ".json"), "`r`n ")), "page": [1]}
		, vars.leveltracker_editor.default_guide := json.dump(vars.leveltracker_editor.default_guide)

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	act := vars.leveltracker_editor.act, page := vars.leveltracker_editor.page, guide := vars.leveltracker_editor.guide, guide_last := vars.leveltracker_editor.guide_last
	check := LLK_HasVal(vars.hwnd.leveltracker_editor, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If InStr(cHWND, "profile#")
	{
		Settings_menuClose(0), new_profile := IsNumber(SubStr(cHWND, 0)) ? SubStr(cHWND, 0) : ""
		If (new_profile != profile)
		{
			vars.leveltracker_editor.act := 1, page := vars.leveltracker_editor.page := [1], vars.leveltracker_editor.guide := [], vars.leveltracker_editor.guide_last := []
			ini := IniBatchRead("ini" vars.poe_version "\leveling guide" new_profile ".ini", "guide")
			Loop, % vars.poe_version ? 6 : 10
				vars.leveltracker_editor.guide.Push(json.Load(ini.guide["act" A_Index])), vars.leveltracker_editor.guide_last.Push(json.Load(ini.guide["act" A_Index]))
			vars.leveltracker_editor.guide_last_json := json.dump(vars.leveltracker_editor.guide), profile := new_profile
		}
	}
	Else If InStr(cHWND, "default#") || (check = "reset")
	{
		If (check = "reset") && LLK_Progress(vars.hwnd.leveltracker_editor.reset_bar, "LButton")
			IniDelete, % "ini" vars.poe_version "\leveling guide" profile ".ini", Progress
		Else If (check = "reset")
			Return
		vars.leveltracker_editor.guide := json.Load(vars.leveltracker_editor.default_guide), vars.leveltracker_editor.guide_last := json.Load(vars.leveltracker_editor.default_guide)
		vars.leveltracker_editor.guide_last_json := json.dump(vars.leveltracker_editor.guide), targetProfile := (check = "reset" ? profile : (IsNumber(SubStr(cHWND, 0)) ? SubStr(cHWND, 0) : ""))
		Leveltracker_GuideEditor("save#" targetProfile)
		If FileExist("ini" vars.poe_version "\leveling guide" targetProfile ".ini")
			IniWrite, % (settings.leveltracker["guide" targetProfile].info.custom := 0), % "ini" vars.poe_version "\leveling guide" targetProfile ".ini", Info, custom

		If InStr(cHWND, "default")
		{
			profile := 0
			If (vars.settings.active = "leveling tracker")
				Settings_menu("leveling tracker")
			Return
		}
		Else If (targetProfile = settings.leveltracker.profile)
		{
			Leveltracker_Load()
			If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
				Leveltracker_Progress(1)
		}
	}
	Else
	{
		If (check = "xbutton")
		{
			KeyWait, LButton
			LLK_Overlay(vars.hwnd.leveltracker_editor.main, "destroy"), vars.hwnd.leveltracker_editor.main := ""
			Return
		}
		Else If InStr(cHWND, "Wheel")
		{
			If InStr(cHWND, "up") && (vars.leveltracker_editor.page[act] = 1) || InStr(cHWND, "down") && (vars.leveltracker_editor.page[act] = vars.leveltracker_editor.guide[act].Count())
				Return
			vars.leveltracker_editor.page[act] += InStr(cHWND, "up") ? -1 : 1
		}
		Else If (check = "winbar")
		{
			start := A_TickCount
			While GetKeyState("LButton", "P")
				If (A_TickCount >= start + 100)
				{
					If !width
					{
						MouseGetPos, xMouse, yMouse
						WinGetPos, xWin, yWin, width, height, % "ahk_id " vars.hwnd.leveltracker_editor.main
					}
					LLK_Drag(width, height, xPos, yPos, 1,,, xMouse - xWin, yMouse - yWin, 1)
					Sleep 10
				}
			vars.general.drag := 0
			If !Blank(xPos)
				vars.leveltracker_editor.xPos := xPos, vars.leveltracker_editor.yPos := yPos
			Return
		}
		Else If InStr(check, "act_")
			vars.leveltracker_editor.act := act := control, vars.leveltracker_editor.page[act] := !vars.leveltracker_editor.page[act] ? 1 : vars.leveltracker_editor.page[act]
		Else If InStr(check, "page_")
			vars.leveltracker_editor.page[act] := control
		Else If InStr(check, "font_")
		{
			If IsNumber(SubStr(control, 1, 1))
				type := SubStr(control, 1, 1), control := SubStr(control, 2)

			If (control = "plus")
				settings.leveltracker["fSize_editor" type] += 1
			Else If (control = "reset")
				settings.leveltracker["fSize_editor" type] := settings.leveltracker.fSize
			Else If (control = "minus") && (settings.leveltracker["fSize_editor" type] > 10)
				settings.leveltracker["fSize_editor" type] -= 1
			Else Return

			IniWrite, % settings.leveltracker["fSize_editor" type], % "ini" vars.poe_version "\leveling tracker.ini", settings, % "font-size editor" . (type ? " text" : "")
			If !type
				LLK_FontDimensions(settings.leveltracker.fSize_editor, fHeight, fWidth), settings.leveltracker.fWidth_editor := fWidth, settings.leveltracker.fHeight_editor := fHeight
		}
		Else If (check = "save") || InStr(cHWND, "save#") ;clicking "save changes", or manually calling the function to save the default guide into a specific slot-#
		{
			If !InStr(cHWND, "#") && !LLK_Progress(vars.hwnd.leveltracker_editor.savebar, "LButton")
				Return

			targetProfile := (InStr(cHWND, "#") ? (IsNumber(SubStr(cHWND, 0)) ? SubStr(cHWND, 0) : "") : profile)
			Loop, % vars.poe_version ? 6 : 10
			{
				Loop, % (count := guide[(outer := A_Index)].Count()) ;remove blank pages
				{
					index := count - (A_Index - 1)
					If !guide[outer][index].Count()
						guide[outer].RemoveAt(index)
				}
				dump .= (!dump ? "" : "`n") "act" A_Index "=""" json.dump(guide[A_Index]) """"
			}

			If FileExist("ini" vars.poe_version "\leveling guide" targetProfile ".ini")
			{
				IniDelete, % "ini" vars.poe_version "\leveling guide" targetProfile ".ini", Guide
				If !settings.general.dev
					IniWrite, 0, % "ini" vars.poe_version "\leveling guide" targetProfile ".ini", Progress, pages
			}
			Else IniWrite, % "", % "ini" vars.poe_version "\leveling guide" targetProfile ".ini", Info

			IniWrite, % dump, % "ini" vars.poe_version "\leveling guide" targetProfile ".ini", Guide
			If InStr(cHWND, "#")
				Return
			IniWrite, % (settings.leveltracker["guide" profile].info.custom := (vars.leveltracker_editor.default_guide != json.dump(guide))), % "ini" vars.poe_version "\leveling guide" profile ".ini", Info, custom

			If (profile = settings.leveltracker.profile)
			{
				Leveltracker_Load()
				LLK_Overlay(vars.hwnd.leveltracker.main, "check")
					Leveltracker_Progress(1)
			}
			guide_last := vars.leveltracker_editor.guide_last := LLK_CloneObject(vars.leveltracker_editor.guide), vars.leveltracker_editor.guide_last_json := json.dump(guide_last)
		}
		Else If (check = "discard")
		{
			If !LLK_Progress(vars.hwnd.leveltracker_editor.discardbar, "LButton")
				Return
			guide := vars.leveltracker_editor.guide := LLK_CloneObject(vars.leveltracker_editor.guide_last)
		}
		Else If InStr(check, "textfield_") || (check_cHWND := InStr(cHWND, "textfield_"))
		{
			control := check_cHWND ? SubStr(cHWND, InStr(cHWND, "_") + 1) : control
			text := LLK_ControlGet(check_cHWND ? vars.hwnd.leveltracker_editor[cHWND] : cHWND), text := Trim(text, " `r`n"), array := []
			Loop, Parse, text, `n, %A_Space%
				array.Push(A_LoopField), areaID := InStr(A_LoopField, "areaid") && !InStr(A_LoopField, "(hint)__") ? 1 : areaID

			If guide[act][control].condition.1
				vars.leveltracker_editor.guide[act][control].lines := array.Clone()
			Else vars.leveltracker_editor.guide[act][control] := array.Clone()

			modified := (vars.leveltracker_editor.guide_last_json != json.dump(vars.leveltracker_editor.guide))
			GuiControl, % "+c" (!areaID && !(act = guide.Count() && control = guide[act].Count()) ? "Red" : (json.dump(guide_last[act][control]) != json.dump(guide[act][control]) ? "Blue" : "Black")), % cHWND
			GuiControl, % "movedraw", % cHWND
			GuiControl, % (modified ? "-" : "+") "Hidden", % vars.hwnd.leveltracker_editor.save_text
			GuiControl, % (modified ? "-" : "+") "Hidden", % vars.hwnd.leveltracker_editor.save
			GuiControl, % (modified ? "-" : "+") "Hidden", % vars.hwnd.leveltracker_editor.discard
			GuiControl, % (!modified ? "-" : "+") "Hidden", % vars.hwnd.leveltracker_editor.export
			Return
		}
		Else If InStr(check, "conditiontype_")
		{
			types := ["", "league-start", "bandit"], options := ["", ["yes", "no"], bandits], type := LLK_ControlGet(cHWND)
			vars.leveltracker_editor.guide[act][control] := {"condition": [types[type], (type = 3) ? [options[type].1] : options[type].1]}
			Leveltracker_GuideEditor("textfield_" control)
		}
		Else If InStr(check, "leaguestart_")
			vars.leveltracker_editor.guide[act][control].condition.2 := (LLK_ControlGet(cHWND) = 1 ? "yes" : "no")
		Else If InStr(check, "bandit")
		{
			input := SubStr(check, InStr(check, "_") - 1, 1)
			If (check := LLK_HasVal(vars.leveltracker_editor.guide[act][control].condition.2, bandits[input]))
				vars.leveltracker_editor.guide[act][control].condition.2.RemoveAt(check)
			Else vars.leveltracker_editor.guide[act][control].condition.2.Push(bandits[input])

			If InStr("40", vars.leveltracker_editor.guide[act][control].condition.2.Count())
				vars.leveltracker_editor.guide[act][control] := vars.leveltracker_editor.guide[act][control].lines.Clone()
		}
		Else If InStr(check, "preview_")
		{
			page_content := Trim(LLK_ControlGet(vars.hwnd.leveltracker_editor["textfield_" control]), " `r`n"), page_content := StrSplit(page_content, "`n", " ")
			vars.leveltracker_editor.dummy_guide := {"group1": page_content.Clone()}
			Leveltracker_PageDraw("guidepreview_main", "guidepreview_back", 1, wPreview, hPreview, hwnd_oldPreview)
			Gui, guidepreview_back: Show, % "NA x" vars.general.xMouse - wPreview " y" vars.general.yMouse - hPreview " w" wPreview " h" hPreview
			Gui, guidepreview_main: Show, % "NA x" vars.general.xMouse - wPreview " y" vars.general.yMouse - hPreview " w" wPreview " h" hPreview
			KeyWait, LButton
			Gui, guidepreview_back: destroy
			Gui, guidepreview_main: destroy
			Return
		}
		Else If InStr(check, "addpanel_")
		{
			vars.leveltracker_editor.page[act] += (control = page[act]) ? 1 : 0
			vars.leveltracker_editor.guide[act].InsertAt(control, [])
		}
		Else If InStr(check, "removepanel_")
		{
			If (guide[act].Count() < 2)
			{
				LLK_ToolTip(Lang_Trans("global_error"),,,,, "Red")
				Return
			}
			If LLK_Progress(vars.hwnd.leveltracker_editor["removepanelbar_" control], "LButton")
				vars.leveltracker_editor.guide[act].RemoveAt(control)
			Else Return
		}
		Else If InStr(check, "pastearea_") || InStr(check, "pasteicon_")
		{
			KeyWait, LButton
			ControlGetFocus, hwnd, % "ahk_id " vars.hwnd.leveltracker_editor.main
			ControlGet, hwnd, HWND,, % hwnd
			If !(focus := LLK_HasVal(vars.hwnd.leveltracker_editor, hwnd)) || !InStr(focus, "textfield_")
				Return
			Sleep 50
			If InStr(check, "pastearea_")
				Clipboard := "areaid" control (InStr(control, "_town") ? " (img:town)" : "") " `;`; " db.leveltracker.areaIDs[control].name . (InStr(control, "g2_3a") ? " (blocked)" : "")
			Else Clipboard := "(img:" control ")"
			SendInput, ^{v}
			Return
		}
		Else If InStr(check, "highlight_")
		{
			Clipboard := ""
			KeyWait, LButton
			ControlFocus,, % "ahk_id " vars.hwnd.leveltracker_editor.text_field
			Sleep 50
			SendInput, ^{c}
			ClipWait, 0.1
			If Blank(Clipboard)
			{
				LLK_ToolTip("no text selected", 1,,,, "Red")
				Return
			}
			If (control = "hint")
				Clipboard := "(hint)_____" . Clipboard
			Else Clipboard := (control = "quest-name" ? "<" : "(quest:") . StrReplace(clipboard, " ", "_") . (control = "quest-name" ? ">" : ")")
			SendInput, ^{v}
			Return
		}
		Else If (check = "export")
		{
			Clipboard := json.dump(vars.leveltracker_editor.guide,, "  ")
			LLK_ToolTip("guide data copied`nto clipboard", 2,,,, "Lime")
			Return
		}
		Else
		{
			LLK_ToolTip("no action")
			Return
		}
	}

	guide := vars.leveltracker_editor.guide, guide_last := vars.leveltracker_editor.guide_last, act := vars.leveltracker_editor.act, page := vars.leveltracker_editor.page, wait := 1
	guide_snapshot := vars.leveltracker_editor.guide_snapshot := json.dump(guide), modified := (vars.leveltracker_editor.guide_last_json != guide_snapshot)
	If (page[act] > guide[act].Count())
		vars.leveltracker_editor.page[act] := guide[act].Count()
	toggle := !toggle, GUI_name := "leveltracker_editor" toggle, margin := settings.general.fWidth//2
	Gui, %GUI_name%: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_editor
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1
	Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.leveltracker_editor.main, vars.hwnd.leveltracker_editor := {"main": hwnd_editor}

	Gui, %GUI_name%: Add, Text, % "Section x-1 y-1 Center Border gLeveltracker_GuideEditor HWNDhwnd_winbar", % " lailloken ui: " Lang_Trans("lvltracker_editor") " (" Lang_Trans("lvltracker_editor_slot") " " (!profile ? 1 : profile) ") "
	Gui, %GUI_name%: Add, Text, % "ys Center Border gLeveltracker_GuideEditor HWNDhwnd_xbutton w" settings.leveltracker.fWidth_editor * 2, % "x"
	vars.hwnd.leveltracker_editor.xbutton := hwnd_xbutton, vars.hwnd.leveltracker_editor.winbar := hwnd_winbar

	Gui, %GUI_name%: Add, Text, % "Section xs x" margin " y+" margin, % Lang_Trans("global_uisize") " "
	Gui, %GUI_name%: Add, Text, % "ys x+0 Border HWNDhwnd gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "–"
	Gui, %GUI_name%: Add, Text, % "ys Border HWNDhwnd1 gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "r"
	Gui, %GUI_name%: Add, Text, % "ys Border HWNDhwnd2 gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "+"
	vars.hwnd.leveltracker_editor["font_minus"] := hwnd, vars.hwnd.leveltracker_editor["font_reset"] := hwnd1, vars.hwnd.leveltracker_editor["font_plus"] := hwnd2

	Gui, %GUI_name%: Add, Text, % "ys x+" margin, % Lang_Trans("global_font") " "
	Gui, %GUI_name%: Add, Text, % "ys x+0 Border HWNDhwnd gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "–"
	Gui, %GUI_name%: Add, Text, % "ys Border HWNDhwnd1 gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "r"
	Gui, %GUI_name%: Add, Text, % "ys Border HWNDhwnd2 gLeveltracker_GuideEditor Center w" settings.leveltracker.fWidth_editor * 2, % "+"
	vars.hwnd.leveltracker_editor["font_1minus"] := hwnd, vars.hwnd.leveltracker_editor["font_1reset"] := hwnd1, vars.hwnd.leveltracker_editor["font_1plus"] := hwnd2

	Gui, %GUI_name%: Add, Text, % "ys x+" margin, % Lang_Trans("lvltracker_editor_acts") " "
	For index, vAct in (vars.poe_version ? [1, 2, 3, 1, 2, 3] : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	{
		Gui, %GUI_name%: Add, Text, % "ys Border Center BackgroundTrans gLeveltracker_GuideEditor HWNDhwnd" (index = 1 ? " x+0" : "") " w" settings.leveltracker.fWidth_editor * 2.5 (vars.poe_version && A_Index > 3 ? " cFF8000" : ""), % vAct
		Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack c" (vars.leveltracker_editor.act = index ? "404040" : "Black"), 100
		vars.hwnd.leveltracker_editor["act_" index] := hwnd
	}

	Gui, %GUI_name%: Add, Text, % "ys Center" (modified ? "" : " Hidden") " cRed HWNDhwnd x+" margin*2, % Lang_Trans("lvltracker_editor_save")
	Gui, %GUI_name%: Add, Text, % "ys Center Border" (modified ? "" : " Hidden") " HWNDhwnd2 BackgroundTrans gLeveltracker_GuideEditor x+" margin, % " " Lang_Trans("global_save") " "
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp BackgroundBlack cGreen Vertical HWNDhwnd21 Range0-500", 0
	Gui, %GUI_name%: Add, Text, % "ys Center Border" (modified ? "" : " Hidden") " HWNDhwnd3 BackgroundTrans gLeveltracker_GuideEditor x+" margin, % " " Lang_Trans("global_discard") " "
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp BackgroundBlack cRed Vertical HWNDhwnd31 Range0-500", 0
	vars.hwnd.leveltracker_editor.save_text := hwnd, vars.hwnd.leveltracker_editor.save := hwnd2, vars.hwnd.leveltracker_editor.discard := hwnd3
	vars.hwnd.leveltracker_editor.savebar := vars.hwnd.help_tooltips["leveltrackereditor_save"] := hwnd21
	vars.hwnd.leveltracker_editor.discardbar := vars.hwnd.help_tooltips["leveltrackereditor_discard"] := hwnd31
	ControlGetPos, xEdit, yEdit,, hEdit,, ahk_id %hwnd%
	wEdit := settings.leveltracker.fWidth_editor * 90, yEdit := yEdit + hEdit - 1, wPage := 0

	Gui, %GUI_name%: Font, % "underline"
	Gui, %GUI_name%: Add, Text, % "Section BackgroundTrans x" wEdit + margin*2 " y" yEdit + margin + (vars.leveltracker_editor.guide.Count() ? settings.leveltracker.fHeight_editor : 0), % Lang_Trans("lvltracker_editor_areas")
	Gui, %GUI_name%: Font, % "norm"
	Gui, %GUI_name%: Add, Progress, % "Disabled Hidden ys hp w" margin + 1
	dimensions := [Lang_Trans("lvltracker_editor_load"), Lang_Trans("lvltracker_editor_export")]

	For index, highlight in ["hint", "quest-name", "quest-item"]
		dimensions.Push(Lang_Trans("lvltracker_editor_" highlight))

	For index, object in db.leveltracker.areas[act]
		dimensions.Push(object.name (InStr(object.id, "g2_3a") ? " " Lang_Trans("lvltracker_editor_blocked") : ""))

	dimensions.Push(db.leveltracker.areas[act + 1].1.name)
	LLK_PanelDimensions(dimensions, settings.leveltracker.fSize_editor, width, height)
	For index, object in db.leveltracker.areas[act]
	{
		Gui, %GUI_name%: Add, Text, % (index = 1 ? "y+" margin : "") " Section xs Border HWNDhwnd gLeveltracker_GuideEditor w" width . (object.id = "labyrinth_airlock" ? " c569777" : ""), % " " object.name . (InStr(object.id, "g2_3a") ? " " Lang_Trans("lvltracker_editor_blocked") : "")
		vars.hwnd.leveltracker_editor["pastearea_" object.id] := hwnd
	}

	Gui, %GUI_name%: Add, Text, % "Section xs Border HWNDhwnd gLeveltracker_GuideEditor cYellow w" width, % " " db.leveltracker.areas[act + 1].1.name
	vars.hwnd.leveltracker_editor["pastearea_" db.leveltracker.areas[act + 1].1.id] := hwnd

	Gui, %GUI_name%: Add, Progress, % "Disabled Hidden ys hp w" margin + 1
	Gui, %GUI_name%: Font, % "underline"
	Gui, %GUI_name%: Add, Text, % "Section xs y+" margin*2, % Lang_Trans("lvltracker_editor_icons")
	Gui, %GUI_name%: Font, % "norm"

	For index, icon in icons
	{
		If (icon != "help") && !vars.pics.leveltracker[icon]
			vars.pics.leveltracker[icon] := LLK_ImageCache("img\GUI\leveling tracker\" icon ".png")
		Gui, %GUI_name%: Add, Pic, % (index = 1 || !icon ? "Section xs y+" (index = 4 ? -1 : margin) : "ys") " Border hp" (index = 1 ? "" : "-2") " w-1 gLeveltracker_GuideEditor HWNDhwnd", % "HBitmap:*" (icon = "help" ? vars.pics.global.help : vars.pics.leveltracker[icon])
		vars.hwnd.leveltracker_editor["pasteicon_" icon] := hwnd
	}

	Gui, %GUI_name%: Font, % "underline"
	Gui, %GUI_name%: Add, Text, % "Section xs y+" margin*2, % Lang_Trans("lvltracker_editor_highlight")
	Gui, %GUI_name%: Font, % "norm"
	For index, highlight in ["hint", "quest-name", "quest-item"]
	{
		Gui, %GUI_name%: Add, Text, % (index = 1 ? "y+" margin : "") " Section xs Border HWNDhwnd gLeveltracker_GuideEditor w" width, % " " Lang_Trans("lvltracker_editor_" highlight)
		vars.hwnd.leveltracker_editor["highlight_" highlight] := hwnd
	}

	ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
	Gui, %GUI_name%: Add, Progress, % "xs Disabled Hidden h" margin + 2
	Gui, %GUI_name%: Add, Text, % "Section x" margin " y" yEdit + margin, % Lang_Trans("maptracker_page")

	Loop, % Max(vars.leveltracker_editor.guide[act].Count(), 1)
	{
		Gui, %GUI_name%: Add, Text, % (xPage + wPage >= wEdit - wPage ? "xs Section" : "ys") . (A_Index = 1 ? " Section x+" margin : "") " Border HWNDhwnd BackgroundTrans gLeveltracker_GuideEditor Center"
		. " w" settings.leveltracker.fWidth_editor*2.5 . (!vars.poe_version && vars.leveltracker_editor.guide[act][A_Index].condition.1 = "bandit" ? " cYellow" : ""), % A_Index
		If (A_Index = page[act] || LLK_IsBetween(A_Index, page[act] - 1, page[act] + 1))
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border BackgroundBlack c" (A_Index = page[act] ? "505050" : LLK_IsBetween(A_Index, page[act] - 1, page[act] + 1) ? "303030" : "Black"), 100
		vars.hwnd.leveltracker_editor["page_" A_Index] := hwnd
		ControlGetPos, xPage, yPage, wPage, hPage,, ahk_id %hwnd%
	}

	types := ["none", "league-start", "bandit"], options := ["none", ["yes", "no"]], handle := ""
	LLK_PanelDimensions([Lang_Trans("lvltracker_editor_add")], settings.leveltracker.fSize_editor, wAdd, hAdd), LLK_PanelDimensions([Lang_Trans("global_preview")], settings.leveltracker.fSize_editor, wPreview, hPreview)
	For i, offset in [-1, 0, 1]
	{
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor1
		page1 := page[act] + offset, array := vars.leveltracker_editor.guide[act][page1], panel := areaID := ""
		For index, line in (array.HasKey("condition") ? array.lines : array)
			panel .= (!panel ? "" : "`n") line, areaID := InStr(line, "areaid") && !InStr(line, "(hint)__") ? 1 : areaID
		style := (page1 < 1 || page1 > vars.leveltracker_editor.guide[act].Count() ? " Hidden" : "")
		color := !areaID && !InStr(panel, "act-tracker") && !(act = guide.Count() && page1 = guide[act].Count()) ? "Red" : (json.dump(array) != json.dump(guide_last[act][page1]) ? "Blue" : "Black")
		Gui, %GUI_name%: Add, Edit, % "Section xs" (i = 1 ? " x" margin : "") " -Wrap c" color " HWNDhwnd Lowercase gLeveltracker_GuideEditor w" wEdit " h" (yLast + hLast - yEdit)//4 . style, % panel
		vars.hwnd.leveltracker_editor["textfield_" page1] := hwnd

		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor
		Gui, %GUI_name%: Add, Text, % "Section xs Border BackgroundTrans HWNDhwnd gLeveltracker_GuideEditor" style, % " " Lang_Trans("lvltracker_editor_remove") " "
		Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp cRed BackgroundBlack Vertical Range0-500 HWNDhwnd2" style, 0
		vars.hwnd.leveltracker_editor["removepanel_" page1] := hwnd
		vars.hwnd.leveltracker_editor["removepanelbar_" page1] := vars.hwnd.help_tooltips["leveltrackereditor_remove panel" handle] := hwnd2

		Gui, %GUI_name%: Add, Text, % "ys hp x+" margin . style, % " " Lang_Trans("global_condition")
		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor - 4
		Gui, %GUI_name%: Add, DDL, % "ys x+" margin " hp r" (vars.poe_version ? 2 : 3) . style . " gLeveltracker_GuideEditor AltSubmit HWNDhwnd Choose" (option := !array.condition.1 ? 1 : LLK_HasVal(types, array.condition.1))
		. " w" settings.leveltracker.fWidth_editor * 11, % Lang_Trans("global_none") "|" Lang_Trans("m_lvltracker_leaguestart") . (!vars.poe_version ? "|" Lang_Trans("m_lvltracker_bandit") : "")
		vars.hwnd.leveltracker_editor["conditiontype_" page1] := vars.hwnd.help_tooltips["leveltrackereditor_conditions" handle] := hwnd

		If (option = 2)
		{
			Gui, %GUI_name%: Add, DDL, % "ys hp r2" style " gLeveltracker_GuideEditor AltSubmit HWNDhwnd Choose" LLK_HasVal(options[option], array.condition.2) " w" settings.leveltracker.fWidth_editor*8
			, % Lang_Trans("global_yes") "|" Lang_Trans("global_no")
			vars.hwnd.leveltracker_editor["leaguestart_" page1] := hwnd
		}
		Else If (option = 3)
		{
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor
			For index, val in ["none", "alira", "kraityn", "oak"]
			{
				Gui, %GUI_name%: Add, Checkbox, % "ys x+" margin " HWNDhwnd gLeveltracker_GuideEditor Checked" (LLK_HasVal(array.condition.2, val) ? 1 : 0), % Lang_Trans((index = 1) ? "global_none" : "m_lvltracker_bandits", (index = 1) ? 1 : index - 1)
				vars.hwnd.leveltracker_editor["bandit" index "_" page1] := hwnd
			}
		}

		Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor
		Gui, %GUI_name%: Add, Text, % "ys x" margin + wEdit - wPreview " Border HWNDhwnd gLeveltracker_GuideEditor w" wPreview . style, % " " Lang_Trans("global_preview")
		vars.hwnd.leveltracker_editor["preview_" page1] := vars.hwnd.help_tooltips["leveltrackereditor_preview" handle] := hwnd, handle .= "|"

		If (i < 3)
		{
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor
			Gui, %GUI_name%: Add, Text, % "xs x" margin + wEdit//2 - wAdd//2 " y+" margin " Center 0x200 Border gLeveltracker_GuideEditor HWNDhwnd", % " " Lang_Trans("lvltracker_editor_add") " "
			vars.hwnd.leveltracker_editor["addpanel_" page[act] + (i - 1)] := hwnd
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor1
			Gui, %GUI_name%: Add, Progress, % "Disabled Hidden xs h" margin + 2
		}
	}
	;Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize_editor
	Gui, %GUI_name%: Add, Progress, % "xs Disabled Hidden h" margin + 2

	Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans Center HWNDhwnd gLeveltracker_GuideEditor x" wEdit + margin*2 " y" yEdit - hEdit + 1 " w" width, % Lang_Trans("lvltracker_editor_load")
	Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp Border Range0-500 Vertical HWNDhwnd1 BackgroundBlack cRed", 0
	vars.hwnd.leveltracker_editor.reset := hwnd, vars.hwnd.leveltracker_editor.reset_bar := vars.hwnd.help_tooltips["leveltrackereditor_guide reset"] := hwnd1
	If vars.leveltracker_editor.guide.Count() && !modified && (vars.leveltracker_editor.default_guide != guide_snapshot)
	{
		Gui, %GUI_name%: Add, Text, % "xs Border BackgroundTrans Center HWNDhwnd gLeveltracker_GuideEditor w" width, % Lang_Trans("lvltracker_editor_export")
		vars.hwnd.leveltracker_editor.export := vars.hwnd.help_tooltips["leveltrackereditor_export"] := hwnd
	}

	Gui, %GUI_name%: Show, NA x10000 y10000
	ControlFocus,, % "ahk_id " vars.hwnd.leveltracker_editor.xbutton
	WinGetPos, xWin, yWin, wWin, hWin, ahk_id %hwnd_editor%
	ControlMove,,,, wWin - settings.leveltracker.fWidth_editor*2 + 1,, % "ahk_id " vars.hwnd.leveltracker_editor.winbar
	ControlMove,, wWin - settings.leveltracker.fWidth_editor*2,,,, % "ahk_id " vars.hwnd.leveltracker_editor.xbutton

	If Blank(vars.leveltracker_editor.xPos)
		xPos := vars.leveltracker_editor.xPos := vars.monitor.x + vars.client.xc - wWin//2, yPos := vars.leveltracker_editor.yPos := vars.monitor.y + vars.client.yc - hWin//2
	Else xPos := vars.leveltracker_editor.xPos, yPos := vars.leveltracker_editor.yPos
	;Gui_CheckBounds(xPos, yPos, wWin, hWin)
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(hwnd_editor, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy"), wait := 0
}

Leveltracker_Hints()
{
	local
	global vars, settings, db

	For key in vars.leveltracker.hints
		If LLK_HasVal(vars.leveltracker.guide.group1, key, 1)
		{
			pic := StrReplace(key, " ", "_")
			Break
		}

	If LLK_HasVal(vars.leveltracker.guide.group1, "(img:craft)", 1,,, 1) && db.leveltracker.areaIDs[vars.log.areaID].craft
		craft := db.leveltracker.areaIDs[vars.log.areaID].craft

	If !pic && !craft
		Return
	Gui, leveltracker_hints: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x02000000 +E0x00080000 HWNDleveltracker_hints
	Gui, leveltracker_hints: Color, Black
	Gui, leveltracker_hints: Margin, 0, 0
	Gui, leveltracker_hints: Font, % "s"settings.general.fSize - 2 " cWhite", % vars.system.font

	If pic
		Gui, leveltracker_hints: Add, Pic, % "Section w" vars.leveltracker.coords.w " h-1 Border", % "img\GUI\leveling tracker\hints" vars.poe_version "\" pic ".jpg"
	If craft
	{
		If !vars.pics.leveltracker.craft
			vars.pics.leveltracker.craft := LLK_ImageCache("img\GUI\leveling tracker\craft.png")
		Gui, leveltracker_hints: Add, Pic, % (pic ? "Section xs y+-1 " : "") "Border h" settings.general.fHeight " w-1", % "HBitmap:*" vars.pics.leveltracker.craft
		Gui, leveltracker_hints: Add, Text, % "ys x+-1 hp Center Border 0x200 w" vars.leveltracker.coords.w - settings.general.fHeight*2, % craft
		Gui, leveltracker_hints: Add, Pic, % "ys x+-1 Border h" settings.general.fHeight " w-1", % "HBitmap:*" vars.pics.leveltracker.craft
	}

	Gui, leveltracker_hints: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %leveltracker_hints%
	yPos := (Blank(settings.leveltracker.yCoord) || settings.leveltracker.yCoord >= vars.monitor.h / 2) ? vars.leveltracker.coords.y1 - h + 1 : vars.leveltracker.coords.y2 - 1
	Gui, leveltracker_hints: Show, % "NA x" vars.monitor.x + vars.leveltracker.coords.x1 " y" yPos

	KeyWait, % vars.hotkeys.tab
	Gui, leveltracker_hints: Destroy
}

Leveltracker_Hotkeys(mode := "")
{
	local
	global vars, settings

	Loop, Parse, % "^!+~#"
		hotkey := (A_Index = 1) ? A_ThisHotkey : hotkey, hotkey := StrReplace(hotkey, A_LoopField)
	If (mode = "refresh")
	{
		Hotkey, If, WinActive("ahk_group poe_ahk_window") && vars.hwnd.leveltracker.main
		Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_01), Leveltracker_Hotkeys, Off
		Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_02), Leveltracker_Hotkeys, Off
		If settings.leveltracker.hotkeys
		{
			Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_1), Leveltracker_Hotkeys, On
			Hotkey, % Hotkeys_Convert(settings.leveltracker.hotkey_2), Leveltracker_Hotkeys, On
		}
		Return
	}
	button := (GetKeyName(hotkey) = settings.leveltracker.hotkey_1) ? "-" : "+"
	Leveltracker(button)
	KeyWait, % hotkey
}

Leveltracker_Import(profile := "")
{
	local
	global vars, settings, Json, db

	KeyWait, LButton
	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	If !InStr(Clipboard, " areaid")
	{
		Try PoB := Leveltracker_PobImport(Clipboard, profile)
		If !IsObject(PoB)
		{
			LLK_ToolTip(Lang_Trans("lvltracker_importerror", 2), 1.5,,,, "red")
			Return
		}
		Else
		{
			Init_leveltracker(), Settings_menu("leveling tracker")
			Clipboard := ""
			Return 1
		}
	}
	Else Try object := json.load(Clipboard)

	If !IsObject(object)
	{
		LLK_ToolTip(Lang_Trans("lvltracker_importerror", 2), 1.5,,,, "red")
		Return
	}
	Else
		Loop, % vars.poe_version ? 6 : 10
			dump .= (!dump ? "" : "`n") "act" A_Index "=""" json.dump(object[A_Index]) """"

	If FileExist("ini" vars.poe_version "\leveling guide" profile ".ini")
	{
		IniDelete, % "ini" vars.poe_version "\leveling guide" profile ".ini", Guide
		IniWrite, 0, % "ini" vars.poe_version "\leveling guide" profile ".ini", Progress, pages
	}
	IniWrite, % (settings.leveltracker["guide" profile].info.custom := 1), % "ini" vars.poe_version "\leveling guide" profile ".ini", Info, custom
	IniWrite, % dump, % "ini" vars.poe_version "\leveling guide" profile ".ini", Guide
	Init_leveltracker(), Settings_menu("leveling tracker")
	If (profile = settings.leveltracker.profile)
	{
		Leveltracker_Load()
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			Leveltracker_Progress(1)
	}
	Clipboard := ""
	Return 1

	If (SubStr(Clipboard, 1, 2) != "[{") || !InStr(Clipboard, """enter""")
	{
		If (SubStr(Clipboard, 1, 2) = "[{") && !InStr(Clipboard, """enter""")
			LLK_ToolTip(Lang_Trans("lvltracker_importerror"), 2,,,, "red")
		Else LLK_ToolTip(Lang_Trans("lvltracker_importerror", 2), 1.5,,,, "red")
		Return
	}

	import := Json.Load(Clipboard), areas := db.leveltracker.areas, gems := db.leveltracker.gems, quests := db.leveltracker.quests
	vars.leveltracker["pob" profile] := ""
	IniDelete, % "ini" vars.poe_version "\leveling tracker.ini", % "PoB" profile

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
								step_text := npc ? "(img:quest) " StrReplace(step_text, "hand in ", npc ": ") "<" StrReplace(quests[quest].name, " ", "_") "> " : step_text "<" StrReplace(quests[quest].name, " ", "_") "> "
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
				If (attr = "none") || (gems[gemID].name = "convocation")
					build_gems_none .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
				Else build_gems_%type%_%attr% .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","

				color := (attr = "str") ? "D81C1C" : (attr = "dex") ? "00BF40" : (attr = "int") ? "0077FF" : "White"
				step_text .= (step.rewardType = "vendor" ? "buy gem: " : "take reward: ") . (color ? "(color:"color ")" : "") StrReplace(gems[gemID].name, " ", "_")

				;If step.requiredGem.note
				;	gem_notes .= gems[gemID].name "=" step.requiredGem.note "`n"
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
						text := !ss_array.parts[ss_part_index + 1].value ? Trim(ss_parts, " ") : (SubStr(ss_parts, 1, 1) = " ") ? SubStr(ss_parts, 2) : ss_parts
						ss_text .= ((ss_text != "(hint)") ? "" : "_______") StrReplace(text, " ", "_")
					}
					Else
					{
						Switch ss_parts.type
						{
							Case "dir":
								ss_text .= " (img:"ss_parts.dirIndex ") "
							Case "waypoint":
								ss_text .= (InStr(ss_text, "broken") ? "" : "_the") " (img:waypoint) "
							Case "quest_text":
								ss_text .= " (quest:" StrReplace(ss_parts.value, " ", "_") ") "
							Case "generic":
								ss_text .= (ss_parts.value = "/passives" ? """" ss_parts.value """" : ss_parts.value) " "
							Case "arena":
								ss_text .= " (img:arena) arena:" StrReplace(ss_parts.value, " ", "_") " "
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
		If InStr(act, "pob-code:") && !InStr(act, "pob-code:none")
			Try vars.leveltracker["pob" profile] := Leveltracker_PobImport(StrReplace(act, "pob-code:"), profile)
	}

	guide_text .= "<you_can_now_disable_the_act-tracker_in_the_settings>`n"
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int build_gems_none ;create single gem-string for gear tracker feature

	If !vars.poe_version
	{
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
	}

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
	guide_text := StrReplace(guide_text, "for_quicksilver flask", "for_quicksilver flask (qsf)")
	guide_text := StrReplace(guide_text, "Vendor_Quicksilver Flask +_Orb of Augmentation +_Normal_Boots", "vendor:_qsf +_aug +_boots //_qsf +_aug +_ms_boots")
	guide_text := StrReplace(guide_text, "(hint)_______Vendor_Quicksilver Flask +_Orb of Augmentation +_Movement_Speed_Boots `n")
	guide_text := StrReplace(guide_text, "at_the_fork_in_the_road_with_wagons,_go_the_route_with_1_wagon,_not_2", "at_the_fork,_follow_the_single_wagon")
	StringLower, guide_text, guide_text

	If FileExist("ini" vars.poe_version "\leveling guide" profile ".ini")
	{
		IniDelete, % "ini" vars.poe_version "\leveling guide" profile ".ini", Steps
		IniDelete, % "ini" vars.poe_version "\leveling guide" profile ".ini", Info
	}
	IniWrite, % guide_text, % "ini" vars.poe_version "\leveling guide" profile ".ini", Steps

	Init_leveltracker()
	Settings_menu("leveling tracker")
	If settings.leveltracker.geartracker
		Geartracker_GUI("refresh")
	Leveltracker_Load()
	Clipboard := ""
	Return 1
}

Leveltracker_Load(profile := 0)
{
	local
	global vars, settings, JSON

	If !IsObject(vars.leveltracker.guide)
		vars.leveltracker.guide := {}

	current_profile := settings.leveltracker.profile
	import := [], gems := {}, ini := IniBatchRead("ini" vars.poe_version "\leveling guide" (profile ? profile : current_profile) ".ini")

	If !profile
		vars.leveltracker.guide.progress := !Blank(check := ini.progress.pages) ? check : 0

	Loop, % vars.poe_version ? 6 : 10
		For iPage, oPage in json.load(ini.guide["act" A_Index])
			import.Push(oPage)

	vars.leveltracker.guide.import := LLK_CloneObject(import)
}

Leveltracker_ScreencapMenu()
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

	Gui, %GUI_name%: Add, Text, % "x-1 y-1 Border Hidden Center Section gLeveltracker_ScreencapMenu2 HWNDhwnd", % Lang_Trans("lvltracker_header")
	vars.hwnd.leveltracker_screencap.winbar := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+-1 Border Hidden Center gLeveltracker_ScreencapMenuClose HWNDhwnd w"settings.general.fWidth*2, % "x"
	vars.hwnd.leveltracker_screencap.winx := hwnd

	files := 0
	Loop, 99
	{
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[0" A_Index "]*")
		|| FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["A_Index "]*")
			files := (A_Index < 10 ? "0" : "") A_Index
	}

	Gui, %GUI_name%: Font, % "bold underline s"settings.general.fSize
	Gui, %GUI_name%: Add, Text, % "xs Section HWNDanchor x"settings.general.fWidth/2, % Lang_Trans("global_skilltree")
	Gui, %GUI_name%: Font, norm
	Gui, %GUI_name%: Add, Picture, % "ys hp w-1 HWNDhwnd", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["leveltracker_skilltree-cap about"] := hwnd

	Loop, % files + 1
	{
		index := (A_Index < 10) ? "0" . A_Index : A_Index, wButtons := (A_Index = active) ? 0 : wButtons
		color := (index = vars.leveltracker.screencap_active) ? " cFuchsia" : !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["index "]*") ? " cGray" : ""
		Gui, %GUI_name%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["index "]*") ? "" : " Border gLeveltracker_ScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 (A_Index = files + 1 ? " cLime" : color), % index
		vars.hwnd.leveltracker_screencap["select_"index] := hwnd
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " " Lang_Trans("global_paste") " "
		vars.hwnd.leveltracker_screencap["paste_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd"(A_Index = files + 1 ? " cLime" : ""), % " " Lang_Trans("global_snip") " "
		vars.hwnd.leveltracker_screencap["snip_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (A_Index = files + 1) && (A_Index != 1)
		{
			Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltracker_ScreencapMenu2 Center w"wButtons2 + settings.general.fWidth/4, % " " Lang_Trans("lvltracker_deleteall") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
			vars.hwnd.leveltracker_screencap.delall := hwnd0, vars.hwnd.leveltracker_screencap.delbarall := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete-all"] := hwnd
		}

		If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["index "]*")
			Continue
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd", % " " Lang_Trans("global_show") " "
		vars.hwnd.leveltracker_screencap["preview_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 := LLK_ControlGetPos(hwnd, "w")
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltracker_ScreencapMenu2", % " " Lang_Trans("global_delete", 2) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_"index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_"index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0, wButtons2 += LLK_ControlGetPos(hwnd, "w"), handle .= "|"
		If (active = index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %GUI_name%: Font, % "s"settings.general.fSize - 4
			Gui, %GUI_name%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltracker_ScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %GUI_name%: Font, % "s"settings.general.fSize
		}
	}

	Gui, %GUI_name%: Font, bold underline
	Gui, %GUI_name%: Add, Text, % "xs Section y+"settings.general.fHeight*0.8, % Lang_Trans("global_ascendancy")
	Gui, %GUI_name%: Add, Picture, % "ys hp w-1 HWNDhwnd69", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI_name%: Font, norm
	Loop 5
	{
		vars.hwnd.help_tooltips["leveltracker_skilltree-cap ascend"] := hwnd69, index := "0"A_Index, color := (active = -A_Index) ? " cFuchsia" : !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab"A_Index "]*") ? " cGray" : "", wButtons := (-A_Index = active) ? 0 : wButtons
		Gui, %GUI_name%: Add, Text, % "Section xs" (!FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab"A_Index "]*") ? " " : " Border gLeveltracker_ScreencapMenu2 ") "HWNDhwnd Center w"settings.general.fWidth*3 color, % index
		vars.hwnd.leveltracker_screencap["select_-"A_Index] := hwnd, handle .= "|"
		If FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab"A_Index "]*")
			vars.hwnd.help_tooltips["leveltracker_skilltree-cap index"handle] := hwnd
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd", % " " Lang_Trans("global_paste") " "
		vars.hwnd.leveltracker_screencap["paste_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap paste"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd", % " " Lang_Trans("global_snip") " "
		vars.hwnd.leveltracker_screencap["snip_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap snip"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab"A_Index "]*")
			Continue
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border gLeveltracker_ScreencapMenu2 HWNDhwnd", % " " Lang_Trans("global_show") " "
		vars.hwnd.leveltracker_screencap["preview_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap show"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		Gui, %GUI_name%: Add, Text, % "ys x+"settings.general.fWidth/4 " Border BackgroundTrans HWNDhwnd0 gLeveltracker_ScreencapMenu2", % " " Lang_Trans("global_delete", 2) " "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range0-500 BackgroundBlack cRed HWNDhwnd", 0
		vars.hwnd.leveltracker_screencap["del_-"A_Index] := hwnd0, vars.hwnd.leveltracker_screencap["delbar_-"A_Index] := vars.hwnd.help_tooltips["leveltracker_skilltree-cap delete"handle] := hwnd
		wButtons += (-A_Index = active) ? LLK_ControlGetPos(hwnd, "w") : 0
		If (active = -A_Index)
		{
			check := InStr(active, "-") ? "lab"StrReplace(active, "-") : active
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["check "]*"
				caption := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, "]") + (InStr(A_LoopFileName, check "] ") ? 2 : 1)), "."A_LoopFileExt)
			Gui, %GUI_name%: Font, % "s"settings.general.fSize - 4
			Gui, %GUI_name%: Add, Edit, % "xs Section r1 cBlack HWNDhwnd gLeveltracker_ScreencapMenu2 w"wButtons + settings.general.fWidth*4, % caption
			vars.hwnd.leveltracker_screencap.caption := vars.hwnd.help_tooltips["leveltracker_skilltree-cap caption"] := hwnd
			Gui, %GUI_name%: Font, % "s"settings.general.fSize
		}
	}
	Gui, %GUI_name%: Add, Button, % "x0 y0 wp hp "(Blank(active) ? "" : " gLeveltracker_ScreencapMenu2") " Hidden Default HWNDhwnd", % ok
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

Leveltracker_ScreencapMenu2(cHWND)
{
	local
	global vars, settings

	check := LLK_HasVal(vars.hwnd.leveltracker_screencap, cHWND), control := SubStr(check, InStr(check, "_") + 1), active := vars.leveltracker.screencap_active
	If InStr(check, "select_")
	{
		vars.leveltracker.screencap_active := control
		Leveltracker_ScreencapMenu()
		Return
	}
	Else If InStr(check, "paste_")
	{
		If !Leveltracker_ScreencapPaste(control)
			Return
	}
	Else If InStr(check, "snip_")
	{
		pBitmap := SnippingTool(1)
		If (pBitmap <= 0)
			Return
		vars.leveltracker.screencap_active := control
		FileDelete, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "].png", 100)
		Gdip_DisposeImage(pBitmap)
		;SnipGuiClose()
	}
	Else If InStr(check, "preview_")
	{
		Leveltracker_Skilltree(StrReplace(control, "-", "lab"))
		Return
	}
	Else If InStr(check, "del_")
	{
		If LLK_Progress(vars.hwnd.leveltracker_screencap["delbar_"control], "LButton")
		{
			FileDelete, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(control, "-") ? "lab" : "") StrReplace(control, "-") "]*"
			vars.leveltracker.screencap_active := (vars.leveltracker.screencap_active = control) ? "" : vars.leveltracker.screencap_active
		}
		Else Return
	}
	Else If (check = "delall")
	{
		If LLK_Progress(vars.hwnd.leveltracker_screencap.delbarall, "LButton")
		{
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[*"
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
				LLK_ToolTip(Lang_Trans("global_errorname", 5) A_LoopField, 2, x, y + h,, "red")
				Return
			}
		GuiControl, +cBlack, % vars.hwnd.leveltracker_screencap.caption
		GuiControl, movedraw, % vars.hwnd.leveltracker_screencap.caption
		FileMove, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]*", % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(active, "-") ? "lab" : "") StrReplace(active, "-") "]"(Blank(caption) ? "" : " ") caption ".*", 1
	}
	Else If (check = "winbar")
	{
		start := A_TickCount
		WinGetPos, xWin, yWin, wWin, hWin, % "ahk_id "vars.hwnd.leveltracker_screencap.main
		MouseGetPos, xMouse, yMouse
		While GetKeyState("LButton", "P")
		{
			LLK_Drag(wWin, hWin, xPos, yPos, 1, A_Gui,, xMouse - xWin, yMouse - yWin)
			Sleep 1
		}
		vars.general.drag := 0
		Return
	}
	Else LLK_ToolTip("no action")
	Leveltracker_ScreencapMenu()
}

Leveltracker_ScreencapMenuClose()
{
	local
	global vars, settings

	LLK_Overlay(vars.hwnd.leveltracker_screencap.main, "destroy"), vars.leveltracker.Delete("screencap_active")
	If !Blank(vars.hwnd.settings.main)
		LLK_Overlay(vars.hwnd.settings.main, "show")
	If WinExist("ahk_id "vars.hwnd.snip.main)
		SnipGuiClose()
}

Leveltracker_PageDraw(name_main, name_back, preview, ByRef width, ByRef height, ByRef hwnd_old)
{
	local
	global vars, settings, db

	guide := preview ? vars.leveltracker_editor.dummy_guide : vars.leveltracker.guide, areas := db.leveltracker.areas, areaIDs := db.leveltracker.areaIDs
	Loop 2 ;create guide panel twice to check its width and correct it if necessary
	{
		outer := A_Index, width_comp := Floor(width / settings.leveltracker.fWidth)
		Gui, %name_back%: New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_back"
		Gui, %name_back%: Color, Black
		;Gui, %name_back%: Margin, % settings.general.fWidth * (outer = 2 && width <= settings.leveltracker.fWidth * 20 ? (19 - width_comp) / 2 : 1), 0
		WinSet, Transparent, % 100 + settings.leveltracker.trans * 30

		Gui, %name_main%: New, % "-DPIScale +E0x20 +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDleveltracker_main +Owner" name_back
		Gui, %name_main%: Color, Black
		Gui, %name_main%: Margin, % settings.general.fWidth  * (outer = 2 && width <= settings.leveltracker.fWidth * 24 ? Max((24 - width_comp) / 2, 1) : 1), 0
		WinSet, TransColor, Black
		Gui, %name_main%: Font, % "s"settings.leveltracker.fSize " cWhite", % vars.system.font
		If (outer = 2) && !preview
			hwnd_old := [vars.hwnd.leveltracker.main, vars.hwnd.leveltracker.background, vars.hwnd.leveltracker.controls2, vars.hwnd.leveltracker.controls1], vars.hwnd.leveltracker := {"background": leveltracker_back}, vars.hwnd.leveltracker.main := leveltracker_main

		guide.gems := [], guide.items := []
		For index_raw, step in guide.group1
		{
			If LLK_PatternMatch(step, "", [Lang_Trans("lvltracker_recommended"), Lang_Trans("lvltracker_recommended", 2)]) && !settings.leveltracker.recommend
				Continue

			style := "Section xs", line := step, step := StrReplace(StrReplace(StrReplace(step, "): ", ") : "), ". ", " . "), ", ", " , "), kill := 0, text_parts := []
			If (check := InStr(step, " `;"))
				step := SubStr(step, 1, check - 1)

			For key in vars.leveltracker.hints
				If InStr(step, key)
					step := StrReplace(step, key, StrReplace(key, " ", "_"))

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
				buy_prompt := 1
				Continue
			}
			Else If (InStr(step, "buy gem:") || InStr(step, "buy item:")) && (guide.gems.Count() || guide.items.Count())
			{
				add := SubStr(step, InStr(step, ":") + 2), add := InStr(add, "(") ? SubStr(add, InStr(add, ")") + 1) : add, add := StrReplace(add, "_", " ")
				guide[InStr(step, "buy item:") ? "items" : "gems"].Push(add)
				Continue
			}

			If (index_raw = guide.group1.Count()) && buy_prompt
			{
				Gui, %name_main%: Add, Text, % style " cFuchsia", % "buy " (LLK_HasVal(guide.group1, "buy item", 1) ? "items" : "gems") " (highlight: hold omni-key)"
				buy_prompt := 0
			}

			For index, part in text_parts
			{
				spacing_check := !Blank(SubStr(text_parts[index + 1], 1, 1)) && InStr(",.:", SubStr(text_parts[index + 1], 1, 1)) ? 1 : 0
				If InStr(part, "(img:")
				{
					img := SubStr(part, InStr(part, "(img:") + 5), img := SubStr(img, 1, InStr(img, ")") - 1), img := StrReplace(img, " ", "_")
					If (img != "help") && !vars.pics.leveltracker[img]
						vars.pics.leveltracker[img] := LLK_ImageCache("img\GUI\leveling tracker\" img ".png")
					Gui, %name_main%: Add, Picture, % style (A_Index = 1 ? "" : " x+"(settings.leveltracker.fWidth/(InStr(step, "(hint)") ? 3 : 2))) " BackgroundTrans "(InStr(step, "(hint)") ? "hp-2" : "h" settings.leveltracker.fHeight - 2) " w-1", % "HBitmap:*" (img = "help" ? vars.pics.global.help : vars.pics.leveltracker[img])
				}
				Else
				{
					text := LLK_StringRemove(StrReplace(StrReplace(part, "&&", "&"), "&", "&&"), "<,>,arena:,(hint)"), area := StrReplace(text, "areaid")
					act := LLK_HasVal(areas, area,,,, 1), act := (vars.poe_version && act > 3 && act != 7 ? act - 3 : act) . (vars.poe_version && InStr(part, "areaidc_") ? Lang_Trans("lvltracker_format_act", 2) : "")
					If InStr(text, "areaid") ;translate ID to location-name (and add potential act-clarification)
						text := (!preview && ((act != vars.log.act) && !InStr(text, "labyrinth") || InStr(vars.log.areaID, "hideout")) ? (act = 11 || vars.poe_version && act = 7 ? Lang_Trans("lvltracker_format_epilogue") : Lang_Trans("lvltracker_format_act", 1) . act) " | " : "") . areaIDs[(area := StrReplace(text, "areaid"))][InStr(line, "img:waypoint") && areaIDs[area].mapname ? "mapname" : "name"]
					text := StrReplace(text, "_", " "), text := StrReplace(text, "(a11)", "(epilogue)")
					If InStr(part, "(quest:")
						replace := SubStr(text, InStr(text, "(quest:")), replace := SubStr(replace, 1, InStr(replace, ")")), item := StrReplace(SubStr(replace, InStr(replace, ":") + 1), ")"), text := StrReplace(text, replace, item)
					If (text_parts[index - 1] = "(img:arena)")
					{
						color := "White"
						Gui, %name_main%: Font, % "underline"
					}
					Else color := InStr(part, "areaid") ? "FEC076" : kill && (part != "everything") || InStr(part, "arena:") ? "FF8111" : InStr(part, "<") ? "FFDB1F" : InStr(part, "(quest:") ? "Lime" : InStr(part, "trial") || InStr(part, "_lab") ? "569777" : "White"
					If InStr(part, "(color:")
						color := SubStr(part, InStr(part, "(color:") + 7), color := SubStr(color, 1, InStr(color, ")") - 1), text := StrReplace(text, "(color:"color ")")
					If InStr(step, "(hint)")
						Gui, %name_main%: Font, % "s"settings.leveltracker.fSize - 2
					If vars.leveltracker.hints[StrReplace(part, "_", " ")]
						color := "Aqua"
					Gui, %name_main%: Add, Text, % style " c"color, % (index = text_parts.MaxIndex()) || spacing_check || InStr(text_parts[index + 1], "(img:") ? text : text " "
					Gui, %name_main%: Font, % "norm s"settings.leveltracker.fSize
					kill := (part = Lang_Trans("lvltracker_format_kill")) ? 1 : 0
				}
				style := InStr(part, "(img:") && !spacing_check ? "ys x+"settings.leveltracker.fWidth/3 : "ys x+0", spacing_check := 0
			}
		}
		If !preview && (outer = 2) && (guide.gems.Count() || guide.items.Count())
			Leveltracker_Strings()

		If !preview
			vars.leveltracker.wait := 1 ;this stops the timer-GUI from being created before the main overlay has finished drawing
		Gui, %name_main%: Show, NA x10000 y10000
		Gui, %name_back%: Show, NA x10000 y10000
		WinGetPos, x, y, width, height, % "ahk_id " leveltracker_main
	}
}

Leveltracker_PobGemLinks(gem_name := "", hover := 1, xPos := "", yPos := "", regex := 0)
{
	local
	global vars, settings, db
	static toggle := 0, last_gem, stat_colors := ["d81c1c", "00bf40", "0077FF"], last_xPos, last_yPos

	If !regex && (!gem_name && !last_gem || Blank(xPos) && Blank(last_xPos) || Blank(yPos) && Blank(last_yPos))
		Return

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	profile := settings.leveltracker.profile
	pob := vars.leveltracker["pob" profile], item := vars.omnikey.item, wHover := settings.leveltracker.fWidth * 15
	If !IsObject(vars.leveltracker.gemlinks)
		vars.leveltracker.gemlinks := {}
	If gem_name
		last_gem := gem_name
	Else gem_name := last_gem
	If !Blank(xPos)
		last_xPos := xPos
	Else xPos := last_xPos
	If !Blank(yPos)
		last_yPos := yPos
	Else yPos := last_yPos
	support := InStr(gem_name, " support") || (item.class = Lang_Trans("items_gem", 2)) ? 1 : 0, gem_name := StrReplace(gem_name, " support")
	check := LLK_HasVal(pob.gems, (support ? " |–" : "") . gem_name,,, 1, 1)
	orientation := (xPos - vars.monitor.x <= vars.monitor.x + vars.client.w//2) ? "right" : "left"

	If !check.Count()
	{
		check := [], check2 := [], regex_string := {}
		If vars.poe_version
		{
			For index, val in ["skill", "support", "spirit"]
				If val && InStr(item.name, Lang_Trans("items_uncut_gem", index))
					type := val

			For index, skillset in pob.gems
				For index2, group in skillset.groups
					For index3, gem in group.gems
						If db.leveltracker.regex[type][StrReplace(gem, " |–")]
						{
							If regex
								regex_string[StrReplace(gem, " |–")] := 1
							If !LLK_HasVal(check, index)
								check.Push(index)
							If !IsObject(check2[index])
								check2[index] := [index2]
							Else If !LLK_HasVal(check2[index], index2)
								check2[index].Push(index2)
						}

			If regex
				If !regex_string.Count()
				{
					LLK_ToolTip(Lang_Trans("lvltracker_gemregex", 2), 1.5,,,, "Red")
					Return
				}
				Else
				{
					For key in regex_string
						string .= key "|"
					Clipboard := Trim(StrReplace(string, " ", "."), "|")
					LLK_ToolTip(Lang_Trans("lvltracker_gemregex"), 1.5,,,, "Lime")
					Return
				}
		}
		If !check.Count()
		{
			LLK_ToolTip(Lang_Trans("lvltracker_gemnotes"), 1.5,,,, "Red")
			Return
		}
	}

	toggle := !toggle, GUI_name := "leveltracker_gemlinks" toggle
	Gui, %GUI_name%: New, -DPIScale +LastFound +AlwaysOnTop -Caption +ToolWindow +E0x02000000 +E0x00080000 HWNDleveltracker_gemlinks
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.leveltracker_gemlinks.main, vars.hwnd.leveltracker_gemlinks := {"main": leveltracker_gemlinks}
	hover := vars.leveltracker.gemlinks.hover := LLK_HasVal(check, hover) ? hover : check.1

	For index, val in (vars.poe_version && type ? check2[hover] : LLK_HasVal(pob.gems[hover].groups, (support ? " |–" : "") gem_name,,, 1, 1))
	{
		If !vars.poe_version
			LLK_PanelDimensions(pob.gems[hover].groups[val].gems, settings.leveltracker.fSize, wLinks, hLinks)
		Else
		{
			dimensions := []
			For iGem, vGem in pob.gems[hover].groups[val].gems
				For gem_type, oGems in db.leveltracker.regex
					If oGems[StrReplace(vGem, " |–")] && !LLK_HasVal(dimensions, vGem, 1)
						dimensions.Push(vGem " (" oGems[StrReplace(vGem, " |–")] ")")
			LLK_PanelDimensions(dimensions, settings.leveltracker.fSize, wLinks, hLinks)
		}

		For link, gem in (vars.poe_version ? dimensions : pob.gems[hover].groups[val].gems)
		{
			gem_lookup := InStr(gem, "|") ? StrReplace(gem, " |–") . (vars.poe_version ? "" : " support") : gem, gem_lookup := StrReplace(StrReplace(gem_lookup, "vaal "), "awakened ")
			style := (index = 1 && link = 1) ? (orientation = "left" || check.Count() = 1 ? "x0" : "x" wHover - 1) " y1" : (link = 1 ? "ys x+-1 y1" : "xs y+-1")
			Gui, %GUI_name%: Add, Text, % style " Section BackgroundTrans HWNDhwnd w" wLinks " h" hLinks - 2 . (!vars.poe_version ? " c" stat_colors[db.leveltracker.regex[gem_lookup].2] : ""), % " " gem
			gem := InStr(gem, "(") ? SubStr(gem, 1, InStr(gem, "(") - 2) : gem, gem := StrReplace(gem, " |–")
			Gui, %GUI_name%: Add, Progress, % "xp+1 yp wp-2 hp Disabled Background" (InStr(gem_name, gem) || type && db.leveltracker.regex[type][gem] ? "303030" : "Black"), 0
			ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
		}
		If !Blank(pob.gems[hover].groups[val].label)
		{
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize - 2
			Gui, %GUI_name%: Add, Text, % "xs Center Border BackgroundTrans w" wLinks, % pob.gems[hover].groups[val].label
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack", 0
			Gui, %GUI_name%: Font, % "s" settings.leveltracker.fSize
		}
		Gui, %GUI_name%: Add, Text, % "x" xLast " y0 BackgroundTrans Border w" wLinks " h" yLast + hLast + 1, % "" ; draw a border around gem-group
	}

	If (check.Count() > 1)
		For index, val in check
		{
			Gui, %GUI_name%: Add, Text, % (index = 1 ? (orientation = "left" ? "ys x+-1" : "x0") " y0" : "xs y+-1") " Section BackgroundTrans Border Center w" wHover, % " " pob.gems[val].title
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled HWNDhwnd Background" (val = hover ? "303030" : "Black"), 0
			vars.hwnd.leveltracker_gemlinks["skillset" val] := hwnd
		}

	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, wWin, hWin, ahk_id %leveltracker_gemlinks%
	xPos -= (orientation = "left") ? wWin - wHover//2 : wHover//2
	Gui_CheckBounds(xPos, yPos, wWin, hWin)
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(leveltracker_gemlinks, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

Leveltracker_PobImport(b64, profile)
{
	local
	global vars, db, settings, JSON
	static classes, replace := {"&lt;": "<", "&gt;": ">", "&quot;": """", "&amp;": "&&", "&apos;": "'"}

	If !classes
		If vars.poe_version
			classes := {"mercenary": ["witchhunter", "gemling legionnaire"], "monk": ["invoker", "acolyte of chayula"], "ranger": ["deadeye", "pathfinder"], "sorceress": ["stormweaver", "chronomancer"], "warrior": ["titan", "warbringer"], "witch": ["infernalist", "blood mage"]}
		Else classes := {"scion": ["ascendant"], "marauder": ["juggernaut", "berserker", "chieftain"], "ranger": ["warden", "deadeye", "pathfinder"], "witch": ["occultist", "elementalist", "necromancer"]
		, "duelist": ["slayer", "gladiator", "champion"], "templar": ["inquisitor", "hierophant", "guardian"], "shadow": ["assassin", "trickster", "saboteur"]}

	Base64Dec((pobString := RTrim(b64, "=")), compressed), buffer := 1024 * 10000
	zlib_Decompress(decompressed, compressed, buffer)
	xml := StrReplace(StrGet(&decompressed, buffer, ""), "`t"), xml := LLK_StringCase(xml)

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	If !vars.poe_version && InStr(xml, "<PathOfBuilding>") && InStr(xml, "</PathOfBuilding>")
	|| vars.poe_version && InStr(xml, "<PathOfBuilding2>") && InStr(xml, "</PathOfBuilding2>")
	{
		For text, replacement in replace
			xml := StrReplace(xml, text, replacement)

		class := SubStr(xml, InStr(xml, " classname=""") + 12), class := SubStr(class, 1, InStr(class, """") - 1)
		tree := SubStr(xml, InStr(xml, "<tree ")), tree := SubStr(tree, 1, InStr(tree, "</tree>") - 2)
		build := SubStr(xml, InStr(xml, "<build ")), build := SubStr(build, 1, InStr(build, "`n"))
		ascendancies := [], trees0 := [], trees := [], treeDB := db.leveltracker.trees, failed_versions := {}
		bandit := SubStr(build, InStr(build, "bandit=""") + 8), bandit := SubStr(bandit, 1, InStr(bandit, """") - 1)

		Loop, Parse, tree, `n, `r
			If InStr(A_LoopField, "<spec")
			{
				ascendancy := SubStr(A_LoopField, InStr(A_LoopField, "ascendclassid=""") + 15), ascendancy := SubStr(ascendancy, 1, InStr(ascendancy, """") - 1)
				If ascendancy && !LLK_HasVal(ascendancies, classes[class][ascendancy])
					ascendancies.Push(classes[class][ascendancy])

				version := SubStr(A_LoopField, InStr(A_LoopField, " treeVersion=""") + 14), version := SubStr(version, 1, InStr(version, """") - 1)
				nodes := SubStr(A_LoopField, InStr(A_LoopField, " nodes=""") + 8), nodes := SubStr(nodes, 1, InStr(nodes, """") - 1), nodes := StrSplit(nodes, ",")
				If Blank(version) || failed_versions[version] || !LLK_HasVal(treeDB.supported, version) || !Leveltracker_PobSkilltree("init " version, failed_versions)
					Continue

				count := 0
				For index, node in nodes ; check for filler-trees that don't have allocated nodes
					count += (treeDB[version].nodes[node].ascendancyname || !Blank(treeDB[version].nodes[node][vars.poe_version ? "classesstart" : "classstartindex"])) ? 0 : 1
				If !count
					Continue

				If InStr(A_LoopField, " title=""")
					title := SubStr(A_LoopField, InStr(A_LoopField, " title=""") + 8), title := SubStr(title, 1, InStr(title, """") - 1), title := Leveltracker_PobRemoveTags(title)
				Else title := "untitled tree"

				masteries := {}
				If !vars.poe_version && InStr(A_LoopField, "masteryEffects=""")
				{
					parse := SubStr(A_LoopField, InStr(A_LoopField, "masteryEffects=""") + 16), parse := SubStr(parse, 1, InStr(parse, """") - 1)
					Loop, Parse, parse, `,, % "{}"
						If Mod(A_Index, 2)
							mastery := A_LoopField
						Else masteries[mastery] := A_LoopField
				}
				trees0.Push({"title": title, "nodes": nodes, "masteries": masteries, "version": version})
			}

		If !ascendancies.Count()
			ascendancies := ["none"]

		inverted := (trees0.1.nodes.Count() > trees0[trees0.MaxIndex()].nodes.Count())
		For index, object in trees0
			If inverted
				trees.InsertAt(1, object)
			Else trees.Push(object)

		skills := SubStr(xml, InStr(xml, "<skills ")), skills := SubStr(skills, InStr(skills, "`n") + 1)
		skills := SubStr(skills, 1, InStr(skills, "</skills>") - 2), skills := StrReplace(skills, "<skillset ", "§")
		skillsets := StrSplit(skills, "§")
		While skillsets.Count() && (Blank(skillsets.1) || !InStr(skillsets.1, "`n"))
			skillsets.RemoveAt(1)
		skillsets_final := []
		For index, skillset in skillsets
		{
			groups := [], group := ""
			Loop, Parse, skillset, `n, `r
			{
				If !IsObject(group)
					group := {"label": "", "gems": []}
				If (A_Index = 1) && InStr(A_LoopField, "title=""")
					title := SubStr(A_LoopField, InStr(A_LoopField, "title=""") + 7), title := Leveltracker_PobRemoveTags(SubStr(title, 1, InStr(title, """") - 1))
				Else If (A_Index = 1) && !InStr(A_LoopField, "title=""")
					title := "default"
				If RegExMatch(A_LoopField, "<Skill.*/>")
					Continue
				If InStr(A_LoopField, "<skill ") && !InStr(A_LoopField, "label=""""")
					group.label := SubStr(A_LoopField, InStr(A_LoopField, "label=""") + 7), group.label := Leveltracker_PobRemoveTags(SubStr(group.label, 1, InStr(group.label, """") - 1))
				If InStr(A_LoopField, "<Gem ")
				{
					name := SubStr(A_LoopField, InStr(A_LoopField, "namespec=""") + 10), name := SubStr(name, 1, InStr(name, """") - 1)
					If !Blank(name)
						group.gems.Push((InStr(A_LoopField, "/supportgem") ? " |–" : "") . name)
				}
				If InStr(A_LoopField, "</skill>")
					groups.Push(group), group := ""
			}
			If groups.Count()
				skillsets_final.Push({"title": title, "groups": groups})
			title := ""
		}

		object := {"class": class, "ascendancies": ascendancies, "bandit": bandit, "gems": skillsets_final, "trees": trees, "active tree": 1}
		For key, val in object
			IniWrite, % """" (IsObject(val) ? json.dump(val) : val) """", % "ini" vars.poe_version "\leveling guide" profile ".ini", PoB, % key
		IniWrite, % (settings.leveltracker["guide" profile].info.bandit := bandit), % "ini" vars.poe_version "\leveling guide" profile ".ini", Info, bandit
		;IniWrite, % """" pobString """", % "ini" vars.poe_version "\leveling guide" profile ".ini", pob, code
		Return object
	}
}

Leveltracker_PobRemoveTags(string) ; removes tags and color-coding from PoB-related text
{
	local
	global vars, settings

	Loop, Parse, string
	{
		If skip
		{
			If IsNumber(A_LoopField)
				skip -= 1
			Else If (A_LoopField = ";")
				skip := 0
			Continue
		}
		If (A_LoopField = "^")
			skip := (SubStr(string, A_Index + 1, 1) = "x") ? 7 : 1
		Else If (A_LoopField = "&") && InStr(SubStr(string, A_Index + 1, 5), ";")
			skip := "yes"
		Else new_string .= A_LoopField
	}
	Return new_string
}

Leveltracker_PobSkilltree(mode := "", ByRef failed_versions := "")
{
	local
	global vars, settings, JSON, db
	static angles, pen, brush, wait, radii, toggle := 0

	If !angles
	{
		angles := [[30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330]
			, [10, 20, 30, 40, 45, 50, 60, 70, 80, 90, 100, 110, 120, 130, 135, 140, 150, 160, 170, 180, 190, 200, 210, 220, 225, 230, 240, 250, 260, 270, 280, 290, 300, 310, 315, 320, 330, 340, 350]]
		angles.1.0 := 0, angles.2.0 := 0
		radii := {"classstart": 200, "mastery": 100, "keystone": 100, "notable": 60, "normal": 40, "line": 10}
		brush := {"white": Gdip_BrushCreateSolid(0x64ffffff), "white2": Gdip_BrushCreateSolid(0x99ffffff), "white3": Gdip_BrushCreateSolid(0xffffffff)
			, "red": Gdip_BrushCreateSolid(0x64ff0000), "red2": Gdip_BrushCreateSolid(0x99ff0000), "red3": Gdip_BrushCreateSolid(0xffff0000)
			, "green": Gdip_BrushCreateSolid(0x6400cc00), "green2": Gdip_BrushCreateSolid(0x9900cc00), "green3": Gdip_BrushCreateSolid(0xff00cc00)
			, "blue": Gdip_BrushCreateSolid(0x640000ff), "blue2": Gdip_BrushCreateSolid(0x990000ff), "blue3": Gdip_BrushCreateSolid(0xff0000ff)
			, "black": Gdip_BrushCreateSolid(0xff000000), "gray": Gdip_BrushCreateSolid(0xff606060), "yellow": Gdip_BrushCreateSolid(0x64ffff00)}
	}

	If (mode = "close")
	{
		vars.leveltracker.skilltree_schematics.GUI := 0, LLK_Overlay(vars.hwnd.skilltree_schematics.info, "destroy")
		Gui, skilltree_schematics: Destroy
		Return
	}

	If wait && !InStr(mode, "init ")
		Return

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	If InStr(mode, "init ")
	{
		version := SubStr(mode, InStr(mode, " ") + 1), dev := settings.general.dev
		If !FileExist(file := "data\global\[leveltracker] tree" vars.poe_version " " version ".json")
		{
			LLK_ToolTip(Lang_Trans("global_downloading"), 2,,,, "Yellow")
			Try download := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/refs/heads/" (dev ? "dev" : "main") "/data/global/%5Bleveltracker%5D%20tree" vars.poe_version "%20" version ".json")
			If (SubStr(download, 1, 1) . SubStr(download, 0) != "{}")
			{
				failed_versions[version] := 1
				Return
			}
			file_new := FileOpen(file, "w", "UTF-8-RAW")
			file_new.Write(download), file_new.Close()
			Sleep 500
			If !FileExist(file)
			{
				LLK_FilePermissionError("create", file), failed_versions[version] := 1
				Return
			}
		}
		If !db.leveltracker.trees[version].Count()
			db.leveltracker.trees[version] := json.Load(LLK_FileRead(file)), db.leveltracker.trees[version].constants.orbitradii.RemoveAt(0), db.leveltracker.trees[version].constants.skillsperorbit.RemoveAt(0)
		Return db.leveltracker.trees[version].Count()
	}
	wait := 1
	profile := settings.leveltracker.profile, active := vars.leveltracker["PoB" profile]["active tree"]
	If (active > vars.leveltracker["PoB" profile].trees.Count())
		IniWrite, % (active := vars.leveltracker["PoB" profile]["active tree"] := 1), % "ini" vars.poe_version "\leveling guide" profile ".ini", PoB, active tree
	version := vars.leveltracker["PoB" profile].trees[active].version
	scale := "0." (StrLen(vars.client.h) < 4 ? "0" : "") vars.client.h

	If (mode = "drag")
	{
		WinGetPos, xPos, yPos,,, % "ahk_id " vars.hwnd.skilltree_schematics.main
		vars.leveltracker.skilltree_schematics.offsets := [vars.general.xMouse - xPos, vars.general.yMouse - yPos]
		KeyWait, RButton
		vars.leveltracker.skilltree_schematics.offsets := wait := 0
		Return
	}
	Else If mode && InStr("prev, next", mode)
	{
		If (mode = "prev") && (active > 1)
			IniWrite, % (active := vars.leveltracker["PoB" profile]["active tree"] -= 1), % "ini" vars.poe_version "\leveling guide" profile ".ini", PoB, active tree
		Else If (mode = "next") && (vars.leveltracker["PoB" profile].trees.Count() > active)
			IniWrite, % (active := vars.leveltracker["PoB" profile]["active tree"] += 1), % "ini" vars.poe_version "\leveling guide" profile ".ini", PoB, active tree
		Else LLK_ToolTip(Lang_Trans("lvltracker_endreached"), 1,,,, "Yellow")
		reset_pos := 1
	}
	Else If InStr(mode, "ascendancy ")
		ascendancy := SubStr(mode, 0), ascendancy_trees := [[], [], [], []], ascendancy_points := []
	Else If (mode = "reset")
		vars.leveltracker.skilltree_schematics.xPos := "reset"

	If !version || !Leveltracker_PobSkilltree("init " version) || !vars.leveltracker["PoB" profile].trees.Count()
	{
		LLK_ToolTip(Lang_Trans("lvltracker_" (!vars.leveltracker["PoB" profile].trees.Count() ? "treenone" : "treeerror")), 2,,,, "Red")
		wait := 0
		Return
	}
	tree := db.leveltracker.trees[version]

	If ascendancy
	{
		For iTree, vTree in vars.leveltracker["PoB" profile].trees
		{
			ascendant_points := 0
			For iNode, vNode in vTree.nodes
				If tree.nodes[vNode].ascendancyname
					If tree.nodes[vNode].isascendancystart
						ascendancy_points.InsertAt(1, vNode)
					Else ascendancy_points.Push(vNode), ascendant_points += tree.nodes[vNode].ismultiplechoiceoption ? 1 : 0
			lab := (ascendancy_points.Count() - ascendant_points) // 2

			If ascendancy_points.Count() && !ascendancy_trees[lab].Count()
				ascendancy_trees[lab] := ascendancy_points.Clone()
			If (lab = ascendancy)
				Break
			Else ascendancy_points := []
		}
	}

	allocated_previous := vars.leveltracker["PoB" profile].trees[active - 1].nodes.Clone()
	tree_title := vars.leveltracker["PoB" profile].trees[active].title, tree_count := vars.leveltracker["PoB" profile].trees.Count()
	If !allocated_previous.Count()
		allocated_previous := []
	allocated_overlap := {}
	allocated := []
	For index, node in vars.leveltracker["PoB" profile].trees[active].nodes
	{
		If tree.nodes[node].ismastery || tree.nodes[node].isascendancystart
			allocated.InsertAt(tree.nodes[node].ismastery ? 1 : 0, node)
		Else allocated.Push(node)
		allocated_overlap[node] := 1
	}
	For index, node in allocated_previous
		allocated_overlap[node] := 1
	For index, node in ascendancy_points
		allocated_overlap[node] := 1, allocated.Push(node), allocated_previous.Push(node)

	x_coords := ["", ""], y_coords := ["", ""]

	For node in allocated_overlap
	{
		If tree.nodes[node].ismastery || tree.nodes[node].expansionjewel.parent || tree.nodes[node].ascendancyname && !ascendancy
			Continue
		group := tree.nodes[node].group, orbit := tree.nodes[node].orbit, orbitIndex := tree.nodes[node].orbitIndex
		x_coord := tree.groups[group].x, y_coord := tree.groups[group].y
		margin := 250

		If ascendancy && tree.nodes[node].HasKey(vars.poe_version ? "classesstart" : "classstartindex")
			ascendancy_points.Push(node)

		If Blank(orbit) || Blank(orbitindex)
			Continue

		If (tree.constants.skillsperorbit[orbit] = 16)
			angle := angles.1[orbitIndex]
		Else If (tree.constants.skillsperorbit[orbit] = 40)
			angle := angles.2[orbitIndex]
		Else angle := (360/tree.constants.skillsperorbit[orbit]) * orbitIndex

		radius := tree.constants.orbitradii[orbit]
		x_coord := radius * cos((angle - 90) * 0.017453293252) + x_coord
		y_coord := radius * sin((angle - 90) * 0.017453293252) + y_coord

		If Blank(x_coords.1) || (x_coord - margin < x_coords.1)
			x_coords.1 := x_coord - margin
		If Blank(x_coords.2) || (x_coord + margin > x_coords.2)
			x_coords.2 := x_coord + margin
		If Blank(y_coords.1) || (y_coord - margin < y_coords.1)
			y_coords.1 := y_coord - margin
		If Blank(y_coords.2) || (y_coord + margin > y_coords.2)
			y_coords.2 := y_coord + margin
	}

	mWidth := Abs(x_coords.2 - x_coords.1), mHeight := Abs(y_coords.2 - y_coords.1)
	If (mode = "overview")
	{
		If (mWidth / mHeight >= 1.25)
			horizontal := 1, scale := Round(vars.monitor.w / 2 / mWidth, 4)
		Else
		{
			If (mHeight > vars.monitor.h * 0.90)
				scale := Round(vars.monitor.h * 0.90 / mHeight, 4)
			If (mWidth * scale > vars.monitor.w / 3)
				scale := Round(vars.monitor.w / 3 / mWidth, 4)
		}
		For kPens, vPen in pen
			Gdip_DeletePen(vPen)
		wPen := Max(2, Ceil(radii.line * scale)), pen := {"white": Gdip_CreatePen(0xffffffff, wPen), "green": Gdip_CreatePen(0xff00cc00, wPen), "red": Gdip_CreatePen(0xffff0000, wPen)}
	}
	mWidth := Round(mWidth * scale), mHeight := Round(mHeight * scale), xOffset := x_coords.1, yOffset := y_coords.1

	If !pen
		wPen := Max(2, Ceil(radii.line * scale)), pen := {"white": Gdip_CreatePen(0x64ffffff, wPen), "green": Gdip_CreatePen(0x6400cc00, wPen), "red": Gdip_CreatePen(0x64ff0000, wPen)}

	Gui, skilltree_schematics: -DPIScale -Caption +E0x80000 +E0x20 +ToolWindow +LastFound +OwnDialogs +AlwaysOnTop +HWNDhwnd_skilltree_schematics
	Gui, skilltree_schematics: Show, NA

	hbmBitmap := CreateDIBSection(mWidth, mHeight)
	hdcBitmap := CreateCompatibleDC()
	obmBitmap := SelectObject(hdcBitmap, hbmBitmap)
	gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
	If (mode = "overview")
	{
		Gdip_FillRectangle(gBitmap, brush.gray, 0, 0, mWidth, mHeight)
		Gdip_FillRectangle(gBitmap, brush.black, 2, 2, mWidth - 4, mHeight - 4)
	}
	Gdip_SetSmoothingMode(gBitmap, 4)
	masteries := vars.leveltracker["PoB" profile].trees[active].masteries
	masteries_previous := vars.leveltracker["PoB" profile].trees[active - 1].masteries

	For index, outer in (ascendancy ? [2] : [1, 2])
		For index, node in (ascendancy ? ascendancy_points : (outer = 2 ? allocated : allocated_previous))
		{
			If tree.nodes[node].expansionjewel.parent || (outer = 1 && !ascendancy) && LLK_HasVal(allocated, node) || tree.nodes[node].ascendancyname && !LLK_HasVal(ascendancy_points, node)
				Continue

			group := tree.nodes[node].group
			x_coord := (tree.groups[group].x - xOffset) * scale, y_coord := (tree.groups[group].y - yOffset) * scale

			orbit := tree.nodes[node].orbit, orbitIndex := tree.nodes[node].orbitIndex
			If Blank(orbit) || Blank(orbitindex)
				Continue
			If (tree.constants.skillsperorbit[orbit] = 16)
				angle := angles.1[orbitIndex]
			Else If (tree.constants.skillsperorbit[orbit] = 40)
				angle := angles.2[orbitIndex]
			Else angle := (360/tree.constants.skillsperorbit[orbit]) * orbitIndex

			radius := tree.constants.orbitradii[orbit] * scale
			x := radius * cos((angle - 90) * 0.017453293252) + x_coord
			y := radius * sin((angle - 90) * 0.017453293252) + y_coord

			type := tree.nodes[node].isnotable || tree.nodes[node].isjewelsocket ? "notable" : tree.nodes[node].ismastery ? "mastery" : tree.nodes[node].HasKey(vars.poe_version ? "classesstart" : "classstartindex") ? (vars.poe_version ? "keystone" : "classstart") : tree.nodes[node].iskeystone ? "keystone" : "normal"
			new_node := !LLK_HasVal(ascendancy ? ascendancy_trees[ascendancy - 1] : allocated_previous, node) || (masteries[node] != masteries_previous[node]) ? 1 : 0
			pBrush := (outer = 1) ? "red" : tree.nodes[node].HasKey(vars.poe_version ? "classesstart" : "classstartindex") ? (vars.poe_version ? "yellow" : "white") : new_node ? "green" : "white"
			pBrush .= (mode = "overview") ? "3" : (type = "mastery") ? "2" : ""
			Gdip_FillEllipseC(gBitmap, brush[pBrush], x, y, rNode := Ceil(radii[type] * scale), rNode)

			If tree.nodes[node].HasKey(vars.poe_version ? "classesstart" : "classstartindex")
			{
				If !Blank(vars.leveltracker.skilltree_schematics.classOrigin.1)
					offsets := [Round(x) - vars.leveltracker.skilltree_schematics.classOrigin.1, Round(y) - vars.leveltracker.skilltree_schematics.classOrigin.2]
				vars.leveltracker.skilltree_schematics.classOrigin := [Round(x), Round(y)]
				If IsNumber(vars.leveltracker.skilltree_schematics.xPos)
					vars.leveltracker.skilltree_schematics.xPos -= offsets.1, vars.leveltracker.skilltree_schematics.yPos -= offsets.2

				If !vars.poe_version
					For kAttr, vAttr in {"blue": 0, "green": 120, "red": 240}
					{
						rAttr := 130 * scale
						xAttr := rAttr * cos((vAttr - 90) * 0.017453293252) + x_coord
						yAttr := rAttr * sin((vAttr - 90) * 0.017453293252) + y_coord
						kAttr .= (mode = "overview") ? "3" : ""
						Gdip_FillEllipseC(gBitmap, brush[kAttr], xAttr, yAttr, radii.normal * scale, radii.normal * scale)
					}
				Continue
			}

			If (type = "mastery")
			{
				For iMastery, vMastery in tree.nodes[node].masteryEffects
					If (vMastery = masteries[node])
						Gdip_TextToGraphics(gBitmap, iMastery, "x" x - Round(rNode * 0.65) " y" y - rNode * 0.8 " s" Floor(rNode * 1.8))
			}
			For inner in (outer = 1 && !vars.poe_version ? [1, 2] : [1])
				For index2, connection in (vars.poe_version ? tree.nodes[node].connections : tree.nodes[node][(inner = 1) ? "out" : "in"])
				{
					If vars.poe_version
						connection_array := connection.Clone(), connection := connection.id

					If !vars.poe_version && !LLK_HasVal((outer = 2) ? allocated : allocated_previous, connection) || vars.poe_version && !LLK_HasVal(allocated_previous, connection) && !LLK_HasVal(allocated, connection)
					|| tree.nodes[connection].ismastery || tree.nodes[connection].HasKey(vars.poe_version ? "classesstart" : "classstartindex")
					|| tree.nodes[connection].expansionjewel.parent || tree.nodes[connection].ascendancyname && !LLK_HasVal(ascendancy_points, connection)
					|| (tree.nodes[node].ascendancyname = "ascendant") && InStr(tree.nodes[node].name, "Path of the ")
					|| (inner = 2) && tree.nodes[node].ismastery
						Continue
					group2 := tree.nodes[connection].group
					x_coord2 := (tree.groups[group2].x - xOffset) * scale, y_coord2 := (tree.groups[group2].y - yOffset) * scale
					orbit2 := tree.nodes[connection].orbit, orbitIndex2 := tree.nodes[connection].orbitIndex

					If (tree.constants.skillsperorbit[orbit2] = 16)
						angle2 := angles.1[orbitIndex2]
					Else If (tree.constants.skillsperorbit[orbit2] = 40)
						angle2 := angles.2[orbitIndex2]
					Else angle2 := (360/tree.constants.skillsperorbit[orbit2]) * orbitIndex2

					radius2 := tree.constants.orbitradii[orbit2] * scale
					x2 := radius2 * cos((angle2 - 90) * 0.017453293252) + x_coord2
					y2 := radius2 * sin((angle2 - 90) * 0.017453293252) + y_coord2

					rConnection := tree.constants.orbitradii[Abs(connection_array.orbit)] * (connection_array.orbit < 0 ? -1 : 1) * scale
					rConnection := !rConnection ? 0 : rConnection
					If vars.poe_version && rConnection
					{
						cX := (x + x2)/2 + (y2 - y) * (rConnection > 0 ? 1 : -1) * Sqrt((rConnection**2 / ((x - x2)**2 + (y - y2)**2)) - 0.25)
						cY := (y + y2)/2 + (x - x2) * (rConnection > 0 ? 1 : -1) * Sqrt((rConnection**2 / ((x - x2)**2 + (y - y2)**2)) - 0.25)
						angleCheck1 := [], angleCheck2 := []
						
						Loop
						{
							If (A_Index > 360)
								Break
							xCheck := Abs(rConnection) * cos((A_Index - 90) * 0.017453293252) + cX
							yCheck := Abs(rConnection) * sin((A_Index - 90) * 0.017453293252) + cY
							angleCheck1[A_Index] := [x - xCheck, y - yCheck]
							angleCheck2[A_Index] := [x2 - xCheck, y2 - yCheck]
						}
						Loop 2
						{
							min := 1000000, iOuter := A_Index
							For index, val in angleCheck%iOuter%
								If (Abs(val.1) + Abs(val.2) < min)
									angle%iOuter% := index, min := Abs(val.1) + Abs(val.2)
						}
						x_coord2 := cX, y_coord2 := cY, radius2 := Abs(rConnection)
					}

					path1 := (360 - Max(rConnection ? angle1 : angle, angle2)) + Min(rConnection ? angle1 : angle, angle2), path2 := Max(rConnection ? angle1 : angle, angle2) - Min(rConnection ? angle1 : angle, angle2)

					If (path1 <= path2)
						start := Max(rConnection ? angle1 : angle, angle2), end := Min(rConnection ? angle1 : angle, angle2) + 360
					Else start := Min(rConnection ? angle1 : angle, angle2), end := Max(rConnection ? angle1 : angle, angle2)
					points := []

					If vars.poe_version && rConnection || (orbit = orbit2) && (group = group2) && (!vars.poe_version || tree.constants.orbitradii[Abs(connection_array.orbit)] = 0)
						Loop
						{
							If (start + A_Index - 1 > end) || (A_Index > 360)
								Break
							points.Push(radius2 * cos((start - 90 + A_Index - 1) * 0.017453293252) + x_coord2)
							points.Push(radius2 * sin((start - 90 + A_Index - 1) * 0.017453293252) + y_coord2)
						}
					Else points := [x, y], points.Push(radius2 * cos((angle2 - 90) * 0.017453293252) + x_coord2), points.Push(radius2 * sin((angle2 - 90) * 0.017453293252) + y_coord2)

					new_connection := !LLK_HasVal(ascendancy ? ascendancy_trees[ascendancy - 1] : allocated_previous, connection) || new_node && LLK_HasVal(allocated, connection) ? 1 : 0
					Gdip_DrawCurve(gBitmap, pen[(outer = 1) || vars.poe_version && LLK_HasVal(allocated_previous, connection) && !LLK_HasVal(allocated, connection) ? "red" : new_connection ? "green" : "white"], points, 0.5)
					type := tree.nodes[connection].isnotable || tree.nodes[node].isjewelsocket ? "notable" : tree.nodes[connection].ismastery ? "mastery" : tree.nodes[connection].iskeystone ? "keystone" : "normal"
				}
		}

	If !IsNumber(xPos := vars.leveltracker.skilltree_schematics.xPos)
		vars.leveltracker.skilltree_schematics.xPos := (Blank(xPos) ? vars.monitor.x + vars.client.xc : vars.general.xMouse) - vars.leveltracker.skilltree_schematics.classOrigin.1
		, vars.leveltracker.skilltree_schematics.yPos := (Blank(xPos) ? vars.monitor.y + vars.client.yc : vars.general.yMouse) - vars.leveltracker.skilltree_schematics.classOrigin.2
	xPos := (mode = "overview") ? vars.monitor.x + (horizontal ? vars.monitor.w//2 - mWidth//2 : 0) : vars.leveltracker.skilltree_schematics.xPos
	yPos := (mode = "overview") ? vars.monitor.y + vars.monitor.h//(divisor := horizontal ? 1 : 2) - mHeight//divisor : vars.leveltracker.skilltree_schematics.yPos
	UpdateLayeredWindow(hwnd_skilltree_schematics, hdcBitmap, xPos, yPos, mWidth, mHeight)
	SelectObject(hdcBitmap, obmBitmap), DeleteObject(hbmBitmap), DeleteDC(hdcBitmap), Gdip_DeleteGraphics(gBitmap)

	toggle := !toggle, GUI_name := "skilltree_schematics_info" toggle, label := "tree: " active "/" tree_count
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_skilltree_schematics_info +Ownerskilltree_schematics"
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Font, % "s" (fSize := settings.leveltracker.fSize + 4) " cWhite", % vars.system.font
	Gui, %GUI_name%: Margin, 0, 0

	LLK_PanelDimensions([tree_title], fSize, wPanel, hPanel), LLK_PanelDimensions([label], fSize, wPanel2, hPanel2)
	hwnd_old := vars.hwnd.skilltree_schematics.info, vars.hwnd.skilltree_schematics := {"main": hwnd_skilltree_schematics, "info": hwnd_skilltree_schematics_info}
	Gui, %GUI_name%: Add, Text, % "Section Border Center BackgroundTrans HWNDhwnd x" 100 + (wPanel2 > wPanel ? (wDiff := wPanel2/2 - wPanel/2 + hPanel2/2) : 0), % " " tree_title " "
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack HWNDhwnd1", 0
	Gui, %GUI_name%: Add, Text, % "xs Section y+-1 x" 100 + (Blank(wDiff) ? wPanel/2 - wPanel2/2 - hPanel2/2 : 0) " Border Center BackgroundTrans", % " " label " "
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack", 0
	Gui, %GUI_name%: Add, Pic, % "ys x+-1 hp-2 w-1 Border BackgroundTrans", % "HBitmap:*" vars.pics.global.help
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack HWNDhwnd", 0
	vars.hwnd.help_tooltips["leveltrackerschematics_how-to"] := hwnd
	Gui, %GUI_name%: Show, % "NA x10000 y10000 w" 200 + Max(wPanel, wPanel2 + hPanel - 1)
	WinGetPos,,, wWin, hWin, ahk_id %hwnd_skilltree_schematics_info%
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x + vars.client.xc - wWin//2 " y" vars.monitor.y + vars.client.y
	LLK_Overlay(hwnd_skilltree_schematics_info, "show",, GUI_name), LLK_Overlay(hwnd_skilltree_schematics, "show",, "skilltree_schematics"), LLK_Overlay(hwnd_old, "destroy")

	If ascendancy || (mode = "overview")
	{
		If ascendancy && (ascendancy_points.Count() < 2)
			LLK_ToolTip(Lang_Trans("lvltracker_treeascendancy"), 1,,,, "Red")
		KeyWait, % A_ThisHotkey
		wait := 0
		If (mode = "overview")
		{
			For kPens, vPen in pen
				Gdip_DeletePen(vPen)
			pen := ""
		}
		Leveltracker_PobSkilltree()
		Return
	}
	If mode && InStr("reset, prev, next", mode)
		KeyWait, % A_ThisHotkey
	wait := 0, vars.leveltracker.skilltree_schematics.GUI := 1
	Return
}

Leveltracker_Progress(mode := 0) ;advances the guide and redraws the overlay
{
	local
	global vars, settings, db
	static in_progress, toggle := 0

	If in_progress
		Return

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	import := vars.leveltracker.guide.import, in_progress := 1, vars.leveltracker.last := A_TickCount*100 ;dummy-value to prevent Loop_main() from prematurely fading the overlay
	guide := vars.leveltracker.guide, areas := db.leveltracker.areas, areaIDs := db.leveltracker.areaIDs, timer := vars.leveltracker.timer ;short-cut variables
	vars.leveltracker.fade := mode ? 0 : vars.leveltracker.fade, vars.leveltracker.toggle := mode ? 1 : vars.leveltracker.toggle
	profile := settings.leveltracker.profile

	If !vars.log.act || (vars.log.act = "c")
		vars.log.act := LLK_HasVal(areas, vars.log.areaID,,,, 1), vars.log.act := (vars.poe_version && vars.log.act > 3 ? vars.log.act - 3 : vars.log.act) . (InStr(vars.log.areaID, "c_") ? "c" : "")

	If (mode = "init")
		GuiControl,, % vars.hwnd.LLK_panel.leveltracker, img\GUI\leveltracker.png

	While !Leveltracker("condition", guide.progress + 1)
		guide.progress += 1

	guide.group1 := import[guide.progress + 1].Clone()
	If guide.group1.condition
		guide.group1 := guide.group1.lines.Clone()

	For index, val in guide.group1
		If (check := InStr(val, " `;"))
			guide.group1[index] := SubStr(val, 1, check - 1)

	guide.target_area := ""
	For index, val in guide.group1
		If InStr(val, "areaid") && !InStr(val, "(hint)")
			Loop, Parse, val, %A_Space%
				If InStr(A_LoopField, "areaid")
					guide.target_area := StrReplace(A_LoopField, "areaid")

	If vars.leveltracker.fast ;skip redrawing the GUIs during fast-forwarding
	{
		in_progress := 0
		Return
	}

	toggle := !toggle, GUI_name_back := "leveltracker_back" toggle, GUI_name_main := "leveltracker_main" toggle
	Leveltracker_PageDraw(GUI_name_main, GUI_name_back, 0, width, height, hwnd_old)

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
		vars.hwnd.leveltracker.timer_total := hwnd, act := (timer.current_act = 11 ? (vars.poe_version ? 6 : 10) : timer.current_act), act := vars.poe_version ? vars.leveltracker.acts[act] : act
		Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w" wButtons * 2, % "a" act
		vars.hwnd.leveltracker.timer_button := hwnd
		Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w" wPanels (timer.current_act = 11 ? " cLime" : (timer.pause = -1) ? " cGray" : ""), % FormatSeconds(timer.current_split, 0)
		vars.hwnd.leveltracker.timer_act := hwnd
	}
	Gui, %GUI_name_controls2%: Add, Text, % "Section xs " (settings.leveltracker.timer ? "xs y+-1" : "") " Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels, % settings.leveltracker.layouts ? check " zl" : ""
	level_diff := vars.log.level - vars.log.arealevel
	vars.hwnd.leveltracker.layouts := hwnd
	If vars.log.level
		exp_info := vars.poe_version ? RegExMatch(vars.log.areaID, "i)^hideout|_town$") ? "" : Lang_Trans("lvltracker_exp") " " (level_diff > 0 ? "+" : "") level_diff : Leveltracker_Experience("", 1)
	color := !vars.poe_version ? (!InStr(exp_info, "100%") ? "Red" : "Lime") : (Abs(level_diff) > 3 ? "Red" : Abs(level_diff) > 2 ? "FF8000" : "Lime")
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w" wButtons, % "<"
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans Center w" wButtons, % ">"
	Gui, %GUI_name_controls2%: Add, Text, % "ys hp Border 0x200 BackgroundTrans HWNDhwnd Center w"wPanels " c" color, % StrReplace(exp_info, (exp_info = "100%") ? "" : "100%")
	vars.hwnd.leveltracker.experience := hwnd

	Gui, %GUI_name_controls2%: Show, % "NA x10000 y10000"
	Gui, %GUI_name_controls1%: Show, % "NA x10000 y10000"
	WinGetPos,,, wControls, hControls, % "ahk_id " vars.hwnd.leveltracker.controls1

	width -= 2, height -= 2, height_total := height + hControls + 2
	xPos := Blank(settings.leveltracker.xCoord) ? vars.client.xc - width / 2 : settings.leveltracker.xCoord, xPos := (xPos >= vars.monitor.w / 2) ? xPos - width : xPos
	xPos := (xPos >= vars.monitor.w) ? vars.monitor.w - width - 2 : xPos
	yPos := Blank(settings.leveltracker.yCoord) ? vars.client.y - vars.monitor.y + vars.client.h + 1 : settings.leveltracker.yCoord, yPos := (yPos >= vars.monitor.h / 2) ? yPos - height_total : yPos
	yPos := (yPos >= vars.monitor.h) ? vars.monitor.h - height_total + 1 : yPos

	Gui, %GUI_name_controls2%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos + height + 1
	Gui, %GUI_name_controls1%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos + height + 1

	Gui, %GUI_name_back%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	Gui, %GUI_name_main%: Show, % (vars.leveltracker.fade ? "Hide" : "NA") " x" vars.monitor.x + xPos " y" vars.monitor.y + yPos
	vars.leveltracker.coords := {"x1": xPos, "x2": xPos + width, "y1": yPos, "y2": yPos + height_total - 1, "w": width, "h": height_total}
	LLK_Overlay(vars.hwnd.leveltracker.background, vars.leveltracker.fade ? "hide" : "show",, GUI_name_back), LLK_Overlay(vars.hwnd.leveltracker.main, vars.leveltracker.fade ? "hide" : "show",, GUI_name_main)
	LLK_Overlay(hwnd_old.1, "destroy"), LLK_Overlay(hwnd_old.2, "destroy")

	LLK_Overlay(vars.hwnd.leveltracker.controls1, vars.leveltracker.fade ? "hide" : "show",, GUI_name_controls1), LLK_Overlay(vars.hwnd.leveltracker.controls2, vars.leveltracker.fade ? "hide" : "show",, GUI_name_controls2)
	LLK_Overlay(hwnd_old.3, "destroy"), LLK_Overlay(hwnd_old.4, "destroy")
	vars.leveltracker.last := A_TickCount
	vars.leveltracker.wait := 0, in_progress := 0
}

Leveltracker_ProgressReset(profile := "")
{
	local
	global vars, settings

	IniWrite, 0, % "ini" vars.poe_version "\leveling guide" profile ".ini", Progress, pages
	If !(custom := settings.leveltracker["guide" profile].info.custom) ;if the guide is not custom, reload the default guide in case it has been updated since last used
		Leveltracker_GuideEditor("default#" profile)

	If (settings.leveltracker.profile = profile)
	{
		If !custom
			Leveltracker_Load()
		vars.leveltracker.guide.progress := 0
		If LLK_Overlay(vars.hwnd.leveltracker.main, "check")
			Leveltracker_Progress(1)
	}
	KeyWait, LButton
}

Leveltracker_ScreencapPaste(index)
{
	local
	global vars, settings

	active := vars.leveltracker.screencap_active
	If InStr(Clipboard, ":\")
	{
		check := 0
		Loop, Parse, Clipboard, `n, `r
			check += InStr(".jpg.png.bmp", SubStr(A_LoopField, -3)) ? 0 : 1
		If !check
		{
			LLK_ToolTip(Lang_Trans("lvltracker_multipaste"), 2,,,, "red")
			Return
		}
		If InStr(Clipboard, ":\",,, 2)
		{
			If InStr(index, "-")
			{
				LLK_ToolTip(Lang_Trans("lvltracker_multipaste", 2), 2,,,, "red")
				Return
			}
			MsgBox, 4, Clipboard multi-paste, % Lang_Trans("lvltracker_multipaste", 3, [LLK_InStrCount(Clipboard, ":"), index])
			IfMsgBox No
				Return
		}
		Loop, Parse, Clipboard, `n, `r
			FileCopy, % A_LoopField, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(index + A_Index - 1 < 10 ? "0" : "") index + A_Index - 1 "].*", 1
	}
	Else
	{
		pBitmap := Gdip_CreateBitmapFromClipboard()
		If (pBitmap < 0)
		{
			LLK_ToolTip(Lang_Trans("global_imageinvalid"), 1.5,,,, "red")
			Return
		}
		Gdip_SaveBitmapToFile(pBitmap, "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["(InStr(index, "-") ? "lab" : "") StrReplace(index, "-") "].png", 100)
		Gdip_DisposeImage(pBitmap)
	}
	Return 1
}

Leveltracker_Skilltree(index := 0)
{
	local
	global vars, settings
	static toggle := 0

	skilltree := vars.leveltracker.skilltree ;short-cut variable
	If !IsNumber(skilltree.active) || !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["skilltree.active "]*")
		skilltree.active := "00"
	index := index ? index : skilltree.active, skilltree.files := [], skilltree.files_lab := []

	Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[*]*"
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

		Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[*]*"
		{
			If InStr(A_LoopFileName, "[lab") && !InStr(index, "lab")
				Continue
			count += 1
			If (index = "00" || SubStr(A_LoopFileName, 2, StrLen(index)) = index) && InStr("jpg,png,bmp", A_LoopFileExt) && (!InStr(A_LoopFileName, "[lab") || InStr(index, "lab"))
			{
				img := A_LoopFilePath, caption := StrReplace(A_LoopFileName, "."A_LoopFileExt), caption := SubStr(caption, InStr(caption, "]") + (InStr(caption, "] ") ? 2 : 1))
				caption := StrReplace(caption, "&", "&&")
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
			Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab*]*"
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
		If Blank(A_Gui) && !Leveltracker_SkilltreeHover()
			Return
		If !Blank(A_Gui)
			KeyWait, LButton
		Omni_Release()
		LLK_Overlay(leveltracker_skilltree, "destroy"), LLK_Overlay(leveltracker_skilltree_labs, "destroy")
	}
	Else LLK_ToolTip(Lang_Trans("lvltracker_noimages"), 1.5,,,, "red")
	vars.hwnd.Delete("leveltracker_skilltree")
}

Leveltracker_SkilltreeHover()
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
			If !FileExist("img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\["check "]*")
			{
				WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.main
				LLK_ToolTip(Lang_Trans("lvltracker_endreached"),, x, y,, "yellow")
				KeyWait, RButton
				check := ""
				Continue
			}
			Else Break
		}

		If WinExist("ahk_id " vars.hwnd.leveltracker_skilltree.labs) && WinExist("ahk_id " vars.hwnd.leveltracker_skilltree.lab) && (vars.general.wMouse != Gui_Dummy(vars.hwnd.leveltracker_skilltree.labs))
			LLK_Overlay(vars.hwnd.leveltracker_skilltree.lab, "destroy")
		HWNDcheck := LLK_HasVal(vars.hwnd.leveltracker_skilltree, vars.general.cMouse)
		If HWNDcheck && (!WinExist("ahk_id "vars.hwnd.leveltracker_skilltree.lab) || lab_active != HWNDcheck)
		{
			Leveltracker_SkilltreeLab(HWNDcheck)
			lab_active := HWNDcheck
		}
	}
	LLK_Overlay(vars.hwnd.leveltracker_skilltree.lab, "destroy")
	If !Blank(check)
	{
		skilltree.active := check
		IniWrite, % skilltree.active, % "ini" vars.poe_version "\leveling tracker.ini", settings, % "last skilltree-image" settings.leveltracker.profile
		SetTimer, Leveltracker_Skilltree, -100
		Return 0
	}
	Return 1
}

Leveltracker_SkilltreeLab(file)
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

	Loop, Files, % "img\GUI\skill-tree" settings.leveltracker.profile (vars.poe_version ? "\PoE 2" : "") "\[lab*]*"
		If (SubStr(A_LoopFileName, 2, 4) = file)
			image := A_LoopFilePath, caption := SubStr(StrReplace(A_LoopFileName, "."A_LoopFileExt), InStr(A_LoopFileName, "]") + 1), caption := StrReplace(StrReplace(caption, " ",,, 1), "&", "&&")
	Gui, %GUI_name%: Add, Picture, % "Section BackgroundTrans Border", % image
	Gui, %GUI_name%: Add, Text, % "xs y+-1 wp Center BackgroundTrans Border"(!caption ? " h"settings.general.fHeight/2 : ""), % caption
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack c404040 Border", 0
	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.leveltracker_skilltree.lab
	Gui, %GUI_name%: Show, % "NA x"vars.client.x + skilltree.w + 2*vars.client.w//250 + vars.monitor.h//25 " y" vars.monitor.y + vars.client.yc - h//2
	LLK_Overlay(leveltracker_skilltree_lab, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

Leveltracker_Strings()
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

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	For key, val in vars.leveltracker.guide.gems
	{
		regex := StrReplace(db.leveltracker.regex[val].1, " ", "."), regex := !regex ? StrReplace(val, " ", ".") : regex
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

Leveltracker_Timer(mode := "")
{
	local
	global vars, settings, db

	timer := vars.leveltracker.timer
	If mode && InStr("pause,reset", mode)
	{
		If (mode = "pause") && (timer.current_act = 11)
			error := [Lang_Trans("lvltracker_timererror", 1), 1.5, "yellow"]
		Else If (mode = "reset") && !(vars.log.areaID = "1_1_1" || vars.log.areaID = "g1_1")
			error := [Lang_Trans("lvltracker_timererror", 2), 2, "red"]
		Else If (mode = "reset") && !timer.pause
			error := [Lang_Trans("lvltracker_timererror", 3), 1, "red"]
		Else If (mode = "pause") && settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")
			error := [Lang_Trans("lvltracker_timererror", 4), 2, "red"]

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
				Leveltracker_ProgressReset(settings.leveltracker.profile)
				IniWrite, % "", % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, name
				IniWrite, 0, % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, time
				Loop, % vars.poe_version ? 6 : 10
					IniWrite, % "", % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, act %A_Index%
				vars.leveltracker.Delete("timer")
				Init_leveltracker(), Leveltracker_Progress(1)
				Return
			}
			Else Return
		}
		Else If (mode = "pause") && (timer.current_act != 11)
		{
			If !InStr(timer.name, ",") && (vars.log.areaID = "1_1_1" || vars.log.areaID = "g1_1")
			{
				FormatTime, date,, ShortDate
				FormatTime, time,, Time
				timer.name := date ", " time
				IniWrite, % """"timer.name """", % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, name
				new_run := 1
			}
			LLK_ToolTip(new_run ? Lang_Trans("lvltracker_timermessage", 1) : (timer.pause != 0) ? Lang_Trans("lvltracker_timermessage", 2) : Lang_Trans("lvltracker_timermessage", 3),, vars.leveltracker.coords.x1 + vars.leveltracker.coords.w / 2, yTooltip,, "lime",,,, 1)
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

	If !IsObject(db.leveltracker)
		DB_Load("leveltracker")

	If vars.hwnd.leveltracker.main && (timer.pause = 1) && (db.leveltracker.areas.HasKey(vars.log.areaID) || InStr(vars.log.areaID, "labyrinth")) && (timer.current_act != 11) ;resume the timer after leaving a hideout (if it wasn't paused manually by the user)
		timer.pause := 0

	If vars.hwnd.leveltracker.main && (timer.pause = 0) ;advance the timer
	{
		timer.current_split += (timer.current_act = 11) ? 0 : 1, timer.pause := (settings.leveltracker.pausetimer && InStr(vars.log.areaID, "hideout")) || (timer.current_act = 11) ? 1 : 0
		If vars.log.act && (timer.current_act + 1 = (InStr(vars.log.act, "c") ? StrReplace(vars.log.act, "c") + 3 : vars.log.act)
		|| vars.poe_version && vars.log.act = 11 && timer.current_act = 6) ;player enters the next act: save previous act's time, add it to total time, then reset it
		{
			IniWrite, % timer.current_split, % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, % "act "timer.current_act
			If InStr(timer.name, ",")
				Leveltracker_TimerCSV()
			timer.total_time += timer.current_split, timer.current_act += 1, timer.current_act := (vars.poe_version && timer.current_act = 7) ? 11 : timer.current_act
			timer.current_split := (timer.current_act = 11) ? timer.current_split : 0
			act := (timer.current_act = 11 ? (vars.poe_version ? 6 : 10) : timer.current_act), act := vars.poe_version ? vars.leveltracker.acts[act] : act
			GuiControl, Text, % vars.hwnd.leveltracker.timer_button, % "a" act
			IniWrite, % timer.current_split, % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, time
			If (timer.current_act = 11)
				Leveltracker_Progress(1)
		}
		Else If timer.current_split && !Mod(timer.current_split, 60) && (timer.current_split != timer.current_split0) ;save current time every minute as backup for potential crashes
			IniWrite, % (timer.current_split0 := timer.current_split), % "ini" vars.poe_version "\leveling tracker.ini", % "current run" settings.leveltracker.profile, time
		If !vars.leveltracker.wait ;update the timer every cycle
		{
			GuiControl, Text, % vars.hwnd.leveltracker.timer_total, % FormatSeconds(timer.total_time + (timer.current_act = 11 ? 0 : timer.current_split), 0)
			GuiControl, Text, % vars.hwnd.leveltracker.timer_act, % FormatSeconds(timer.current_split, 0)
		}
	}
}

Leveltracker_TimerCSV()
{
	local
	global vars, settings

	If !FileExist("exports\campaign runs" (vars.poe_version ? " (PoE 2)" : "") ".csv")
		FileAppend, % """date, time"",act 1,act 2,act 3,act 4,act 5,act 6" (!vars.poe_version ? ",act 7,act 8,act 9,act 10" : ""), % "exports\campaign runs" (vars.poe_version ? " (PoE 2)" : "") ".csv"

	FileRead, csv, % "exports\campaign runs" (vars.poe_version ? " (PoE 2)" : "") ".csv"
	If InStr(csv, vars.leveltracker.timer.name)
		FileAppend, % ","""FormatSeconds(vars.leveltracker.timer.current_split) ".00""", % "exports\campaign runs" (vars.poe_version ? " (PoE 2)" : "") ".csv"
	Else FileAppend, % "`n"""vars.leveltracker.timer.name ""","""FormatSeconds(vars.leveltracker.timer.current_split) ".00""", % "exports\campaign runs" (vars.poe_version ? " (PoE 2)" : "") ".csv"
}

Leveltracker_Toggle(mode)
{
	local
	global vars

	LLK_Overlay(vars.hwnd.leveltracker.main, mode), LLK_Overlay(vars.hwnd.leveltracker.background, mode), LLK_Overlay(vars.hwnd.leveltracker.controls2, mode), LLK_Overlay(vars.hwnd.leveltracker.controls1, mode)
}

Leveltracker_ZoneLayouts(mode := 0, drag := 0, cHWND := "")
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
	vars.general.drag := 0

	If cHWND && !longpress && (drag = 1)
	{
		settings.leveltracker.aLayouts := (settings.leveltracker.aLayouts = "vertical") ? "horizontal" : "vertical"
		IniWrite, % settings.leveltracker.aLayouts, % "ini" vars.poe_version "\leveling tracker.ini", settings, zone-layouts arrangement
	}
	Else If cHWND && !longpress && (drag = 2)
		x := (settings.leveltracker.aLayouts = "vertical") ? vars.client.x - vars.monitor.x : "", y := (settings.leveltracker.aLayouts = "vertical") ? "" : vars.client.y - vars.monitor.y

	If !Blank(x) || !Blank(y)
	{
		settings.leveltracker.xLayouts := x, settings.leveltracker.yLayouts := y
		IniWrite, % settings.leveltracker.xLayouts, % "ini" vars.poe_version "\leveling tracker.ini", settings, zone-layouts x
		IniWrite, % settings.leveltracker.yLayouts, % "ini" vars.poe_version "\leveling tracker.ini", settings, zone-layouts y
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

Leveltracker_ZoneLayoutsSize(hotkey)
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
	Leveltracker_ZoneLayouts((hotkey = "MButton") ? 1 : 0)
	If (hotkey = "MButton")
	{
		KeyWait, MButton
		Leveltracker_ZoneLayouts()
	}
	resizing := 0
}
