/* The course site: a "Filter pages" box at the top of the left tree.
   Typing keeps the pages whose title contains the text, with the sections that hold
   them opened; clearing the box puts the tree back as it was. */
(function () {
  "use strict";

  function linkText(li) {
    var el = li.querySelector(
      ":scope > a.md-nav__link, :scope > label.md-nav__link, :scope > .md-nav__container > a.md-nav__link"
    );
    return el ? el.textContent.replace(/\s+/g, " ").trim().toLowerCase() : "";
  }

  function init() {
    var nav = document.querySelector(".md-sidebar--primary .md-nav--primary");
    if (!nav || nav.querySelector(".ada-filter")) return;
    var list = nav.querySelector(":scope > .md-nav__list");
    if (!list) return;

    var wrap = document.createElement("div");
    wrap.className = "ada-filter";
    var label = document.createElement("div");
    label.className = "ada-filter__label";
    label.textContent = "The course";
    var input = document.createElement("input");
    input.type = "search";
    input.className = "ada-filter__input";
    input.placeholder = "Filter pages";
    input.setAttribute("aria-label", "Filter pages");
    input.autocomplete = "off";
    wrap.appendChild(label);
    wrap.appendChild(input);
    nav.insertBefore(wrap, list);

    var toggles = Array.prototype.slice.call(list.querySelectorAll("input.md-nav__toggle"));
    var saved = toggles.map(function (t) { return t.checked; });

    function visit(li, q) {
      var own = linkText(li).indexOf(q) !== -1;
      var child = li.querySelector(":scope > nav > ul.md-nav__list");
      var any = false;
      if (child) {
        Array.prototype.forEach.call(child.querySelectorAll(":scope > li.md-nav__item"), function (c) {
          if (visit(c, q)) any = true;
        });
        if (own) {
          Array.prototype.forEach.call(child.querySelectorAll("li.md-nav__item"), function (c) {
            c.classList.remove("ada-hide");
          });
        }
      }
      var show = own || any;
      li.classList.toggle("ada-hide", !show);
      var toggle = li.querySelector(":scope > input.md-nav__toggle");
      if (toggle && any) toggle.checked = true;
      return show;
    }

    input.addEventListener("input", function () {
      var q = input.value.trim().toLowerCase();
      var items = list.querySelectorAll("li.md-nav__item");
      if (!q) {
        Array.prototype.forEach.call(items, function (li) { li.classList.remove("ada-hide"); });
        toggles.forEach(function (t, i) { t.checked = saved[i]; });
        nav.classList.remove("ada-filtering");
        return;
      }
      nav.classList.add("ada-filtering");
      Array.prototype.forEach.call(list.querySelectorAll(":scope > li.md-nav__item"), function (li) {
        visit(li, q);
      });
    });

    input.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        input.value = "";
        input.dispatchEvent(new Event("input"));
      }
    });
  }

  /* Code blocks whose lines run past the edge: .ada-more on the pre while it can still
     scroll right, which draws a fade on the right edge (ada.css). */
  function markOverflow() {
    var codes = document.querySelectorAll(".md-typeset pre > code");
    Array.prototype.forEach.call(codes, function (code) {
      var pre = code.parentElement;
      function update() {
        var more = code.scrollWidth - code.clientWidth - code.scrollLeft > 2;
        pre.classList.toggle("ada-more", more);
      }
      if (!code.dataset.adaMore) {
        code.dataset.adaMore = "1";
        code.addEventListener("scroll", update, { passive: true });
      }
      update();
    });
  }

  var resizeTimer = null;
  window.addEventListener("resize", function () {
    if (resizeTimer) clearTimeout(resizeTimer);
    resizeTimer = setTimeout(markOverflow, 150);
  });

  function start() {
    init();
    markOverflow();
    /* Web fonts change line widths once they arrive. */
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(markOverflow);
    }
  }

  if (typeof window.document$ !== "undefined" && window.document$.subscribe) {
    window.document$.subscribe(start);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
