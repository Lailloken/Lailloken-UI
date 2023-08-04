Init_legion(mode := "")
{
	local
	global vars, settings, db, Json
	
	If !mode
	{
		db.legion := Json.Load(LLK_FileRead("data\timeless jewels\jewels.json"))
		
		settings.legion := {"fSize": LLK_IniRead("ini\seed-explorer.ini", "settings", "font-size", settings.general.fSize)}
		LLK_FontDimensions(settings.legion.fSize, height, width), settings.legion.fWidth := width, settings.legion.fHeight := height
		settings.legion.profile := LLK_IniRead("ini\seed-explorer.ini", "settings", "profile", 1)

		vars.legion := {}
	}
	settings.legion.highlights := {}
	Loop, Parse, % LLK_IniRead("ini\seed-explorer.ini", "highlights profile "settings.legion.profile), `n
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), settings.legion.highlights[key] := val
}

Legion(cHWND := "")
{
	local
	global vars, settings, db

	check := LLK_HasVal(A_Gui = vars.hwnd.legion_tree.main ? vars.hwnd.legion_tree : vars.hwnd.legion, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If InStr(check, "profile_")
	{
		If (vars.system.click = 2) && LLK_Progress(vars.hwnd.legion["delbar_"control], "RButton")
		{
			IniDelete, ini\seed-explorer.ini, highlights profile %control%
			If (control = settings.legion.profile)
				settings.legion.highlights := {}
			LegionGUI()
			KeyWait, RButton
			Return
		}
		Else If (vars.system.click = 2)
			Return
		IniWrite, % control, ini\seed-explorer.ini, settings, profile
		settings.legion.profile := control, Init_legion("highlights"), LegionGUI()
	}
	Else If (check = "import")
	{
		If LegionParse()
			LegionGUI()
	}
	Else If (check = "trade")
	{
		conquerors := []
		For key, val in db.legion.jewels[vars.legion.jewel]
			If (key != "_decoder")
				conquerors.Push(val.1)
		legion_trade := "{%22query%22:{%22status%22:{%22option%22:%22any%22},%22stats%22:[{%22type%22:%22count%22,%22filters%22:[{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.1 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed
		. "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.2 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed
		. "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.3 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed "},%22disabled%22:false}],%22value%22:{%22min%22:1}}]},%22sort%22:{%22price%22:%22asc%22}}"
		Run, https://www.pathofexile.com/trade/search/?q=%legion_trade%
		Return
	}
	Else If (control = "+5 devotion")
		Return
	Else If InStr(check, "font_")
	{
		While GetKeyState("LButton")
		{
			If (control = "minus") && (settings.legion.fSize > 6)
				settings.legion.fSize -= 1
			Else If (control = "reset")
				settings.legion.fSize := settings.general.fsize
			Else If (control = "plus")
				settings.legion.fSize += 1
			GuiControl, text, % vars.hwnd.legion.font_reset, % settings.legion.fSize
			Sleep, 125
		}
		LLK_FontDimensions(settings.legion.fSize, height, width), settings.legion.fWidth := width, settings.legion.fHeight := height, vars.legion.fSize_tree := ""
		IniWrite, % settings.legion.fSize, ini\seed-explorer.ini, settings, font-size
		LegionGUI()
	}
	Else If InStr(check, "mod_")
	{
		If (vars.system.click = 1)
		{
			regex_string := "nota ^("
			KeyWait, LButton
			If !vars.legion.socket
				Return
			vars.legion.selection := control, LegionGUI()
			WinActivate, ahk_group poe_window
			WinWaitActive, ahk_group poe_window
			If vars.legion.nodes.HasKey(control)
				Clipboard := "^("StrReplace(control, " ", "\s") ")"
			Else
			{
				For index, val in LLK_HasVal(vars.legion.data.3, vars.legion.decoder_invert[control],,, 1)
					If LLK_HasVal(db.legion.sockets[vars.legion.socket].nodes, vars.legion.nodes_invert[val])
					{
						db_clone := db.legion.notables.Clone()
						Loop, Parse, % "mine", `;
							db_clone.Push(A_LoopField)
						check := CreateRegex(vars.legion.nodes_invert[val], db_clone)
						regex_string .= check ? StrReplace(check, " ", "\s") "|" : ""
					}
				Clipboard := SubStr(regex_string, 1, -1) ")"
			}
			SendInput, ^{f}^{a}^{v}{Enter}
		}
		Else If (vars.system.click = 2)
		{
			settings.legion.highlights[control] := settings.legion.highlights[control] ? 0 : 1
			IniWrite, % settings.legion.highlights[control], ini\seed-explorer.ini, % "highlights profile "settings.legion.profile, % control
			LegionGUI()
		}
	}
	Else If InStr(check, "socket_")
		vars.legion.socket := (vars.legion.socket != control) ? control : "", vars.legion.selection := "", LegionGUI()
	Else LLK_ToolTip("no action")
}

