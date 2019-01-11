const domin = "http://test.backend.com";
let http = new XMLHttpRequest();

function getMethod() {
    if (http) {
        let url = domin + "/image";
        http.open("POST", url, true);
        http.withCredentials = true; // 前端关键
        http.setRequestHeader("Content-Type", "application/json");
        http.onreadystatechange = function () {
            console.log(http.url);
            if (http.readyState == XMLHttpRequest.OPENED) {
                console.log("OPENED")
            }

            if (http.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("HEADERS_RECEIVED")
            }

            if (http.readyState == XMLHttpRequest.LOADING) {
                console.log("LOADING")
            }

            if (http.readyState == XMLHttpRequest.DONE) {
                console.log(http);
                console.log("DONE")
            }
        };
        http.send(null)
    }
}

function switchScript() {
    let http = new XMLHttpRequest();
    if (http) {
        let url = domin + "/switch";
        http.open("POST", url, true);
        http.send(null);
    }
}
