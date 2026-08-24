#!/usr/bin/env python3
import os
import shutil
from pathlib import Path

DRY_RUN = False

moves = []

def move(src, dst):
    src_path = Path(src)
    dst_path = Path(dst)
    if not src_path.exists():
        print(f"  [SKIP]  {src}  →  not found")
        return
    if dst_path.exists():
        print(f"  [SKIP]  {src}  →  destination already exists: {dst}")
        return
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    if DRY_RUN:
        print(f"  [DRY]   {src}  →  {dst}")
    else:
        shutil.move(str(src_path), str(dst_path))
        print(f"  [MOVE]  {src}  →  {dst}")
    moves.append((src, dst))

def archive(src, reason=""):
    src_path = Path(src)
    dst = f"Archive/{src_path.name}"
    if reason:
        print(f"          ({reason})")
    move(src, dst)

def ensure_dir(path):
    if not DRY_RUN:
        Path(path).mkdir(parents=True, exist_ok=True)

if not Path("README.md").exists():
    print("ERROR: Run this from the root of the cr_powerbi repo.")
    exit(1)

print("=" * 60)
print(f"cr_powerbi cleanup — {'DRY RUN' if DRY_RUN else 'LIVE'}")
print("=" * 60)

print("\n[1] Creating target folders...")
for folder in ["notebooks", "themes", "docs", "Archive"]:
    ensure_dir(folder)
    print(f"  [OK]    {folder}/")

print("\n[2] Moving active solution files...")

if Path("themes/CRM_Dark_Navy_Theme_V2.json").exists():
    print("  [SKIP]  themes/CRM_Dark_Navy_Theme_V2.json  →  already in place")
elif Path("CRM_Dark_Navy_Theme_V2.json").exists():
    move("CRM_Dark_Navy_Theme_V2.json", "themes/CRM_Dark_Navy_Theme_V2.json")
else:
    print("  [WARN]  CRM_Dark_Navy_Theme_V2.json not found — add manually to themes/")

for nb in ["PROD_Capacity_Notebook.ipynb", "PROD_Capacity_Notebook.py"]:
    if Path(f"notebooks/{nb}").exists():
        print(f"  [SKIP]  notebooks/{nb}  →  already in place")
        break
    elif Path(nb).exists():
        move(nb, f"notebooks/{nb}")
        break
else:
    print("  [WARN]  PROD_Capacity_Notebook not found — export from Fabric and add to notebooks/")

if Path("V4PROD_LAKEHOUSE_ChangeRequest_Analytics.pbix").exists():
    print("  [OK]    V4PROD_LAKEHOUSE_ChangeRequest_Analytics.pbix  →  in root")
else:
    print("  [WARN]  V4PROD_LAKEHOUSE_ChangeRequest_Analytics.pbix not found")

print("\n[3] Archiving stray root files...")
root_keepers = {
    "README.md", ".gitattributes", ".gitignore",
    "V4PROD_LAKEHOUSE_ChangeRequest_Analytics.pbix",
    "cleanup_cr_powerbi.py"
}
root_keeper_dirs = {"notebooks", "themes", "docs", "Archive"}

for item in Path(".").iterdir():
    if item.name.startswith("."):
        continue
    if item.name in root_keepers:
        continue
    if item.is_dir() and item.name in root_keeper_dirs:
        continue
    if item.is_file():
        archive(str(item), reason="stray root file")
    elif item.is_dir():
        print(f"  [WARN]  Unexpected folder: {item.name}/ — review manually")

print("\n" + "=" * 60)
print(f"Done. {len(moves)} file(s) moved.")
print("\nNext steps:")
print("  git status")
print("  git add -A")
print('  git commit -m "chore: reorganise repo into clean structure"')
print("  git push")
