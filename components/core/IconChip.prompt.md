Small tinted rounded-square that wraps a glyph — precedes almost every list-row title in Spekooh (subjects, settings rows, help rows).

```jsx
<IconChip tint="green" icon={<Ic name="leaf"/>} />
```
(`Ic` builds an inline `<svg>` from `lucide.icons[PascalName]` node data each render — safe inside React; do not use `data-lucide` + `lucide.createIcons()` together with React state, it mutates DOM React owns and crashes on re-render/unmount)

Tints map to subject/semantic color: blue = default/math/science, green = biology/success, purple = chemistry, amber = rewards/plus, red = warnings. Always paired with a Lucide icon (see Iconography card) — never emoji.
