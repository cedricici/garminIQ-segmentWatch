
using Toybox.Application;
using Toybox.Time;

// This is the primary entry point of the application.
class CedricWatchApp extends Application.AppBase
{

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    // This method runs each time the main application starts.
    function getInitialView() {
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new AnalogView(), new AnalogDelegate()];
        } else {
            return [new CedricWatchView()];
        }
    }

}
