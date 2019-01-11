const nginx = require('./nginx');
const express = require('express');
const cookieParser = require('cookie-parser');

const app = express();
const port = 8080;

function post(request, response) {
    console.log("cookies is:", request.cookies);
    /**
     * nodejs vs golang 的 cookie 字段对比
     *
     * path: Path
     * domain: Domain
     * maxAge: MaxAge
     * expires: Expires
     * signed: Secure
     * httpOnly: HttpOnly
     */
    response.cookie('access', 'abc', {
        path: "/",
        domain: "test.backend.com",
        maxAge: 120 * 1000,
        httpOnly: true,
        signed: false,
    });

    response.cookie('fresh', 'abc', {
        path: "/",
        domain: "test.backend.com",
        maxAge: 120 * 1000,
        httpOnly: true,
        signed: false,
    });

    response.writeHead(200, {
        "content-type": "application/json",
    });
    let data = {status: 200, msg: 'ok', cookie: request.cookies};
    response.end(JSON.stringify(data))
}

function get(request, response) {
    console.log("cookies is:", request.cookies);
    response.cookie('name', 'abc', {
        "path": "/",
        domain: "test.backend.com",
        maxAge: 20 * 1000,
        httpOnly: true,
        signed: false,
    });
    response.writeHead(200, {
        "content-type": "application/json",
    });
    response.end()
}

function options(request, response) {
    response.end()
}

function head(request, response) {

}

function put(request, response) {

}

const router = {
    "GET": get,
    "POST": post,
    "HEAD": head,
    "PUT": put,
    "OPTIONS": options,
    "switch": nginx.setScript,
    "script": nginx.getScript,
};

app.use(cookieParser());
app.use(function (request, response) {
    console.log(request.url);

    if (request.url.indexOf("switch") != -1) {
        return router["switch"](request, response);
    }

    if (request.url.indexOf("script") != -1) {
        return router["script"](request, response);
    }

    router[request.method](request, response)
});

app.listen(port);
console.log('Server running on port 8080');
