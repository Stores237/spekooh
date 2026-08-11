function SettingsScreen({onLogin}) {
  const { IconChip, Toggle } = window.KawloSpekoohDesignSystem_10ffa8;
  const [lang,setLang] = React.useState('en');
  const Ic = window.Ic;
  const Row = ({icon,title,sub,trailing}) => (
    <div style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0'}}>
      <IconChip tint="blue" icon={<Ic name={icon}/>} size={38}/>
      <div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div>{sub&&<div style={{fontSize:12,color:'var(--text-secondary)'}}>{sub}</div>}</div>
      {trailing||<Ic name="chevron-right"/>}
    </div>
  );
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="chevron-left"/></button>
        <div><div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Settings</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Account & app</div></div>
      </div>
      <div style={{marginTop:16,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12}}>
        <div style={{width:44,height:44,borderRadius:'var(--radius-chip)',background:'var(--gold-200)',display:'flex',alignItems:'center',justifyContent:'center'}}><Ic name="star" size={20}/></div>
        <div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Spekooh Pro</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Unlimited paper views · no ads</div></div>
        <Ic name="chevron-right"/>
      </div>
      <div style={{marginTop:20,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.06em'}}>Language</div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'0 16px'}}>
        <div onClick={()=>setLang('en')} style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0',cursor:'pointer'}}><Ic name="globe"/><div style={{flex:1,fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>English</div>{lang==='en'&&<Ic name="check"/>}</div>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <div onClick={()=>setLang('fr')} style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0',cursor:'pointer'}}><Ic name="globe"/><div style={{flex:1,fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Français</div>{lang==='fr'&&<Ic name="check"/>}</div>
      </div>
      <div style={{marginTop:20,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.06em'}}>Help</div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'0 16px'}}>
        <Row icon="phone" title="Help & support" sub="Chat with a real person"/>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <Row icon="message-circle" title="Join our WhatsApp group" sub="Tips & updates"/>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <Row icon="user" title="Contact us" sub="Questions or feedback"/>
      </div>
      <div style={{marginTop:20,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.06em'}}>About</div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'0 16px'}}>
        <Row icon="globe" title="Visit our website" sub="spekooh.app"/>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <Row icon="lock" title="Privacy policy"/>
      </div>
      <button style={{width:'100%',marginTop:24,background:'var(--gradient-primary)',color:'#fff',fontWeight:700,border:'none',borderRadius:999,padding:'15px',fontSize:15,boxShadow:'var(--shadow-button)',cursor:'pointer'}} onClick={onLogin}>Log in</button>
    </div>
  );
}
window.SettingsScreen = SettingsScreen;
