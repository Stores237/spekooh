import React from 'react';
export function SegmentedTabs({options,active,onChange}) {
  return React.createElement('div',{style:{display:'flex',gap:8,overflowX:'auto'}},
    options.map((opt,i)=>React.createElement('button',{key:opt,onClick:()=>onChange(i),style:{flexShrink:0,padding:'8px 16px',borderRadius:'var(--radius-pill)',border:'none',cursor:'pointer',fontFamily:'var(--font-sans)',fontSize:13,fontWeight:600,background:i===active?'var(--navy-900)':'var(--surface-card)',color:i===active?'#fff':'var(--text-secondary)',boxShadow:i===active?'none':'var(--shadow-card)'}},opt))
  );
}
