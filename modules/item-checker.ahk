Init_iteminfo()
{
	local
	global vars, settings, db, Json

	If !FileExist("ini\item-checker.ini")
		IniWrite, % "", ini\item-checker.ini, settings
	If !FileExist("ini\item-checker gear.ini")
		IniWrite, % "", ini\item-checker gear.ini, amulet

	lang := settings.general.lang_client
	If !IsObject(db.anoints)
		db.anoints := Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\anoints.json") ? lang : "english") "\anoints.json",, "65001"))
	,	db.essences := Json.Load(LLK_FileRead("data\" (FileExist("data\" lang "\essences.json") ? lang : "english") "\essences.json",, "65001"))

	settings.iteminfo := {}, ini := IniBatchRead("ini\item-checker.ini")
	settings.iteminfo.profile := !Blank(check := ini.settings["current profile"]) ? check : 1
	settings.iteminfo.modrolls := !Blank(check := ini.settings["hide roll-ranges"]) ? check : 1
	settings.iteminfo.trigger := !Blank(check := ini.settings["enable wisdom-scroll trigger"]) ? check : 0
	settings.iteminfo.ilvl := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["enable item-levels"]) ? check : 0
	settings.iteminfo.itembase := !Blank(check := ini.settings["enable base-info"]) ? check : 1
	settings.iteminfo.override := !Blank(check := ini.settings["enable blacklist-override"]) ? check : 0
	settings.iteminfo.compare := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["enable gear-tracking"]) ? check : 0

	settings.iteminfo.rules := {}
	settings.iteminfo.rules.res_weapons := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["weapon res override"]) ? check : 0
	settings.iteminfo.rules.res := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["res override"]) ? check : 0
	settings.iteminfo.rules.spells := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["spells override"]) ? check : 0
	settings.iteminfo.rules.attacks := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["attacks override"]) ? check : 0
	settings.iteminfo.rules.hitgain := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["lifemana gain override"]) ? check : 0
	settings.iteminfo.rules.crit := (settings.general.lang_client != "english") ? 0 : !Blank(check := ini.settings["crit override"]) ? check : 0

	settings.iteminfo.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
	LLK_FontDimensions(settings.iteminfo.fSize, height, width), settings.iteminfo.fWidth := width, settings.iteminfo.fHeight := height

	settings.iteminfo.dColors_tier := ["00bb00", "008000", "ffff00", "ff8c00", "ff4040", "aa0000", "00eeee"]
	settings.iteminfo.dColors_tier[0] := "3399ff"
	settings.iteminfo.colors_tier := [], settings.iteminfo.colors_ilvl := []
	settings.iteminfo.dColors_ilvl := ["ffffff", "00bb00", "008000", "ffff00", "ff8c00", "ff4040", "aa0000", "ff00ff"]
	settings.iteminfo.ilevels := ["80", "70", "60", "50", "40", "30", "20", "10"]

	Loop 8 ;load custom colors
	{
		settings.iteminfo.colors_tier[A_Index - 1] := !Blank(check := ini.UI[(A_Index = 8) ? "fractured" : "tier " A_Index - 1]) ? check : settings.iteminfo.dColors_tier[A_Index - 1]
		settings.iteminfo.colors_ilvl[A_Index] := !Blank(check := ini.UI["ilvl tier " A_Index]) ? check : settings.iteminfo.dColors_ilvl[A_Index]
	}

	If !IsObject(vars.iteminfo) ;only do this when the function is called for the very first time (i.e. at startup) ;this function is used whenever major features are toggled on/off
	{
		vars.iteminfo := {"UI": {}, "compare": {}}
		vars.iteminfo.compare.slots := {"mainhand": {}, "offhand": {}, "helmet": {}, "body": {}, "amulet": {}, "ring1": {}, "ring2": {}, "belt": {}, "gloves": {}, "boots": {}}
		vars.hwnd.iteminfo := {}, ini2 := IniBatchRead("ini\item-checker gear.ini")

		For key in vars.iteminfo.compare.slots ;load gear from ini
			vars.iteminfo.compare.slots[key].equipped := !Blank(check := ini2[key]) ? check.Clone() : "empty"
	}

	vars.iteminfo.highlight := {"global": {}}, vars.iteminfo.blacklist := {"global": {}}

	For key, val in ini["highlighting " settings.iteminfo.profile]
	{
		If !InStr(key, "highlight") && !InStr(key, "blacklist")
		{
			IniDelete, ini\item-checker.ini, % "highlighting " settings.iteminfo.profile, % key ;delete buggy key in ini-file
			continue
		}
		category := InStr(key, "highlight") ? "highlight" : "blacklist"
		class := InStr(key, " ") ? SubStr(key, InStr(key, " ") + 1) : "global"
		If !IsObject(vars.iteminfo[category][class])
			vars.iteminfo[category][class] := {}
		Loop, Parse, val, |
		{
			If !A_LoopField
				continue
			vars.iteminfo[category][class][A_LoopField] := 1
		}
	}

	vars.iteminfo.inverted_mods := {}
	Loop, Parse, % ini["inverted mods"].invert, |, % A_Space
	{
		If Blank(A_LoopField)
			Continue
		vars.iteminfo.inverted_mods[A_LoopField] := 1
	}

	If settings.iteminfo.compare
		settings.iteminfo.itembase := 0 ;, settings.iteminfo.dps := 0
	Else Return

	vars.iteminfo.compare.xBase := vars.client.h* (443/720) - 1 ;x-coordinate in client that approximates the left edge of the inventory
	vars.iteminfo.compare.dButton := vars.client.h*(1/18)/3, vars.hwnd.iteminfo_comparison := {}
	coords := {"mainhand": [1/16, 1/9, 5/48, 1/5], "offhand": [107/240, 1/9, 5/48, 1/5], "helmet": [23/90, 7/72, 5/48, 5/48], "body": [23/90, 5/24, 5/48, 11/72], "amulet": [3/8, 7/36, 1/18, 1/18]
	, "ring1": [11/60, 23/90, 1/18, 1/18], "ring2": [3/8, 23/90, 1/18, 1/18], "belt": [23/90, 35/96, 5/48, 1/18], "gloves": [13/96, 91/288, 5/48, 5/48], "boots": [3/8, 91/288, 5/48, 5/48]}
	For key in vars.iteminfo.compare.slots ;load/update gear-update buttons used for tracking equipped items
	{
		vars.iteminfo.compare.slots[key].x := vars.client.h * coords[key].1, vars.iteminfo.compare.slots[key].y := vars.client.h * coords[key].2
		vars.iteminfo.compare.slots[key].w := vars.client.h * coords[key].3, vars.iteminfo.compare.slots[key].h := vars.client.h * coords[key].4

		Gui, iteminfo_button_%key%: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption HWNDhwnd
		Gui, iteminfo_button_%key%: Margin, 0, 0
		If !vars.pics.iteminfo.refresh
			vars.pics.iteminfo.refresh := LLK_ImageCache("img\GUI\refresh.png")
		Gui, iteminfo_button_%key%: Add, Picture, % "BackgroundTrans w"vars.iteminfo.compare.dButton " h-1", % "HBitmap:*" vars.pics.iteminfo.refresh
		Gui, iteminfo_button_%key%: Show, % "Hide x"vars.client.x + vars.client.w - vars.iteminfo.compare.xBase + vars.iteminfo.compare.slots[key].x " y"vars.client.y + vars.iteminfo.compare.slots[key].y
		vars.hwnd.iteminfo_comparison[key] := hwnd
		LLK_Overlay(hwnd, "hide",, "iteminfo_button_" key)

		;the box drawn by x1, x2, y1, and y2 is the area of a given inventory gear-slot and serves as a reference-point for clicks
		vars.iteminfo.compare.slots[key].x1 := vars.client.x + vars.client.w - vars.iteminfo.compare.xBase + vars.iteminfo.compare.slots[key].x
		vars.iteminfo.compare.slots[key].x2 := vars.client.x + vars.client.w - 1 - vars.iteminfo.compare.xBase + vars.iteminfo.compare.slots[key].x + vars.iteminfo.compare.slots[key].w
		vars.iteminfo.compare.slots[key].y1 := vars.client.y + vars.iteminfo.compare.slots[key].y
		vars.iteminfo.compare.slots[key].y2 := vars.client.y + vars.iteminfo.compare.slots[key].y - 1 + vars.iteminfo.compare.slots[key].h
	}
}

Iteminfo(refresh := 0) ; refresh: 1 to refresh it normally, 2 for clipboard parsing only (omni-key)
{
	local
	global vars, settings, db

	Clipboard := StrReplace(Clipboard, LangTrans("items_unequippable") "`r`n--------`r`n") ;remove "you cannot use this item" line (removing it also enables craft of exile for such items)
	UI := vars.iteminfo.UI ;short-cut variable
	If !UI.wSegment ;width of a 'segment' (tooltip is made out of x segments) ;examples: dps-cells represent this width, the (un)desired rectangle represents a quarter of this width, icons one half
	{
		Gui, itemchecker_width: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border ;create a dummy GUI and get the height of texts with the current font-size
		Gui, itemchecker_width: Margin, 0, 0
		Gui, itemchecker_width: Color, Black
		Gui, itemchecker_width: Font, % "cWhite s"settings.iteminfo.fSize, % vars.system.font
		Gui, itemchecker_width: Add, Text, % "Border HWNDhwnd", % "77777"
		GuiControlGet, text_, Pos, % hwnd

		While Mod(text_h, 4) ;increase the height until it's divisible by 4
			text_h += 1
		UI.wSegment := text_h*2 ;one width-unit is height*2
		UI.hSegment := text_h ;it's important to manually apply this height to text-panels so that half-width cells are square (e.g. cells with icons)
		Gui, itemchecker_width: Destroy
	}
	UI.segments := 10 ;number of segments the tooltip is made of, i.e. the tooltip is 10 standardized widths wide
	UI.hDivider := UI.hSegment//9 ;thickness of the dividing lines between implicits, prefixes, suffixes, etc.

	If (refresh = 1) ;refresh tooltip after changing settings in the menu, i.e. use the previously omni-clicked item's info and redraw the tooltip with new settings
	{
		If !vars.iteminfo.clipboard
			Return

		If WinExist("ahk_id " vars.hwnd.iteminfo.main)
		{
			WinGetPos, xPos, yPos,,, % "ahk_id " vars.hwnd.iteminfo.main
			UI.xPos := xPos, UI.yPos := yPos
		}
		Else If InStr(A_Gui, "settings_menu")
			UI.xPos := vars.general.xMouse, UI.yPos := vars.general.yMouse + vars.monitor.h/100
	}
	Else UI.xPos := "", UI.yPos := "", vars[(refresh = 2) ? "omnikey" : "iteminfo"].clipboard := StrReplace(StrReplace(StrReplace(Clipboard, "maelström", "maelstrom"), " — " LangTrans("items_unscalable")), "&", "&&"), vars[(refresh = 2) ? "omnikey" : "iteminfo"].item := {}

	clip := vars[(refresh = 2) ? "omnikey" : "iteminfo"].clipboard, item := vars[(refresh = 2) ? "omnikey" : "iteminfo"].item ;short-cut variables
	Loop, % (refresh = 2 && settings.general.lang_client != "english") ? 2 : 1
	{
		If (A_Index = 2)
		{
			outer := 2, clipboard_copy := Clipboard, Clipboard := ""
			SendInput, ^{c}
			ClipWait, 0.1
			If InStr(Clipboard, "{")
				Break
		}
		Loop, Parse, % (refresh = 2 && outer = 2) ? Clipboard : clip, `n, `r ;store item's class, rarity, name, and base-type
		{
			If (refresh = 2 && outer = 2)
			{
				If (A_Index = 3)
					item.name_copy := A_LoopField
				If (A_Index = 4 && !InStr(A_LoopField, "---"))
					item.itembase_copy := A_LoopField
				Continue
			}
			If InStr(A_LoopField, "---")
				Break
			If InStr(A_LoopField, LangTrans("items_class"), 1)
				item.class_copy := item.class := StrReplace(A_LoopField, LangTrans("items_class") " ") ;StrReplace(StrReplace(A_LoopField, "item class: "), " ", "_")
			If InStr(A_LoopField, LangTrans("items_rarity"), 1)
				item.rarity := StrReplace(A_LoopField, LangTrans("items_rarity") " ")
			If (A_Index = 3)
				item.name := StrReplace(StrReplace(A_LoopField, "superior "), "synthesised ") ;remove 'superior' and 'synthesised' from the name
			If (A_Index = 4)
				item.itembase := StrReplace(A_LoopField, "synthesised ") ;remove 'synthesised' from the base-type
		}
	}
	If (settings.general.lang_client = "english")
		item.name_copy := item.name, item.itembase_copy := item.itembase
	item.unid := InStr(clip, "`r`n" LangTrans("items_unidentified") "`r`n") ? 1 : 0, Clipboard := clipboard_copy ? clipboard_copy : Clipboard
	Loop, Parse, % "name,itembase", `,
	{
		While (SubStr(item[A_LoopField], 1, 1) = " ")
			item[A_LoopField] := SubStr(item[A_LoopField], 2)
		While ((SubStr(item[A_LoopField], 0) = " "))
			item[A_LoopField] := SubStr(item[A_LoopField], 1, -1)
	}

	If InStr(clip, LangTrans("items_quality") . " +")
		item.quality := SubStr(clip, InStr(clip, LangTrans("items_quality") . " +") + StrLen(LangTrans("items_quality") . " +")), item.quality := SubStr(item.quality, 1, InStr(item.quality, "%") - 1)

	If !item.itembase ;if base-type couldn't be directly determined from the first lines, derive it from the item's characteristics or database
	{
		If item.unid || (item.rarity = LangTrans("items_normal")) ;unid and normal items = name is also base-type
			item.itembase := item.name
		Else If (settings.general.lang_client = "english") && (item.rarity = "magic")
		{
			Loop, Parse, % vars[(refresh = 2) ? "omnikey" : "iteminfo"].clipboard, `n, `r
			{
				If !LLK_PatternMatch(A_LoopField, "{ ", ["Master Crafted Prefix ", "Prefix ", "Master Crafted Suffix ", "Suffix "])
					Continue
				If InStr(A_LoopField, "Prefix")
					prefix := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), prefix := SubStr(prefix, 1, InStr(prefix, """") - 1) . " "
				Else If InStr(A_LoopField, "Suffix")
					suffix := SubStr(A_LoopField, InStr(A_LoopField, """") + 1), suffix := " " . SubStr(suffix, 1, InStr(suffix, """") - 1)
			}
			item.itembase := StrReplace(StrReplace(item.name, prefix), suffix)
		}
		Else
			For key in db.item_bases["_bases"]
				If InStr(item.name, " " key, 1) || InStr(item.name, key " ", 1)
					item.itembase := (StrLen(key) > StrLen(item.itembase)) ? key : item.itembase
	}

	If (settings.general.lang_client != "english") && item.itembase ;try to get the English item-class on non-English clients (via base-item database)
		item.class := db.item_bases._classes[db.item_bases._bases[item.itembase]]

	For key, val in vars.lang ;get the English item-class for certain items that are not included in the database, e.g. heist items (via lang_XYZ)
		If LLK_PatternMatch(key, "items_", ["heist"]) && !Blank(LLK_HasVal(val, item.class_copy))
			item.class := LLK_StringCase(StrReplace(key, "items_"),, 1)

	If InStr(item.name, "cluster jewel") || InStr(item.itembase, "cluster jewel")
		item.class := "Cluster Jewels" ;override cluster jewels' item-class

	If (refresh = 2)
		Return

	If !db.item_bases.HasKey(item.class) || (item.itembase = "Timeless Jewel") ;|| (item.name = "Impossible Escape")
	{
		LLK_ToolTip(LangTrans("ms_item-info") ":`n" LangTrans("iteminfo_unsupported"), 2,,,, "red"), LLK_Overlay(vars.hwnd.iteminfo.main, "destroy")
		Return
	}

	Iteminfo2_stats() ;calculate data related to base-stats (defenses)
	Iteminfo3_mods() ;parse item's mods
	Iteminfo4_GUI() ;use parsed data to build the tooltip
}

