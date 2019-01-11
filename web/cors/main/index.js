const domin = "http://test.backend.com";
let http = new XMLHttpRequest();
let script = "";

function postMethod() {
    if (http) {
        let url = domin + "/image";
        http.open("POST", url, true);
        // http.withCredentials = true; // 前端关键
        // http.setRequestHeader("Content-Type", "application/json");
        http.onreadystatechange = function () {
            if (http.readyState == XMLHttpRequest.DONE) {
                console.log("XMLHttpRequest: ", http);
                console.log("method: ", 'POST', "url:", url);
                console.log("data: ", http.response);
                console.log("===========================")
            }
        };
        http.send(null)
    }
}

function getMethod() {
    if (http) {
        let url = domin + "/get";
        http.open("GET", url, true);
        // http.withCredentials = true; // 前端关键
        // http.setRequestHeader("Content-Type", "application/json");
        http.onreadystatechange = function () {
            if (http.readyState == XMLHttpRequest.DONE) {
                console.log("XMLHttpRequest: ", http);
                console.log("method: ", 'POST', "url:", url);
                console.log("data: ", http.response);
                console.log("===========================")
            }
        };
        http.send(null)
    }
}

function switchScript(type) {
    console.log(type);
    if (http) {
        let url = domin + "/switch?type=" + type;
        http.open("GET", url, true);
        http.onreadystatechange = function () {
            if (http.readyState == XMLHttpRequest.DONE) {
                let data = JSON.parse(http.responseText);
                let conf = document.getElementById("nginx-conf");
                conf.setAttribute("style", "text-align:left; margin-left:29%; border:1px solid; font-size:14px; " +
                    "width:fit-content; font-family:sans-serif; padding:10px; margin-top:-8px; margin-bottom: -8px;");
                conf.innerHTML = data.data;
                script = data.data;
                console.log(data.data);
            }
        };
        http.send();
    }
}

function getScript() {
    if (script) {
        let conf = document.getElementById("nginx-conf");
        conf.setAttribute("style", "text-align:left; margin-left:29%; border:1px solid; font-size:14px; " +
            "width:fit-content; font-family:sans-serif; padding:10px; margin-top:-8px; margin-bottom: -8px;");
        conf.innerHTML = script;
        return
    }

    if (http) {
        let url = domin + "/script";
        http.open("GET", url, true);
        http.onreadystatechange = function () {
            if (http.readyState == XMLHttpRequest.DONE) {
                let data = JSON.parse(http.responseText);
                let conf = document.getElementById("nginx-conf");
                conf.setAttribute("style", "text-align:left; margin-left:29%; border:1px solid; font-size:14px; " +
                    "width:fit-content; font-family:sans-serif; padding:10px; margin-top:-8px; margin-bottom: -8px;");
                conf.innerHTML = data.data;
                console.log(data.data);
            }
        };
        http.send();
    }
}