{
  description = "Dynamixel Wizard 2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      qtLibs = with pkgs.libsForQt5; [qtbase qtsvg qtserialport qtserialbus];

      runtimeLibs = with pkgs; [
        fontconfig
        freetype
        zlib
        libglvnd
        xorg.libxcb
        xorg.libX11
        xorg.libXext
        xorg.libXrender
        libxkbcommon
        dbus
        udev
        stdenv.cc.cc.lib
      ];

      wizard = pkgs.stdenv.mkDerivation rec {
        pname = "dynamixel-wizard2";
        version = "2.1.12.1";

        src = pkgs.fetchurl {
          url = "https://www.dropbox.com/s/csawv9qzl8m8e0d/DynamixelWizard2Setup-x86_64?dl=1";
          sha256 = "sha256-lHaiUk8c9OluakuQAFxOzpObfVgG13XWH6RuNq6iqjc=";
          executable = true;
          curlOptsList = ["--location"];
        };

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.patchelf
          pkgs.makeWrapper
        ];

        buildInputs =
          qtLibs
          ++ runtimeLibs
          ++ [
            pkgs.udev
            pkgs.libgpg-error
          ];

        dontWrapQtApps = true;

        unpackPhase = ''
          install -m755 ${src} installer.orig
          patchelf \
            --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
            --set-rpath "${pkgs.lib.makeLibraryPath runtimeLibs}" \
            --output installer.run \
            installer.orig

          export HOME=$PWD/.home
          export XDG_RUNTIME_DIR=$PWD/.run
          mkdir -p "$HOME/.local/share/applications" "$XDG_RUNTIME_DIR"
          chmod 700 "$XDG_RUNTIME_DIR"

          QT_QPA_PLATFORM=minimal \
            ./installer.run install --silent \
              --root "$PWD/extracted" \
              --accept-licenses --accept-messages --confirm-command

          sourceRoot=$PWD/extracted
        '';

        installPhase = ''
          mkdir -p $out/opt
          cp -r * $out/opt

          # drop ancient vendor OpenGL libs
          find $out/opt -type f -regex '.*\(lib\(GL\|EGL\|GLES\|glapi\).so.*\)' -delete

          autoPatchelf $out

          makeWrapper $out/opt/DynamixelWizard2 \
              $out/bin/dynamixel \
              --set QT_QPA_PLATFORM xcb
        '';
      };
    in {
      packages.default = wizard;

      devShells.default = pkgs.mkShell {
        buildInputs = [wizard];
        shellHook = ''echo "Run Dynamixel Wizard with:  dynamixel"'';
      };

      apps.default = flake-utils.lib.mkApp {
        drv = wizard;
        exePath = "/bin/dynamixel";
      };
    });
}
