# UI / UX

## Principles
- Never trap the player: every window has ✕, — (minimize) and responds to **Escape / B**. `UIController` keeps a stack; the top window closes first. Only one modal (confirm dialog) at a time.
- No invisible blockers; windows are `Active` frames of explicit size.
- HUD is read-only and always visible: phase, timer, status (role/team/state), score, centre countdown, toast feed, priority banner.
- Voting: a side panel lists the three candidates with live counts and "◀ you"; the *interaction* is walking onto a platform (signs in world).
- Results window lists placements with crowns and highlights you; auto-closes on the next Lobby/Intermission.
- Intro card shows name, one-line description, map and modifier for 5 s.
- Spectator bar: ◀ ▶ buttons (touch), Q/E, LB/RB.
- Side menu icons: Profile, Shop, Challenges, Settings — each a normal window.
- Admin panel: tabs by category, search, target field, three argument fields, output console, dangerous actions require confirmation. F9 / D-pad Up; a ContextAction touch button appears for admins on mobile.

## Device support
Touch: ContextActionService buttons for Sprint, Slide, Action, Admin. Controller: B closes, D-pad/bumpers navigate, `GuiService.SelectedObject` set on open. Text is `TextScaled` in world signs; screen UI uses fixed sizes ≥ 15 px.

## Stale-state prevention
All windows are created once at boot; state is rewritten on each event; `PhaseChanged` closes contextual windows; `_bannerToken` prevents late banner hides.
