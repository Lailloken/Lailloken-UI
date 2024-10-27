Init_recombination()
{
	local
	global vars, settings

	If !FileExist("ini" vars.poe_version "\recombination.ini")
		IniWrite, % "", % "ini" vars.poe_version "\recombination.ini", settings
	If !IsObject(settings.recombination)
		settings.recombination := {}

	ini := IniBatchRead("ini" vars.poe_version "\recombination.ini")
	dcolors := settings.recombination.dcolors := ["00FF00", "FF0000", "FF8000"]
	settings.recombination.colors := [!Blank(check1 := ini.settings.color1) ? check1 : dColors.1, !Blank(check2 := ini.settings.color2) ? check2 : dColors.2, !Blank(check3 := ini.settings.color3) ? check3 : dColors.3]
	settings.recombination.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.recombination.fSize, font_height, font_width), settings.recombination.fWidth := font_width, settings.recombination.fHeight := font_height
}

Recombination()
{
	local
	global vars, settings

	If !IsObject(vars.recombination.item1)
		vars.recombination.item1 := {}, vars.recombination.item2 := {}

	If Blank(vars.recombination.wStash)
		vars.recombination.wStash := Floor(vars.client.h * (37/60)), vars.recombination.wInventory := Floor(vars.client.h * 0.6155)
	If !IsObject(vars.recombination.influences)
	{
		vars.recombination.influences := {"shaper": "", "elder": "", "crusader": "", "redeemer": "", "hunter": "", "warlord": "", "synthesis": ""}
		For key in vars.recombination.influences
			vars.recombination.influences[key] := {"item": Lang_Trans("items_" key), "affixes": [Lang_Trans("items_" key "_prefix"), Lang_Trans("items_" key "_suffix")]}
	}

	influences := vars.recombination.influences
	clip := SubStr(vars.omnikey.clipboard, InStr(vars.omnikey.clipboard, Lang_Trans("items_ilevel"))), clip := StrReplace(clip, "`r`n", ";")
	clip := StrReplace(clip, " (crafted)"), clip := StrReplace(clip, " — " Lang_Trans("items_unscalable"))
	item := {	"name": LLK_StringCase(vars.omnikey.item.name), "itembase": LLK_StringCase(vars.omnikey.item.itembase),"class": LLK_StringCase(vars.omnikey.item.class)
	,		"prefixes": [], "suffixes": [], "mod_counts": {"prefixes": 3, "suffixes": 3}, "influences": {}, "attributes": vars.omnikey.item.attributes}
	item1 := vars.recombination.item1, item2 := vars.recombination.item2

	Loop, Parse, % vars.omnikey.clipboard, `n, `r
		If Lang_Match(A_LoopField, vars.lang.items_prefix_allowed)
			item.mod_counts.prefixes += SubStr(A_LoopField, 1, 2)
		Else If Lang_Match(A_LoopField, vars.lang.items_suffix_allowed)
			item.mod_counts.suffixes += SubStr(A_LoopField, 1, 2)

	For key, object in influences
		If InStr(clip, ";" object.item ";")
			item.influences[key] := 1

	Loop, Parse, clip, `;, %A_Space%
	{
		If InStr(A_LoopField, Lang_Trans("items_implicit")) || !LLK_PatternMatch(A_LoopField, "", [Lang_Trans("items_prefix"), Lang_Trans("items_suffix")])
			Continue
		mod := "", type := InStr(A_LoopField, Lang_Trans("items_prefix")) ? "prefixes" : "suffixes", fractured := InStr(A_LoopField, "(fractured)")
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
		item[type].Push({"text": LLK_StringCase(mod), "affix": affix_name, "fractured": fractured ? 1 : 0, "influence": affix_name ? LLK_HasVal(vars.recombination.influences, affix_name,,,, 1) : "", "crafted": InStr(A_LoopField, "crafted") ? 1 : 0})
	}

	If !(item1.locked * item2.locked)
	{
		If !(item.prefixes.Count() + item.suffixes.Count())
		{
			LLK_ToolTip(Lang_Trans("global_errorname", 2),,,,, settings.recombination.colors.2)
			Return
		}
		Else If !A_Gui
			LLK_ToolTip(Lang_Trans("lvltracker_gearadd"), 1,,,, settings.recombination.colors.1)

		If !IsObject(vars.recombination.desired)
			vars.recombination.desired := {"itembase": 0, "prefixes": {}, "suffixes": {}}, vars.recombination.desired_mods := 0

		If item1.locked
			vars.recombination.item2 := item.Clone()
		Else If (item1.prefixes.Count() + item1.suffixes.Count())
		{
			If !item2.locked
				vars.recombination.item2 := vars.recombination.item1.Clone()
		}
		Else If !item2.locked
			vars.recombination.item2 := item.Clone(), vars.recombination.item2.name := "dummy item", vars.recombination.item2.prefixes := [], vars.recombination.item2.suffixes := []

		If !item1.locked
			vars.recombination.item1 := item.Clone()

		For item_no in [1, 2] ; reset state of NNN and fractured for every mod
			For index, affix in ["prefixes", "suffixes"]
				For index, mod in vars.recombination["item" item_no][affix]
				{
					vars.recombination["item" item_no][affix][index].Delete("nnn")
					If vars.recombination["item" item_no][affix][index].fractured
						vars.recombination["item" item_no][affix][index].fractured := item_no
				}
	}
	Recombination_GUI()
}

Recombination_CheckMod(mod, type := 0) ; checks if a mod is "exclusive" or "non-native, natural"
{
	local
	global vars, settings
	static exclusive := ["chayula", "uul-netol", "esh", "tul", "xoph"
	, "citaqualotl", "guatelitzi", "matatl", "puhuarte", "tacati", "topotante", "xopec"
	, "catarina", "haku", "elreon", "tora", "vagan", "vorici", "hillock", "leo", "guff", "janus", "it", "gravicius", "jorgin", "korell", "rin", "cameria", "aisling", "riker"
	, "saqawal", "farrul", "craiceann", "fenumus"]

	If !type
	{
		If mod.affix
		&& (InStr(mod.affix, "elevated ") || (mod.affix = "of crafting") || InStr(mod.affix, "veiled")
		|| InStr("chosen, of the order, essences, of the essence, subterranean, of the underground, suffixed, of prefixes, of spellcraft, of weaponcraft", mod.affix))
			Return 1
		Else If mod.crafted && (RegExMatch(mod.text, "i)^to maximum life$") || RegExMatch(obect.text, "i)^to.*resistance$"))
			Return 0

		For index, val in exclusive
			If RegExMatch(mod.affix, "i)^(" val "'s|of\s" val ")$")
				Return 1
	}
	Else
	{
		item1 := vars.recombination.item1, item2 := vars.recombination.item2, other := (type = 1) ? 2 : 1
		If mod.influence && !item%other%.influences[mod.influence] ; mod is influenced and the other item doesn't have the required influence
		|| item%other%.attributes && !mod.crafted ; attribute/defense-related restrictions
			&& (RegExMatch(mod.text, "i)armour|strength|life.regeneration") && !InStr(item%other%.attributes, "str")
				|| RegExMatch(mod.text, "i)evasion|suppress|dexterity") && !InStr(item%other%.attributes, "dex")
				|| RegexMatch(mod.text, "i)energy.shield|intelligence|mana") && !InStr(item%other%.attributes, "int"))
		|| mod.fractured
		Return 1
	}
	Return 0
}

Recombination_GUI(cHWND := "")
{
	local
	global vars, settings
	static toggle := 0

	If !Blank(cHWND)
	{
		check := LLK_HasVal(vars.hwnd.recombination, cHWND), control := SubStr(check, InStr(check, "_") + 1)
		item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
		item1 := vars.recombination.item1, item2 := vars.recombination.item2
		If InStr(check, "edit_")
		{
			input := LLK_ControlGet(cHWND), modified := (input != vars.recombination["item" item_no][affix][mod_slot].text)
			GuiControl, % "+c" (modified ? settings.recombination.colors.2 : "Black"), % cHWND
			GuiControl, % "movedraw", % cHWND

			modified := 0
			For key, val in vars.hwnd.recombination
				If InStr(key, "edit_")
				{
					input := LLK_ControlGet(val), control := SubStr(key, InStr(key, "_") + 1)
					item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
					modified += (input != vars.recombination["item" item_no][affix][mod_slot].text)
				}
			GuiControl, % (modified ? "+c" settings.recombination.colors.2 " +gRecombination_GUI" : "+cWhite -g"), % vars.hwnd.recombination.chance
			GuiControl, % "Text", % vars.hwnd.recombination.chance, % modified ? Lang_Trans("recomb_refresh") : vars.recombination.chance
			GuiControl, % "movedraw", % vars.hwnd.recombination.chance
			GuiControl, % (modified || !vars.recombination.desired_mods ? "+" : "-") "Hidden", % vars.hwnd.recombination.rerun
			GuiControl, % "movedraw", % vars.hwnd.recombination.rerun

			For key, val in vars.hwnd.recombination
				If InStr(key, "check_")
				{
					If InStr("0", SubStr(key, 1, 1))
						GuiControl, % (modified ? "-" : "+") "Hidden", % val
					Else GuiControl, % (modified ? "+" : "-") "Hidden", % val
				}
				Else If InStr(key, "exclusive_") || InStr(key, "nnn_")
				{
					If InStr("0", SubStr(key, 1, 1))
						GuiControl, % (modified ? "-" : "+") "Hidden", % val
					Else GuiControl, % (modified ? "+" : "-") "Hidden", % val
				}
				Else If InStr(key, "desiredbase_")
					GuiControl, % (modified ? "+" : "-") "Hidden", % val
		}
		Else If InStr(check, "desiredbase_")
		{
			other := (control = 1) ? 2 : 1, input := LLK_ControlGet(cHWND)
			GuiControl,, % vars.hwnd.recombination["desiredbase_" other], 0
			GuiControl, +cWhite, % vars.hwnd.recombination["desiredbase_" other]
			GuiControl, movedraw, % vars.hwnd.recombination["desiredbase_" other]
			GuiControl, % "+c" (input ? settings.recombination.colors.3 : "White"), % cHWND
			GuiControl, movedraw, % cHWND
			vars.recombination.desired.itembase := input ? control : 0
		}
		Else If InStr(check, "lock_")
		{
			input := LLK_ControlGet(cHWND), item%control%.locked := input
			GuiControl, % "+c" (input ? settings.recombination.colors.3 : "White"), % cHWND
			GuiControl, % "movedraw", % cHWND
		}
		Else If InStr(check, "exclusive_") || InStr(check, "nnn_")
		{
			input := LLK_ControlGet(cHWND), type := InStr(check, "nnn_") ? "nnn" : "exclusive", other := (item_no = 1) ? 2 : 1
			fractured := item%item_no%[affix][mod_slot].fractured, influence := item%item_no%[affix][mod_slot].influence
			If (type = "nnn") && (fractured || influence && !item%other%.influences[influence])
			{
				LLK_ToolTip("mod is " (fractured ? "fractured" : "influenced"), 1.5,,,, "Red")
				GuiControl,, % cHWND, 1
				Return
			}
			GuiControl, % "+c" (input ? settings.recombination.colors.3 : "White"), % cHWND
			GuiControl, % "movedraw", % cHWND
			item%item_no%[affix][mod_slot][type] := input ? item_no : 0
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
						LLK_ToolTip(Lang_Trans("recomb_desired"), 1.5,,,, "Red")
						Return
					}
					vars.recombination.desired[affix][mod] := 1
				}
				Else vars.recombination.desired[affix].Delete(mod)
			}
		}
		Else If (check = "chance") ; clicking "refresh"
		{
			For key, val in vars.hwnd.recombination
				If InStr(key, "edit_")
				{
					input := LLK_ControlGet(val), control := SubStr(key, InStr(key, "_") + 1)
					If IsNumber(input)
					{
						WinGetPos, xEdit, yEdit,,, ahk_id %val%
						LLK_ToolTip("cannot be a number", 1.5, xEdit, yEdit,, "Red")
						Return
					}
					item_no := SubStr(control, 1, 1), affix := (SubStr(control, 2, 1) = 1) ? "prefixes" : "suffixes", mod_slot := SubStr(control, 3, 1)
					Loop, Parse, input, µ, % " `n"
						input := A_LoopField
					If (input != vars.recombination["item" item_no][affix][mod_slot].text)
						vars.recombination["item" item_no][affix][mod_slot] := {"text": input}
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
		Else LLK_ToolTip("no action")

		If InStr(check, "check_") || (check = "rerun") || InStr(check, "exclusive_") || InStr(check, "nnn_") || InStr(check, "desiredbase_")
		{
			desired_mods := vars.recombination.desired_mods := vars.recombination.desired.prefixes.Count() + vars.recombination.desired.suffixes.Count()
			GuiControl, Text, % vars.hwnd.recombination.chance, % desired_mods ? (vars.recombination.chance := Recombination_Simulate()) : ""
			GuiControl, % (desired_mods ? "-" : "+") "Hidden", % vars.hwnd.recombination.rerun
		}

		If (check != "chance") && !InStr(check, "color_") && !InStr(check, "font_")
			Return
	}

	; clean up left-over (desired) mods
	remove_prefixes := [], remove_suffixes := []
	For index, affix in ["prefixes", "suffixes"]
	{
		For item in [1, 2]
			Loop, % (count := vars.recombination["item" item][affix].Count())
				If Blank(vars.recombination["item" item][affix][count - A_Index + 1].text)
					vars.recombination["item" item][affix].RemoveAt(count - A_Index + 1)

		For key in vars.recombination.desired[affix]
			If !LLK_HasVal(vars.recombination.item1, key,,,, 1) && !LLK_HasVal(vars.recombination.item2, key,,,, 1)
				remove_%affix%.Push(key)

		For index, val in remove_%affix%
			vars.recombination.desired[affix].Delete(val)
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
			Gui, %GUI_name%: Add, Pic, % "HWNDhwnd h" settings.recombination.fHeight " w-1 y" settings.recombination.fWidth " x" settings.recombination.fWidth + width + wNNN, % "HBitmap:*" vars.pics.global.help
			vars.hwnd.help_tooltips["recombination_basics"] := hwnd
			ControlGetPos, xHelp, yHelp, wHelp, hHelp,, ahk_id %hwnd%
		}
		Else If (A_Index = 1) && !mismatch && !mismatch_affixes && item2.Count()
		{
			Gui, %GUI_name%: Font, % "s" settings.recombination.fSize - 2
			Gui, %GUI_name%: Add, Checkbox, % "y0 HWNDhwnd Hidden x" settings.recombination.fWidth, nnn
			Gui, %GUI_name%: Font, % "s" settings.recombination.fSize
			ControlGetPos,,, wNNN,,, ahk_id %hwnd%
			wNNN += settings.recombination.fWidth//2
		}
		Else wNNN := 0

		style := (A_Index = 1 ? "xp" : "ys x+0") " y" settings.recombination.fWidth, outer := A_Index
		Gui, %GUI_name%: Add, Text, % "Section " style " Center w" width + wNNN " h" settings.recombination.fHeight, % item%A_Index%.name
		color := mismatch ? " c" settings.recombination.colors.2 : (!Blank(item2.itembase) && (item1.itembase != item2.itembase)) ? " c" settings.recombination.colors.3 : " c" settings.recombination.colors.1
		Gui, %GUI_name%: Add, Text, % "xs y+0 Center wp hp" color, % item%A_Index%.itembase (!Blank(item2.itembase) && !mismatch ? (item1.itembase != item2.itembase ? " (50%)" : "") : "")

		influences := "", other := (A_Index = 1) ? 2 : 1
		For key in item%A_Index%.influences
			influences .= (!influences ? "" : ", ") key
		If influences || item%other%.influences.Count()
			Gui, %GUI_name%: Add, Text, % "xs y+0 Center wp hp", % influences
		Gui, %GUI_name%: Font, % "s" settings.recombination.fSize - 2
		If !mismatch && !mismatch_affixes
		{
			Gui, %GUI_name%: Add, Checkbox, % "xs Section HWNDhwnd gRecombination_GUI Checked" (desired.itembase = outer ? "1 c" settings.recombination.colors.3 : "0") . (mismatch || mismatch_affixes ? " Hidden" : ""), % "desired final base"
			Gui, %GUI_name%: Add, Checkbox, % "ys HWNDhwnd_lock gRecombination_GUI Checked" (item%outer%.locked ? "1 c" settings.recombination.colors.3 : "0"), % "lock item-slot"
			vars.hwnd.recombination["desiredbase_" A_Index] := hwnd
		}
		Else Gui, %GUI_name%: Add, Checkbox, % "xs HWNDhwnd_lock gRecombination_GUI Checked" (item%outer%.locked ? "1 c" settings.recombination.colors.3 : "0"), % "lock item-slot"
		vars.hwnd.recombination["lock_" A_Index] := vars.hwnd.help_tooltips["recombination_lock" (A_Index = 2 ? "|" : "")] := hwnd_lock

		For index, val in (affixes := ["prefixes", "suffixes"])
		{
			Loop, % item%outer%.mod_counts[val]
			{
				mod := item%outer%[val][A_Index]
				Gui, %GUI_name%: Add, Edit, % "xs cBlack Section Lowercase HWNDhwnd gRecombination_GUI -Wrap R2 w" width . (mismatch || mismatch_affixes || !item2.Count() ? " Disabled" : ""), % mod.text
				vars.hwnd.recombination["edit_" outer . index . A_Index] := hwnd, exclusive := nnn := 0
				If !mismatch && !mismatch_affixes && item%outer%[val][A_Index].text && (item2.Count() || (outer = 2))
				{
					If Blank(mod.exclusive)
						mod.exclusive := exclusive := Recombination_CheckMod(mod)
					Else exclusive := mod.exclusive

					Gui, %GUI_name%: Add, Text, % "ys HWNDhwnd00 cGray Hidden gRecombination_GUI x+" settings.recombination.fWidth//2, excl
					Gui, %GUI_name%: Add, Checkbox, % "xp yp HWNDhwnd gRecombination_GUI Checked" exclusive . (exclusive ? " c" settings.recombination.colors.3 : ""), excl

					If Blank(mod.nnn)
					{
						If Recombination_CheckMod(mod, outer)
							mod.nnn := nnn := outer
						Else nnn := 0
					}
					Else nnn := mod.nnn

					Gui, %GUI_name%: Add, Text, % "xp y+0 HWNDhwnd01 cGray Hidden gRecombination_GUI", nnn
					Gui, %GUI_name%: Add, Checkbox, % "xp yp HWNDhwnd1 gRecombination_GUI Checked" nnn . (nnn ? " c" settings.recombination.colors.3 : ""), nnn
					vars.hwnd.recombination["0exclusive_" outer . index . A_Index] := hwnd00, vars.hwnd.recombination["0nnn_" outer . index . A_Index] := hwnd01
					vars.hwnd.recombination["exclusive_" outer . index . A_Index] := hwnd, vars.hwnd.recombination["nnn_" outer . index . A_Index] := hwnd1
					vars.hwnd.help_tooltips["recombination_exclusive" handle] := hwnd, vars.hwnd.help_tooltips["recombination_nnn" handle] := hwnd1, handle .= "|"
				}
			}
			If (index = 1)
				Gui, %GUI_name%: Add, Progress, % "xs Disabled BackgroundTrans c" settings.recombination.colors[mismatch_affixes ? 2 : 1] " w" width " h" settings.recombination.fWidth//2, 100
			Else Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans wp h" settings.recombination.fWidth, % ""
		}
		Gui, %GUI_name%: Font, % "s" settings.recombination.fSize
		index := A_Index + 1
		If !mismatch && !mismatch_affixes && (item%index%.Count() || (A_Index = 2))
		{
			Gui, %GUI_name%: Font, % "underline"
			Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd w" width, % Lang_Trans("recomb_" affixes[A_Index])
			ControlGetPos,, yLast,, hLast,, ahk_id %hwnd%
			yMax := (yLast + hLast > yMax) ? yLast + hLast : yMax
			Gui, %GUI_name%: Font, % "norm s" settings.recombination.fSize - 2
			added := {}

			Loop 2
			{
				For index, val in item%A_Index%[affixes[outer]]
				{
					If added[val.text]
						Continue
					Gui, %GUI_name%: Add, Checkbox, % "xs HWNDhwnd gRecombination_GUI w" width + wNNN " Checked" vars.recombination.desired[affixes[outer]].HasKey(val.text), % val.text
					Gui, %GUI_name%: Add, Text, % "xp yp wp hp HWNDhwnd0 Hidden cGray", % val.text
					vars.hwnd.recombination["0check_" val.text] := hwnd0, vars.hwnd.recombination["check_" affixes[outer] "_" val.text] := hwnd, added[val.text] := 1
					ControlGetPos,, yLast,, hLast,, ahk_id %hwnd%
					yMax := (yLast + hLast > yMax) ? yLast + hLast : yMax
				}
			}

			Gui, %GUI_name%: Font, % "s" settings.recombination.fSize
			If (A_Index = 2)
			{
				Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans wp h" settings.recombination.fWidth, % ""
				Gui, %GUI_name%: Font, underline
				Gui, %GUI_name%: Add, Text, % "Section xs y" yMax + settings.recombination.fWidth, % Lang_Trans("recomb_simulation")
				Gui, %GUI_name%: Font, norm
				Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth//2 " Border gRecombination_GUI HWNDhwnd0" (desired_mods ? "" : " Hidden"), % " " Lang_Trans("recomb_rerun") " "
				Gui, %GUI_name%: Add, Text, % "xs Section HWNDhwnd w" wChance, % (desired.prefixes.Count() + desired.suffixes.Count() > 0) ? (vars.recombination.chance := Recombination_Simulate()) : ""
				vars.hwnd.recombination.rerun := hwnd0, vars.hwnd.recombination.chance := hwnd

				Gui, %GUI_name%: Font, underline
				Gui, %GUI_name%: Add, Text, % "Section x" settings.recombination.fWidth " y" yMax + settings.recombination.fWidth, % Lang_Trans("global_settings") ":"
				Gui, %GUI_name%: Font, norm
				Gui, %GUI_name%: Add, Text, % "Section xs", % Lang_Trans("global_font")
				Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/2 " Center Border gRecombination_GUI HWNDhwnd0 w"settings.recombination.fWidth*2, % "–"
				Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/4 " Center Border gRecombination_GUI HWNDhwnd1 w"settings.recombination.fWidth*3, % settings.recombination.fSize
				Gui, %GUI_name%: Add, Text, % "ys x+"settings.recombination.fWidth/4 " Center Border gRecombination_GUI HWNDhwnd2 w"settings.recombination.fWidth*2, % "+"
				vars.hwnd.recombination.font_minus := hwnd0, vars.hwnd.recombination.font_reset := hwnd1, vars.hwnd.recombination.font_plus := hwnd2

				Gui, %GUI_name%: Add, Text, % "ys", % Lang_Trans("global_color", 2) ":"
				For index, val in settings.recombination.colors
				{
					Gui, %GUI_name%: Add, Text, % "ys x+" settings.recombination.fWidth/(A_Index = 1 ? 2 : 4) " BackgroundTrans Border HWNDhwnd gRecombination_GUI w" settings.recombination.fHeight " h" settings.recombination.fHeight, % ""
					ControlGetPos, xFinal, yFinal, wFinal, hFinal,, ahk_id %hwnd%
					Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd1 Disabled Border BackgroundBlack c" val, 100
					vars.hwnd.recombination["color_" index] := hwnd, vars.hwnd.recombination["colorback_" index] := vars.hwnd.help_tooltips["recombination_color " index] := hwnd1
				}
			}
			If (A_Index = 2)
				Gui, %GUI_name%: Add, Progress, % "Disabled BackgroundWhite w2 x" xHelp + wHelp//2 - 2 " y" yHelp + hHelp " h" (yFinal + hFinal) - (yHelp + hHelp), 0
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
	static rolls := [1000, 999, 1000, 1000, 1000, 1000]
	, odds := [{"0": 410, "1": 1000}, {"1": 666, "2": 999}, {"1": 390, "2": 900, "3": 1000}, {"1": 110, "2": 690, "3": 1000}, {"2": 430, "3": 1000}, {"2": 280, "3": 1000}]

	item1 := vars.recombination.item1, item2 := vars.recombination.item2, desired := vars.recombination.desired, hits := 0, item1_nnn := item2_nnn := 0
	For index, affix in ["prefixes", "suffixes"] ; throw mods into affix pools
	{
		%affix%_1 := [], %affix%_2 := []
		For item_no in [1, 2]
			For iMod, vMod in item%item_no%[affix]
			{
				If !vMod.fractured || (vMod.fractured = 1)
					%affix%_1.Push(vMod), item1_nnn += (vMod.nnn && vMod.nnn != 1) ? 1 : 0
				If !vMod.fractured || (vMod.fractured = 2)
					%affix%_2.Push(vMod), item2_nnn += (vMod.nnn && vMod.nnn != 2) ? 1 : 0
			}
		unique_mods_%affix%_1 := {}, unique_mods_%affix%_2 := {}
		For item_no in [1, 2]
			For i, v in %affix%_%item_no% ; count number of unique mods
				unique_mods_%affix%_%item_no%[v.text] := 1
	}

	Loop 10000 ; simulate X times
	{
		Random, item, 1, 2 ; pick one of the two items as the final base
		Random, order, 0, 1 ; determine if prefixes or suffixes are combined first

		If desired.itembase && (desired.itembase != item)
			Continue
		exclusive_picked := 0
		For index, affix in (!order ? ["prefixes", "suffixes"] : ["suffixes", "prefixes"])
			If %affix%_%item%.Count()
			{
				unique_mods := unique_mods_%affix%_%item%.Count()
				other_type := (affix = "prefixes") ? "suffixes" : "prefixes", other_item := (item = 1) ? 2 : 1
				Random, rng, 1, rolls[Min(6, %affix%_%item%.Count())] ; this roll determines the final affix-#
				For key, val in odds[Min(6, %affix%_%item%.Count())] ; get final affix-# from table
					If (rng <= val)
					{
						mod_count := Min(key, unique_mods, item1.mod_counts[affix]) ; reduce final affix-# if there aren't enough unique mods to roll, or if affix-# is restricted (heist)
						Break
					}

				If (item1.prefixes.Count() = 1 && !item1.suffixes.Count() && item2.suffixes.Count() = 1 && !item2.prefixes.Count()
					|| item1.suffixes.Count() = 1 && !item1.prefixes.Count() && item2.prefixes.Count() = 1 && !item2.suffixes.Count())
				&& (index = 1 && item%other_item%_nnn || index = 2 && !mods.Count()) && !item%item%_nnn ; prevent 0/0 items if input is 1/0 + 0/1
					mod_count := 1

				mods := {}, mod_pool := %affix%_%item%.Clone()
				If (mod_count < desired[affix].Count()) ; if final number of affixes is already below desired count, the outcome counts as failed
					Continue 2
				While (mods.Count() < mod_count) && (mods.Count() < unique_mods) ; populate available affix-slots with mods from pool until final count is reached
				{
					Random, rng, 1, mod_pool.Count() ; pick random mod out of the pool
					mod_pool_unique := {}
					For index, val in mod_pool
						mod_pool_unique[val.text] := 1
					unique_mods := mod_pool_unique.Count()
					If (mod_pool[rng].nnn && (mod_pool[rng].nnn != item))
					{
						mod_pool.RemoveAt(rng)
						Continue
					}
					If mod_pool[rng].exclusive
					{
						If !exclusive_picked
							exclusive_picked := 1
						Else
						{
							If !mods[mod_pool[rng].text]
								mod_pool.RemoveAt(rng)
							Continue
						}
					}
					mods[mod_pool[rng].text] := 1
					If (A_Index > 1000)
						Return "error"
				}
				For key, mod in desired[affix] ; if at least one desired mod is missing, the outcome has failed
					If !mods[key]
						Continue 3
			}
			Else If !%affix%_%item%.Count() && desired[affix].Count()
				Continue 2
			Else Continue
		hits += 1 ; item turned out as desired
	}
	Return hits "/10000 (" Round((hits/10000) * 100, 2) "%)" ; return X/Y (Z%) successful outcomees
}
