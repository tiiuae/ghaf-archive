## Signature Verification of a Binary Image

In this example we verify a signature of a Ghaf package. These steps can be applied to any Ghaf package.
Notice that sometimes the binary image and the signature file are in sd-image directory.
Replace `$VERSION` in these instructions with the ghaf version, e.g. `ghaf-25-03`.

### Step-by-step instructions

Download and extract the package in an empty directory:

```sh
wget https://hel1.your-objectstorage.com/ghaf-artifacts/$VERSION/aarch64-linux.nvidia-jetson-orin-agx-debug.tar
tar -xf *.tar
cd aarch64-linux.nvidia-jetson-orin-agx-debug 
```

Verify the signature

```sh
nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- --cert INT-Ghaf-Devenv-Image --path disk1.raw.zst --sigfile disk1.raw.zst.sig  
```

Example output of successful signature verification:

```
Signature verification result: {'message': 'Signature Verification Result', 'is_valid': True}
```

---

## Signature Verification of the Provenance File

In this example we verify the signature of the SLSA provenance file.

### Step-by-step instructions

Download and extract the package in an empty directory:

```sh
wget https://hel1.your-objectstorage.com/ghaf-artifacts/$VERSION/aarch64-linux.nvidia-jetson-orin-agx-debug.tar
tar -xf *.tar
cd aarch64-linux.nvidia-jetson-orin-agx-debug/scs/
```

Verify the signature:

```sh
nix run github:tiiuae/ci-yubi/bdb2dbf#verify -- --path provenance.json --sigfile provenance.json.sig --cert INT-Ghaf-Devenv-Provenance
```

Example output of successful signature verification

```
Signature verification result: {'message': 'Signature Verification Result', 'is_valid': True}
```
