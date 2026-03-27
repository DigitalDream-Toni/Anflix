const input = document.getElementById("searchInput");
const button = document.getElementById("searchButton");
const noResults = document.getElementById("noResults");

const searchableItems = [...document.querySelectorAll("[data-title]")];

const preloader = document.querySelector(".preloader");
window.addEventListener("load", () => {
  document.body.classList.add("loaded");
  if (preloader) {
    setTimeout(() => preloader.remove(), 450);
  }
});

const normalize = (value) => value.toLowerCase().trim();

const getTitleElement = (item) =>
  item.querySelector(
    ".row-title, .card-title, .side-name, .home-hero-title, .panel-title, .strip-title, .collection-item"
  );

const clearHighlights = () => {
  searchableItems.forEach((item) => {
    const titleEl = getTitleElement(item);
    if (!titleEl) return;
    if (titleEl.dataset.originalText) {
      titleEl.textContent = titleEl.dataset.originalText;
      delete titleEl.dataset.originalText;
    }
  });
};

const highlightMatch = (element, term) => {
  if (!element || term === "") return;
  const text = element.textContent;
  const lower = text.toLowerCase();
  const index = lower.indexOf(term);
  if (index === -1) return;

  element.dataset.originalText = text;
  const before = text.slice(0, index);
  const match = text.slice(index, index + term.length);
  const after = text.slice(index + term.length);
  element.innerHTML = `${before}<span class="highlight">${match}</span>${after}`;
};

const applySearch = () => {
  const term = normalize(input.value);
  let visibleCount = 0;

  clearHighlights();

  searchableItems.forEach((item) => {
    const title = normalize(item.dataset.title || "");
    const match = term === "" || title.includes(term);
    item.style.display = match ? "" : "none";
    if (match) {
      visibleCount += 1;
      highlightMatch(getTitleElement(item), term);
    }
  });

  if (noResults) {
    noResults.style.display = visibleCount === 0 ? "block" : "none";
  }
};

button.addEventListener("click", applySearch);
input.addEventListener("keydown", (event) => {
  if (event.key === "Enter") {
    applySearch();
  }
});
