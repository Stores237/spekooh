function StatusBar() {
  return React.createElement('div',{style:{display:'flex',justifyContent:'space-between',padding:'10px 20px 4px',fontSize:13,fontWeight:700,color:'var(--navy-900)'}},
    React.createElement('span',null,'16:32'),
    React.createElement('span',null,'••• LTE 100%')
  );
}
window.StatusBar = StatusBar;
