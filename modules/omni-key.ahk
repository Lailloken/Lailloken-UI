Omnikey()
{
	local
	global vars, settings, db

	If vars.omnikey.last	;when the omni-key was last pressed ;for certain hotkeys, AHK keeps firing whatever is bound to it while holding down the key
		Return			;there is a separate function activated when releasing the omni-key that clears this variable again
	vars.omnikey.last := A_TickCount
	StringScroll("ESC") ;close searchstring-scrolling

	If vars.client.stream
	{
		Omnikey2()
		Return
	}

	ThisHotkey_copy := StrReplace(A_ThisHotkey, "*~"), guide := vars.leveltracker.guide

	Loop, Parse, % "!,+,#,^, UP", `,
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(ThisHotkey_copy, A_LoopField)
	If Blank(ThisHotkey_copy)
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(A_ThisHotkey, "*~")

	Clipboard := ""
	If (vars.general.wMouse = vars.hwnd.poe_client) && !WinActive("ahk_id " vars.hwnd.poe_client)
	{
		WinActivate, % "ahk_id " vars.hwnd.poe_client
		WinWaitActive, % "ahk_id " vars.hwnd.poe_client
	}

	If WinExist("ahk_id " vars.hwnd.maptrackernotes_edit.main)
	{
		MaptrackerNoteAdd(), OmniRelease()
		Return
	}

	If settings.hotkeys.item_descriptions && settings.hotkeys.rebound_alt
		SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
	Else SendInput !^{c}

	ClipWait, 0.1

	If Clipboard
	{
		If (settings.general.lang_client = "unknown")
		{
			LLK_ToolTip(LangTrans("omnikey_language"), 3,,,, "red"), OmniRelease()
			Return
		}

		vars.omnikey.start := A_TickCount, vars.omnikey.item := {} ;store data about the clicked item here
		OmniItemInfo()

		Switch OmniContext()
		{
			Case "essences":
				While GetKeyState(vars.omnikey.hotkey, "P")
				{
					If (A_TickCount >= essence_last + 100)
						EssenceTooltip(vars.general.cMouse), essence_last := A_TickCount
					Sleep 1
				}
				LLK_Overlay(vars.hwnd.essences.main, "destroy")
			Case "iteminfo":
				Iteminfo()
			Case "gemnotepad":
				text := StrReplace(LLK_ControlGet(vars.hwnd.notepad.note), "`n", "(n)"), text .= (Blank(text) ? "" : "(n)") vars.omnikey.item.name_copy
				While (SubStr(text, 1, 1) = " ") || (SubStr(text, 1, 3) = "(n)")
					text := (SubStr(text, 1, 1) = " ") ? SubStr(text, 2) : SubStr(text, 4)
				If InStr(LLK_IniRead("ini\qol tools.ini", "notepad", "gems"), vars.omnikey.item.name_copy)
					LLK_ToolTip(LangTrans("notepad_addgems", 2),,,,, "red")
				Else
				{
					IniWrite, % LLK_StringCase(text), ini\qol tools.ini, notepad, gems
					Notepad(), LLK_ToolTip(LangTrans("notepad_addgems"),,,,, "lime")
				}
			Case "gemnotes":
				note := vars.leveltracker.guide.gem_notes[vars.omnikey.item.name]
				LLK_ToolTip(!note ? LangTrans("lvltracker_gemnotes") : note, note? 0 : 2,,, "gem_notes")
			Case "geartracker":
				GeartrackerAdd()
			Case "legion":
				LegionParse(), LegionGUI()
			Case "context_menu":
				OmniContextMenu()
			Case "horizons":
				HorizonsTooltip("a")
				KeyWait, % ThisHotkey_copy
				LLK_Overlay(vars.hwnd.horizons.main, "destroy")
			Case "horizons_map":
				HorizonsTooltip(vars.omnikey.item.tier)
				KeyWait, % ThisHotkey_copy
				LLK_Overlay(vars.hwnd.horizons.main, "destroy")
			Case "horizons_shaper":
				HorizonsTooltip("shaper")
				KeyWait, % ThisHotkey_copy
				LLK_Overlay(vars.hwnd.horizons.main, "destroy")
			Case "mapinfo":
				If MapinfoParse()
					MapinfoGUI()
			Case "recombination":
				Recombination_()
		}
	}
	Else If (ThisHotkey_copy != settings.hotkeys.omnikey2) ;prevent item-only omni-key from executing non-item features
		Omnikey2()
	OmniRelease()
}

