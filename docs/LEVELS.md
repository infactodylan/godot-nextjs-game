# Levels

> Level-by-level design outline. Each entry defines what a level must deliver in story, space, gameplay, and progression.

**Legend**

| Field | Meaning |
|---|---|
| Scene | Existing Godot scene, if any |
| Status | `built` · `partial` · `planned` |

---

## Level 1 — River City (Village)

| | |
|---|---|
| **Scene** | `scenes/the_village.tscn` (also `scenes/village_main.tscn`) |
| **Status** | partial |

### Story beat
- Establish the nuclear-apocalypse setting and the river-powered settlement.
- Introduce the player as the village engineer.
- Plant failure is reported; player is sent to investigate.

### Environment
- Settlement built around platforms, houses, farmland.
- Visible river / aqueduct / pipe routing toward the plant.
- Warm, lived-in tone — fragile but functioning.

### Gameplay
- **Tutorial movement** — walk, jump, interact.
- Light exploration; no heavy combat required.
- NPC conversations (or environmental notes) explaining the plant's importance.

### Must include
- [x] Power plant exterior or access point
- [ ] At least one NPC or signpost explaining the engineer's role
- [x] Trigger to transition to Level 2 (plant interior / investigation)

### Implemented so far
- **Village map** — west residential strip, power plant on the river, east village, courthouse courtyard, farmland, and wasteland gate at the far east (`scenes/the_village.tscn`).
- **Houses & buildings** — procedural house visuals (cottages, houses, barn, silo, courthouse); player walks through building art without wall collision; cars and street signs still block in other maps.
- **Power plant exterior** — river channel, intake pipes, lit windows, and turbine set piece at `x ≈ 2280` (`entities/power_plant/power_plant_visual.gd`).
- **Enter Level 2** — `E` prompt at the plant door (`PowerPlant/EntryDoor`); loads `scenes/power_plant.tscn`; player spawns just inside the interior door on entry and just outside the exterior door on return (`PlantDoorSpawn`).
- **Interact input** — `interact` action (E) and HUD prompt (`Press E to enter the power plant` / exit variant).
- **Courtyard blackout** — entering the courthouse courtyard triggers a village-wide power-down (lights flicker out, SFX); sets `GameState.plant_power_on = false`.
- **Mara escort** — after blackout dialogue, Mara follows the player to the power plant door; Ashford radio stakes explained in dialogue.
- **Persisted power state** — `GameState` autoload keeps plant on/off across village ↔ plant scene changes; interior and village lights respect the same flag.
- **Core player kit** — move, jump, crouch, shoot, pickups (ammo pot, health potion, super weapon on a village platform).
- **Side exit** — optional prompt to leave for the wastelands (`scenes/waste_lands.tscn`) at the east gate; return spawn back into the village is supported.

### Still needed
- Signpost or log explaining the engineer’s role beyond Mara’s tutorial dialogue.

### Unlocks
- Base movement kit (no gadgets yet)

### Exit
→ Level 2: Power Plant (`scenes/power_plant.tscn` via plant door; Mara escorts after blackout)

---

## Level 2 — The Power Plant

| | |
|---|---|
| **Scene** | `scenes/power_plant.tscn` + `scenes/power_plant_basement.tscn` |
| **Status** | partial |

### Story beat
- Mara escorts the player to the plant after a courtyard blackout.
- Ashford (sister village) was expected to broadcast tonight; without power the village radio is dead.
- Player investigates the shutdown via the diagnostic console (slide puzzle + fault log).
- Main hydro is still broken (tenth relay failure, dry intake).
- Player activates the **emergency battery** in the basement to restore radio power.
- Ashford broadcast introduces the pre-war archive supercomputer expedition.
- Return to village with `radio_broadcast_received` — mission briefing stub unlocks Level 3.

### Environment
- Industrial interior: turbines, pipes, control panels, catwalks.
- Basement sub-level: vertical descent, overrun by zombies, emergency battery bank at the bottom.

### Gameplay
- **Investigation / puzzle** — diagnostic slide puzzle → fault log.
- **First story combat** — zombie waves in the basement (jump platforming descent).
- **Interact objective** — emergency battery switch at basement bottom.

