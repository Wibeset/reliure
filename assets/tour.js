// Tour: as the section scrolls past, show the screen and callout for the current step.
(() => {
  const tour = document.querySelector(".tour");
  if (!tour) return;
  const screens = tour.querySelectorAll(".screen");
  const callouts = tour.querySelectorAll(".callout");
  const count = screens.length;
  let current = 0;
  let queued = false;

  const update = () => {
    queued = false;
    const rect = tour.getBoundingClientRect();
    const progress = -rect.top / (rect.height - innerHeight);
    const step = Math.min(count - 1, Math.max(0, Math.floor(progress * count)));
    if (step === current) return;
    current = step;
    screens.forEach((el, i) => el.classList.toggle("is-active", i === step));
    callouts.forEach((el, i) => el.classList.toggle("is-active", i === step));
  };

  addEventListener("scroll", () => {
    if (!queued) { queued = true; requestAnimationFrame(update); }
  }, { passive: true });
  addEventListener("resize", update);
  update();
})();
