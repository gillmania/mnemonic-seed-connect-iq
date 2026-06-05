import Toybox.WatchUi;
import Toybox.Lang;

// Top-level menu: "Generate seed" launches the dice-entropy flow;
// "How it works" opens the InfoView.
class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :generate) {
            var menu = new WatchUi.Menu2({:title => "Seed length"});
            menu.addItem(new WatchUi.MenuItem("12 words", "128-bit", 128, null));
            menu.addItem(new WatchUi.MenuItem("24 words", "256-bit", 256, null));
            WatchUi.pushView(menu, new StrengthMenuDelegate(), WatchUi.SLIDE_UP);
        } else if (id == :info) {
            var view = new InfoView();
            WatchUi.pushView(view, new InfoDelegate(view), WatchUi.SLIDE_UP);
        }
    }
}

// Picks entropy strength, then lets the user choose dice or motion.
class StrengthMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var strengthBits = item.getId() as Number;
        var menu = new WatchUi.Menu2({:title => "Entropy source"});
        menu.addItem(new WatchUi.MenuItem("Dice rolls", "50 or 100 throws", :dice, null));
        menu.addItem(new WatchUi.MenuItem("Shake watch", "move for ~5 sec", :motion, null));
        WatchUi.pushView(menu, new MethodMenuDelegate(strengthBits), WatchUi.SLIDE_UP);
    }
}

// Launches the chosen entropy entry view with the selected strength.
class MethodMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _strengthBits as Number;

    function initialize(strengthBits as Number) {
        Menu2InputDelegate.initialize();
        _strengthBits = strengthBits;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :dice) {
            var view = new DiceEntryView(_strengthBits);
            WatchUi.pushView(view, new DiceEntryDelegate(view), WatchUi.SLIDE_UP);
        } else {
            var view = new MotionEntryView(_strengthBits);
            WatchUi.pushView(view, new MotionEntryDelegate(view), WatchUi.SLIDE_UP);
        }
    }
}
