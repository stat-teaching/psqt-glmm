#import "@preview/polylux:0.4.0": *
#import "@preview/fontawesome:0.5.0": *

// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false,
    fill: background_color,
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"),
    width: 100%,
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt,
          width: 100%,
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

// Shortcuts for callout types
#let alert(title, body, fill: red) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("triangle-exclamation"),
  icon_color: white
)

#let example(title, body, fill: rgb("e5f5ff")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("lightbulb"),
  icon_color: blue
)

#let tip(title, body, fill: rgb("d2f4d2")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("circle-check"),
  icon_color: green
)

#let reminder(title, body, fill: rgb("f5f5dc")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("sticky-note"),
  icon_color: black
)

#let info(title, body, fill: rgb("e0f0ff")) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("circle-info"),
  icon_color: blue
)

#let warning(title, body, fill: orange) = callout(
  title: title,
  body: body,
  background_color: fill,
  icon: fa-icon("triangle-exclamation"),
  icon_color: white
)

#let projector-block(title, body) = callout(
  title: title,
  body: body
)

#let focus-slide = slide
#let last-slide = slide

#let title-slide(title, subtitle, authors, date) = {
  slide[
    #if title != none {
      align(center)[
        #block(inset: 1em)[
          #text(weight: "bold", size: 3em)[
            #title
          ]
          #if subtitle != none {
            linebreak()
            text(subtitle, size: 2em, weight: "semibold")
          }
        ]
      ]
    }
    #set text(size: 1.25em)

    #if authors != none and authors != [] {
      let count = authors.len()
      let ncols = calc.min(count, 3)
      grid(
        columns: (1fr,) * ncols,
        row-gutter: 1.5em,
        ..authors.map(author => align(center)[
          #author.name \
          #author.affiliation
        ])
      )
    }

    #if date != none {
      align(center)[#block(inset: 1em)[
          #date
        ]
      ]
    }
  ]
}

#let toc-slide(toc_title) = {
  slide[
    #let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    #heading(toc_title)
    #set text(size: 2em)
    #align(horizon)[
      #toolbox.all-sections((sections, current) => {
        sections
        .map(s => if s == current { emph(s) } else { s })
        .join([ #linebreak() ])
      })
    ]
  ]
}

#let section-slide(name) = {
  slide[
    #align(horizon)[
      #text(size: 4em)[
        #strong(name)
      ]
      #toolbox.register-section(name)
    ]
  ]
}



#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 0.5in, y: 0.5in),
  paper: "presentation-16-9",
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  handout: false,
  background: none,
  theme: none,
  doc,
) = {

  show: it => {
    if theme != none {
      //import theme: *
      show: projector-theme
      it
    } else {
      it
    }
  }

  set page(
    paper: paper,
    margin: margin,
    numbering: none,
    footer: context align(center)[#toolbox.slide-number],
  )

  show: it => {
    if background != none {
      set page(background: image(background, width: 100%, height: 100%))
      it
    } else {
      it
    }
  }

  set par(
    justify: false,
    leading: linestretch * 0.65em
  )

  set text(
    lang: lang,
    region: region,
    size: fontsize,
  )
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      this
    }
  }

  set heading(numbering: sectionnumbering)
  show heading: set text(size: 1.5em)
  set text(size: 1.25em)

  if handout {
    enable-handout-mode(true)
  }

  if title != none or authors != none or date != none {
    title-slide(title, subtitle, authors, date)
  }

  if toc {
    toc-slide(toc_title)
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none,
)
#import "@preview/fontawesome:0.5.0": *

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)



#show: doc => article(
  title: [A presentation with Polylux via Quarto],
  subtitle: [PSQT - Quantitative Psychology],
  authors: (
    ( name: [Filippo Gambarota],
      affiliation: [University of Padova],
      email: [filippo.gambarota\@unipd.it] ),
    ),
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

#block[
```r
mtheme <- function(){
    ggplot2::theme_minimal(20)   
}

ggplot2::theme_set(mtheme())

knitr::opts_chunk$set(
    echo = TRUE,
    fig.align = "center",
    message = FALSE,
    warning = FALSE
)
```

]
#slide[
= Contenuti
Questo corso ha l'obiettivo di espandere i modelli lineari e generalizzati che avete già affrontato introducendo la distinzione tra #strong[effetti fissi] ed #strong[effetti random];. Questo ha diversi vantaggi, tra cui:

- gestire strutture dati complesse con dipendenza/correlazione tra osservazioni
- distinguere chiaramente diversi livelli di nidificazione (#emph[nesting];) tipici delle strutture dati multilivello
- includere predittori specifici per ogni livello

]
#slide[
= Terminologia
In generale, la terminologia in statistica può essere complessa e confondente. Potreste aver sentito:

#block[
#callout(
body: 
[
Variance component models, Random intercept and slope models. Random effects models, Random coefficient models, Varying coefficient models, Intercepts and/or slopes-as-outcomes models, Hierarchical linear models Multilevel models, Growth curve models, etc.

]
, 
title: 
[
None
]
, 
background_color: 
rgb("#e6e6e6")
, 
icon_color: 
rgb("#909090")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Tutti questi sono, più o meno, sinonimi o casi particolari della generica famiglia dei #strong[mixed-effects models];.

]




