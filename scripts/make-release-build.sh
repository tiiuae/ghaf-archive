#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

set -u          # treat unset variables as an error and exit
set -o pipefail # exit if any pipeline command fails

################################################################################

MYNAME=$(basename "$0")

################################################################################

usage() {
	echo "Usage: $MYNAME "
	echo ""
	echo "Make a Ghaf release"
	echo ""
	echo ""
	echo "Options:"
	echo " -h    Print this help message"
	echo " -t    ghaf tag/version, e.g. 'ghaf-25.05'"
	echo " -b    Hetzner bucket name (default: ghaf-artifacts)"
	echo " -a    URL to the artifacts to download"
	echo ""
	echo "Example:"
	echo ""
	echo "  ./$MYNAME -t ghaf-25.11 -a https://ci-release.vedenemo.dev/artifacts/ghaf-release-candidate/20251115_140253267-commit_1f425edf99fbda513953bd85184bf1d8fe005d09/"
	echo ""
}

################################################################################

argparse() {
	OPTIND=1; GHAF_VERSION=""; BUCKET="ghaf-artifacts"; ARTIFACTS_URL="";
	while getopts "ht:b:a:" copt; do
		case "${copt}" in
		h)
			usage
			exit 0
			;;
		t)
			GHAF_VERSION="$OPTARG"
			;;
		b)
			BUCKET="$OPTARG"
			;;
		a)
			ARTIFACTS_URL="$OPTARG"
			BUILD_PATH=$(echo "${ARTIFACTS_URL%/}" | cut -d/ -f4-)
			ARTIFACTS_LOCATION="/tmp/$BUILD_PATH"
			;;
		*)
			echo "unrecognized option"
			usage
			exit 1
			;;
		esac
	done
	shift $((OPTIND - 1))
	if [ -n "$*" ]; then
		echo "unsupported positional argument(s): '$*'"
		exit 1
	fi
	if [ -z "$ARTIFACTS_URL" ]; then
		echo "missing mandatory option (-a)"
		usage
		exit 1
	fi
	if [ -z "$GHAF_VERSION" ]; then
		echo "missing mandatory option (-t)"
		usage
		exit 1
	fi
}

check_files() {
	echo "[+] Checking all files are present before downloading..."
	./check-all-targets.sh "$ARTIFACTS_URL"
}

download_artifacts() {
	echo "[+] Downloading artifacts"
	./download-artifacts.sh -u "$ARTIFACTS_URL" -o /tmp
}

prepare_artifacts() {
	# Remove all index.html files
	find "$ARTIFACTS_LOCATION" -name "index.html" -type f -delete
	# Move all subdirs from scs/* and test-results/* to ARTIFACTS_LOCATION subdirs
	for dir in "$ARTIFACTS_LOCATION"/*/; do
		if [ ! -d "$dir" ]; then contine; fi
		subdir=$(basename "$dir")
		if [ -d "$ARTIFACTS_LOCATION/scs/$subdir" ]; then
			mv "$ARTIFACTS_LOCATION/scs/$subdir" "$ARTIFACTS_LOCATION/$subdir/scs"
		fi
		if [ -d "$ARTIFACTS_LOCATION/test-results/$subdir" ]; then
			mv "$ARTIFACTS_LOCATION/test-results/$subdir" "$ARTIFACTS_LOCATION/$subdir/test-results"
		fi
	done
	# Remove now unnecessary scs/ and test-restuls/ directories
	rm -fr "$ARTIFACTS_LOCATION/scs" "$ARTIFACTS_LOCATION/test-results"
	# Remove possible doc target dir that should not be included in the release artifacts
	find "$ARTIFACTS_LOCATION" -maxdepth 1 -name "*doc" -type d -exec rm -r {} +
}

verify_signatures() {
	echo "[+] Verifying signatures"
	./verify-signatures.sh "$ARTIFACTS_LOCATION"
}

ask_to_continue() {
	echo ""
	read -r -p "OK to continue $1? [y/N] " response
	response=${response,,} # lower
	if [[ ! "$response" =~ ^(yes|y)$ ]]; then
		echo "Aborting..."
		exit 0
	fi
}

create_tarballs() {
	echo "[+] Zipping up target directories"
	mkdir -p "/tmp/$GHAF_VERSION"
	for dir in "$ARTIFACTS_LOCATION"/*/; do
		target_reldir="$(basename "$dir")"
		tarball=${target_reldir#"packages."} # strip possible 'packages.' prefix
		tar -c -f "/tmp/$GHAF_VERSION/$tarball.tar" -C "$ARTIFACTS_LOCATION" "$target_reldir"
		echo " --> created /tmp/$GHAF_VERSION/$tarball.tar"
	done
}

upload_files() {
	echo "[+] Uploading tarballs to Hetzner"
	mc mirror "/tmp/$GHAF_VERSION" "hetzner/$BUCKET/$GHAF_VERSION"
}

exit_unless_command_exists() {
	if ! command -v "$1" &>/dev/null; then
		echo "command '$1' is not installed (Hint: are you inside a nix-shell?)"
		exit 1
	fi
}

main() {
	argparse "$@"
	exit_unless_command_exists mc
	exit_unless_command_exists tar

	echo "ARTIFACTS: $ARTIFACTS_URL"
	echo "GHAF VERSION: $GHAF_VERSION"
	echo "BUCKET: $BUCKET"

	DOWNLOAD=1
	if [ -d "$ARTIFACTS_LOCATION" ]; then
		read -r -p "$ARTIFACTS_LOCATION exists, skip download step? [y/N] " response
		response=${response,,} # lower
		if [[ "$response" =~ ^(yes|y)$ ]]; then
			echo "Using files already present"
			DOWNLOAD=0
		else
			DOWNLOAD=1
		fi
	fi

	if [ "$DOWNLOAD" == 1 ]; then
		check_files
		ask_to_continue "downloading"
		download_artifacts
	fi

	prepare_artifacts
	verify_signatures
	ask_to_continue "uploading"
	create_tarballs
	upload_files
}

main "$@"
