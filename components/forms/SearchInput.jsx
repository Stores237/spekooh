import React from 'react';
export function SearchInput({placeholder,value,onChange,icon}) {
  return React.createElement('div',{style:{display:'flex',alignItems:'center',gap:10,background:'var(--surface-card)',border:'1px solid var(--border-subtle)',borderRadius:'var(--radius-pill)',padding:'12px 18px'}},
    icon||React.createElement('svg',{width:16,height:16,viewBox:'0 0 24 24',fill:'none',stroke:'var(--text-tertiary)',strokeWidth:2},React.createElement('circle',{cx:11,cy:11,r:7}),React.createElement('line',{x1:21,y1:21,x2:16.65,y2:16.65})),
    React.createElement('input',{placeholder,value,onChange:e=>onChange&&onChange(e.target.value),style:{border:'none',outline:'none',flex:1,fontFamily:'var(--font-sans)',fontSize:14,color:'var(--text-primary)',background:'transparent'}})
  );
}
