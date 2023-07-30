Omnikey()
{
	local
	global vars, settings, db
	
	If vars.omnikey.last ;when the omni-key was last pressed ;for certain hotkeys, AHK keeps firing whatever is bound to it while holding down the key
		Return ;there is a separate function activated when releasing the omni-key that clears this variable again
	vars.omnikey.last := A_TickCount

	StringScroll("ESC") ;close searchstring-scrolling
	ThisHotkey_copy := A_ThisHotkey, guide := vars.leveltracker.guide
	If !IsObject(vars.omnikey)
		vars.omnikey := {}
	;If WinExist("ahk_id " vars.hwnd.mapinfo)
	;	LLK_MapInfoClose()

	Loop, Parse, % "*,~,!,+,#,^, UP", `,
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(ThisHotkey_copy, A_LoopField)

	If settings.features.cheatsheets && vars.cheatsheets.enabled && GetKeyState(settings.cheatsheets.omni_modifier, "P")
	|| (InStr(vars.log.areaID, "_town") || vars.log.areaID = "1_3_17_1") && WinExist("ahk_id "vars.hwnd.leveltracker.main) && (guide.group1.gems.Count() || guide.group1.items.Count())
	{
		Omnikey2()
		Return
	}

	Clipboard := ""
	
	If (vars.general.wMouse = vars.hwnd.poe_client) && !WinActive("ahk_id "vars.hwnd.poe_client)
	{
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		Sleep 250
	}

	If settings.hotkeys.item_descriptions && settings.hotkeys.rebound_alt
		SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
	Else SendInput !^{c}

	If GetKeyState("Ctrl", "p") && settings.general.dev ;override clipboard for testing purposes
	{
		Clipboard := 
		(LTrim
		)
	}
	ClipWait, 0.05

	If Clipboard
	{
		vars.omnikey.start := A_TickCount
		vars.omnikey.item := {} ;store data about the clicked item here
		vars.omnikey.clipboard := StrReplace(Clipboard, "You cannot use this item. Its stats will be ignored`r`n--------`r`n")
		
		OmniItemInfo()

		Switch OmniContext()
		{
			Case "iteminfo":
				Iteminfo()
			Case "gemnotes":
				note := vars.leveltracker.guide.gem_notes[vars.omnikey.item.name]
				LLK_ToolTip(!note ? "no notes" : note, note? 0 : 1,,, "gem_notes")
			Case "geartracker":
				GeartrackerAdd()
			Case "recombinators_blank":

			Case "recombinators_add":

			Case "legion":
				LegionParse(), LegionGUI()
			Case "context_menu":
				OmniContextMenu()

			Case "horizons":
				LLK_ToolTip("horizons:`n"db.mapinfo.maps.a, 0,,, "horizon")
				While GetKeyState(ThisHotkey_copy, "P")
				{
					Input, keypress, L1 T0.5
					If LLK_IsType(keypress, "alpha") && db.mapinfo.maps[keypress]
						LLK_ToolTip("horizons:`n"db.mapinfo.maps[keypress], 0,,, "horizon")
				}
				Gui, tooltiphorizon: Destroy
				vars.hwnd.Delete("tooltiphorizon")
			Case "horizons_map":
				LLK_ToolTip("horizons:`n"db.mapinfo.maps[vars.omnikey.item.tier] (vars.log.level ? "`nexp: " LeveltrackerExperience(67 + vars.omnikey.item.tier) "%" : ""), 0,,, "horizon")
				KeyWait, % ThisHotkey_copy
				Gui, tooltiphorizon: Destroy
				vars.hwnd.Delete("tooltiphorizon")
			Case "mapinfo":
				If MapinfoParse()
					MapinfoGUI()
		}
	}
	Else If (ThisHotkey_copy != settings.hotkeys.omnikey2) ;prevent item-only omni-key from executing non-item features
		Omnikey2()
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

	guide := vars.leveltracker.guide, ThisHotkey_copy := A_ThisHotkey
	Loop, Parse, % "*,~,!,+,#,^, UP", `,
		ThisHotkey_copy := vars.omnikey.hotkey := StrReplace(ThisHotkey_copy, A_LoopField)
	
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
		Gdip_DisposeImage(vars.cheatsheets.pHaystack)
		OmniRelease()
		Return
	}
	
	If !settings.features.pixelchecks
		Screenchecks_PixelSearch("gamescreen")
	
	If !vars.pixelsearch.gamescreen.check
	{
		/*
		If (InStr(current_location, "_town") || InStr(current_location, "1_3_17_1")) && WinExist("ahk_id " hwnd_leveling_guide2) && InStr(text2, "hold omni-key")
		{
			If searchstrings_scroll_contents
				searchstrings_scroll_contents := ""
			start := A_TickCount
			While GetKeyState(ThisHotkey_copy, "P")
			{
				If (A_TickCount >= start + 100)
				{
					;LLK_StringPick("exile leveling")
					KeyWait, % ThisHotkey_copy
					Return
				}
			}
		}
		*/
		
		Screenchecks_ImageSearch()
		
		If settings.features.betrayal && vars.imagesearch.betrayal.check
		{
			Betrayal()
			Return
		}

		If settings.features.leveltracker && vars.imagesearch.skilltree.check
		{
			LeveltrackerSkilltree()
			Return
		}
		
		If (InStr(vars.log.areaID, "_town") || (vars.log.areaID = "1_3_17_1")) && WinExist("ahk_id "vars.hwnd.leveltracker.main) && (guide.gems.Count() || guide.items.Count())
		{
			start := A_TickCount
			While GetKeyState(ThisHotkey_copy, "P")
			{
				If (A_TickCount >= start + 100)
				{
					StringContextMenu("exile-leveling")
					KeyWait, % ThisHotkey_copy
					Return
				}
			}
		}

		If vars.searchstrings.enabled
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
	Return

	pHaystack := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	For key, value in searchstrings_enabled
	{
		If bla ;LLK_StringSearch(value)
		{
			If WinExist("ahk_id " hwnd_searchstrings_menu)
			{
				Gui, searchstrings_menu: Submit, NoHide
				;LLK_StringMenuSave()
			}
			parse := StrReplace(value, " ", "_")
			If !searchstrings_%parse%_contents.Count()
			{
				LLK_ToolTip("no strings set up for:`n" value, 1.5)
				Return
			}
			searchstring_activated := value, searchstring_activated1 := StrReplace(searchstring_activated, " ", "_")
			;LLK_StringActivate(value)
			Break
		}
	}
	Gdip_DisposeImage(pHaystack)
}

