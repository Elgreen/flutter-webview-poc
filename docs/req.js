// Set response 
function setResponse(responseText) {
    currentTime = new Date().toLocaleTimeString();
    document.getElementById("response").innerHTML = `<p>Event time: ${currentTime}.</p><p>Event data: ${responseText}</p>`;
}

setResponse("Loading...");