#!/usr/bin/env python3
"""Status line for Claude Code and Antigravity CLI (agy).

Reads the session JSON payload on stdin and prints up to three rows:
rows 1 and 2 always print; row 3 prints when cache or quota/rate-limit
data is present.
"""
from datetime import datetime
import json, os, re, subprocess, sys, time

R = "\033[0m"; B = "\033[1m"
# Secondary text (labels, units). Do NOT use "\033[2m" (dim): on a dark theme it is
# nearly invisible. "\033[37m" is the terminal's normal white; if that still reads
# too faint, go up to "\033[97m" (bright white).
DIM = "\033[37m"
GRN = "\033[32m"; YLW = "\033[33m"; RED = "\033[31m"
CYN = "\033[36m"; MAG = "\033[35m"; BLU = "\033[34m"

def as_dict(v):
    return v if isinstance(v, dict) else {}

def sh(args, cwd):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True,
                              timeout=1).stdout.strip()
    except Exception:
        return ""

def parse_owner_repo(url):
    if not url:
        return ""
    m = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?$", url.strip().rstrip("/"))
    return f"{m.group(1)}/{m.group(2)}" if m else ""

def repo_and_git(cwd):
    """(owner/repo, branch + counters) cached per cwd for 5 s."""
    cache = f"/tmp/claude-{os.getuid()}/statusline-git.cache"
    now = time.time()
    entries = {}
    try:
        with open(cache) as f:
            raw = json.load(f)
        if isinstance(raw, dict) and "entries" in raw and isinstance(raw["entries"], dict):
            entries = raw["entries"]
            hit = entries.get(cwd)
            if isinstance(hit, dict) and now - hit.get("ts", 0) < 5:
                return hit.get("repo", ""), hit.get("out", "")
    except Exception:
        entries = {}

    branch = sh(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd)
    if not branch:
        return "", ""
    owner_repo = parse_owner_repo(sh(["git", "config", "--get", "remote.origin.url"], cwd))
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
        # Keep only recent entries so the cache stays tiny.
        entries = {k: v for k, v in entries.items()
                   if isinstance(v, dict) and now - v.get("ts", 0) < 300}
        entries[cwd] = {"ts": now, "repo": owner_repo, "out": out}
        with open(cache, "w") as f:
            json.dump({"entries": entries}, f)
    except Exception:
        pass
    return owner_repo, out

def bar(pct, width=12):
    pct = max(0, min(100, pct))
    filled = round(pct * width / 100)
    return "█" * filled + "░" * (width - filled)

def hue(pct):
    return RED if pct >= 90 else YLW if pct >= 70 else GRN

def human(n):
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.1f}k"
    return str(int(n))

