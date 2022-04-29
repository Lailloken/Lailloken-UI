## Motivation & Philosophy
My goal with this script is to bring several QoL features to the PoE-client while staying as close to a natural in-game interface as possible, both from a design and user-friendliness point-of-view. This includes an easy and straight-forward setup, visual clarity, and a lack of required extra hotkeys and alt-tabbing.

That being said, I am not a programmer, and this is a merely a fun project and learning experience for me that I decided to share. This means I will not be taking code input or optimizations from people (unless critical bugs need to be fixed or I am hard-stuck) because learning-by-doing and problem-solving is what makes this project fun for me.
<br>
<br>

## Features
- Archnemesis UI & feature extension ([info](https://github.com/Lailloken/Lailloken-UI/wiki/Archnemesis))
- Context-menu for items to quickly access popular 3rd-party websites ([info](https://github.com/Lailloken/Lailloken-UI/wiki/Context-menu-for-items))
- Several minor QoL improvements ([info](https://github.com/Lailloken/Lailloken-UI/wiki/General-QoL-features))
<br>

## Installation & Setup
Download the latest release here: [releases](https://github.com/Lailloken/Lailloken-UI/releases)
<br>
<br>

Requirements:
- This tool is an AHK script and thus requires AutoHotkey to be installed on your system
- Like most PoE overlays, it needs the PoE client to run in windowed fullscreen
![fullscreen](https://user-images.githubusercontent.com/61888437/155345187-06e604a8-8a80-403b-be7b-061c100d0de0.png)
<br>
<br>

## Known issues / limitations

This is a list of general known issues that may occur while using this script. For more specific issues regarding league- and mechanic-related features, visit the corresponding [wiki-pages](https://github.com/Lailloken/Lailloken-UI/wiki).
<br>
<br>

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

### Severe performance drops
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

### Uncommon resolutions
Uncommon resolutions (768p, 1024p, and 1050p, and maybe more) have very inconsistent image detection because of how the game client renders the archnemesis icons at these resolutions. There is a big variance in how the very same icon is rendered, depending in which inventory row or column the item is placed. This leads to the user having to train the tool multiple times for the same icon.
- the tool is still usable at these resolutions and should still recognize every mod and recipe, but it will take more time and effort since the pool of archnemesis mods is effectively multiplied by the number of different ways the game renders a single icon

   ![PoE rendering](https://user-images.githubusercontent.com/61888437/155091150-bef763d7-078d-4663-89f9-edc044a7ebe3.png)
   (Two Gargantuans at 1050p, only two columns apart in the inventory. The areas around the noses and eyes are visibly different, which makes the scanner recognize it as two different icons)

Workaround: [custom resolution](https://github.com/Lailloken/Lailloken-UI/discussions/49)
