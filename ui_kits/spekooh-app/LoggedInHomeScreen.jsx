function LoggedInHomeScreen({onOpenSettings,onOpenPaper,onOpenSubmit,onOpenNotifications,onOpenProfile,onOpenNotes,onOpenShop}) {
  const { Badge } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{background:'var(--ink-900)',margin:'-1px -18px 0',padding:'18px 18px 40px',borderRadius:'0 0 32px 32px'}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <div onClick={onOpenProfile} style={{display:'flex',alignItems:'center',gap:10,cursor:'pointer'}}>
            <div style={{width:38,height:38,borderRadius:'50%',background:'var(--gold-200)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,color:'var(--gold-700)'}}>K</div>
            <div><div style={{fontSize:12,color:'var(--text-on-dark-muted)'}}>Good morning</div><div style={{fontSize:15,fontWeight:800,color:'#fff'}}>Kkk</div></div>
          </div>
          <div style={{display:'flex',gap:8,alignItems:'center'}}>
            <div style={{display:'flex',background:'rgba(255,255,255,0.12)',borderRadius:999,padding:2}}>
              <span style={{padding:'5px 10px',borderRadius:999,fontSize:11,fontWeight:800,background:'#fff',color:'var(--ink-900)'}}>EN</span>
              <span style={{padding:'5px 10px',borderRadius:999,fontSize:11,fontWeight:800,color:'#fff'}}>FR</span>
            </div>
            <button onClick={onOpenSettings} style={{width:32,height:32,borderRadius:'50%',border:'none',background:'rgba(255,255,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer'}}><Ic name="settings" size={15} style={{color:'#fff'}}/></button>
            <button onClick={onOpenNotifications} style={{width:32,height:32,borderRadius:'50%',border:'none',background:'rgba(255,255,255,0.12)',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer'}}><Ic name="bell" size={15} style={{color:'#fff'}}/></button>
          </div>
        </div>
        <div style={{display:'flex',gap:8,marginTop:14}}>
          <span style={{background:'rgba(255,255,255,0.12)',color:'#fff',fontSize:11,fontWeight:700,padding:'6px 12px',borderRadius:999}}>GCE A LEVEL · SCIENCE</span>
          <span style={{background:'var(--gold-500)',color:'var(--ink-900)',fontSize:11,fontWeight:800,padding:'6px 12px',borderRadius:999,display:'flex',alignItems:'center',gap:4}}><Ic name="flame" size={12}/>START A STREAK</span>
        </div>
      </div>

      <div onClick={onOpenPaper} style={{marginTop:-24,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16,display:'flex',gap:12,alignItems:'center',cursor:'pointer'}}>
        <div style={{width:48,height:48,borderRadius:'50%',border:'3px solid var(--green-500)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}}><Ic name="target" size={20} style={{color:'var(--green-500)'}}/></div>
        <div style={{flex:1}}>
          <div style={{fontSize:11,fontWeight:700,color:'var(--green-600)',textTransform:'uppercase',letterSpacing:'0.04em'}}>Practice mode</div>
          <div style={{fontWeight:800,fontSize:15,color:'var(--text-primary)',marginTop:2}}>Learn without countdown pressure</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Start with a paper, quiz, or ask the AI assistant something.</div>
        </div>
        <Ic name="chevron-right"/>
      </div>

      <div style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16}}>
        <div style={{fontSize:11,fontWeight:700,color:'var(--gold-700)',textTransform:'uppercase',letterSpacing:'0.04em'}}>Your free trial</div>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginTop:4}}>
          <div style={{display:'flex',gap:10,alignItems:'flex-start'}}>
            <div style={{width:22,height:22,borderRadius:'50%',background:'var(--gold-50)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,marginTop:2}}><Ic name="check" size={12} style={{color:'var(--gold-700)'}}/></div>
            <div style={{fontWeight:800,fontSize:14,color:'var(--text-primary)'}}>Open your first marking guide free</div>
          </div>
          <span style={{fontSize:11,fontWeight:700,color:'var(--text-secondary)',background:'var(--surface-sunken)',padding:'4px 10px',borderRadius:999,flexShrink:0}}>7 days left</span>
        </div>
        <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:8}}>Unlimited paper views · offline downloads · AI assistant</div>
        <button style={{width:'100%',marginTop:10,background:'var(--gradient-primary)',color:'#fff',fontWeight:700,border:'none',borderRadius:999,padding:'13px',fontSize:14,cursor:'pointer'}}>Keep my access</button>
      </div>

      <div style={{display:'grid',gridTemplateColumns:'repeat(3,1fr)',gap:8,marginTop:16}}>
        {[['file-text','Papers',undefined],['book-open','Notes',onOpenNotes],['upload','Contribute',onOpenSubmit],['shopping-bag','Shop',onOpenShop],['message-circle','Forum',undefined],['download','Offline',undefined]].map(([icon,label,fn])=>(
          <div key={label} onClick={fn} style={{background:'#fff',borderRadius:'var(--radius-md)',boxShadow:'var(--shadow-card)',padding:'12px 4px',display:'flex',flexDirection:'column',alignItems:'center',gap:6,cursor:fn?'pointer':'default'}}>
            <Ic name={icon} size={18} style={{color:'var(--gold-700)'}}/>
            <span style={{fontSize:11,fontWeight:700,color:'var(--text-primary)'}}>{label}</span>
          </div>
        ))}
      </div>

      <div style={{marginTop:16,background:'var(--ink-900)',borderRadius:'var(--radius-lg)',padding:16,display:'flex',gap:12,alignItems:'center'}}>
        <div style={{flex:1}}>
          <div style={{fontWeight:800,fontSize:13,color:'#fff'}}>Daily challenge</div>
          <div style={{fontSize:11,color:'var(--text-on-dark-muted)',marginTop:2}}>5-minute mixed quiz · earn +50 XP</div>
          <button style={{marginTop:8,background:'var(--gold-500)',color:'var(--ink-900)',border:'none',borderRadius:999,padding:'8px 16px',fontWeight:800,fontSize:12,cursor:'pointer'}}>Play now</button>
        </div>
        <div style={{width:1,height:44,background:'rgba(255,255,255,0.15)'}}/>
        <div style={{flex:1,textAlign:'center'}}>
          <Ic name="flame" size={22} style={{color:'var(--gold-500)'}}/>
          <div style={{fontWeight:800,fontSize:13,color:'#fff',marginTop:4}}>Start</div>
          <div style={{fontSize:10,color:'var(--text-on-dark-muted)'}}>Play a quiz to begin</div>
        </div>
      </div>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'baseline',marginTop:20}}>
        <div style={{fontWeight:800,fontSize:15,color:'var(--text-primary)'}}>Ready offline</div>
        <span style={{fontSize:12,fontWeight:700,color:'var(--gold-700)'}}>Downloads · 1</span>
      </div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12}}>
        <div style={{width:40,height:40,borderRadius:'var(--radius-chip)',background:'var(--green-100)',display:'flex',alignItems:'center',justifyContent:'center'}}><Ic name="download" size={18} style={{color:'var(--green-600)'}}/></div>
        <div style={{flex:1}}>
          <div style={{fontWeight:700,fontSize:13,color:'var(--text-primary)'}}>Biology O-Level marking guide</div>
          <div style={{fontSize:11,color:'var(--green-600)',fontWeight:700,marginTop:2}}>✓ OFFLINE READY</div>
        </div>
        <Ic name="chevron-right"/>
      </div>
    </div>
  );
}
window.LoggedInHomeScreen = LoggedInHomeScreen;