Iteminfo2_stats()
{
	local
	global vars, settings, db

	clip := vars.iteminfo.clipboard, item := vars.iteminfo.item ;short-cut variables
	vars.iteminfo.item.defenses := {} ;store item's defensive stats for item-comparison feature
	defenses := vars.iteminfo.item.defenses ;short-cut variable
	Loop, Parse, clip, `n, `r ;get the raw defense values and store them
	{
		If InStr(A_LoopField, LangTrans("items_armour"))
			defenses.armor := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ": ") + 2), " (augmented)")
		If InStr(A_LoopField, LangTrans("items_evasion"))
			defenses.evasion := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ": ") + 2), " (augmented)")
		If InStr(A_LoopField, LangTrans("items_energy"))
			defenses.energy := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ": ") + 2), " (augmented)")
		If InStr(A_LoopField, LangTrans("items_ward"))
			defenses.ward := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ": ") + 2), " (augmented)")
		If InStr(A_LoopField, LangTrans("items_requirements"))
			break
	}

	If InStr(clip, LangTrans("items_aps")) ;get the broad item-type (this influences which info will be included in the tooltip, e.g. dps, defense-comparisons, anoints, etc.)
		item.type := "attack"
	Else If defenses.armor || defenses.evasion || defenses.energy || defenses.ward
		item.type := "defense"
	Else If InStr("rings,belts,amulets,", item.class) || InStr(item.class, "jewels")
		item.type := "jewelry"
	Else item.type := ""

	item.ilvl_max := "86", item.stats := {} ;list of stats that will later be listed in the optional base-info area of the tooltip

	For class, class_val in db.item_bases ;parse through the item-databases to get relevant information
	{
		If !item.itembase && !InStr(item.class, "heist") || !(settings.iteminfo.itembase || settings.iteminfo.ilvl)
			Break
		If (item.class = class)
		{
			item.ilvl_max := class_val.HasKey("_ilvl_max") ? class_val["_ilvl_max"] : item.ilvl_max ;get class-specific max ilvl, e.g. gloves = 85
			If (item.itembase = "two-toned boots") ;get the correct variation of two-toned boots
				Loop, Parse, % "armor,evasion,energy", `,
					If defenses[A_LoopField]
						variation .= (variation ? "/" : "") . StrReplace(A_LoopField, "armor", "armour")

			For subtype, subtype_val in class_val ;parse through the sub-types within the class, e.g. armour/evasion
			{
				If (item.itembase = "two-toned boots") && (subtype != variation)
					Continue

				If (subtype = item.itembase) || subtype_val.HasKey(item.itembase)
				{
					item.ilvl_max := subtype_val.HasKey("_ilvl_max") ? subtype_val["_ilvl_max"] : item.ilvl_max ;get sub-type-specific max ilvl, e.g. cluster jewels = 84
					If (item.type = "defense") ;get defense-stats (min/max values, combined, block)
					{
						item.tags := subtype_val[item.itembase]._tags.Clone()
						For defense_stat, defense_value in subtype_val[item.itembase]
						{
							If InStr(defense_stat, "tag")
								Continue
							If (defense_stat = "block")
							{
								block := 1
								continue
							}
							base_min_%defense_stat% := SubStr(defense_value, 1, InStr(defense_value, "-") - 1)
							base_best_%defense_stat% := SubStr(defense_value, InStr(defense_value, "-") + 1)
							base_best_combined += SubStr(defense_value, InStr(defense_value, "-") + 1)
							class_best_%defense_stat% := class_val[defense_stat]._best
							class_best_combined := subtype_val._best
							item.stats[defense_stat] := {"base_min": base_min_%defense_stat%, "base_best": base_best_%defense_stat%, "class_best": class_best_%defense_stat%}
						}
						If (item.stats.Count() = 2) ;if item has two types of defenses, also include combined stats (this will not be done for triple-defense items)
							item.stats.combined := {"base_best": base_best_combined, "class_best": class_best_combined}
						If block ;include block stats for shields
						{
							base_best_block := subtype_val[item.itembase].block
							class_best_block := class_val._best
							item_block_rel := Format("{:0.0f}", base_best_block/class_best_block*100)
							item.stats.block := {"base_best": base_best_block, "class_best": class_best_block, "relative": item_block_rel}
						}
					}
					Else item.tags := subtype_val._tags.Clone()

					If (item.type = "attack") ;get offense-stats (avg. flat phys, speed, crit)
					{
						For attack_stat, attack_value in subtype_val
						{
							If InStr(attack_stat, "_")
								Continue
							base_best_%attack_stat% := attack_value
							class_best_%attack_stat% := class_val._best[attack_stat]
							item_%attack_stat%_rel := Format("{:0.0f}", base_best_%attack_stat%/class_best_%attack_stat%*100)
							item.stats[attack_stat] := {"base_best": base_best_%attack_stat%, "class_best": class_best_%attack_stat%, "relative": item_%attack_stat%_rel}
						}
					}

					If (item.type = "defense") ;pick one base defense-stat to calculate the raw base-percentile of the item
					{
						natural_defense_stat := item.stats.HasKey("armour") ? "armour" : item.stats.HasKey("evasion") ? "evasion" : item.stats.HasKey("energy") ? "energy" : "ward"
						defense_flat := 0
					}
					Break
				}
			}
		}
	}
	item_quality := defense_increased := 0

	Loop, parse, clip, `n, `r ;parse quality and defense-stats
	{
		If InStr(A_LoopField, LangTrans("items_quality"))
			item_quality := StrReplace(SubStr(A_LoopField, InStr(A_LoopField, ":") + 3), " (augmented)"), item_quality := StrReplace(item_quality, "%")
		If InStr(A_LoopField, LangTrans("items_" natural_defense_stat))
		{
			stat_value := StrReplace(A_LoopField, " (augmented)"), stat_value := SubStr(stat_value, InStr(stat_value, ":") + 2) ;stat-value as is (may include increases and flat added)
			stat_augmented := InStr(A_LoopField, " (augmented)") ? 1 : 0 ;is value altered by quality or modifiers?
		}
	}

	If (item.type = "defense") ;calculate the value of the base-percentile roll (the one that's re-rolled with sacred orbs)
	{
		If stat_augmented
		{
			If !InStr(clip, LangTrans("mods_qual_enchant")) ;check if quality actually affects defense-stat
				stat_value /= (1 + item_quality/100)
			Loop, Parse, % SubStr(clip, InStr(clip, LangTrans("items_ilevel"))), `n, `r ;parse flat and % increases
			{
				number := "", text := ""
				Loop, Parse, % IteminfoModRemoveRange(A_LoopField)
					number .= LLK_IsType(A_LoopField, "number") ? A_LoopField : "", text .= LLK_IsType(A_LoopField, "number") || InStr("()", A_LoopField) ? "" : A_LoopField
				While (SubStr(text, 1, 1) = " ")
					text := SubStr(text, 2)
				While (SubStr(text, 0) = " ")
					text := SubStr(text, 1, -1)

				For key, val in vars.lang
				{
					If !InStr(key, "mods_" natural_defense_stat)
						Continue
					string := ""
					For index, val1 in val
						string .= val1
					If (string = text)
					{
						If InStr(key, "_flat")
							defense_flat += number
						Else If InStr(key, "_%")
							defense_increased += number
					}
				}
			}
			defense_increased := Format("{:0.2f}", 1 + defense_increased/100) ;factor by which defense-stat is increased, e.g. 1.2x
			stat_value := Format("{:0.0f}", stat_value / defense_increased) ;divide stat-value by factor to get value without % increases
			stat_value -= defense_flat ;subtract flat increases to get base value
		}
		defense_roll := stat_value/base_best_%natural_defense_stat%*100 ;how close is the given base-percentile to the perfect roll (e.g. 69%), in terms of absolute values

		For key, val in item.stats
		{
			If (key = "block") || (key = "combined")
				continue
			item_%key% := base_best_%key%*defense_roll/100
			item_%key%_rel := val.relative := Format("{:0.0f}", item_%key%/class_best_%key%*100) ;how close is the given stat-keyue to the best-in-class?
			item_%key% := Format("{:0.0f}", base_best_%key%*defense_roll/100)
			If (item.stats.Count() >= 2)
			{
				item_combined += item_%key% ;combined keyue of multiple stats
				item_combined_rel := item.stats.combined.relative := Format("{:0.0f}", item_combined/class_best_combined*100) ;how close is the combined keyue to the combined best-in-class?
			}
		}
		If (base_min_%natural_defense_stat% = base_best_%natural_defense_stat%)
			item.base_percent := 100
		Else item.base_percent := Format("{:0.0f}", (stat_value - base_min_%natural_defense_stat%)/(base_best_%natural_defense_stat% - base_min_%natural_defense_stat%)*100) ;base-percentile as calculated on trade
	}

	If (item.quality >= 25)
		vars.iteminfo.UI.cDivider := "ffd700" ;color of the dividing lines
	Else vars.iteminfo.UI.cDivider := InStr(clip, "`r`n" LangTrans("items_corrupted") "`r`n", 1) ? "dc0000" : InStr(clip, "`r`n" LangTrans("items_mirrored") "`r`n", 1) ? "00cccc" : "e0e0e0"

	If InStr(clip, LangTrans("items_aps")) ;calculate dps values if item is a weapon
	{
		phys_dmg := pdps := ele_dmg := ele_dmg1 := ele_dmg2 := ele_dmg3 := edps0 := chaos_dmg := cdps := speed := 0
		Loop, Parse, clip, `n, `r
		{
			If InStr(A_LoopField, LangTrans("items_phys_dmg"))
				phys_dmg := SubStr(StrReplace(A_LoopField, " (augmented)"), InStr(A_LoopField, ":") + 2)
			If InStr(A_LoopField, LangTrans("items_ele_dmg"))
			{
				ele_dmg := SubStr(StrReplace(A_LoopField, " (augmented)"), InStr(A_LoopField, ":") + 2)
				Loop, Parse, ele_dmg, `,, % A_Space
					ele_dmg%A_Index% := A_LoopField
			}
			If InStr(A_LoopField, LangTrans("items_chaos_dmg"))
				chaos_dmg := SubStr(StrReplace(A_LoopField, " (augmented)"), InStr(A_LoopField, ":") + 2)
			If InStr(A_LoopField, LangTrans("items_aps"))
			{
				speed := SubStr(StrReplace(A_LoopField, " (augmented)"), InStr(A_LoopField, ":") + 2)
				break
			}
		}
		If phys_dmg
		{
			Loop, Parse, phys_dmg, % "-"
				phys%A_Index% := A_LoopField
			pdps := Format("{:0.2f}", ((phys1+phys2)/2)*speed)
		}
		If ele_dmg
		{
			edps2 := 0
			edps3 := 0
			Loop, Parse, ele_dmg1, % "-"
				ele_dmg1_%A_Index% := A_LoopField
			edps1 := ((ele_dmg1_1+ele_dmg1_2)/2)*speed
			If ele_dmg2
			{
				Loop, Parse, ele_dmg2, % "-"
					ele_dmg2_%A_Index% := A_LoopField
				edps2 := ((ele_dmg2_1+ele_dmg2_2)/2)*speed
			}
			If ele_dmg3
			{
				Loop, Parse, ele_dmg3, % "-"
					ele_dmg3_%A_Index% := A_LoopField
				edps3 := ((ele_dmg3_1+ele_dmg3_2)/2)*speed
			}
			edps0 := Format("{:0.2f}", edps1 + edps2 + edps3)
		}
		If chaos_dmg
		{
			Loop, Parse, chaos_dmg, % "-"
				chaos_dmg%A_Index% := A_LoopField
			cdps := Format("{:0.2f}", ((chaos_dmg1+chaos_dmg2)/2)*speed)
		}
		item.dps := {"total": Format("{:0.2f}", pdps + edps0 + cdps), "phys": pdps, "ele": edps0, "chaos": cdps, "speed": speed}
		item.dps0 := {"cdps": cdps, "pdps": pdps, "edps": edps0, "speed": speed, "dps": pdps + edps0 + cdps} ;secondary object for dps-comparison that uses a very rigid format (ini-format)
	}
}

