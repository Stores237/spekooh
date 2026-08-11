function SubmitScreen() {
  const { Button, IconChip, Badge } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [type,setType] = React.useState('paper');
  const [step,setStep] = React.useState(0);
  if (step===1) {
    return (
      <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'0 24px',gap:14,textAlign:'center'}}>
        <IconChip tint="green" icon={<Ic name="check" size={28}/>} size={64}/>
        <div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Contribution received</div>
        <div style={{fontSize:13,color:'var(--text-secondary)'}}>{type==='paper' ? "We'll check it against existing papers first — if it's new, it moves to instructor review. Track it under Profile." : "Thanks — academic reports are added straight to the library, browsable by discipline & year."}</div>
        <Button variant="primary" onClick={()=>setStep(0)}>Submit another</Button>
      </div>
    );
  }
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{fontWeight:800,fontSize:20,marginTop:10,color:'var(--text-primary)'}}>Contribution</div>
      <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:4}}>Share a past paper or an academic report — every contribution helps another student.</div>
      <div style={{display:'flex',gap:8,marginTop:14,background:'var(--surface-sunken)',borderRadius:999,padding:4}}>
        {[['paper','Exam paper'],['report','Academic report']].map(([key,label])=>(
          <button key={key} onClick={()=>setType(key)} style={{flex:1,border:'none',borderRadius:999,padding:'9px 0',fontWeight:700,fontSize:13,cursor:'pointer',background:type===key?'#fff':'transparent',color:type===key?'var(--text-primary)':'var(--text-secondary)',boxShadow:type===key?'var(--shadow-card)':'none'}}>{label}</button>
        ))}
      </div>

      <div style={{marginTop:16,border:'1.5px dashed var(--gold-400)',borderRadius:'var(--radius-lg)',background:'var(--gold-50)',padding:26,display:'flex',flexDirection:'column',alignItems:'center',gap:8,cursor:'pointer'}}>
        <IconChip tint="amber" icon={<Ic name="camera" size={22}/>} size={52}/>
        <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Take a photo or upload a PDF</div>
        <div style={{fontSize:12,color:'var(--text-secondary)'}}>JPG, PNG or PDF · up to 20MB</div>
      </div>

      {type==='paper' ? (
        <div style={{marginTop:18,display:'flex',flexDirection:'column',gap:10}}>
          {[['Subject','Physics'],['Education level','A-Level'],['Exam type','GCE final'],['Year','2025'],['Exam board / school (optional)','—']].map(([label,val])=>(
            <div key={label} style={{background:'#fff',borderRadius:'var(--radius-md)',boxShadow:'var(--shadow-card)',padding:'12px 14px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <span style={{fontSize:13,color:'var(--text-secondary)'}}>{label}</span>
              <span style={{fontSize:13,fontWeight:700,color:'var(--text-primary)',display:'flex',alignItems:'center',gap:6}}>{val}<Ic name="chevron-right" size={14}/></span>
            </div>
          ))}
        </div>
      ) : (
        <div style={{marginTop:18,display:'flex',flexDirection:'column',gap:10}}>
          {[['Report type','Bachelor’s Report'],['Discipline','Computer Science'],['Institution','University of Buea'],['Year','2025']].map(([label,val])=>(
            <div key={label} style={{background:'#fff',borderRadius:'var(--radius-md)',boxShadow:'var(--shadow-card)',padding:'12px 14px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <span style={{fontSize:13,color:'var(--text-secondary)'}}>{label}</span>
              <span style={{fontSize:13,fontWeight:700,color:'var(--text-primary)',display:'flex',alignItems:'center',gap:6}}>{val}<Ic name="chevron-right" size={14}/></span>
            </div>
          ))}
        </div>
      )}

      <div style={{marginTop:14,display:'flex',alignItems:'center',gap:10,background:'var(--green-100)',borderRadius:'var(--radius-lg)',padding:'12px 14px'}}>
        <Ic name="gift" size={18} style={{color:'var(--green-600)'}}/>
        <span style={{fontSize:12,color:'var(--green-600)',fontWeight:600,flex:1}}>{type==='paper' ? 'New, verified submissions earn bonus credit — redeemable toward marking-guide unlocks.' : 'Academic reports are browsable references — no marking guide, but you still earn contributor credit.'}</span>
      </div>
      <Button variant="primary" onClick={()=>setStep(1)} style={{width:'100%',marginTop:18}}>{type==='paper' ? 'Submit paper' : 'Submit report'}</Button>
    </div>
  );
}
window.SubmitScreen = SubmitScreen;
