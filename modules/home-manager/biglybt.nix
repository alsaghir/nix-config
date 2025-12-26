{ pkgs, ... }:
{
  # Create the VM options file
  home.file.".biglybt/java.vmoptions" = {
    text = ''
      --patch-module=java.base=${pkgs.biglybt}/share/biglybt/ghostfucker_utils.jar
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
    '';
    force = true;
  };
}
