---
layout: ../layouts/Document.astro
title: Ghaf Signature Verification
---
## Signature verification step-by-step instructions

1. Download the target artifact you want from the release page (here represented as `archive.tar`)
2. Navigate to where the tar file is.
3. Extract the archive into a folder and enter it:

```sh
tar -xf archive.tar
cd archive
```

4. Locate the image file and its signature. Note that sometimes they are located in `sd-image` directory.

5. Run the verification script with the path of the image and signature:

```sh
nix run github:tiiuae/ci-yubi#verify -- \
    --cert INT-Ghaf-Devenv-Image \
    --path disk1.raw.zst \
    --sigfile disk1.raw.zst.sig  
```

6. You should see the following message upon successful signature verification:

```
Signature verification result: {'message': 'Signature Verification Result', 'is_valid': True}
```

7. The same instructions apply for the provenance file as well, located in the `scs` directory:

```sh
nix run github:tiiuae/ci-yubi#verify -- \
    --cert INT-Ghaf-Devenv-Image \
    --path scs/provenance.json \
    --sigfile scs/provenance.json.sig
```

```
Signature verification result: {'message': 'Signature Verification Result', 'is_valid': True}
```
