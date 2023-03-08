Recombinators:
mod_pool_count := []
mod_pool_count[0] := 1 "," 1 "," 1
mod_pool_count[1] := 2/3 "," 0 "," 0
mod_pool_count[2] := 2/3 "," 1/3 "," 0
mod_pool_count[3] := 0.3 "," 0.5 "," 0.2
mod_pool_count[4] := 0.1 "," 0.55 "," 0.35
mod_pool_count[5] := 0 "," 0.5 "," 0.5
mod_pool_count[6] := 0 "," 0.3 "," 0.7
Return

Recombinators_add:
recomb_regular := 1
item_name := ""
item_class := ""
allowed := 0
If !InStr(clipboard, "prefix modifier") || !InStr(clipboard, "suffix modifier")
{
	LLK_ToolTip("no item in clipboard")
	Return
}
Loop, Parse, clipboard, `n, `n
{
	If InStr(A_LoopField, "item class:")
	{
		item_class := StrReplace(A_LoopField, "item class:")
		item_class := StrReplace(item_class, "`r")
	}
	If (A_Index = 3)
		item_name := StrReplace(A_LoopField, "`r")
	If (A_Index = 4)
		item_name := InStr(item_class, "sentinel") ? item_name "`nsentinel" : item_name "`n" StrReplace(A_LoopField, "`r")
	If (A_Index > 4)
		break
}
StringLower, item_name, item_name	

Loop, Parse, allowed_recomb_classes, `,, `,
{
	If InStr(item_class, A_LoopField)
	{
		allowed := 1
		break
	}
}
If (allowed = 0) || InStr(clipboard, "unidentified") || InStr(clipboard, "rarity: unique")
{
	LLK_ToolTip("cannot be recombined")
	Return
}

parse_clipboard := ""
Loop, Parse, clipboard, `n, `n
{
	If (A_Loopfield = "") || ((SubStr(A_Loopfield, 1, 1) != "{") && (!InStr(A_Loopfield, "prefix") || !InStr(A_Loopfield, "suffix")))
		continue
	Else If (SubStr(A_Loopfield, 1, 1) = "{") && (InStr(A_Loopfield, "prefix") || InStr(A_Loopfield, "suffix"))
	{
		parse_clipboard := SubStr(clipboard, InStr(clipboard, A_LoopField))
		break
	}
}

prefixes := 0
suffixes := 0
Loop 3
{
	prefix_%A_Index% := ""
	suffix_%A_Index% := ""
}
Loop, Parse, parse_clipboard, `n, `n
{
	If (A_Loopfield = "")
		continue
	If (SubStr(A_Loopfield, 1, 1) = "{")
	{
		If InStr(A_Loopfield, "prefix")
		{
			prefixes += 1
			affix := "prefix"
			brace_expected := 0
		}
		Else If InStr(A_LoopField, "suffix")
		{
			suffixes += 1
			affix := "suffix"
			brace_expected := 0
		}
	}
	Else
	{
		If (brace_expected = 1)
			break
		If (SubStr(A_LoopField, 1, 1) != "(") && (affix = "prefix")
			%affix%_%prefixes% := (%affix%_%prefixes% = "") ? StrReplace(A_Loopfield, "`r") : %affix%_%prefixes% " / " StrReplace(A_Loopfield, "`r")
		Else If (SubStr(A_LoopField, 1, 1) != "(") && (affix = "suffix")
			%affix%_%suffixes% := (%affix%_%suffixes% = "") ? StrReplace(A_Loopfield, "`r") : %affix%_%suffixes% " / " StrReplace(A_Loopfield, "`r")
		%affix%_%suffixes% := StrReplace(%affix%_%suffixes%, " — Unscalable Value")
		brace_expected := InStr(A_Loopfield, "`r") ? 1 : 0
	}
	
	Loop 3
	{
		prefix_%A_Index% := StrReplace(prefix_%A_Index%, " (crafted)")
		suffix_%A_Index% := StrReplace(suffix_%A_Index%, " (crafted)")
	}
}

remove_chars := "+-0123456789()%."

