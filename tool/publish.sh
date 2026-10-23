#!/usr/bin/env bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}        🌸 Bloom Ecosystem Pub.dev Publishing Flow         ${NC}"
echo -e "${BLUE}============================================================${NC}"

# Topological publishing order
PACKAGES=(
  "packages/blooming"
  "packages/blooming_lints"
  "packages/blooming_extensions"
  "packages/blooming_test"
  "packages/blooming_flutter"
  "packages/blooming_flutter_test"
)

# Step 1: Pre-flight Checks
echo -e "\n${YELLOW}[Step 1/3] Running Pre-flight Checks...${NC}"

echo -n "  Checking git status... "
if [ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]; then
  echo -e "${RED}FAILED${NC}"
  echo -e "${RED}Error: Working directory has uncommitted changes. Please commit or stash first.${NC}"
  exit 1
fi
echo -e "${GREEN}CLEAN${NC}"

echo -n "  Checking code formatting... "
(cd "$ROOT_DIR" && dart format --output=none --set-exit-if-changed .) > /dev/null 2>&1
echo -e "${GREEN}PASS${NC}"

echo -n "  Checking static analysis... "
(cd "$ROOT_DIR" && dart analyze) > /dev/null 2>&1
echo -e "${GREEN}PASS${NC}"

# Step 2: Dry Run Validation
echo -e "\n${YELLOW}[Step 2/3] Validating packages (dry-run)...${NC}"
for rel_path in "${PACKAGES[@]}"; do
  pkg_dir="$ROOT_DIR/$rel_path"
  pkg_name=$(basename "$rel_path")
  echo -n "  Validating $pkg_name... "
  (cd "$pkg_dir" && dart pub publish --dry-run) > /dev/null 2>&1
  echo -e "${GREEN}0 Warnings${NC}"
done

FORCE=false
for arg in "$@"; do
  case $arg in
    -f|--force)
      FORCE=true
      ;;
  esac
done

# Step 3: Publishing
echo -e "\n${YELLOW}[Step 3/3] Ready for Publishing in Topological Order${NC}"
echo -e "Packages will be published in the following sequence:"
for i in "${!PACKAGES[@]}"; do
  echo "  $((i+1)). ${PACKAGES[$i]}"
done
echo ""

if [ "$FORCE" != true ]; then
  read -p "Do you want to proceed with interactive publishing? (y/N): " confirm
  if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
    echo -e "${YELLOW}Publishing aborted.${NC}"
    exit 0
  fi
fi

TOTAL_PACKAGES=${#PACKAGES[@]}
for idx in "${!PACKAGES[@]}"; do
  rel_path="${PACKAGES[$idx]}"
  pkg_dir="$ROOT_DIR/$rel_path"
  pkg_name=$(basename "$rel_path")
  pkg_version=$(grep '^version:' "$pkg_dir/pubspec.yaml" | awk '{print $2}')
  
  echo -e "\n${BLUE}------------------------------------------------------------${NC}"
  echo -e "${BLUE}  Package $((idx+1))/${TOTAL_PACKAGES}: ${GREEN}$pkg_name ($pkg_version)${NC}"
  echo -e "${BLUE}  Path: ${pkg_dir}${NC}"
  echo -e "${BLUE}------------------------------------------------------------${NC}"

  # Check if already published on pub.dev
  if curl -fs "https://pub.dev/api/packages/$pkg_name" 2>/dev/null | grep -q "\"version\":\"$pkg_version\""; then
    echo -e "${YELLOW}ℹ $pkg_name $pkg_version is already published on pub.dev. Skipping upload.${NC}"
    continue
  fi
  
  if [ "$FORCE" = true ]; then
    (cd "$pkg_dir" && dart pub publish --force)
  else
    (cd "$pkg_dir" && dart pub publish)
  fi
  
  echo -e "\n${GREEN}✔ $pkg_name published successfully!${NC}"
  
  if [ "$idx" -lt "$((TOTAL_PACKAGES - 1))" ]; then
    echo -e "${YELLOW}Waiting 15 seconds for pub.dev cache/indexing before the next package...${NC}"
    sleep 15
  fi
done

echo -e "\n${GREEN}============================================================${NC}"
echo -e "${GREEN}  🎉 All Bloom Ecosystem packages published successfully!  ${NC}"
echo -e "${GREEN}============================================================${NC}"
