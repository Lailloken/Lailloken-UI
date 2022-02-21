# Lailloken-UI
A collection of Path of Exile user interface improvements that focus on simplicity, user-friendliness, and minimalist design.
<br>
<br>

## Motivation & Philosophy

My goal with this overlay is to bring several QoL features to the archnemesis game mechanic (and more in the future) while staying as close to a natural in-game interface as possible, both from a design and user-friendliness point-of-view. This includes an easy and straight-forward setup, visual clarity, and a lack of required extra hotkeys and alt-tabbing.

That being said, I am not a programmer, and this is a merely a fun project and learning experience for me that I decided to share. This means I'll not be taking code input or optimizations from people unless critical bugs need to be fixed or I am hard-stuck.
<br>
<br>

## User Interface
![screenshot_new](https://user-images.githubusercontent.com/61888437/154802725-8a22a4ba-586a-4eab-b54d-0c7a65c17bb4.jpg)
The tool's UI consists of a letter bar and two small recipe windows: one that contains priority (or 'chase') recipes and one that shows recipes that are ready to be completed.
<br>
<br>

## Features

Using image recognition, this tool scans the contents of your archnemesis inventory, which enables a multitude of features not found in the game:
- creating a user-configurable list of favorite/chase recipes
- monitoring the progress of your list by breaking down recipes in a tree-view schematic
- highlighting recipes connected to your list that are ready to be assembled
- highlighting irrelevant mods and recipes that can be safely 'burned' without interfering with your list
- calculating which and how many base mods you need in order to complete your recipe list
- calculating your surplus in archnemesis mods for easy inventory management
- showing where the required base mods commonly drop, and suggesting optimal drop locations where multiple mods drop ([data source](https://www.reddit.com/r/pathofexile/comments/srtuug/i_made_a_sheet_for_archnemesis_drop_locations/), creator: [u/Rymse](https://www.reddit.com/user/Rymse/))

Rather than using universal image recognition, the tool has to be 'trained' manually. This means it has a longer set-up time, but this should provide higher scanning speeds and reliability in the long run. Think of it as 'tailored' to your system and settings.
<br>
<br>

### 'Training' the tool to recognize archnemesis icons:
![training_new](https://user-images.githubusercontent.com/61888437/154835584-2d432a0e-82ac-4181-9d4c-73ac31a1ea7b.jpg)
The tool scans your archnemesis inventory slot by slot, starting from the top left and working its way down in columns. Whenever it finds a new icon, it asks you to specify which archnemesis mod this icon belongs to. My plan is to optimize this system to the extend that every icon (63 in total) has to be specified only once and is from that point onwards recognized with 100% accuracy.
<br>
<br>

### Navigating the UI:
![letter_new](https://user-images.githubusercontent.com/61888437/154803454-5ed1928e-bc56-436f-bc1f-05c31a5fbf3f.jpg)
The letter bar is used to navigate a sort of glossary of the available recipes in game. Clicking a recipe will add it to the priority list and highlight it in yellow. The MAX button will search for recipes that are maxed out and cannot be upgraded, and the SCAN button will scan your inventory.
<br>
<br>

### The priority list:
![prio_new](https://user-images.githubusercontent.com/61888437/154803573-6c43fde9-7785-4fb1-9ddd-40e7da123e17.png)
The priority list is the center-piece of the tool and contains the set of archnemesis mods that you want to run as the endgame of the league-mechanic, i.e. the money-maker, the big wombo-combo. As such, this is where you set your goal for the archnemesis mechanic, and the tool accompanies you there and supplies recipe suggestions based on your inventory state and overall progression. Green highlighting indicates that your inventory contains at least one assembled version of the recipe. In addition, it calculates the missing base mods required to finish this list and displays them underneath.

![tree_new](https://user-images.githubusercontent.com/61888437/154804804-330a8914-f626-459e-bbf7-cbf326440bb0.png)
Hold-clicking a recipe in the priority list will show a tree-view schematic and breaks the recipe down. Use this to have a more detailed view on your progress.

![surplus](https://user-images.githubusercontent.com/61888437/154805163-401b44ac-7638-474b-bc95-c6a56e193773.png)
Hold-clicking the 'prio'-label gives you an overview of your surplus in archnemesis mods that are connected to the priority set. This also copies the top item on the list into your clipboard, so you can CTRL-F-V immediately after releasing the mouse button. Use this as a last resort to make room in your inventory in case nothing else can be burned.
<br>
<br>

### Optimal drop locations:
![base info](https://user-images.githubusercontent.com/61888437/154804196-1524117f-52e4-43ec-9091-3845ea89a37c.png)
![optimal location](https://user-images.githubusercontent.com/61888437/154804267-9f64bbe3-1fdc-4e50-83e6-9e9511eebd04.png)
You can hold-click the individual bases' icons to show where they more commonly drop, and you can hold-click the 'missing'-label to see which location drops the most missing mod bases. ([data source](https://www.reddit.com/r/pathofexile/comments/srtuug/i_made_a_sheet_for_archnemesis_drop_locations/), creator: [u/Rymse](https://www.reddit.com/user/Rymse/))
<br>

### On-the-fly recipe suggestions:
![ready_new](https://user-images.githubusercontent.com/61888437/154805018-065c29cf-7bda-403f-9e13-6663a73d6fc6.png)
The second window is divided into two parts – priority recipes and non-priority recipes/mods: The first part shows the recipes that are ready and lead to the priority set, the second shows irrelevant mods and recipes that are ready and do not use components from priority recipes. In PoE terms, they can be referred to as the 'chase' and the 'burner' list. Clicking on an item on the list will perform an in-game search in the inventory.
<br>
<br>

# Installation & Setup

### Download
Download the latest release here: [releases](https://github.com/Lailloken/Lailloken-UI/releases)

### Requirements
This tool is an AHK script and thus requires AutoHotkey to be installed on your system. Like most PoE overlays, it needs the PoE client to run in windowed fullscreen. Windowed support is planned for the future but low-priority at the moment.

### Setup
Once you run 'Lailloken UI.ahk' for the first time, the tool will guide you through a very short first-time-setup, and you're good to go.

### Known issues
Some mouse drivers/software may cause problems with (hold-)clicking UI elements. If issues like these occur on your system, you will have to disable or close your mouse software to continue using this tool.
