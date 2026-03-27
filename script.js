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

const welcomeTrack = document.querySelector(".welcome-track");
let welcomeSlides = document.querySelectorAll(".welcome-slide");
const welcomePrev = document.querySelector(".welcome-btn.prev");
const welcomeNext = document.querySelector(".welcome-btn.next");
let welcomeIndex = 0;
let welcomeTimer;

const updateWelcomeCarousel = () => {
  if (!welcomeTrack || welcomeSlides.length === 0) return;
  const offset = welcomeIndex * 100;
  welcomeTrack.style.transform = `translateX(-${offset}%)`;
};

const goWelcomeNext = () => {
  welcomeIndex = (welcomeIndex + 1) % welcomeSlides.length;
  updateWelcomeCarousel();
};

const goWelcomePrev = () => {
  welcomeIndex = (welcomeIndex - 1 + welcomeSlides.length) % welcomeSlides.length;
  updateWelcomeCarousel();
};

const startWelcomeCarousel = () => {
  clearInterval(welcomeTimer);
  welcomeTimer = setInterval(goWelcomeNext, 5000);
};

if (welcomeTrack && welcomeSlides.length > 0) {
  // Create seamless loop by cloning first and last slides
  const firstClone = welcomeSlides[0].cloneNode(true);
  const lastClone = welcomeSlides[welcomeSlides.length - 1].cloneNode(true);
  firstClone.classList.add("clone");
  lastClone.classList.add("clone");
  welcomeTrack.appendChild(firstClone);
  welcomeTrack.insertBefore(lastClone, welcomeSlides[0]);
  welcomeSlides = document.querySelectorAll(".welcome-slide");
  welcomeIndex = 1;
  updateWelcomeCarousel();

  welcomeTrack.addEventListener("transitionend", () => {
    const current = welcomeSlides[welcomeIndex];
    if (current && current.classList.contains("clone")) {
      welcomeTrack.style.transition = "none";
      if (welcomeIndex === 0) {
        welcomeIndex = welcomeSlides.length - 2;
      } else if (welcomeIndex === welcomeSlides.length - 1) {
        welcomeIndex = 1;
      }
      updateWelcomeCarousel();
      requestAnimationFrame(() => {
        welcomeTrack.style.transition = "transform 0.6s ease";
      });
    }
  });

  if (welcomePrev && welcomeNext) {
    welcomePrev.addEventListener("click", () => {
      goWelcomePrev();
      startWelcomeCarousel();
    });
    welcomeNext.addEventListener("click", () => {
      goWelcomeNext();
      startWelcomeCarousel();
    });
  }
  startWelcomeCarousel();
}


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
