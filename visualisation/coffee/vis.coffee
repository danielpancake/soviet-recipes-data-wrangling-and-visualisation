root = exports ? this

capitalise = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

# Based on https://projects.flowingdata.com/tut/interactive_network_demo/
Network = () ->
  width = 960
  height = 960

  # ==== STYLES ====
  recipe_color = "#ef553b"
  recipe_stroke_color = "#000000"
  recipe_radius = 15

  ingredient_color = "#636efa"
  ingredient_stroke_color = "#000000"
  ingredient_radius = 8

  link_color = "#dbd8ce"
  link_opacity = 1.0
  link_stroke_width = 0.5

  link_highlight_color = "#555"
  link_highlight_opacity = 1.0
  link_highlight_stroke_width = 3.0

  node_stroke_width = 1.0

  node_highlight_stroke_color = "#555"
  node_highlight_stroke_width = 2.0

  node_searched_fill_color = "#ffa15a"
  node_searched_stroke_color = "#555"
  node_searched_stroke_width = 5.0
  # ==== STYLES ====

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
      .style("stroke-width", node_stroke_width)
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
      .attr("stroke", link_color)
      .attr("stroke-opacity", link_opacity)
      .attr("stroke-width", link_stroke_width)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    link.exit().remove()

  #
  handleTick = (e) ->
    node
      .attr("cx", (d) -> boundHorizontally(d))
      .attr("cy", (d) -> boundVertically(d))

    link
      .attr("x1", (d) -> boundHorizontally(d.source))
      .attr("y1", (d) -> boundVertically(d.source))
      .attr("x2", (d) -> boundHorizontally(d.target))
      .attr("y2", (d) -> boundVertically(d.target))

  #
  boundHorizontally = (d) ->
    Math.max(d.radius, Math.min(width - d.radius, d.x))

  #
  boundVertically = (d) ->
    Math.max(d.radius, Math.min(height - d.radius, d.y))

  #
  generateTooltipContent = (d) ->
    content = "<h2>#{capitalise d.name}</h2>"
    content += "<hr class='tooltip-hr'>"

    if d.is_recipe
      uses = ""

      # Gather all ingredients used in recipe
      for l in current_links
        if l.source == d
          uses += "<p class='main'>#{l.target.name}</p>"

      content += "<h3>Ингредиенты:</h3><br />"
      content += uses
    else
      used_in = ""

      # Gather all neighbouring recipes
      for l in current_links
        used_in += "<p class='main'>#{
          if l.source == d
          then l.target.name
          else if l.target == d
          then l.source.name
          else ""
        }</p>"

      content += "<h3>Используется в:</h3><br />"
      content += used_in

    content

  #
  showDetails = (d, i) ->
    content = generateTooltipContent d
    tooltip.showTooltip(content, d3.event)

    if link
    then link
        .attr("stroke", (l) ->
          if l.source == d or l.target == d
          then link_highlight_color
          else link_color
        )
        .attr("stroke-opacity", (l) ->
          if l.source == d or l.target == d
          then link_highlight_opacity
          else link_opacity
        )
        .attr("stroke-width", (l) ->
          if l.source == d or l.target == d
          then link_highlight_stroke_width
          else 0
        )

    # Do not highlight nodes if search is active
    node.each (n) ->
      el = d3.select(this)
      el.style("opacity", (n) ->
        if neighboring(d, n)
        then 1.0
        else 0.2
      )

      if not n.searched
        el.style("stroke", (n) ->
          if neighboring(d, n)
          then node_highlight_stroke_color
          else d.stroke_color
        )
        .style("stroke-width", (n) ->
          if neighboring(d, n)
          then node_highlight_stroke_width
          else node_stroke_width
        )

  #
  hideDetails = (d, i) ->
    tooltip.hideTooltip()

    if link
    then link
        .attr("stroke", link_color)
        .attr("stroke-opacity", link_opacity)
        .attr("stroke-width", link_stroke_width)

    node.each (n) ->
      el = d3.select(this)
      el.style("opacity", 1.0)

      if not n.searched
        el.style("stroke", n.stroke_color)
          .style("stroke-width", node_stroke_width)

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

  #
  network.updateSearch = (search) ->
    regex = new RegExp(search.toLowerCase())

    node.each (d) ->
      el = d3.select(this)
      match = d.name.toLowerCase().search(regex)

      if search.length > 0 and match >= 0
        el.style("fill", node_searched_fill_color)
          .style("stroke", node_searched_stroke_color)
          .style("stroke-width", node_searched_stroke_width)

        d.searched = yes
      else
        el.style("fill", (d) -> d.color)
          .style("stroke", (d) -> d.stroke_color)
          .style("stroke-width", node_stroke_width)

        d.searched = no

  return network

$ ->
  network = Network()

  $subcategory_select = $("#subcategory-select")
  $search = $("#search")

  $category_stats = $("#category-stats")
  $per_category_stats = $("#per-category-stats")

  current_category = null

  updateCategoryStats = () ->
    selected_category = $subcategory_select.find("option:selected").parent().attr("label")

    # Show category stats
    if current_category == null or current_category != selected_category
      svg_path = "images/stats_per_category/#{selected_category}.svg"

      $per_category_stats.empty()
      $per_category_stats.append("<object type='image/svg+xml' data='#{svg_path}'></object>")

      current_category = selected_category

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
      updateCategoryStats()

  # On subcategory selection change
  $subcategory_select.on "change", (e) ->
    d3.json "data/network/#{$(this).val()}", (error, json) ->
      network.updateData(json)
      network.updateSearch($search.val())
      updateCategoryStats()

  # Update nodes on search
  $search.on "keyup", (e) ->
    network.updateSearch($(this).val())
