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
![Untitled 2](https://user-images.githubusercontent.com/61888437/156729115-52d867a1-85ee-427a-8ffb-67b43d0efa0f.jpg)
The tool's UI consists of a letter bar and a recipe panel that shows lists of chase and burn recipes, as well as burn mods.
<br>
<br>

## Features

Using image recognition, this tool scans the contents of your archnemesis inventory, which enables a multitude of features not found in the game:
- creating a user-configurable list of favorite/chase recipes
- monitoring the progress of chase recipes by breaking them down in a tree-view schematic
- highlighting recipes connected to your list that are ready to be assembled
- highlighting irrelevant mods and recipes that can be safely 'burned' without interfering with your list
- calculating which and how many base mods you need in order to complete your recipe list
- calculating your surplus in archnemesis mods for easy inventory management
- showing where the required base mods commonly drop, and suggesting optimal drop locations where multiple mods drop ([data source](https://www.reddit.com/r/pathofexile/comments/srtuug/i_made_a_sheet_for_archnemesis_drop_locations/), creator: [u/Rymse](https://www.reddit.com/user/Rymse/))
- automatic recipe selection for a 1-click-0-attention interaction with the league mechanic
- blacklisting certain recipes that you want to avoid running
<br>

### 'Training' the tool to recognize archnemesis icons:
![training_new](https://user-images.githubusercontent.com/61888437/154835584-2d432a0e-82ac-4181-9d4c-73ac31a1ea7b.jpg)<br>
Rather than using universal image recognition, the tool has to be 'trained' manually. This means it has a longer set-up time, but this should provide higher scanning speeds and accuracy in the long run – think of it as 'tailored' to your system and settings.

The tool scans your archnemesis inventory slot by slot, starting from the top left and working its way down in columns. Whenever it finds a new icon, it asks you to specify which archnemesis mod this icon belongs to. This has to be done only once per icon for the vast majority of users (see 'known issues' at the end of this page).
<br>
<br>

### Navigating the UI:
![letter_bar](https://user-images.githubusercontent.com/61888437/157827689-ad90096f-a632-4000-adbd-cb657faeaec9.jpg)<br>
The letter bar is used to navigate a sort of glossary of the available archnemesis mods. Clicking an entry will highlight it in yellow and add it to the priority list, the - and + buttons will resize all interfaces. Clicking the PREV button will restore the in-game search to a previously selected recipe, and clicking the SCAN button will scan your inventory.
<br>
<br>

### The priority list:
![Untitled 6](https://user-images.githubusercontent.com/61888437/156738702-80a38462-5f9e-446f-bda7-771b31eca683.png)
The priority list is the center-piece of the tool and contains the set of archnemesis mods that you want to run as the endgame of the league-mechanic, i.e. the money-maker, the big wombo-combo. As such, this is where you set your goal for the archnemesis mechanic, and the tool accompanies you there and supplies recipe suggestions based on your inventory state and overall progression. Long-clicking the (?) icon will show UI navigation tips.

Green highlighting indicates that your inventory contains at least one assembled version of the recipe, and the quantity is shown in brackets. Indented entries show available recipes that are connected to your chase archnemesis mods. The panel also shows how close you are to completing the current set of the prio-list (X bases missing).

Long-right-click an entry on the list to remove it, long-right-click the 'prio-list' label to clear the whole list. You can right-click an entry to pause its tracking. This will highlight it in purple and stop suggestions for this specific recipe, freeing up the components, so that these may be used elsewhere. This is different from removing a recipe in that its components stay prioritized and don't go into the burn pool. Pausing a recipe is useful if it's pulling ahead of others, or if you feel you have assembled enough of it.

**What to put in**: You only need to add the end-point of a recipe chain to the list (e.g. Innocence-touched), the tool will calculate everything leading up to that. So there is no need to put the whole chain into the list (I specify this here because there had been some confusion in the past).

**How it calculates**: The system cross-checks every entry of your prio-list with our inventory state and calculates the required **remaining** pieces. That means it will only suggest assembling each sub-component once to complete the entry. As an example: Innocence-touched requires Lunaris-, Solaris-touched, Mirror Image, and Mana Siphoner. You can blindly follow the suggestions without the fear of assembling multiples of these **until Innocence-touched is assembled**. Then the next round of suggestions will start and, again, one set of its sub-components will be worked on.
<br>
<br>

![tree_new](https://user-images.githubusercontent.com/61888437/154804804-330a8914-f626-459e-bbf7-cbf326440bb0.png)<br>
Long-clicking a prio-list entry will show a tree-view schematic and breaks the recipe down. Use this to have a more detailed view on your progress.
<br>
<br>

![Untitled 8](https://user-images.githubusercontent.com/61888437/156736481-01f5cd9c-63ff-4ef0-be52-5f55b2d798f0.png)<br>
Clicking the 'prio-list' label gives you an overview of your surplus in archnemesis mods that are connected to the priority set. Additionally, you can set a threshold above which your surplus will be suggested as a burnable recipe or mod (these entries will be highlighted in yellow). Use this panel as a last resort to make room in your inventory in case nothing else can be burned.
<br>
<br>

### Optimal drop locations ([data source](https://www.reddit.com/r/pathofexile/comments/srtuug/i_made_a_sheet_for_archnemesis_drop_locations/), creator: [u/Rymse](https://www.reddit.com/user/Rymse/)):
![optimal_maps](https://user-images.githubusercontent.com/61888437/155491602-946470ef-403e-4da4-b574-cb50e43f7959.png)<br>
You can click the 'missing' label to open a movable window with a list of locations that commonly drop the missing mod bases. With it open, you can acces your map tab and search for these maps by clicking them in the list.
<br>
<br>

### Cheat sheet: Archnemesis bases
![Untitled 9](https://user-images.githubusercontent.com/61888437/156737068-8bd7a1c3-0712-4b91-b95c-0d85924ab413.jpg)<br>
Right-clicking the 'missing'-label opens a movable popout window with the list of missing bases that can be placed anywhere on the screen. You can use this as a cheat sheet if you only want to loot missing bases.
<br>
<br>

### On-the-fly recipe suggestions:
![Untitled 10](https://user-images.githubusercontent.com/61888437/156738303-506ffdea-92b7-4321-bd1c-673cf88007c5.jpg)<br>
The lower part of the prio-list panel shows 'burn' recipes and mods, i.e. irrelevant ones that are available and do not use components from priority recipes. Clicking on an item on the list will perform an in-game search in the inventory.
<br>
<br>

### Automation of the league mechanic:
Starting with v1.22.1, you can right-click the scan button to have the script automatically fill the slots in the current encounter. The tool will automatically check how many free slots are available and also avoid duplicates. This is primarily for convenience and a one-click solution that doesn't require any attention: you can use it to automate the whole archnemesis mechanic or to automatically fill the remaining slots in an encounter. This feature uses the current contents of the in-game search field as an orientation as to which and how many mods have already been used in the current encounter. This was initially planned to work without having to click anything, like an auto pilot, but there are too many variables that prevent this.
<br>
<br>

![Untitled 7](https://user-images.githubusercontent.com/61888437/158019686-9d6574aa-6e1f-4f7a-9b0d-39df8bd27c98.png)<br>
example 1 (3+1 slots): the first right-click highlights the invulnerable recipe, the second adds soul conduit as a burner
<br>
<br>

![Untitled 1](https://user-images.githubusercontent.com/61888437/158019706-1d86be54-3313-4408-b214-0f6e050c679c.png)<br>
example 2 (2+2 slots): the first right-click highlights the ice prison recipe, the second adds the storm strider recipe
<br>
<br>

![Untitled 2](https://user-images.githubusercontent.com/61888437/157716056-2d1fbcfe-e399-4406-a55f-61296bfcb84e.png)<br>
example 3 (2+1+1 slots): the first right-click highlights the drought bringer recipe, the second skips malediction (because it's already in use) and instead adds soul conduit as a burner, the third skips deadeye (again, it's already in use) and instead adds berserker as a burner
<br>
<br>

Auto-highlighting will stop as soon as four mods are reached, and the script will merely refresh these four when right-clicking scan again. When re-entering a map, make sure you don't accidentally right-click 'scan' when the search field is blank, otherwise a new auto-highlight set of four mods will be started. Instead, click the 'prev' button to go back to the previous highlighting state. Inversely, you have to make sure the search field is blank when you want to start a new set of four (it is blank at the start of the map, but it still doesn't hurt to check).
<br>

**CAUTION**: This feature has to be used while actively doing archnemesis encounters, i.e. you must not queue up recipes at the start of the map. So, as with normal scanning, only right-click the scan button after finishing a recipe. This is what can happen if you use this feature incorrectly: Queueing recipes AB and burners C and D at the start of the map may result in assembling AC and BD if you don't pay attention and the recipe constellation allows it.<br>
<br>
<br>

### Blacklisting recipes:
![blacklist](https://user-images.githubusercontent.com/61888437/158016417-ac80cb77-4e31-47a6-9ecd-5b022d166e6a.png)![burn mods](https://user-images.githubusercontent.com/61888437/158015460-b462ae84-d57d-405b-ba80-31dd62d93649.jpg)<br>
Starting with v1.22.2, you can right-click mods in the letter-bar glossary to add them to the blacklist. These blacklisted recipes will then not be suggested for assembly when ready, and they will be highlighted in red on the burn-mod list in case you already have assembled versions in your inventory. Use this feature to avoid archnemesis mods that you hate or can't run with your build, which becomes even more useful if you use the automation feature described above.
<br>
<br>

![blacklist button](https://user-images.githubusercontent.com/61888437/158017145-f60b10f0-c23f-4119-afed-00394706603b.jpg)<br>
Clicking the 'BL' button on the letter bar will show the current blacklist, and entries can be removed by clicking them.
<br>
<br>


# Installation & Setup

### Download
Download the latest release here: [releases](https://github.com/Lailloken/Lailloken-UI/releases)
<br>
<br>

### Requirements
- This tool is an AHK script and thus requires AutoHotkey to be installed on your system
- Like most PoE overlays, it needs the PoE client to run in windowed fullscreen
![fullscreen](https://user-images.githubusercontent.com/61888437/155345187-06e604a8-8a80-403b-be7b-061c100d0de0.png)
- You have to disable the in-game filters introduced in patch 3.17.1
<br>

### Setup
Once you run 'Lailloken UI.ahk' for the first time, the tool will guide you through a very short first-time-setup, and you're good to go.
<br>
<br>

# Known issues

### Clicking
Some mouse drivers/software may cause problems with (hold-)clicking UI elements. If issues like these occur on your system, you will have to disable or close your mouse software to continue using this tool.
<br>
<br>

### Graphical filters/post-processing
Using graphical filters or post-processing via ReShade, Nvidia Freesyle, or similar may cause the tool to work inconsistently or incorrectly. This may manifest as the overlay opening and closing on its own randomly, or scans not working. If you experience these issues, you will have to disable filters or post-processing for PoE and set the tool up from scratch, i.e. do a clean install.
<br>
<br>

### GeForce Now: fluctuating image quality
Being a streaming-based gaming solution, GeForce Now's fluctuating image quality may impact how well the script is able to detect the archnemesis inventory. This manifests as the overlay not showing when the archnemesis inventory is open. v1.21.4 introduced a workaround for situations like these which enables the user to make the script's pixel check less strict.
- open the ini\config.ini file and change the 'variation' value from 0 to 15. Save the file and restart the script
- if the issues remain, re-do this and increase the value by 5 until the tool is able to detect the inventory reliably
![notepad, geforce now](https://user-images.githubusercontent.com/61888437/157830289-31b15865-364d-4745-ad8f-9015e7e58a84.jpg)<br>
<br>

### Performance drops
An unknown combination of hardware or software may cause dramatic frametime spikes while the tool is running
- v1.20.4 introduced a fallback mechanic that can be used in this situation: it replaces the automatic background pixel check with a manual pixel check triggered by the in-game archnemesis hotkey
- open the Fallback.ahk file in a text editor and follow the instructions inside; save it afterwards
- open the ini\config.ini file and change fallback=0 to fallback=1 (add the line in the PixelSearch section if the value doesn't exist yet); save it afterwards
- from now on, the overlay will behave as follows:
   - whenever you open the archnemesis inventory by using the in-game hotkey, the overlay will automatically show up
   - opening the inventory by clicking the statue will require you to press the hotkey to make the overlay appear
   - whenever the inventory closes, the overlay will disappear automatically (no matter how it was opened)
   - the frametime spikes will persist while interacting with the inventory but disappear immediately after it is closed
<br>

### Scanning
A corrupt or outdated installation of AutoHotkey on your system may cause the tool to not work, without showing any signs of error. Telltale signs of this include:
- you have just completed training the tool, but during the following scan the tool immediately asks you to do it again
- the img\Recognition\XXXXp\Archnemesis (accessible via right-clicking the ?-icon) folder contains image files that clearly show the CENTER of the archnemesis icons and have coherent file names
<br>

### Resolutions
Uncommon resolutions (768p, 1024p, and 1050p, and maybe more) have very inconsistent image detection because of how the game client renders the archnemesis icons at these resolutions. There is a big variance in how the very same icon is rendered, depending in which inventory row or column the item is placed. This leads to the user having to train the tool multiple times for the same icon.
- the tool is still usable at these resolutions and should still recognize every mod and recipe, but it will take more time and effort since the pool of archnemesis mods is effectively multiplied by the number of different ways the game renders a single icon

   ![PoE rendering](https://user-images.githubusercontent.com/61888437/155091150-bef763d7-078d-4663-89f9-edc044a7ebe3.png)
   (Two Gargantuans at 1050p, only two columns apart in the inventory. The areas around the noses and eyes are visibly different, which makes the scanner recognize it as two different icons)

- workaround (v1.21.0+): Run the PoE client with a custom resolution in windowed fullscreen
   1. set the PoE client up as usual (normal desktop resolution, windowed fullscreen, etc.)
   2. go to the PoE settings -> UI -> confine mouse to window
   
   ![options](https://user-images.githubusercontent.com/61888437/155990051-aed94750-050b-452d-9b60-c7446e764a28.jpg)
   
   3. open ini\config.ini in a text editor and change "force-resolution" to 1 (or add this line UNDER SETTINGS if it doesn't exist yet); save the file
   
   ![notepad](https://user-images.githubusercontent.com/61888437/155990675-743e3eb5-5be3-4619-9654-9ac474df5fac.jpg)
   
   4. restart the script, a new window will open up in which to set the custom resolution; don't click "remember settings" just yet, do a test run first
   
   ![custom resolution](https://user-images.githubusercontent.com/61888437/155990785-ad0a9c25-3595-4ad1-a639-3f47b4207d6f.jpg)
   
   5. if everything works as expected, click "remember settings" the next time you start the script, and the script will automatically apply the custom resolution from now on
      - to disable custom resolutions, set "force-resolution" back to 0
      - to change to a different custom resolution, delete the "custom-height" line in the ini-file, save it, and restart the script
