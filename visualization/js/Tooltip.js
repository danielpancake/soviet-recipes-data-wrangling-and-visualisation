// https://projects.flowingdata.com/tut/interactive_network_demo/
function Tooltip(tooltipId, width) {
  var tooltipId = tooltipId;
  $("body").append("<div class='tooltip' id='" + tooltipId + "'></div>");

  if (width) {
    $("#" + tooltipId).css("width", width);
  }

  hideTooltip();

  function showTooltip(content, event) {
    $("#" + tooltipId).html(content);
    $("#" + tooltipId).show();

    updatePosition(event);
  }

  function hideTooltip() {
    $("#" + tooltipId).hide();
  }

  function updatePosition(event) {
    var ttid = "#" + tooltipId;
    var xOffset = 20;
    var yOffset = 10;

    var toolTipW = $(ttid).width();
    var toolTipeH = $(ttid).height();
    var windowY = $(window).scrollTop();
    var windowX = $(window).scrollLeft();
    var curX = event.pageX;
    var curY = event.pageY;
    var ttleft =
      curX < $(window).width() / 2
        ? curX - toolTipW - xOffset * 2
        : Math.min(curX + xOffset, $(window).width() - toolTipW - xOffset * 2);
    if (ttleft < windowX + xOffset) {
      ttleft = windowX + xOffset;
    }

    var tttop =
      curY - windowY + yOffset * 2 + toolTipeH > $(window).height()
        ? curY - toolTipeH - yOffset * 2
        : curY + yOffset;
    if (tttop < windowY + yOffset) {
      tttop = curY + yOffset;
    }
    $(ttid)
      .css("top", tttop + "px")
      .css("left", ttleft + "px");
  }

  return {
    showTooltip: showTooltip,
    hideTooltip: hideTooltip,
    updatePosition: updatePosition,
  };
}
