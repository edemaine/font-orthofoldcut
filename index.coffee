letterURL = (id) ->
  #"font.svg##{id}"
  "##{id}"

drawLetter = (char, container, state) ->
  group = container.group()
  {width, height, id} = window.font[char]
  use = group.use().attr 'href', letterURL id
  element: use
  #x: 0
  #y: 0
  width: width
  height: height

## Origami Simulator
simulator = null
ready = false
onReady = null
checkReady = ->
  if ready
    onReady?()
    onReady = null
window.addEventListener 'message', (e) ->
  if e.data and e.data.from == 'OrigamiSimulator' and e.data.status == 'ready'
    ready = true
    checkReady()
simulate = (svg) ->
  if simulator? and not simulator.closed
    simulator.focus()
  else
    ready = false
    #simulator = window.open 'OrigamiSimulator/?model=', 'simulator'
    simulator = window.open 'https://origamisimulator.org/?model=', 'simulator'
  onReady = -> simulator.postMessage
    op: 'importSVG'
    svg: svg
    vertTol: 0.1
    filename: 'strip-simulate.svg'
  , '*'
  checkReady()

svgPrefixId = (svg, prefix = 'N') ->
  svg.replace /\b(id\s*=\s*")([^"]*")/gi, "$1#{prefix}$2"
  .replace /\b(xlink:href\s*=\s*"#)([^"]*")/gi, "$1#{prefix}$2"

colorMap =
  'e50000': 'f00'
  '66b2ff': '00f'
  '0b840b': 'f0f'
  '090': 'f0f'

cleanupSVG = (svg) -> svg
simulateSVG = (svg) ->
  explicit = SVG().addTo '#output'
  try
    explicit.svg svgPrefixId svg.svg(), ''
    ## Expand <use> into duplicate copies with translation
    explicit.find 'use'
    .each ->
      replacement = document.getElementById @attr('xlink:href').replace /^#/, ''
      replacement = null if replacement?.id.startsWith 'f' # remove folded
      unless replacement?  # reference to non-existing object
        return @remove()
      replacement = SVG replacement
      viewbox = replacement.attr('viewBox') ? ''
      viewbox = viewbox.split /\s+/
      viewbox = (parseFloat n for n in viewbox)
      replacement = svgPrefixId replacement.svg()
      replacement = replacement.replace /<symbol\b/, '<g'
      replacement = explicit.group().svg replacement
      ## First transform according to `transform`, then translate by `x`, `y`
      if @attr 'transform'
        replacement.attr 'transform', @attr 'transform'
      else
        replacement.translate \
          (@attr('x') or 0) - (viewbox[0] or 0),
          (@attr('y') or 0) - (viewbox[1] or 0)
      replacement.attr 'viewBox', null
      replacement.attr 'id', null
      #console.log 'replaced', @attr('xlink:href'), 'with', replacement.svg()
      @replace replacement
    ## Delete now-useless <symbol>s
    explicit.find 'symbol'
    .each -> @remove()
    ## Convert colors to Origami Simulator colors
    for before, after of colorMap
      explicit.find "[stroke='##{before}']"
      .each -> @attr 'stroke', "##{after}"
    explicit.svg()
    ## Remove surrounding <svg>...</svg> from explicit SVG container
    .replace /^<svg[^<>]*>/, ''
    .replace /<\/svg>$/, ''
  finally
    explicit.remove()

window?.onload = ->
  app = new FontWebappSVG
    root: '#output'
    rootSVG: '#svg'
    margin: 2
    charKern: 4
    lineKern: 4
    spaceWidth: 12
    shouldRender: (changed, state) ->
      changed.text
    renderChar: (char, state, group) ->
      char = char.toUpperCase()
      return unless char of window.font
      drawLetter char, group, state

  document.getElementById('links').innerHTML = (
    for char, letter of font
      """<a href="#{letter.filename}">#{char}</a>"""
  ).join ', '

  document.getElementById('downloadSVG')?.addEventListener 'click', ->
    app.downloadSVG 'impossible.svg', cleanupSVG app.svg.svg()
  document.getElementById('downloadSim')?.addEventListener 'click', ->
    app.downloadSVG 'impossible-simulate.svg', simulateSVG app.svg
  document.getElementById('simulate')?.addEventListener 'click', ->
    simulate simulateSVG app.svg
