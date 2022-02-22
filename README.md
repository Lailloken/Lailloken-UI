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
<br>
<br>

### 'Training' the tool to recognize archnemesis icons:
![training_new](https://user-images.githubusercontent.com/61888437/154835584-2d432a0e-82ac-4181-9d4c-73ac31a1ea7b.jpg)
Rather than using universal image recognition, the tool has to be 'trained' manually. This means it has a longer set-up time, but this should provide higher scanning speeds and reliability in the long run. Think of it as 'tailored' to your system and settings.
The tool scans your archnemesis inventory slot by slot, starting from the top left and working its way down in columns. Whenever it finds a new icon, it asks you to specify which archnemesis mod this icon belongs to. This has to be done only once per icon for the vast majority of users (see 'known issues' at the end of this page).
<br>
<br>

### Navigating the UI:
![letter_new](https://user-images.githubusercontent.com/61888437/155020590-223c2f87-d75e-48fc-b66e-0025fd2c7d9e.png)
The letter bar is used to navigate a sort of glossary of the available recipes in game. Clicking a recipe will add it to the priority list and highlight it in yellow. The - and + buttons will resize all interfaces, and the SCAN button will scan your inventory.
<br>
<br>

### The priority list:
![prio_new](https://user-images.githubusercontent.com/61888437/154803573-6c43fde9-7785-4fb1-9ddd-40e7da123e17.png)
The priority list is the center-piece of the tool and contains the set of archnemesis mods that you want to run as the endgame of the league-mechanic, i.e. the money-maker, the big wombo-combo. As such, this is where you set your goal for the archnemesis mechanic, and the tool accompanies you there and supplies recipe suggestions based on your inventory state and overall progression. Green highlighting indicates that your inventory contains at least one assembled version of the recipe. In addition, it calculates the missing base mods required to finish this list and displays them underneath.

**Note**: You only need to add the end-point of a recipe chain to the list (e.g. Innocence-touched), the tool will calculate everything leading up to that. So there is no need to put the whole chain into the list (I specify this here because there had been some confusion in the past). Also, the priority system currently only calculates the route to complete one set of the priority list, i.e. every part in the chain will only be completed once in order to more efficiently allocate resources. I will look into implementing user-definable set sizes.

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
![ready_new](https://user-images.githubusercontent.com/61888437/155020962-a8fcbd8e-2ae6-4a64-9147-b3dcbfd17349.png)
The second window is divided into three parts – priority recipes, non-priority recipes, and non-priority mods: The first part shows the recipes that are ready and lead to the priority set, the second and third show irrelevant recipes and mods, respectively, that are ready and do not use components from priority recipes. Clicking on an item on the list will perform an in-game search in the inventory.
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
- Some mouse drivers/software may cause problems with (hold-)clicking UI elements. If issues like these occur on your system, you will have to disable or close your mouse software to continue using this tool.
- Uncommon resolutions (768p, 1024p, and 1050p) have very inconsistent image detection because of how the game client renders the archnemesis icons at these resolutions. There is a big variance in how the very same icon is rendered, depending in which inventory row or column the item is placed. This leads to the user having to train the tool multiple times for the same icon.
   - the only way to circumvent this issue is to lower or increase your desktop resolution (if possible).
   - the tool is still usable at these resolutions and should still recognize every mod and recipe, but it will take more time and effort since the pool of archnemesis mods is effectively multiplied by the number of different ways the game renders a single icon
![PoE rendering](https://user-images.githubusercontent.com/61888437/155091150-bef763d7-078d-4663-89f9-edc044a7ebe3.png)
(Two Gargantuans at 1050p, only two columns apart in the inventory. The areas around the noses and eyes are visibly different, which makes the scanner recognize it as two different icons)

