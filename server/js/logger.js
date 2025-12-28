/**
 * Simple logger to replace the old 'log' package
 * Provides a compatible API for BrowserQuest
 */

const levels = {
    ERROR: 1,
    INFO: 2,
    DEBUG: 3,
};

const Logger = function (level) {
    this.level = level || levels.INFO;
};

Logger.ERROR = levels.ERROR;
Logger.INFO = levels.INFO;
Logger.DEBUG = levels.DEBUG;

Logger.prototype.error = function () {
    if (this.level >= levels.ERROR) {
        console.error.apply(console, ['[ERROR]'].concat(Array.prototype.slice.call(arguments)));
    }
};

Logger.prototype.info = function () {
    if (this.level >= levels.INFO) {
        console.log.apply(console, ['[INFO]'].concat(Array.prototype.slice.call(arguments)));
    }
};

Logger.prototype.debug = function () {
    if (this.level >= levels.DEBUG) {
        console.log.apply(console, ['[DEBUG]'].concat(Array.prototype.slice.call(arguments)));
    }
};

module.exports = Logger;
