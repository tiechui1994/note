let n = require('./nginx');
let http = require('http');
let port = 8080;

function post(request, response) {
    console.log(request.url);
    let data = {"a": 11};
    response.writeHead(200, {
        'content-type': 'application/json'
    });

    response.end(JSON.stringify(data));
}

function get(request, response) {
    console.log(request.url);
    let data = {"a": 11};
    response.writeHead(200, {
        "content-type": "application/json",
        "Set-Cookie": "www=1;max-age=86400;HttpOnly"
    });
    response.end(JSON.stringify(data));
}

function head(request, response) {

}

function put(request, response) {

}

let router = {
    "GET": get,
    "POST": post,
    "HEAD": head,
    "PUT": put,
    "switch": n.switchBackend
};

let server = http.createServer(function (request, response) {
        if (request.url.indexOf("switch") != -1) {
            return router["switch"](response);
        }

        router[request.method](request, response)
    }
);

server.listen(port);
console.log('Server running on port 8080');