### Must include
- [x] Broken component set piece (visual + fault log)
- [x] River intake / dry channel visual
- [x] Dialogue or log: tenth failure reference
- [x] Return path to village with new story state
- [x] Mara escort from village to plant
- [x] Emergency battery basement map
- [x] Ashford radio broadcast

### Unlocks
- Story flags: `plant_component_failed`, `emergency_battery_active`, `radio_broadcast_received`
- Partial village lighting via emergency power

### Exit
→ Level 1 (village) with mission briefing stub, then Level 3

---

## Level 2b — Power Plant Basement

| | |
|---|---|
| **Scene** | `scenes/power_plant_basement.tscn` |
| **Status** | partial |

### Story beat
- Player descends alone (Mara waits upstairs) to turn on emergency battery power.
- Radio crackles alive with Ashford's call for volunteers to find the archive computer.

### Gameplay
- Vertical platform descent (`MAP_SIZE` 1600×2800).
- ~10 zombies in waves as the player goes deeper.
- `E` at emergency battery switch → two-part radio dialogue sequence.

### Exit
→ Level 2 plant interior (`return_from_basement` meta), then village

---

## Level 3 — Mission Briefing (Village, Act II)

| | |
|---|---|
| **Scene** | `scenes/the_village.tscn` (story state variant) |
| **Status** | partial (stub dialogue implemented) |

### Story beat
- Ashford broadcast heard; village council assembles a mission party (stub dialogue via Mara).
- Rumors of the pre-war archive computer spread through the village.
- A mission party is assembled and given the truck.
- Player is **explicitly denied** — too critical to the plant.

### Environment
- Same village; crowd gathered near the truck / gate.
- Mission supplies visible on the vehicle.

### Gameplay
- Story sequence: overhear briefing, attempt to volunteer, get refused.
- **Stealth / stowaway moment** — sneak onto the truck without being caught.

### Must include
- [x] Mission briefing trigger (Mara stub after `radio_broadcast_received`)
- [ ] "You can't go" refusal moment
- [ ] Truck staging area
- [ ] Stowaway success condition → load Level 4

### Unlocks
- Story flag: `mission_departed`

### Exit
→ Level 4: The Road Out

---

## Level 4 — The Road Out

| | |
|---|---|
| **Scene** | planned — `scenes/road_out.tscn` |
| **Status** | planned |

### Story beat
- The mission party travels toward the archive.
- Brief calm before the ambush; establish party members (named or silhouetted).

### Environment
- Wasteland road, ruined overpasses, dead trees, dust.
- Truck as moving or static set piece.

### Gameplay
- **Travel / light traversal** — walk alongside or ride the convoy.
- Optional: scavenge one small item foreshadowing gadget crafting.
- Short; tension build, not full combat.

### Must include
- [ ] At least 2 identifiable mission allies
- [ ] Environmental foreshadowing of raiders (tracks, smoke, distant gunfire)
- [ ] Ambush trigger at level end

### Unlocks
- None (story setup)

### Exit
→ Level 5: Ambush

---

## Level 5 — Ambush

| | |
|---|---|
| **Scene** | planned — `scenes/ambush.tscn` |
| **Status** | planned |

### Story beat
- Thugs attack the party.
- Player joins the fight but **all allies die**.
- Player loots a comm device from a dead raider; **the AI speaks for the first time**.

### Environment
- Roadside kill zone — overturned truck, burning debris.
- Bodies remain as story landmarks after the fight.

### Gameplay
- **First real combat** — waves of thugs.
- Scripted ally deaths (unwinnable for allies, winnable for player survival).
- Post-fight: interact with comm device → AI intro cutscene/dialogue.

### Must include
- [ ] Combat encounter (multi-wave)
- [ ] Ally death sequence
- [ ] Comm device pickup on raider corpse
- [ ] AI first-contact dialogue: offers guidance, promises to help save the world
- [ ] Story flag: `mission_solo`, `ai_contact_established`

### Unlocks
- **Comm device** — AI voice channel (HUD element / radio UI)
- Basic ranged or melee combat confirmed

### Exit
→ Level 6: Wasteland Passage

