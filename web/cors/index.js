var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/post-here/';
var body = '<?xml version="1.0"?><person><name>Arun</name></person>';

function callOtherDomain() {
    if (invocation) {
        invocation.open('POST', url, true);
        invocation.setRequestHeader('X-PINGOTHER', 'pingpong');
        invocation.setRequestHeader('Content-Type', 'application/xml');
        invocation.onreadystatechange = handler;
        invocation.send(body);
    }
}

window.onload = function () {
    callOtherDomain()
};