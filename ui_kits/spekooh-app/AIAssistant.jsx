function AIAssistant() {
  const Ic = window.Ic;
  const [open,setOpen] = React.useState(false);
  const prompts = ['Explain a hard Physics topic','Give me 5 Maths practice questions','Summarize this paper’s marking guide'];
  return (
    <React.Fragment>
      <button onClick={()=>setOpen(true)} style={{position:'absolute',right:16,bottom:96,width:52,height:52,borderRadius:16,background:'var(--gradient-primary)',border:'none',boxShadow:'var(--shadow-button)',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer',zIndex:8}}>
        <Ic name="sparkles" size={22} style={{color:'#fff'}}/>
      </button>
      {open && (
        <div onClick={()=>setOpen(false)} style={{position:'absolute',inset:0,background:'rgba(36,26,8,0.45)',backdropFilter:'blur(2px)',display:'flex',alignItems:'flex-end',zIndex:12}}>
          <div onClick={e=>e.stopPropagation()} style={{background:'#fff',width:'100%',borderRadius:'26px 26px 0 0',padding:'10px 20px 24px',maxHeight:'70%',display:'flex',flexDirection:'column'}}>
            <div style={{width:40,height:4,borderRadius:2,background:'var(--border-subtle)',margin:'0 auto 14px'}}/>
            <div style={{display:'flex',alignItems:'center',gap:10}}>
              <div style={{width:36,height:36,borderRadius:12,background:'var(--gradient-primary)',display:'flex',alignItems:'center',justifyContent:'center'}}><Ic name="sparkles" size={16} style={{color:'#fff'}}/></div>
              <div><div style={{fontWeight:800,fontSize:15,color:'var(--text-primary)'}}>Spekooh Assistant</div><div style={{fontSize:11,color:'var(--text-secondary)'}}>Explains topics using real past papers</div></div>
            </div>
            <div style={{flex:1,overflowY:'auto',marginTop:14,display:'flex',flexDirection:'column',gap:8}}>
              {prompts.map(p=>(
                <button key={p} style={{textAlign:'left',background:'var(--surface-sunken)',border:'1px solid var(--border-subtle)',borderRadius:'var(--radius-md)',padding:'12px 14px',fontSize:13,color:'var(--text-primary)',cursor:'pointer'}}>{p}</button>
              ))}
            </div>
            <div style={{display:'flex',gap:8,marginTop:12,alignItems:'center',background:'var(--surface-sunken)',border:'1px solid var(--border-subtle)',borderRadius:999,padding:'10px 14px'}}>
              <input placeholder="Ask about a topic or paper..." style={{border:'none',outline:'none',flex:1,fontSize:13,background:'transparent'}}/>
              <Ic name="send" size={16} style={{color:'var(--gold-700)'}}/>
            </div>
          </div>
        </div>
      )}
    </React.Fragment>
  );
}
window.AIAssistant = AIAssistant;
