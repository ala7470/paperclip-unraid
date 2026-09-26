#!/usr/bin/env bash
# Validate the Paperclip Unraid Docker Manager template.
# Usage: bash scripts/validate_template.sh [path/to/paperclip.xml]
set -euo pipefail

TEMPLATE="${1:-$(dirname "$0")/../unraid/paperclip.xml}"
ICON="$(dirname "$TEMPLATE")/paperclip-icon.png"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$TEMPLATE" ]] || fail "template not found: $TEMPLATE"

# 1. XML well-formedness
python3 - "$TEMPLATE" <<'EOF'
import sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.argv[1])
root = tree.getroot()
if root.tag != "template":
    sys.exit(f"FAIL: root element must be <template>, got <{root.tag}>")
name = root.findtext("Name")
if not name or name != "Paperclip":
    sys.exit(f"FAIL: Name must be 'Paperclip', got {name!r}")

required_top = ["Name", "Description", "Repository", "Branch", "Params", "Variable", "Port", "Path"]
for tag in required_top:
    if root.find(tag) is None:
        sys.exit(f"FAIL: missing required element <{tag}>")

repo = root.findtext("Repository")
if repo != "ghcr.io/paperclipai/paperclip":
    sys.exit(f"FAIL: Repository must be the official image, got {repo!r}")

branch = root.findtext("Branch")
import re
if not branch:
    sys.exit("FAIL: Branch (image tag) must be set")
if branch == "latest":
    print("WARN: Branch tracks 'latest' (auto-follows stable upstream releases; see docs/UPDATE.md)")
elif not re.fullmatch(r"\d{4}\.\d{3,4}\.\d+", branch):
    sys.exit(f"FAIL: Branch {branch!r} is not a CalVer image tag (e.g. 2026.916.1) and not 'latest'")

params = root.find("Params")
for p in ["Network", "WebUI", "Shell", "Privileged", "Project", "Support", "Icon"]:
    if params is None or params.findtext(p) is None:
        sys.exit(f"FAIL: Params missing <{p}>")

webui = params.findtext("WebUI")
if webui != "http://[IP]:[?PORT]/":
    sys.exit(f"FAIL: WebUI must be 'http://[IP]:[?PORT]/', got {webui!r}")

if "CHANGE-ME" in params.findtext("Icon"):
    print("WARN: Icon URL still contains the CHANGE-ME placeholder - set it before distribution")

variables = {v.get("name"): v for v in root.findall("Variable")}
for var in ["HOST", "PORT", "PAPERCLIP_HOME", "PAPERCLIP_DEPLOYMENT_MODE",
            "PAPERCLIP_DEPLOYMENT_EXPOSURE", "PAPERCLIP_PUBLIC_URL",
            "BETTER_AUTH_SECRET", "USER_UID", "USER_GID"]:
    if var not in variables:
        sys.exit(f"FAIL: missing Variable {var}")

# No invented variables the image does not support
for var in ["PUID", "PGID", "UMASK"]:
    if var in variables:
        sys.exit(f"FAIL: unsupported variable {var} present - the image uses USER_UID/USER_GID")

if variables["BETTER_AUTH_SECRET"].get("required") != "true":
    sys.exit("FAIL: BETTER_AUTH_SECRET must be required=true")

ports = root.findall("Port")
if len(ports) != 1:
    sys.exit(f"FAIL: expected exactly one Port, got {len(ports)}")
p = ports[0]
if p.get("default") != "3100" or p.get("target") != "3100" or p.get("protocol") != "tcp":
    sys.exit(f"FAIL: Port must be 3100/tcp, got {p.attrib}")

paths = root.findall("Path")
if len(paths) != 1:
    sys.exit(f"FAIL: expected exactly one Path, got {len(paths)}")
p = paths[0]
if p.get("default") != "/mnt/user/appdata/paperclip" or p.get("target") != "/paperclip":
    sys.exit(f"FAIL: Path must be /mnt/user/appdata/paperclip -> /paperclip, got {p.attrib}")

print("XML checks passed: name, official image, tag, ports, paths, variables")
EOF

# 2. Safety checks: no secrets, no privileged mode
grep -q "<Privileged>no</Privileged>" "$TEMPLATE" || fail "template must not be privileged"
if grep -Eiq 'BETTER_AUTH_SECRET="?[^ <]' "$TEMPLATE" && ! grep -q 'name="BETTER_AUTH_SECRET"' "$TEMPLATE"; then
    fail "template may contain a hardcoded secret"
fi

# 3. Icon sanity: valid PNG, >= 128x128
[[ -f "$ICON" ]] || fail "icon not found: $ICON"
python3 - "$ICON" <<'EOF'
import sys, struct
with open(sys.argv[1], "rb") as f:
    d = f.read(33)
if d[:8] != b"\x89PNG\r\n\x1a\n":
    sys.exit("FAIL: icon is not a PNG")
w, h = struct.unpack(">II", d[16:24])
if w < 128 or h < 128:
    sys.exit(f"FAIL: icon too small ({w}x{h})")
print(f"icon ok: {w}x{h}")
EOF

echo "PASS: template validation complete"
