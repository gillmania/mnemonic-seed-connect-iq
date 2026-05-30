import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BTCSeedApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here.
    // The top-level menu is the initial view so that BACK on it exits the app.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var menu = new WatchUi.Menu2({:title => "Mnemonic Seed"});
        menu.addItem(new WatchUi.MenuItem("Generate seed", null, :generate, null));
        menu.addItem(new WatchUi.MenuItem("How it works", null, :info, null));
        return [ menu, new MainMenuDelegate() ];
    }

}

function getApp() as BTCSeedApp {
    return Application.getApp() as BTCSeedApp;
}