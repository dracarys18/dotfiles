// CPU temperature: colour the number by value, and drop the bar under it —
// a temperature is a reading, not a percentage of something.
(function () {
  const colour = (t) => (t >= 85 ? "#ef4444" : t >= 70 ? "#f59e0b" : "#22c55e");

  function paint() {
    document.querySelectorAll(".information-widget-resource").forEach((row) => {
      const label = row.querySelector(".pr-1");
      if (!label || label.textContent.trim().toUpperCase() !== "TEMP") return;

      const value = row.querySelector(".resource-value");
      const temp = value ? parseFloat(value.textContent) : NaN;
      if (!Number.isNaN(temp)) value.style.color = colour(temp);

      const bar = row.querySelector(".resource-usage");
      if (bar) bar.style.display = "none";
    });
  }

  setInterval(paint, 800);
})();
