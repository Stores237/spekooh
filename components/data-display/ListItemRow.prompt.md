The single most repeated pattern in Spekooh — settings rows, help rows, subject rows, download rows. Rows are usually grouped inside one white card with thin dividers between them (not individually carded).

```jsx
<div style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'4px 16px'}}>
  <ListItemRow icon={<IconChip tint="blue" icon={<Ic name="globe"/>}/>} title="English" trailing={<Check/>} />
</div>
```

Pass `trailing` explicitly to override the default chevron (e.g. a checkmark for the selected language, a lock icon for gated features).
