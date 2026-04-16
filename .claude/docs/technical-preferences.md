# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Compatibility Renderer (2D pixel art 최적, 저사양 호환, D3D12/Vulkan 불필요)
- **Physics**: Godot Physics 2D (내장 2D 물리. Jolt는 3D 전용 — 이 프로젝트 미사용)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows / Linux / macOS via Steam)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (Steam Deck 호환 권장 — 모든 핵심 액션은 gamepad 매핑 필요)
- **Touch Support**: None
- **Platform Notes**: UI는 마우스 hover 없이도 동작해야 함 (Steam Deck). 키 리바인딩 지원 권장.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`, `CompanionData`)
- **Variables**: snake_case (e.g., `move_speed`, `current_health`)
- **Functions**: snake_case (e.g., `take_damage()`, `join_party()`)
- **Signals/Events**: snake_case 과거형 (e.g., `health_changed`, `companion_joined`, `quest_completed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`, `companion_data.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`, `CompanionBase.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `BASE_MOVE_SPEED`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 200 (2D pixel art 기준 — CanvasItem 배칭 활용)
- **Memory Ceiling**: 512 MB (2D 인디 게임 기준 보수적 상한)

## Testing

- **Framework**: GUT (Godot Unit Testing) — Godot 표준 단위 테스트 프레임워크
- **Minimum Coverage**: TBD — MVP 이후 결정
- **Required Tests**: 영입 조건 판정 로직, 전투 데미지 공식, 퀘스트 상태 머신

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here ONLY when actively integrating them -->
- GUT (Godot Unit Testing) — 테스트 전용, 런타임 제외

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
