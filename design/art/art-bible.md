# Art Bible: 유랑단 (The Wandering Band)

*Created: 2026-04-16*
*Status: In Progress*
*Engine: Godot 4.6 / GDScript / Compatibility Renderer*
*Platform: PC (Steam)*

---

## Table of Contents

1. [Visual Identity Statement](#1-visual-identity-statement)
2. [Mood & Atmosphere](#2-mood--atmosphere)
3. [Shape Language](#3-shape-language)
4. [Color System](#4-color-system)
5. [Character Design Direction](#5-character-design-direction)
6. [Environment Design Language](#6-environment-design-language)
7. [UI/HUD Visual Direction](#7-uihud-visual-direction)
8. [Asset Standards](#8-asset-standards)
9. [Reference Direction](#9-reference-direction)

---

## 1. Visual Identity Statement

### One-Line Visual Rule

> **"의심스러울 때는 가독성을 우선하라 — 화면의 모든 캐릭터는 '유닛'이 아닌 '사람'으로 즉시 읽혀야 한다."**
>
> *"When in doubt, prioritize readability — every character on screen must be legible as a person, not a unit."*

### Supporting Principles

#### Principle 1: 따뜻하되 낡은 (Warm but Worn)

세계와 인물은 따뜻한 색조를 사용하되, 아무것도 새것이 아니다. 앰버, 녹슨 붉은색, 바랜 초록, 부드러운 흙빛의 팔레트. 중세 판타지 배경이지만 광택 나는 갑옷과 선명한 원색이 아닌, 오래 쓴 도구와 살아온 공간의 색이다.

*Design test*: 새 환경 타일이 "밝고 선명" vs. "바래고 따뜻함" 사이에서 고민되면 → 바랜 것을 선택. 캐릭터 팔레트가 생동감 있는 색 vs. 흙빛 사이에서 고민되면 → 흙빛을 선택 (의도적으로 눈에 띄는 캐릭터 제외).

*Pillar served*: **작지만 진짜인 이야기** — 서사시의 영웅이 아닌, 세상 어딘가에 실제로 있을 것 같은 사람으로 느끼게 한다.

#### Principle 2: 실루엣이 먼저 (Silhouette Before Detail)

모든 동료 캐릭터는 실루엣만으로 구별되어야 한다. 색과 디테일을 보기 전에 형태, 자세, 비율이 개성을 먼저 말한다. 대기 자세(idle stance)가 1순위 실루엣이다 — 게임에서 가장 많이 보이는 포즈.

*Design test*: 새 동료 스프라이트를 단색 실루엣으로 변환했을 때 다른 동료와 구별되지 않으면 → 디테일과 색을 추가하기 전에 실루엣을 재설계한다.

*Pillar served*: **눈에 보이는 성장** + **모인 사람들** — 스노우볼이 감동적이려면 각 합류가 화면에서 뚜렷하게 보여야 한다. 12명이 함께 싸울 때 12개의 뚜렷한 실루엣이 12명의 개인으로 읽혀야 한다.

#### Principle 3: 조용한 순간을 위한 공간 (The Quiet Moment Has Space)

영입 장면, 동료 대화, 캠프 순간은 시각적으로 절제된다. 요소가 적고, 움직임이 느리며, 프레임이 가깝다. 전투의 활기와 대비되는 이 조용함이 감정적 무게를 만든다.

*Design test*: 스토리 장면에 시각 요소를 더 추가할지 뺄지 고민된다면 → 뺀다. 두 캐릭터가 심플한 배경에서 마주보는 것이 대부분의 경우 더 감동적이다 (언더테일의 교훈).

*Pillar served*: **작지만 진짜인 이야기** + **팀이 곧 열쇠다** — 새 동료가 합류하는 순간은 전투와 시각적으로 달라야 그 의미가 전달된다.

---

## 2. Mood & Atmosphere

### 2.1 Overworld Exploration

**Emotion target:** The low hum of forward motion — not safety, not danger, just the feeling of being small in a large world with somewhere to be.
**Lighting character:** Warm-neutral, low contrast. Midday or late afternoon direction. Shadows are soft, implied by tile color shift rather than drawn.
**Atmospheric adjectives:** Dusty, open, unhurried, faintly lonely, forward-leaning.
**Energy level:** Measured.
**Mood carrier:** Tile density drops at the center of the path. The walkable lane is visually quieter (fewer overlapping tiles, fewer foreground objects) than the edges. The eye rests on the party. The world recedes.

---

### 2.2 Active Combat

**Emotion target:** Controlled chaos — the tight, readable panic of outnumbered people who are starting to hold their own.
**Lighting character:** No lighting change from overworld. Mood is carried entirely by animation speed and palette contrast. Enemy silhouettes use cooler, darker variants of the base palette to oppose the warm party tones.
**Atmospheric adjectives:** Crowded, sharp, urgent, percussive, readable.
**Energy level:** Frenetic — but legibility is never sacrificed for energy.
**Mood carrier:** Animation frame rate. Party attack animations play at 1.5× the idle rate. Enemy death animations are slower, deliberate — one beat of stillness before the sprite disappears. This contrast makes victories feel earned, not lucky.

---

### 2.3 Town / Settlement

**Emotion target:** Cautious exhale — relief that is not quite comfort, because this world doesn't owe you rest.
**Lighting character:** Warmest palette state in the game. Amber and soft clay dominate. Interior/sheltered areas use slightly increased saturation compared to the road.
**Atmospheric adjectives:** Lived-in, layered, still, breathing, cluttered.
**Energy level:** Contemplative.
**Mood carrier:** Tile density at its highest. Backgrounds are busiest here — barrels, hanging cloth, small props in the mid-ground. The visual complexity signals civilization without a single NPC needing to be on screen. Contrast against the sparse road sells the arrival.

---

### 2.4 Recruitment Moment

**Emotion target:** The specific weight of a stranger becoming someone you're responsible for.
**Lighting character:** Same palette as wherever the moment occurs — no special lighting. Mood is carried by composition and motion, not color change.
**Atmospheric adjectives:** Still, close, deliberate, held, turning.
**Energy level:** Tender.
**Mood carrier:** The new companion's idle animation plays at half speed for 2–3 seconds after the join event fires — a single beat of visual stillness before normal gameplay resumes. Everything else on screen continues at normal speed. That one slower sprite signals: something just changed.
> ⚠️ *Implementation note: Verify per-sprite playback speed modifier in Godot 4.6 before locking in.*

---

### 2.5 Main Menu / Title Screen

**Emotion target:** The promise of people worth following, before you know them.
**Lighting character:** Cool-warm split. Background is cool (dusk blue-grey). Party silhouettes in the foreground are warm amber-outlined. High contrast along the silhouette edge.
**Atmospheric adjectives:** Silhouetted, anticipatory, quiet, campfire-adjacent, inviting.
**Energy level:** Contemplative.
**Mood carrier:** A slow idle sway on the silhouetted party figures — no detail visible, just weight and personality readable from posture and outline. The visual identity principle "Silhouette Before Detail" is most literal here. The player meets the characters as shapes before they meet them as people.

---

### 2.6 Defeat / Game Over

**Emotion target:** Exhaustion, not punishment — the party scattered, not erased.
**Lighting character:** Desaturated version of whichever palette was active. No new color — same hues pushed toward grey. Contrast drops.
**Atmospheric adjectives:** Drained, quiet, distant, unfinished, still.
**Energy level:** Contemplative — approaching still.
**Mood carrier:** The party sprites do not disappear. They stay on screen, static — idles frozen, not fading to black. The world is still visible. The stillness of characters who were moving is the defeat image. No dramatic cut, no red overlay. The absence of motion is the consequence.
> ⚠️ *Implementation note: Requires the engine to hold the scene frozen rather than transition out — verify implementation complexity.*

---

**Global rule:** No scene-specific dynamic lighting. Every mood state stays within the established warm-worn palette and uses tile density, color contrast, and animation timing as the primary mood levers.

---

## 3. Shape Language

### 3.1 Character Silhouette Philosophy

Each archetype owns one distinguishing geometric trait readable at 32×32 or smaller. The player character reads as a vertical rectangle with a consistent head-to-body ratio — deliberate, upright, human but unremarkable in outline, so companions read as distinct against them. Friendly companions each own one silhouette departure: a wide stance, an asymmetric weapon, a slouch, a tall hat. The rule is **one trait per character**, not a combination — combinations blur at small size. Hostile enemies skew toward compressed horizontal mass (hunched, wide, low center of gravity) — not because wide shapes signal evil, but because a low-slung silhouette reads as *blocking the path*, which is the enemy's actual function in combat. Neutral NPCs use the same upright proportions as the player but without weapon or tool attachments.

*Design test:* Export any character sprite as a 32×32 black silhouette. If the archetype is not identifiable in 2 seconds, the silhouette fails before color or detail is added.

*Pillar served:* **Earned Fellowship** — each companion's silhouette must be distinct enough that the player notices when a new shape joins the party.

---

### 3.2 Environment Geometry

The primary world vocabulary is **interrupted rectangles** — stone walls, wooden structures, and soil paths are all grid-aligned rectangular blocks, but always partially broken: a crumbling corner, a leaning post, a crooked doorframe. Perfect geometry reads as constructed; broken geometry reads as lived-in. This serves Warm but Worn without requiring complex tile art.

Safe areas (towns, camps, cleared roads) use **closed shapes** — enclosures, overhangs, and structures that frame the party. The eye reads containment as rest. Dangerous areas (enemy camps, ruins, ambush corridors) use **open geometry with obstructed sightlines** — broken walls that do not close into rooms, columns that block without defining a space. The danger signal is the *absence of enclosure*, not spiky shapes.

*Design test:* Remove all characters from a scene. Does the geometry read as "shelter" or "exposure"? If unclear, increase or decrease enclosure accordingly.

---

### 3.3 UI Shape Grammar

The UI uses a **separate screen-space language** from the world — deliberately. The world is broken rectangles and organic wear; the UI is clean low-border rectangles with minimal corner radius.
> ⚠️ *Exact corner radius in pixels deferred until base canvas resolution is defined in Section 8.*

The separation is functional: at the tile density and palette of this game, a hand-drawn organic UI border would compete with environment art and lose. The UI must be immediately distinguishable as *not the world*. The one concession to world aesthetic: UI panels use the same desaturated amber-clay tones as the environment at slightly increased opacity. The shape family is clean; the color family is warm.

Icon shapes within UI: simple geometric — circle for heal states, diamond for status effects — chosen for 16×16 legibility, not thematic resonance.

*Design test:* Place a UI panel over the busiest town background. If the panel borders read as tile edges, increase border contrast before adjusting shape.

---

### 3.4 Hero Shapes vs. Supporting Shapes

The player character is **the only sprite on screen with a consistent warm highlight** at all times — a single 1px rim on the top edge in soft amber, applied as a fixed overlay. This is not a glow effect; it is a single-pixel priority signal. When 10 companions fill the screen, the eye finds the player character by that one persistent warm edge before reading any other shape or color.
> ⚠️ *Implementation note: Requires a shader pass or per-sprite overlay layer — verify technical feasibility in Godot 4.6.*

Supporting companions are drawn in the same palette but without the rim. Enemy shapes use cooler, darker values (per Section 2.2), keeping them visually separated from the party cluster even in crowded combat.

**Hard layout rule (all non-cutscene scenes):** The player character is never fully occluded by companions. Z-order is managed so the player sprite always has at least 60% of its bounding box visible.
> ⚠️ *Cross-reference: This rule must also appear in Section 7 (UI/HUD) as a layout constraint.*

*Design test:* Fill the screen with the maximum companion count in a combat arrangement. The player character must be findable within 1 second without UI assistance. If not, adjust z-order rules or rim intensity.

*Pillar served:* **Visible Snowball** — the party growing must not cost the player their spatial anchor.

---

## 4. Color System

### 4.1 Master Palette

This game uses a **restricted 14-color master palette** shared across all world sprites, character sprites, and UI elements. No sprite may introduce a color outside this palette.

The palette is organized into four functional bands:
- **Neutral Band** (4 colors): tonal backbone of all world art
- **Warm Accent Band** (4 colors): life-and-light signal for friendly elements
- **Cool Contrast Band** (3 colors): enemy and shadow signal
- **Reserved Signal Band** (3 colors): reward, health, and UI-only uses

#### Neutral Band

| Name | Hex | Role |
|---|---|---|
| **Stone Dust** | `#2A2520` | Darkest shadow. Sprite outlines, deep shadow tiles, text. Brown-black, not blue-black — the world's darkest moment is still warm. |
| **Worn Clay** | `#5C4A38` | Mid-shadow. Stone walls, soil paths, tree bark in shadow. Default unlit surface. |
| **Pale Oat** | `#C8B89A` | Base neutral highlight. Parchment, worn wood, sunlit stone. The mid-tone most tiles spend the most pixels on. |
| **Bleached Linen** | `#EDE0CA` | Lightest neutral. Highest highlight points on surfaces, NPC skin highlights, scroll/paper UI elements. |

**Semantic meaning:** These colors communicate material reality — stone, soil, wood, skin. They are not mood colors. A tile entirely within the Neutral Band reads as background. The moment a Warm Accent color appears, that element becomes foreground.

---

#### Warm Accent Band

| Name | Hex | Role |
|---|---|---|
| **Ember Amber** | `#C87A2A` | Primary warm signal. Party member highlights, firelight, warm item glow, town lamplight. When the eye sees Ember Amber, it reads "belonging to the player's world." |
| **Rust Red** | `#8C3A2A` | Warm danger-adjacent. Worn leather, dried blood on enemy units (not player), desaturated health bar fill. Color of hard use, not pure danger. |
| **Worn Sage** | `#5A6E48` | The one cool-leaning warm. Overgrown ruins, mossy stone, grass in shadow, worn traveler's cloth. Keeps the palette from reading as entirely amber-brown. |
| **Soft Terracotta** | `#B46450` | Skin mid-tone for warm-complexioned characters, roof tiles, fired clay pots. Town palette's secondary warmth signal. |

**Semantic meaning:** These colors signal human presence, warmth, and belonging. Any interactive object or allied NPC should have at least one warm accent pixel visible at all times. If an object looks entirely neutral-band, it will not register as interactive.

---

#### Cool Contrast Band

| Name | Hex | Role |
|---|---|---|
| **Dusk Iron** | `#3A4A5C` | Primary enemy signal. Replaces Ember Amber in enemy sprite warm-slot swaps. Enemy armor, shadow-side surfaces in enemy territory, night sky fill. |
| **Slate Shadow** | `#1E2A38` | Deepest enemy/hostile shadow. Where Stone Dust appears on friendly sprites, Slate Shadow appears on enemy equivalents. |
| **Fog Grey** | `#8090A0` | Desaturated mid-tone for defeat state and ruin areas only. When Fog Grey appears, the game communicates loss of vitality. No other use. |

**Semantic meaning:** These colors signal opposition, threat, and emptiness. A sprite carrying Dusk Iron in its palette is hostile to the player. Fog Grey appears only in defeat and decay contexts.

---

#### Reserved Signal Band

| Name | Hex | Role |
|---|---|---|
| **Warm Gold** | `#E8B840` | Reward and achievement only. Loot glints, quest completion flash, XP gain indicator. Never used for ambient decoration. Scarcity is the signal. |
| **Deep Umber** | `#3C2A1A` | UI panel fill exclusively. Warmer and darker than Stone Dust. Separates screen-space from world-space without breaking hue family. |
| **Soft Amber Glow** | `#D4A060` | UI text and icon color. Lightened desaturated Ember Amber. Primary UI text and icon fills. Not used in world sprites. |

**Semantic meaning:** These three colors only appear in UI or reward contexts. Their scarcity in world art is what makes them signal. If Warm Gold appears on ambient prop textures, it will no longer reliably communicate reward.

---

### 4.2 Semantic Color Vocabulary

Level designer reference. Every color-based gameplay signal must be derivable from this table.

| Signal | Primary Color | Where It Appears | Backup Cue (required) |
|---|---|---|---|
| **Hostile / Enemy** | Dusk Iron replacing warm accents | Enemy sprites, hostile area tiles | Animation timing + horizontal-mass silhouette (Section 3.1) |
| **Interactive Object** | ≥1 Ember Amber pixel visible | Chests, doors, switches, usable props | Subtle idle animation (breathing, glint loop) |
| **Recruitable NPC** | No special color — matches surrounding area | Wherever the NPC stands | Unique idle animation, contextual proximity cue |
| **Player Character** | 1px Ember Amber rim on top edge (always) | Player sprite only | Z-order priority + 60% visibility rule (Section 3.4) |
| **Party Companion** | Warm Accent palette; no amber rim | Companion sprites | Consistent follow-behavior relative to player |
| **Reward / Loot** | Warm Gold `#E8B840` | Drop VFX, loot icon, quest complete flash | Chime sound cue + brief scale-up animation |
| **Danger Area** | Dusk Iron + Slate Shadow dominate tiles | Enemy camp tiles, hostile zone entrances | Open geometry, broken enclosures (Section 3.2) |
| **Safe Area** | Ember Amber + Soft Terracotta dominate tiles | Town tiles, camp tiles | Closed geometry, enclosures |
| **Defeat State** | All warm accents replaced by Fog Grey | Full scene | All sprite animations frozen |
| **Health (UI)** | Rust Red fill, Pale Oat background | Health bar widget | Numeric value always visible alongside bar |
| **XP / Progress (UI)** | Worn Sage fill, Deep Umber background | Progress bar widget | Numeric or fractional label |

> ⚠️ **Recruitable NPCs use no special color signal — intentional.** Discovery of who is recruitable comes from dialogue and proximity cues, not color tags. Do not add a recruitable-marker color without explicit design approval.

---

### 4.3 Per-Area Color Temperature Rules

Palette shifts between areas are achieved by **changing which band dominates tile coverage**, not by introducing new colors.

| Area Type | Dominant Band | Temperature | Notes |
|---|---|---|---|
| **Open Road / Wilderness** | Neutral (Pale Oat, Worn Clay); Warm Accent at 15–20% | Warm-neutral | Warm accents on path edges, not center-lane tiles. Eye rests on party. |
| **Town / Settlement** | Warm Accent (Ember Amber, Soft Terracotta) at 40%+ | Warmest | Highest saturation state. Tile density maximum. |
| **Enemy Camp** | Cool Contrast (Dusk Iron, Slate Shadow) dominates | Cool-dark | Warm Accent only on loot objects or damaged friendly props — instantly legible as "not of this place." |
| **Ruins / Abandoned** | Neutral + Worn Sage; Warm Accent <10% | Muted, cool-drifting | Warmth that left. Not fully hostile but not safe. |
| **Ambush Corridor** | Neutral with Dusk Iron intrusions | Neutral with hostile undertone | Cool intrusions telegraph threat before enemies appear. |
| **Title Screen** | Background: Dusk Iron + Slate Shadow; Silhouettes: Ember Amber rim | Cool-warm split | Maximum silhouette pop. The one place where Cool Contrast dominates background. |
| **Defeat Overlay** | Fog Grey replaces all Warm Accent slots | Desaturated | No new colors — warm accents drain to grey. |

**Transition rule:** Tile palette shifts happen over 2–3 tile widths at area boundaries — no hard cutoffs. Tile artists: maintain a 2–3 tile transition strip at every major area boundary.

---

### 4.4 UI Palette

UI palette is a **constrained subset** of the master palette using only Reserved Signal Band + Pale Oat. No colors outside the master palette.

| UI Element | Color | Notes |
|---|---|---|
| **Panel background** | Deep Umber `#3C2A1A` | All dialog boxes, HUD containers, menus. Fully opaque — no translucent panels. |
| **Panel border** | Pale Oat `#C8B89A` at 1–2px | Thin border separates panel from world art. |
| **Primary text** | Soft Amber Glow `#D4A060` | Names, values, menu options. |
| **Secondary text / labels** | Pale Oat `#C8B89A` | Descriptors, sub-labels. |
| **Health bar fill** | Rust Red `#8C3A2A` | Warm, not pure-red — avoids classic red-green colorblind failure mode. |
| **Health bar background** | Worn Clay `#5C4A38` | Drained, not black. |
| **XP / Progress bar fill** | Worn Sage `#5A6E48` | Spatially separated from health bar in HUD layout (≥8px gap). |
| **Reward flash** | Warm Gold `#E8B840` | 0.5–1 second maximum. Quest complete, loot drop, XP milestone. |
| **Icon fills** | Soft Amber Glow `#D4A060` | All HUD icons base fill. |
| **Disabled state** | Fog Grey `#8090A0` | Grayed-out options, locked slots. Reuses defeat palette signal — intentional. |

**No translucent panels.** At pixel art resolution and tile density, alpha-blended panels create color mixing artifacts. All UI panels are fully opaque Deep Umber.

**UI divergence rule:** UI diverges from world art in **luminosity only, not hue**. All UI colors are lighter (Soft Amber Glow, Pale Oat) or darker (Deep Umber) than world equivalents — no new hues.

---

### 4.5 Colorblind Safety

Every semantic color signal must have a backup from one of: shape, animation, sound, or spatial position. Color alone is never the sole distinguishing cue.

| Signal Pair | Failure Mode | Required Backup Cue |
|---|---|---|
| **Rust Red health vs. Worn Sage XP bar** | Both may appear dull yellow-brown to deuteranopes | Spatial separation (≥8px gap) + numeric value always visible on health bar |
| **Worn Sage (safe) vs. Dusk Iron (enemy)** | May both shift toward brown-grey | Shape signal: enemy horizontal-mass silhouette (3.1) + open geometry danger areas (3.2) |
| **Ember Amber (friendly) vs. Rust Red (worn/enemy)** | Both shift toward dull orange under protanopia | Animation: enemy sprites have distinct hostile idle; allied sprites have calm idles |
| **Warm Gold (reward) vs. Ember Amber (ambient)** | May appear as similar yellow | Sound cue + scale-up/bounce animation on every reward event |
| **Worn Sage tiles vs. Neutral Band tiles** | Sage may flatten to grey-brown | Tile pattern: Worn Sage tiles use organic edge shapes vs. rectangular stone/soil |
| **Defeat desaturation** | Color change may not be perceived | All sprite animations freeze — cessation of movement is the primary defeat signal |

**Global rule:** No semantic gameplay signal may rely on color as its sole distinguishing cue. This applies at all times including title screen and defeat state.

---

## 5. Character Design Direction

### 5.1 Player Character Visual Archetype

The player character is a **traveler who hasn't decided anything yet.** Their design is deliberately mid-range on every axis: mid-height, mid-build, no dominant color beyond the amber rim, no weapon that signals a class before gameplay does. The silhouette reads as upright rectangle — no jutting element, no defining ornament. This is not blandness; it is a **designed absence of conclusion.** The player is readable as a person because they have proportion, posture, and wear on their clothes, but those qualities do not add up to a personality the player hasn't chosen.

What is deliberately left neutral: hair volume, weapon choice, primary garment color (any palette-legal color may serve). What is not neutral: posture is upright and slightly forward-leaning — purposeful, not passive. They look like someone walking toward something. The amber rim is always present and is the only visual cue that says "this one is you."

*Design test:* Place the player silhouette alongside the busiest companion lineup. If the player reads as "a specific type of fighter," the silhouette has over-committed. The player is the shape companions orbit, not the shape that competes with them.

---

### 5.2 Companion Design Rules

**Each companion must signal their role and personality through silhouette before any text is read.** The design process for a new companion is strictly ordered:

1. **Silhouette first.** Sketch as a black fill only at 32×32. Must be distinguishable from every existing companion. One silhouette departure from the upright-rectangle baseline — wide stance, large prop, stoop, asymmetric protrusion. One only.
2. **Role signal second.** The single visual element that carries their function — a carried tool, a garment type, a posture. Not a class icon; a prop or posture that makes their role readable as a *vocation*, not a game stat.
3. **Color application third.** Differentiation within the palette is done by **proportional dominance**: one companion's primary color takes up 50%+ of their visible pixel area; that same color is a secondary accent at most on other companions.

**The snowball must be visible, not uniform.** By companion six, the party should look like people who found each other — not a team designed together. Avoid repeating silhouette departure type: if one companion reads through horizontal width, the next should use height or asymmetry instead.

*Avoid the Power Ranger failure:* Different colors on identical body types is not differentiation. If removing color makes two companions indistinguishable, the design is incomplete.

---

### 5.3 Enemy Visual Archetypes

**Type 1: The Blocker.** Wide, hunched, occupies horizontal tile space. Center of gravity sits below the sprite midpoint. Head sits no higher than 40% of total sprite height. Shoulders or arms extend past body width by ≥4px at 32-wide. These are the enemies that make the party feel outnumbered. Palette: Dusk Iron dominant, minimal warm pixels.

**Type 2: The Reach.** Tall but bent — a vertical threat that leans into the player's space. Not a straight rectangle (the player's read). The lean is the tell. Top of sprite extends past upright centerline by 3–4px, as if perpetually mid-lunge. Elongated limb props (spear, long staff) extend the silhouette further. Palette: Slate Shadow and Dusk Iron, no warm accents except on captured loot.

**Type 3: The Swarm Unit.** Smaller than the player at 32×32, designed to be repeated in groups. Horizontally compact but crouching: legs wide, head low. The single identifying silhouette element is the head shape — exaggerated ears, horns, or head covering, the part that pops above the mass when several are tiled. Palette: Worn Clay + Dusk Iron (feels environmental, like the land itself turned against the party).

*Design test for all enemy types:* In a mixed scene, enemy sprites must read as "on the other side of this confrontation" from shape alone, before any UI or color coding is checked.

---

### 5.4 Expression and Pose Style

This game's expressiveness target is **understated with single clear beats.** Not pantomime cartoon, not stoic portrait — the emotional range is narrow by intention. Each visible emotion carries more weight because it is rare. The visual language is "one thing at a time": a character has either a neutral pose or one clearly readable departure from neutral. Expressions are not layered.

**The limit of expressiveness** is the "Small but True" pillar: if an expression or pose requires more than one read to understand, it is too much. A surprised companion tilts the head and opens the stance slightly. That is the whole expression.

**Pose states by context:**

- **Dialogue / story scenes:** Characters hold near-static poses — one pose per emotional beat, held for the full duration. Pose changes are slow and deliberate. Two characters facing each other with minimal props; the pose IS the scene. Posture carries subtext.
- **Idle / overworld:** The idle animation is the most-seen pose in the game. It should read as each character *at rest but present* — a small sway, a subtle breath cycle. Design the idle to reflect the character's dominant trait, not their combat function. This is the pose the player will associate with this person.
- **Combat:** Poses shift to forward-weight and compressed — combat stance is shorter and wider than idle. Attack poses are held for exactly one frame before resolving — the impact frame is the expressive moment, not the wind-up.

*Global rule:* No character smiles or expresses overt warmth through facial expression alone — the warm palette does that work. Emotional warmth is carried by color and proximity, not illustrated faces at pixel scale. Character faces at 32×32 are 3–5 pixels of feature area; do not invest in nuanced facial expression at that resolution.

---

## 6. Environment Design Language

### 6.1 Architectural Style and World-History Relationship

This is a world that was built by people who believed things would last, and then they didn't. The architecture is **post-peak medieval** — not ruined enough to be gothic, not intact enough to be prosperous. Structures show competent original construction (dressed stone foundations, mortared joints, tiled roofs) with decades of patchwork on top: a repaired wall in cheaper fieldstone, a doorframe that no longer fits its door, a wooden lean-to built against an older stone wall.

The visual rule is **two visible eras per major structure**: what it was built as, and what someone made of it later. This history is told through **tile adjacency, not illustration.** Two tile sets — "original construction" (rectangular stone, uniform coursing) and "later repair" (uneven fieldstone, wood patch) — placed in deliberate adjacency tell the full story. The broken geometry from Section 3.2 is the physical record of people who kept going after things fell apart.

- **Currently occupied areas**: functional clutter — things actively in use, tools upright, containers open.
- **Recently vacated areas**: arrested clutter — things stopped mid-task, left in place. A lid half-on. Tools fallen flat.
- **Long abandoned areas**: entropy clutter — nothing stands without leaning; Worn Sage overtakes all vertical surfaces; only ceramic, stone, and metal props survive.

**Pillar served:** Small but True — the world's difficult past is in the mortar joints, not in a loading screen text box.

---

### 6.2 Texture Philosophy

At pixel art scale with a 14-color palette, **material differentiation is achieved through pattern geometry, not color range.** Stone, wood, and earth all draw from the same Neutral Band colors; what separates them is the shape and rhythm of pixel patterns.

| Material | Pattern Rule | Distinguishing Characteristic |
|---|---|---|
| **Dressed stone** | Horizontal brick stagger, 4–6px runs | Regular horizontal rhythm; 1px mortar line (Worn Clay) between Pale Oat faces |
| **Fieldstone / rubble** | Irregular polygon clusters, varied sizes | No regular rhythm; irregular angle joints |
| **Worn wood** | Vertical grain lines, 2–3px spacing | Vertical rhythm; knot as 2px oval in Stone Dust against Worn Clay |
| **Packed earth** | Horizontal dither, no hard edges | No distinct line rhythm; Worn Clay to Stone Dust gradient implies depth |
| **Mossy / overgrown** | Stone or wood base + Worn Sage stipple on upper half | Material below still readable; Worn Sage clusters signal neglect |

**Tile style is flat with implied depth through color banding, not painted highlights.** Fixed light source: upper-left. Depth is implied by placing darker Neutral Band colors at the bottom edge of objects and lighter at the top — no shadows drawn as separate objects. This approach is production-efficient: depth reading comes from which Neutral Band color occupies which pixel row, not from per-tile painting.

**Solo dev rule:** All surface material is determined at tile-set definition time, not per-instance. A mossy stone tile is a distinct tile variant, not a base tile with a hand-painted overlay. Material variation scales as additional tile variants, not additional art passes.

---

### 6.3 Prop Density Rules

**The first law is Section 3.4's rule: characters are the subject, environments are the setting.** Prop density must never compete with character legibility. The ceiling for any area is: "can I still read every sprite's silhouette at a glance?" If no, the prop layer is too heavy.

Props are placed in one of three **depth lanes:**
- **Foreground (character level):** Character-reserved. No decorative props. Interactive props (doors, chests) allowed only with an Ember Amber pixel signal.
- **Midground (1 tile behind):** Props allowed; must not overlap character bounding boxes.
- **Background (2+ tiles behind):** Props may overlap each other freely.

| Area Type | Prop Density | Center Lane Rule |
|---|---|---|
| **Open road / wilderness** | Sparse (1–2 props per screen-width) | Center lane clear — visual rest zone |
| **Town / settlement** | Dense (4–6 props visible) | No prop within 1 tile of expected walk path |
| **Enemy camp** | Medium-sparse (2–3 props) | Enemy silhouettes must not be broken by mid-ground props |
| **Ruin / abandoned** | Medium (3–4 props, all low and horizontal) | Enforce open geometry — few vertical occluders |
| **Active combat area** | Locked at pre-combat density | No new occlusion during active combat |

**Production-efficient prop system:** Define 3–5 prop clusters per area type (a cluster = 2–4 props designed to sit together). Place clusters in midground and background lanes. Clusters are reused across instances of the same area type. This is the same reuse logic as tile sets, applied to prop arrangements.

**The density signal is the area boundary.** The contrast between road density and town density makes arrival feel like arrival. If town density bleeds onto the road approach, the arrival beat is lost.

---

### 6.4 Environmental Storytelling Guidelines

**Three spatial states** recur across all area types:

**State 1: Currently occupied.** Tools upright or in active position. Containers open or recently closed. Light sources lit or showing recent ash. Perishable items (cloth, food props) whole. Repair work mid-process. *Test: would a figure stepping into frame feel like they belong here?*

**State 2: Recently vacated.** Containers sealed but with dying fire (Ember Amber yielding to Worn Clay in fire pit tiles). Cloth folded with gravity, not crumpled. Doors in partial-open position, not broken. Tools horizontal but not scattered. *Test: the viewer can construct a story of the last hour.*
> ⚠️ *Requires one tile variant per fire prop: "fire-dying" state (Ember Amber → Worn Clay, no Bleached Linen highlight).*

**State 3: Long abandoned.** Worn Sage intrudes on all vertical surfaces (upper third of walls, stone path edges). Nothing stands upright without leaning. No perishable props remain. Two construction eras visible but neither recently repaired. *Test: no human would sleep here without clearing it first.*

**The party camp — a fourth state (being made):**
The camp the party establishes is visually distinct from all three states above: it is the one environment the player watches come into existence. **Each new companion adds one prop to camp.** Not a restructuring — one prop in their visual vocabulary (a tool matching their silhouette role, a cloth in their dominant color). After 8 companions, the camp reads as "built by multiple people with different habits." No single organizing aesthetic — these people did not all have the same background.
> ⚠️ *Scope note: The camp must exist as a persistent location with up to 10 prop slots. Confirm with game design before production.*

**What a lone NPC's space looks like before recruitment:**
One organized area within general disorder — one cleared shelf, one clean tool, one carefully folded cloth. Everything else shows ambient entropy. The person stopped maintaining the larger space and focused only on what matters to them. The recruiting moment is already implicit in the environment before the player speaks to them.

**Cross-reference to Section 3.2:** Occupied areas use closed geometry. Vacated areas show enclosures partially opened or broken. Long-abandoned areas have no functional enclosures. Geometry tracks the same human presence signal as the prop vocabulary.

---

## 7. UI/HUD Visual Direction

### 7.1 Diegetic vs. Screen-Space HUD

All UI in 유랑단 is **screen-space only**. No diegetic health meters embedded in character sprites, no floating damage numbers over world sprites. The 14-color palette is too restricted for any embedded UI to survive without creating visual noise.

**Persistent elements** (always visible during gameplay):
- Player health bar (corner zone)
- Companion dot strip: one 1px dot per active companion, up to 5 for MVP
- Active companion ability slot (if manual ability triggers are exposed)

**Contextual elements** (appear only when relevant):
- Enemy health bars: appear automatically for all enemies in active combat with any party member; disappear when combat with that enemy resolves. No targeting system required.
- Dialogue panel: appears only during NPC dialogue or recruitment sequences
- Notification strip: single-line panel, 1.5–2 seconds, for loot/XP/quest events

**Hard layout rule (carry-forward from Section 3.4):** No persistent HUD element may occupy screen real estate that pushes player character visibility below 60% bounding box. Health bar and companion dots belong in corner zones, not spanning bottom.

---

### 7.2 Typography Direction

At pixel art resolution, the font must be a **bitmap pixel font** — not a vector font scaled down. Vector fonts anti-alias at small sizes and fight pixel art's hard edges.

**Selected font: Monogram** (open-license). Angular with beveled stroke terminations — reads as hand-carved and used. Test at 2x and 4x integer scale before finalizing any size decisions.

**Three size levels — no more:**

| Level | Use | Size |
|---|---|---|
| **Large** | NPC name, section headers | 8px cap height |
| **Body** | Dialogue text, menu options | 6px cap height |
| **Micro** | HP numbers, XP fractions, item counts | 5px cap height |

**Color rule:** Large + Body text in Soft Amber Glow (`#D4A060`) on Deep Umber panels. Micro text in Pale Oat (`#C8B89A`) — visually receded since it is always paired with a bar that carries semantic meaning.

**Gamepad / Steam Deck rule:** Every icon in the UI displays a text label directly below it at all times (Body text, Pale Oat). Icon + label is the minimum interactive unit. No hover-only information.

---

### 7.3 Iconography Style

**Grammar: two shapes, all icons.** Circle = heal/health. Diamond = status effect. All companion ability and status icons are variants of these two base forms — not departures. A companion ability that heals uses a circle with an interior cross mark. A buff uses a diamond with an interior mark. Players learn two shapes; all future icons extend them.

**16×16 icon legibility rules:**
- One strong silhouette — shape reads before interior detail
- Interior detail: max 2px stroke weight
- Max 3 colors: Soft Amber Glow (fill), Stone Dust (outline), Pale Oat (interior accent)
- ≥2px breathing room from icon edge

**What makes icons fail at 16×16:** Two competing silhouette elements of equal weight; interior detail that requires reading vs. recognizing; deviation from circle/diamond grammar for a single special case.

**Disabled state:** Fog Grey (`#8090A0`) replaces Soft Amber Glow as icon fill. Shape unchanged. No X overlay — adds illegible noise at 16×16.

**Production rule:** Author all icons as a single sprite sheet (128×16 or 128×32). All icons share the same base canvas — forces consistency and makes additions a controlled process.

---

### 7.4 Animation Feel for UI Elements

Motion vocabulary: **direct and deliberate, never decorative.** All UI animations must be achievable with a Godot `Tween` — no custom shaders or animation state machines required.

| Context | Motion | Duration | Easing |
|---|---|---|---|
| **Combat HUD** | Health bar: instant fill reduction (v1). Companion dot: scale 0→1 on join/loss | 0.1s | ease-out |
| **Dialogue panel** | Slides in from bottom edge (not fade — alpha-blend conflicts with no-translucency rule) | 0.2–0.25s | ease-out |
| **Dialogue text** | Typewriter scroll at fixed interval; player input advances immediately | — | — |
| **Menu** | Slides in from fixed edge (choose one edge, never change it) | Entry: 0.15s / Exit: 0.1s | ease-out / ease-in |
| **Menu selection** | Soft Amber Glow + single-pixel Warm Gold highlight on selected row | Instant | — |
| **Notification strip** | Slides from off-screen top-right; holds; exits upward | 0.1s in/out | ease-out/ease-in |

**Notification queueing:** Maximum 2 queued; anything beyond is dropped. Do not stack visible notifications in v1.

**Global motion rule:** No UI panel animation during active combat except health bar and notification strip. Combat is visually busy enough.

---

## 8. Asset Standards

*Engine: Godot 4.6 / Compatibility Renderer / GDScript*

### 8.1 Sprite and Character Asset Specifications

**Base resolution:** 32×32 pixels per character tile. Integer scaling only — no sub-pixel scaling or fractional scale values.

**Texture import settings (Godot 4.6):**
- Import preset: `2D Pixel`
- Filter: Nearest (no filtering)
- Mipmaps: Disabled
- Compress: Lossless (or Uncompressed if lossless introduces palette dithering artifacts)

**Sprite sheet organization:** One sprite sheet per character containing all animation states. Do not split a single character across multiple textures — one character = one draw call via `AnimatedSprite2D`.

Recommended layout: **horizontal strip per animation state, states stacked vertically.** All frames uniform size within the sheet (`SpriteFrames` requires uniform frame dimensions per animation). Target: 256×256 px or smaller per character sheet.

**Hard cap:** 512×512 px per character sprite sheet.

---

### 8.2 Tile Set Specifications

**Tile size:** 16×16 pixels (2:1 ratio to 32×32 character footprint).

**Node:** Use `TileMapLayer` — **NOT `TileMap`** (deprecated since Godot 4.3, confirmed in 4.6). Three `TileMapLayer` nodes for the three depth lanes (foreground, midground, background).
> ⚠️ *Godot 4.6 note: `TileMapLayer` gained the ability to rotate scene tiles (not just atlas tiles) in 4.6 — new capability, not breaking.*

**Atlas texture size:** Maximum **2048×2048 px** per atlas. Aim for **one atlas per area type** (road, town, enemy camp, ruin) to minimize texture swaps during scene transitions.

**Import settings:** Same as character sprites — Nearest filter, mipmaps disabled, lossless compress.

**Performance ceiling:** No more than **4 unique tile atlas textures bound simultaneously**. Beyond 4, risk draw call budget breach when combined with character sprites and UI.

---

### 8.3 Texture Memory Budget

**Total memory ceiling:** 512MB. Texture memory hard cap: **128MB** (remainder reserved for engine, scene data, audio, runtime).

| Asset type | Memory per unit | Max units | Total |
|---|---|---|---|
| Character sprite sheet (256×256 RGBA8) | ~0.25MB | 12 active | ~3MB |
| Character sprite sheet (512×512 RGBA8) | ~1MB | 12 active | ~12MB |
| Tile atlas (2048×2048 RGBA8) | ~16MB | 4 simultaneous | ~64MB |
| UI atlas (512×512) | ~1MB | 1 | ~1MB |
| **Total estimated** | — | — | **~77MB** well under 128MB cap |

---

### 8.4 Animation Constraints

| Parameter | Limit | Reason |
|---|---|---|
| Frames per standard state (idle, walk) | **8 max** | Diminishing returns at 32×32 |
| Frames per complex state (attack, death) | **12 max** | Texture sampling cost × 10+ instances |
| Animation states per character | **8 max** | `SpriteFrames` load time at scene instantiation |
| Simultaneous `AnimatedSprite2D` instances | Safe at 10–12 on PC (Compatibility) | Each is one draw call; 12 chars ≈ 12 draws |

If a character requires more than 8 states, split into a **base sheet** (combat states, always loaded) and an **auxiliary sheet** (cutscene/interaction states, loaded contextually). Never simultaneously.

---

### 8.5 File Format and Naming Conventions

**Export format:** PNG only. No JPG (lossy), no WebP (inconsistent pixel fidelity), no TGA/BMP.

**PNG settings:**
- 8-bit indexed or 32-bit RGBA (Godot imports both)
- No interlacing
- No embedded ICC color profile
- No EXIF metadata
- Compression level: maximum

**Naming convention (GDScript snake_case):**

| Asset type | Pattern | Example |
|---|---|---|
| Character sprite sheet | `chr_[name]_[variant].png` | `chr_bard_base.png` |
| Tile atlas | `til_[area]_[set].png` | `til_town_ground.png` |
| Animation state key (`SpriteFrames`) | `[action]_[direction]` | `walk_south`, `attack_light` |
| Scene file | `[name].tscn` | `chr_bard.tscn` |
| SpriteFrames resource | `[name]_frames.tres` | `chr_bard_frames.tres` |

**Directory layout:**
```
assets/art/characters/[character_name]/
assets/art/tilesets/[area_type]/
assets/art/ui/
assets/vfx/
```

---

### 8.6 Godot 4.6-Specific Flags

Critical deviations from Godot 4.3 (LLM training data baseline):

| Flag | Impact | Action Required |
|---|---|---|
| `TileMap` deprecated → use `TileMapLayer` | **Direct impact** — 3-lane system must use 3 `TileMapLayer` nodes | Always use `TileMapLayer` |
| Shader texture uniform type changed in 4.4 | Affects any custom 2D shaders (palette swap, outline, dissolve) | Use `Texture` base type, not `Texture2D` |
| D3D12 default on Windows in 4.6 | **No impact** — Compatibility renderer uses OpenGL regardless | No action; note for project settings review |
| Glow pipeline changed in 4.6 (pre-tonemapping) | Compatibility renderer's glow availability must be verified | Test before designing any glow-based VFX |
| `duplicate_deep()` for SpriteFrames copies (4.5+) | Affects palette-swapped companion variants | Use `duplicate_deep()`, not `duplicate()` |

**UI corner radius (deferred):** Exact pixel value deferred from Section 3.3. Specify at asset production time using this project's confirmed base canvas resolution.

---

## 9. Reference Direction

Five references. Each covers one specific technique. No two overlap in what they contribute. Reading them together should produce implementable decisions, not a mood board.

---

### 9.1 퍼스트퀸4 (First Queen 4)

**What to take:** Unit-as-person legibility under mass-combat conditions. Strict silhouette separation between unit types — no two archetypes share head height, weapon protrusion axis, or horizontal-to-vertical mass ratio. Study how its soldier types remain distinguishable even when overlapping. Apply to Section 3.1 and 5.2 companion silhouette rules.

**What to avoid:** Flat, functionally uniform color blocking that makes units read as a military force. Do not apply uniform palette assignment to companions (different color on same body type). Each companion's color proportion must be unique.

**Why additive:** The only reference that depicts large-scale friendly unit clusters at pixel scale while maintaining individual legibility.

---

### 9.2 스타듀밸리 (Stardew Valley)

**What to take:** The prop density contract — using background object density to communicate the character of a space before any NPC or text appears. Road sparsity versus town density creates arrival beats. Direct application of Section 6.3.

**What to avoid:** Stardew's optimistic, vivid palette. If a tile looks similar to a Stardew equivalent, it is probably too saturated. The warmth in 유랑단 must read as "what survived," not "what thrives."

**Why additive:** The only reference that models how arrival beats work through prop density contrast — road to town, road to enemy camp.

---

### 9.3 언더테일 (Undertale)

**What to take:** Near-static dialogue scene composition. Two characters, a simple or empty background, a small number of pixels doing all emotional work. In a recruitment scene, the recruitable character's one composed area (Section 6.4) should be the only visually organized space in the frame. Everything else is ambient.

**What to avoid:** Undertale's deliberate visual roughness as a design choice. The restraint borrowed is compositional, not quality-level. Each element in a quiet scene must be more carefully drawn than a combat frame — there is nowhere to hide.

**Why additive:** The only reference that models emotional restraint as a visual technique — how to make a recruitment moment feel heavier than the combat around it.

---

### 9.4 Hyper Light Drifter

**What to take:** Two-era tile adjacency technique. Intact structural tiles placed against crumbled variants of the same tile family, with overgrowth on vertical surfaces. Every major structure uses a "built" tile variant and a "broken/patched" variant in deliberate adjacency. Direct implementation guide for Section 6.1.

**What to avoid:** Hyper Light Drifter's cool, high-contrast, melancholic palette. Its ruins communicate annihilation. 유랑단's decay is ordinary — things fell apart because people couldn't keep them up. Extract only the tile placement logic; apply 유랑단's warm Neutral Band, not HLD's blue-greys.

**Why additive:** The only reference that answers: "How do two tile variants side by side read as fifty years of decline?"

---

### 9.5 Final Fantasy Tactics (PSX original)

**What to take:** Silhouette differentiation for a large, mixed cast at small sprite scale. Every job class reads from silhouette alone: one distinguishing axis change per archetype (width, height, or asymmetry). Direct precedent for Section 5.2's "one silhouette departure per companion" rule.

**What to avoid:** FFT's class-uniform design logic — multiple characters of the same job look identical. In 유랑단, the silhouette departure belongs to a specific person, not their function. Two warrior companions must use different silhouette axes. The departure signals the individual, not the role.

**Why additive:** The only reference that answers: "What does the ninth companion look like when eight already exist?"

---

*Art Director Sign-Off (AD-ART-BIBLE): Skipped — Lean mode (2026-04-16)*
