# Written to nixpkgs conventions so it can move as is to
# pkgs/by-name/mi/misterdownloadmanager/package.nix; this repo exposes it through
# overlays/misterdownloadmanager until then.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  pkg-config,
  aws-lc,
  dejavu_fonts,
  fontconfig,
  gtk3,
  makeFontsConf,
  nix-update-script,
  libayatana-appindicator,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  vulkan-loader,
  wayland,
  writeCBin,
}:
let
  # Upstream's Linux release builds these crates (tools/installer/build-linux.sh), not the
  # whole workspace (lab servers, dev tools).
  cargoPackages = [
    "mdm-app"
    "mdm-cli"
    "mdm-mcp"
    "mdm-nmhost"
  ];
  cargoPackageFlags = lib.concatMap (p: [
    "-p"
    p
  ]) cargoPackages;
  standaloneSleep = writeCBin "sleep" ''
    #include <stdlib.h>
    #include <unistd.h>
    int main(int argc, char **argv) { return argc > 1 ? sleep(atoi(argv[1])) : 1; }
  '';
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "misterdownloadmanager";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "anefzaoui";
    repo = "misterdownloadmanager";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WRBG1npj6+//0YjWooMmw03ngVRkDx1WyhvwOL2+7sc=";
  };

  cargoHash = "sha256-+l1+VATWsXyAD/JRq8tIfED7lIRsfJK95bWhVR6NSGE=";

  cargoBuildFlags = cargoPackageFlags;
  cargoTestFlags = cargoPackageFlags;

  postPatch = ''
    # Font lookup runs fc-match from PATH, which NixOS doesn't guarantee; without it the app
    # loses its symbol and non-Latin fonts.
    substituteInPlace crates/app/src/theme.rs \
      --replace-fail 'Command::new("fc-match")' 'Command::new("${lib.getExe' fontconfig "fc-match"}")'
    # The self-updater treats a binary no package manager claims as the .tar.gz release and
    # replaces it in place, which the read-only store refuses; leave updates to Nix, as for
    # /usr/bin.
    substituteInPlace crates/tools/src/update.rs \
      --replace-fail '|| exe.parent() == Some(Path::new("/usr/bin"))' \
                     '|| exe.parent() == Some(Path::new("/usr/bin")) || exe.starts_with("${builtins.storeDir}")'
    # Test-only: the sandbox has no /bin, and coreutils' sleep is a link to its multi-call
    # binary, which refuses to run under the copy's name; the test needs a standalone program.
    substituteInPlace crates/app/src/unix.rs \
      --replace-fail '"/bin/sleep"' '"${lib.getExe standaloneSleep}"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
    # aws-lc-sys generates its bindings to the system AWS-LC.
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    # rustls' crypto; nixpkgs' cargo hook sets AWS_LC_SYS_USE_SYSTEM=1 instead of the vendored copy.
    aws-lc
    # rfd (file dialogs) and tray-icon link GTK.
    gtk3
  ];

  # The glyph test checks the UI marks against the fonts fontconfig finds; DejaVu Sans has
  # them all. Languages whose script font is absent are skipped by the test itself.
  preCheck = ''
    export FONTCONFIG_FILE=${makeFontsConf { fontDirectories = [ dejavu_fonts ]; }}
    export XDG_CACHE_HOME=$TMPDIR
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "misterdownloadmanager";
      desktopName = "Mister Download Manager";
      comment = finalAttrs.meta.description;
      exec = "misterdownloadmanager %U";
      icon = "misterdownloadmanager";
      categories = [
        "Network"
        "FileTransfer"
      ];
      mimeTypes = [
        "x-scheme-handler/magnet"
        "application/x-bittorrent"
      ];
    })
  ];

  # Browser extension bridge: upstream's generator writes system-wide manifests naming
  # /usr/bin/misterdownloadmanager-nmhost; point them at this package. Firefox (and
  # programs.firefox.nativeMessagingHosts) reads lib/mozilla/native-messaging-hosts.
  postInstall = ''
    install -Dm644 "art/Mister Download Manager.png" \
      "$out/share/pixmaps/misterdownloadmanager.png"

    hosts=$(mktemp -d)
    "$out/bin/misterdownloadmanager-nmhost" --package-manifests "$hosts"
    find "$hosts" -name '*.json' -exec substituteInPlace {} \
      --replace-fail /usr/bin/misterdownloadmanager-nmhost "$out/bin/misterdownloadmanager-nmhost" \;
    mkdir -p "$out/lib"
    cp -r "$hosts/usr/lib/mozilla" "$out/lib/"
    if [ -d "$hosts/etc" ]; then cp -r "$hosts/etc" "$out/"; fi
  '';

  # winit, glow/wgpu and the tray load these with dlopen, so the linker never records them.
  postFixup = ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        libayatana-appindicator
        libGL
        libx11
        libxcursor
        libxi
        libxkbcommon
        libxrandr
        vulkan-loader
        wayland
      ]
    } "$out/bin/misterdownloadmanager"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Download manager with torrent support and browser integration";
    homepage = "https://github.com/anefzaoui/misterdownloadmanager";
    changelog = "https://github.com/anefzaoui/misterdownloadmanager/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      gpl3Plus
      # crates/geo/data: DB-IP's IP to Country Lite database, and the flag icons.
      cc-by-40
      mit
    ];
    mainProgram = "misterdownloadmanager";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
