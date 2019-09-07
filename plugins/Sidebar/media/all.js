
/* ---- Class.coffee ---- */


(function() {
  var Class,
    slice = [].slice;

  Class = (function() {
    function Class() {}

    Class.prototype.trace = true;

    Class.prototype.log = function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (!this.trace) {
        return;
      }
      if (typeof console === 'undefined') {
        return;
      }
      args.unshift("[" + this.constructor.name + "]");
      console.log.apply(console, args);
      return this;
    };

    Class.prototype.logStart = function() {
      var args, name;
      name = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (!this.trace) {
        return;
      }
      this.logtimers || (this.logtimers = {});
      this.logtimers[name] = +(new Date);
      if (args.length > 0) {
        this.log.apply(this, ["" + name].concat(slice.call(args), ["(started)"]));
      }
      return this;
    };

    Class.prototype.logEnd = function() {
      var args, ms, name;
      name = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      ms = +(new Date) - this.logtimers[name];
      this.log.apply(this, ["" + name].concat(slice.call(args), ["(Done in " + ms + "ms)"]));
      return this;
    };

    return Class;

  })();

  window.Class = Class;

}).call(this);

/* ---- Console.coffee ---- */


(function() {
  var Console,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Console = (function(superClass) {
    extend(Console, superClass);

    function Console(sidebar) {
      this.sidebar = sidebar;
      this.stopDragY = bind(this.stopDragY, this);
      this.cleanup = bind(this.cleanup, this);
      this.onClosed = bind(this.onClosed, this);
      this.onOpened = bind(this.onOpened, this);
      this.open = bind(this.open, this);
      this.close = bind(this.close, this);
      this.loadConsoleText = bind(this.loadConsoleText, this);
      this.addLines = bind(this.addLines, this);
      this.formatLine = bind(this.formatLine, this);
      this.checkTextIsBottom = bind(this.checkTextIsBottom, this);
      this.tag = null;
      this.opened = false;
      this.filter = null;
      if (window.top.location.hash === "#console") {
        setTimeout(((function(_this) {
          return function() {
            return _this.open();
          };
        })(this)), 10);
      }
    }

    Console.prototype.createHtmltag = function() {
      if (!this.container) {
        this.container = $("<div class=\"console-container\">\n	<div class=\"console\">\n		<div class=\"console-top\">\n			<div class=\"console-text\">Loading...</div>\n		</div>\n		<div class=\"console-middle\">\n			<div class=\"mynode\"></div>\n			<div class=\"peers\">\n				<div class=\"peer\"><div class=\"line\"></div><a href=\"#\" class=\"icon\">\u25BD</div></div>\n			</div>\n		</div>\n	</div>\n</div>");
        this.text = this.container.find(".console-text");
        this.text_elem = this.text[0];
        this.text.on("mousewheel", (function(_this) {
          return function(e) {
            if (e.originalEvent.deltaY < 0) {
              _this.text.stop();
            }
            return RateLimit(300, _this.checkTextIsBottom);
          };
        })(this));
        this.text.is_bottom = true;
        this.container.appendTo(document.body);
        this.tag = this.container.find(".console");
        this.container.on("mousedown touchend touchcancel", (function(_this) {
          return function(e) {
            if (e.target !== e.currentTarget) {
              return true;
            }
            _this.log("closing");
            if ($(document.body).hasClass("body-console")) {
              _this.close();
              return true;
            }
          };
        })(this));
        return this.loadConsoleText();
      }
    };

    Console.prototype.checkTextIsBottom = function() {
      return this.text.is_bottom = Math.round(this.text_elem.scrollTop + this.text_elem.clientHeight) >= this.text_elem.scrollHeight - 15;
    };

    Console.prototype.toColor = function(text, saturation, lightness) {
      var hash, i, j, ref;
      if (saturation == null) {
        saturation = 60;
      }
      if (lightness == null) {
        lightness = 70;
      }
      hash = 0;
      for (i = j = 0, ref = text.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        hash += text.charCodeAt(i) * i;
        hash = hash % 1777;
      }
      return "hsl(" + (hash % 360) + ("," + saturation + "%," + lightness + "%)");
    };

    Console.prototype.formatLine = function(line) {
      var added, level, match, module, ref, text;
      match = line.match(/(\[.*?\])[ ]+(.*?)[ ]+(.*?)[ ]+(.*)/);
      if (!match) {
        return line.replace(/\</g, "&lt;").replace(/\>/g, "&gt;");
      }
      ref = line.match(/(\[.*?\])[ ]+(.*?)[ ]+(.*?)[ ]+(.*)/), line = ref[0], added = ref[1], level = ref[2], module = ref[3], text = ref[4];
      added = "<span style='color: #dfd0fa'>" + added + "</span>";
      level = "<span style='color: " + (this.toColor(level, 100)) + ";'>" + level + "</span>";
      module = "<span style='color: " + (this.toColor(module, 60)) + "; font-weight: bold;'>" + module + "</span>";
      text = text.replace(/(Site:[A-Za-z0-9\.]+)/g, "<span style='color: #AAAAFF'>$1</span>");
      text = text.replace(/\</g, "&lt;").replace(/\>/g, "&gt;");
      return added + " " + level + " " + module + " " + text;
    };

    Console.prototype.addLines = function(lines, animate) {
      var html_lines, j, len, line;
      if (animate == null) {
        animate = true;
      }
      html_lines = [];
      this.logStart("formatting");
      for (j = 0, len = lines.length; j < len; j++) {
        line = lines[j];
        html_lines.push(this.formatLine(line));
      }
      this.logEnd("formatting");
      this.logStart("adding");
      this.text.append(html_lines.join("<br>") + "<br>");
      this.logEnd("adding");
      if (this.text.is_bottom && animate) {
        return this.text.stop().animate({
          scrollTop: this.text_elem.scrollHeight - this.text_elem.clientHeight + 1
        }, 600, 'easeInOutCubic');
      }
    };

    Console.prototype.loadConsoleText = function() {
      this.sidebar.wrapper.ws.cmd("consoleLogRead", {
        filter: this.filter
      }, (function(_this) {
        return function(res) {
          var pos_diff, size_read, size_total;
          _this.text.html("");
          pos_diff = res["pos_end"] - res["pos_start"];
          size_read = Math.round(pos_diff / 1024);
          size_total = Math.round(res['pos_end'] / 1024);
          _this.text.append("Displaying " + res.lines.length + " of " + res.num_found + " lines found in the last " + size_read + "kB of the log file. (" + size_total + "kB total)<br>");
          _this.addLines(res.lines, false);
          return _this.text_elem.scrollTop = _this.text_elem.scrollHeight;
        };
      })(this));
      return this.sidebar.wrapper.ws.cmd("consoleLogStream", {
        filter: this.filter
      }, (function(_this) {
        return function(res) {
          return _this.stream_id = res.stream_id;
        };
      })(this));
    };

    Console.prototype.close = function() {
      this.sidebar.move_lock = "y";
      this.sidebar.startDrag();
      return this.sidebar.stopDrag();
    };

    Console.prototype.open = function() {
      this.createHtmltag();
      this.sidebar.fixbutton_targety = this.sidebar.page_height;
      return this.stopDragY();
    };

    Console.prototype.onOpened = function() {
      this.sidebar.onClosed();
      return this.log("onOpened");
    };

    Console.prototype.onClosed = function() {
      $(document.body).removeClass("body-console");
      if (this.stream_id) {
        return this.sidebar.wrapper.ws.cmd("consoleLogStreamRemove", {
          stream_id: this.stream_id
        });
      }
    };

    Console.prototype.cleanup = function() {
      if (this.container) {
        this.container.remove();
        return this.container = null;
      }
    };

    Console.prototype.stopDragY = function() {
      var targety;
      if (this.sidebar.fixbutton_targety === this.sidebar.fixbutton_inity) {
        targety = 0;
        this.opened = false;
      } else {
        targety = this.sidebar.fixbutton_targety - this.sidebar.fixbutton_inity;
        this.onOpened();
        this.opened = true;
      }
      if (this.tag) {
        this.tag.css("transition", "0.5s ease-out");
        this.tag.css("transform", "translateY(" + targety + "px)").one(transitionEnd, (function(_this) {
          return function() {
            _this.tag.css("transition", "");
            if (!_this.opened) {
              return _this.cleanup();
            }
          };
        })(this));
      }
      this.log("stopDragY", "opened:", this.opened, targety);
      if (!this.opened) {
        return this.onClosed();
      }
    };

    return Console;

  })(Class);

  window.Console = Console;

}).call(this);