Loop 3
{
	loop := A_Index
	prefix_%A_Index%_clean := ""
	suffix_%A_Index%_clean := ""
	Loop, Parse, prefix_%A_Index%
	{
		If !InStr(remove_chars, A_Loopfield)
			prefix_%loop%_clean := (prefix_%loop%_clean = "") ? A_Loopfield : prefix_%loop%_clean A_Loopfield
	}
	Loop, Parse, suffix_%A_Index%
	{
		If !InStr(remove_chars, A_Loopfield)
			suffix_%loop%_clean := (suffix_%loop%_clean = "") ? A_Loopfield : suffix_%loop%_clean A_Loopfield
	}
	loop := A_Index
	Loop 2
	{
		affix := (A_Index = 1) ? "prefix" : "suffix"
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "increased ", "% ")
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "stun and block recovery", "stun recovery")
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 4) = " to ") ? SubStr(%affix%_%loop%_clean, 5) : %affix%_%loop%_clean
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 4) = " of ") ? SubStr(%affix%_%loop%_clean, 5) : %affix%_%loop%_clean
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 1) = " ") ? SubStr(%affix%_%loop%_clean, 2) : %affix%_%loop%_clean
		%affix%_%loop%_clean := InStr(%affix%_%loop%_clean, "/  to ") ? StrReplace(%affix%_%loop%_clean, "/  to ", "/ ") : %affix%_%loop%_clean
		%affix%_%loop%_clean := InStr(%affix%_%loop%_clean, "/  ") ? StrReplace(%affix%_%loop%_clean, "/  ", "/ ") : %affix%_%loop%_clean
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "  to  ", " ")
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "  ", " ")
		StringLower, %affix%_%loop%, %affix%_%loop%_clean
		%affix%_%loop% := (%affix%_%loop% = "") ? "(empty " affix " slot)" : %affix%_%loop%
	}
}

recomb_item2 := (recomb_item1 = "") ? "" : recomb_item1
prefix_pool2 := (prefix_pool1 = "") ? "" : prefix_pool1
prefix_pool1 := "[" prefix_1 "],[" prefix_2 "],[" prefix_3 "],"
prefix_pool1 := StrReplace(prefix_pool1, "[(empty prefix slot)],")
suffix_pool2 := (suffix_pool1 = "") ? "" : suffix_pool1
suffix_pool1 := "[" suffix_1 "],[" suffix_2 "],[" suffix_3 "],"
suffix_pool1 := StrReplace(suffix_pool1, "[(empty suffix slot)],")
recomb_item1 := item_name ":`n`n" prefix_1 "`n" prefix_2 "`n" prefix_3 "`n`n" suffix_1 "`n" suffix_2 "`n" suffix_3
recomb_item1 := StrReplace(recomb_item1, "(empty prefix slot)")
recomb_item1 := StrReplace(recomb_item1, "(empty suffix slot)")
GoSub, Recombinators_add2
Return

Recombinators_add2:
If WinExist("ahk_id " hwnd_recombinator_window)
	WinGetPos, xRecomb_window, yRecomb_window