OmniRelease()
{
	global
	
	If IsObject(vars.omnikey)
		vars.omnikey.last := "", vars.omnikey.last2 := ""
}

OmniURL(site)
{
	global
	local exceptions := ["unset ring", "iron flask", "bone ring", "convoking wand", "bone spirit shield", "silver flask", "crimson jewel", "viridian jewel", "cobalt jewel", "prismatic jewel"]
	
	Switch site
	{
		Case "wiki":
			If InStr(vars.omnikey.item.name, " Oil", 1)
				Return "Oil"
			Else If InStr(vars.omnikey.item.name, " Catalyst", 1)
				Return "Catalyst"
			Else If LLK_HasVal(vars.omnikey.item, " Cluster Jewel", 1, 1)
				Return "Cluster_Jewel"
			Else If LLK_HasVal(vars.omnikey.item, "Runic ", 1, 1) && InStr(vars.omnikey.clipboard, "ward: ")
				Return "Runic_base_type#" vars.omnikey.item.class
			Else If InStr(vars.omnikey.item.class, "heist ")
			{
				If vars.omnikey.item.heist_job
					Return "Rogue's_equipment#"vars.omnikey.item.heist_job
				Else If InStr(vars.omnikey.clipboard, "melee damage (implicit)")
					Return "Rogue's_equipment#Melee"
				Else If InStr(vars.omnikey.clipboard, "projectile attack damage (implicit)")
					Return "Rogue's_equipment#Ranged"
				Else If InStr(vars.omnikey.clipboard, "spell damage (implicit)")
					Return "Rogue's_equipment#Caster"
				Else Return "Rogue's_equipment#"StrReplace(vars.omnikey.item.class, "heist ")
			}
			Else Return (vars.omnikey.item.class = "Body armours") ? "Body_Armour" : StrReplace(vars.omnikey.item.class, " ", "_")
		Case "poe.db":
			If LLK_HasVal(vars.omnikey.item, "Runic ", 1, 1) && InStr(vars.omnikey.clipboard, "`nWard: ", 1)
			{
				If (vars.omnikey.item.class = "gloves")
					Return "Runic_Gauntlets"
				Else Return (vars.omnikey.item.class = "helmets") ? "Runic_Crown" : "Runic_Sabatons"
			}
			Else If LLK_HasVal(exceptions, vars.omnikey.item.itembase) || InStr(vars.omnikey.item.class, "heist ") && !InStr(vars.omnikey.item.class, " target") || (vars.omnikey.item.class = "abyss jewels")
				Return StrReplace(vars.omnikey.item.itembase, " ", "_")
			Else If InStr("Gloves,Boots,Body Armours,Helmets,Shields", vars.omnikey.item.class)
				Return StrReplace(vars.omnikey.item.class, " ", "_") vars.omnikey.item.attributes
			Else Return StrReplace(vars.omnikey.item.class, " ", "_")
	}
	
}

