#!/usr/bin/env python3
"""Status line para Claude Code. Lee el JSON de sesion por stdin y pinta dos filas."""
import json, os, subprocess, sys, time

R = "\033[0m"; B = "\033[1m"
# Texto secundario (etiquetas, unidades). NO uses "\033[2m" (dim): sobre un tema
# oscuro queda casi invisible. "\033[37m" es el blanco normal del terminal; si aun
# asi lo quieres mas fuerte, sube a "\033[97m" (blanco brillante).
DIM = "\033[37m"
GRN = "\033[32m"; YLW = "\033[33m"; RED = "\033[31m"
CYN = "\033[36m"; MAG = "\033[35m"; BLU = "\033[34m"

def sh(args, cwd):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True,
                              timeout=1).stdout.strip()
    except Exception:
        return ""

def git_segment(cwd):
    """Rama + contadores. Cacheado 5 s: git status es caro en repos grandes."""
    cache = "/tmp/claude-1000/statusline-git.cache"
    try:
        if time.time() - os.path.getmtime(cache) < 5:
            with open(cache) as f:
                data = json.load(f)
            if data.get("cwd") == cwd:
                return data["out"]
    except Exception:
        pass
    branch = sh(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    if not branch:
        return ""
    porcelain = sh(["git", "status", "--porcelain"], cwd)
    staged = sum(1 for l in porcelain.splitlines() if l[:1] not in (" ", "?", ""))
    dirty = sum(1 for l in porcelain.splitlines() if l[1:2] not in (" ", ""))
    out = f"{MAG}⎇ {branch}{R}"
    if staged:
        out += f" {GRN}+{staged}{R}"
    if dirty:
        out += f" {YLW}~{dirty}{R}"
    if not staged and not dirty:
        out += f" {DIM}clean{R}"
    try:
        os.makedirs(os.path.dirname(cache), exist_ok=True)
        with open(cache, "w") as f:
            json.dump({"cwd": cwd, "out": out}, f)
    except Exception:
        pass
    return out

def bar(pct, width=12):
    filled = round(pct * width / 100)
    return "█" * filled + "░" * (width - filled)

def hue(pct):
    return RED if pct >= 90 else YLW if pct >= 70 else GRN

def human(n):
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.1f}k"
    return str(n)

def reset_in(epoch):
    if not epoch:
        return ""
    mins = max(0, int((epoch - time.time()) // 60))
    return f"{mins//60}h{mins%60:02d}m" if mins >= 60 else f"{mins}m"

d = json.load(sys.stdin)
cwd = d.get("workspace", {}).get("current_dir") or d.get("cwd") or "."

# --- fila 1: identidad -------------------------------------------------------
model = d.get("model", {}).get("display_name", "?")
effort = d.get("effort", {}).get("level", "")
tags = []
if d.get("fast_mode"):
    tags.append("fast")
if d.get("thinking", {}).get("enabled"):
    tags.append("think")
suffix = f"{DIM}[{'/'.join(tags)}]{R}" if tags else ""

repo = d.get("workspace", {}).get("repo") or {}
where = f"{repo.get('owner')}/{repo.get('name')}" if repo.get("name") else os.path.basename(cwd)

row1 = f"{B}{CYN}{model}{R} {DIM}{effort}{R} {suffix} {BLU}{where}{R}"
git = git_segment(cwd)
if git:
    row1 += f"  {git}"

# --- fila 2: consumo ---------------------------------------------------------
ctx = d.get("context_window", {})
pct = ctx.get("used_percentage", 0)
size = ctx.get("context_window_size", 0)
# Ojo: es lo que ocupa la conversacion AHORA, no el acumulado de la sesion.
in_ctx = ctx.get("total_input_tokens", 0)
c = hue(pct)

cost = d.get("cost", {})
usd = cost.get("total_cost_usd", 0.0)
secs = cost.get("total_duration_ms", 0) // 1000
clock = f"{secs//3600}h{(secs%3600)//60:02d}m" if secs >= 3600 else f"{secs//60}m{secs%60:02d}s"
api_s = cost.get("total_api_duration_ms", 0) // 1000
api = f"{api_s//60}m{api_s%60:02d}s" if api_s >= 60 else f"{api_s}s"
plus, minus = cost.get("total_lines_added", 0), cost.get("total_lines_removed", 0)

row2 = (f"{c}{bar(pct)}{R} {c}{pct}%{R} {DIM}ctx{R} {human(in_ctx)}{DIM}/{human(size)}{R}"
        f"  {YLW}${usd:.2f}{R}"
        f"  {DIM}⏱ {clock} (api {api}){R}")
if plus or minus:
    row2 += f"  {GRN}+{plus}{R}/{RED}-{minus}{R}"

# --- fila 3: cache y cuotas --------------------------------------------------
pc = d.get("prompt_cache", {})
bits = []
if pc.get("caching_observed"):
    hr = pc.get("hit_ratio", 0) * 100
    state = f"{GRN}warm{R}" if pc.get("warm") else f"{YLW}cold{R}"
    bits.append(f"{DIM}cache{R} {state} {hue(100-hr)}{hr:.0f}%{R} {DIM}hit · ttl {pc.get('ttl','?')}{R}")

rl = d.get("rate_limits", {})
for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
    seg = rl.get(key)
    if seg:
        p = seg.get("used_percentage", 0)
        bits.append(f"{DIM}{label}{R} {hue(p)}{p}%{R} {DIM}↺ {reset_in(seg.get('resets_at'))}{R}")

print(row1)
print(row2)
if bits:
    print("  ".join(bits))