LegionGUI()
{
	local
	global vars, settings, db

	vars.legion.width := settings.legion.fWidth*29, LLK_Overlay(vars.hwnd.legion.tooltip, "destroy"), vars.legion.tooltip := "", vars.legion.wait := 1
	If !IsObject(vars.legion.nodes)
		Loop, Parse, % vars.legion.nodes, `,
		{
			If (A_Index = 1)
				vars.legion.nodes := {}, vars.legion.nodes_invert := []
			vars.legion.nodes[A_LoopField] := A_Index, vars.legion.nodes_invert.Push(A_LoopField)
		}
	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDlegion"
	Gui, %legion%: Color, Black
	Gui, %legion%: Margin, 0, 0
	Gui, %legion%: Font, % "s"settings.legion.fSize " cWhite", Fontin SmallCaps
	hwnd_old := vars.hwnd.legion.main, vars.hwnd.legion := {"main": legion, "old": hwnd_old, "tooltips": {}, "tooltips2": {}}
	
	Gui, %legion%: Add, Text, % "x"settings.legion.fWidth/2 " y"settings.legion.fWidth/2 " Section HWNDhwnd", % "profile: "
	ControlGetPos, xAnchor, yAnchor, wAnchor, hAnchor,, ahk_id %hwnd%
	Loop 5
	{
		Gui, %legion%: Add, Text, % "ys x+"(A_Index = 1 ? 0 : settings.legion.fWidth/4) " Border BackgroundTrans Center gLegion HWNDhwnd w"settings.legion.fWidth*2 (A_Index = settings.legion.profile ? " cFuchsia" : ""), % A_Index
		Gui, %legion%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed Range0-500 HWNDhwndbar", 0
		vars.hwnd.legion["profile_"A_Index] := hwnd, vars.hwnd.legion["delbar_"A_Index] := hwndbar
	}
	Gui, %legion%: Font, % "underline bold"
	Gui, %legion%: Add, Text, % "xs y+"settings.legion.fWidth/2, % "jewel:"
	Gui, %legion%: Font, % "norm"
	Gui, %legion%: Add, Text, % "xs y+0", % "type: "vars.legion.jewel
	Gui, %legion%: Add, Text, % "xs y+0", % "seed: "vars.legion.seed
	Gui, %legion%: Add, Text, % "xs y+0", % "conqueror: "vars.legion.leader

	Gui, %legion%: Add, Text, % "xs Center Border HWNDhwndimport gLegion", % " import "
	Gui, %legion%: Add, Text, % "x+"settings.legion.fWidth/2 " yp Center Border HWNDhwndtrade gLegion", % " trade-check "
	vars.hwnd.legion.import := vars.hwnd.help_tooltips["seed-explorer_import"] := hwndimport, vars.hwnd.legion.trade := vars.hwnd.help_tooltips["seed-explorer_trade"] := hwndtrade

	Gui, %legion%: Font, % "underline bold"
	Gui, %legion%: Add, Text, % "xs y+"settings.legion.fWidth, % "keystones:"
	Gui, %legion%: Font, % "norm"
	For keystone, val in db.legion.jewels[vars.legion.jewel]
		If !InStr(keystone, "decoder")
		{
			Gui, %legion%: Add, Text, % "xs HWNDhwnd y+0"(val.1 = vars.legion.leader ? " cLime" : ""), % keystone
			vars.hwnd.legion.tooltips[keystone] := hwnd
		}

	If vars.legion.socket
	{
		Gui, %legion%: Font, % "underline bold"
		Gui, %legion%: Add, Text, % "xs y+"settings.legion.fWidth, % "resulting notables:"
		Gui, %legion%: Font, % "norm"
		mods := {}
		For index, node in db.legion.sockets[vars.legion.socket].nodes
			text := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], mods[text] := mods[text] ? mods[text] + 1 : 1
		For mod, count in mods
		{
			Gui, %legion%: Add, Text, % "xs HWNDhwnd gLegion"(settings.legion.highlights[mod] ? " cAqua" : "") (vars.legion.selection = mod ? " Border" : ""), % mod " (" count ")"
			vars.hwnd.legion["mod_"mod] := hwnd
			If db.legion.jewels.descriptions.HasKey(mod)
				vars.hwnd.legion.tooltips[mod] := hwnd
		}
	}

	Gui, %legion%: Add, Text, % "x0 y0 Border BackgroundTrans w"vars.legion.width " h"vars.monitor.h - vars.legion.width + 1
	Gui, %legion%: Add, Pic, % "xp y+-1 Border HWNDhwnd w"vars.legion.width - 2 " h-1", img\GUI\legion_treemap.jpg
	vars.hwnd.legion.treemap := hwnd

	Gui, %legion%: Add, Text, % "Section x"xAnchor + vars.legion.width " y"yAnchor, % "text-size: "
	Gui, %legion%: Add, Text, % "ys x+0 Center Border gLegion HWNDhwnd w"settings.legion.fWidth*2, % "–"
	vars.hwnd.legion.font_minus := hwnd
	Gui, %legion%: Add, Text, % "ys x+"settings.legion.fWidth/4 " Center Border gLegion HWNDhwnd w"settings.legion.fWidth*3, % settings.legion.fSize
	vars.hwnd.legion.font_reset := hwnd
	Gui, %legion%: Add, Text, % "ys x+"settings.legion.fWidth/4 " Center Border gLegion HWNDhwnd w"settings.legion.fWidth*2, % "+"
	vars.hwnd.legion.font_plus := hwnd

	Gui, %legion%: Font, % "underline bold"
	Gui, %legion%: Add, Text, % "xs y+"settings.legion.fWidth/2, % vars.legion.socket ? "notables around socket:" : "jewel notables:"
	Gui, %legion%: Font, % "norm"

	If !vars.legion.socket
	{
		For index, mod in vars.legion.jewel_mods
		{
			Gui, %legion%: Add, Text, % "xs HWNDhwnd gLegion"(settings.legion.highlights[mod] ? " cAqua" : ""), % mod
			vars.hwnd.legion["mod_"mod] := hwnd
			If db.legion.jewels.descriptions.HasKey(mod)
				vars.hwnd.legion.tooltips[mod] := hwnd
		}
	}
	Else
		For index, node in db.legion.sockets[vars.legion.socket].nodes
		{
			mod := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]]
			color := settings.legion.highlights[node] && settings.legion.highlights[mod] ? " cYellow" : settings.legion.highlights[node] ? " cLime" : ""
			Gui, %legion%: Add, Text, % "xs HWNDhwnd gLegion"color (vars.legion.selection = node ? " Border" : ""), % node
			While vars.hwnd.legion.tooltips2.HasKey(mod)
				mod .= "_"
			vars.hwnd.legion["mod_"node] := hwnd, vars.hwnd.legion.tooltips2[mod] := hwnd
		}
		
	Gui, %legion%: Add, Text, % "x"vars.legion.width - 1 " y0 Border BackgroundTrans w"vars.legion.width " h"vars.monitor.h

	Gui, %legion%: Show, % "NA x10000 y10000 h"vars.monitor.h
	If (A_Gui = DummyGUI(vars.hwnd.legion_tree.main))
		Gui, % vars.hwnd.legion_tree.main ": +Owner"legion
	Gui, %legion%: Show, % "Hide x"vars.monitor.x " y"vars.monitor.y
	LLK_Overlay(legion, "show", 0), LLK_Overlay(hwnd_old, "destroy")
	If (A_Gui = DummyGUI(vars.hwnd.legion_tree.main))
		LegionTree()
	vars.legion.wait := 0
}

LegionHover()
{
	local
	global vars, settings, db
	static tooltip

	If vars.legion.wait
		Return
	ControlGetPos,, y,, h,, % "ahk_id "vars.general.cMouse
	check := LLK_HasVal(vars.hwnd.legion.tooltips, vars.general.cMouse), check2 := !check ? StrReplace(LLK_HasVal(vars.hwnd.legion.tooltips2, vars.general.cMouse), "_") : "0"
	If (vars.general.cMouse = vars.hwnd.legion.treemap) && !WinExist("ahk_id "vars.hwnd.legion_tree.main)
		LegionTree()
	Else If WinExist("ahk_id "vars.hwnd.legion_tree.main) && (vars.general.wMouse != vars.hwnd.legion_tree.main)
		LLK_Overlay(vars.hwnd.legion_tree.main, "destroy")

	If vars.general.cMouse && (check || check2) && (vars.legion.tooltip != check) && (vars.legion.tooltip != check2)
	{
		Gui, legion_tooltip: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDtooltip"
		Gui, legion_tooltip: Color, 202020
		Gui, legion_tooltip: Margin, 0, 0
		Gui, legion_tooltip: Font, % "s"settings.legion.fSize " cWhite", Fontin SmallCaps
		vars.hwnd.legion.tooltip := tooltip, parse := db.legion.jewels.descriptions[check ? check : check2] ? db.legion.jewels.descriptions[check ? check : check2].Clone() : []
		If check2
			parse.0 := "result:`n"check2
		For index, text in parse
			Gui, legion_tooltip: Add, Text, % (A_Index = 1 ? "" : "xs y+0") " Center Border w"settings.legion.fWidth*29 - 2, % text
		vars.legion.tooltip := check ? check : check2
		Gui, legion_tooltip: Show, % "NA x"(vars.general.xMouse - vars.monitor.x < vars.legion.width ? vars.monitor.x : vars.monitor.x + vars.legion.width - 1) " y"y + h + 1
	}
	Else If !check && !check2 && vars.legion.tooltip
		vars.legion.tooltip := "", LLK_Overlay(tooltip, "destroy")
}

