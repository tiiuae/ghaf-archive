verify_image() {
	nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- \
		--cert INT-Ghaf-Devenv-Image \
		--path "$1" \
		--sigfile "$2"
}

verify_provenance() {
	nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- \
		--cert INT-Ghaf-Devenv-Provenance \
		--path "$1" \
		--sigfile "$2"
}

BUILD_DIR="$1"

for dir in "$BUILD_DIR"/*/; do
	echo "$dir"
done
