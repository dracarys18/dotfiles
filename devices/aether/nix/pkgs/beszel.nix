{
  lib,
  buildGo127Module,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildGo127Module (finalAttrs: {
  pname = "beszel";
  version = "0.21.1";

  src = fetchFromGitHub {
    owner = "henrygd";
    repo = "beszel";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OB1pbfUKeE+tu/ehhoJhkPBmOBDLiQzGxb74bin2Qmg=";
  };

  webui = buildNpmPackage {
    inherit (finalAttrs)
      pname
      version
      src
      meta
      ;

    npmFlags = [ "--legacy-peer-deps" ];

    buildPhase = ''
      runHook preBuild

      npx lingui extract --overwrite
      npx lingui compile
      node --max_old_space_size=1024000 ./node_modules/vite/bin/vite.js build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist/* $out

      runHook postInstall
    '';

    sourceRoot = "${finalAttrs.src.name}/internal/site";

    npmDepsHash = "sha256-pL4Qmi17CC4t6G/Mw/AgZUPf6cl0UPm75zfHVfrkoKI=";
  };

  vendorHash = "sha256-NStpXYnaVkJxmzT1fIPFqSNbNSJqpnC0LsVQweFOwcI=";

  preBuild = ''
    mkdir -p internal/site/dist
    cp -r ${finalAttrs.webui}/* internal/site/dist
  '';

  doCheck = false;

  postInstall = ''
    mv $out/bin/agent $out/bin/beszel-agent
    mv $out/bin/hub $out/bin/beszel-hub
  '';

  meta = {
    homepage = "https://github.com/henrygd/beszel";
    changelog = "https://github.com/henrygd/beszel/releases/tag/v${finalAttrs.version}";
    description = "Lightweight server monitoring hub with historical data, docker stats, and alerts";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
