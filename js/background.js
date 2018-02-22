// Set up context menu at install time.
chrome.runtime.onInstalled.addListener(function() {
  var context = "selection";
  var title = "Annotate \"%s\"";
  var id = chrome.contextMenus.create({"title": title, "contexts":[context],
                                         "id": "context" + context});  
  chrome.declarativeContent.onPageChanged.removeRules(undefined, function() {
    chrome.declarativeContent.onPageChanged.addRules([
      {
        conditions: [
          new chrome.declarativeContent.PageStateMatcher({
            pageUrl: { hostEquals: 'github.com', schemes: ['https'] },
          })
        ],
        // And shows the extension's page action.
        actions: [ new chrome.declarativeContent.ShowPageAction() ]
      }
    ]);
  });

});

// add click event
chrome.contextMenus.onClicked.addListener(onClickHandler);

// The onClicked callback function.
function onClickHandler(info, tab) {
  var formUrl = "../html/popup.html";
  var highlight = info.selectionText;
  var w = (screen.width/4);
  var h = (screen.width/3);
  var left = (screen.width/2)-(w/2);
  var top = (screen.height/2)-(h/2);   
  chrome.windows.create({'url': formUrl, 'type': 'popup', 
  	'width': w, 'height': h, 'left': left, 'top': top} , function(window) {
  		$('highlight').val(info.selectionText);
    });
};