final: prev: rec {
  swt = prev.swt.overrideAttrs (old: {
    preConfigure = ''
      # Check if file exists before patching
      if [[ -f library/make_linux.mak ]]; then
        substituteInPlace library/make_linux.mak \
          --replace "-Werror" ""
      fi
    '';
  });

  biglybt = prev.biglybt.overrideAttrs (oldAttrs: rec {
    version = "4.0.0.0";

    src = prev.fetchurl {
      url = "https://github.com/BiglySoftware/BiglyBT/releases/download/v${version}/GitHub_BiglyBT_unix.tar.gz";
      hash = "sha256-J61AgH9WnkUunqWsYKU/hyH569QobJqh9M3lBpxCcAk=";
    };

    jdk25 = prev.fetchurl {
      url = "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.1%2B8/OpenJDK25U-jdk_x64_linux_hotspot_25.0.1_8.tar.gz";
      hash = "sha256-ja930arP/jjJiJaJvCJKE1V953VZ2aW7kZkeaimLqg0=";
    };

    modFiles = ./extreme-mod;

    postInstall = ''
      mkdir -p $out/jre
      tar -xzf ${jdk25} -C $out/jre --strip-components=1
      cp -r ${modFiles}/* $out/share/biglybt/

      # Remove any existing StartupWMClass or Icon lines to avoid duplicates
      # Append the correct Window Class.
      # BiglyBT windows usually identify as "BiglyBT Extreme Mod" or "org-gudy-azureus2-ui-swt-Main"
      sed -i '/StartupWMClass/d' $out/share/biglybt/biglybt.desktop
      echo "StartupWMClass=BiglyBT Extreme Mod" >> $out/share/biglybt/biglybt.desktop
      
      # Set the correct JDK path in the wrapper script
      substituteInPlace $out/share/biglybt/.biglybt-wrapped \
        --replace-fail 'JAVA_PROGRAM_DIR=""' 'JAVA_PROGRAM_DIR="'"$out/jre/bin/"'"'
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix PATH : $out/jre/bin
        --set JAVA_HOME $out/jre
        --set BIGLYBT_ICON $out/share/biglybt/biglybt.svg
      )
      '';

    meta = oldAttrs.meta // {
      description = "BiglyBT BitTorrent Client with extreme mod and JDK 25";
    };
  });
}
