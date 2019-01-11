let fs = require("fs");
const {exec} = require("child_process");
const TYPE = {
    '1': 'backend_simple.conf',
    '2': 'backend_regex.conf',
    '3': 'backend_origin.conf',
};

function setScript(request, response) {
    console.log(request.query, request.query['type']);
    let data = fs.readFileSync(__dirname + "/" + TYPE[request.query['type']]);
    console.log(data.toString());

    fs.writeFile("/opt/local/nginx/conf/conf.d/backend.conf", data, null, function (err) {
        response.writeHead(200, {
            "content-type": "application/json"
        });

        if (err) {
            response.end(JSON.stringify(err));
        } else {
            exec("sudo service nginx reload", (err, stdout, stderr) => {
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
    let data = fs.readFileSync("/opt/local/nginx/conf/conf.d/backend.conf");
    console.log(data.toString());
    response.writeHead(200, {
        "content-type": "application/json"
    });
    response.end(JSON.stringify({"msg": "ok", "data": data.toString()}));
}

exports.setScript = setScript;
exports.getScript = getScript;