def reset_in(ts):
    if not ts:
        return ""
    epoch = None
    if isinstance(ts, (int, float)):
        epoch = float(ts)
    elif isinstance(ts, str):
        try:
            epoch = float(ts)
        except ValueError:
            try:
                epoch = datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
            except ValueError:
                return ""
    if epoch is None:
        return ""
    mins = max(0, int((epoch - time.time()) // 60))
    return f"{mins//60}h{mins%60:02d}m" if mins >= 60 else f"{mins}m"

try:
    raw_in = sys.stdin.read()
    d = json.loads(raw_in) if raw_in.strip() else {}
    if not isinstance(d, dict):
        d = {}
except Exception:
    d = {}

ws = as_dict(d.get("workspace"))
cwd = ws.get("current_dir") or d.get("cwd") or os.getcwd()
ctx = as_dict(d.get("context_window"))
cu = as_dict(ctx.get("current_usage"))

# --- row 1: identity ---------------------------------------------------------
raw_model = d.get("model")
if isinstance(raw_model, dict):
    model = raw_model.get("display_name") or raw_model.get("id") or "?"
elif isinstance(raw_model, str) and raw_model:
    model = raw_model
else:
    model = "?"

raw_effort = d.get("effort")
if isinstance(raw_effort, dict):
    effort = raw_effort.get("level", "")
elif isinstance(raw_effort, str):
    effort = raw_effort
else:
    effort = ""

# Strip trailing "(High)" / "(Thinking)" badges that agy bakes into display_name
# so model + effort look identical to Claude Code.
think_badge = False
m_eff = re.match(r"^(.*?)\s*\((low|medium|high|xhigh|max|thinking)\)\s*$", model, re.I)
if m_eff:
    model = m_eff.group(1)
    badge = m_eff.group(2).lower()
    if badge == "thinking":
        think_badge = True
    elif not effort:
        effort = badge

tags = []
if d.get("fast_mode"):
    tags.append("fast")
raw_think = d.get("thinking")
think_on = (
    think_badge
    or (raw_think.get("enabled") if isinstance(raw_think, dict)
        else (raw_think.lower() not in ("", "off", "none", "false") if isinstance(raw_think, str)
              else bool(raw_think)))
    or bool(d.get("thinking_tokens") or ctx.get("thinking_tokens"))
)
if think_on:
    tags.append("think")
suffix = f"{DIM}[{'/'.join(tags)}]{R}" if tags else ""

git_repo, git = repo_and_git(cwd)
repo = as_dict(ws.get("repo"))
if repo.get("name"):
    where = f"{repo.get('owner')}/{repo.get('name')}" if repo.get("owner") else repo["name"]
elif git_repo:
    where = git_repo
else:
    where = os.path.basename(os.path.abspath(cwd)) or cwd

parts1 = [f"{B}{CYN}{model}{R}"]
if effort:
    parts1.append(f"{DIM}{effort}{R}")
if suffix:
    parts1.append(suffix)
parts1.append(f"{BLU}{where}{R}")
row1 = " ".join(parts1)
if git:
    row1 += f"  {git}"

# --- row 2: consumption ------------------------------------------------------
pct_raw = ctx.get("used_percentage") or 0
# Note: this is what the conversation holds RIGHT NOW, not the session total.
in_ctx = (
    ctx.get("total_input_tokens")
    or ctx.get("input_tokens")
    or ctx.get("total_tokens")
    or (cu.get("input_tokens", 0) + cu.get("cache_read_input_tokens", 0) + cu.get("cache_creation_input_tokens", 0))
    or 0
)
size = ctx.get("context_window_size") or ctx.get("max_tokens") or 0
if not pct_raw and in_ctx and size:
    pct_raw = in_ctx * 100 / size
elif not size and in_ctx and pct_raw:
    size = round(in_ctx * 100 / pct_raw)
pct = round(pct_raw)
c = hue(pct)

cost = as_dict(d.get("cost"))
usd = cost.get("total_cost_usd")
if usd is None:
    usd = (cost.get("estimated") or cost.get("total_usd") or 0.0) + (cost.get("subagent_usd") or 0.0)
secs = int(cost.get("total_duration_ms") or d.get("duration_ms") or 0) // 1000
clock = f"{secs//3600}h{(secs%3600)//60:02d}m" if secs >= 3600 else f"{secs//60}m{secs%60:02d}s"
has_api = "total_api_duration_ms" in cost or "api_duration_ms" in cost
api_s = int(cost.get("total_api_duration_ms") or cost.get("api_duration_ms") or 0) // 1000
api = f"{api_s//60}m{api_s%60:02d}s" if api_s >= 60 else f"{api_s}s"
plus = cost.get("total_lines_added") or 0
minus = cost.get("total_lines_removed") or 0

ctx_tok = f"{human(in_ctx)}{DIM}/{human(size)}{R}" if size else human(in_ctx)
time_seg = f"{DIM}⏱ {clock} (api {api}){R}" if has_api else f"{DIM}⏱ {clock}{R}"
row2 = f"{c}{bar(pct)}{R} {c}{pct}%{R} {DIM}ctx{R} {ctx_tok}  {YLW}${usd:.2f}{R}  {time_seg}"
if plus or minus:
    row2 += f"  {GRN}+{plus}{R}/{RED}-{minus}{R}"

# --- row 3: cache and quotas -------------------------------------------------
pc = as_dict(d.get("prompt_cache"))
bits = []
if pc.get("caching_observed"):
    hr = (pc.get("hit_ratio") or 0) * 100
    state = f"{GRN}warm{R}" if pc.get("warm") else f"{YLW}cold{R}"
    bits.append(f"{DIM}cache{R} {state} {hue(100-hr)}{hr:.0f}%{R} {DIM}hit · ttl {pc.get('ttl','?')}{R}")
elif cu.get("cache_read_input_tokens"):
    cr = cu.get("cache_read_input_tokens", 0)
    tot = cr + cu.get("input_tokens", 0) + cu.get("cache_creation_input_tokens", 0)
    if tot > 0:
        hr = cr * 100 / tot
        bits.append(f"{DIM}cache{R} {GRN}warm{R} {hue(100-hr)}{hr:.0f}%{R} {DIM}hit{R}")

rl = as_dict(d.get("rate_limits"))
for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
    seg = as_dict(rl.get(key))
    if seg:
        p = round(seg.get("used_percentage") or 0)
        bits.append(f"{DIM}{label}{R} {hue(p)}{p}%{R} {DIM}↺ {reset_in(seg.get('resets_at'))}{R}")

raw_quota = d.get("quota") or d.get("quotas")
buckets = []
if isinstance(raw_quota, list):
    buckets = [b for b in raw_quota if isinstance(b, dict)]
elif isinstance(raw_quota, dict):
    if isinstance(raw_quota.get("buckets"), list):
        buckets = [b for b in raw_quota["buckets"] if isinstance(b, dict)]
    else:
        for k, v in raw_quota.items():
            if isinstance(v, dict):
                buckets.append({"label": k, **v})

for b in buckets:
    lbl = b.get("label") or b.get("display_name") or b.get("name") or b.get("model") or "quota"
    if b.get("used_percentage") is not None:
        p = round(b["used_percentage"])
    elif b.get("remaining_percentage") is not None:
        p = round(100 - b["remaining_percentage"])
    elif b.get("remaining_fraction") is not None:
        p = round((1.0 - b["remaining_fraction"]) * 100)
    else:
        continue
    rst = reset_in(b.get("reset_time") or b.get("resets_at") or b.get("quota_resets"))
    seg_str = f"{DIM}{lbl}{R} {hue(p)}{p}%{R}"
    if rst:
        seg_str += f" {DIM}↺ {rst}{R}"
    bits.append(seg_str)

print(row1)
print(row2)
if bits:
    print("  ".join(bits))
