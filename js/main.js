var example = [
  "# hello, This is Markdown Live Preview",
  "",
  "----",
  "## what is Markdown?",
  "see [Wikipedia](http://en.wikipedia.org/wiki/Markdown)",
  "",
  "> Markdown is a lightweight markup language, originally created by John Gruber and Aaron Swartz allowing people \"to write using an easy-to-read, easy-to-write plain text format, then convert it to structurally valid XHTML (or HTML)\".",
  "",
  "----",
  "## usage",
  "1. Write markdown text in this textarea.",
  "2. Click 'HTML Preview' button.",
  "",
  "----",
  "## markdown quick reference",
  "# headers",
  "",
  "*emphasis*",
  "",
  "**strong**",
  "",
  "* list",
  "",
  ">block quote",
  "",
  "    code (4 spaces indent)",
  "[links](http://wikipedia.org)",
  "",
  ""
].join("\n");

$(function() {
  var currentMode = 'edit';
  var body = $('#body');
  var header = $('#header');
  var headerHeight = header.outerHeight();
  var titleHeight = $('#header h1').outerHeight();
  var fixedTop = -titleHeight;
  var scrollTops = {
    'edit' : 0,
    'preview' : 0
  };

  var isEdited = false;

  $('#body').val(example);
  $('#output').html(markdown.toHTML(example));
  $('#body').bind('keyup', function() {
    isEdited = true;
    $('#output').html(markdown.toHTML($('#body').val()));
  });


  //reference
  $("table#reference tr td:odd").each(function(index, element) {
    var self = $(element);
    if (self.html() === "") {
      self.html(markdown.toHTML(self.siblings().html()));
    }
  });

  //autoresize
  $('textarea').autosize();
  
  //leave
  $(window).bind('beforeunload', function() {
    if (isEdited) {
      return 'Are you sure you want to leave? Your changes will be lost.';
    }
  });
});

window.addEventListener('load', function(evt) {
    // Cache a reference to the status display SPAN
    statusDisplay = document.getElementById('status-display');
    // Handle the bookmark form submit event with our addBookmark function
    document.getElementById('addbookmark').addEventListener('submit', addBookmark);
    // Get the event page
    chrome.runtime.getBackgroundPage(function(eventPage) {
        // Call the getPageInfo function in the event page, passing in 
        // our onPageDetailsReceived function as the callback. This injects 
        // content.js into the current tab's HTML
        eventPage.getPageDetails(onPageDetailsReceived);
    });
});
