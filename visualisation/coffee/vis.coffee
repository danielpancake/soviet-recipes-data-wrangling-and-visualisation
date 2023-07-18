root = exports ? this

# Based on https://projects.flowingdata.com/tut/interactive_network_demo/
Network = () ->
  width = 960
  height = 800

  node_charge = -200
  link_distance = 150

  unfiltered_data = []
  current_nodes = []
  current_links = []

  nodesG = null
  node = null

  linksG = null
  link = null

  force = d3.layout.force()

  # Initializes visualization and starts force layout
  network = (el, data) ->
    unfiltered_data = setupData data

    vis = el.append("svg")
      .attr("width", width)
      .attr("height", height)

    linksG = vis.append("g").attr("id", "links")
    nodesG = vis.append("g").attr("id", "nodes")

    force.size([width, height])

    force.on("tick", handleTick)
      .charge(node_charge)
      .linkDistance(link_distance)

    update()

  #
  update = () ->
    current_nodes = unfiltered_data.nodes #filterNodes(allData.nodes)
    current_links = unfiltered_data.links #filterLinks(allData.links, current_nodes)

    force.nodes(current_nodes)
    updateNodes()
    
    force.links(current_links)
    updateLinks()

    force.start()

  #
  updateNodes = () ->
    node = nodesG.selectAll("circle.node")
      .data(current_nodes, (d) -> d.id)

    node.enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", (d) -> d.radius)
      # .style("fill", (d) -> nodeColors(d.artist))
      # .style("stroke", (d) -> strokeFor(d))
      .style("stroke-width", 1.0)

    # node.on("mouseover", showDetails)
    #   .on("mouseout", hideDetails)

    node.exit().remove()

  #
  updateLinks = () ->
    link = linksG.selectAll("line.link")
      .data(current_links, (d) -> "#{d.source.id}_#{d.target.id}")

    link.enter().append("line")
      .attr("class", "link")
      .attr("stroke", "#ddd")
      .attr("stroke-opacity", 0.8)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    link.exit().remove()

  # 
  handleTick = (e) ->
    node
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)

    link
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

  #
  setupData = (data) ->
    data.nodes.forEach (n) ->
      n.x = Math.floor(Math.random() * width)
      n.y = Math.floor(Math.random() * height)

      n.radius = if n.is_recipe then 10 else 5

    nodesMap  = mapNodes(data.nodes)

    data.links.forEach (l) ->
      l.source = nodesMap.get(l.source)
      l.target = nodesMap.get(l.target)

    data

  #
  mapNodes = (nodes) ->
    nodesMap = d3.map()
    nodes.forEach (n) ->
      nodesMap.set(n.id, n)
    nodesMap

  #
  network.updateData = (data) ->
    unfiltered_data = setupData(data)
    link.remove()
    node.remove()
    update()

  return network


$ ->
  network = Network()

  $subcategory_select = $("#subcategory_select")

  # Load json index file
  d3.json "data/network/index.json", (error, json) ->
    # Add subcategory selection groups
    for k, v of json
      $category = $("<optgroup label='#{k}'></optgroup>")

      for subcategory in v
        $subcategory = $("<option value='#{k}/#{subcategory}.json'>#{subcategory}</option>")
        $category.append($subcategory)

      $subcategory_select.append($category)

    # Finish with loading first subcategory
    d3.json "data/network/#{$subcategory_select.val()}", (error, json) ->
      network(d3.select("#network"), json)

  # On subcategory selection change
  $subcategory_select.on "change", (e) ->
    # console.log $(this).val()
    d3.json "data/network/#{$(this).val()}", (error, json) ->
      network.updateData(json)
