# Vicinae (launcher), from its GitHub release DMG: nixpkgs' vicinae is
# `platforms = linux`. The image is APFS, which `undmg` refuses, so this mounts
# it with /usr/bin/hdiutil directly.
{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation {
  pname = "vicinae-bin";
  version = "0.29.1";

  src = fetchurl {
    url = "https://github.com/vicinaehq/vicinae/releases/download/v0.29.1/Vicinae.dmg";
    hash = "sha256-6DzvD5rVz/MXLUUgBUUo5PQd59ks0KTAp4kOzk79bh8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications mnt
    /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint mnt "$src"
    cp -R mnt/Vicinae.app $out/Applications/
    /usr/bin/hdiutil detach mnt
    runHook postInstall
  '';

  meta = {
    description = "A focused launcher for your desktop";
    homepage = "https://vicinae.com";
    platforms = lib.platforms.darwin;
  };
}
