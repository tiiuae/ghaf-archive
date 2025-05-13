verify_image() {
	echo "Verifying image signature..."
	nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- \
		--cert INT-Ghaf-Devenv-Image \
		--path "$1" \
		--sigfile "$2"
}

verify_provenance() {
	echo "Verifying provenance signature..."
	nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- \
		--cert INT-Ghaf-Devenv-Provenance \
		--path "$1" \
		--sigfile "$2"
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
