# BiglyBT newer than nixpkgs, on JDK 25 with the Extreme Mod files, and swt without -Werror.
final: prev: rec {
  swt = prev.swt.overrideAttrs {
    preConfigure = ''
      # Check if file exists before patching
      if [[ -f library/make_linux.mak ]]; then
        substituteInPlace library/make_linux.mak \
          --replace "-Werror" ""
      fi
    '';
  };

  # The nixpkgs wrapper prefixes PATH with `jre`; the launcher finds java there
  biglybt = (prev.biglybt.override { jre = prev.jdk25; }).overrideAttrs (oldAttrs: rec {
    version = "4.2.0.0";

    src = prev.fetchurl {
      # Version in the name changes the store path on every bump, so a stale hash fails instead of reusing the old tarball
      name = "biglybt-${version}-unix.tar.gz";
      url = "https://github.com/BiglySoftware/BiglyBT/releases/download/v${version}/GitHub_BiglyBT_unix.tar.gz";
      hash = "sha256-kI96ZlI/BWcqRQfKPdog8m6ANq/le2/aQoaBxMdfGBo=";
    };

    modFiles = ./extreme-mod;

    postInstall = ''
      cp -r ${modFiles}/* $out/share/biglybt/

      # Remove any existing StartupWMClass or Icon lines to avoid duplicates
      # Append the correct Window Class.
      # BiglyBT windows usually identify as "BiglyBT Extreme Mod" or "org-gudy-azureus2-ui-swt-Main"
      sed -i '/StartupWMClass/d' $out/share/biglybt/biglybt.desktop
      echo "StartupWMClass=BiglyBT Extreme Mod" >> $out/share/biglybt/biglybt.desktop

      sed -i 's|^Icon=biglybt.svg$|Icon=biglybt|' $out/share/biglybt/biglybt.desktop

      substituteInPlace $out/share/biglybt/.biglybt-wrapped \
        --replace-fail 'GDK_BACKEND=x11' 'GDK_BACKEND=wayland'
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --set BIGLYBT_ICON $out/share/biglybt/biglybt.svg
        --set GTK_THEME "Adwaita"
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
      -Dsun.java2d.opengl=false
      -Dsun.java2d.xrender=false
      -Dsun.java2d.d3d=false
      -Dsun.java2d.dpiaware=true
      -Djava.awt.focusWindowByDefault=false
      -Dawt.toolkit.name=WLToolkit
      -Djava.awt.headless=false
      -Dawt.useSystemAAFontSettings=on
      -Dsun.awt.disablegrab=true
      -Dsun.java2d.noddraw=true
      -Dswing.bufferPerWindow=false
      -Dsun.java2d.pmoffscreen=false
      -Dsun.awt.noerasebackground=true
      -Dswing.aatext=true
      --enable-native-access=ALL-UNNAMED
      -Dcom.biglybt.ui.swt.enableGTK3=true
      -Djdk.gtk.version=3
      -D_JAVA_AWT_WM_NONREPARENTING=0
      EOV
      )"
      VMOPTS="''${VMOPTS//$'\n'/ }"

      # Inject VM options and Wayland-related env into the wrapped launcher
      gappsWrapperArgs+=(
        --set JAVA_TOOL_OPTIONS "''${VMOPTS}"
        --set _JAVA_AWT_WM_NONREPARENTING 0
        --set JDK_GTK_VERSION 3
      )
    '';

    meta = oldAttrs.meta // {
      description = "BiglyBT BitTorrent Client with extreme mod";
    };
  });
}
