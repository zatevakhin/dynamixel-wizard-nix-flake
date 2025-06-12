# Dynamixel Wizard 2 – Nix flake

Reproducible, one‑command install of [**Dynamixel Wizard 2**](https://emanual.robotis.com/docs/en/software/dynamixel/dynamixel_wizard2/#software-installation) on any Linux host that has Nix with flakes enabled.

## Requirements

| what         | version                                                  |
| ------------ | -------------------------------------------------------- |
| **Nix**      | ≥ 2.19 with `experimental-features = nix-command flakes` |
| **Internet** | reach the Dropbox link (read below why) that hosts the official installer |
| **CPU**      | x86‑64 (Robotis ships only a 64‑bit build)               |


## What about Mac
- IDC (but it easy to do)

## Quick start

```bash
# clone the repo
$ git clone <this‑repo> wiz2-flake && cd wiz2-flake

# *build and launch* Dynamixel Wizard 2
$ nix run .
```

Nix builds the `dynamixel-wizard2` derivation (first run \~ 1 min), patches all
its libraries, then launches the program.


## Developer shell

```bash
$ nix develop      # drop into a shell with the package in $PATH
$ dynamixel        # start the wizard
```

The dev‑shell is handy for debugging the flake itself or running the wizard
alongside other dev tools.


## Flake outputs

| output                           | what you get                           |
| -------------------------------- | -------------------------------------- |
| `packages.x86_64-linux.default`  | the fully patched **Wizard 2** package |
| `apps.x86_64-linux.default`      | runnable app → used by `nix run`       |
| `devShells.x86_64-linux.default` | shell with the package + build tools   |


## Updating to a new Robotis release

1. Download the new `.run` installer from [Robotis website](https://emanual.robotis.com/docs/en/software/dynamixel/dynamixel_wizard2/#software-installation).
2. In *flake.nix* bump

   ```nix
   version = "<new‑version>";
   url     = "<new‑url>?dl=1";
   sha256  = lib.fakeSha256;  # temporary
   ```
3. Run

   ```bash
   nix build .
   ```

   The build will fail once and print the **real** SHA‑256.
4. Paste that hash back into *flake.nix* → rebuild → done.


## How it works (under the hood)

* Downloads the vendor installer (Qt Installer Framework) from [download page for Linux](https://www.robotis.com/service/download.php?no=1671),
then it redirects on [Dropbox](https://www.dropbox.com/s/csawv9qzl8m8e0d/DynamixelWizard2Setup-x86_64) where binary Linux installer is located.
* Patches its ELF header so it can run in the sandbox, then runs it **head‑less**
  with a fake `$HOME` so no UI or DBus interaction is needed.
* Removes the bundled, outdated OpenGL libs; `autoPatchelf` relinks everything
  against the host’s Qt 5.15, Mesa & other crap.
* Wraps the final launcher in `bin/dynamixel` with `QT_QPA_PLATFORM=xcb` so it
  works under X11 and Wayland (via XWayland).


## Troubleshooting

| symptom                                    | fix                                                                                                              |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| Wizard crashes at startup on pure Wayland  | run `QT_QPA_PLATFORM=wayland nix run .`                                                                          |
| USB port not detected                      | ensure your user is in the `dialout` group or run with `sudo`                                                    |


## License & Disclaimer

Dynamixel Wizard 2 is © Robotis. This flake only automates the **installer**
Redistribution of the binary remains subject to Robotis' licence terms.

