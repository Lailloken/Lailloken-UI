# About:
A light-weight AHK script with UI and QoL features for Path of Exile, emphasizing ease-of-use, minimalist design, low hotkey requirements, and seamless integration into the game-client. **`This project is not affiliated with or endorsed by Grinding Gear Games (GGG) in any way`**.  
<br>

# Download & Setup
[![img](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/autohotkey.png)](https://www.autohotkey.com/) [![img](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/guide.png)](https://github.com/Lailloken/Lailloken-UI/wiki) [![img](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/download.png)](https://github.com/Lailloken/Lailloken-UI/archive/refs/heads/main.zip)  
[![img](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/help.png)](https://github.com/Lailloken/Lailloken-UI/issues/340) [![img](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/releases.png)](https://github.com/Lailloken/Lailloken-UI/releases)  
<br>

# Contributions
[![image](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/translations.png)](https://github.com/Lailloken/Lailloken-UI/discussions/326) [![image](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/issues.png)](https://github.com/Lailloken/Lailloken-UI/issues/339) ![image](https://github.com/Lailloken/Lailloken-UI/blob/main/img/readme/code.png)
<br>
<br>

# Context: What is this project?
<details><summary>show</summary>

- this is a fun-project (by a self-taught hobby-coder) that contains various UI/QoL features

  - I implement ideas that I think are fun/interesting to work on and figure out (even if they're not necessarily useful to everyone, or even myself)

  - since some features are user-requested and I don't use every single one myself, some aspects are heavily reliant on user-feedback (use the banners above to contribute)
 
  - my own ideas are always centered around SSF, but I'm open to trade-league-related ideas (if they're interesting enough and not too complex)
 
  - I generally avoid features that are "OP" or abusable because I don't think they're good for the game, regardless of how much QoL they would provide

- I view this as a personal toolkit rather than a product, so certain aspects may seem rough around the edges (or simply unconventional) when compared to other PoE-related projects
</details>
<br>

# Transparency Notice / Things you should know
<details><summary>show</summary>

- **things this tool does**

  - reads the game's client.txt log-file for certain statistics/events: current character level, area & transitions, NPC dialogues, etc.
 
  - sends key-presses to copy item-info, or activate chat-commands and in-game searches
 
  - checks screen-content for context-sensitivity to adapt the tool's behavior: it searches for open UIs (e.g. inventory, stash), `but it never reads/checks game-related values or bars`
 
  - reads on-screen text `on key-press` to summarize the information and display it in customizable tooltips
 
- **FAQ: has GGG approved this / can I be banned?**

  - to my knowledge, GGG has never approved any (local) 3rd-party tool
 
  - I can't make any claims regarding bans, only that I strictly follow [GGG's guidelines](https://www.pathofexile.com/developer/docs/index#policy): creators can be banned for distributing tools that violate the ToS, so it's in my best interest to follow them
 
  - (weak) annecdotal evidence: I have not been banned, nor have I heard of anyone else being banned
</details>
<br>

# Main Features
\* = based on a user-request
<br>

## [Clone-frames](https://github.com/Lailloken/Lailloken-UI/wiki/Clone-frames): pseudo interface-customization, functionally similar to 'Weakauras'  
![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/5b367a6b-7f69-4dd4-bbc0-0164de628013)  
<br>

## [Item-info](https://github.com/Lailloken/Lailloken-UI/wiki/Item-info): compact & customizable tooltip to determine loot quality at a glance
| segments ||
|---|---|
| DPS info | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/a1ba26c1-caf3-454f-b0db-a6382fc6fa35) |
| item-base info (optional) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/64ee0282-1cbd-464f-94d9-9de8d79f1e66)<br>![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/ce61b656-474e-4ce3-871c-0124377d64ce) |
| comparison with current gear (optional) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/03ae8243-bdac-4f06-be2f-f3ab43365380) |
| implicits, (un)desired highlighting | ![image](https://user-images.githubusercontent.com/61888437/224276010-99ce801f-e2d8-4c99-af37-026a1847abe2.png) |
| explicits, rolls, (un)desired highlighting | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/e449237e-62ef-4abb-951a-f1b1b3b8631d) |
| drop-tier and roll-percentages for uniques | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/b44f953e-0b51-4563-b661-a7a94533c881) |
<br>