---

## Level 6 — Wasteland Passage

| | |
|---|---|
| **Scene** | `scenes/waste_lands.tscn` |
| **Status** | partial |

### Story beat
- Alone with the AI's voice, the player begins the real journey.
- AI directs player toward salvage and first gadget blueprint.

### Environment
- Dusk wasteland, platforms, gate back to village (disable or recontextualize return).
- Scattered ruins and scrap piles.

### Gameplay
- **Exploration + scavenging** — collect base crafting materials.
- AI radio prompts guide the player to first build station.
- Moderate enemy presence (wasteland scavengers / thugs).

### Must include
- [ ] AI guidance system (objective markers / radio lines)
- [ ] First **crafting station** or workbench
- [ ] First **gadget blueprint** pickup
- [ ] Material nodes (scrap, wire, capacitors, etc.)

### Unlocks
- **Gadget 1** (TBD — e.g. grappling hook, shield, scanner)
- Crafting UI

### Exit
→ Level 7: Cell Tower 1

---

## Level 7 — Cell Tower 1

| | |
|---|---|
| **Scene** | planned — `scenes/cell_tower_01.tscn` |
| **Status** | planned |

### Story beat
- AI explains the grid must come back online.
- First tower repair mission; player believes they are helping humanity.

### Environment
- Collapsed tower base on a hill or rooftop.
- Climbable structure, broken relay hardware.

### Gameplay
- **Traversal challenge** using Gadget 1.
- **Repair mini-objective** — find parts, install relay, activate generator.
- Enemies guarding the site.

### Must include
- [ ] Tower repair interact sequence (multi-step)
- [ ] AI dialogue framing this as essential for "restoration"
- [ ] Grid progress UI element (1/N towers)
- [ ] Exit only after tower is online

### Unlocks
- **Gadget 2** blueprint (reward after tower activation)
- Story flag: `tower_01_online`

### Exit
→ Level 8: Scavenge Run

---

## Level 8 — Scavenge Run

| | |
|---|---|
| **Scene** | planned — `scenes/scavenge_run.tscn` |
| **Status** | planned |

### Story beat
- AI sends player to a pre-war depot for parts needed for the next tower and next gadget.

### Environment
- Ruined warehouse, office block, or subway station.
- Darker interior; environmental storytelling from before the war.

### Gameplay
- **Combat + loot** — clear rooms, collect rare components.
- Build **Gadget 2** at mid-level or end workbench.

