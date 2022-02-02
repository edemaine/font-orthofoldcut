#!/usr/bin/coffee
# Based on https://github.com/edemaine/font-impossible/blob/main/make.coffee
fs = require 'fs'
path = require 'path'
stringify = require 'json-stringify-pretty-compact'
#stringify = JSON.stringify

font = {}

out = ['''
  <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  <svg xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" version="1.1">

''']
defs = []
gradientDark = {}
nextId = 0

root = 'svg'
subdirs = ['']
for subdir in subdirs
  dir = path.join root, subdir
  files = fs.readdirSync dir
  for file in files when not file.startsWith '.'
    continue if file in ['font.svg', 'README.md']
    match = /^(.).svg$/.exec file
    unless match?
      console.error "'#{file}' failed to parse"
      continue
    letter = match[1]
    fullFile = path.join dir, file
    #console.log letter, fullFile

    width = height = null
    id = "#{letter}"
    idMap = {}
    svg = fs.readFileSync fullFile, encoding: 'utf8'
    .replace /<svg[^<>]*>/, (match) ->
      width = /width="([^"]*?)mm"/.exec match
      height = /height="([^"]*?)mm"/.exec match
      viewbox = /viewBox="([^"]*)"/.exec match
      unless width? and height? and viewbox?
        console.error "Missing stuff in #{match}"
      coords = /^([.\d]+)\s+([.\d]+)\s+([.\d]+)\s+([.\d]+)$/.exec viewbox[1]
      unless coords?
        console.error "Unparsable viewbox #{coords} in #{fullFile}"
      unless coords[1] == coords[2] == "0"
        console.error "Weird viewbox #{coords} in #{fullFile}"
      unless width? and height? and viewbox?
        console.error "Missing stuff in #{match}"
      unless width[1][...-1] == coords[3][...-1] and height[1][...-1] == coords[4][...-1]
        console.error "Invalid width/height #{width[1]}/#{height[1]} vs. viewbox #{coords[3]}/#{coords[4]} in #{match}"
      width = width[1]
      height = height[1]
      """<symbol id="#{id}" width="#{width}" height="#{height}">"""
    .replace /<\/svg>/, '</symbol>'
    out.push svg

    font[letter] =
      width: parseFloat width
      height: parseFloat height
      id: id
      filename: fullFile.replace /\\/g, '/'

out.push '</svg>\n'
fs.writeFileSync 'font.svg', out.join '\n'
fs.writeFileSync 'font-inline.svg', out[1...-1].join '\n'
fs.writeFileSync 'font.js', "window.font = #{stringify font};"

console.log "Wrote font.svg, font-inline.svg, and font.js with #{(x for x of font).length} symbols"
