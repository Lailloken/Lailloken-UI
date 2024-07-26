Init_recombination()
{
	local
	global vars, settings

	If !FileExist("ini\recombination.ini")
		IniWrite, % "", ini\recombination.ini, settings
	If !IsObject(settings.recombination)
		settings.recombination := {}

	ini := IniBatchRead("ini\recombination.ini")
	dcolors := settings.recombination.dcolors := ["00FF00", "FF0000", "FF8000"]
	settings.recombination.colors := [!Blank(check1 := ini.settings.color1) ? check1 : dColors.1, !Blank(check2 := ini.settings.color2) ? check2 : dColors.2, !Blank(check3 := ini.settings.color3) ? check3 : dColors.3]
	settings.recombination.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.recombination.fSize, font_height, font_width), settings.recombination.fWidth := font_width, settings.recombination.fHeight := font_height
}

Recombination_()
{
	local
	global vars, settings

	If !IsObject(vars.recombination.item1)
		vars.recombination.item1 := {}, vars.recombination.item2 := {}
	vars.recombination.desired := {"prefixes": {}, "suffixes": {}}, vars.recombination.desired_mods := 0
	If Blank(vars.recombination.wStash)
		vars.recombination.wStash := Floor(vars.client.h * (37/60)), vars.recombination.wInventory := Floor(vars.client.h * 0.6155)
	If !IsObject(vars.recombination.influences)
	{
		vars.recombination.influences := {"shaper": "", "elder": "", "crusader": "", "redeemer": "", "hunter": "", "warlord": "", "synthesis": ""}
		For key in vars.recombination.influences
			vars.recombination.influences[key] := {"item": LangTrans("items_" key), "affixes": [LangTrans("items_" key "_prefix"), LangTrans("items_" key "_suffix")]}
	}

	influences := vars.recombination.influences
	clip := SubStr(vars.omnikey.clipboard, InStr(vars.omnikey.clipboard, LangTrans("items_ilevel"))), clip := StrReplace(clip, "`r`n", ";")
	clip := StrReplace(clip, " (crafted)"), clip := StrReplace(clip, " — " LangTrans("items_unscalable"))
	item := {"name": LLK_StringCase(vars.omnikey.item.name), "itembase": LLK_StringCase(vars.omnikey.item.itembase), "class": LLK_StringCase(vars.omnikey.item.class), "prefixes": [], "suffixes": []
	, "mod_counts": {"prefixes": 3, "suffixes": 3}, "influences": []}

	Loop, Parse, % vars.omnikey.clipboard, `n, `r
		If LangMatch(A_LoopField, vars.lang.items_prefix_allowed)
			item.mod_counts.prefixes += SubStr(A_LoopField, 1, 2)
		Else If LangMatch(A_LoopField, vars.lang.items_suffix_allowed)
			item.mod_counts.suffixes += SubStr(A_LoopField, 1, 2)

	For key, object in influences
		If InStr(clip, ";" object.item ";")
			item.influences.Push(key)

	Loop, Parse, clip, `;, %A_Space%
	{
		If InStr(A_LoopField, LangTrans("items_implicit")) || !LLK_PatternMatch(A_LoopField, "", [LangTrans("items_prefix"), LangTrans("items_suffix")])
			Continue
		mod := "", type := InStr(A_LoopField, LangTrans("items_prefix")) ? "prefixes" : "suffixes", fractured := InStr(A_LoopField, "(fractured)")
		Loop, Parse, % StrReplace(A_LoopField, " (fractured)"), `n, %A_Space%
		{
			affix := ""
			If InStr(A_LoopField, "{") && InStr(A_LoopField, """")
				affix_name := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), affix_name := SubStr(affix_name, 1, InStr(affix_name, """") - 1)
			If InStr(A_LoopField, "{") || (SubStr(A_LoopField, 1, 1) = "(")
				Continue
			Loop, Parse, A_LoopField
			{
				If !IsNumber(A_LoopField) && !InStr("+-()%.", A_LoopField)
					affix .= A_LoopField
			}
			Loop, Parse, affix, `;, % " `n"
				affix := A_LoopField
			While InStr(affix, "  ")
				affix := StrReplace(affix, "  ", " ")
			mod .= affix "`n"
		}
		Loop, Parse, mod, `;, % " `n"
			mod := A_LoopField
		item[type].Push([LLK_StringCase(mod), [affix_name, fractured]])
	}
	If !(item.prefixes.Count() + item.suffixes.Count())
	{
		LLK_ToolTip(LangTrans("global_errorname", 2),,,,, settings.recombination.colors.2)
		Return
	}
	Else If !A_Gui
		LLK_ToolTip(LangTrans("lvltracker_gearadd"), 1,,,, settings.recombination.colors.1)

	If (vars.recombination.item1.prefixes.Count() + vars.recombination.item1.suffixes.Count())
		vars.recombination.item2 := vars.recombination.item1.Clone()
	vars.recombination.item1 := item.Clone()
	Recombination_GUI()
}

