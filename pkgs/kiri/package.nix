# Written to nixpkgs conventions so it can move as is to pkgs/kde/third-party/kiri/default.nix;
# this repo exposes it through overlays/kiri until then. Call it with kdePackages.callPackage.
{
  lib,
  stdenv,
  fetchzip,
  cmake,
  extra-cmake-modules,
  makeWrapper,
  python3,
  kcmutils,
  kconfig,
  kconfigwidgets,
  kcoreaddons,
  kservice,
  kwin,
  libepoxy,
  libnotify,
  qtbase,
  qtdeclarative,
  qttools,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "kiri";
  version = "1.1";

  # The release tarball, not the tag: it carries the KWin script already built from TypeScript
  # (upstream uses pnpm for that), so only the C++ effects are compiled here.
  src = fetchzip {
    url = "https://github.com/SeniorMatt/kiri/releases/download/v${finalAttrs.version}/kiri_${
      lib.replaceStrings [ "." ] [ "_" ] finalAttrs.version
    }.tar.gz";
    hash = "sha256-svG6kuYsFyZuWSG7/T2TkYp4DevoOhia7RKEhqh6wbw=";
  };

  cmakeDir = "../effect-cpp";

  cmakeFlags = [
    # Unset, effect-cpp/CMakeLists.txt asks qmake, which answers qtbase's own store path.
    (lib.cmakeFeature "KDE_INSTALL_QTPLUGINDIR" qtbase.qtPluginPrefix)
  ];

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    makeWrapper
  ];

  buildInputs = [
    kcmutils
    kconfig
    kconfigwidgets
    kcoreaddons
    kwin
    libepoxy
    python3 # patchShebangs target for niri2kiri
    qtdeclarative
    qttools # Qt6UiTools, for the settings page
  ];

  # Only Qt plugins and shell/Python scripts; KWin and System Settings load the plugins.
  dontWrapQtApps = true;

  postInstall = ''
    # What kpackagetool6 --install does, without needing KWin's package-structure plugin at build
    # time: the directory is named after metadata.json's KPlugin.Id.
    mkdir -p $out/share/kwin/scripts
    cp -r ../package $out/share/kwin/scripts/kiri

    install -Dm755 ../kiri-mode $out/bin/kiri-mode
    wrapProgram $out/bin/kiri-mode \
      --prefix PATH : ${
        lib.makeBinPath [
          kconfig
          libnotify
          qttools
        ]
      }

    install -Dm755 ../niri2kiri.py $out/bin/niri2kiri
    wrapProgram $out/bin/niri2kiri \
      --prefix PATH : ${
        lib.makeBinPath [
          kconfig
          kservice
        ]
      }
  '';

  meta = {
    description = "Scrollable tiling KWin script in the style of niri, a fork of Karousel";
    homepage = "https://github.com/SeniorMatt/kiri";
    license = lib.licenses.gpl3Only;
    mainProgram = "kiri-mode";
    platforms = lib.platforms.linux;
  };
})