style_recomb_window := WinExist("ahk_id " hwnd_recombinator_window) ? " x"xRecomb_window " y"yRecomb_window : " Center"
Gui, recombinator_window: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_recombinator_window, Lailloken UI: recombinators (credit: u/TheDiabeetusKing`, u/myrahz)
Gui, recombinator_window: Color, Black
Gui, recombinator_window: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, recombinator_window: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
Loop, Parse, recomb_item1, `n, `n
{
	If (A_Index = 1)
	{
		add_text := (StrLen(A_Loopfield) > 25) ? " [...]" : ""
		Gui, recombinator_window: Add, Text, % "Section BackgroundTrans vRecomb_item1_name w"width_native/8, % SubStr(A_Loopfield, 1, 25) add_text
		continue
	}
	If (A_Index = 2)
	{
		Gui, recombinator_window: Add, Text, % "xs y+0 BackgroundTrans vRecomb_item1_class wp", % A_Loopfield
		Gui, recombinator_window: Font, % "s"fSize0 - 4
		continue
	}
	If A_Index between 4 and 6
	{
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item1_prefix"A_Index - 3, % A_LoopField
		continue
	}
	If (A_Index = 8)
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp y+"fSize0 " vRecomb_item1_suffix"A_Index - 7, % A_LoopField
	If (A_Index > 8)
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item1_suffix"A_Index - 7, % A_LoopField
}
recomb_item2 := (recomb_item2 = "") ? "sample item`nclass x:`n`n`n`n`n`n`n`n" : recomb_item2
If (recomb_item2 != "")
{
	prefix_pool_unique := ""
	suffix_pool_unique := ""
	prefix_pool_target := ""
	suffix_pool_target := ""
	
	Loop, Parse, recomb_item1, `n, `n
	{
		If (A_Index < 4) || (A_LoopField = "")
			continue
		If (A_Index < 8)
			prefix_pool_unique := !InStr(prefix_pool_unique, "[" A_LoopField "],") ? prefix_pool_unique "[" A_Loopfield "]," : prefix_pool_unique
		If (A_Index > 7)
			suffix_pool_unique := !InStr(suffix_pool_unique, "[" A_LoopField "],") ? suffix_pool_unique "[" A_LoopField "]," : suffix_pool_unique
	}
	Loop, Parse, recomb_item2, `n, `n
	{
		If (A_Index < 4) || (A_LoopField = "")
			continue
		If (A_Index < 8)
			prefix_pool_unique := !InStr(prefix_pool_unique, "[" A_LoopField "],") ? prefix_pool_unique "[" A_Loopfield "]," : prefix_pool_unique
		If (A_Index > 7)
			suffix_pool_unique := !InStr(suffix_pool_unique, "[" A_LoopField "],") ? suffix_pool_unique "[" A_LoopField "]," : suffix_pool_unique
	}
	prefix_pool_unique := StrReplace(prefix_pool_unique, "[(empty prefix slot)],")
	suffix_pool_unique := StrReplace(suffix_pool_unique, "[(empty suffix slot)],")
	
	Gui, recombinator_window: Font, s%fSize0% underline
	Gui, recombinator_window: Add, Text, % "xs BackgroundTrans HWNDprefix_header wp y+"fSize0*1.2, desired prefixes:
	Gui, recombinator_window: Font, % "norm s"fSize0 - 3
	Loop, Parse, prefix_pool_unique, `,, `,
	{
		If (A_Loopfield = "")
			continue
		Gui, recombinator_window: Add, Checkbox, % "xs wp BackgroundTrans gRecombinators_calc vCheckbox_prefix"A_Index, % SubStr(A_LoopField, 2, -1)
	}
	Gui, recombinator_window: Font, % "norm s"fSize0
	
	Loop, Parse, recomb_item2, `n, `n
	{
		If (A_Index = 1)
		{
			add_text := (StrLen(A_Loopfield) > 25) ? " [...]" : ""
			Gui, recombinator_window: Add, Text, % "ys Section BackgroundTrans vRecomb_item2_name w"width_native/8, % SubStr(A_Loopfield, 1, 25) add_text
			continue
		}
		If (A_Index = 2)
		{
			Gui, recombinator_window: Add, Text, % "xs y+0 BackgroundTrans vRecomb_item2_class wp", % A_Loopfield
			Gui, recombinator_window: Font, % "s"fSize0 - 4
			continue
		}
		If A_Index between 4 and 6
		{
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item2_prefix"A_Index - 3, % A_LoopField
			continue
		}
		If (A_Index = 8)
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp y+"fSize0 " vRecomb_item2_suffix"A_Index - 7, % A_LoopField
		If (A_Index > 8)
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item2_suffix"A_Index - 7, % A_LoopField
	}
	Gui, recombinator_window: Font, underline s%fSize0%
	Gui, recombinator_window: Add, Text, % "xs BackgroundTrans HWNDsuffix_header wp y+"fSize0*1.2, desired suffixes:
	Gui, recombinator_window: Font, % "norm s"fSize0 - 3
	Loop, Parse, suffix_pool_unique, `,, `,
	{
		If (A_Loopfield = "")
			continue
		Gui, recombinator_window: Add, Checkbox, % "xs wp BackgroundTrans gRecombinators_calc vCheckbox_suffix"A_Index, % SubStr(A_LoopField, 2, -1)
	}
	Gui, recombinator_window: Font, s%fSize0% underline
	Gui, recombinator_window: Add, Text, % "xs wp vRecomb_success gRecombinators_apply BackgroundTrans y+"fSize0*1.2, % "chance of success: 100.00%"
	GuiControl, Text, recomb_success, chance of success:
	Gui, recombinator_window: Font, norm
}

ControlFocus,, ahk_id %prefix_header%
If (recomb_regular != 1)
	Gui, recombinator_window: Show, %style_recomb_window%
Else Gui, recombinator_window: Show, NA %style_recomb_window%
KeyWait, LButton
Gui, context_menu: Destroy
If (recomb_apply != 1) && (recomb_regular = 1)
	WinActivate, ahk_group poe_window
recomb_regular := 0
recomb_apply := 0
Return

Recombinators_apply:
recomb_apply := 1
refresh_needed := 0
Gui, recombinator_window: Submit, NoHide
Loop 3
{
	If InStr(recomb_item1_prefix%A_Index%, ",") || InStr(recomb_item2_prefix%A_Index%, ",") || InStr(recomb_item1_suffix%A_Index%, ",") || InStr(recomb_item2_suffix%A_Index%, ",")
	{
		LLK_ToolTip("don't use commas in text fields")
		recomb_apply := 0
		Return
	}
}
GuiControlGet, recomb_item1_name
GuiControlGet, recomb_item1_class
GuiControlGet, recomb_item2_name
GuiControlGet, recomb_item2_class
prefix_pool1 := ""
prefix_pool2 := ""
suffix_pool1 := ""
suffix_pool2 := ""
Loop 3
{
	prefix_pool1 := (recomb_item1_prefix%A_Index% != "") ? prefix_pool1 "[" recomb_item1_prefix%A_Index% "]," : prefix_pool1
	prefix_pool2 := (recomb_item2_prefix%A_Index% != "") ? prefix_pool2 "[" recomb_item2_prefix%A_Index% "]," : prefix_pool2
	suffix_pool1 := (recomb_item1_suffix%A_Index% != "") ? suffix_pool1 "[" recomb_item1_suffix%A_Index% "]," : suffix_pool1
	suffix_pool2 := (recomb_item2_suffix%A_Index% != "") ? suffix_pool2 "[" recomb_item2_suffix%A_Index% "]," : suffix_pool2
}
recomb_item1 := recomb_item1_name "`n" recomb_item1_class "`n`n" recomb_item1_prefix1 "`n" recomb_item1_prefix2 "`n" recomb_item1_prefix3 "`n`n" recomb_item1_suffix1 "`n" recomb_item1_suffix2 "`n" recomb_item1_suffix3
recomb_item2 := recomb_item2_name "`n" recomb_item2_class "`n`n" recomb_item2_prefix1 "`n" recomb_item2_prefix2 "`n" recomb_item2_prefix3 "`n`n" recomb_item2_suffix1 "`n" recomb_item2_suffix2 "`n" recomb_item2_suffix3
;(debugging) ToolTip, % recomb_item1_prefix1 "," recomb_item1_prefix2 "," recomb_item1_prefix3 "," recomb_item1_suffix1 "," recomb_item1_suffix2 "," recomb_item1_suffix3 "`n" recomb_item2_prefix1 "," recomb_item2_prefix2 "," recomb_item2_prefix3 "," recomb_item2_suffix1 "," recomb_item2_suffix2 "," recomb_item2_suffix3 "`n"
GoSub, Recombinators_add2
Return

Recombinators_calc:
If (refresh_needed = 1)
{
	LLK_ToolTip("refresh the window first")
	GuiControl, , %A_GuiControl%, 0
	Return
}
Gui, recombinator_window: Submit, NoHide
GuiControlGet, checkbox_text,, %A_GuiControl%, text
affix := InStr(prefix_pool_unique, "[" checkbox_text "],") ? "prefix" : "suffix"
%affix%_pool_target := InStr(%affix%_pool_target, "[" checkbox_text "],") ? StrReplace(%affix%_pool_target, "[" checkbox_text "],") : %affix%_pool_target "[" checkbox_text "],"
If (LLK_InStrCount(%affix%_pool_target, ",") > 3)
{
	LLK_ToolTip("too many " affix "es")
	%affix%_pool_target := StrReplace(%affix%_pool_target, "[" checkbox_text "],")
	GuiControl, , %A_GuiControl%, 0
	Return
}
Loop 2
{
	affix := (A_Index = 1) ? "prefix" : "suffix"
	%affix%_pool_total := %affix%_pool1 %affix%_pool2
	%affix%_pool_number := LLK_InStrCount(%affix%_pool_total, ",")
	%affix%_target_number := LLK_InStrCount(%affix%_pool_target, ",")
	%affix%_pool_unique_number := LLK_InStrCount(%affix%_pool_unique, ",")
	pool_number_offset := 0
	Loop, Parse, %affix%_pool_target, `,, `,
	{
		If (A_LoopField = "")
			continue
		If (LLK_InStrCount(%affix%_pool_total, A_Loopfield, ",") > 1)
			pool_number_offset += 1
	}
	%affix%_pool_calc := %affix%_pool_number - pool_number_offset
	Loop, Parse, % mod_pool_count[%affix%_pool_number], `,, `,
		chance_%A_Index%%affix% := A_Loopfield

	chance_1roll := 1
	chance_2roll := 1
	chance_3roll := 1
	If (%affix%_target_number != 0)
	{
		If (%affix%_pool_unique_number = 1)
			chance_1roll := (%affix%_target_number <= 1) ? 1 / %affix%_pool_unique_number : 0
		Else chance_1roll := (%affix%_target_number <= 1) ? 1 / %affix%_pool_calc : 0
		Loop 2
		{
			loopmod := A_Index - 1
			If (%affix%_pool_unique_number <= 2)
				chance_2roll *= (%affix%_target_number <= 2) ? (2 - loopmod) / (%affix%_pool_unique_number - loopmod) : 0
			Else chance_2roll *= (%affix%_target_number <= 2) ? (2 - loopmod) / (%affix%_pool_calc - loopmod) : 0
			If (A_Index = %affix%_target_number)
				break
		}
		Loop 3
		{
			loopmod := A_Index - 1
			If (%affix%_pool_unique_number <= 3)
				chance_3roll *= (3 - loopmod) / (%affix%_pool_unique_number - loopmod)
			Else chance_3roll *= (3 - loopmod) / (%affix%_pool_calc - loopmod)
			If (A_Index = %affix%_target_number)
				break
		}
		chance_2roll := (chance_2roll > 1) ? 1 : chance_2roll
		chance_3roll := (chance_3roll > 1) ? 1 : chance_3roll
	}
	Loop, 3
	{
		chance_%A_Index%roll_%affix% := chance_%A_Index%roll ;chance for X slots to hit desired mods
		chance_%A_Index%roll *= chance_%A_Index%%affix% ;chance for X slots to hit desired mods, and to appear on the final item
	}
	%affix%_chance := (%affix%_target_number != 0) ? chance_1roll + chance_2roll + chance_3roll : 1 ;chance for desired affix-group to appear on the final item
	%affix%_chance := (%affix%_chance > 1) ? 1 : %affix%_chance
}
debug_tooltip =
(
prefix_pool: %prefix_pool1%%prefix_pool2%
suffix_pool: %suffix_pool1%%suffix_pool2%
prefix_pool_unique: %prefix_pool_unique%
suffix_pool_unique: %suffix_pool_unique%
prefix_pool_target: %prefix_pool_target%
suffix_pool_target: %suffix_pool_target%
prefix roll odds: %chance_1roll_prefix%, %chance_2roll_prefix%, %chance_3roll_prefix%,
prefix slot chances: %chance_1prefix%, %chance_2prefix%, %chance_3prefix%
suffix roll odds: %chance_1roll_suffix%, %chance_2roll_suffix%, %chance_3roll_suffix%,
suffix slot chances: %chance_1suffix%, %chance_2suffix%, %chance_3suffix%
)
;ToolTip, % debug_tooltip, 0, 0
If (prefix_target_number + suffix_target_number > 0)
	GuiControl, Text, recomb_success, % "chance of success: " Format("{:0.2f}", (prefix_chance * suffix_chance)*100) "%"
Else GuiControl, Text, recomb_success, % "chance of success: "
Return

Recombinators_input:
refresh_needed := 1
GuiControl, Text, recomb_success, refresh
Return

recombinator_windowGuiClose()
{
	global
	recomb_item1 := ""
	Gui, recombinator_window: Destroy
	hwnd_recombinator_window := ""
	WinActivate, ahk_group poe_window
}