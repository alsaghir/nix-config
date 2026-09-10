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

  # ============== RUST SHELL ==============
  rustShell = pkgs.mkShell {
    name = "rust-devshell";

    packages =
      with pkgs;
      [
        cargo
        rustc
        rustfmt
        clippy
        rust-analyzer
        pkg-config
        openssl
        cargo-edit
        cargo-watch
        cargo-nextest
      ]
      ++ basics;

    nativeBuildInputs = with pkgs; [ pkg-config ];

    shellHook = ''
      export RUST_SRC_PATH="${pkgs.rustPlatform.rustLibSrc}"
      export PATH="$PWD/.sdk/bin:$PWD/target/debug:$PATH"

      mkdir -p .sdk/bin
      ln -sf "${pkgs.cargo}/bin/cargo"        .sdk/bin/cargo
      ln -sf "${pkgs.rustc}/bin/rustc"        .sdk/bin/rustc
      ln -sf "${pkgs.rust-analyzer}/bin/rust-analyzer" .sdk/bin/rust-analyzer
      ln -sf "${pkgs.rustfmt}/bin/rustfmt"    .sdk/bin/rustfmt
      ln -sf "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb" .sdk/bin/codelldb
      ln -sfT "${pkgs.rustPlatform.rustLibSrc}" .sdk/rust-src

      # RustRover on NixOS can't index a read-only Nix store path (JetBrains RUST-7912),
      # so keep a real writable copy at a fixed path, regenerated only when the
      # pinned rustc version changes.
      RUST_SRC_MARKER=".sdk/rust-src/.nix-version"
      CURRENT_RUST_VERSION="${pkgs.rustc.version}"
      if [ ! -f "$RUST_SRC_MARKER" ] || [ "$(cat "$RUST_SRC_MARKER" 2>/dev/null)" != "$CURRENT_RUST_VERSION" ]; then
        cp -r "${pkgs.rustPlatform.rustLibSrc}" .sdk/rust-src-hard-copy
        chmod -R u+w .sdk/rust-src-hard-copy
        echo "$CURRENT_RUST_VERSION" > "$RUST_SRC_MARKER"
      fi

      echo "✅ Rust dev shell ready"
      echo "   $(rustc --version)"
      echo "   $(cargo --version)"
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

  # Default shell (pick your most common one)
  default = nodejsShell;
}
