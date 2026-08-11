function NotificationsScreen({onBack}) {
  const Ic = window.Ic;
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button onClick={onBack} style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="chevron-left"/></button>
        <div><div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Notifications</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>All caught up</div></div>
      </div>
      <div style={{marginTop:16,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',gap:12,alignItems:'flex-start'}}>
        <div style={{width:36,height:36,borderRadius:'var(--radius-chip)',background:'var(--gold-50)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}><Ic name="sparkles" size={16} style={{color:'var(--gold-700)'}}/></div>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:'var(--text-primary)'}}>Welcome to Spekooh 🎉</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>You've got 7 days free: all marking guides, unlimited AI assistant and downloads.</div>
          <div style={{fontSize:11,color:'var(--text-tertiary)',marginTop:4}}>12 min ago</div>
        </div>
      </div>
      <div style={{marginTop:10,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',gap:12,alignItems:'flex-start'}}>
        <div style={{width:36,height:36,borderRadius:'var(--radius-chip)',background:'var(--green-100)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}><Ic name="check" size={16} style={{color:'var(--green-600)'}}/></div>
        <div>
          <div style={{fontWeight:700,fontSize:13,color:'var(--text-primary)'}}>Physics paper published</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Your submission's marking guide is live — you earned 150 credits.</div>
          <div style={{fontSize:11,color:'var(--text-tertiary)',marginTop:4}}>1 day ago</div>
        </div>
      </div>
    </div>
  );
}
window.NotificationsScreen = NotificationsScreen;