OmniContext(mode := 0)
{
	local
	global vars, settings
	
	ThisHotkey_copy := A_ThisHotkey, clip := !mode ? vars.omnikey.clipboard : Clipboard
	Loop, Parse, % "*~!+#^"
		ThisHotkey_copy := StrReplace(ThisHotkey_copy, A_LoopField)

	If WinExist("ahk_id "vars.hwnd.legion.main) && InStr(clipboard, "passives in radius are conquered by ")
		Return "legion"

	If vars.hwnd.tooltipgem_notes && WinExist("ahk_id "vars.hwnd.tooltipgem_notes) && InStr(vars.omnikey.clipboard, "rarity: gem")
		Return "gemnotes"

	While GetKeyState(ThisHotkey_copy, "P") && InStr(vars.omnikey.clipboard, "rarity: gem")
		If (A_TickCount >= vars.omnikey.start + 200)
			Return "gemnotes"

	If WinExist("ahk_id " vars.hwnd.iteminfo.main) && !InStr(clip, "item class: maps") && !InStr(clip, "orb of horizon") && !InStr(clip, "rarity: gem") && !InStr(clip, "item class: blueprints") && !InStr(clip, "item class: contracts")
		Return "iteminfo"

	While GetKeyState(ThisHotkey_copy, "P") && !InStr(clip, "item class: maps") && !InStr(clip, "orb of horizon") && !InStr(clip, "rarity: gem") && !InStr(clip, "item class: blueprints") && !InStr(clip, "item class: contracts")
		If (A_TickCount >= vars.omnikey.start + 200)
			Return "iteminfo"

	If WinExist("ahk_id "vars.hwnd.geartracker.main)
		Return "geartracker"

	If InStr(clip, "recombinator") || InStr(clip, "power core")
		Return "recombinators_blank"

	If WinExist("ahk_id " hwnd_recombinator_window)
		Return "recombinators_add"
	
	If InStr(clip, "`nOil Extractor", 1) || InStr(clip, " catalyst`r`n") || InStr(clip, " class: map fragments") || InStr(clip, " splinter`r`n") || InStr(clip, "`r`nsplinter of ") || InStr(clip, "`r`nblessing of ")
		Return "context_menu"

	If !InStr(clip, "Rarity: Currency") && (!InStr(clip, "Item Class: Map") && !InStr(vars.omnikey.item.itembase, " invitation")) && !InStr(clip, "item class: heist target") && !InStr(clip, "Item Class: Expedition")
	&& !InStr(clip, "Item Class: Stackable Currency") && !InStr(clip, "item class: blueprints") && !InStr(clip, "item class: contracts") && !InStr(clip, "rarity: quest")
	|| InStr(clip, "to the goddess") || InStr(clip, "other oils")
		Return "context_menu"

	If InStr(clip, "Orb of Horizons")
	{
		While GetKeyState(ThisHotkey_copy, "P")
		{
			If (A_TickCount >= vars.omnikey.start + 200)
				Return "horizons"
		}
	}
	
	If (InStr(clip, "Item Class: Map") || InStr(vars.omnikey.item.itembase, " invitation") || InStr(clip, "item class: blueprints") || InStr(clip, "item class: contracts") || InStr(clip, "item class: expedition")) && !InStr(clip, "Fragment")
	{
		While GetKeyState(ThisHotkey_copy, "P") && !InStr(clip, "item class: blueprints") && !InStr(clip, "item class: contracts") && !InStr(clip, "item class: expedition")
		{
			If (A_TickCount >= vars.omnikey.start + 200)
			{
				Loop, Parse, clip, `n, `r
				{
					If InStr(A_Loopfield, "Map Tier: ")
					{
						vars.omnikey.item.tier := StrReplace(A_Loopfield, "Map Tier: ")
						Break
					}
				}
				If InStr(clip, "maze of the minotaur") || InStr(clip, "forge of the phoenix") || InStr(clip, "lair of the hydra") || InStr(clip, "pit of the chimera")
				{
					LLK_ToolTip("horizons:`nmaze of the minotaur`nforge of the phoenix`nlair of the hydra`npit of the chimera" (vars.log.level ? "`nexp: " LeveltrackerExperience(83) "%" : ""), 0,,, "horizon")
					KeyWait, % ThisHotkey_copy
					Gui, tooltiphorizon: Destroy
					vars.hwnd.Delete("tooltiphorizon")
					Return
				}
				Else Return "horizons_map"
			}
		}
		If settings.features.mapinfo
		{
			If !LLK_CheckAdvancedItemInfo()
				Return
			Return "mapinfo"
		}
	}
}

