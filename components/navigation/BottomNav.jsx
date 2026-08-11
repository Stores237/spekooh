import React from 'react';
export function BottomNav({items,active,onChange}) {
  return React.createElement('div',{style:{display:'flex',alignItems:'center',justifyContent:'space-between',background:'#fff',borderTop:'1px solid var(--border-subtle)',padding:'10px 18px 14px'}},
    items.map((it,i)=>{
      const isActive=i===active;
      const isCenter=it.center;
      if(isCenter){
        return React.createElement('button',{key:i,onClick:()=>onChange(i),style:{width:52,height:52,borderRadius:'var(--radius-lg)',background:'var(--gradient-bot)',border:'none',display:'flex',alignItems:'center',justifyContent:'center',boxShadow:'var(--shadow-button)',cursor:'pointer',marginTop:-24}},it.icon);
      }
      return React.createElement('button',{key:i,onClick:()=>onChange(i),style:{display:'flex',flexDirection:'column',alignItems:'center',gap:3,background:'none',border:'none',cursor:'pointer',color:isActive?'var(--blue-600)':'var(--text-tertiary)',fontSize:11,fontWeight:600,fontFamily:'var(--font-sans)'}},it.icon,it.label);
    })
  );
}