LegionParse()
{
	local
	global vars, settings, db

	leaders := ["asenath", "balbala", "nasima", "cadiro", "caspiro", "victario", "ahuana", "doryani", "xibaqua", "akoya", "kaom", "rakiata", "avarius", "dominus", "maxarius"]
	jewels := ["glorious vanity", "lethal pride", "brutal restraint", "militant faith", "elegant hubris"], vars.legion.selection := "", sections := InStr(Clipboard, "(implicit)") ? 0 : 1

	If !InStr(Clipboard, "Passives in radius are Conquered by")
	{
		LLK_ToolTip("invalid item-info in clipboard", 2,,,, "red")
		Return 0
	}

	StringLower, Clipboard, Clipboard
	Loop, Parse, % StrReplace(Clipboard, "`r`n", ";"), `;
	{
		If InStr(A_LoopField, "----")
		{
			sections += 1
			Continue
		}
		If (A_Index = 3)
			vars.legion.jewel := A_LoopField, vars.legion.jewel_number := LLK_HasVal(jewels, A_LoopField) ;the url for vilsol's calculator uses numbers to specify the jewel-type
		If InStr(A_LoopField, "{ unique modifier")
		{
			mod_text := SubStr(A_LoopField, InStr(A_LoopField, "}") + 2), mod_text := SubStr(mod_text, 1, InStr(mod_text, "Passives in radius are Conquered") - 2), mod_text := IteminfoModRemoveRange(mod_text)
			Break
		}
		If !InStr(Clipboard, "{ unique modifier") && (sections = 4)
		{
			mod_text := A_LoopField
			Break
		}
	}
	Loop, Parse, mod_text
		If IsNumber(A_LoopField)
			seed .= A_LoopField
	vars.legion.seed := seed

	For index, leader in leaders
		If InStr(mod_text, leader)
			vars.legion.leader := leader
	If (vars.legion.data.1 != vars.legion.jewel || vars.legion.data.2 != vars.legion.seed)
	{
		vars.legion.data := [vars.legion.jewel, vars.legion.seed, []]
		Loop, Parse, % LLK_FileRead("data\timeless jewels\"vars.legion.jewel ".csv"), `n, `r
		{
			If !vars.legion.nodes && (A_Index = 1)
				vars.legion.nodes := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1)
			If (SubStr(A_LoopField, 1, InStr(A_LoopField, ",") - 1) = vars.legion.seed)
			{
				Loop, Parse, A_LoopField, `,
					If (A_Index > 1)
						vars.legion.data.3.Push(A_LoopField)
				Break
			}
		}
			
	}
	vars.legion.jewel_mods := [], vars.legion.decoder_invert := {}
	For index, mod in db.legion.jewels[vars.legion.jewel]["_decoder"]
		vars.legion.jewel_mods.Push(mod), vars.legion.decoder_invert[mod] := index
	vars.legion.jewel_mods := LLK_ArraySort(vars.legion.jewel_mods)
	Return 1
}

