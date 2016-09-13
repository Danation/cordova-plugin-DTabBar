(function (cordova) {
    cordova.define("cordova-plugin-DTabBar",
        function (require, exports, module) {
            var exec = require("cordova/exec");

            var DTabBar = function () {

                this.create = function (options) {
                    options = options || {};
                    exec(null, null, "DTabBar", "create", [options]);
                };

                this.selectItem = function (tab) {
                    exec(null, null, "DTabBar", "selectItem", [tab]);
                };

                this.setVisible = function (shouldShow) {
                    exec(null, null, "DTabBar", "setVisible", [shouldShow]);
                };
            };
            var dTabBar = new DTabBar();
            module.exports = dTabBar;
            exports = dTabBar;
        }
    );
}(window.cordova));