Iteminfo3_mods()
{
	local
	global vars, settings, db

	clip := vars.iteminfo.clipboard, item := vars.iteminfo.item ;short-cut variables
	clip2 := SubStr(clip, InStr(clip, LangTrans("items_ilevel"))) ;lower part of the in-game item-info
	item.ilvl := SubStr(clip2, 1, InStr(clip2, "`r`n") - 1), item.ilvl := SubStr(item.ilvl, InStr(item.ilvl, ":") + 2)
	clip2 := SubStr(clip2, InStr(clip2, "--`r`n") + 4)
	item.implicits := [], item.implicits2 := [], item.anoint := ""
	clip2 := LLK_StringCase(StrReplace(clip2, "`r`n", "|")) ;group lines that belong to a mod together
	itemcheck_parse := "(-.)|[]%" ;characters that indicate numerical values/strings
	loop := 0 ;count affixes

	If item.itembase && InStr("crimson jewel, viridian jewel, cobalt jewel", item.itembase)
		item.class := "base jewels"

	Loop, Parse, clip2, | ;remove unnecessary item-info: implicits, crafted mods, etc.
	{
		If (A_Index = 1)
			clip2 := ""

		If LangMatch(SubStr(A_LoopField, 1, InStr(A_LoopField, "`n") - 1), vars.lang.mods_cluster_enchant, 0) ;is the item a cluster jewel?
		{
			target := InStr(item.name, "cluster jewel") ? "name" : "itembase"
			If InStr(item[target], "small")
				item.cluster := {"type": "small", "min": 2, "max": -3, "optimal": -2} ;store cluster-related data
			Else item.cluster := {"type": InStr(item[target], "medium") ? "medium" : "large"}, item.cluster.min := InStr(item[target], "medium") ? 4 : 8, item.cluster.max := InStr(item[target], "medium") ? -6 : -12, item.cluster.optimal := InStr(item[target], "medium") ? -5 : -8
			Loop, Parse, A_LoopField
				If LLK_IsType(A_LoopField, "number")
					item.cluster.passives .= (!item.cluster.passives ? "-" : "") A_LoopField ;store passive-count
		}

		If item.cluster.type && InStr(A_LoopField, LangTrans("mods_cluster_passive")) ;parse cluster enchant
		{
			Loop, Parse, A_LoopField, `n, `n
			{
				If (SubStr(A_LoopField, 1, 1) = "(") ;skip lines containing explanations
					Continue
				cluster_enchant .= (cluster_enchant = "") ? A_LoopField : "`n" A_LoopField, cluster_enchant := StrReplace(StrReplace(cluster_enchant, " (enchant)"), LangTrans("mods_cluster_passive") " ")
			}
			item.cluster.enchant := cluster_enchant
		}

		If InStr(A_LoopField, " (enchant)") && LangMatch(A_LoopField, vars.lang.mods_blight_enchant, 0) ;parse blight-anointments (amulet)
		{
			item.implicits.Push(StrReplace(A_LoopField, " (enchant)"))
			If !settings.iteminfo.compare ;if item-comparison is turned off (comparison and base-info are mutually exclusive)
				item.anoint .= (Blank(item.anoint) ? "" : ",") db.anoints.amulets[StrReplace(LangTrim(A_LoopField, vars.lang.mods_blight_enchant), " (enchant)")]
		}

		If db.anoints.rings[StrReplace(A_LoopField, " (enchant)")]
		{
			item.implicits.Push(StrReplace(A_LoopField, " (enchant)"))
			If !settings.iteminfo.compare
				item.anoint := db.anoints.rings[StrReplace(A_LoopField, " (enchant)")]
		}

		If (InStr(A_LoopField, LangTrans("items_implicit_vaal")) || InStr(A_LoopField, LangTrans("items_implicit_eater")) || InStr(A_LoopField, LangTrans("items_implicit_exarch"))
		|| ((InStr(clip, "`r`nSynthesised ", 1) || InStr(item.itembase, " Talisman", 1) && (item.rarity != LangTrans("items_unique"))) && InStr(A_LoopField, LangTrans("items_implicit")))) && !settings.iteminfo.compare
			item.implicits.Push(StrReplace(A_LoopField, " (implicit)")) ;store implicits: eater, exarch, corruption, synthesis, rare talisman

		If InStr(A_LoopField, LangTrans("items_implicit")) && settings.iteminfo.compare
			item.implicits.Push(StrReplace(A_LoopField, " (implicit)")) ;store all implicits if league-start mode is enabled

		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, LangTrans("items_implicit")) || InStr(A_LoopField, "{ Allocated Crucible") ;don't include implicits or crucible info
			Continue
		clip2 .= A_LoopField "`n" ;rebuild the copied item-info without unnecessary lines
	}

	For key, val in item.implicits ;create list of implicits relevant for the item-comparison feature, and store it in a separate array
	{
		If InStr(val, LangTrans("items_implicit_vaal")) || InStr(val, LangTrans("items_implicit_eater")) || InStr(val, LangTrans("items_implicit_exarch"))
			continue
		item.implicits2.Push(val)
	}

	For key, val in item.implicits2 ;remove unnecessary implicit text, and trim certain phrases for space-efficiency
	{
		If (A_Index = 1)
			item.implicits3 := []
		Loop, Parse, val, `n
		{
			If (SubStr(A_LoopField, 1, 1) = "{")
				continue

			parse := (SubStr(A_LoopField, 1, 1) = " ") ? SubStr(A_LoopField, 2) : A_LoopField
			While InStr(parse, "  ")
				parse := StrReplace(parse, "  ", " ")
			parse := StrReplace(parse, "`n ", "`n"), parse := LangTrim(parse, vars.lang.mods_blight_enchant)
			item.implicits3.Push(parse)
		}
	}
	item.implicits2 := item.implicits3.Clone(), item.implicits3 := ""

	If item.cluster.enchant ;parse cluster info, and trim certain phrases for space-efficiency
	{
		Loop, Parse, % item.cluster.enchant
		{
			If (A_Index = 1)
				item.cluster.enchant := ""
			If IsNumber(A_LoopField) || InStr("+%", A_LoopField)
				continue
			item.cluster.enchant .= A_LoopField
		}
		While InStr(item.cluster.enchant, "  ")
			item.cluster.enchant := StrReplace(item.cluster.enchant, "  ", " ")
		item.cluster.enchant := StrReplace(item.cluster.enchant, "`n ", "`n"), item.cluster.enchant := LangTrim(item.cluster.enchant, vars.lang.mods_cluster_remove, "`n")
		For index, val in vars.lang.mods_cluster_replace
			If InStr(item.cluster.enchant, val)
			{
				item.cluster.enchant := LLK_StringCase(StrReplace(item.cluster.enchant, val, vars.lang.mods_cluster_replace[index + 1]))
				Break
			}
		If LangMatch(item.cluster.enchant, vars.lang.mods_cluster_replace_res, 0)
			item.cluster.enchant := StrReplace(item.cluster.enchant, vars.lang.mods_cluster_replace_res.1)
		While (SubStr(item.cluster.enchant, 1, 1) = " ")
			item.cluster.enchant := SubStr(item.cluster.enchant, 2)
	}

	Loop, Parse, clip2, `n ;remove tooltips from item-info
	{
		If (A_Index = 1)
			clip2 := ""
		If (SubStr(A_LoopField, 1, 1) = "(")
			continue
		clip2 .= A_LoopField "`n"
	}

	While (SubStr(clip2, 0) = "`n") ;remove white-space at the end
		clip2 := SubStr(clip2, 1, -1)

	If settings.iteminfo.compare ;parse the item's info if league-start mode is enabled
	{
		For slot, val in vars.iteminfo.compare.slots ;determine which item-slot the given item belongs in
		{
			If (slot = "mainhand" || slot = "offhand") && InStr(clip, "attacks per second: ")
				item_slot := InStr(vars.iteminfo.compare.slots.offhand.equipped, "speed=") ? "mainhand,offhand" : "mainhand"
			If (slot = "offhand") && (InStr(clip, "item class: shield") || InStr(clip, "item class: quiver"))
				item_slot := "offhand"
			If InStr(clip, InStr(slot, "ring") ? "item class: " SubStr(slot, 1, -1) : "item class: " slot)
				item_slot := InStr(slot, "ring") ? "ring1,ring2" : slot
		}
		;create a list of summarized stats for the given item
		offenses := "dps=" item.dps.total "`npdps=" item.dps.phys "`nedps=" item.dps.ele "`ncdps=" item.dps.chaos "`nspeed=" item.dps.speed "`n"
		For key, val in item.defenses
			defenses .= key "="val "`n"
		For key, val in item.implicits2
			implicits .= val "`n"
		;this variable stores a list with dps and defense stats which has a fixed structure for easy comparison
		parse_comparison := (item.type != "attack") ? IteminfoCompare(implicits defenses StrReplace(StrReplace(clip2, " (fractured"), " (crafted)"), item.type) : IteminfoCompare(offenses StrReplace(clip2, " (fractured)"))

		compare := vars.iteminfo.compare ;short-cut variable
		compare.items := [], compare.items.0 := {}, compare.items.1 := {} ;store up to 3 items here (index 0 = looted item, index 1 = inventory-slot 1, index 2 = inventory-slot 2)
		If InStr(item_slot, ",")
			compare.items.2 := {}

		Loop, Parse, parse_comparison, `n ;parse the list, read the individual stats, and declare variables
		{
			parse := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
			%parse% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1) ;declare variable, e.g. to_maximum_life := 100
			compare.items.0[parse] := %parse%
			%parse%_1 := 0 ;set variable of first comparison-slot to 0, e.g. to_maximum_life_1 := 0
			compare.items.1[parse] := 0
			If InStr(item_slot, ",")
				%parse%_2 := 0, compare.items.2[parse] := 0 ;set variable of potential second comparison-slot to 0
			stats_item .= parse "," ;list stats that are present on the item
		}
		compare.items.0.stats := stats_item, compare.items.slots := item_slot

		Loop, Parse, item_slot, `, ;read individual stats for all currently equipped items in the target slots
		{
			loop := A_Index
			For key, val in vars.iteminfo.compare.slots[A_LoopField].equipped
			{
				%key%_%loop% := val ;declare variable, e.g. to_maximum_life_1 := 100 ("_n" denoting the n-th currently equipped item, e.g. ring1)
				compare.items[loop][key] := %key%_%loop%
				If (%key% = "")
				{
					%key% := 0  ;if the looted item doesn't have this stat, set its variable to 0
					compare.items.0[key] := 0
				}
				stats_equipped_%loop% .= key "," ;list stats that are present on the item
			}
			compare.items[loop].stats := stats_equipped_%loop%
		}

		compare.losses := [] ;store comparisons between item and equipped items
		Loop, % loop ;loop n times (n = number of target slots)
		{
			loop1 := A_Index
			losses_%A_Index% := {} ;store stat losses/gains for given slot here
			Loop, Parse, stats_equipped_%A_Index%, `, ;parse the stats on item in slot n
			{
				If (A_LoopField = "")
					Continue
				If (%A_LoopField%_%loop1% - %A_LoopField% != "") ;store the difference in stat-value in an array
					losses_%loop1%[A_LoopField] := (%A_LoopField%_%loop1% - %A_LoopField% = 0) ? (%A_LoopField%_%loop1% - %A_LoopField%) : (%A_LoopField%_%loop1% - %A_LoopField%) * (-1)
			}
			vars.iteminfo.compare.losses.Push(losses_%A_Index%)
		}
	}

	clip2 := StrReplace(clip2, "`n{", "|{") ;group lines that belong to a single affix together
	vars.iteminfo.clipboard2 := clip2
}

Iteminfo4_GUI()
{
	local
	global vars, settings, db
	static toggle := 0

	toggle := !toggle, GUI_name := "iteminfo" toggle, clip := vars.iteminfo.clipboard, clip2 := vars.iteminfo.clipboard2, item := vars.iteminfo.item, UI := vars.iteminfo.UI ;short-cut variables
	Gui, %GUI_name%: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDiteminfo +E0x02000000 +E0x00080000 ;the last two styles reduce flashing by using double-buffering and bottom-to-top rendering
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Font, % "cWhite s"settings.iteminfo.fSize, % vars.system.font
	hwnd_old := vars.hwnd.iteminfo.main, vars.hwnd.iteminfo := {"main": iteminfo, "inverted_mods": {}}

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// DPS area

	If (item.type = "attack") && !settings.iteminfo.compare ;create top-area with DPS values if item is weapon
	{
		all_dps := item.dps.phys "," item.dps.ele "," item.dps.chaos
		Sort, all_dps, D`, N
		filler := 0, dps_added := 0, filler_width := UI.segments - 6 ;filler_width used to set the width of a (potentially) very wide empty cell ;default = 4 segments
		Loop, Parse, all_dps, `,
		{
			If !A_LoopField
			{
				filler_width += (A_LoopField = 0) ? 1.5 : 0 ;if one damage-type is not present on a weapon (e.g. ele-dmg), widen the filler-cell by 1.5 segments (0.5 for the icon, 1 for the text)
				Continue
			}
			dps_added += 1, style := (dps_added = 1) ? "xs Section" : "ys"
			text := (item.dps.chaos = A_LoopField) ? Format("{:0.1f}", item.dps.chaos) : (item.dps.ele = A_LoopField) ? Format((item.dps.ele < 1000) ? "{:0.1f}" : "{:0.0f}", item.dps.ele) : Format("{:0.1f}", item.dps.phys) ;text for the cell
			label := (item.dps.chaos = A_LoopField) ? "chaos" : (item.dps.ele = A_LoopField) ? "allres" : "phys" ;icon for the cell
			If !filler
			{
				Gui, %GUI_name%: Add, Text, % style " Right Border w"filler_width*UI.wSegment " h"UI.hSegment, % LangTrans("iteminfo_dps") " " ;add the filler cell
				style := "ys", filler := 1
			}
			If !vars.pics.iteminfo[label]
				vars.pics.iteminfo[label] := LLK_ImageCache("img\GUI\item info\" label ".png")
			Gui, %GUI_name%: Add, Picture, % style " Border BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo[label] ;icon for the dmg-type
			Gui, %GUI_name%: Add, Text, % "ys Center Border w"UI.wSegment " h"UI.hSegment, % text ;dmg-text
		}
		If !vars.pics.iteminfo.damage
			vars.pics.iteminfo.damage := LLK_ImageCache("img\GUI\item info\damage.png")
		Gui, %GUI_name%: Add, Picture, % "ys Border Center BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo.damage ;total-dps icon
		Gui, %GUI_name%: Add, Text, % "ys Center Border w"UI.wSegment " h"UI.hSegment, % (item.dps.total < 1000) ? Format("{:0.1f}", item.dps.total) : Format("{:0.0f}", item.dps.total) ;total-dps text
	}

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// base-info / league-start area

	losses := vars.iteminfo.compare.losses, compare := vars.iteminfo.compare ;short-cut variables
	If (settings.iteminfo.itembase && ((item.rarity != LangTrans("items_unique") || item.anoint) || (item.type = "defense" && IsNumber(item.base_percent)))) || settings.iteminfo.compare
	{
		If !settings.iteminfo.compare ;if league-start mode is disabled, add base-item info
		{
			Switch item.type
			{
				Case "attack": ;tooltip shows how close an item's phys-dmg, crit, and attack-speed are to the best-in-class item
					stats_present := "phys,crit,speed,"
					phys_text := item.stats.phys.relative "%"
					crit_text := item.stats.crit.relative "%"
					speed_text := item.stats.speed.relative "%"
				Case "defense": ;tooltip shows how close an item's defense and block values are to the best-in-class item
					stat_order := "armour,evasion,energy,ward,combined,block"
					armour_text := item.stats.armour.relative "%"
					evasion_text := item.stats.evasion.relative "%"
					energy_text := item.stats.energy.relative "%"
					ward_text := item.stats.ward.relative "%"
					combined_text := item.stats.combined.relative "%"
					block_text := item.stats.block.base_best "/"item.stats.block.class_best ;item.stats.block.relative "%"
					Loop, Parse, stat_order, `,
					{
						For key, val in item.stats
							If (key = A_LoopField)
								stats_present .= A_LoopField ","
					}
					stats_present .= ","
				Default:
					stats_present := ""
					If (item.anoint != "") && !InStr(vars.iteminfo.clipboard, "`r`n" LangTrans("items_corrupted") "`r`n")
						stats_present := item.anoint ","
			}
			If (item.rarity = LangTrans("items_unique")) && !item.anoint
				stats_present := ""
		}

		If (item.class != "base jewels") ;exclude base/generic jewels
		{
			Loop, % settings.iteminfo.compare ? losses.Count() : 1 ;if league-start mode is enabled, create up to two tooltip areas (one per potential comarison, e.g. ring 1 & 2, mainhand & offhand)
			{
				loop := A_Index
				If settings.iteminfo.compare
				{
					Switch item.type
					{
						Case "attack":
							stat_order := "cdps,pdps,edps,speed,dps" ;for attack items, every dps-type and attack-speed will be compared
							Loop, Parse, stat_order, `,
							{
								If (A_Index = 1)
									stats_present := ""
								If (compare.items.0[A_LoopField] != 0) || (compare.items[loop][A_LoopField] != 0) ;display comparison of the given stat if it's present on either weapon
									stats_present .= A_LoopField ","
							}
							Loop, Parse, stats_present, `,
							{
								%A_LoopField%_difference := "" ;difference between the items' values, e.g. +100, -50, etc.
								If (A_LoopField = "")
									continue
								Switch A_LoopField
								{
									Case "cdps":
										label := "chaos" ;which icon to use for the cell
									Case "pdps":
										label := "phys"
									Case "edps":
										label := "allres" ;[sic!] allres and ele-dmg share the same icon
									Case "speed":
										label := "speed"
									Case "dps":
										label := "damage"
								}
								If losses[loop].HasKey(A_LoopField) ;the given stat is present on both items, and the difference is not 0
								{
									decimals := (A_LoopField = "speed") ? 0.2 : 0.0 ;how many decimals to display
									parse := compare.items[loop][A_LoopField] ? Format("{:0.0f}", (losses[loop][A_LoopField] / compare.items[loop][A_LoopField]) * 100) : Format("{:"decimals "f}", (losses[loop][A_LoopField]))
									%A_LoopField%_text := (losses[loop][A_LoopField] > 0) ? parse : -parse
									%A_LoopField%_text .= compare.items[loop][A_LoopField] ? "%" : "" ;if the equipped item has more than 0 of the stat, the difference was stored as a percentage
									%A_LoopField%_difference := parse ;store the raw value separately to determine color later
									losses[loop][A_LoopField] := "" ;this object will be parsed again later to calculate non-dps losses, so this loss has to be cleared
								}
								Else If !losses[loop].HasKey(A_LoopField) && (InStr(compare.items.0.stats, A_LoopField) && compare.items.0[A_LoopField]) ;only the looted item has the stat
								{
									decimals := (A_LoopField = "speed") ? 0.2 : 0.0
									parse := Format("{:"decimals "f}", compare.items.0[A_LoopField])
									%A_LoopField%_text := parse
									%A_LoopField%_difference := parse
								}
							}
						Default:
							stat_order := "chaos,fire,lightning,cold,life" ;for defense items, every resist and flat life will be compared
							Loop, Parse, stat_order, `,
							{
								If (A_Index = 1)
									stats_present := ""
								If (InStr(compare.items.0.stats, "to_"A_LoopField "_resistance") && compare.items.0["to_"A_LoopField "_resistance"]) || (InStr(compare.items[loop].stats, "to_" A_LoopField "_resistance") && compare.items[loop]["to_"A_LoopField "_resistance"])
									stats_present .= A_LoopField ","
								Else If (InStr(compare.items.0.stats, "to_maximum_" A_LoopField) && !InStr(compare.items.0.stats, "to_maximum_" A_LoopField "_")) || (InStr(compare.items[loop].stats, "to_maximum_" A_LoopField) && !InStr(compare.items[loop].stats, "to_maximum_" A_LoopField "_"))
									stats_present .= A_LoopField ","
							}

							Loop, Parse, stats_present, `,
							{
								%A_LoopField%_difference := ""
								If (A_LoopField = "")
									continue
								If losses[loop].HasKey("to_"A_LoopField "_resistance") ;the res-stat is present on both items
								{
									%A_LoopField%_text := (losses[loop]["to_"A_LoopField "_resistance"] > 0) ? losses[loop]["to_"A_LoopField "_resistance"] : -losses[loop]["to_"A_LoopField "_resistance"]
									%A_LoopField%_difference := losses[loop]["to_"A_LoopField "_resistance"]
									losses[loop]["to_"A_LoopField "_resistance"] := ""
								}
								;res-stat is only present on looted item
								Else If !losses[loop].HasKey("to_"A_LoopField "_resistance") && (InStr(compare.items.0.stats, "to_"A_LoopField "_resistance") && compare.items.0["to_"A_LoopField "_resistance"])
								{
									%A_LoopField%_text := compare.items.0["to_"A_LoopField "_resistance"]
									%A_LoopField%_difference := compare.items.0["to_"A_LoopField "_resistance"]
								}

								If losses[loop].HasKey("to_maximum_"A_LoopField) && !losses[loop].HasKey("to_maximum_"A_LoopField "_") ;both items have flat life
								{
									%A_LoopField%_text := (losses[loop]["to_maximum_"A_LoopField] > 0) ? losses[loop]["to_maximum_"A_LoopField] : -losses[loop]["to_maximum_"A_LoopField]
									%A_LoopField%_difference := losses[loop]["to_maximum_"A_LoopField]
									losses[loop]["to_maximum_"A_LoopField] := ""
								}
								Else If !losses[loop].HasKey("to_maximum_"A_LoopField) && (InStr(compare.items.0.stats, "to_maximum_"A_LoopField) && compare.items.0["to_maximum_"A_LoopField]) ;only looted item has flat life
								{
									%A_LoopField%_text := compare.items.0["to_maximum_"A_LoopField]
									%A_LoopField%_difference := compare.items.0["to_maximum_"A_LoopField]
								}
							}
					}
				}

				loop_count := !settings.iteminfo.compare ? LLK_InStrCount(stats_present, ",") + 1 : LLK_InStrCount(stats_present, ",")
				stats_present := "filler," stats_present ;add a filler cell

				If InStr(stats_present, "life") ;if flat life is part of the comparison, determine if its cell needs more space (2- vs 3-digit value)
					life_width := (life_difference > 99 || life_difference < -99) ? 0.25 : 0
				Else life_width := 0

				;determine cell-widths for different scenarios
				If settings.iteminfo.compare ;for league-start mode
				{
					width := (item.type = "attack") ? UI.wSegment : UI.wSegment*0.5
					filler_width := (item.type = "attack") ? (UI.segments - loop_count*1.5) * UI.wSegment : (UI.segments - loop_count - life_width) * UI.wSegment
				}
				Else If (item.anoint != "") ;for anointed items
				{
					width := UI.wSegment * 0.5, loop_count += 1
					filler_width := (item.rarity != LangTrans("items_unique")) ? (UI.segments - loop_count*1.25 + 1) * UI.wSegment : (UI.segments - loop_count*1.25 + 2.5) * UI.wSegment
				}
				Else ;for generic base-type information
				{
					width := UI.wSegment
					filler_width := (UI.segments - loop_count*1.5) * UI.wSegment
				}

				filler := ""
				Loop, Parse, stats_present, `,, %A_Space% ;go through every stat and create the necessary cells
				{
					If (A_LoopField = "")
						continue
					If (A_LoopField = "filler")
					{
						style := (filler = "") ? "xs Section" : "ys"
						If settings.iteminfo.compare ;filler-text for league-start mode
						{
							If InStr(compare.items.slots, ",") ;for rings, change ring1 and ring2 to l-ring and r-ring
								parse := (loop = 1) ? StrReplace(SubStr(compare.items.slots, 1, InStr(compare.items.slots, ",") - 1), "ring1", "l-ring") " " : StrReplace(SubStr(compare.items.slots, InStr(compare.items.slots, ",") + 1), "ring2", "r-ring") " "
							Else parse := compare.items.slots " "
						}
						Else parse := LangTrans("iteminfo_base") " " ;filler-text for base-item info
						Gui, %GUI_name%: Add, Text, % style " Border Right BackgroundTrans w"filler_width " h"UI.hSegment, % parse
						filler := 1
						continue
					}

					If (item.anoint != "")
						width_override := width*2.5
					Else width_override := (A_LoopField = "life") ? width + UI.wSegment*life_width : width
					style := (filler = 1) ? "ys h"UI.hSegment " w"width_override : "xs Section h"UI.hSegment " w"width_override
					filler := 1

					If (item.anoint != "") ;add oil-name to cell and determine highlight-color
						%A_LoopField%_text := db.anoints._oils[A_LoopField]
						, rank := 14 - A_LoopField, rank := (rank >= 6) ? 6 : rank
						, color := (rank = 0) ? "White" : settings.iteminfo.colors_tier[rank]
					Else color := (item.stats[A_LoopField].base_best = item.stats[A_LoopField].class_best) ? settings.iteminfo.colors_tier.1 : "404040"

					If (%A_LoopField%_difference != "")
					{
						If (%A_LoopField%_difference >= 1)
							color := settings.iteminfo.colors_tier.2
						If (%A_LoopField%_difference >= 11)
							color := settings.iteminfo.colors_tier.1
						If (%A_LoopField%_difference = 0)
							color := "Black"
						If (%A_LoopField%_difference < 0)
							color := settings.iteminfo.colors_tier.5
						If (%A_LoopField%_difference <= -11)
							color := settings.iteminfo.colors_tier.6
					}

					If settings.iteminfo.compare
					{
						If (item.type = "attack")
							label := (A_LoopField = "cdps") ? "chaos" : (A_LoopField = "pdps") ? "phys" : (A_LoopField = "edps") ? "allres" : (A_LoopField = "speed") ? "speed" : "damage"
						Else label := A_LoopField
					}
					Else
					{
						If (item.type = "attack")
							label := A_LoopField
						Else label := (A_LoopField = "armour") ? "armor" : (A_LoopField = "energy") ? "energy" : A_LoopField

						If (A_LoopField = "combined")
							label := InStr(stats_present, "armour,evasion") ? "armor_evasion" : InStr(stats_present, "armour,energy") ? "armor_energy" : "evasion_energy"
					}

					If (item.anoint = "")
					{
						If !vars.pics.iteminfo[label]
							vars.pics.iteminfo[label] := LLK_ImageCache("img\GUI\item info\" label ".png")
						Gui, %GUI_name%: Add, Picture, % "ys Border BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo[label]
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack", 0
					}

					color1 := (color = "White") ? "Red" : InStr("Black, 404040", color) ? "White" : "Black"
					Gui, %GUI_name%: Add, Text, % style " Border Center BackgroundTrans c"color1 " h"UI.hSegment, % %A_LoopField%_text
					Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border range0-100 BackgroundBlack c"color, % !settings.iteminfo.compare && (item.anoint = "") ? item.stats[A_LoopField].relative : 100
				}

				If settings.iteminfo.compare ;for league-start mode, add an additional area with losses/wins, e.g. suppression, flat dmg on armour, etc.
				{
					For key, value in losses[loop]
					{
						If (value = "" || value >= 0) || (item.type = "attack" && key = "increased_attack_speed") || (IteminfoModHighlight(StrReplace(key, "_", " "), 0, 0) < 1) ;&& IteminfoModHighlight(StrReplace(key, "_", " "), 0, 1) < 1)
							continue
						parse := StrReplace(key, "adds_to_")
						If (SubStr(parse, 1, 10) = "chance_to_") || (SubStr(parse, 1, 10) = "increased_") || (SubStr(parse, 1, 8) = "reduced_")
							parse := "%_" parse
						value *= (value < 0) ? -1 : 1
						If InStr(value, ".")
							value := Format("{:0.2f}", value)
						Gui, %GUI_name%: Add, Text, % "xs Section w"UI.wSegment*UI.segments " h"UI.hSegment " Border Center BackgroundTrans c"settings.iteminfo.colors_tier.5, % InStr(parse, "%") ? value StrReplace(parse, "_", " ") : value " " StrReplace(parse, "_", " ") ;add actual text label
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Section Disabled Border BackgroundBlack w"UI.wSegment*UI.segments " h"UI.hSegment, 0
					}
					Gui, %GUI_name%: Add, Progress, % "xs Section Disabled Background646464 w"UI.wSegment*UI.segments " h"UI.hDivider*2.5, 0
				}
				Else
				{
					If (item.type = "defense") ;add the cells for the base-percentile roll
					{
						If !vars.pics.iteminfo.defense
							vars.pics.iteminfo.defense := LLK_ImageCache("img\GUI\item info\defense.png")
						Gui, %GUI_name%: Add, Picture, % "ys Border BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo.defense
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack", 0
						color := (item.base_percent >= 99) ? settings.iteminfo.colors_tier.1 : "404040", color1 := (color != "404040") ? "Black" : "White" ;highlight base-% bar green if >= 99
						Gui, %GUI_name%: Add, Text, % "ys h"UI.hSegment " w"UI.wSegment " Border Center BackgroundTrans c"color1, % item.base_percent "%"
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border range0-100 BackgroundBlack c"color, % item.base_percent
					}

					If (item.rarity != LangTrans("items_unique"))
					{
						If !vars.pics.iteminfo.ilvl
							vars.pics.iteminfo.ilvl := LLK_ImageCache("img\GUI\item info\ilvl.png")
						Gui, %GUI_name%: Add, Picture, % "ys Border Center BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo.ilvl
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack", 0
						color := (item.ilvl >= item.ilvl_max) ? settings.iteminfo.colors_tier.1 : "404040", color1 := (color != "404040") ? "Black" : "White" ;highlight ilvl bar green if ilvl >= 86
						Gui, %GUI_name%: Add, Text, % "ys h"UI.hSegment " w"UI.wSegment " Border Center BackgroundTrans c"color1, % (item.ilvl = 100) ? item.ilvl : item.ilvl "/" item.ilvl_max
						Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border range66-"item.ilvl_max " BackgroundBlack c"color, % item.ilvl
					}
				}
			}
		}
	}

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// implicit area

	tColors := settings.iteminfo.colors_tier, iColors := settings.iteminfo.colors_ilvl ;short-cut variables
	For index, implicit in item.implicits ;add segments to the GUI
	{
		;determine if there's a suitable icon for the implicit
		If !InStr(implicit, LangTrans("items_implicit_exarch")) && !InStr(implicit, LangTrans("items_implicit_eater"))
			type := InStr(implicit, LangTrans("items_implicit_vaal")) ? "vaal" : InStr(clip, "`r`nSynthesised ", 1) ? "synthesis" : ""
		Else type := InStr(implicit, LangTrans("items_implicit_exarch")) ? "exarch" : "eater"
		type := InStr(implicit, LangTrans("mods_implicit_vendor")) ? "delve" : InStr(implicit, LangTrans("mods_blight_enchant", 1)) || db.anoints.rings.HasKey(implicit) ? "blight" : InStr(clip, " Talisman`r`n", 1) ? "talisman" : type

		tCheck := ["lesser", "greater", "grand", "exceptional", "exquisite", "perfect"]
		If InStr("exarch, eater", type)
			For index0, tier0 in vars.lang.items_implicit_tiers
				If InStr(implicit, tier0)
					tier := tCheck[index0]

		implicit := LangTrim(implicit, vars.lang.mods_blight_enchant), implicit := SubStr(implicit, InStr(implicit, "`n") + 1)
		While InStr(implicit, "`n(") ;remove info-text
			parse := SubStr(implicit, InStr(implicit, "`n(")), parse := SubStr(parse, 1, InStr(parse, ")")), implicit := StrReplace(implicit, parse)

		If LangMatch(implicit, vars.lang.mods_eldritch_interval, 0) ;trim mods with intervals
			implicit := StrReplace(implicit, vars.lang.mods_eldritch_interval.1, " ("), implicit := StrReplace(implicit, vars.lang.mods_eldritch_interval.2, " sec)")

		While InStr(implicit, "  ")
			implicit := StrReplace(implicit, "  ", " ")

		If LangMatch(implicit, vars.lang.mods_eldritch_condition, 0)
			boss_type := copy := SubStr(implicit, InStr(implicit, vars.lang.mods_eldritch_condition.2) + StrLen(vars.lang.mods_eldritch_condition.2) + 1), boss_type := LangTrim(StrReplace(implicit, boss_type), vars.lang.mods_eldritch_condition) . ": ", implicit := boss_type . copy

		highlight := IteminfoModHighlight(implicit, 0, 1)
		If !highlight ;mod is neither desired nor undesired
			color := "Black"
		Else color := (highlight = 1) ? tColors.1 : tColors.6

		color1 := (color = "Black") ? "White" : "Black"
		Gui, %GUI_name%: Add, Text, % "xs Center Hidden Border w"UI.wSegment*(UI.segments - 1.25) " HWNDhwnd c"color1, % IteminfoModRemoveRange(implicit) ;add hidden text label as dummy to get the correct height
		GuiControlGet, text_, Pos, %hwnd%
		height := (text_h <= UI.hSegment) ? UI.hSegment : text_h ;if mod-text consists of two lines, use that height, otherwise force standardized height
		Gui, %GUI_name%: Add, Text, % "xp yp wp h"height " Border Center BackgroundTrans HWNDhwnd c"color1, % IteminfoModRemoveRange(implicit) ;add actual text label on top
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled Section HWNDhwnd BackgroundBlack c"color, 100 ;place progress bar on top of text label (reversed stack-order)

		Gui, %GUI_name%: Add, Text, % "ys hp w"UI.wSegment/4 " Border 0x200 Center BackgroundTrans", % ""
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd c"color, 100 ;small rectangle that displays neutral/(un)desired
		vars.hwnd.iteminfo["implicit_"implicit] := hwnd

		Switch tier ;translate eldritch tiers and set colors
		{
			Case "lesser":
				color := tColors.4, tier := 6
			Case "greater":
				color := tColors.3, tier := 5
			Case "grand":
				color := tColors.2, tier := 4
			Case "exceptional":
				color := tColors.1, tier := 3
			Case "exquisite":
				color := "White", tier := 2
			Case "perfect":
				color := "White", tier := 1
			Default:
				color := tColors.0, tier := "#"
		}

		width := (type = "") ? UI.wSegment : UI.wSegment/2, color1 := (tier = 1 || tier = 2) ? "Red" : "Black" ;cell-width and text-color
		Gui, %GUI_name%: Add, Text, % "ys hp w"width " 0x200 Border Center BackgroundTrans c"color1, % tier ;text-cell
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd c"color, 100 ;cell coloring

		If type ;implicit has a suitable icon
		{
			If !vars.pics.iteminfo[type]
				vars.pics.iteminfo[type] := LLK_ImageCache("img\GUI\item info\" type ".png")

			If (height <= UI.hSegment) ;if cell is single-line height, add regular cell
				Gui, %GUI_name%: Add, Picture, % "ys h"UI.hSegment-2 " w-1 Border BackgroundTrans HWNDhwnd", % (type != "") ? "HBitmap:*" vars.pics.iteminfo[type] : ""
			Else ;if cell is multi-line height, add taller cell and place icon in the middle
			{
				Gui, %GUI_name%: Add, Text, % "ys wp hp Border BackgroundTrans HWNDhwnd", ;dummy text-cell with a border (can't use icon-border for this case)
				Gui, %GUI_name%: Add, Picture, % "xp+1 yp+"height/2 - UI.hSegment/2 + 1 " BackgroundTrans h"UI.hSegment-2 " w-1", % (type != "") ? "HBitmap:*" vars.pics.iteminfo[type] : ""
			}
			ControlGetPos, x, y,,,, % "ahk_id " hwnd ;manually get coordinates of the appropriate control (can't use xp yp in the second case above)
			Gui, %GUI_name%: Add, Progress, % "x"x-1 " y"y-1 " w"UI.wSegment/2 " h"height " Disabled Border BackgroundBlack c"color, 100
		}
	}
	If item.implicits.Count()
		Gui, %GUI_name%: Add, Progress, % "xs w"UI.wSegment*UI.segments " Disabled h"UI.hDivider " Background"UI.cDivider, ;add divider-line to visually separate implicits

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// cluster-enchant area

	If item.cluster ;if item is a cluster jewel, add passive-skills and enchant info
	{
		highlight := IteminfoModHighlight(StrReplace(item.cluster.enchant, "`n", ";"), 0, 1)
		If (highlight = 0) ;mod is neither desired nor undesired
			color := "Black"
		Else color := (highlight = 1) ? tColors.1 : tColors.6 ;determine which is the case

		Gui, %GUI_name%: Add, Text, % "xs Section Border Hidden Center BackgroundTrans w"UI.wSegment*(UI.segments - 1.25) " cWhite HWNDmain_text", % item.cluster.enchant ;dummy panel to get the correct height
		GuiControlGet, check_, Pos, %main_text%
		height := (check_h <= UI.hSegment) ? UI.hSegment : check_h, color1 := (color = "Black") ? "White" : "Black" ;get correct height, determine text-color
		Gui, %GUI_name%: Add, Text, % "xp yp wp h"height " Border Center BackgroundTrans HWNDhwnd_itemchecker_cluster_text c"color1, % item.cluster.enchant ;add actual text label
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c"color, 100 ;add background color

		Gui, %GUI_name%: Add, Text, % "ys hp w"UI.wSegment*0.25 " Border Center BackgroundTrans cBlack", % " " ;small rectangle to set the mod to (un)desired
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd BackgroundBlack c"color, 100
		vars.hwnd.iteminfo["implicit_"item.cluster.enchant] := hwnd

		color := (item.cluster.passives >= item.cluster.optimal) ? tColors.1 : "404040", color1 := (color = tColors.1) ? "Black" : "White" ;determine cell- and text-color for passive-count
		Gui, %GUI_name%: Add, Text, % "ys hp w"UI.wSegment " Border 0x200 Center BackgroundTrans c"color1, % -item.cluster.passives "/" -item.cluster.max ;add text: passives/max passives
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled range"item.cluster.max "-"item.cluster.optimal " BackgroundBlack c"color, % item.cluster.passives
		If !InStr(clip, "rarity: normal") ;only add a divider if cluster jewel is not normal rarity
			Gui, %GUI_name%: Add, Progress, % "xs Background"UI.cDivider " h"UI.hDivider " w"UI.wSegment*UI.segments,
	}

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// explicit area

	unique := (item.rarity = LangTrans("items_unique")) ? 1 : 0, divider := 0 ;is item unique, has a divider been placed?
	roll_stats := [], roll_colors := {0: tColors[1], 10: tColors[2], 20: tColors[3], 30: tColors[4], 40: tColors[5], 50: tColors[6]}
	Loop, Parse, clip2, | ;parse the item-info affix by affix
	{
		If (item.class != "base jewels")
			tier := unique ? "u" : InStr(A_LoopField, LangTrans("items_tier")) ? SubStr(A_LoopField, InStr(A_LoopField, LangTrans("items_tier")) + StrLen(LangTrans("items_tier")) + 1, 2) : InStr(A_LoopField, "(crafted)") ? "c" : "#", tier := InStr(tier, ")") ? StrReplace(tier, ")") : tier ;determine affix tier for non-jewel items
		Else tier := "?"

		mod := SubStr(A_LoopField, InStr(A_LoopField, "`n") + 1) ;text of the mod
		While InStr(mod, "`n(") ;remove info-text
			parse := SubStr(mod, InStr(mod, "`n(")), parse := SubStr(parse, 1, InStr(parse, ")")), mod := StrReplace(mod, parse)

		height := 0, name := unique ? "" : SubStr(A_LoopField, InStr(A_LoopField, """",,, 1) + 1, InStr(A_LoopField, """",,, 2) - InStr(A_LoopField, """",,, 1) - 1) ;height and name for the mod
		affix_type := InStr(A_LoopField, " Prefix Modifier ") ? "prefix" : "?", affix_type := InStr(A_LoopField, " Suffix Modifier ") ? "suffix" : affix_type
		search_class := InStr(item.class, " Flasks") ? "flasks" : IsObject(item.cluster) ? "cluster jewels" : item.class ;flasks and cluster-jewels need to be handled differently when looked up in the databases

		If settings.iteminfo.ilvl && (item.class != "base jewels") ;if item-levels are enabled, look them up in the databases
		{
			ilvl := "??" ;set placeholder ilvl
			For key, val in db.item_mods[db.item_mods.HasKey(search_class) ? search_class : "universal"]
			{
				If (val.affix = name) && (val.type = affix_type)
				{
					For index, text in val.texts ; to avoid ambiguity, also check if the mod-texts match
						If !InStr(mod, text)
							Continue 2

					tag_check := 0
					For index, tag in item.tags ; to avoid ambiguity, also check if the tags match
						If LLK_HasVal(val.tags, tag, 1)
							tag_check += 1

					If !tag_check
						Continue

					ilvl := val.level
					Break
				}
			}
		}
		mod := StrReplace(mod, LangTrans("mods_cluster_passive", 2) " "), mod := StrReplace(mod, LangTrans("mods_cluster_passive", 3) " ") ;trim cluster-jewel mod-texts

		If (settings.general.lang_client = "english") && (item.class = "base jewels") ;for base/generic jewels, look up mod-weights
		{
			For key, val in db.item_mods["base jewels"]
			{
				If (val.affix = name) ;affix names match
				{
					For index, text in val.texts ;to avoid ambiguity, also check if the mod-texts match
					{
						If !InStr(mod, text)
							Continue 2
					}
					tags := db.item_bases.jewels[item.itembase]._tags ;tags also need to be checked because those influence the weights in some cases
					For index, tag in tags
					{
						If !Blank(LLK_HasVal(val.tags, tag))
						{
							tier := Format("{:0.0f}", val.weights[LLK_HasVal(val.tags, tag)]/10)
							Break
						}
					}
				}
			}
		}

		If !unique && (SubStr(A_LoopField, 1, 1) = "{") && InStr(A_LoopField, LangTrans("items_prefix"))
			divider -= 1
		If !unique && (SubStr(A_LoopField, 1, 1) = "{") && InStr(A_LoopField, LangTrans("items_suffix")) && (divider < 0)
		{
			Gui, %GUI_name%: Add, Progress, % "xs Section w"UI.segments*UI.wSegment " h"UI.hDivider " Background"UI.cDivider, 0 ;divider between pre- and suffixes
			divider := 1
		}

		highlights := "", color_t := "Black" ;track (un)desired highlighting for every part of hybrid mods
		Loop, Parse, mod, `n ;parse mod-text line by line
		{
			text_check := StrReplace(StrReplace(A_LoopField, " (crafted)"), " (fractured)"), invert_check := vars.iteminfo.inverted_mods.HasKey(IteminfoModHighlight(A_LoopField, "parse"))
			rolls := IteminfoModRollCheck(A_LoopField)
			If invert_check
				rolls[4] := rolls[1], rolls[1] := rolls[3], rolls [3] := rolls[4]
			rolls_val := Abs(rolls.2 - rolls.1), rolls_max := Abs(rolls.3 - rolls.1), valid_rolls := (!IsNumber(rolls.1 + rolls.2 + rolls.3) || !InStr(text_check, "(")) ? 0 : 1
			If unique && !valid_rolls ;for uniques, skip mod-parts that don't have a roll
				Continue
			mod_text := settings.iteminfo.modrolls ? IteminfoModRemoveRange(text_check) : text_check
			Gui, %GUI_name%: Add, Text, % "xs Section HWNDhwnd Border Hidden Center w"(UI.segments - (unique ? 1 : 1.25))*UI.wSegment, % mod_text ;dummy text-panel to gauge the required height of the text
			GuiControlGet, text_, Pos, % hwnd

			color := (invert_check && (rolls_val / rolls_max) * 100 != 0) ? "505000" : unique ? "994C00" : !InStr(LLK_StringRemove(A_LoopField, " (fractured), (crafted)"), "(") ? "303060" : "404040"
			;if dummy text-panel is single-line, increase height slightly to make small cells square
			Gui, %GUI_name%: Add, Text, % "xp yp wp h"(text_h < UI.hSegment ? UI.hSegment : "p" ) " Section BackgroundTrans HWNDhwnd Border Center" (invert_check && (rolls_val / rolls_max) * 100 = 0 ? " cCCCC00" : ""), % mod_text ;add actual text-panel with the correct size
			GuiControlGet, text_, Pos, % hwnd ;get position and size of the text-panel
			height += text_h ;sum up the heights of each line belonging to the same mod, so it can be used for the cells right next to them (highlight, tier, and potentially icon/ilvl)
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Section HWNDhwnd Border Disabled BackgroundBlack range0-100 c"color, % (rolls_val / rolls_max) * 100
			If InStr(text_check, "(")
				vars.hwnd.iteminfo.inverted_mods[IteminfoModHighlight(A_LoopField, "parse")] := hwnd

			If unique ;add roll-% to unique mods
			{
				color := "White", roll_percent := Format("{:0.0f}", rolls_val / rolls_max * 100), roll_percent := (roll_percent > 100) ? 100 : roll_percent
				For key, val in roll_colors
					color := (100 - roll_percent > key) ? val : color
				Gui, %GUI_name%: Add, Text, % "ys hp w" UI.wSegment " Border 0x200 BackgroundTrans Center c" (color = "White" ? "Red" : "Black"), % roll_percent
				roll_stats.Push([rolls_val, rolls_max])
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack c"color, 100
			}
			Else ;add (un)desired rectangle for non-uniques
			{
				highlights .= highlight := IteminfoModHighlight(A_LoopField) ;highlights = (un)desired highlighting for the whole mod-group, highlight = highlighting for the single part
				color := !highlight ? "Black" : (highlight = -2) ? iColors.8 : (highlight = -1) ? tColors.6 : (highlight = 1) ? tColors.1 : tColors.7 ;determine the right color
				Gui, %GUI_name%: Add, Text, % "ys hp w"UI.wSegment/4 " Border BackgroundTrans Center", % " " ;add the rectangle
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd Disabled Border BackgroundBlack c"color, 100 ;color the rectangle
				vars.hwnd.iteminfo[StrReplace(StrReplace(A_LoopField, " (crafted)"), " (fractured)")] := hwnd ;store the rectangle's HWND and include the mod-text
			}
			If (A_Index = 1) ;for the first line within a group, store the coordinates so that the tier-cell can be placed right next to it
			{
				GuiControlGet, text_, Pos, % hwnd
				x := text_x + text_w, y := text_y
			}
		}
		If !unique ;add tier and icon/ilvl-cells for non-uniques
		{
			;determine the right color for the cells
			If InStr(A_LoopField, " (fractured)")
			{
				color := tColors.7 ;fractured mods have a specific color
				If InStr(highlights, "+",,, LLK_InStrCount(A_LoopField, "`n")) && ((tier = 1) || item.class = "base jewels") ;if the fractured mod is also desired, add red highlighting to the text and make it bold
				{
					color_t := "Red"
					Gui, %GUI_name%: Font, bold
				}
			}
			Else If InStr(highlights, "-",,, LLK_InStrCount(A_LoopField, "`n")) && settings.iteminfo.override ;if the override-option is enabled and the mod is undesired, apply t6 color
				color := tColors.6
			Else If InStr(highlights, "+",,, LLK_InStrCount(A_LoopField, "`n")) && (item.class = "base jewels") ;if the item is a base/generic jewel and the mod is desired, override cell colors with t1 color
				color := tColors.1
			Else If InStr(highlights, "+",,, LLK_InStrCount(A_LoopField, "`n")) && (tier = 1 || tier = "#") ;if the mod is desired and t1 or untiered, apply white background and red text (Neversink's t1 color-scheme)
				color := "White", color_t := "Red"
			Else If (item.class = "base jewels") ;for base/generic jewel mods, use shades of gray (lighter shade = lower weight/probability)
				color := IsNumber(tier) ? 119-tier*2 . 119-tier*2 . 119-tier*2 : "Black", color_t := (tier < 10) ? "Red" : "White"
			Else color := InStr("c#", tier) ? tColors.0 : (tier >= 6) ? tColors.6 : IsNumber(tier) ? tColors[tier] : "Black"

			label := IteminfoModgroupCheck(name, 1) ? IteminfoModgroupCheck(name, 1) : IteminfoModCheck(mod, item.type), label := InStr(A_LoopField, " (crafted)") ? "mastercraft" : label ;check for suitable icon
			width := (label || settings.iteminfo.ilvl && item.class != "base jewels" && ilvl != "??") ? UI.wSegment/2 : UI.wSegment ;determine the width of the cell, and whether it needs to be divided into two parts
			width := (settings.iteminfo.override && InStr(highlights, "-",,, LLK_InStrCount(A_LoopField, "`n")) && !InStr(A_LoopField, " (fractured)")) ? UI.wSegment : width

			Gui, %GUI_name%: Add, Text, % "x"x " y"y " h"height " w"width " BackgroundTrans Border 0x200 Center cBlack c"color_t, % tier ;add tier-cell
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c"color, 100
			Gui, %GUI_name%: Font, norm

			If (width < UI.wSegment) && (label || settings.iteminfo.ilvl && item.class != "base jewels" && ilvl != "??") ;divide tier-cell if necessary (to add icon/ilvl)
			{
				If !vars.pics.iteminfo[label]
					vars.pics.iteminfo[label] := LLK_ImageCache("img\GUI\item info\" label ".png")

				If (height <= UI.hSegment) ;if the mod is single-line, enforce standardized height for the cell
				{
					If (settings.iteminfo.ilvl && item.class != "base jewels" && ilvl != "??")
						Gui, %GUI_name%: Add, Text, % "ys h"UI.hSegment " wp Border Center BackgroundTrans HWNDhwnd c" ;cont
						. (ilvl >= settings.iteminfo.ilevels.1 && (settings.iteminfo.colors_ilvl.1 = "ffffff") ? "Red" : "Black"), % ilvl ;add ilvl-cell
					Else Gui, %GUI_name%: Add, Picture, % "ys h"UI.hSegment-2 " w-1 Border BackgroundTrans HWNDhwnd", % "HBitmap:*" vars.pics.iteminfo[label] ;add icon-cell
				}
				Else ;if the mod is multi-line, add a taller cell
				{
					If (settings.iteminfo.ilvl && item.class != "base jewels" && ilvl != "??")
						Gui, %GUI_name%: Add, Text, % "x+0 wp hp 0x200 Center Border BackgroundTrans HWNDhwnd c"
						. (ilvl >= settings.iteminfo.ilevels.1 && (settings.iteminfo.colors_ilvl.1 = "ffffff") ? "Red" : "Black"), % ilvl ;add ilvl-cell
					Else
					{
						Gui, %GUI_name%: Add, Text, % "x+0 wp hp Border BackgroundTrans HWNDhwnd", ;add dummy text-panel with borders (can't use icon's borders for taller cells)
						Gui, %GUI_name%: Add, Picture, % "xp+1 yp+"height/2 - UI.hSegment/2 + 1 " BackgroundTrans h"UI.hSegment-2 " w-1", % "HBitmap:*" vars.pics.iteminfo[label] ;add icon-cell
					}
				}
				ControlGetPos, x, y,,,, % "ahk_id " hwnd ;get the cells coordinates to place progress-control right onto it (can't use xp yp in cases with taller cells that also contain an icon)
				If (settings.iteminfo.ilvl && item.class != "base jewels" && ilvl != "??") && !InStr(A_LoopField, " (fractured)") ;get the correct color for the ilvl (unless the mod is fractured)
					For index, level in settings.iteminfo.ilevels
						If (ilvl >= level)
						{
							color := settings.iteminfo.colors_ilvl[index]
							Break
						}
						Else If (ilvl <= settings.iteminfo.ilevels.8)
						{
							color := settings.iteminfo.colors_ilvl.8
							Break
						}
				Gui, %GUI_name%: Add, Progress, % "x"x-1 " y"y-1 " w"UI.wSegment/2 " h"height " Disabled Border BackgroundBlack c"color, 100 ;add color to the cell
			}
		}
	}

	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	;////////////////////////////////////////// unique drop-tier and roll-health

	If unique
	{
		If roll_stats.Count()
			Gui, %GUI_name%: Add, Progress, % "xs w" UI.wSegment*UI.segments " Disabled h" UI.hDivider " BackgroundWhite",
		If db.item_drops[item.name]
			drop_tier := (StrLen(db.item_drops[item.name]) > 2) ? LangTrans("iteminfo_drop_" db.item_drops[item.name]) : db.item_drops[item.name]
		Else drop_tier := LangTrans("iteminfo_drop_unknown")
		segments := 1, sFiller := UI.segments - (roll_stats.Count() > 1 ? 1 : 0)
		LLK_PanelDimensions([LLK_StringCase(drop_tier " " LangTrans("items_unique"))], settings.iteminfo.fSize, wDrop, hDrop,,, 1)
		While (wDrop >= UI.wSegment * segments)
			segments += 0.25
		wDrop := UI.wSegment * segments, sFiller -= segments, roll_stats_val := roll_stats_max := 0

		For index, roll in roll_stats
			roll_stats_val += roll.1, roll_stats_max += roll.2
		roll_stats_average := Format("{:0.0f}", (roll_stats_val / roll_stats_max) * 100)
		Gui, %GUI_name%: Show, NA x10000 y10000
		WinGetPos,,, w, h, % "ahk_id " vars.hwnd.iteminfo.main
		Gui, %GUI_name%: Hide
		If (w >= 50)
			Gui, %GUI_name%: Add, Text, % "xs Section Border Right BackgroundTrans cWhite w" UI.wSegment * sFiller, % ""
		color := InStr(drop_tier, "0") ? "White" : (StrLen(drop_tier) = 2) ? tColors[SubStr(drop_tier, 2, 1)] : tColors[0]
		If !Blank(drop_tier)
		{
			Gui, %GUI_name%: Add, Text, % "ys Border Center BackgroundTrans w" wDrop " c" (color = "White" ? "Red" : "Black"), % LLK_StringCase(drop_tier " " LangTrans("items_unique"))
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack c" color, 100
		}
		;Gui, %GUI_name%: Add, Text, % "ys Border Center BackgroundTrans cWhite w" wPercent, % LangTrans("iteminfo_roll_percent")
		color := "White"
		For key, val in roll_colors
			color := (100 - roll_stats_average > key) ? val : color
		If (roll_stats.Count() > 1)
		{
			Gui, %GUI_name%: Add, Text, % "ys Border Center BackgroundTrans w" UI.wSegment " c" (color = "White" && roll_stats.Count() ? "Red" : "Black"), % roll_stats_average
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border BackgroundBlack HWNDhwnd_roll_percent_total_back c" (!roll_stats.Count() ? tColors[0] : color), 100
		}
	}

	Gui, %GUI_name%: Show, NA AutoSize x10000 y10000 ;show the GUI outside the monitor's area to get dimensions
	WinGetPos,,, w, h, % "ahk_id " vars.hwnd.iteminfo.main
	If (vars.iteminfo.UI.xPos != "") ;if tooltip is being refreshed to apply changes in settings, use previous coordinates
	{
		xPos := vars.iteminfo.UI.xPos, yPos := vars.iteminfo.UI.yPos
		xPos := (xPos + w > vars.client.x + vars.client.w) ? vars.client.x + vars.client.w - w : xPos
		yPos := (yPos + h > vars.client.y + vars.client.h) ? vars.client.y + vars.client.h - h : yPos
	}
	Else ;otherwise, place tooltip to the left and above the cursor
	{
		xPos := vars.general.xMouse, yPos := vars.general.yMouse
		xPos := (xPos - w - vars.client.w/200 < vars.client.x) ? vars.client.x : xPos - w - vars.client.w/200
		yPos := (yPos - h - vars.client.h/100 < vars.client.y) ? vars.client.y : yPos - h - vars.client.h/100
	}
	Gui, %GUI_name%: Show, % "NA x"xPos " y"yPos
	LLK_Overlay(vars.hwnd.iteminfo.main, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")

	If (w < UI.wSegment) ;if the tooltip is tiny, it contains no information (item was either not supported or doesn't have anything worthwhile to display, e.g. unscalable uniques)
		LLK_ToolTip(LangTrans("ms_item-info") ": " LangTrans("global_nothing"), 1.5,,,, "yellow"), IteminfoClose()
}

IteminfoClose(mode := 0) ;closes the tooltip and potential markers, and removes HWNDs
{
	local
	global vars, settings

	LLK_Overlay(vars.hwnd.iteminfo.main, "destroy")
	If mode
	{
		For index in vars.hwnd.iteminfo_markers
			Gui, iteminfo_marker%index%: Destroy
		vars.hwnd.Delete("iteminfo_markers")
	}
}

IteminfoCompare(string, item_type := "") ;takes a string with item-stats and returns a summary-string for comparisons
{
	local
	global vars, settings, db

	resists := "cold,lightning,fire,chaos"
	attributes := "strength,dexterity,intelligence"
	result := {}

	Loop, Parse, resists, `,
		result["to_"A_LoopField "_resistance"] := 0 ;set stats to 0 as a baseline

	Loop, Parse, attributes, `,
		result["to_"A_LoopField] := 0 ;set stats to 0 as a baseline

	Loop, Parse, string, `n, `r ;remove roll-ranges from the item-data
	{
		If InStr(A_LoopField, "{") || (A_LoopField = "")
			continue
		Loop, % LLK_InStrCount(A_LoopField, "(")
			parse_remove%A_Index% := SubStr(A_LoopField, InStr(A_LoopField, "(",,, A_Index), InStr(A_LoopField, ")",,, A_Index) - InStr(A_LoopField, "(",,, A_Index) + 1)
		loop := 1
		parse := A_LoopField
		loopfield_copy := A_LoopField
		While InStr(parse, parse_remove%loop%) && (parse_remove%loop% != "")
		{
			If (A_Index > LLK_InStrCount(loopfield_copy, "("))
				break
			parse := InStr(parse, " " parse_remove%loop%) ? StrReplace(parse, " " parse_remove%loop%) : StrReplace(parse, parse_remove%loop%)
			loop += 1
		}
		gear_clip .= parse "`n" ;create new string without roll-ranges
	}

	Loop, Parse, gear_clip, `n ;parse the new string
	{
		If (A_LoopField = "") || ((item_type = "attack") && InStr(A_LoopField, "adds ") && InStr(A_LoopField, "damage") && !InStr(A_LoopField, "spell"))
		|| ((item_type = "attack") && InStr(A_LoopField, "increased physical damage")) ;skip flat and % dmg mods since dps comparison already covers potential losses of desired mods
			continue

		loopfield_original := A_LoopField
		If (InStr(A_LoopField, "adds") || InStr(A_LoopField, "added")) && InStr(A_LoopField, "to") ;mods with 'x to y' need a backup string to save their text (because of reasons I can't fully remember)
		{
			loopfield_copy := A_LoopField
			Loop, Parse, loopfield_copy
			{
				If (A_Index = 1)
					loopfield_copy := ""
				If LLK_IsType(A_LoopField, "alpha")
					loopfield_copy .= StrReplace(A_LoopField, " ", "_")
			}
		}
		While InStr(loopfield_copy, "__")
			loopfield_copy := StrReplace(loopfield_copy, "__", "_")
		While (SubStr(loopfield_copy, 1, 1) = "_")
			loopfield_copy := SubStr(loopfield_copy, 2)

		Loop, Parse, % (InStr(A_LoopField, "adds") || InStr(A_LoopField, "added")) && InStr(A_LoopField, "to") ? StrReplace(A_LoopField, " to ", "|",, 1) : A_LoopField
		{
			If (A_Index = 1)
			{
				parse := ""
				parse_name := ""
			}
			If IsNumber(A_LoopField) || (A_LoopField = "|") || (A_LoopField = ".")
				parse .= A_LoopField
			If LLK_IsType(A_LoopField, "alpha")
				parse_name .= StrReplace(A_LoopField, " ", "_")
			;If (A_LoopField = "%")
			;	parse_name .= "percent_"
		}
		If InStr(parse, "|")
			parse := Format("{:0.0f}", (SubStr(parse, 1, InStr(parse, "|") - 1) + SubStr(parse, InStr(parse, "|") + 1)) / 2)

		While InStr(parse_name, "__")
			parse_name := StrReplace(parse_name, "__", "_")
		While (SubStr(parse_name, 1, 1) = "_")
			parse_name := SubStr(parse_name, 2)

		If (parse = "") ;if mod is not numeric, save it as 'absolute', e.g. "hits cannot be evaded"
			%parse_name% := "absolute"
		Else
		{
			If InStr(parse_name, "all_attributes") ;if the mod is +x to all attributes, add x to every attribute
			{
				Loop, Parse, attributes, `,
					result["to_"A_LoopField] += parse
			}
			Else If (InStr(parse_name, "strength") || InStr(parse_name, "dexterity") || InStr(parse_name, "intelligence")) && InStr(parse_name, "and") ;for hybrid attribute-mods, add x to the corresponding attributes
			{
				Loop, Parse, attributes, `,
				{
					If InStr(parse_name, A_LoopField)
						result["to_"A_LoopField] += parse
				}
				continue
			}
			Else If InStr(parse_name, "all_elemental") && !InStr(parse_name, "minion") ;for all-res mods, add x to every resistance
			{
				Loop, Parse, resists, `,
				{
					If (A_LoopField = "chaos")
						continue
					result["to_"A_LoopField "_resistance"] += parse
				}
				continue
			}
			Else If (InStr(parse_name, "resistance") && InStr(parse_name, "and") && !InStr(parse_name, "minion") && !InStr(parse_name, "maximum")) ;for hybrid res-mods, add x to the corresponding resistances
			{
				Loop, Parse, resists, `,
				{
					If InStr(parse_name, A_LoopField)
						result["to_"A_LoopField "_resistance"] += parse
				}
				continue
			}
			Else
			{
				If (InStr(loopfield_original, "adds") || InStr(loopfield_original, "added")) && InStr(loopfield_original, "to")
					%loopfield_copy% += parse
				Else %parse_name% += parse
			}
		}
		If (InStr(loopfield_original, "adds") || InStr(loopfield_original, "added")) && InStr(loopfield_original, "to")
			result[loopfield_copy] := %loopfield_copy%
		Else result[parse_name] := %parse_name%
	}

	For key, val in result ;parse all results and store them in a string
	{
		If (A_Index = 1)
			string := ""
		string .= key "=" val "`n"
	}
	While (SubStr(string, 0) = "`n")
		string := SubStr(string, 1, -1)
	Return string
}

LLK_PatternMatch(text, string, object, swap := 0, value := 1, case := 1) ;swap param switches the order around, val param determines if values or keys of the object are used
{
	local

	For index, val in object
	{
		val := value ? val : index
		check := swap ? val . string : string . val
		If InStr(text, check, case)
		{
			While (SubStr(val, 1, 1) = " ")
				val := SubStr(val, 2)
			Return InStr(val, " ") ? SubStr(val, 1, InStr(val, " ") - 1) : val
		}
	}
}

IteminfoModgroupCheck(name, mode := 0) ;check the affix-name to determine if the mods belongs to a certain mod-group
{
	local
	global settings

	If (settings.general.lang_client != "english")
		Return
	parse := "bestiary,delve,incursion,syndicate"
	If mode
		parse .= ",shaper,elder,crusader,redeemer,hunter,warlord,essence"
	bestiary := ["saqawal", "farrul", "craiceann", "fenumus"]
	delve := ["subterranean", "of the underground"]
	incursion := ["Citaqualotl", "Guatelitzi", "Matatl", "Tacati", "Topotante", "Xopec"]
	syndicate := ["chosen", "veil", "of the order"]
	shaper := ["shaper", "shaping"]
	elder := ["elder"]
	crusader := ["crusader", " crusade"]
	redeemer := ["redeemer", "redemption"]
	hunter := ["hunter's", " hunt"]
	warlord := ["warlord", "conquest"]
	essence := ["essences", " essence"]

	Loop, Parse, parse, `,
		For key, val in %A_LoopField%
			If InStr(name, val) && !InStr(name, "flame shaper's")
				Return A_LoopField
}

IteminfoModHighlight(string, mode := 0, implicit := 0) ;check if mod is highlighted or blacklisted
{
	local
	global vars, settings

	item := vars.iteminfo.item, highlight := vars.iteminfo.highlight, blacklist := vars.iteminfo.blacklist ;short-cut variables
	itemchecker_highlight_parse := "+-.()%", itemchecker_rule_applies := ""
	implicit_check := !implicit ? "global" : "implicits" ;simple flag to facilitate handling objects
	string := InStr(string, ":") ? SubStr(string, InStr(string, ":") + 2) : string, string := StrReplace(string, "`n", ";")
	string := StrReplace(string, " (fractured)"), string := StrReplace(string, " (crafted)")

	If LangMatch(string, vars.lang.mods_eldritch_targets, 0) ;remove singular/plural distinction from this mod so they don't have to be highlighted as (un)desired separately
		For index, val in vars.lang.mods_eldritch_targets
			string := (A_Index = 1) ? "" : string, string .= val

	string := IteminfoModRemoveRange(string)
	Loop, Parse, string ;parse string handed to function character by character
	{
		If (A_Index = 1)
			string := "" ;clear string
		If !IsNumber(A_LoopField) && !InStr(itemchecker_highlight_parse, A_LoopField) ;remove numbers and numerical signs
			string .= A_LoopField
	}

	While (SubStr(string, 1, 1) = " ")
		string := SubStr(string, 2)
	While (SubStr(string, 0, 1) = " ")
		string := SubStr(string, 1, -1)
	While InStr(string, "  ")
		string := StrReplace(string, "  ", " ")

	string := StrReplace(string, "; ", ";")

	If (mode = "parse")
		Return string

	If !implicit ;if mod is not an implicit, check if global rules/overrides apply
	{
		If settings.iteminfo.rules.hitgain && (InStr(string, "life per enemy") || InStr(string, "mana per enemy"))
			itemchecker_rule_applies := -1
		If settings.iteminfo.rules.spells && (InStr(string, " to spell") || (InStr(string, "spell damage") && !InStr(string, "suppress") && !InStr(string, "block")) || InStr(string, " for spell")
		|| InStr(string, "spell skill") || InStr(string, "added spell") || (InStr(string, "with spell") && !InStr(string, "gain ")))
			itemchecker_rule_applies := -1
		If settings.iteminfo.rules.attacks && (InStr(string, "increased physical damage") || (InStr(string, "adds") && InStr(string, " damage") && !InStr(string, "to spell") && (item.type = "attack"))
		|| ((InStr(string, "increased") || InStr(string, "added") || InStr(string, "adds")) && (InStr(string, "with") && !InStr(string, "speed") || InStr(string, "to")) && InStr(string, " attack")) || InStr(string, "attack damage"))
			itemchecker_rule_applies := -1
		If settings.iteminfo.rules.crit && (InStr(string, "critical strike"))
			itemchecker_rule_applies := -1

		If (item.type = "attack") || (itemchecker_rule_applies != "")
		{
			If (itemchecker_rule_applies = "") && settings.iteminfo.rules.res_weapons && (InStr(string, "resistance") && !InStr(string, "penetrate"))
				itemchecker_rule_applies := -1
			If (itemchecker_rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip(LangTrans("iteminfo_ruleblock"),,,,, "red")
					Return -1
				}
				Return itemchecker_rule_applies
			}
		}

		If (item.type = "defense") || (item.type = "jewelry")
		{
			If settings.iteminfo.rules.res && InStr(string, "to ") && InStr(string, " resistance") && !InStr(string, "minion")
				itemchecker_rule_applies := "+1"
			If (itemchecker_rule_applies != "")
			{
				If (mode != 0)
				{
					LLK_ToolTip(LangTrans("iteminfo_ruleblock"),,,,, "red")
					Return -1
				}
				Return itemchecker_rule_applies
			}
		}
	}

	If (mode = 0) ;check if mod is highlighted/blacklisted in order to determine color
	{
		If !implicit && (item.class != "") && (item.class_copy != "")
		{
			If highlight[item.class_copy].HasKey(string) ;explicit is marked as desired (class-specific)
				Return +2
			Else If blacklist[item.class_copy].HasKey(string) ;explicit is marked as undesired (class-specific)
				Return -2
		}
		If implicit && !highlight.implicits.HasKey(string) && !blacklist.implicits.HasKey(string) ;implicit is not marked
			Return 0
		If !implicit && !highlight.global.HasKey(string) && !blacklist.global.HasKey(string) && !highlight[item.class].HasKey(string) && !blacklist[item.class].HasKey(string) ;explicit is not marked
			Return 0
		Else If highlight[implicit_check].HasKey(string) ;mod is desired (global)
			Return +1
		Else If blacklist[implicit_check].HasKey(string) ;mod is undesired (global)
			Return -1
	}

	If (mode = 1) ;mod was left-clicked
	{
		If !implicit && (highlight[item.class_copy].HasKey(string) || blacklist[item.class_copy].HasKey(string))
		{
			LLK_ToolTip(LangTrans("iteminfo_clearfirst"), 1.5,,,, "yellow")
			Return -1
		}
		If !IsObject(highlight[implicit_check])
			highlight[implicit_check] := {}
		If !highlight[implicit_check].HasKey(string) ;mod is not highlighted: add it to highlighted mods and save
		{
			highlight[implicit_check][string] := 1
			IniWrite, % IteminfoModHighlightString(highlight[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "highlight" : "highlight implicits"
			If blacklist[implicit_check].HasKey(string) ;if mod was previously blacklisted, remove it from there and save the blacklist
			{
				blacklist[implicit_check].Delete(string)
				IniWrite, % IteminfoModHighlightString(blacklist[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "blacklist" : "blacklist implicits"
			}
			Return 1
		}
		Else ;mod is highlighted: remove it from highlighted mods and save
		{
			highlight[implicit_check].Delete(string)
			IniWrite, % IteminfoModHighlightString(highlight[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "highlight" : "highlight implicits"
			Return 0
		}
	}
	Else If (mode = -1) ;mod was long-leftclicked
	{
		If !IsObject(highlight[item.class_copy])
			highlight[item.class_copy] := {}
		If !highlight[item.class_copy].HasKey(string) ;mod is not highlighted: add it to class-specific highlighted mods and save
		{
			highlight[item.class_copy][string] := 1
			IniWrite, % IteminfoModHighlightString(highlight[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "highlight "item.class_copy
			If blacklist[item.class_copy].HasKey(string) ;if mod was previously blacklisted, remove it from there and save the blacklist
			{
				blacklist[item.class_copy].Delete(string)
				IniWrite, % IteminfoModHighlightString(blacklist[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "blacklist "item.class_copy
			}
			Return 2
		}
		Else ;mod is highlighted: remove it from class-specific highlighted mods and save
		{
			highlight[item.class_copy].Delete(string)
			IniWrite, % IteminfoModHighlightString(highlight[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "highlight "item.class_copy
			Return 0
		}
	}
	If (mode = 2) ;mod was right-clicked
	{
		If !implicit && (blacklist[item.class_copy].HasKey(string) || highlight[item.class_copy].HasKey(string))
		{
			LLK_ToolTip(LangTrans("iteminfo_clearfirst"), 1.5,,,, "yellow")
			Return -1
		}
		If !IsObject(blacklist[implicit_check])
			blacklist[implicit_check] := {}
		If !blacklist[implicit_check].HasKey(string) ;mod is not blacklisted: add it to blacklisted mods and save
		{
			blacklist[implicit_check][string] := 1
			IniWrite, % IteminfoModHighlightString(blacklist[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "blacklist" : "blacklist implicits"
			If highlight[implicit_check].HasKey(string) ;if mod was previously highlighted, remove it from there and save the highlights
			{
				highlight[implicit_check].Delete(string)
				IniWrite, % IteminfoModHighlightString(highlight[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "highlight" : "highlight implicits"
			}
			Return 1
		}
		Else ;mod is blacklisted: remove it from blacklisted mods and save
		{
			blacklist[implicit_check].Delete(string)
			IniWrite, % IteminfoModHighlightString(blacklist[implicit_check]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % !implicit ? "blacklist" : "blacklist implicits"
			Return 0
		}
	}
	Else If (mode = -2) ;mod was long-rightclicked
	{
		If !IsObject(blacklist[item.class_copy])
			blacklist[item.class_copy] := {}
		If !blacklist[item.class_copy].HasKey(string) ;mod is not blacklisted: add it to class-specific blacklisted mods and save
		{
			blacklist[item.class_copy][string] := 1
			IniWrite, % IteminfoModHighlightString(blacklist[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "blacklist "item.class_copy
			If highlight[item.class_copy].HasKey(string) ;if mod was previously highlighted, remove it from there and save the highlights
			{
				highlight[item.class_copy].Delete(string)
				IniWrite, % IteminfoModHighlightString(highlight[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "highlight "item.class_copy
			}
			Return 2
		}
		Else ;mod is blacklisted: remove it from class-specific blacklist and save
		{
			blacklist[item.class_copy].Delete(string)
			IniWrite, % IteminfoModHighlightString(blacklist[item.class_copy]), ini\item-checker.ini, % "highlighting "settings.iteminfo.profile, % "blacklist "item.class_copy
			Return 0
		}
	}
}

IteminfoModHighlightString(object) ;dump highlighting info into a string in order to save it in the ini-file
{
	local

	For key in object
		string .= "|" key "|"
	Return string
}

IteminfoModInvert(cHWND)
{
	local
	global vars, settings

	mod := LLK_HasVal(vars.hwnd.iteminfo.inverted_mods, cHWND)

	If InStr(A_ThisHotkey, "RButton") && !vars.iteminfo.inverted_mods[mod] || InStr(A_ThisHotkey, "LButton") && vars.iteminfo.inverted_mods[mod]
		Return

	If InStr(A_ThisHotkey, "RButton")
		vars.iteminfo.inverted_mods.Delete(mod)
	Else vars.iteminfo.inverted_mods[mod] := 1
	For key, val in vars.iteminfo.inverted_mods
		string .= "|" key "|"
	IniWrite, % string, ini\item-checker.ini, inverted mods, invert
	Iteminfo(1)
}

IteminfoModRemoveRange(string) ;takes mod-text string and returns it without roll-ranges
{
	local

	Loop, % LLK_InStrCount(string, "(")
	{
		parse_remove%A_Index% := SubStr(string, InStr(string, "(",,, A_Index), InStr(string, ")",,, A_Index) - InStr(string, "(",,, A_Index) + 1)
		removed_text .= parse_remove%A_Index% ","
	}
	loop := 1
	parse := string
	string_copy := string
	While InStr(parse, parse_remove%loop%) && (parse_remove%loop% != "")
	{
		If InStr(parse_remove%loop%, " sec)")
		{
			loop += 1
			continue
		}
		If (A_Index > LLK_InStrCount(string_copy, "("))
			break
		parse := InStr(parse, " " parse_remove%loop%) ? StrReplace(parse, " " parse_remove%loop%) : StrReplace(parse, parse_remove%loop%)
		loop += 1
	}
	Return parse
}

IteminfoGearParse(slot) ;parse the info of an equipped item and save it for item-comparisons
{
	local
	global vars, settings

	Loop, Parse, A_ThisHotkey
	{
		If (A_Index = 1)
			hotkey := ""
		If LLK_IsType(A_LoopField, "alpha")
			hotkey .= A_LoopField
	}

	start := A_TickCount
	While GetKeyState(hotkey, "P")
	{
		If (A_TickCount >= start + 250)
		{
			pass := 1
			Break
		}
	}

	If !pass
		Return

	If !WinActive("ahk_id "vars.hwnd.poe_client) ;activate the game-client in case it's not active (item-info cannot be copied from an inactive client)
	{
		WinActivate, % "ahk_id "vars.hwnd.poe_client
		WinWaitActive, % "ahk_id "vars.hwnd.poe_client
	}

	If (hotkey = "RButton") ;clear the info for the hovered gear-slot
	{
		vars.iteminfo.compare.slots[slot].equipped := ""
		If FileExist("ini\item-checker gear.ini")
			IniDelete, ini\item-checker gear.ini, % slot
		LLK_ToolTip(slot " cleared")
		If WinExist("ahk_id "vars.hwnd.iteminfo.main)
			Iteminfo(1)
		KeyWait, % hotkey
		Return
	}

	Clipboard := ""
	If settings.hotkeys.rebound_alt && settings.hotkeys.item_descriptions
		SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
	Else SendInput, !^{c}
	ClipWait, 0.1

	If !Clipboard
	{
		LLK_ToolTip(LangTrans("omnikey_copyfail"), 2,,,, "red")
		Return
	}

	snip := SubStr(Clipboard, InStr(Clipboard, "item level: ")) ;lower part of the item's information
	item_type := InStr(Clipboard, "attacks per second: ") ? "attack" : ""

	Loop, Parse, Clipboard, `n, `r ;parse the item's defenses (not actually used at the moment)
	{
		If InStr(A_LoopField, "armour: ")
		{
			armor := StrReplace(A_LoopField, " (augmented)")
			armor := SubStr(armor, 9)
			defenses .= "armor,"
		}
		If InStr(A_LoopField, "evasion rating: ")
		{
			evasion := StrReplace(A_LoopField, " (augmented)")
			evasion := SubStr(evasion, 17)
			defenses .= "evasion,"
		}
		If InStr(A_LoopField, "energy shield: ")
		{
			energy := StrReplace(A_LoopField, " (augmented)")
			energy := SubStr(energy, 16)
			defenses .= "energy,"
		}
		If InStr(A_LoopField, "ward: ")
		{
			ward := StrReplace(A_LoopField, " (augmented)")
			ward := SubStr(ward, 7)
			defenses .= "ward,"
		}
		If InStr(A_LoopField, "requirements: ")
			break
	}

	Loop, Parse, defenses, `,
	{
		If (A_Index = 1)
			defenses := ""
		If (A_LoopField = "")
			continue
		defenses .= A_LoopField "=" %A_LoopField% "`n"
	}

	If InStr(Clipboard, "attacks per second: ") ;get the item's DPS
	{
		item_type := "attack"
		phys_dmg := 0
		pdps := 0
		ele_dmg := 0
		ele_dmg3 := 0
		ele_dmg4 := 0
		ele_dmg5 := 0
		edps0 := 0
		chaos_dmg := 0
		cdps := 0
		speed := 0
		Loop, Parse, clipboard, `n, `r
		{
			If InStr(A_LoopField,"Physical Damage: ")
			{
				phys_dmg := A_LoopField
				Loop, Parse, phys_dmg, " "
					If (A_Index=3)
						phys_dmg := A_LoopField
			}
			If InStr(A_LoopField,"Elemental Damage: ")
			{
				ele_dmg := StrReplace(A_LoopField, "`r`n")
				ele_dmg := StrReplace(ele_dmg, " (augmented)")
				ele_dmg := StrReplace(ele_dmg, ",")
				Loop, Parse, ele_dmg, " "
					If A_Index between 3 and 5
						ele_dmg%A_Index% := A_LoopField
			}
			If InStr(A_LoopField, "Chaos Damage: ")
			{
				chaos_dmg := StrReplace(A_LoopField, "`r`n")
				chaos_dmg := StrReplace(chaos_dmg, " (augmented)")
				Loop, Parse, chaos_dmg, " "
					If (A_Index=3)
						chaos_dmg := A_LoopField
			}
			If InStr(A_LoopField, "Attacks per Second: ")
			{
				speed := A_LoopField
				Loop, Parse, speed, " "
					If (A_Index=4)
						speed := SubStr(A_LoopField,1,4)
				break
			}
		}
		If (phys_dmg!=0)
		{
			Loop, Parse, phys_dmg, "-"
				phys%A_Index% := A_LoopField
			pdps := ((phys1+phys2)/2)*speed
			pdps := Format("{:0.2f}", pdps)
		}
		If (ele_dmg!=0)
		{
			edps2 := 0
			edps3 := 0
			Loop, Parse, ele_dmg3, "-"
				ele_dmg3_%A_Index% := A_LoopField
			edps1 := ((ele_dmg3_1+ele_dmg3_2)/2)*speed
			If (ele_dmg4!=0)
			{
				Loop, Parse, ele_dmg4, "-"
					ele_dmg4_%A_Index% := A_LoopField
				edps2 := ((ele_dmg4_1+ele_dmg4_2)/2)*speed
			}
			If (ele_dmg5!=0)
			{
				Loop, Parse, ele_dmg5, "-"
					ele_dmg5_%A_Index% := A_LoopField
				edps3 := ((ele_dmg5_1+ele_dmg5_2)/2)*speed
			}
			edps0 := edps1+edps2+edps3
			edps0 := Format("{:0.2f}", edps0)
		}
		If (chaos_dmg!=0)
		{
			Loop, Parse, chaos_dmg, "-"
				chaos_dmg%A_Index% := A_LoopField
			cdps := ((chaos_dmg1+chaos_dmg2)/2)*speed
			cdps := Format("{:0.2f}", cdps)
		}
		tdps := pdps+edps0+cdps
		tdps := Format("{:0.2f}", tdps)
		all_dps := pdps "," edps0 "," cdps
		edps := edps0
		dps := tdps
	}

	itemcheck_clip := SubStr(StrReplace(Clipboard, " — " LangTrans("items_unscalable")), InStr(Clipboard, "item level:"))
	item_lvl := SubStr(itemcheck_clip, 1, InStr(itemcheck_clip, "`r`n",,, 1) - 1)
	item_lvl := StrReplace(item_lvl, "item level: ")
	itemcheck_clip := StrReplace(itemcheck_clip, "`r`n", "|") ;combine single item-info lines into affix groups
	StringLower, itemcheck_clip, itemcheck_clip

	itemcheck_parse := "(-.)|[]%" ;characters that indicate numerical values/strings
	loop := 0 ;count affixes
	unique := InStr(Clipboard, LangTrans("items_rarity") " " LangTrans("items_unique")) ? 1 : 0 ;is item unique?

	Loop, Parse, itemcheck_clip, | ;remove unnecessary item-info: implicits, crafted mods, etc.
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If InStr(A_LoopField, "{ implicit modifier ")
		{
			parse := StrReplace(A_LoopField, "to accuracy rating", "to local accuracy rating")
			implicits .= StrReplace(parse, " (implicit)") "`n"
		}
		;If InStr(A_LoopField, "crafted")
		;	crafted_mods .= StrReplace(A_LoopField, " (crafted)") "`n"

		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") || InStr(A_LoopField, "{ Allocated Crucible") ;|| InStr(A_LoopField, "crafted")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}

	Loop, Parse, implicits, `n
	{
		If (A_Index = 1)
			implicits := ""
		If (SubStr(A_LoopField, 1, 1) = "{")
			continue
		implicits .= A_LoopField "`n"
	}

	While (SubStr(implicits, 0) = "`n")
		implicits := SubStr(implicits, 1, -1)

	Loop, Parse, itemcheck_clip, `n ;remove tooltips from item-info
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "(")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}

	itemcheck_clip := StrReplace(itemcheck_clip, " (fractured)")
	itemcheck_clip := StrReplace(itemcheck_clip, " (crafted)")

	Loop, Parse, itemcheck_clip, `n
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "{")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}

	While (SubStr(itemcheck_clip, 0) = "`n")
		itemcheck_clip := SubStr(itemcheck_clip, 1, -1)

	vars.iteminfo.compare.slots[slot].equipped := (item_type = "attack") ? "dps="tdps "`npdps="pdps "`nedps="edps0 "`ncdps="cdps "`nspeed=" speed "`n" IteminfoCompare(implicits "`n" itemcheck_clip, item_type) : defenses IteminfoCompare(implicits "`n" itemcheck_clip, item_type)
	IniWrite, % vars.iteminfo.compare.slots[slot].equipped, ini\item-checker gear.ini, % slot
	Loop, Parse, % vars.iteminfo.compare.slots[slot].equipped, `n
	{
		If (A_Index = 1)
			vars.iteminfo.compare.slots[slot].equipped := {}
		If Blank(A_LoopField)
			Continue
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1)
		vars.iteminfo.compare.slots[slot].equipped[key] := val
	}
	LLK_ToolTip(slot " updated")
	If WinExist("ahk_id " vars.hwnd.iteminfo.main)
		Iteminfo(1)
	KeyWait, % hotkey
}

IteminfoHighlightApply(cHWND) ;apply (un)desired highlighting to a mod by clicking the rectangles while hovering over them
{
	local
	global vars, settings

	hotkey := A_ThisHotkey, check := LLK_HasVal(vars.hwnd.iteminfo, cHWND), start := A_TickCount, mode := InStr(A_ThisHotkey, "LButton") ? 1 : 2
	Loop, Parse, % "*^!+~"
		hotkey := StrReplace(hotkey, A_LoopField)
	While GetKeyState(hotkey, "P") && !InStr(check, "implicit_")
		If (A_TickCount >= start + 250)
		{
			mode := -mode
			Break
		}

	If check && (IteminfoModHighlight(StrReplace(check, "implicit_"), mode, InStr(check, "implicit_")) >= 0)
		Iteminfo(1)
	KeyWait, % hotkey
}

IteminfoMarker() ;placing markers while using the shift-trigger feature
{
	local
	global vars, settings

	If !WinExist("ahk_id "vars.hwnd.iteminfo.main) && !WinExist("ahk_id "vars.hwnd.iteminfo_markers.1)
		Return
	If !IsObject(vars.hwnd.iteminfo_markers)
		vars.hwnd.iteminfo_markers := []

	MouseGetPos, x, y
	dimensions := vars.client.h*0.047/2, count := vars.hwnd.iteminfo_markers.Count() + 1

	Gui, iteminfo_marker%count%: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd
	Gui, iteminfo_marker%count%: Margin, 0, 0
	Gui, iteminfo_marker%count%: Color, Red
	WinSet, Trans, 250
	Gui, iteminfo_marker%count%: Add, Text, % "Center BackgroundTrans Border w"dimensions " h"dimensions,
	Gui, iteminfo_marker%count%: Show, % "NA x"x - dimensions/2 " y"y - dimensions/2
	vars.hwnd.iteminfo_markers.Push(hwnd)
}

IteminfoModCheck(string, item_type := "") ;checks a mod's text to determine if there's a suitable icon to represent the mod
{
	local
	global settings

	If (settings.general.lang_client != "english")
		Return
	resists := "fire,lightning,cold,chaos"
	stats := "strength,dexterity,intelligence"
	Loop, Parse, string, `n
	{
		If (A_LoopField = "")
			continue

		If (item_type = "attack")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, "adds ") && InStr(string, A_LoopField) && InStr(string, "damage") && !InStr(string, "spells")
					Return A_LoopField "_attack"
			}
			If (InStr(string, "adds ") && InStr(string, "physical") && InStr(string, "damage") && !InStr(string, "spells")) || InStr(string, "increased physical damage")
				Return "phys"
		}

		If InStr(string, "minion")
			Return "minion"
		Else If InStr(string, "totem")
			Return "totems"
		Else If InStr(string, "increased") && InStr(string, "damage")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_damage"
			}
			If InStr(string, "spell")
				Return "spell_damage"
			If InStr(string, "global physical")
				Return "phys"
		}
		Else If InStr(string, "adds") && InStr(string, "damage") && InStr(string, "to spells")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_spell"
			}
			If InStr(string, "physical")
				Return "phys_spell"
		}
		Else If InStr(string, "adds") && InStr(string, "damage to attacks")
		{
			Loop, Parse, resists, `,
			{
				If InStr(string, A_LoopField)
					Return A_LoopField "_attack"
			}
			If InStr(string, "physical")
				Return "phys"
		}
		Else If InStr(string, "critical strike")
			Return "crit"
		Else If InStr(string, "attack speed")
			Return "speed"
		Else If InStr(string, "all elemental resistances") && !InStr(string, "penetrate")
			Return "allres"
		Else If InStr(string, "all attributes") || InStr(string, "increased attributes")
			Return "allstats"
		Else if InStr(string, "to maximum life") || InStr(string, "increased maximum life")
			Return "life"

		Loop, Parse, % resists "," stats, `,
		{
			If InStr(string, A_LoopField) && !InStr(string, " and ") && ((InStr(resists, A_LoopField) && InStr(string, "resistance") && !InStr(string, " enem") && !InStr(string, "penetrate")) || InStr(stats, A_LoopField))
				Return A_LoopField
			Else If InStr(string, A_LoopField) && InStr(stats, A_LoopField) && InStr(string, " and ")
				Return "allstats"
		}

		If InStr(string, "armour and evasion")
			Return "armor_evasion"
		If InStr(string, "armour and energy")
			Return "armor_energy"
		If InStr(string, "evasion and energy")
			Return "evasion_energy"

		If InStr(string, "+") && InStr(string, "to armour") && InStr(string, "to evasion rating")
			Return "armor_evasion"
		If InStr(string, "+") && InStr(string, "to armour") && InStr(string, "to maximum energy shield")
			Return "armor_energy"
		If InStr(string, "+") && InStr(string, "to evasion rating") && InStr(string, "to maximum energy shield")
			Return "evasion_energy"

		If (InStr(string, "increased ") && (InStr(string, "armour"))) || (InStr(string, "+") && InStr(string, " to ") && (InStr(string, "armour")))
			Return "armor"
		If (InStr(string, "increased ") && InStr(string, "evasion")) || (InStr(string, "+") && InStr(string, " to ") && InStr(string, "evasion"))
			Return "evasion"
		If InStr(string, "+") && InStr(string, "to maximum energy shield") || (InStr(string, "increased energy shield") && !InStr(string, "recharge")) || InStr(string, "increased maximum energy shield")
			Return "energy"
		If InStr(string, "+") && InStr(string, "to ward") || (InStr(string, "increased ward"))
			Return "ward"

		If InStr(string, " block") && !InStr(string, "block recovery")
			Return "block"

		If InStr(string, "to maximum mana") || InStr(string, "increased maximum mana")
			Return "mana"

		If InStr(string, "regenerate") && InStr(string, "mana per second") || InStr(string, "increased mana regeneration rate")
			Return "mana_regen"

		If InStr(string, "flask")
			Return "flasks"

		If InStr(string, "regenerate") && InStr(string, "life per second") || InStr(string, "increased life regeneration rate")
			Return "life_regen"

		If InStr(string, "to level of ") && InStr(string, " gem")
			Return "gem_level"
	}
}

IteminfoModCheckInvert(mod)
{
	local
	global settings

	If (settings.general.lang_client != "english")
		Return
	If InStr(mod, "(-") && InStr(mod, "damage taken") || StrMatch(mod, "lose")
	|| (InStr(mod, "you ") || InStr(mod, "summoned ")) && InStr(mod, "take") && InStr(mod, "damage") && !InStr(mod, "reduced")
	|| (InStr(mod, "+") || InStr(mod, "increased")) && ((InStr(mod, "strength") || InStr(mod, "dexterity") || InStr(mod, "intelligence") || InStr(mod, "attribute")) && InStr(mod, "requirement") || InStr(mod, "damage taken") && !InStr(mod, "taken to enem") || InStr(mod, "charges per use"))
	|| (InStr(mod, "reduced") || InStr(mod, "less")) && (InStr(mod, "elemental resistances") || InStr(mod, "life") || (!InStr(mod, "take") && InStr(mod, "damage")) || InStr(mod, "rarity") || InStr(mod, "quantity") || (!InStr(mod, "enem") && InStr(mod, "stun and block"))
	|| (!InStr(mod, "--") && InStr(mod, "skill effect duration")) || InStr(mod, "cast speed") || InStr(mod, "maximum mana") || InStr(mod, "throwing speed") || InStr(mod, "strength") || InStr(mod, "dexterity") || InStr(mod, "intelligence") || InStr(mod, "amount recovered")
	|| InStr(mod, "recovery rate") || InStr(mod, "duration"))
	Return 1
	Else Return 0
}

IteminfoModRollCheck(mod) ;parses a mod's text and returns an array with information on how well it's rolled
{
	local

	mod := StrReplace(StrReplace(mod, " (crafted)"), " (fractured)")
	rolls := [], sum_min := 0, sum_current := 0, sum_max := 0

	If !InStr(mod, "(")
		Return [0, 1, 1]

	Loop, Parse, % StrReplace(mod, "non-") " " ;parse the mod-text character by character (the added space is a workaround for languages with different format, e.g. Japanese: Accuracy +X, where parsing would end prematurely due to EoL)
	{
		If !LLK_IsType(A_LoopField, "number") && !InStr("(-).", A_LoopField) ;if current character is not a number or numeric sign
		{
			If parse ;if numbers have already been parsed from the string, push the number-string into the array and 'open a new slot'
			{
				If (parse = "-")
					Continue
				rolls.Push(parse)
				parse := ""
			}
			Continue
		}
		parse .= A_LoopField ;collect numbers in string
	}

	For key, val in rolls ;parse through the collected numbers
	{
		min := InStr(val, "(") ? SubStr(val, InStr(val, "(") + 1) : val ;declare the min-roll (either within potential brackets, or the number itself)
		If (SubStr(min, 1, 1) = "-")
			min := InStr(min, ")") ? SubStr(min, 1, InStr(min, "-",,, 2) - 1) : min
		Else min := InStr(min, ")") ? SubStr(min, 1, InStr(min, "-") - 1) : min
		current := InStr(val, "(") ? SubStr(val, 1, InStr(val, "(") - 1) : val ;declare the current roll
		max := InStr(val, "(") ? StrReplace(val, current "(" min "-") : val , max := StrReplace(max, ")") ;declare the max-roll
		If !IsNumber(min + current + max)
			Return ["", "", ""]
		sum_min += min, sum_current += current, sum_max += max ;if the mod as multiple ranges, sum up the values
	}
	Return [sum_min, sum_current, sum_max]
}

IteminfoOverlays() ;show update buttons for specific gear-slots underneath the cursor
{
	local
	global vars, settings

	If settings.iteminfo.compare
		For slot, val in vars.iteminfo.compare.slots
		{
			If LLK_IsBetween(vars.general.xMouse, val.x1, val.x2) && LLK_IsBetween(vars.general.yMouse, val.y1, val.y2) && (vars.log.areaID != "login") && Screenchecks_PixelSearch("inventory")
			&& !WinExist("ahk_id "vars.hwnd.iteminfo_comparison[slot]) && (vars.general.wMouse != vars.hwnd.iteminfo.main) && (vars.general.wMouse != vars.hwnd.omni_context.main) && WinActive("ahk_group poe_window")
				LLK_Overlay(vars.hwnd.iteminfo_comparison[slot], "show",, "iteminfo_button_" slot)
			Else If WinExist("ahk_id " vars.hwnd.iteminfo_comparison[slot])
			&& (!(LLK_IsBetween(vars.general.xMouse, val.x1, val.x2) && LLK_IsBetween(vars.general.yMouse, val.y1, val.y2)) || (vars.general.wMouse = vars.hwnd.iteminfo.main) || (vars.general.wMouse = vars.hwnd.omni_context.main) || (vars.log.areaID = "login") || !WinActive("ahk_group poe_window") || !Screenchecks_PixelSearch("inventory"))
				LLK_Overlay(vars.hwnd.iteminfo_comparison[slot], "hide")
		}
}

IteminfoTrigger(mode := 0) ;handles shift-clicks on items and currency for the shift-trigger feature
{
	local
	global vars, settings
	static last := 0

	Clipboard := ""
	If mode
	{
		If (last + 500 > A_TickCount)
			Return
		last := A_TickCount
		Sleep 350
		If settings.hotkeys.rebound_alt && settings.hotkeys.item_descriptions
			SendInput, % "{" settings.hotkeys.item_descriptions " down}^{c}{" settings.hotkeys.item_descriptions " up}"
		Else SendInput, !^{c}
		ClipWait, 0.1
		If Clipboard
		{
			If settings.mapinfo.trigger && (OmniContext(1) = "mapinfo")
				IteminfoClose(), MapinfoParse(), MapinfoGUI()
			Else If settings.iteminfo.trigger
				LLK_Overlay(vars.hwnd.mapinfo.main, "destroy"), Iteminfo()
		}
		Return
	}
	Else
	{
		SendInput, ^{c}
		ClipWait, 0.1
	}

	If (settings.iteminfo.trigger || settings.mapinfo.trigger) && LLK_PatternMatch(Clipboard, LangTrans("items_rarity") " ", [LangTrans("items_currency")])
		vars.general.shift_trigger := 1
	Else Return
	KeyWait, Shift
	vars.general.shift_trigger := 0
	IteminfoClose(), LLK_Overlay(vars.hwnd.mapinfo.main, "destroy")
}
