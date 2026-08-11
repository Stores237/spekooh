function PaywallSheet({onClose}) {
  const { Button } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return (
    <div onClick={onClose} style={{position:'absolute',inset:0,background:'rgba(24,36,81,0.45)',backdropFilter:'blur(2px)',display:'flex',alignItems:'flex-end',zIndex:10}}>
      <div onClick={e=>e.stopPropagation()} style={{background:'#fff',width:'100%',borderRadius:'26px 26px 0 0',padding:'10px 22px 26px',boxShadow:'var(--shadow-sheet)'}}>
        <div style={{width:40,height:4,borderRadius:2,background:'var(--border-subtle)',margin:'0 auto 16px'}}/>
        <div style={{display:'flex',justifyContent:'center'}}><div style={{width:60,height:60,borderRadius:16,background:'var(--gradient-primary)',display:'flex',alignItems:'center',justifyContent:'center'}}><Ic name="star" size={26}/></div></div>
        <div style={{textAlign:'center',fontWeight:800,fontSize:20,marginTop:12,color:'var(--text-primary)'}}>Get Spekooh Pro</div>
        <div style={{textAlign:'center',fontSize:13,color:'var(--text-secondary)',marginTop:6}}>Unlimited question-paper views and an ad-free app. Marking guides are always unlocked separately.</div>
        <div style={{marginTop:16,background:'var(--surface-sunken)',borderRadius:'var(--radius-lg)',padding:'2px 16px'}}>
          {[['eye','Unlimited question paper views'],['ban','Zero ads while you study'],['bell','Instructor status alerts']].map(([icon,label],i)=>(
            <div key={label} style={{display:'flex',alignItems:'center',gap:10,padding:'11px 0',borderTop:i>0?'1px solid var(--border-subtle)':'none'}}>
              <div style={{width:26,height:26,borderRadius:'50%',background:'var(--green-100)',display:'flex',alignItems:'center',justifyContent:'center',color:'var(--green-600)'}}><Ic name={icon} size={14}/></div>
              <div style={{fontSize:13,color:'var(--text-primary)'}}>{label}</div>
            </div>
          ))}
        </div>
        <div style={{marginTop:14,border:'1.5px solid var(--blue-400)',borderRadius:'var(--radius-lg)',padding:'12px 16px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <span style={{fontSize:11,fontWeight:800,color:'var(--text-secondary)',letterSpacing:'0.04em'}}>SPEKOOH PRO</span>
          <span style={{fontWeight:800,fontSize:17,color:'var(--text-primary)'}}>500 <span style={{fontSize:11,color:'var(--text-tertiary)',fontWeight:600}}>FCFA/mo</span></span>
        </div>
        <div style={{marginTop:14,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>MTN MoMo or Orange Money number</div>
        <div style={{marginTop:6,display:'flex',alignItems:'center',gap:8,background:'#fff',border:'1px solid var(--border-subtle)',borderRadius:'var(--radius-md)',padding:'12px 14px'}}>
          <span style={{color:'var(--text-secondary)',fontWeight:600}}>+237</span>
          <input placeholder="670 12 34 56" style={{border:'none',outline:'none',flex:1,fontSize:14}}/>
        </div>
        <Button variant="primary" style={{width:'100%',marginTop:14}}>Pay 500 FCFA</Button>
        <div style={{textAlign:'center',fontSize:11,color:'var(--text-tertiary)',marginTop:10}}>Official Spekooh merchant · we never ask for your PIN · receipt + SMS within 2 min</div>
      </div>
    </div>
  );
}
window.PaywallSheet = PaywallSheet;