Recombination_GUI(cHWND := "")
{
	local
	global vars, settings
	static toggle := 0

	If !Blank(cHWND)
	{
		check := LLK_HasVal(vars.hwnd.recombination, cHWND), control := SubStr(check, InStr(check, "_") + 1)
		If InStr(check, "edit_")
		{
			item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
			input := LLK_ControlGet(cHWND), modified := (input != vars.recombination["item" item_no][affix][mod_slot].1)
			GuiControl, % "+c" (modified ? settings.recombination.colors.2 : "Black"), % cHWND
			GuiControl, % "movedraw", % cHWND

			modified := 0
			For key, val in vars.hwnd.recombination
				If InStr(key, "edit_")
				{
					input := LLK_ControlGet(val), control := SubStr(key, InStr(key, "_") + 1)
					item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
					modified += (input != vars.recombination["item" item_no][affix][mod_slot].1)
				}
			GuiControl, % (modified ? "+c" settings.recombination.colors.2 " +gRecombination_GUI" : "+cWhite -g"), % vars.hwnd.recombination.chance
			GuiControl, % "Text", % vars.hwnd.recombination.chance, % modified ? LangTrans("recomb_refresh") : vars.recombination.chance
			GuiControl, % "movedraw", % vars.hwnd.recombination.chance
			GuiControl, % (modified || !vars.recombination.desired_mods ? "+" : "-") "Hidden", % vars.hwnd.recombination.rerun
			GuiControl, % "movedraw", % vars.hwnd.recombination.rerun
			For key, val in vars.hwnd.recombination
				If InStr(key, "check_")
				{
					If InStr(key, "0check_")
						GuiControl, % (!modified ? "+" : "-") "Hidden", % val
					Else GuiControl, % (modified ? "+" : "-") "Disabled", % val
					GuiControl, % "movedraw", % val
				}
		}
		Else If InStr(check, "check_") || (check = "rerun")
		{
			If (check != "rerun")
			{
				affix := SubStr(control, 1, InStr(control, "_") - 1), mod := SubStr(control, InStr(control, "_") + 1)
				If (input := LLK_ControlGet(cHWND))
				{
					If (vars.recombination.desired[affix].Count() = Min(3, vars.recombination.item1.mod_counts[affix]))
					{
						GuiControl,, % cHWND, 0
						LLK_ToolTip(LangTrans("recomb_desired"), 1.5,,,, "Red")
						Return
					}
					vars.recombination.desired[affix][mod] := 1
				}
				Else vars.recombination.desired[affix].Delete(mod)
			}
			desired_mods := vars.recombination.desired_mods := vars.recombination.desired.prefixes.Count() + vars.recombination.desired.suffixes.Count()
			GuiControl, Text, % vars.hwnd.recombination.chance, % desired_mods ? (vars.recombination.chance := Recombination_Simulate()) : ""
			GuiControl, % (desired_mods ? "-" : "+") "Hidden", % vars.hwnd.recombination.rerun,
		}
		Else If (check = "chance")
		{
			For key, val in vars.hwnd.recombination
				If InStr(key, "edit_")
				{
					input := LLK_ControlGet(val), control := SubStr(key, InStr(key, "_") + 1)
					item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
					Loop, Parse, input, µ, % " `n"
						input := A_LoopField
					If (input != vars.recombination["item" item_no][affix][mod_slot].1)
					{
						If !IsObject(vars.recombination["item" item_no][affix][mod_slot])
							vars.recombination["item" item_no][affix][mod_slot] := []
						vars.recombination["item" item_no][affix][mod_slot] := [input]
					}
				}
			remove_prefixes := [], remove_suffixes := []
			For index, affix in ["prefixes", "suffixes"]
			{
				Loop 2
					Loop, % (length := vars.recombination["item" (outer := A_Index)][affix].Length() + 1)
						If (length - A_Index > 0) && Blank(vars.recombination["item" outer][affix][length - A_Index].1)
							vars.recombination["item" outer][affix].RemoveAt(length - A_Index)

				For key in vars.recombination.desired[affix]
					If !LLK_HasVal(vars.recombination.item1, key,,,, 1) && !LLK_HasVal(vars.recombination.item2, key,,,, 1)
						remove_%affix%.Push(key)

				For index, val in remove_%affix%
					vars.recombination.desired[affix].Delete(val)
			}
		}
		Else If InStr(check, "font_")
		{
			KeyWait, LButton
			If (control = "reset")
				settings.recombination.fSize := settings.general.fSize
			Else settings.recombination.fSize += (control = "plus") ? 1 : (settings.recombination.fSize > 6 && control = "minus") ? -1 : 0
			IniWrite, % settings.recombination.fSize, ini\recombination.ini, settings, font-size
			LLK_FontDimensions(settings.recombination.fSize, font_height, font_width), settings.recombination.fWidth := font_width, settings.recombination.fHeight := font_height
		}
		Else If InStr(check, "color_")
		{
			color := (vars.system.click = 1) ? RGB_Picker(settings.recombination.colors[control]) : settings.recombination.dColors[control]
			If Blank(color)
				Return
			IniWrite, % (settings.recombination.colors[control] := color), ini\recombination.ini, settings, % "color" control
		}
		If (check != "chance") && !InStr(check, "color_") && !InStr(check, "font_")
			Return
	}

	toggle := !toggle, GUI_name := "recombination" toggle, vars.recombination.wait := 1
	LLK_PanelDimensions(["7777777777777777777777777777777777777"], settings.recombination.fSize, width, height), vars.recombination.wMods := width, vars.recombination.hMods := height
	desired_mods := vars.recombination.desired_mods := vars.recombination.desired.prefixes.Count() + vars.recombination.desired.suffixes.Count()
	Gui, %GUI_name%: New, % "-DPIScale +LastFound -Caption +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDrecombination"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, % settings.recombination.fWidth, % settings.recombination.fWidth/2
	Gui, %GUI_name%: Font, % "s" settings.recombination.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.recombination.main, vars.hwnd.recombination := {"main": recombination, "GUI_name": GUI_name}
	item1 := vars.recombination.item1, item2 := vars.recombination.item2, desired := vars.recombination.desired, width := vars.recombination.wMods, height := vars.recombination.hMods
	mismatch := (!Blank(item2.class) && (item1.class != item2.class))
	mismatch_affixes := (!Blank(item2.class) && (item1.mod_counts.prefixes != item2.mod_counts.prefixes || item1.mod_counts.suffixes != item2.mod_counts.suffixes))
	LLK_PanelDimensions(["10000/10000 (100.00%)"], settings.recombination.fSize, wChance, hChance,,, 0)

	Loop 2
	{
		If !item%A_Index%.Count()
			Continue
		If (A_Index = 2)
		{
			Gui, %GUI_name%: Add, Pic, % "ys x+0 HWNDhwnd h" settings.recombination.fHeight " w-1", % "HBitmap:*" vars.pics.global.help
			vars.hwnd.help_tooltips["recombination_basics"] := hwnd
		}
		style := " ys x+0 y" settings.recombination.fWidth, outer := A_Index
		Gui, %GUI_name%: Add, Text, % "Section" style " Center w" width " h" settings.recombination.fHeight, % item%A_Index%.name
		color := mismatch ? " c" settings.recombination.colors.2 : (!Blank(item2.itembase) && (item1.itembase != item2.itembase)) ? " c" settings.recombination.colors.3 : " c" settings.recombination.colors.1
		Gui, %GUI_name%: Add, Text, % "xs Center w" width " h" settings.recombination.fHeight . color, % item%A_Index%.itembase (!Blank(item2.itembase) && !mismatch ? (item1.itembase != item2.itembase ? " (50%)" : "") : "")
		Gui, %GUI_name%: Font, % "s" settings.recombination.fSize - 2
		For index, val in (affixes := ["prefixes", "suffixes"])
		{
			Loop, % item%outer%.mod_counts[val]
			{
				Gui, %GUI_name%: Add, Edit, % "xs cBlack Lowercase HWNDhwnd gRecombination_GUI -Wrap R2 w" width . (mismatch || mismatch_affixes || !item2.Count() ? " Disabled" : ""), % item%outer%[val][A_Index].1
				vars.hwnd.recombination["edit_" outer . index . A_Index] := hwnd
			}
			If (index = 1)
				Gui, %GUI_name%: Add, Progress, % "xs Disabled BackgroundTrans c" settings.recombination.colors[mismatch_affixes ? 2 : 1] " wp h" settings.recombination.fWidth//2, 100
			Else Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans wp h" settings.recombination.fWidth, % ""
		}
		Gui, %GUI_name%: Font, % "s" settings.recombination.fSize
		index := A_Index + 1
		If !mismatch && !mismatch_affixes && (item%index%.Count() || (A_Index = 2))
		{
			Gui, %GUI_name%: Font, % "underline s" settings.recombination.fSize
			Gui, %GUI_name%: Add, Text, % "xs w" width, % LangTrans("recomb_" affixes[A_Index])
			Gui, %GUI_name%: Font, % "norm s" settings.recombination.fSize - 2
			added := {}
			Loop 2
			{
				For index, val in item%A_Index%[affixes[outer]]
				{
					If added[val.1]
						Continue
					Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd0 Hidden cGray w" width, % val.1
					Gui, %GUI_name%: Add, Checkbox, % "xp yp HWNDhwnd gRecombination_GUI w" width " Checked" vars.recombination.desired[affixes[outer]].HasKey(val), % val.1
					vars.hwnd.recombination["0check_" val.1] := hwnd0, vars.hwnd.recombination["check_" affixes[outer] "_" val.1] := hwnd, added[val.1] := 1
					ControlGetPos,, yLast,, hLast,, ahk_id %hwnd%
					yMax := (yLast + hLast > yMax) ? yLast + hLast : yMax
				}
			}
			Gui, %GUI_name%: Font, % "s" settings.recombination.fSize
			If (A_Index = 2)
			{
				Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans wp h" settings.recombination.fWidth, % ""
				Gui, %GUI_name%: Font, underline
				Gui, %GUI_name%: Add, Text, % "Section xs y" yMax + settings.recombination.fWidth, % LangTrans("recomb_simulation")
				Gui, %GUI_name%: Font, norm
				Gui, %GUI_name%: Add, Text, % "ys Border gRecombination_GUI HWNDhwnd0" (desired_mods ? "" : " Hidden"), % " " LangTrans("recomb_rerun") " "
				Gui, %GUI_name%: Add, Text, % "xs Section HWNDhwnd w" wChance, % (desired.prefixes.Count() + desired.suffixes.Count() > 0) ? (vars.recombination.chance := Recombination_Simulate()) : ""
				vars.hwnd.recombination.rerun := hwnd0, vars.hwnd.recombination.chance := hwnd

				Gui, %GUI_name%: Font, underline
				Gui, %GUI_name%: Add, Text, % "Section x" settings.recombination.fWidth " y" yMax + settings.recombination.fWidth, % LangTrans("global_settings") ":"
				Gui, %GUI_name%: Font, norm
				Gui, %GUI_name%: Add, Text, % "Section xs", % LangTrans("global_font")
				Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/2 " Center Border gRecombination_GUI HWNDhwnd0 w"settings.recombination.fWidth*2, % "–"
				Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/4 " Center Border gRecombination_GUI HWNDhwnd1 w"settings.recombination.fWidth*3, % settings.recombination.fSize
				Gui, %GUI_name%: Add, Text, % "ys x+"settings.recombination.fWidth/4 " Center Border gRecombination_GUI HWNDhwnd2 w"settings.recombination.fWidth*2, % "+"
				vars.hwnd.recombination.font_minus := hwnd0, vars.hwnd.recombination.font_reset := hwnd1, vars.hwnd.recombination.font_plus := hwnd2

				Gui, %GUI_name%: Add, Text, % "ys", % LangTrans("global_color", 2) ":"
				For index, val in settings.recombination.colors
				{
					Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/(A_Index = 1 ? 2 : 4) " BackgroundTrans Border HWNDhwnd gRecombination_GUI w" settings.recombination.fHeight " h" settings.recombination.fHeight, % ""
					Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd1 Disabled Border BackgroundBlack c" val, 100
					vars.hwnd.recombination["color_" index] := hwnd, vars.hwnd.recombination["colorback_" index] := vars.hwnd.help_tooltips["recombination_color " index] := hwnd1
				}
			}
		}
	}
	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos, x, y, w, h, ahk_id %recombination%
	Gui, %GUI_name%: Show, % "NA x" vars.client.x + vars.client.w - vars.recombination.wInventory - w " y" vars.client.y + Floor(vars.client.h * (47/48)) - h
	LLK_Overlay(recombination, "show", 1, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	vars.recombination.wait := 0
}

Recombination_Simulate()
{
	local
	global vars, settings
	static rolls := [999, 999, 1000, 1000, 1000, 1000]
	, odds := [{"0": 333, "1": 999}, {"1": 666, "2": 999}, {"1": 300, "2": 800, "3": 1000}, {"1": 100, "2": 650, "3": 1000}, {"2": 500, "3": 1000}, {"2": 300, "3": 1000}]

	item1 := vars.recombination.item1, item2 := vars.recombination.item2, desired := vars.recombination.desired, hits := 0
	For index, affix in ["prefixes", "suffixes"] ; throw mods into affix pools
	{
		%affix% := []
		Loop 2
			For iMod, vMod in item%A_Index%[affix]
				%affix%.Push(vMod)
		unique_mods_%affix% := {}
		For i, v in %affix% ; count number of unique mods
			unique_mods_%affix%[v.1] := 1
		Loop 2
		{
			incompatible_mods_%affix%_%A_Index% := {}, item := A_Index
			For iAffix, aAffix in %affix% ; check each mod in the mod-pool for influences
			{
				influence := aAffix.2.1 ? LLK_HasVal(vars.recombination.influences, aAffix.2.1,,,, 1) : ""
				If influence && !LLK_HasVal(item%item%.influences, influence) || aAffix.2.2 && item%item%.influences.Count()
					incompatible_mods_%affix%_%item%[aAffix.1] := 1 ; if mod is influenced but the target-base isn't, or if mod is fractured and target-base is synth/influenced, mark mod as incompatible
			}
		}
	}
	Loop 10000 ; simulate X times
	{
		Random, item, 1, 2 ; pick one of the two items as the final base
		For index, affix in ["prefixes", "suffixes"]
			If %affix%.Count()
			{
				unique_mods_copy := unique_mods_%affix%.Count() - incompatible_mods_%affix%_%item%.Count()
				Random, rng, 1, rolls[Min(6, %affix%.Count())] ; this roll determines the final affix-#
				For key, val in odds[Min(6, %affix%.Count())] ; get final affix-# from table
					If (rng <= val)
					{
						mod_count := Min(key, unique_mods_copy, item1.mod_counts[affix]) ; reduce final affix-# if there aren't enough unique mods to roll, or if affix-# is restricted (heist)
						Break
					}
				mods := {}
				If (mod_count < desired[affix].Count()) ; if final number of affixes is already below desired count, the outcome counts as failed
					Continue 2
				While (mods.Count() < mod_count) ; populate available affix-slots with mods from pool (cannot pick duplicates or incompatible mods)
				{
					Random, rng, 1, %affix%.Count() ; pick random mod out of the pool
					If !incompatible_mods_%affix%_%item%[%affix%[rng].1] ; check if mod is incompatible
						mods[%affix%[rng].1] := 1
				}
				For key, mod in desired[affix] ; if at least one desired mod is missing, the outcome has failed
					If !mods.HasKey(key)
						Continue 3
			}
			Else Continue
		hits += 1 ; item turned out as desired
	}
	Return hits "/10000 (" Round((hits/10000) * 100, 2) "%)" ; return X/Y (Z%) successful outcomees
}