LegionTree()
{
	local
	global vars, settings, db

	vars.legion.wait := 1
	If !vars.legion.fSize_tree
		vars.legion.fSize_tree := LLK_FontSizeGet(vars.legion.width/20, width), LLK_FontDimensions(vars.legion.fSize_tree, fHeight, fWidth), vars.legion.fWidth_tree := fWidth, vars.legion.fHeight_tree := fHeight
	Gui, New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDtree +Owner"vars.hwnd.legion.main
	Gui, %tree%: Color, Black
	Gui, %tree%: Margin, 0, 0
	Gui, %tree%: Font, % "s"vars.legion.fSize_tree " cWhite bold", Fontin SmallCaps
	hwnd_old := vars.hwnd.legion_tree.main, vars.hwnd.legion_tree := {"main": tree}

	For socket, val in db.legion.sockets
	{
		hAqua := 0, hYellow := 0, mods := {}
		For index, node in db.legion.sockets[socket].nodes
			mod := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], hYellow += settings.legion.highlights[node] && settings.legion.highlights[mod] ? 1 : 0
		For index, node in db.legion.sockets[socket].nodes
			text := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], mods[text] := mods[text] ? mods[text] + 1 : 1
		For mod, count in mods
			hAqua += settings.legion.highlights[mod] ? count : 0
		Gui, %tree%: Add, Text, % "BackgroundTrans Center cYellow w"vars.legion.fHeight_tree*1.8 " x"val.x * vars.legion.width*2 " y"val.y * vars.legion.width*2, % hYellow ? hYellow : ""
		Gui, %tree%: Add, Text, % "BackgroundTrans Center cAqua w"vars.legion.fHeight_tree*1.8 " x"val.x * vars.legion.width*2 " y+-"vars.legion.fHeight_tree*0.2, % hAqua ? hAqua : ""
		Gui, %tree%: Add, Pic, % "BackgroundTrans gLegion HWNDhwnd h"vars.legion.fHeight_tree*1.8 " w-1 x"val.x * vars.legion.width*2 " y"val.y * vars.legion.width*2, % "img\GUI\legion_socket"(socket = vars.legion.socket ? 1 : 0) ".jpg"
		vars.hwnd.legion_tree["socket_"socket] := hwnd
	}
	Gui, %tree%: Add, Pic, % "x0 y0 Border HWNDhwnd w"vars.legion.width*2 - 3 " h-1", img\GUI\legion_treemap.jpg
	vars.hwnd.legion_tree.map := hwnd
	Gui, %tree%: Show, % "NA x0 y"vars.monitor.y + vars.monitor.h - vars.legion.width*2
	LLK_Overlay(hwnd_old, "destroy"), vars.legion.wait := 0
	Gui, %tree%: -Owner
}
