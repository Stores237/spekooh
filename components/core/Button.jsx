import React from 'react';
export function Button({variant='primary',size='md',children,disabled,onClick,style}) {
  const sizes={sm:{padding:'8px 16px',fontSize:13},md:{padding:'13px 20px',fontSize:15},lg:{padding:'16px 24px',fontSize:16}};
  const base={fontFamily:'var(--font-sans)',fontWeight:700,borderRadius:'var(--radius-pill)',border:'none',cursor:disabled?'default':'pointer',opacity:disabled?0.5:1,display:'inline-flex',alignItems:'center',justifyContent:'center',gap:8,transition:'transform .12s ease, opacity .12s ease',...sizes[size],...style};
  const variants={
    primary:{background:'var(--gradient-primary)',color:'#fff',boxShadow:'var(--shadow-button)'},
    secondary:{background:'var(--blue-100)',color:'var(--blue-600)'},
    outline:{background:'transparent',color:'var(--blue-600)',border:'1.5px solid var(--blue-500)'},
    ghost:{background:'transparent',color:'var(--blue-600)',padding:'4px 0',boxShadow:'none'},
    dark:{background:'var(--navy-900)',color:'#fff'}
  };
  return React.createElement('button',{
    disabled,onClick,
    style:{...base,...variants[variant]},
    onMouseDown:e=>{e.currentTarget.style.transform='scale(0.97)'},
    onMouseUp:e=>{e.currentTarget.style.transform='scale(1)'},
    onMouseLeave:e=>{e.currentTarget.style.transform='scale(1)'}
  },children);
}
