
$(function () {
  var currentMode = 'edit';
  var body = $('#body');
  var header = $('#header');
  var headerHeight = header.outerHeight();
  var titleHeight = $('#header h1').outerHeight();
  var fixedTop = -titleHeight;
  var scrollTops = {
    'edit': 0,
    'preview': 0
  };

  var isEdited = false;

  $('#body').val("");
  $('#output').html("");
  $('#body').bind('keyup', function () {
    isEdited = true;
    $('#output').html(markdown.toHTML($('#body').val()));
  });


  //reference
  $("table#reference tr td:odd").each(function (index, element) {
    var self = $(element);
    if (self.html() === "") {
      self.html(markdown.toHTML(self.siblings().html()));
    }
  });

  $("textarea").keyup(function (e) {
    while ($(this).outerHeight() < this.scrollHeight + parseFloat($(this).css("borderTopWidth")) + parseFloat($(this).css("borderBottomWidth"))) {
      $(this).height($(this).height() + 1);
    };
  });

  //leave
  $(window).bind('beforeunload', function () {
    if (isEdited) {
      return 'Are you sure you want to leave? Your changes will be lost.';
    }
  });
});

chrome.runtime.onMessage.addListener(function (request, sender) {
  if (request.action == "getSource") {

    var pageSource = request.source

    var re = /\s*TK:(.*)<\/span>\s*/g;
    var m;

    var availableComments = []

    do {
      m = re.exec(pageSource);
      if (m) {
        availableComments.push(m[1]);
      }
    } while (m);

    availableComments.forEach(function (commentId) {
      var settings = {
        "crossDomain": true,
        "url": "https://trblknwldge.herokuapp.com/comments/" + commentId,
        "method": "GET",
        "headers": {
          "Content-Type": "application/json",
          "Cache-Control": "no-cache",
        },
      }

      $.ajax(settings).done(function (response) {

        document.getElementById('existing-comments-title').hidden = false;
        $('#existing-comments').append(
          '<li><div>' + markdown.toHTML(response.comment) + '</div></li>'
        )
      });
    })
  }
});


window.addEventListener('load', function (evt) {
  // Cache a reference to the status display SPAN
  statusDisplay = document.getElementById('status-display');
  // Handle the bookmark form submit event with our addBookmark function
  document.getElementById('addRemark').addEventListener('submit', addRemark);
  // Get the event page

  document.getElementById("clear").addEventListener("click", function (e) {
    e.preventDefault();
    document.getElementById("body").value = "";
  })

  document.getElementById("save").addEventListener("click", function (e) {

    e.preventDefault();

    data = {
      "Comment": document.getElementById('body').value
    }

    var settings = {
      "crossDomain": true,
      "url": "https://trblknwldge.herokuapp.com/comments",
      "method": "POST",
      "headers": {
        "Content-Type": "application/json",
        "Cache-Control": "no-cache",
      },
      "data": JSON.stringify(data)
    }

    $.ajax(settings).done(function (response) {
      console.log(response);
      // TODO: make this comment style work for different code languages
      document.getElementById("comment-link").value = 'TK:' + response.id
      document.getElementById("comment-link").focus();
      document.getElementById("comment-link").select();
    });
  })


  var message = document.querySelector('#message');

  chrome.tabs.executeScript(null, {
    file: "js/getPagesSource.js"
  }, function () {
    // If you try and inject into an extensions page or the webstore/NTP you'll get an error
    if (chrome.runtime.lastError) {
      console.log('There was an error injecting script : \n' + chrome.runtime.lastError.message);
    }
  });



});