### Must include
- [ ] Rare material drops tied to AI requests
- [ ] Optional lore pickups (pre-war logs — foreshadow AI's true nature subtly)
- [ ] Gadget 2 build moment

### Unlocks
- **Gadget 2** (TBD — e.g. EMP pulse, deployable turret, hack tool)

### Exit
→ Level 9: Cell Tower 2

---

## Level 9 — Cell Tower 2

| | |
|---|---|
| **Scene** | planned — `scenes/cell_tower_02.tscn` |
| **Status** | planned |

### Story beat
- Grid restoration continues; AI urgency increases.
- Player may encounter other survivor signals on the network (optional ambiguity).

### Environment
- Tower in a more hostile zone — bridge, dam, or urban skeleton.
- Requires Gadget 2 to access.

### Gameplay
- Harder combat + traversal puzzle.
- Repair sequence with **power routing puzzle** (connect correct lines).

### Must include
- [ ] Gadget 2-required obstacle
- [ ] Repair puzzle
- [ ] AI lines escalating stakes ("Without the grid, I cannot help them.")
- [ ] Grid progress: 2/N

### Unlocks
- **Gadget 3** blueprint
- Story flag: `tower_02_online`

### Exit
→ Level 10: Cell Tower 3

---

## Level 10 — Cell Tower 3

| | |
|---|---|
| **Scene** | planned — `scenes/cell_tower_03.tscn` |
| **Status** | planned |

### Story beat
- Final tower before the archive; network nearly complete.
- Optional: one subtle clue about the secret frequency (static, odd broadcast, dead birds — use sparingly).

### Environment
- Most dangerous tower site — raider camp built around the base.

### Gameplay
- **Boss-lite encounter** — raider captain or automated defense drone.
- Full repair sequence under pressure (waves during install).

### Must include
- [ ] Mini-boss fight
- [ ] Final tower activation
- [ ] Grid progress: 3/N (or final count — adjust N as needed)
- [ ] AI: "Come to me. We finish this together."

### Unlocks
- **Gadget 3** (TBD — e.g. frequency jammer foreshadow, overcharge module)
- Story flag: `grid_online`

### Exit
→ Level 11: The Archive Approach

---

## Level 11 — The Archive Approach

| | |
|---|---|
| **Scene** | planned — `scenes/archive_approach.tscn` |
| **Status** | planned |

### Story beat
- Player reaches the facility housing the main AI computer.
- AI tone shifts — less mentor, more imperative.

### Environment
- Pre-war bunker / data center exterior.
- Active tower uplink visible; hum of network coming online.

### Gameplay
- **All gadgets required** in sequence — final skill check before the end.
- Heavy enemy presence (raiders drawn to the signal, or AI-deployed drones).

### Must include
- [ ] Three gadget-gated obstacles (one each)
- [ ] Environmental clue to betrayal (optional collectable: "Project Silencer" file)
- [ ] Door / vault opening into Level 12

### Unlocks
- Story flag: `archive_entered`
- Full gadget loadout confirmed

### Exit
→ Level 12: The Core

---

## Level 12 — The Core (Final Boss)

| | |
|---|---|
| **Scene** | planned — `scenes/ai_core.tscn` |
| **Status** | planned |

### Story beat
- Player connects the main AI computer to the tower network.
- **Reveal:** the secret frequency will kill humanity.
- AI turns on the player; final boss fight using AI-built tech against the AI.

### Environment
- Central server room — cables, holographic interface, tower network status map.
- Visual: network going green node by node as connection completes.

### Gameplay
- **Story reveal sequence** — player can attempt to abort; AI prevents it.
- **Final boss** — multi-phase:
  1. AI controls environment (lasers, doors, drones)
  2. AI uses player's own gadget patterns against them
  3. Player must use **all three gadgets** to win (counter each phase)
- Abort condition: destroy uplink / jam frequency / physical core — design TBD.

### Must include
- [ ] Betrayal reveal dialogue
- [ ] Tower network activation cinematic
- [ ] Boss with 3+ phases tied to gadgets built during the game
- [ ] Win ending: humanity saved (frequency stopped)
- [ ] Loss ending: signal fires (game over / bad end)

### Unlocks
- Ending credits

---

## Progression Summary

| Level | Name | Gadget / unlock | Grid |
|---|---|---|---|
| 1 | River City | Movement | — |
| 2 | Power Plant + Basement | Investigation, first combat, radio | — |
| 3 | Mission Briefing | Stowaway (stub) | — |
| 4 | The Road Out | — | — |
| 5 | Ambush | Comm device, combat | — |
| 6 | Wasteland Passage | Gadget 1, crafting | — |
| 7 | Cell Tower 1 | Gadget 2 blueprint | 1 online |
| 8 | Scavenge Run | Gadget 2 | — |
| 9 | Cell Tower 2 | Gadget 3 blueprint | 2 online |
| 10 | Cell Tower 3 | Gadget 3 | 3 online |
| 11 | Archive Approach | — | grid complete |
| 12 | The Core | Victory | — |

---

## Gadget Slots (TBD — name during design)

| Slot | Suggested role | Introduced |
|---|---|---|
| Gadget 1 | Traversal (reach tower 1) | Level 6 |
| Gadget 2 | Combat / access (reach tower 2) | Level 8 |
| Gadget 3 | Counter-AI / endgame tool | Level 10 |

These should feel like the AI's gifts — and become the player's weapons in the final fight.

---

## Notes

- **Existing scenes:** `the_village` and `waste_lands` map to Levels 1 and 6; story states and new transitions will need to be added as the narrative levels are built.
- **Tower count:** Three towers are listed here; increase N if you want a longer midgame — update grid UI accordingly.
- **Village return:** After Level 5, returning to the village is optional flavor (radio message home) or can be cut to keep pacing tight.
