var fill = d3.scaleOrdinal(d3.schemeCategory20);
var data = [
  {text: "Hello"},
  {text: "happy"},
  {text: "beautiful"},
  {text: "rainbow"},
  {text: "unicorn"},
  {text: "glitter"},
  {text: "happy"},
  {text: "pie"}];

  var layout = d3.layout.cloud()
  .size([400, 300])
  .words(data)
  .on("end", draw);

  layout.start();

  function draw(words) {
    d3.select("#demo1")
        .append("g")
        .attr("transform", "translate(" + layout.size()[0] / 2 + "," + layout.size()[1] / 2 + ")")
        .selectAll("text")
        .data(words)
        .enter()
        .append("text")
        .text((d) => d.text)
        .style("font-size", (d) => d.size + "px")
        .style("font-family", (d) => d.font)
        .style("fill", (d, i) => fill(i))
        .attr("text-anchor", "middle")
        .attr("transform", (d) => "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")");
}