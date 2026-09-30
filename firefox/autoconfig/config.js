//
const manifest = Services.dirsvc.get("UChrm", Ci.nsIFile);
manifest.append("chrome.manifest");
Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(manifest);

Services.obs.addObserver((window) => {
  const entries = Services.dirsvc.get("UChrm", Ci.nsIFile).directoryEntries;
  while (entries.hasMoreElements()) {
    const name = entries.nextFile.leafName;
    if (name.endsWith(".uc.js")) {
      Services.scriptloader.loadSubScript(`chrome://userchromejs/content/${name}`, window);
    }
  }
}, "browser-delayed-startup-finished");
