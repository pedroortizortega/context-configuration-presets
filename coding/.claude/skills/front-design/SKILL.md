---
name: front-design
description: Guidelines for designing user-facing visuals (web pages, buttons, icons, images, app screens, commercial presentations) under Occam's razor. Use it when deciding layout, components, styles and assets, or when reviewing a UI for usability, accessibility and weight.
---

# Principle

Occam's razor: the best design is the one with the fewest components, pages and assets that still lets the user complete the goal. Every element must justify itself by a user need stated in the spec. If it cannot, remove it.

# Structure

- One page per user goal. Add a page only when a goal cannot be reached from an existing one without clutter.
- One primary action per screen; secondary actions must look visibly weaker.
- Reuse a component before creating a new one. Create a new one only when a third use appears.
- Design mobile first, then widen. Use relative units and fluid layouts instead of fixed sizes.

# Visual system

- Define tokens once (color, spacing, type scale, radius) and reference them everywhere; no ad hoc values.
- Maximum two font families and a modular type scale.
- Palette: one brand color, one accent, neutral greys, plus semantic colors (success, warning, error).
- Contrast must meet WCAG AA (4.5:1 for body text, 3:1 for large text and UI boundaries). Never use color as the only signal.
- Interactive targets are at least 44x44 px, with visible focus, hover and disabled states.

# Assets

- Prefer, in order: CSS, inline SVG, system fonts, then raster images.
- Icons and logos are SVG with `viewBox`, no hardcoded size, and `currentColor` when themeable.
- Raster images need explicit width and height, a modern format (WebP/AVIF), lazy loading below the fold and a text alternative (`alt`).
- Audio and video are optional and never autoplay with sound; provide captions or a transcript.
- You can author SVG, CSS and HTML directly. Photos, video and audio cannot be generated with your tools: write an asset brief (purpose, dimensions, format, tone, source suggestion) and report it as an open question.

# Commercial presentations

- One message per slide or section, in this order: problem, product, proof, call to action.
- Show the product benefit before its features. Keep text short and legible from a distance.

# Review checklist

1. Can a new user find the primary action in under five seconds?
2. Can any component, page or asset be removed without losing a user goal?
3. Does it pass the contrast, keyboard and focus checks?
4. Is the visual weight justified (no unused fonts, images or scripts)?
