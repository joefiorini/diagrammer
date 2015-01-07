module Partials.Help where

import Markdown

view = Markdown.toHtml """

# Keyboard Shortcuts

<dl class='cheatsheet'>
  <dt>
    `a`
    <h3>Add a box</h3>
  </dt>
  <dd>
    Adds a new box to the top-left corner of the board and marks it selected so you can start working with it immediately.
  </dd>
  <dt>
    `d`
    <h3>Delete a box</h3>
  </dt>
  <dd>
    Removes the selected box from the board.
  </dd>
  <dt>
    `c`
    <h3>Connect boxes</h3>
  </dt>
  <dd>
    Select two boxes (click one, then click another while holding down shift) and press c. This draws a line between the boxes, with an arrowhead pointing at the first box selected.
  </dd>
  <dt>
    `h/j/k/l`
    <h3>Nudge selected box</h3>
  </dt>
  <dd>
    Move the selected boxes left, down, up or right on the board in small increments.
  </dd>
  <dt>
    `shift+h/j/k/l`
    <h3>Push selected box</h3>
  </dt>
  <dd>
    Move the selected boxes left, down, up or right on the board in larger incremements.
  </dd>
  <dt>
    `alt+shift+h/j/k/l`
    <h3>Jump selected box</h3>
  </dt>
  <dd>
    Move the selected boxes left, down, up or right on the board in ginormous incremements.
  </dd>
  <dt>
    `+`
    <h3>Increase box size</h3>
  </dt>
  <dd>
    Make the selected boxes a little bigger.
  </dd>
  <dt>
    `-`
    <h3>Decrease box size</h3>
  </dt>
  <dd>
    Make the selected boxes a little smaller.
  </dd>
  <dt>
    `alt++`
    <h3>Increase box width</h3>
  </dt>
  <dd>
    Make the selected boxes a little wider.
  </dd>
  <dt>
    `alt+-`
    <h3>Decrease box width</h3>
  </dt>
  <dd>
    Make the selected boxes a little thinner.
  </dd>
  <dt>
    `ctrl++`
    <h3>Increase box height</h3>
  </dt>
  <dd>
    Make the selected boxes a little taller.
  </dd>
  <dt>
    `ctrl+-`
    <h3>Decrease box height</h3>
  </dt>
  <dd>
    Make the selected boxes a little shorter.
  </dd>
  <dt>
    `1/2/3/4`
    <h3>Dark box styles</h3>
  </dt>
  <dd>
    Changes the colors of the selected boxes to a dark style (this affects background, text and border color of each selected box).
  </dd>
  <dt>
    `shift+1/2/3/4`
    <h3>Light box styles</h3>
  </dt>
  <dd>
    Changes the colors of the selected boxes to a light style (colors correspond to the dark styles of the same number).
  </dd>
  <dt>
    `0/shift+0`
    <h3>Black/White box styles</h3>
  </dt>
  <dd>
    Switches between black or white box styles.
  </dd>
</dl>

"""
