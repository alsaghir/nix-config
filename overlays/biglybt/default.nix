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

      VMOPTS="$(cat <<EOV
--patch-module=java.base=$out/share/biglybt/ghostfucker_utils.jar
--add-exports=java.base/sun.net.www.protocol=ALL-UNNAMED
--add-exports=java.base/sun.net.www.protocol.http=ALL-UNNAMED
--add-exports=java.base/sun.net.www.protocol.https=ALL-UNNAMED
--add-opens=java.base/java.net=ALL-UNNAMED
-Dorg.glassfish.jaxb.runtime.v2.bytecode.ClassTailor.noOptimize=true
--add-opens=java.base/java.io=ALL-UNNAMED
--add-opens=java.base/java.lang.reflect=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED
--add-opens=java.base/java.util.concurrent=ALL-UNNAMED
--add-opens=java.base/java.util=ALL-UNNAMED
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED
-Djava.security.properties="/app/biglybt/java-security-override.properties"
-Dsecurity.overridePropertiesFile=true
-Dsun.java2d.opengl=false
-Dsun.java2d.xrender=false
-Dsun.java2d.d3d=false
-Dsun.java2d.dpiaware=true
-Djava.awt.focusWindowByDefault=false
-Dawt.toolkit.name=WLToolkit
-Djava.awt.headless=false
-Dawt.useSystemAAFontSettings=on
-Dgdk.backend=wayland
-DGDK_BACKEND=wayland
-Dsun.awt.disablegrab=true
-Dsun.java2d.pmoffscreen=false
-Dsun.awt.noerasebackground=true
-Dswing.aatext=true
--enable-native-access=ALL-UNNAMED
-Dcom.biglybt.ui.swt.enableGTK3=true
-Djdk.gtk.version=3
-D_JAVA_AWT_WM_NONREPARENTING=1
EOV
)"
      VMOPTS="''${VMOPTS//$'\n'/ }"

      # Inject VM options and Wayland-related env into the wrapped launcher
      gappsWrapperArgs+=(
        --set JAVA_TOOL_OPTIONS "''${VMOPTS}"
        --set GDK_BACKEND wayland
        --set _JAVA_AWT_WM_NONREPARENTING 1
        --set JDK_GTK_VERSION 3
      )
      '';

    meta = oldAttrs.meta // {
      description = "BiglyBT BitTorrent Client with extreme mod and JDK 25";
    };
  });
}
