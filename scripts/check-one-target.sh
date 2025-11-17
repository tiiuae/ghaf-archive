#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2022-2025 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

# Color
GREEN='\e[32m'
RED='\e[31m'
RESET='\e[0m'

show_help() {
	echo "Usage: $0 <BASE_URL> <SUBDIR>"
	echo
	echo "This script checks for the presence of expected files and folders at the specified URL."
	echo
	echo "Arguments:"
	echo "  BASE_URL   The base URL where the artifacts are located."
	echo "  SUBDIR     The subdir where the artifacts are located."
	echo
	echo "Example:"
	echo "  $0 https://example.com/artifacts/path/ "
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	show_help
	exit 0
fi

if [ -z "$1" ]; then
	echo -e "${RED}Error: No BASE_URL provided.${RESET}"
	show_help
	exit 1
fi
BASE_URL="${1%/}"

if [ -z "$2" ]; then
	echo -e "${RED}Error: No SUBDIR provided.${RESET}"
	show_help
	exit 1
fi
SUBDIR="${2%/}"

if ! curl --head --silent --fail "$BASE_URL" >/dev/null; then
	echo -e "${RED}Error: The BASE_URL is not reachable or the server is down.${RESET}"
	exit 1
fi

expected_files=(
	"scs/$SUBDIR/provenance.json"
	"scs/$SUBDIR/provenance.json.sig"
	"test-results/$SUBDIR/Robot-Framework/test-suites/bat/log.html"
	"test-results/$SUBDIR/Robot-Framework/test-suites/bat/output.xml"
	"test-results/$SUBDIR/Robot-Framework/test-suites/bat/report.html"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relayboot/log.html"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relayboot/output.xml"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relayboot/report.html"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relay-turnoff/log.html"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relay-turnoff/output.xml"
	"test-results/$SUBDIR/Robot-Framework/test-suites/relay-turnoff/report.html"
)

image_files=(".raw.zst" ".img.zst")
missing_files=()

check_file() {
	local url=$1
	if curl --head --silent --fail "$url" >/dev/null; then
		echo -e "${GREEN}✓ Found${RESET}"
		return 0
	else
		return 1
	fi
}

check_expected_files() {
	for file in "${expected_files[@]}"; do
		echo -n "Checking ${file} ... "
		if ! check_file "$BASE_URL/$file"; then
			echo -e "${RED}✗ Missing${RESET}"
			missing_files+=("$file")
		fi
	done
}

check_image_files() {
	local sig_file=""
	for dir in "" "sd-image"; do
		local img_url="${BASE_URL}/${SUBDIR}/${dir}/"
		local contents
		contents=$(curl --silent "$img_url")

		for img_file in "${image_files[@]}"; do
			img_name=$(echo "$contents" | grep -m1 -oE "[^/>]+${img_file}")
			if [ ! -z "$img_name" ]; then
				echo -e "Checking ${SUBDIR}/${dir}/*${img_file} ... ${GREEN}✓ Found${RESET}"
				sig_file="$BASE_URL/scs/${SUBDIR}/${dir}/${img_name}.sig"
		        echo -n "Checking scs/${SUBDIR}/${dir}/${img_name}.sig ... "
	            if ! check_file "$sig_file"; then
			        echo -e "${RED}✗ Missing${RESET}"
					missing_files+=("$sig_file")
				fi
			fi
		done
	done
	if [ -z "$sig_file" ]; then
	 	echo -e "Checking ${SUBDIR}:IMAGE_FILE ... ${RED}✗ Missing${RESET}"
		missing_files+=("${SUBDIR}:IMAGE_FILE")
	fi
}

print_summary() {
	echo -e "\nVerification complete:"
	if [ ${#missing_files[@]} -eq 0 ]; then
		echo -e "${GREEN}✅ All expected artifacts are present!${RESET}"
	else
		echo -e "${RED}❌ Missing Resources:${RESET}"
		printf '  - %s\n' "${missing_files[@]}"
		exit 1
	fi
}

main() {
	echo "Checking '${SUBDIR}' artifacts in ${BASE_URL} ..."
	check_expected_files
	check_image_files
	print_summary
}

main "$@"