Omnikey2()
{
	local
	global vars, settings

	If vars.omnikey.last2
		Return
	vars.omnikey.last2 := A_TickCount

	StringScroll("ESC") ;close searchstring-scrolling
	If !IsObject(vars.omnikey)
		vars.omnikey := {}

	guide := vars.leveltracker.guide, ThisHotkey_copy := StrReplace(A_ThisHotkey, "*~")
	Loop, Parse, % "!,+,#,^, UP", `,
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(ThisHotkey_copy, A_LoopField)
	If Blank(ThisHotkey_copy)
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(A_ThisHotkey, "*~")

	If settings.features.cheatsheets && GetKeyState(settings.cheatsheets.modifier, "P")
	{
		vars.cheatsheets.pHaystack := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
		For cheatsheet in vars.cheatsheets.list
		{
			If !vars.cheatsheets.list[cheatsheet].enable
				continue
			If CheatsheetSearch(cheatsheet)
			{
				CheatsheetActivate(cheatsheet, ThisHotkey_copy)
				Break
			}
		}
		Gdip_DisposeImage(vars.cheatsheets.pHaystack), OmniRelease()
		Return
	}

	If !settings.features.pixelchecks
		Screenchecks_PixelSearch("gamescreen")

	If !vars.pixelsearch.gamescreen.check
	{
		Screenchecks_ImageSearch()
		If settings.features.betrayal && vars.imagesearch.betrayal.check
		{
			Betrayal(), OmniRelease()
			Return
		}

		If settings.features.leveltracker && vars.imagesearch.skilltree.check
		{
			LeveltrackerSkilltree(), OmniRelease()
			Return
		}

		If (InStr(vars.log.areaID, "_town") || (vars.log.areaID = "1_3_17_1") || vars.client.stream) && vars.leveltracker.toggle && (guide.gems.Count() || guide.items.Count())
		{
			start := A_TickCount
			While GetKeyState(ThisHotkey_copy, "P")
			{
				If (A_TickCount >= start + 100)
				{
					StringContextMenu("exile-leveling")
					KeyWait, % ThisHotkey_copy
					OmniRelease()
					Return
				}
			}
		}

		If !stash && vars.searchstrings.enabled
		{
			If WinExist("ahk_id "vars.hwnd.searchstrings_menu.main)
				StringMenuSave()
			vars.searchstrings.pHaystack := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
			For string, val in vars.searchstrings.list
			{
				If !val.enable
					Continue
				If StringSearch(string)
				{
					StringContextMenu(string)
					Break
				}
			}
			Gdip_DisposeImage(vars.searchstrings.pHaystack)
		}
	}
	OmniRelease()
}

OmniRelease()
{
	local
	global vars, settings

	KeyWait, % vars.omnikey.hotkey
	If IsObject(vars.omnikey)
		vars.omnikey.last := "", vars.omnikey.last2 := ""
}

OmniContext(mode := 0)
{
	local
	global vars, settings

	If mode
		Iteminfo(2)
	ThisHotkey_copy := A_ThisHotkey, clip := !mode ? vars.omnikey.clipboard : Clipboard, item := vars.omnikey.item

	Loop, Parse, % "*~!+#^"
		ThisHotkey_copy := StrReplace(ThisHotkey_copy, A_LoopField)

	While (!settings.features.stash || GetKeyState("ALT", "P")) && GetKeyState(ThisHotkey_copy, "P") && InStr(item.name, "Essence of ", 1) || (item.name = "remnant of corruption")
		If (A_TickCount >= vars.omnikey.start + 200)
			Return "essences"
	If WinExist("ahk_id " vars.hwnd.recombination.main) && LLK_PatternMatch(item.class, "", vars.recombination.classes,,, 0)
		Return "recombination"
	If WinExist("ahk_id "vars.hwnd.legion.main) && (item.itembase = "Timeless Jewel")
		Return "legion"
	If WinExist("ahk_id " vars.hwnd.notepad.main) && (vars.notepad.selected_entry = "gems") && (item.rarity = LangTrans("items_gem"))
		Return "gemnotepad"
	If settings.features.leveltracker && vars.hwnd.tooltipgem_notes && WinExist("ahk_id " vars.hwnd.tooltipgem_notes) && (item.rarity = LangTrans("items_gem"))
		Return "gemnotes"
	While settings.features.leveltracker && vars.hwnd.leveltracker.main && GetKeyState(ThisHotkey_copy, "P") && (item.rarity = LangTrans("items_gem"))
		If (A_TickCount >= vars.omnikey.start + 200)
			Return "gemnotes"
	If !settings.features.stash && (item.name = "Orb of Horizons")
		While GetKeyState(ThisHotkey_copy, "P")
			If (A_TickCount >= vars.omnikey.start + 200)
				Return "horizons"
	If !LLK_PatternMatch(item.name "`n" item.itembase, "", ["Doryani", "Maple"]) && LLK_PatternMatch(item.name "`n" item.itembase, "", ["Map", "Invitation", "Blueprint:", "Contract:", "Expedition Logbook"])
	&& (item.rarity != LangTrans("items_unique"))
	{
		While GetKeyState(ThisHotkey_copy, "P") && LLK_PatternMatch(item.name "`n" item.itembase, "", ["Map"])
			If (A_TickCount >= vars.omnikey.start + 200)
			{
				If LLK_PatternMatch(vars.omnikey.clipboard, "", ["Maze of the Minotaur", "Forge of the Phoenix", "Lair of the Hydra", "Pit of the Chimera"])
					Return "horizons_shaper"
				Else If item.tier
					Return "horizons_map"
				Else Return
			}
		If settings.features.mapinfo
			Return "mapinfo"
	}
	If settings.features.stash && !GetKeyState("ALT", "P")
	{
		check := LLK_HasKey(vars.stash, item.name,,,, 1), start := A_TickCount
		While check && (Blank(item.itembase) || item.name = item.itembase) && GetKeyState(ThisHotkey_copy, "P")
			If (A_TickCount >= start + 150)
			{
				Stash_(check)
				Return
			}
	}
	If WinExist("ahk_id " vars.hwnd.iteminfo.main)
		Return "iteminfo"
	While GetKeyState(ThisHotkey_copy, "P")
		If (A_TickCount >= vars.omnikey.start + 200)
			Return "iteminfo"
	If WinExist("ahk_id " vars.hwnd.geartracker.main)
		Return "geartracker"
	If !LLK_PatternMatch(item.name "`n" item.itembase, "", ["Map", "Invitation", "Blueprint:", "Contract:", "Expedition Logbook"]) || LLK_PatternMatch(item.name "`n" item.itembase, "", ["Doryani", "Maple"])
	|| (item.rarity = LangTrans("items_unique"))
		Return "context_menu"
}

