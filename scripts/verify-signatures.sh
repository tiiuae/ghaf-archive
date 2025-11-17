#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

set -e          # exit immediately if a command fails
set -u          # treat unset variables as an error and exit
set -o pipefail # exit if any pipeline command fails

KEYSDIR=$(realpath "$(dirname "$0")/../public/keys")

verify_image() {
	echo "Verifying image signature..."
	trg="$1"
	sig="$2"
	openssl dgst -verify \
		"$KEYSDIR/GhafInfraSignECP256.pub" -signature "$sig" "$trg"
}

verify_provenance() {
	echo "Verifying provenance signature..."
	trg="$1"
	sig="$2"
	openssl pkeyutl -verify -inkey \
		"$KEYSDIR/GhafInfraSignProv.pub" -pubin -sigfile "$sig" -in "$trg" -rawin
}

BUILD_DIR="$1"

for dir in "${BUILD_DIR%/}"/*/; do
	echo "$dir"

	img_file=$(find "$dir" -type f -name "*.zst" -o -name "*.img" -o -name "*.iso" | head -n 1)
	sig_file=$(find "$dir" -type f -name "$(basename "$img_file").sig" | head -n 1)

	if [[ -n "$img_file" && -n "$sig_file" ]]; then
		verify_image "$img_file" "$sig_file"
	else
		echo "[ !!! ] Missing image file or signature!"
	fi
	provenance_file="$dir"scs/provenance.json
	if [[ -f "$provenance_file" && -f "$provenance_file".sig ]]; then
		verify_provenance "$provenance_file" "$provenance_file".sig
	else
		echo "[ !!! ] Missing provenance file or signature!"
	fi

	echo ""
done