## [Context-menu](https://github.com/Lailloken/Lailloken-UI/wiki/Minor-Features) for items: single-hotkey access to features and popular 3rd-party websites  
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/c778ea69-346e-47de-8f1b-ce5f69668557) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/8ed592d5-fe0e-4aeb-b511-cee4f610da3d) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/e12e66f6-ffad-4a79-b402-ac1844b5e385) |
|---|---|---|
<br>

## [Search-strings](https://github.com/Lailloken/Lailloken-UI/wiki/Search-strings): customizable, single-hotkey menu for every individual in-game search  
| regular stash | vendor | Gwennen | beast-crafting |
|---|---|---|---|
| ![image](https://user-images.githubusercontent.com/61888437/214894515-609be1ef-1b7a-40d2-afe4-8fa6374d5442.png) | ![image](https://user-images.githubusercontent.com/61888437/214895726-1a1c93d9-7183-40ca-bd6d-2da446169286.png) | ![image](https://user-images.githubusercontent.com/61888437/214895979-0df171e8-b7f3-4f8a-873b-14ade78306b3.png) | ![image](https://user-images.githubusercontent.com/61888437/170810022-cda485de-8be9-4b78-b98e-b2481a809475.png) |
<br>

## [Leveling tracker](https://github.com/Lailloken/Lailloken-UI/wiki/Leveling-Tracker): leveling-related QoL features
| \*automatic [exile-leveling](https://heartofphos.github.io/exile-leveling/) guide overlay | quick-access skilltree overlays | search-strings for every gem in a build |
|---|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/6f5d655f-0627-4147-b97e-ef4f8effe900) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/ed186c0d-05a9-4896-9d0e-7a03e7969e21) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/5ad3e10d-7124-4dfa-a114-2f3c58a56262) |
<br>

## [Stash-Ninja](https://github.com/Lailloken/Lailloken-UI/wiki/Stash%E2%80%90Ninja): interactive overlay that shows poe.ninja prices inside stash tabs
| customizable price-tags and profiles | conversion rates & optional price history | bulk-sale management with customizable margins |
|---|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/bc93c30a-74be-46bf-bc0f-af21cd810646) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/b19feea9-666c-4eb1-a809-b0a60cd5a2e2) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/7cedd403-e6df-47dd-b102-56e79523ed8b) |
<br>

## [Necropolis Lantern Highlighting](https://github.com/Lailloken/Lailloken-UI/wiki/Necropolis): customizable highlighting for necropolis lantern mods
![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/4a0a5533-b12d-4d64-a796-135ee4960845)
<br>
<br>

## [TLDR-Tooltips](https://github.com/Lailloken/Lailloken-UI/wiki/TLDR%E2%80%90Tooltips): customizable tooltips that summarize & highlight on-screen information
| eldritch altars | vaal side areas |
|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/02f258ae-a564-48aa-a6c7-4f1c2c5a84f5) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/fb8b12e7-7a26-4512-a160-ce716999396b) |
<br>

## [Cheat-sheet Overlay Toolkit](https://github.com/Lailloken/Lailloken-UI/wiki/Cheat-sheet-Overlay-Toolkit): create customizable, context-sensitive overlays
| types | example 1 | example 2 |
|---|---|---|
| image-based overlay | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/7a212c22-6c66-4a80-8598-1b0ed6b901c0) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/bb0779be-e178-4d07-8db1-3c942067e297) |
| app-based "overlay" | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/5467f558-049b-4590-9adf-b3729d79e307) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/be8f3177-a79c-479e-939a-1e5b4a2b9b4d) |
| advanced overlays | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/2c01c548-1163-4551-97da-2d5899fdba1a) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/dccf9161-0859-426a-b056-785e85632243) |
<br>

## \*[Mapping tracker](https://github.com/Lailloken/Lailloken-UI/wiki/Mapping-tracker): collect, save, view, and export mapping-related data for statistical analysis
| in-game log viewer | loot tracking | map-mod tracking |
|---|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/437d5ea8-b3a7-4783-a9cd-ad49d06a6f8d) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/8cdf2e78-43e1-465d-a61f-c58f263182db) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/209f7650-753f-4997-88a0-7bba23dbc6e7) |
<br>

