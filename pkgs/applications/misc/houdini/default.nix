{ callPackage, buildFHSUserEnv, undaemonize, libsForQt5 }:

let
  houdini-runtime = libsForQt5.callPackage ./runtime.nix { };
in buildFHSUserEnv {
  name = "houdini";

  extraBuildCommands = ''
    mkdir -p $out/usr/lib/sesi
  '';

  runScript = "${undaemonize}/bin/undaemonize ${houdini-runtime}/bin/houdini";
}