OmniContextMenu()
{
	global
	local cluster_type, mouseX, mouseY, x_context, w_context

	Gui, omni_context: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
	Gui, omni_context: Margin, % settings.general.fWidth, % settings.general.fHeight/3
	Gui, omni_context: Color, Black
	WinSet, Transparent, % settings.general.trans
	Gui, omni_context: Font, % "s"settings.general.fSize " cWhite", Fontin SmallCaps
	vars.hwnd.omni_context := hwnd

	If !InStr(Clipboard, "`nUnidentified", 1) && (InStr(Clipboard, "Rarity: Unique") || InStr(Clipboard, "Rarity: Gem") || InStr(Clipboard, "Class: Quest") || InStr(Clipboard, "Rarity: Divination Card") ;cont
	|| InStr(Clipboard, "Class: Breachstones") || InStr(Clipboard, "Class: Memories") || InStr(Clipboard, "Class: map fragments") && !InStr(Clipboard, "to the goddess") || InStr(Clipboard, " splinter`r`n") || InStr(Clipboard, "`r`nsplinter of ")
	|| InStr(Clipboard, "Class: Misc Map Items") || InStr(Clipboard, "`r`nblessing of "))
		Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", wiki (exact item)
	Else If InStr(Clipboard, " catalyst`r`n")
		Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", wiki (item class)
	Else If InStr(Clipboard, "to the goddess")
	{
		Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", wiki (exact item)
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", lab info
	}
	Else If InStr(Clipboard, "other oils")
	{
		Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", wiki (item class)
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", anoint table
	}
	Else If InStr(Clipboard, "cluster jewel")
	{
		If !LLK_CheckAdvancedItemInfo()
			Return
		If InStr(Clipboard, "small cluster")
			cluster_type := "small"
		Else cluster_type := InStr(Clipboard, "medium cluster") ? "medium" : "large"
		
		Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", poe.db: all cluster
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", poe.db: %cluster_type% cluster
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", craft of exile
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", wiki (item class)
	}
	Else
	{
		If !LLK_CheckAdvancedItemInfo()
			Return
		If !InStr(Clipboard, "rarity: unique") && !(vars.omnikey.item.itembase = "breach ring")
			Gui, omni_context: Add, Text, % "Section gOmniContextMenuPick", poe.db: modifiers
		If !InStr(Clipboard, "`nUnidentified", 1) && !InStr(Clipboard, "item class: heist") && !(vars.omnikey.item.itembase = "breach ring")
			Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", craft of exile
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", wiki (item class)
	}

	If InStr(Clipboard, "limited to: 1 historic")
	{
		If !LLK_CheckAdvancedItemInfo()
			Return
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", seed-explorer
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", vilsol's calculator
	}

	If InStr(Clipboard, "Sockets: ") && !InStr(Clipboard, "Class: Ring") && !InStr(Clipboard, "Class: Amulet") && !InStr(Clipboard, "Class: Belt")
		Gui, omni_context: Add, Text, % "xs Section gOmniContextMenuPick", chromatics
	/*
	Loop, Parse, % recombinators.classes, `,, `,
	{
		If InStr(item_class, A_Loopfield) && !InStr(Clipboard, "rarity: unique") && !InStr(Clipboard, "`nUnidentified", 1) && !InStr(Clipboard, "rarity: normal")
		{
			If !LLK_CheckAdvancedItemInfo()
				Return
			Gui, omni_context: Add, Text, % "xs Section gRecombinators_add", recombinator
			break
		}
	}
	*/
	MouseGetPos, mouseX, mouseY
	Gui, omni_context: Show, % "Hide x"mouseX " y"mouseY
	WinGetPos, x_context,, w_context
	Gui, omni_context: Show, % "Hide x"mouseX - w_context " y"mouseY
	WinGetPos, x_context,, w_context
	If (x_context < vars.client.x)
		Gui, omni_context: Show, % "NA x"vars.client.x " y"mouseY
	Else Gui, omni_context: Show, % "NA x"mouseX - w_context " y"mouseY
	;WinWaitNotActive, % "ahk_id " vars.hwnd.omni_context
	/*
	While WinActive("ahk_id " vars.hwnd.omni_context)
	{
		KeyWait, ESC, D T0.05
		If !ErrorLevel
			Break
	}
	If WinExist("ahk_id " vars.hwnd.omni_context)
	{
		Gui, omni_context: destroy
		vars.hwnd.Delete("omni_context")
	}
	*/
}

