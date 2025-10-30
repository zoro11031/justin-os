#!/usr/bin/env bash
# Install popular Nerd Fonts during image build
# Includes MesloLGS NF (for Powerlevel10k) and other common developer fonts
set -euo pipefail

# Exit codes
readonly E_DOWNLOAD=1
readonly E_EXTRACT=2
readonly E_CACHE=3
readonly E_SELINUX=4

# Create temporary directory
TEMP_DIR=$(mktemp -d) || exit 1
trap "rm -rf ${TEMP_DIR}" EXIT

# Nerd Fonts version
readonly NF_VERSION="v3.4.0"
readonly NF_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_VERSION}"

# Base font directory
readonly FONT_BASE_DIR="/usr/share/fonts/nerd-fonts"
mkdir -p "${FONT_BASE_DIR}"

# Nerd Fonts to download (popular coding fonts)
# Note: JetBrainsMono and FiraCode are already installed via Fedora packages
# We'll add the Nerd Font versions for additional glyphs/icons
declare -A NERD_FONTS=(
  ["Hack"]="hack"
  ["CascadiaCode"]="cascadia-code"
  ["Iosevka"]="iosevka"
  ["SourceCodePro"]="source-code-pro"
)

echo "=========================================="
echo "Installing Nerd Fonts"
echo "=========================================="

# Download and install Nerd Font archives
for font_name in "${!NERD_FONTS[@]}"; do
  font_dir="${NERD_FONTS[$font_name]}"
  echo ""
  echo "Installing ${font_name}..."

  cd "${TEMP_DIR}"

  # Download font archive
  echo "  Downloading ${font_name}.zip..."
  if ! curl -L -f --retry 3 --retry-delay 5 --max-time 300 \
    -o "${font_name}.zip" \
    "${NF_BASE_URL}/${font_name}.zip"; then
    echo "ERROR: Failed to download ${font_name}" >&2
    exit ${E_DOWNLOAD}
  fi

  # Extract to font directory
  echo "  Extracting to ${FONT_BASE_DIR}/${font_dir}..."
  mkdir -p "${FONT_BASE_DIR}/${font_dir}"
  if ! unzip -q -o "${font_name}.zip" -d "${FONT_BASE_DIR}/${font_dir}"; then
    echo "ERROR: Failed to extract ${font_name}" >&2
    exit ${E_EXTRACT}
  fi

  # Clean up zip file
  rm -f "${font_name}.zip"

  echo "  ✓ ${font_name} installed"
done

# Install MesloLGS NF for Powerlevel10k (separate direct download)
echo ""
echo "Installing MesloLGS NF (Powerlevel10k official font)..."
readonly MESLO_BASE_URL="https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master"
readonly MESLO_DIR="${FONT_BASE_DIR}/meslolgs-nf"
mkdir -p "${MESLO_DIR}"

readonly MESLO_FILES=(
  "MesloLGS NF Regular.ttf"
  "MesloLGS NF Bold.ttf"
  "MesloLGS NF Italic.ttf"
  "MesloLGS NF Bold Italic.ttf"
)

for font in "${MESLO_FILES[@]}"; do
  echo "  Downloading ${font}..."
  if ! curl -L -f --retry 3 --retry-delay 5 --max-time 60 \
    -o "${MESLO_DIR}/${font}" \
    "${MESLO_BASE_URL}/${font// /%20}"; then
    echo "ERROR: Failed to download ${font}" >&2
    exit ${E_DOWNLOAD}
  fi
done

echo "  ✓ MesloLGS NF installed"

# Fix SELinux contexts on font directory
echo ""
echo "Restoring SELinux contexts..."
if ! restorecon -R /usr/share/fonts/; then
  echo "ERROR: Failed to restore SELinux contexts" >&2
  exit ${E_SELINUX}
fi

# Regenerate font cache
echo "Regenerating font cache..."
if ! fc-cache -f; then
  echo "ERROR: Failed to regenerate font cache" >&2
  exit ${E_CACHE}
fi

echo ""
echo "=========================================="
echo "Nerd Fonts installation complete!"
echo "=========================================="
echo ""
echo "Installed fonts:"
echo "  - MesloLGS NF (Powerlevel10k)"
for font_name in "${!NERD_FONTS[@]}"; do
  echo "  - ${font_name}"
done
echo ""
echo "Note: JetBrainsMono and FiraCode are also available"
echo "      via Fedora packages (already installed)"
echo ""
exit 0
