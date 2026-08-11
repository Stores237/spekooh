Horizontal scrolling row of pill tabs — used for category filters ("All · Sciences · Arts · Commercial") and year filters ("2026 · 2025 · 2023…").

```jsx
<SegmentedTabs options={['All','Sciences','Arts','Commercial']} active={0} onChange={setTab}/>
```

Active pill is solid navy with white text; inactive pills are white cards with a soft shadow, gray text.