## Overhauled [map-info panel](https://github.com/Lailloken/Lailloken-UI/wiki/Map-info-panel): streamlined & customizable map-mod tooltip and panel
| tooltip for rolling maps | on-demand panel to quickly re-check mods while mapping |
|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/1ecb2c4c-25ff-4b01-a3b9-6c62934e91bb) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/0ab3ff68-b74a-4a50-963a-8b5210be0a62) |
<br>

## [Betrayal-info](https://github.com/Lailloken/Lailloken-UI/wiki/Betrayal-Info): streamlined & customizable info-sheet (with optional image recognition)  
| simple overlay + customization | on-hover overlay + board tracking |
|-------------------------------|-----------------|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/c69c0459-cef7-431c-ba8a-2e39961046ec) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/7402bdce-3bdf-4d4b-8455-b523fd14ff4a) |
<br>

## [Seed-explorer](https://github.com/Lailloken/Lailloken-UI/wiki/Seed-explorer): in-client UI to quickly test a legion jewel in every socket
![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/2bb8a1f0-54cb-47e0-85df-a735cdacaa4c)  
<br>

## Several minor [QoL features](https://github.com/Lailloken/Lailloken-UI/wiki/Minor-Features):  
| essence tooltip to check the next tier's stats | orb of horizons tooltips | countdown & stopwatch |
| --- | --- | --- |
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/d02e44af-a2e5-47f0-a131-5911eb4e5c17) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/0c0ae2b3-148e-4138-af4f-d98fef0ce4b7) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/e965e405-5cea-46d0-9632-71a69c6487e1) |

| in-client notepad & sticky-notes | quick-access overlay and tracker for casual lab-runs |
| --- | --- |
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/f2c0f1dd-5863-4ebe-9516-cae0822ca32d) | ![image](https://user-images.githubusercontent.com/61888437/219877353-6b8a56b9-ae3c-4470-98c6-05f298d0ace3.png) |
<br>

## \*Support for [community translations](https://github.com/Lailloken/Lailloken-UI/discussions/categories/translations-localization):
| item-info tooltip in German | item-info tooltip in Japanese |
|---|---|
|![item info](https://github.com/Lailloken/Lailloken-UI/assets/61888437/bd523165-5118-41e3-8c6d-aab3e90e178f)|![japanese](https://github.com/Lailloken/Lailloken-UI/assets/61888437/315041a6-8c82-4a22-b472-7a2a64857b72)|
<br>
<br>

## Acknowledgements
- `item-info` uses a custom version of [Path of Building's](https://github.com/PathOfBuildingCommunity/PathOfBuilding) datamined resources

- `leveling tracker` uses leveling guides generated via [exile-leveling](https://github.com/HeartofPhos/exile-leveling) and was implemented with the help of its maintainer
- `seed-explorer` uses a custom version of the timeless-jewel databases provided via [TimelessJewelData](https://github.com/KeshHere/TimelessJewelData)
<br>

## (Temporarily-)retired / Legacy Features:
| [Archnemesis Recipe Helper/Scanner](https://github.com/Lailloken/Lailloken-UI/wiki/%5BArchive%5D-Archnemesis) | [Delve-helper](https://github.com/Lailloken/Lailloken-UI/wiki/%5BArchive%5D-Delve-helper): in-game UI to help you find secret passages |
|---|---|
| ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/0ae34934-76f6-4862-982a-04e258403c6e) | ![image](https://github.com/Lailloken/Lailloken-UI/assets/61888437/2ec14fe5-95aa-435e-8a0a-6b27177c8f13) |

| [Recombinator calculator](https://github.com/Lailloken/Lailloken-UI/wiki/%5BArchive%5D-Recombinator-calculator) | \*[Overlayke: Kalandra Planner/Preview Overlay](https://github.com/Lailloken/Lailloken-UI/wiki/%5BArchive%5D-Overlayke) | [Sanctum-room tooltip overlays](https://github.com/Lailloken/Lailloken-UI/releases/tag/v1.29.4-hotfix2) |
|---|---|---|
| ![image](https://user-images.githubusercontent.com/61888437/172839566-ea8295aa-b252-4889-93db-be5eca284a04.png) | ![Overlayke](https://user-images.githubusercontent.com/61888437/186435575-4b67b189-25de-426f-a045-24fef5d725ed.png) | ![image](https://user-images.githubusercontent.com/61888437/214906646-3a00a938-c955-48ce-8717-ec9a2d17bf4c.png) |
<br>
