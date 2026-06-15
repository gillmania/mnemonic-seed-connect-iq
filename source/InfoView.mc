import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Paged explanation of how the app works and why it is secure. UP/DOWN page,
// BACK exits. Pure text, no input collected.
class InfoView extends WatchUi.View {

    // Each page is a [title, line, line, ...]. Kept short to fit small screens.
    private var _pages as Array<Array<String>> = [
        ["How it works",
            "Use the buttons to",
            "pick a die, or",
            "shake the watch.",
            "Get a BIP-39 seed",
            "of 12 or 24 words."],
        ["Dice + chance",
            "Your dice give",
            "entropy YOU control.",
            "The watch adds its",
            "own secure random",
            "bytes on top."],
        ["How mixing works",
            "Both sources are",
            "combined with",
            "SHA-256, so the",
            "result reflects",
            "both inputs."],
        ["Your own entropy",
            "You add randomness",
            "the watch alone",
            "would not have.",
            "More throws = more",
            "of your own entropy."],
        ["Stays offline",
            "No network, nothing",
            "is saved. The seed",
            "lives only on screen",
            "and is wiped when",
            "you leave."],
        ["Keep it secret",
            "Write the words on",
            "paper, in order.",
            "Never type them into",
            "a phone or website.",
            "Guard the watch."],
        ["Use anywhere",
            "It is a standard",
            "BIP-39 phrase. Use",
            "it with any wallet",
            "that takes 12 or",
            "24 word seeds."],
        ["Please note",
            "For your own use,",
            "no warranty. Check",
            "the phrase with an",
            "offline tool. You",
            "keep it safe."]
    ];
    private var _page as Number = 0;

    function initialize() {
        View.initialize();
    }

    function pageCount() as Number { return _pages.size(); }

    function nextPage() as Void {
        if (_page < _pages.size() - 1) { _page++; WatchUi.requestUpdate(); }
    }

    function prevPage() as Void {
        if (_page > 0) { _page--; WatchUi.requestUpdate(); }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var page = _pages[_page];

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 0.12).toNumber(), Graphics.FONT_XTINY,
            page[0] + "  " + (_page + 1) + "/" + _pages.size(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Build version, shown on the first page so a fresh sideload is
        // verifiable without cluttering the entry screens.
        if (_page == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, (h * 0.19).toNumber(), Graphics.FONT_XTINY, Version.STRING,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var y = h * 0.26;
        var step = (h * 0.52) / 6;
        for (var i = 1; i < page.size(); i++) {
            dc.drawText(w / 2, y.toNumber(), Graphics.FONT_XTINY, page[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += step;
        }

        var s = (w * 0.035).toNumber();
        if (s < 5) { s = 5; }
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (_page > 0) {
            var ay = (h * 0.04).toNumber();
            dc.fillPolygon([[cx, ay - s], [cx - s, ay + s], [cx + s, ay + s]]);
        }
        if (_page < _pages.size() - 1) {
            var ay = (h * 0.96).toNumber();
            dc.fillPolygon([[cx, ay + s], [cx - s, ay - s], [cx + s, ay - s]]);
        }
    }
}

class InfoDelegate extends WatchUi.BehaviorDelegate {

    private var _view as InfoView;

    function initialize(view as InfoView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onPreviousPage() as Boolean { _view.prevPage(); return true; }
    function onNextPage() as Boolean { _view.nextPage(); return true; }
}
