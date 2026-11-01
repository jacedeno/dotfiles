// Key launcher (migrated from herdr config.toml). Opened by mod.open from keys.json.
import { View, div } from "gpui-kit";
import { run, props, closeOverlay, layout } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const c of node?.children ?? []) { const f = find(c, id); if (f) return f; }
  return null;
}

function togglePanel(id) {
  const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
  if (!panel) return;
  if (!panel.hidden && body?.active === id) run("layout.hide", { id: "panel" });
  else { run("layout.select", { stack: "panel-body", child: id }); run("layout.show", { id: "panel" }); }
}

export default class Launcher extends View {
  init() {
    const overlay = props()?.overlay;
    if (!overlay) return;   // herdr-app check renders without an overlay: do nothing
    togglePanel("files");
    closeOverlay(overlay);
  }
  render() { return div(); }
}
