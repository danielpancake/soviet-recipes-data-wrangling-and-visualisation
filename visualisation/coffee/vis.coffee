root = exports ? this

capitalise = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

# Based on https://projects.flowingdata.com/tut/interactive_network_demo/
Network = () ->
  width = 960
  height = 800

  recipe_color = "#FF0000"
  recipe_stroke_color = "#000000"
  recipe_radius = 15

  ingredient_color = "#0000FF"
  ingredient_stroke_color = "#000000"
  ingredient_radius = 8

  node_charge = -300
  link_distance = 150

  unfiltered_data = []
  current_nodes = []
  current_links = []

  nodesG = null
  node = null

  linksG = null
  link = null

  tooltip = Tooltip("vis-tooltip", 230)
  index_links = {}

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

    force
      .charge(node_charge)
      .linkDistance(link_distance)
      .on("tick", handleTick)

    update()

  #
  setupData = (data) ->
    data.nodes.forEach (n) ->
      n.x = Math.floor(Math.random() * width)
      n.y = Math.floor(Math.random() * height)

      [ n.radius, n.color, n.stroke_color ] =
        if n.is_recipe
        then [ recipe_radius, recipe_color, recipe_stroke_color ]
        else [ ingredient_radius, ingredient_color, ingredient_stroke_color ]

    nodesMap  = mapNodes(data.nodes)

    data.links.forEach (l) ->
      l.source = nodesMap.get(l.source)
      l.target = nodesMap.get(l.target)

      index_links["#{l.source.id},#{l.target.id}"] = yes

    data

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

    node
      .enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", (d) -> d.radius)
      .style("fill", (d) -> d.color)
      .style("stroke", (d) -> d.stroke_color)
      .style("stroke-width", 1.0)
      .style("transition", "opacity 0.2s ease-in-out")

    node
      .on("mouseover", showDetails)
      .on("mouseout", hideDetails)

    node.exit().remove()

  #
  updateLinks = () ->
    link = linksG.selectAll("line.link")
      .data(current_links, (d) -> "#{d.source.id}_#{d.target.id}")

    link
      .enter().append("line")
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
  showDetails = (d, i) ->
    content = "<p class='main'>#{capitalise d.name}</span></p>"
    content += "<hr class='tooltip-hr'>"

    if d.is_recipe
      uses = ""

      # Gather all ingredients used in recipe
      for l in current_links
        if l.source == d
          uses += "<p class='main'>#{l.target.name}</span></p>"

      content += "<p class='main'>Ингредиенты:</span></p><br />"
      content += uses
    else
      used_in = ""

      # Gather all neighbouring recipes
      for l in current_links
        if l.source == d
          used_in += "<p class='main'>#{l.target.name}</span></p>"
        else if l.target == d
          used_in += "<p class='main'>#{l.source.name}</span></p>"

      content += "<p class='main'>Используется в:</span></p><br />"
      content += used_in

    tooltip.showTooltip(content,d3.event)

    if link
      link
        .attr("stroke", (l) ->
          if l.source == d or l.target == d
          then "#555"
          else "#ddd"
        )
        .attr("stroke-opacity", (l) ->
          if l.source == d or l.target == d
          then 1.0
          else 0.5
        )

    node
      .style("opacity", (n) ->
        if neighboring(d, n)
        then 1.0
        else 0.2
      )
      .style("stroke", (n) ->
        if neighboring(d, n)
        then "#555"
        else d.stroke_color
      )
      .style("stroke-width", (n) ->
        if neighboring(d, n)
        then 2.0
        else 1.0
      )

    d3
      .select(this)
      .style("stroke", "black")
      .style("stroke-width", 2.0)

  #
  hideDetails = (d, i) ->
    tooltip.hideTooltip()

    if link
      link
        .attr("stroke", "#ddd")
        .attr("stroke-opacity", 0.8)

    node
      .style("opacity", 1.0)
      .style("stroke", d.stroke_color)
      .style("stroke-width", 1.0)
  
  #
  neighboring = (a, b) ->
    index_links["#{a.id},#{b.id}"] or index_links["#{b.id},#{a.id}"] or a.id == b.id

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
