<div align="center">
  <img src="assets/flick_app_logo.png" width="128" alt="Flick">
  <h1>Flick</h1>
  <p>A macOS notch companion with a living AI pet.</p>
</div>

---

Flick puts a pet in your MacBook notch. It watches your Claude Code sessions, reacts to what you're doing, and you can talk to it. It also handles tool approvals, tracks your usage, and replaces your system HUD — all from the notch.

## What Makes Flick Different

### Talk to Your Pet
Chat with your buddy through any LLM provider — OpenAI, Anthropic, Grok, or local models (Ollama, LM Studio). Each of the 18 species has a unique personality. Your dragon is sassy. Your capybara is chill. Your ghost is spooky but friendly. Conversations stream in real-time.

### Pet It
Tap your buddy for a happy animation. Rapid-tap for excited reactions with hearts. It knows when you're paying attention.

### Stats & Leveling
Your buddy earns XP from your coding sessions — tool approvals, messages, petting. It levels up over time. An affection system tracks your bond from "Stranger" to "Soulmate". Tap the buddy's name to see the full stats card with lifetime counters.

### Custom Personality
Add your own personality traits in Settings. Want your duck to be obsessed with semicolons? Your robot to speak in haiku? Write it in and it becomes part of who they are.

### Security Hardened
Flick includes security improvements over the upstream project — hook integrity verification, socket authentication, scoped permissions, and structured logging with privacy annotations.

### Always Visible
The notch stays visible even over fullscreen apps. No hiding, no disappearing.

## Claude Code Integration

- **Live session monitoring** — Track multiple concurrent Claude Code sessions
- **Permission approvals** — Approve or deny tool executions from the notch
- **Chat interface** — View conversation history with markdown rendering
- **Usage tracking** — Session and weekly API utilization at a glance
- **Multiplexer support** — Works with cmux and tmux sessions
- **Auto-setup** — Hooks install automatically on first launch

## Buddy Chat Providers

| Provider | Default Model | Notes |
|----------|--------------|-------|
| OpenAI | gpt-5-nano | Responses API, streaming |
| Anthropic | claude-sonnet-4-6 | Messages API |
| Grok (xAI) | grok-3-mini-fast | Chat Completions |
| Local | default | localhost:1234, Ollama/LM Studio |

## Notch Utilities

- Music player with album art and visualizer
- Calendar events at a glance
- Battery status and charging indicator
- Custom volume and brightness HUD
- Drag-and-drop file shelf
- Webcam mirror
- Customizable keyboard shortcuts

## 18 Buddy Species

duck, goose, blob, cat, dragon, octopus, owl, penguin, turtle, snail, ghost, axolotl, capybara, cactus, robot, rabbit, mushroom, chonk — each with unique ASCII art, animations, and chat personality. Customize eyes, hats, rarity, and name.

## Install

```bash
git clone https://github.com/JOSH1059/Flick.git
cd Flick
open buddi.xcodeproj
```

Requires Xcode. Set your signing team in Signing & Capabilities for both the `buddi` and `BuddiXPCHelper` targets, then Cmd+R.

**Requirements:** macOS 15.0+, MacBook with notch (or external display), [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed.

## How It Works

```
Claude Code → Hooks → Unix Socket → Flick → Notch UI
```

Flick registers hooks with Claude Code on launch. When Claude emits events — tool use, session start/end, permission requests — the hooks forward them over a Unix domain socket. The app maps events to buddy animations and UI state.

## Lineage

Flick is a fork of [Buddi](https://github.com/talkvalue/Buddi) by TalkValue, which was built on [boring.notch](https://github.com/TheBoredTeam/boring.notch) by TheBoredTeam and [Claude Island](https://github.com/farouqaldori/claude-island) by farouqaldori. See [NOTICE](NOTICE) for full attribution.

## License

[GNU General Public License v3.0](LICENSE)