/* ---- Sidebar.coffee ---- */


(function() {
  var Sidebar,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Sidebar = (function(superClass) {
    extend(Sidebar, superClass);

    function Sidebar(prefix) {
      this.prefix = prefix;
      this.animDrag = bind(this.animDrag, this);
      this.waitMove = bind(this.waitMove, this);
      this.resized = bind(this.resized, this);
      this.opened = false;
      this.width = 410;
      this.console = new Console(this);
      this.fixbutton = $(this.prefix.dom.querySelector(".fixbutton"));
      this.fixbutton_addx = 0;
      this.fixbutton_addy = 0;
      this.fixbutton_initx = 0;
      this.fixbutton_inity = 15;
      this.fixbutton_targetx = 0;
      this.move_lock = null;
      this.page_width = $(window).width();
      this.page_height = $(window).height();
      this.initFixbutton();
      this.initTag();
      this.dragStarted = 0;
    }

    Sidebar.prototype.initFixbutton = function() {
      this.fixbutton.on("mousedown touchstart", (function(_this) {
        return function(e) {
          if (e.button > 0) {
            return;
          }
          e.preventDefault();
          _this.fixbutton.off("click touchend touchcancel");
          _this.dragStarted = +(new Date);
          return $(window).one("mousemove touchmove", function(e) {
            var mousex, mousey;
            mousex = e.pageX;
            mousey = e.pageY;
                        if (mousex != null) {
              mousex;
            } else {
              mousex = e.originalEvent.touches[0].pageX;
            };
                        if (mousey != null) {
              mousey;
            } else {
              mousey = e.originalEvent.touches[0].pageY;
            };
            _this.fixbutton_addx = _this.fixbutton.offset().left - mousex;
            _this.fixbutton_addy = _this.fixbutton.offset().top - mousey;
            return _this.startDrag();
          });
        };
      })(this));
      this.fixbutton.parent().on("click touchend touchcancel", (function(_this) {
        return function(e) {
          if ((+(new Date)) - _this.dragStarted < 100) {
            window.top.location = _this.fixbutton.find(".fixbutton-bg").attr("href");
          }
          return _this.stopDrag();
        };
      })(this));
      this.resized();
      return $(window).on("resize", this.resized);
    };

    Sidebar.prototype.initTag = function() {
      this.tag = $("<div class=\"sidebar\">\n	<iframe src=\"/ZeroNet-Internal/Sidebar?wrapper_key=" + this.prefix.wrapper_key + "\"></iframe>\n</div>");
      return $(this.prefix.dom).append(this.tag);
    };

    Sidebar.prototype.resized = function() {
      this.page_width = $(window).width();
      this.page_height = $(window).height();
      this.fixbutton_initx = this.page_width - 75;
      if (this.opened) {
        return this.fixbutton.css({
          left: this.fixbutton_initx - this.width
        });
      } else {
        return this.fixbutton.css({
          left: this.fixbutton_initx
        });
      }
    };

    Sidebar.prototype.startDrag = function() {
      this.log("startDrag", this.fixbutton_initx, this.fixbutton_inity);
      this.fixbutton_targetx = this.fixbutton_initx;
      this.fixbutton_targety = this.fixbutton_inity;
      this.fixbutton.addClass("dragging");
      this.fixbutton.one("click", (function(_this) {
        return function(e) {
          var moved_x, moved_y;
          _this.stopDrag();
          _this.fixbutton.removeClass("dragging");
          moved_x = Math.abs(_this.fixbutton.offset().left - _this.fixbutton_initx);
          moved_y = Math.abs(_this.fixbutton.offset().top - _this.fixbutton_inity);
          if (moved_x > 5 || moved_y > 10) {
            return e.preventDefault();
          }
        };
      })(this));
      $(window).on("mousemove touchmove", this.animDrag);
      $(window).on("mousemove touchmove", this.waitMove);
      this.tag.css("pointer-events", "none");
      return $(window).one("mouseup touchend touchcancel", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.stopDrag();
        };
      })(this));
    };

    Sidebar.prototype.waitMove = function(e) {
      var moved_x, moved_y;
      moved_x = Math.abs(parseInt(this.fixbutton[0].style.left) - this.fixbutton_targetx);
      moved_y = Math.abs(parseInt(this.fixbutton[0].style.top) - this.fixbutton_targety);
      if (moved_x > 5 && (+(new Date)) - this.dragStarted + moved_x > 50) {
        this.moved("x");
        this.fixbutton.stop().animate({
          "top": this.fixbutton_inity
        }, 1000);
        return $(window).off("mousemove touchmove", this.waitMove);
      } else if (moved_y > 5 && (+(new Date)) - this.dragStarted + moved_y > 50) {
        this.moved("y");
        return $(window).off("mousemove touchmove", this.waitMove);
      }
    };

    Sidebar.prototype.moved = function(direction) {
      this.log("Moved", direction);
      this.move_lock = direction;
      if (direction === "y") {
        $(document.body).addClass("body-console");
        return;
      }
      $(document.body).addClass("body-sidebar");
      this.tag.on("mousedown touchend touchcancel", (function(_this) {
        return function(e) {
          if (e.target !== e.currentTarget) {
            return true;
          }
          _this.log("closing");
          if ($(document.body).hasClass("body-sidebar")) {
            _this.close();
            return true;
          }
        };
      })(this));
      $(window).off("resize");
      return $(window).on("resize", (function(_this) {
        return function() {
          return _this.resized();
        };
      })(this));
    };

    Sidebar.prototype.animDrag = function(e) {
      var mousex, mousey, overdrag, overdrag_percent, targetx, targety;
      mousex = e.pageX;
      mousey = e.pageY;
      if (!mousex && e.originalEvent.touches) {
        mousex = e.originalEvent.touches[0].pageX;
        mousey = e.originalEvent.touches[0].pageY;
      }
      overdrag = this.fixbutton_initx - this.width - mousex;
      if (overdrag > 0) {
        overdrag_percent = 1 + overdrag / 300;
        mousex = (mousex + (this.fixbutton_initx - this.width) * overdrag_percent) / (1 + overdrag_percent);
      }
      targetx = this.fixbutton_initx - mousex - this.fixbutton_addx;
      targety = this.fixbutton_inity - mousey - this.fixbutton_addy;
      if (this.move_lock === "x") {
        targety = this.fixbutton_inity;
      } else if (this.move_lock === "y") {
        targetx = this.fixbutton_initx;
      }
      if (!this.move_lock || this.move_lock === "x") {
        this.fixbutton[0].style.left = (mousex + this.fixbutton_addx) + "px";
        this.tag[0].style.transform = "translateX(" + (0 - targetx) + "px)";
      }
      if (!this.move_lock || this.move_lock === "y") {
        this.fixbutton[0].style.top = (mousey + this.fixbutton_addy) + "px";
        if (this.console.tag) {
          this.console.tag[0].style.transform = "translateY(" + (0 - targety) + "px)";
        }
      }
      if ((!this.opened && targetx > this.width / 3) || (this.opened && targetx > this.width * 0.9)) {
        this.fixbutton_targetx = this.fixbutton_initx - this.width;
      } else {
        this.fixbutton_targetx = this.fixbutton_initx;
      }
      if ((!this.console.opened && 0 - targety > this.page_height / 10) || (this.console.opened && 0 - targety > this.page_height * 0.8)) {
        return this.fixbutton_targety = this.page_height - this.fixbutton_inity - 50;
      } else {
        return this.fixbutton_targety = this.fixbutton_inity;
      }
    };

    Sidebar.prototype.stopDrag = function() {
      var left, top;
      $(window).off("mousemove touchmove");
      this.fixbutton.off("mousemove touchmove");
      if (!this.fixbutton.hasClass("dragging")) {
        return;
      }
      this.fixbutton.removeClass("dragging");
      if (this.fixbutton_targetx !== this.fixbutton.offset().left || this.fixbutton_targety !== this.fixbutton.offset().top) {
        if (this.move_lock === "y") {
          top = this.fixbutton_targety;
          left = this.fixbutton_initx;
        }
        if (this.move_lock === "x") {
          top = this.fixbutton_inity;
          left = this.fixbutton_targetx;
        }
        this.fixbutton.stop().animate({
          "left": left,
          "top": top
        }, 500, "easeOutBack", (function(_this) {
          return function() {
            return $(".fixbutton-bg").trigger("mouseout");
          };
        })(this));
        this.stopDragX();
        this.console.stopDragY();
      }
      this.move_lock = null;
      return this.tag.css("pointer-events", "");
    };

    Sidebar.prototype.stopDragX = function() {
      var targetx;
      if (this.fixbutton_targetx === this.fixbutton_initx || this.move_lock === "y") {
        targetx = 0;
        this.opened = false;
      } else {
        targetx = this.width;
        this.onOpened();
        this.opened = true;
      }
      this.tag.css("transition", "0.4s ease-out");
      this.tag.css("transform", "translateX(-" + targetx + "px)").one(transitionEnd, (function(_this) {
        return function() {
          return _this.tag.css("transition", "");
        };
      })(this));
      this.log("stopdrag", "opened:", this.opened);
      if (!this.opened) {
        return this.onClosed();
      }
    };

    Sidebar.prototype.onOpened = function() {
      this.log("Opened");
      return this.tag.find(".close").off("click touchend").on("click touchend", (function(_this) {
        return function(e) {
          _this.close();
          return false;
        };
      })(this));
    };

    Sidebar.prototype.close = function() {
      this.move_lock = "x";
      this.startDrag();
      return this.stopDrag();
    };

    Sidebar.prototype.onClosed = function() {
      $(window).off("resize");
      $(window).on("resize", this.resized);
      return $(document.body).removeClass("body-sidebar");
    };

    return Sidebar;

  })(Class);

  Prefix.plugins.push(Sidebar);

  window.transitionEnd = 'transitionend webkitTransitionEnd oTransitionEnd otransitionend';

}).call(this);
