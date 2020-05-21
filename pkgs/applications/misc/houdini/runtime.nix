{ stdenv, requireFile, zlib, libpng, libSM, libICE, fontconfig, xorg, libGLU, libGL, libXScrnSaver, alsaLib, nss, nspr, pciutils, expat, dbus, xkeyboardconfig, bc, addOpenGLRunpath, WrapQtAppsHook }:

let
  ld_library_path = builtins.concatStringsSep ":" [
    "${stdenv.cc.cc.lib}/lib64"
    (stdenv.lib.makeLibraryPath [
      libGLU
      libGL
      xorg.libXmu
      xorg.libXi
      xorg.libXext
      xorg.libX11
      xorg.libXrender
      xorg.libXcursor
      xorg.libXfixes
      xorg.libXrender
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXtst
      xorg.libxcb
      xorg.xcbutil
      libXScrnSaver
      alsaLib
      fontconfig
      libSM
      libICE
      zlib
      libpng
      nss
      nspr
      pciutils
      expat
      dbus
      addOpenGLRunpath.driverLink
    ])
  ];
  license_dir = "~/.config/houdini";
in
stdenv.mkDerivation rec {
  version = "18.0.460";
  pname = "houdini-runtime";
  src = requireFile rec {
    name = "houdini-${version}-linux_x86_64_gcc6.3.tar.gz";
    sha256 = "4dcbd11a96388d76e5082b0d38584d1f145c7b16a6abf593755fe8c9bee62ba3";
    message = ''
      This nix expression requires that ${name} is already part of the store.
      Download it from https://www.sidefx.com and add it to the nix store with:

          nix-prefetch-url <URL>

      This can't be done automatically because you need to create an account on
      their website and agree to their license terms before you can download
      it. That's what you get for using proprietary software.
    '';
  };

  buildInputs = [ bc qtbase];
  nativeBuildInputs = [ wrapQtAppsHook ];
  installPhase = ''
    patchShebangs houdini.install
    mkdir -p $out
    sed -i "s|/usr/lib/sesi|${license_dir}|g" houdini.install
    ./houdini.install --install-houdini \
                      --no-install-menus \
                      --no-install-bin-symlink \
                      --auto-install \
                      --no-root-check \
                      --accept-EULA \
                      $out
    echo -e "localValidatorDir = ${license_dir}\nlicensingMode = localValidator" > $out/houdini/Licensing.opt
    sed -i "s|/usr/lib/sesi|${license_dir}|g" $out/houdini/sbin/sesinetd_safe
    sed -i "s|/usr/lib/sesi|${license_dir}|g" $out/houdini/sbin/sesinetd.startup
    echo "export LD_LIBRARY_PATH=${ld_library_path}" >> $out/bin/app_init.sh
    echo "export QT_XKB_CONFIG_ROOT="${xkeyboardconfig}/share/X11/xkb"" >> $out/bin/app_init.sh
    echo "export LD_LIBRARY_PATH=${ld_library_path}" >> $out/houdini/sbin/app_init.sh
    echo "export QT_XKB_CONFIG_ROOT="${xkeyboardconfig}/share/X11/xkb"" >> $out/houdini/sbin/app_init.sh
  '';
  postFixup = ''
    INTERPRETER="$(cat "$NIX_CC"/nix-support/dynamic-linker)"
    for BIN in $(find $out/bin -type f -executable); do
      if patchelf $BIN 2>/dev/null ; then
        echo "Patching ELF $BIN"
        patchelf --set-interpreter "$INTERPRETER" "$BIN"
      fi
    done
  '';
  meta = {
    description = "3D animation application software";
    homepage = "https://www.sidefx.com";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    maintainers = [ stdenv.lib.maintainers.canndrew ];
  };
}

