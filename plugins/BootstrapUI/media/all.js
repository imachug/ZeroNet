
/* ---- browser.coffee ---- */


(function() {
  window.BROWSERS = {
    firefox: {
      title: "Mozilla Firefox",
      linkText: "Install",
      link: "#",
      onclick: function() {
        return InstallTrigger.install({
          "ZeroNet": "/uimedia/plugins/bootstrapui/zeronet.xpi"
        });
      }
    },
    edge: {
      title: "Microsoft Edge",
      linkText: "Go to Microsoft Store",
      link: "#"
    },
    chrome: {
      title: "Google Chrome",
      linkText: "Go to Chrome Web Store",
      link: "#"
    },
    tor: {
      title: "Tor Browser",
      linkText: "Install",
      link: "#"
    }
  };

  window.detectBrowser = function() {
    if (window.InstallTrigger) {
      return "firefox";
    } else if (navigator.userAgent.indexOf("Edge/") > -1) {
      return "edge";
    } else {
      return "chrome";
    }
  };

}).call(this);


/* ---- main.coffee ---- */


(function() {
  var showBrowsers;

  showBrowsers = function(current, other) {
    var browser, i, len, node, renderBrowser, results;
    renderBrowser = function(browser, node) {
      node.innerHTML = "<img src='/uimedia/plugins/bootstrapui/imgs/" + browser + ".png'> <h3>" + BROWSERS[browser].title + "</h3> <a href='" + BROWSERS[browser].link + "'>" + BROWSERS[browser].linkText + "</a>";
      return node.querySelector("a").onclick = BROWSERS[browser].onclick;
    };
    node = document.querySelector("#current-browser");
    renderBrowser(current, node);
    results = [];
    for (i = 0, len = other.length; i < len; i++) {
      browser = other[i];
      node = document.createElement("div");
      node.className = "browser";
      renderBrowser(browser, node);
      results.push(document.querySelector("#other-browsers").appendChild(node));
    }
    return results;
  };

  window.addEventListener("load", function() {
    var browser;
    browser = detectBrowser();
    if (browser === "firefox") {
      return showBrowsers("firefox", ["chrome", "tor", "edge"]);
    } else if (browser === "edge") {
      return showBrowsers("edge", ["tor", "chrome", "firefox"]);
    } else if (browser === "chrome") {
      return showBrowsers("chrome", ["tor", "edge", "firefox"]);
    } else if (browser === "tor") {
      return showBrowsers("tor", ["chrome", "firefox", "edge"]);
    }
  });

}).call(this);