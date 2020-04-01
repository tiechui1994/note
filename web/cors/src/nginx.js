const fs = require("fs");
const CONF = "/opt/local/nginx/conf/conf.d";
const TYPE = {
    '1': 'backend_simple.conf',
    '2': 'backend_regex.conf',
    '3': 'backend_origin.conf',
};

function setScript(request, response) {
    console.log(request.query, request.query['type']);
    const data = fs.readFileSync(__dirname + "/" + TYPE[request.query['type']]);

    fs.writeFile(CONF + "/backend.conf", data, null, function (err) {
        response.writeHead(200, {
            "content-type": "application/json"
        });

        if (err) {
            response.end(JSON.stringify(err));
        } else {
            const {exec} = require("child_process");
            exec("sudo service nginx reload", (err) => {
                if (err) {
                    response.end(JSON.stringify(err));
                } else {
                    response.end(JSON.stringify({"msg": "ok", "data": data.toString()}));
                }
            });
        }
    });
}

function getScript(request, response) {
    const data = fs.readFileSync(CONF + "/backend.conf");
    console.log(request.url, data.toString());
    response.writeHead(200, {
        "content-type": "application/json"
    });
    response.end(JSON.stringify({"msg": "ok", "data": data.toString()}));
}

exports.setScript = setScript;
exports.getScript = getScript;