ARTIFACTS_URL="https://ghaf-jenkins-controller-prod.northeurope.cloudapp.azure.com/artifacts/ghaf-nightly-pipeline/build_131-commit_3b5a09887591d172c568bbb13b5a3c3d61407abc/"
BUILD_NAME="${ARTIFACTS_URL%/}"
BUILD_NAME="${BUILD_NAME##*/}"
ARTIFACTS_DOWNLOAD_DIR="/tmp/$BUILD_NAME"
DOWNLOAD=1

if [ -d "$ARTIFACTS_DOWNLOAD_DIR" ]; then
	read -r -p "$ARTIFACTS_DOWNLOAD_DIR exists, skip download step? [y/N] " response
	response=${response,,} # lower
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		echo "Using files already present"
		DOWNLOAD=0
	else
		DOWNLOAD=1
	fi
fi

if [ "$DOWNLOAD" == 1 ]; then
	echo "[+] Checking all files are present before downloading..."
	./check-all-targets.sh "$ARTIFACTS_URL"

	read -r -p "OK to continue downloading? [y/N] " response
	response=${response,,} # lower
	if [[ ! "$response" =~ ^(yes|y)$ ]]; then
		echo "Aborting..."
		exit 0
	fi

	echo "[+] Downloading artifacts"
	./download-artifacts.sh -u "$ARTIFACTS_URL" -o "$ARTIFACTS_DOWNLOAD_DIR"
fi

# 3. verify sigs

# 4. upload to s3
