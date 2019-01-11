let fs = require("fs");
const {exec} = require("child_process");

function switchBackend(response) {
    let data = fs.readFileSync(__dirname + "/backend_complex.conf");
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

exports.switchBackend = switchBackend;