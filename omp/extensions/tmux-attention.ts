import { execFile } from "node:child_process";

// omp -> tmux "needs you" signal.
//
// When an interactive omp session finishes a turn (the agent stopped and is
// waiting on the user), it raises two tmux markers for the pane it runs in:
//
//   * pane option   @omp_attn_pane -> a dot on that pane's border
//                                     (bin/tmux.conf pane-border-format)
//   * window option @omp_attn_win  -> a dot on that window's status entry
//                                     (bin/tmux-theme.sh window-status-format)
// The two options use DISTINCT names on purpose: tmux resolves #{?@opt} in a
// format by walking pane -> window -> session -> global, so a single
// window-scoped @omp_attn would bleed into EVERY pane border (and a pane-scope
// unset could never clear it). Separate names keep each marker readable only at
// its own scope.
//
// The pane dot pinpoints WHICH agent is waiting (you run several omp panes per
// window); the window dot is the cross-window glance ("which window needs me")
// from anywhere in the status bar. Both clear the instant you engage: tmux
// select hooks (bin/tmux-theme.sh) drop the pane flag when you focus that pane
// and the window flag when you enter that window, and `turn_start` here drops
// the pane flag when you send the next message.
//
// Gating: by default a marker is NOT raised for the thing you are already
// looking at -- the pane dot is skipped when that pane is focused, the window
// dot when that window is current. Set OMP_ATTN_ALWAYS=1 to raise both every
// turn regardless (useful to confirm it fires, or if you want a signal on every
// completion).
//
// Loaded globally via ~/.omp/agent/extensions -> omp/extensions (install.conf.yaml),
// so every profile gets it with no per-launch flag. Only the interactive
// top-level TUI signals: print mode and task subagents report hasUI=false.

type Handler = (event: unknown, ctx: unknown) => void | Promise<void>;
interface ExtensionAPI {
	on(event: string, handler: Handler): void;
}

const PANE = process.env.TMUX_PANE;
const IN_TMUX = Boolean(process.env.TMUX) && Boolean(PANE);
const ALWAYS = process.env.OMP_ATTN_ALWAYS === "1";

// Fire-and-forget: tmux calls are sub-millisecond and must never block a turn.
function tmux(args: string[]): void {
	execFile("tmux", args, { timeout: 2000 }, () => {});
}

function tmuxCapture(args: string[]): Promise<string> {
	const { promise, resolve } = Promise.withResolvers<string>();
	execFile("tmux", args, { timeout: 2000 }, (err, stdout) => {
		resolve(err ? "" : String(stdout).trim());
	});
	return promise;
}

function hasInteractiveUI(ctx: unknown): boolean {
	if (ctx && typeof ctx === "object" && "hasUI" in ctx) {
		return ctx.hasUI === true;
	}
	return false;
}

export default function tmuxAttention(pi: ExtensionAPI): void {
	if (!IN_TMUX || !PANE) return;
	const pane = PANE;

	// A new turn means the user just engaged this pane -> drop its waiting flag.
	pi.on("turn_start", () => {
		tmux(["set-option", "-up", "-t", pane, "@omp_attn_pane"]);
		tmux(["refresh-client", "-S"]);
	});

	// Turn finished: the agent is waiting on the user. Flag the pane (border) and
	// its window (status), each only if the user isn't already looking at it.
	pi.on("turn_end", async (_event, ctx) => {
		if (!hasInteractiveUI(ctx)) return;
		const state = await tmuxCapture([
			"display-message",
			"-p",
			"-t",
			pane,
			"#{pane_active}|#{window_active}",
		]);
		const [paneActive, windowActive] = state.split("|");
		if (ALWAYS || paneActive !== "1") {
			tmux(["set-option", "-p", "-t", pane, "@omp_attn_pane", "1"]);
		}
		if (ALWAYS || windowActive !== "1") {
			tmux(["set-option", "-w", "-t", pane, "@omp_attn_win", "1"]);
		}
		tmux(["refresh-client", "-S"]);
	});
}
