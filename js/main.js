var example = [
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

  $('#body').val(example);
  $('#output').html(markdown.toHTML(example));
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



window.addEventListener('load', function (evt) {
  // Cache a reference to the status display SPAN
  statusDisplay = document.getElementById('status-display');
  // Handle the bookmark form submit event with our addBookmark function
  document.getElementById('addRemark').addEventListener('submit', addRemark);
  // Get the event page


  const realFileBtn = document.getElementById("real-file")
  const customBtn = document.getElementById("custom-button")
  const customTxt = document.getElementById("custom-text")

  customBtn.addEventListener("click", function () {
    realFileBtn.click();
  });

  realFileBtn.addEventListener("change", function () {
    if (realFileBtn.value) {
      customTxt.innerHTML = realFileBtn.value.match(/[\/\\]([\w\d\s\.\-\(\)]+)$/)[1];
    }
    else {
      customTxt.innerHTML = "No file chosen, yet."
    }
  })

});

