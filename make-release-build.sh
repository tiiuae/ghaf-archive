ARTIFACTS_URL="https://ghaf-jenkins-controller-prod.northeurope.cloudapp.azure.com/artifacts/ghaf-nightly-pipeline/build_131-commit_3b5a09887591d172c568bbb13b5a3c3d61407abc/"
BUILD_NAME="${ARTIFACTS_URL%/}"
BUILD_NAME="${BUILD_NAME##*/}"
ARTIFACTS_DOWNLOAD_DIR="/tmp/$BUILD_NAME"

# 1. download artifacts

if [ -d "$ARTIFACTS_DOWNLOAD_DIR" ]; then
	echo "$ARTIFACTS_DOWNLOAD_DIR exists, assuming download is already done..."
else
	./download-artifacts.sh -u "$ARTIFACTS_URL" -o "$ARTIFACTS_DOWNLOAD_DIR"
fi

# 2. check files

# 3. verify sigs

# 4. upload to s3
