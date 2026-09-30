(() => {
  const key = document.createXULElement("key");
  key.setAttribute("key", ";");
  key.setAttribute("modifiers", "accel");
  key.addEventListener("command", () => {
    gURLBar.setAttribute("uc-newtab", "");
    gURLBar.value = "";
    gURLBar.focus();
    gURLBar.startQuery();
  });
  const keyset = document.createXULElement("keyset");
  keyset.append(key);
  document.documentElement.append(keyset);

  const whereToOpen = gURLBar.controller.whereToOpen.bind(gURLBar.controller);
  gURLBar.controller.whereToOpen = (event) => (gURLBar.hasAttribute("uc-newtab") ? "tab" : whereToOpen(event));

  gURLBar.addEventListener("blur", () => {
    if (!gURLBar.hasAttribute("uc-newtab")) return;
    gURLBar.removeAttribute("uc-newtab");
    gURLBar.handleRevert();
  });
})();
