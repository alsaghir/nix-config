{ pkgs }:
let
  # ============== SHARED BASICS ==============
  basics = with pkgs; [
    git
    curl
    jq
  ];

  # ============== NODE.JS SHELL ==============
  nodejsShell = pkgs.mkShell {
    name = "nodejs-devshell";

    packages =
      with pkgs;
      [
        nodejs
        corepack
        openssl
      ]
      ++ basics;

    nativeBuildInputs = with pkgs; [
      python3
      pkg-config
      gcc
      gnumake
    ];

    shellHook = ''
      export PATH="$PWD/node_modules/.bin:$PATH"

      mkdir -p .idea/sdk
      ln -sf ${pkgs.nodejs}/bin/node .idea/sdk/node
      ln -sf ${pkgs.nodejs}/bin/npm  .idea/sdk/npm
      ln -sf ${pkgs.nodejs}/bin/npx  .idea/sdk/npx

      if command -v corepack >/dev/null 2>&1; then
        corepack enable >/dev/null 2>&1 || true
      fi

      export NODE_ENV=development

      echo "✅ Node.js dev shell ready ($(node --version))"
    '';
  };

  # ============== KOTLIN MULTIPLATFORM SHELL ==============
  kotlinShell =
    let
      jdk = pkgs.jetbrains.jdk;
      gradle = pkgs.gradle_9;
      chromium = pkgs.chromium;

      libPath = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          libglvnd
          libGLU
          mesa
          libx11
          libxext
          libxi
          libxrender
          libxtst
          libxxf86vm
          libxcursor
          libxrandr
          fontconfig
          freetype
          zlib
          stdenv.cc.cc.lib
          glib
          dbus
          dconf
          gtk3
          libportal
          dbus.lib
        ]
      );
    in
    pkgs.mkShell {
      name = "kotlin-multiplatform-shell";

      packages = [
        jdk
        gradle
        chromium
        pkgs.firebase-tools
      ]
      ++ basics;

      shellHook = ''
        export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

        export JAVA_HOME="${jdk}"
        export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"
        export CHROME_BIN="${chromium}/bin/chromium"
        export PATH="$PWD/.idea/sdk/bin:$PATH"

        mkdir -p .idea/sdk/bin
        ln -sfT "${chromium}" .idea/sdk/chromium-home
        ln -sfT "${jdk}" .idea/sdk/jdk-home
        ln -sfT "${gradle}" .idea/sdk/gradle-home
        ln -sf "${jdk}/bin/java"      .idea/sdk/bin/java
        ln -sf "${gradle}/bin/gradle" .idea/sdk/bin/gradle
        ln -sf "${chromium}/bin/chromium" .idea/sdk/bin/chromium
        ln -sf "${pkgs.firebase-tools}/bin/firebase" .idea/sdk/bin/firebase

        echo "✅ Kotlin Multiplatform shell ready"
        echo "   Java:   $(java --version 2>&1 | head -n1)"
        echo "   Gradle: $(gradle --version | grep Gradle)"
        echo "   Kotlin: Managed by Gradle (check gradle/libs.versions.toml)"
      '';
    };

  # ============== PYTHON SHELL (example for future) ==============
  pythonShell = pkgs.mkShell {
    name = "python-devshell";
    packages =
      with pkgs;
      [
        python312
        poetry
      ]
      ++ basics;
    shellHook = ''
      echo "✅ Python dev shell ready ($(python --version))"
    '';
  };

  # ============== Java And Maven SHELL ==============
  javaShell =
    let
      jdk = pkgs.jetbrains.jdk;
      gradle = pkgs.gradle_9;
      maven = pkgs.maven;

      libPath = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          libglvnd
          libGLU
          mesa
          libx11
          libxext
          libxi
          libxrender
          libxtst
          libxxf86vm
          libxcursor
          libxrandr
          fontconfig
          freetype
          zlib
          stdenv.cc.cc.lib
        ]
      );
    in
    pkgs.mkShell {
      name = "java-shell";

      packages = [
        jdk
        gradle
        maven
      ]
      ++ basics;

      shellHook = ''
        export LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH"
        export JAVA_HOME="${jdk}"
        export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"
        export MAVEN_HOME="${maven}"
        export PATH="$PWD/.idea/sdk/bin:$PATH"

        mkdir -p .idea/sdk/bin
        ln -sfT "${maven}" .idea/sdk/maven-home
        ln -sfT "${jdk}" .idea/sdk/jdk-home
        ln -sfT "${gradle}" .idea/sdk/gradle-home
        ln -sf ${pkgs.nodejs}/bin/node .idea/sdk/bin/node
        ln -sf ${pkgs.nodejs}/bin/npm  .idea/sdk/bin/npm
        ln -sf ${pkgs.nodejs}/bin/npx  .idea/sdk/bin/npx
        ln -sf "${jdk}/bin/java"      .idea/sdk/bin/java
        ln -sf "${gradle}/bin/gradle" .idea/sdk/bin/gradle
        ln -sf "${maven}/bin/mvn" .idea/sdk/bin/mvn

        echo "✅ Java and Maven shell ready"
        echo "   Java:   $(java --version 2>&1 | head -n1)"
        echo "   Gradle: $(gradle --version | grep Gradle)"
        echo "   Maven:  $(mvn --version | head -n1)"
      '';
    };

  # ============== SHARED RUST TOOLCHAIN (rust-overlay) ==============
  mkRustToolchain =
    targets:
    pkgs.rust-bin.stable.latest.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "clippy"
        "rustfmt"
      ];
      inherit targets;
    };

  # ============== DIOXUS SHELL ==============
  dioxusShell =
    let
      rustToolchain = mkRustToolchain [ "wasm32-unknown-unknown" ];

      # wasm-bindgen-cli pinned to match Dioxus's expected schema version.
      # When bumping Dioxus, check what wasm-bindgen version it wants, update
      # `version` below, set both hashes to pkgs.lib.fakeHash, rebuild twice,
      # copy the real hashes from the errors (fetchCrate first, then cargoVendor).
      wasm-bindgen-cli =
        let
          src = pkgs.fetchCrate {
            pname = "wasm-bindgen-cli";
            version = "0.2.128";
            hash = "sha256-a7lcXJnnZkYReja+iUO7NqqrWyv3toxnUgQb8s4IS5s=";
          };
        in
        pkgs.buildWasmBindgenCli {
          inherit src;
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            inherit (src) pname version;
            hash = "sha256-R1Tas33Ursy8kqsxguAkG0ZhNed2n5uFTAhw1l2qlLY=";
          };
        };

      libPath = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          atkmm
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          pango
          atk
          openssl
          libsoup_3
          xdotool
        ]
      );
    in
    pkgs.mkShell {
      name = "dioxus-devshell";

      packages =
        with pkgs;
        [
          rustToolchain
          vscode-extensions.vadimcn.vscode-lldb
          dioxus-cli
          wasm-bindgen-cli
          pkg-config
          openssl
          cargo-edit
          cargo-watch
          cargo-nextest
          binaryen
          lld
        ]
        ++ basics;

      nativeBuildInputs = with pkgs; [
        pkg-config
        gcc
        gnumake
      ];

      shellHook = ''
        export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export PATH="$PWD/.sdk/bin:$PWD/target/debug:$PATH"

        mkdir -p .sdk/bin
        ln -sf "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb" .sdk/bin/codelldb

        echo "✅ Dioxus dev shell ready (nix rust-overlay)"
        echo "   $(rustc --version 2>/dev/null || true)"
        echo "   $(cargo --version 2>/dev/null || true)"
        echo "   dx: $(dx --version 2>/dev/null || echo 'dx missing')"
      '';
    };

  # ============== RUST SHELL ==============
  rustShell =
    let
      toolchainFile = ./rust-toolchain.toml;
      rustToolchain =
        if builtins.pathExists toolchainFile then
          pkgs.rust-bin.fromRustupToolchainFile toolchainFile
        else
          mkRustToolchain [ ];
    in

    pkgs.mkShell {
      name = "rust-devshell";

      packages =
        with pkgs;
        [
          rustToolchain
          vscode-extensions.vadimcn.vscode-lldb
          pkg-config
          openssl
          cargo-edit
          cargo-watch
          cargo-nextest
        ]
        ++ basics;

      nativeBuildInputs = with pkgs; [ pkg-config ];

      shellHook = ''
        export PATH="$PWD/.sdk/bin:$PWD/target/debug:$PATH"

        mkdir -p .sdk/bin
        ln -sf "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb" .sdk/bin/codelldb

        echo "✅ Rust dev shell ready (rustup-managed)"
        echo "   $(rustc --version 2>/dev/null || echo 'toolchain installing…')"
        echo "   $(cargo --version 2>/dev/null || true)"
      '';
    };
in
{
  # Named shells
  nodejs = nodejsShell;
  kotlin = kotlinShell;
  python = pythonShell;
  java = javaShell;
  rust = rustShell;
  dioxus = dioxusShell;

  # Default shell (pick your most common one)
  default = nodejsShell;
}
