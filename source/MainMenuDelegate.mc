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

// Picks entropy strength, then opens the dice entry view. Item id is the bit count.
class StrengthMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var strengthBits = item.getId() as Number;
        var view = new DiceEntryView(strengthBits);
        WatchUi.pushView(view, new DiceEntryDelegate(view), WatchUi.SLIDE_UP);
    }
}
