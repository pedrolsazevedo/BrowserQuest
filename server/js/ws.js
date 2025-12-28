const cls = require('./lib/class'),
    url = require('url'),
    http = require('http'),
    Utils = require('./utils'),
    _ = require('underscore'),
    BISON = require('bison'),
    WebSocketServer = require('ws').WebSocketServer,
    WS = {},
    useBison = false;

module.exports = WS;

/**
 * Abstract Server and Connection classes
 */
const Server = cls.Class.extend({
    init: function (port) {
        this.port = port;
    },

    onConnect: function (callback) {
        this.connection_callback = callback;
    },

    onError: function (callback) {
        this.error_callback = callback;
    },

    broadcast: function (message) {
        throw 'Not implemented';
    },

    forEachConnection: function (callback) {
        _.each(this._connections, callback);
    },

    addConnection: function (connection) {
        this._connections[connection.id] = connection;
    },

    removeConnection: function (id) {
        delete this._connections[id];
    },

    getConnection: function (id) {
        return this._connections[id];
    },
});

const Connection = cls.Class.extend({
    init: function (id, connection, server) {
        this._connection = connection;
        this._server = server;
        this.id = id;
    },

    onClose: function (callback) {
        this.close_callback = callback;
    },

    listen: function (callback) {
        this.listen_callback = callback;
    },

    broadcast: function (message) {
        throw 'Not implemented';
    },

    send: function (message) {
        throw 'Not implemented';
    },

    sendUTF8: function (data) {
        throw 'Not implemented';
    },

    close: function (logError) {
        log.info(
            'Closing connection to ' +
                this._connection._socket.remoteAddress +
                '. Error: ' +
                logError
        );
        this._connection.close();
    },
});

/**
 * Modern WebSocket Server using 'ws' library
 * Replaces the old MultiVersionWebsocketServer that supported draft-75, draft-76, etc.
 */
WS.MultiVersionWebsocketServer = Server.extend({
    _connections: {},
    _counter: 0,

    init: function (port) {
        const self = this;

        this._super(port);

        // Create HTTP server for status endpoint and WebSocket upgrade
        this._httpServer = http.createServer(function (request, response) {
            const path = url.parse(request.url).pathname;
            switch (path) {
                case '/status':
                    if (self.status_callback) {
                        response.writeHead(200);
                        response.write(self.status_callback());
                        break;
                    }
                default:
                    response.writeHead(404);
            }
            response.end();
        });

        this._httpServer.listen(port, function () {
            log.info('Server is listening on port ' + port);
        });

        // Create modern WebSocket server
        this._wsServer = new WebSocketServer({
            server: this._httpServer,
            perMessageDeflate: false,
            maxPayload: 0x100000,
        });

        this._wsServer.on('connection', function (ws, request) {
            // Add remoteAddress for compatibility
            ws._socket = ws._socket || {};
            ws._socket.remoteAddress = request.socket.remoteAddress;

            const c = new WS.ModernWebSocketConnection(self._createId(), ws, self);

            if (self.connection_callback) {
                self.connection_callback(c);
            }
            self.addConnection(c);
        });

        this._wsServer.on('error', function (error) {
            if (self.error_callback) {
                self.error_callback(error);
            }
            log.error('WebSocket server error: ' + error);
        });
    },

    _createId: function () {
        return '5' + Utils.random(99) + '' + this._counter++;
    },

    broadcast: function (message) {
        this.forEachConnection(function (connection) {
            connection.send(message);
        });
    },

    onRequestStatus: function (status_callback) {
        this.status_callback = status_callback;
    },
});

/**
 * Modern WebSocket Connection using 'ws' library
 * Replaces both worlizeWebSocketConnection and miksagoWebSocketConnection
 */
WS.ModernWebSocketConnection = Connection.extend({
    init: function (id, ws, server) {
        const self = this;

        this._super(id, ws, server);

        this._connection.on('message', function (data, isBinary) {
            if (self.listen_callback) {
                try {
                    const message = data.toString('utf8');
                    if (useBison) {
                        self.listen_callback(BISON.decode(message));
                    } else {
                        self.listen_callback(JSON.parse(message));
                    }
                } catch (e) {
                    if (e instanceof SyntaxError) {
                        self.close('Received message was not valid JSON.');
                    } else {
                        throw e;
                    }
                }
            }
        });

        this._connection.on('close', function () {
            if (self.close_callback) {
                self.close_callback();
            }
            self._server.removeConnection(self.id);
        });

        this._connection.on('error', function (error) {
            log.error('WebSocket connection error: ' + error);
        });
    },

    send: function (message) {
        let data;
        if (useBison) {
            data = BISON.encode(message);
        } else {
            data = JSON.stringify(message);
        }
        this.sendUTF8(data);
    },

    sendUTF8: function (data) {
        if (this._connection.readyState === 1) {
            // OPEN
            this._connection.send(data);
        }
    },
});

// Backward compatibility aliases
WS.worlizeWebSocketConnection = WS.ModernWebSocketConnection;
WS.miksagoWebSocketConnection = WS.ModernWebSocketConnection;
