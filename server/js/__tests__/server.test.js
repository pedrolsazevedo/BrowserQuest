/**
 * Basic server tests for BrowserQuest
 */

describe('BrowserQuest Server', () => {
    test('Logger module exists and exports expected API', () => {
        const Logger = require('../logger');
        expect(Logger).toBeDefined();
        expect(Logger.ERROR).toBeDefined();
        expect(Logger.INFO).toBeDefined();
        expect(Logger.DEBUG).toBeDefined();

        const logger = new Logger(Logger.INFO);
        expect(logger.info).toBeDefined();
        expect(logger.error).toBeDefined();
        expect(logger.debug).toBeDefined();
    });

    test('WebSocket module exists and exports expected classes', () => {
        const WS = require('../ws');
        expect(WS).toBeDefined();
        expect(WS.MultiVersionWebsocketServer).toBeDefined();
        expect(WS.ModernWebSocketConnection).toBeDefined();
    });

    test('Utils module provides random function', () => {
        const Utils = require('../utils');
        expect(Utils).toBeDefined();
        expect(Utils.random).toBeDefined();

        const rand = Utils.random(100);
        expect(rand).toBeGreaterThanOrEqual(0);
        expect(rand).toBeLessThan(100);
    });
});
