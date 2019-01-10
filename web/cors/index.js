let invocation = new XMLHttpRequest();
let domin = 'http://test.backend.com';

function getMethod() {
    if (invocation) {
        let url = domin + "/image";
        invocation.open('GET', url, true);
        // invocation.setRequestHeader('Content-Type', 'application/json');
        // invocation.setRequestHeader("X", "11");
        invocation.onreadystatechange = function () {
            console.log(invocation.url);
            if (invocation.readyState == XMLHttpRequest.OPENED) {
                console.log("OPENED")
            }

            if (invocation.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("HEADERS_RECEIVED")
            }

            if (invocation.readyState == XMLHttpRequest.LOADING) {
                console.log("LOADING")
            }

            if (invocation.readyState == XMLHttpRequest.DONE) {
                console.log(invocation);
                console.log("DONE")
            }
        };

        invocation.send(null);
    }
}

function switchScript() {
    if (invocation) {
        let url = domin + "/switch";
        invocation.open('POST', url, true);
        // invocation.setRequestHeader('Content-Type', 'application/json');
        invocation.onreadystatechange = function () {
            console.log(invocation.url);
            if (invocation.readyState == XMLHttpRequest.OPENED) {
                console.log("OPENED")
            }

            if (invocation.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
                console.log("HEADERS_RECEIVED")
            }

            if (invocation.readyState == XMLHttpRequest.LOADING) {
                console.log("LOADING")
            }

            if (invocation.readyState == XMLHttpRequest.DONE) {
                console.log(invocation);
                console.log("DONE")
            }
        };

        invocation.send(null);
    }
}
