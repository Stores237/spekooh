function Phone({children}) {
  return React.createElement('div',{style:{width:390,height:800,background:'var(--surface-bg)',borderRadius:36,overflow:'hidden',position:'relative',display:'flex',flexDirection:'column',fontFamily:'var(--font-sans)',boxShadow:'0 20px 60px rgba(24,36,81,0.25)',border:'8px solid #14162A'}},children);
}
window.Phone = Phone;
