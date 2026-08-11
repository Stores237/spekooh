Bottom tab bar. Center item ("Kawlo Bot" / AI) is visually elevated — a larger blue-gradient rounded square that pokes above the bar, distinct from the flat icon+label tabs either side.

```jsx
<BottomNav items={[
  {icon:<Home/>,label:'Home'},
  {icon:<FileText/>,label:'Papers'},
  {icon:<Sparkle/>,center:true},
  {icon:<MessageCircle/>,label:'Forum'},
  {icon:<Zap/>,label:'Quizzes'}
]} active={0} onChange={setActive}/>
```

Active tab turns blue-600; inactive tabs are text-tertiary gray. No badge/counter dots seen in source material.
