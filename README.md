# Lailloken-UI
A collection of Path of Exile user interface improvements that focus on simplicity, user-friendliness, and minimalist design.

# Motivation & Philosophy

My goal with this overlay is to bring several QoL features to the archnemesis game mechanic (and more in the future) while staying as close to a natural in-game interface as possible, both from a design and user-friendliness point-of-view. This includes an easy and straight-forward setup, visual clarity, and a lack of required extra hotkeys and alt-tabbing.

That being said, I am not a programmer, and this is a merely a fun project and learning experience for me that I decided to share. This means I'll not be taking code input or optimizations from people unless critical bugs need to be fixed or I am hard-stuck.

# Features

Using image recognition, this tool keeps track of the archnemesis inventory, is able to monitor your progression for specific recipes, and highlights recipes that are ready to be assembled. Rather than using universal image recognition, the tool has to be 'trained' manually. This means it has a longer set-up time, but this should provide higher scanning speeds and reliability in the long run.
![Untitled 6](https://user-images.githubusercontent.com/61888437/153947382-ff7abc3d-06c6-49fc-b1c9-351265e53d5d.jpg)


# User Interface
![screenshot_new](https://user-images.githubusercontent.com/61888437/154561700-032f3e19-4fcc-48f2-aa8e-d038f09ee346.jpg)


The tool's UI consists of a letter bar and two small recipe windows: one that contains priority (favorite/bookmarked) recipes and one that shows recipes that are ready to be completed.

![Untitled 3](https://user-images.githubusercontent.com/61888437/153942215-1d2760da-29ba-438f-85ee-0425b9362847.jpg) ![ready_new](https://user-images.githubusercontent.com/61888437/154561864-2bd6c5c2-ba1e-477c-b734-4ac75b9c9c80.jpg)


The letter bar is used to navigate a sort of glossary of the available recipes in game. Clicking a recipe will add it to the priority list and highlight it in yellow. The 'MAX' button will search for recipes that are maxed out and cannot be upgraded. The 'SCAN' button will scan your inventory.

![Untitled 5](https://user-images.githubusercontent.com/61888437/153943016-7b266be4-fa99-4013-a2d8-94ec2e8309f4.jpg)

The second window is divided into two parts – priority recipes and non-priority recipes: The first part shows the recipes from your priority list that are ready, the second shows recipes that are ready and do not use components from priority recipes. In PoE terms, they can be referred to as the 'juice' and the 'alch and go' list. Clicking on a recipe will perform an in-game search in the inventory.

![tree_new](https://user-images.githubusercontent.com/61888437/154561985-147a14d6-3985-4554-a6fa-76e076bbeb50.png)


Hold-click a recipe in the priority list to see a tree-view schematic of its components and their progress.

# Installation & Setup

## Requirements

This tool is an AHK script and thus requires AutoHotkey to be installed on your system. Like most PoE overlays, this needs the PoE client to run in windowed fullscreen. Windowed support is planned for the future but low-priority at the moment.

## Setup

Once you run 'Lailloken UI.ahk' for the first time, the tool will guide you through a very short first-time-setup, and you're good to go.