OmniContextMenuPick()
{
	global
	local browser_search, clusterURL

	KeyWait, LButton
	Switch A_GuiControl
	{
		Case "wiki (exact item)":
			Run, % "https://www.poewiki.net/wiki/"StrReplace(vars.omnikey.item.name, " ", "_")
		Case "wiki (item class)":
			Run, % "https://www.poewiki.net/wiki/"OmniURL("wiki")
		Case "lab info":
			Run, % "https://www.poelab.com/"
			If settings.qol.lab && settings.features.browser
			{
				WinWaitNotActive, ahk_group poe_ahk_window,, 2
				ToolTip_Mouse("lab", 1)
			}
			If settings.qol.lab
				Lab("import")
		Case "poe.db: modifiers":
			Run, % "https://poedb.tw/us/"OmniURL("poe.db") "#ModifiersCalc"
			Clipboard := vars.omnikey.item.ilvl
		Case "craft of exile":
			Run, https://www.craftofexile.com/
		Case "anoint table":
			Run, https://blight.raelys.com/
		Case "seed-explorer":
			LegionParse(), LegionGUI()
		Case "vilsol's calculator":
			LegionParse()
			Run, % "https://vilsol.github.io/timeless-jewels/tree?jewel="vars.legion.jewel_number "&conqueror="vars.legion.leader "&seed="vars.legion.seed "&mode=seed"
		Case "chromatics":
			Run, https://siveran.github.io/calc.html
			If settings.features.browser
			{
				WinWaitNotActive, ahk_group poe_ahk_window,, 2
				ToolTip_Mouse("chromatics", 1)
			}
		Case "recombinator":
			SoundBeep
	}
	If InStr(A_GuiControl, "poe.db:") && InStr(A_GuiControl, "cluster")
	{
		If !InStr(A_GuiControl, " all ")
		{
			clusterURL := StrReplace(A_GuiControl, "poe.db: "), clusterURL := StrReplace(clusterURL, " cluster") "_"
			StringUpper, clusterURL, clusterURL, T
		}
		Run, % "https://poedb.tw/us/"clusterURL "Cluster_Jewel#EnchantmentModifiers"
		Clipboard := vars.omnikey.item.ilvl
		If settings.features.browser
		{
			WinWaitNotActive, ahk_group poe_ahk_window,, 2
			ToolTip_Mouse("cluster", 1)
		}
	}
	Gui, omni_context: Hide
}