OmniContextMenu()
{
	local
	global vars, settings, db

	Loop 2
	{
		Gui, omni_context: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd0
		Gui, omni_context: Margin, % settings.general.fWidth, % settings.general.fWidth//2
		Gui, omni_context: Color, Black
		;WinSet, Transparent, % settings.general.trans
		Gui, omni_context: Font, % "s"settings.general.fSize " cWhite", % vars.system.font
		vars.hwnd.omni_context := {"main": hwnd0}, vars.omni_context := {}, item := vars.omnikey.item, style := (A_Index = 2) ? " w" width : "", hwnd := ""

		If !(item.unid && item.rarity = LangTrans("items_unique")) && (LLK_PatternMatch(item.name, "", ["Splinter"]) || item.itembase || !LLK_PatternMatch(item.rarity, "", [LangTrans("items_magic"), LangTrans("items_rare"), LangTrans("items_currency")]))
		{
			Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick HWNDhwnd" style, % "poe.wiki: " LLK_StringCase(item[item.itembase && item.rarity != LangTrans("items_unique") ? "itembase" : "name"])
			ControlGetPos,,, w1,,, % "ahk_id " hwnd
			vars.hwnd.omni_context.wiki_exact := hwnd, vars.omni_context[hwnd] := item[item.itembase && item.rarity != LangTrans("items_unique") ? "itembase" : "name"]
		}

		If (item.rarity != LangTrans("items_unique"))
		&& (settings.general.lang_client = "english" && !InStr(item.class, "currency") || LLK_HasVal(db.item_bases._classes, item.class) || LLK_PatternMatch(item.name, "", ["Essence of", "Scarab", "Catalyst", " Oil", "Memory of "]))
		{
			If !Blank(LLK_HasVal(db.item_bases._classes, item.class))
				class := db.item_bases._classes[LLK_HasVal(db.item_bases._classes, item.class)]
			Else If LLK_PatternMatch(item.name, "", ["Essence of", "Scarab", "Catalyst", " Oil", "Memory of "])
				class := LLK_PatternMatch(item.name, "", ["Essence of", "Scarab", "Catalyst", " Oil", "Memory of "])
			Else If (settings.general.lang_client = "english")
				class := item.class
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd" style, % "poe.wiki: " LLK_StringCase((InStr(item.itembase, "Runic ") ? "runic " : "") . class)
			ControlGetPos,,, w2,,, % "ahk_id " hwnd
			If (class != "cluster jewels") && (!Blank(LLK_HasVal(db.item_bases._classes, item.class)) || InStr(item.class, "heist") && item.itembase)
			{
				Gui, omni_context: Add, Text, % "Section xs gOmniContextMenuPick HWNDhwnd1" style, % "poe.db: " LangTrans("system_poedb_lang", 2)
				ControlGetPos,,, w3,,, % "ahk_id " hwnd1
			}
			If !item.unid && (settings.general.lang_client = "english") && !Blank(LLK_HasVal(db.item_bases._classes, item.class)) && !LLK_PatternMatch(item.name, "", ["Essence of", "Scarab", "Catalyst", " Oil"])
			{
				Gui, omni_context: Add, Text, % "Section xs gOmniContextMenuPick HWNDhwnd2" style, % "craft of exile"
				ControlGetPos,,, w4,,, % "ahk_id " hwnd2
			}
			If LLK_PatternMatch(item.class, "", vars.recombination.classes,,, 0)
				Gui, omni_context: Add, Text, % "Section xs gOmniContextMenuPick HWNDhwnd3 " style, % "recombination"
			vars.hwnd.omni_context.wiki_class := hwnd, vars.omni_context[hwnd] := class, vars.hwnd.omni_context.poedb := hwnd1
			vars.hwnd.omni_context.craftofexile := hwnd2, vars.hwnd.omni_context.recombination := hwnd3
			width := (Max(w, w1, w2) > width) ? Max(w, w1, w2) : width
		}

		If InStr(item.name, "to the goddess")
		{
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd", % "poelab.com"
			ControlGetPos,,, w5,,, % "ahk_id " hwnd
			vars.hwnd.omni_context.poelab := hwnd
		}

		If (class = "oil")
		{
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd", % "raelys' blight-helper"
			ControlGetPos,,, w6,,, % "ahk_id " hwnd
			vars.hwnd.omni_context.oiltable := hwnd
		}

		If (class = "Cluster jewels")
		{
			cluster_type := InStr(item.itembase, "small") ? "small" : InStr(item.itembase, "medium") ? "medium" : "large"
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd" style, % "poe.db: all clusters"
			Gui, omni_context: Add, Text, % "Section xs gOmniContextMenuPick HWNDhwnd1" style, % "poe.db: " . cluster_type . " clusters"
			ControlGetPos,,, w7,,, % "ahk_id " hwnd
			ControlGetPos,,, w8,,, % "ahk_id " hwnd1
			vars.hwnd.omni_context.poedb := hwnd, vars.hwnd.omni_context.poedb1 := hwnd1
		}

		If !item.unid && (item.itembase = "Timeless Jewel") && InStr(vars.omnikey.clipboard, LangTrans("items_uniquemod"))
		{
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd" style, % "seed-explorer"
			ControlGetPos,,, w9,,, % "ahk_id " hwnd
			Gui, omni_context: Add, Text, % "Section xs gOmniContextMenuPick HWNDhwnd1" style, % "vilsol's calculator"
			ControlGetPos,,, w10,,, % "ahk_id " hwnd
			vars.hwnd.omni_context.seed := hwnd, vars.hwnd.omni_context.vilsol := hwnd1
		}

		If !item.unid && item.sockets
		{
			Gui, omni_context: Add, Text, % "Section" (hwnd ? " xs " : " ") "gOmniContextMenuPick HWNDhwnd" style, % "chromatic calculator"
			ControlGetPos,,, w11,,, % "ahk_id " hwnd
			vars.hwnd.omni_context.chromatics := hwnd
		}
		Loop 11
			w%A_Index% := !w%A_Index% ? 0 : w%A_Index%
		width := Max(w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11)
	}

	MouseGetPos, mouseX, mouseY
	Gui, omni_context: Show, % "NA x10000 y10000"
	WinGetPos,,, w, h, % "ahk_id " vars.hwnd.omni_context.main
	xTarget := (mouseX + w > vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - w : mouseX
	yTarget := (mouseY + h > vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - h : mouseY
	If (w > 50)
		Gui, omni_context: Show, % "NA x" xTarget " y" yTarget
	Else Gui, omni_context: Destroy
}

OmniContextMenuPick(cHWND)
{
	local
	global vars, settings

	item := vars.omnikey.item, check := LLK_HasVal(vars.hwnd.omni_context, cHWND), control := SubStr(check, InStr(check, " ") + 1)
	KeyWait, LButton
	If InStr(check, "wiki_")
	{
		class := StrReplace(vars.omni_context[cHWND], " ", "_"), class := (class = "body_armours") ? "Body_armour" : (InStr(item.itembase, "Runic ") ? "Runic_base_type#" : "") . class
		class := StrReplace(class, "Jewels", "jewel"), class := InStr(item.class, "heist ") ? "Rogue's_equipment#" . StrReplace(item.class, "heist ") : class
		Run, % "https://www.poewiki.net/wiki/" . class
	}
	Else If (check = "poelab")
	{
		Run, % "https://www.poelab.com/"
		If settings.qol.lab && settings.features.browser
		{
			WinWaitActive, ahk_group snipping_tools,, 2
			ToolTip_Mouse("lab", 1)
		}
		If settings.qol.lab
			Lab("import")
	}
	Else If (check = "oiltable")
		Run, https://blight.raelys.com/
	Else If InStr(check, "poedb")
	{
		If InStr(item.itembase, "Cluster Jewel")
			page := (InStr(A_GuiControl, "all clusters") ? "" : (InStr(item.itembase, "small") ? "Small_" : InStr(item.itembase, "medium") ? "Medium_" : "Large_")) "Cluster_Jewel"
		Else If InStr(item.itembase, "Runic ", 1)
			page := (item.class = "boots") ? "Runic_Sabatons" : (item.class = "helmets") ? "Runic_Crown" : "Runic_Gauntlets"
		Else If !Blank(LLK_HasVal(["unset ring", "iron flask", "bone ring", "convoking wand", "bone spirit shield", "silver flask"], item.itembase)) || InStr(item.class, "jewels") || InStr(item.class, "heist")
			page := StrReplace(item.itembase, " ", "_")
		Else page := StrReplace(item.class, " ", "_") . item.attributes
		Run, % "https://poedb.tw/" . LangTrans("system_poedb_lang") . "/" . page . (InStr(page, "cluster_jewel") ? "#EnchantmentModifiers" : "#ModifiersCalc")
		Clipboard := item.ilvl
		If InStr(page, "cluster_jewel") && settings.features.browser
		{
			WinWaitActive, ahk_group snipping_tools,, 2
			ToolTip_Mouse("cluster", 1)
		}
	}
	Else If (check = "craftofexile")
		Run, https://www.craftofexile.com/
	Else If (check = "seed")
		LegionParse(), LegionGUI()
	Else If (check = "vilsol")
	{
		LegionParse()
		Run, % "https://vilsol.github.io/timeless-jewels/tree?jewel=" vars.legion.jewel_number "&conqueror=" LLK_StringCase(vars.legion.leader,, 1) "&seed=" vars.legion.seed "&mode=seed"
	}
	Else If (check = "chromatics")
	{
		Run, https://siveran.github.io/calc.html
		If settings.features.browser
		{
			WinWaitActive, ahk_group snipping_tools,, 2
			ToolTip_Mouse("chromatics", 1)
		}
	}
	Else If (check = "recombination")
		Recombination_()
	Gui, omni_context: Destroy
}

OmniItemInfo()
{
	local
	global vars, settings, db

	Iteminfo(2)
	item := vars.omnikey.item, clip := vars.omnikey.clipboard ;short-cut variables

	If item.itembase
	{
		item.attributes := ""
		For class, val in db.item_bases
			If InStr(item.class, class)
				For subtype, val1 in val
					If val1.HasKey(item.itembase)
						item.attributes .= InStr(subtype, "armour") ? "_str" : "", item.attributes .= InStr(subtype, "evasion") ? "_dex" : "", item.attributes .= InStr(subtype, "energy") ? "_int" : ""
	}

	Loop, Parse, clip, `n, % "`r " ;store the item's class, rarity, and miscellaneous info
	{
		loopfield := A_LoopField
		If InStr(A_LoopField, LangTrans("items_level"), 1) && !InStr(A_LoopField, LangTrans("items_ilevel"))
			item.lvl_req := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), " (unmet)"), item.lvl_req := (item.lvl_req < 10) ? 0 . item.lvl_req : item.lvl_req

		Loop, Parse, % "str,dex,int", `,
			If LLK_PatternMatch(loopfield, "", vars.lang["items_" A_LoopField])
				item[A_LoopField] := StrReplace(StrReplace(SubStr(loopfield, InStr(loopfield, ":") + 2), " (augmented)"), " (unmet)")

		If InStr(A_LoopField, LangTrans("items_ilevel"))
			item.ilvl := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)

		If InStr(A_LoopField, LangTrans("mods_cluster_passive"))
			item.cluster_enchant := StrReplace(StrReplace(SubStr(A_LoopField, StrLen(LangTrans("mods_cluster_passive")) + 2), "+"), " (enchant)")

		If !InStr("rings,belts,amulets", item.class) && LLK_PatternMatch(SubStr(A_LoopField, 0), "", ["R", "G", "B", "W", "A"])
			item.sockets := StrLen(StrReplace(StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), " "), "-"))

		If InStr(A_LoopField, LangTrans("items_maptier"))
			item.tier := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)
	}
}