OmniItemInfo()
{
	local
	global vars, settings, db

	item := vars.omnikey.item, clip := vars.omnikey.clipboard ;short-cut variables

	;store the item's name & base
	Loop, Parse, clip, `n, `r ;store item's class, rarity, name, and base-type
	{
		If InStr(A_LoopField, "---")
			Break
		If InStr(A_LoopField, "Item class:")
			item.class := StrReplace(A_LoopField, "item class: ") ;StrReplace(StrReplace(A_LoopField, "item class: "), " ", "_")
		If InStr(A_LoopField, "Rarity: ")
			item.rarity := StrReplace(A_LoopField, "rarity: ")
		If (A_Index = 3)
			item.name := StrReplace(StrReplace(A_LoopField, "superior "), "synthesised ") ;remove 'superior' and 'synthesised' from the name
		If (A_Index = 4)
			item.itembase := StrReplace(A_LoopField, "synthesised ") ;remove 'synthesised' from the base-type
	}
	item.unid := InStr(clip, "`r`nUnidentified`r`n", 1) ? 1 : 0
	
	If !item.itembase ;if base-type couldn't be directly determined from the first lines, derive it from the item's characteristics
	{
		If item.unid || (item.rarity = "normal") ;unid and normal items = name is also base-type
			item.itembase := item.name
		Else If (item.rarity = "magic") ;magic items = base-type has to be derived from affixes
		{
			item.itembase := item.name
			parse := InStr(clip, "{ Prefix Modifier """)
			prefix := parse ? SubStr(clip, parse + 19) : "", prefix := SubStr(prefix, 1, InStr(prefix, """") - 1)
			parse := InStr(clip, "{ Suffix Modifier """)
			suffix := parse ? SubStr(clip, parse + 19) : "", suffix := SubStr(suffix, 1, InStr(suffix, """") - 1)
			If prefix
				item.itembase := StrReplace(item.itembase, prefix " ")
			If suffix
				item.itembase := StrReplace(item.itembase, " "suffix)
		}
	}
	
	If item.itembase
	{
		item.attributes := ""
		For class, val in db.item_bases
		{
			If InStr(item.class, class)
			{
				For subtype, val1 in val
				{
					If val1.HasKey(item.itembase)
						item.attributes .= InStr(subtype, "armour") ? "_str" : "", item.attributes .= InStr(subtype, "evasion") ? "_dex" : "", item.attributes .= InStr(subtype, "energy") ? "_int" : ""
				}
			}
		}
	}

	If InStr(clip, "`nSockets: ", 1)
		item.str := 0, item.dex := 0, item.int := 0

	Loop, Parse, clip, `n, `r ;store the item's class, rarity, and miscellaneous info
	{	
		If InStr(A_LoopField, "item class: ")
			item.class := StrReplace(A_LoopField, "item class: ")

		If InStr(A_LoopField, "rarity: ")
			item.rarity := StrReplace(A_LoopField, "rarity: ")

		If (SubStr(A_LoopField, 1, 7) = "Level: ")
			item.lvl_req := StrReplace(A_LoopField, " (unmet)"), item.lvl_req := SubStr(item.lvl_req, InStr(item.lvl_req, " ") + 1)

		If InStr(A_LoopField, "Level", 1) && InStr(A_LoopField, " in ") && !InStr(A_LoopField, " Any Job", 1)
			item.heist_job := SubStr(A_LoopField, InStr(A_LoopField, "in ") + 3)

		If InStr(A_LoopField, "Str: ") || InStr(A_LoopField, "Strength: ") ;oddly enough, unidentified items don't use abbreviations for attribute-requirements
			item.str := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), item.str := StrReplace(item.str, " (augmented)"), item.str := StrReplace(item.str, " (unmet)")
		
		If InStr(A_LoopField, "Dex: ") || InStr(A_LoopField, "Dexterity: ")
			item.dex := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), item.dex := StrReplace(item.dex, " (augmented)"), item.dex := StrReplace(item.dex, " (unmet)")
		
		If InStr(A_LoopField, "Int: ") || InStr(A_LoopField, "Intelligence: ")
			item.int := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2), item.int := StrReplace(item.int, " (augmented)"), item.int := StrReplace(item.int, " (unmet)")

		If InStr(A_LoopField, "Item Level: ")
			item.ilvl := SubStr(A_LoopField, InStr(A_LoopField, ":") + 2)

		If InStr(A_LoopField, "Added Small Passive Skills grant: ")
			item.cluster_enchant := SubStr(A_LoopField, 35), item.cluster_enchant := StrReplace(item.cluster_enchant, "+"), item.cluster_enchant := StrReplace(item.cluster_enchant, " (enchant)")

		If InStr(A_LoopField, "Sockets: ")
			item.sockets := StrReplace(A_LoopField, "Sockets: "), item.sockets := StrReplace(item.sockets, " "), item.sockets := StrReplace(item.sockets, "-"), item.sockets := StrLen(item.sockets)

		If InStr(A_LoopField, "Map tier: ")
			item.tier := StrReplace(A_LoopField, "Map tier: ")
	}
}

LLK_CheckAdvancedItemInfo()
{
	If !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier") && !InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "`nRarity: Normal", 1) && !InStr(Clipboard, "`nUnidentified", 1)
	{
		LLK_ToolTip("couldn't copy advanced item-info.`nconfigure the omni-key in the hotkeys menu.", 3,,,, "red")
		Return 0
	}
	Else Return 1
}
