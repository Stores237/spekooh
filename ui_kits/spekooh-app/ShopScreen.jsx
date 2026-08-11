function ShopScreen({onBack,onOpenPamphlet}) {
  const { SearchInput, Button } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const items = [
    ['Probatoire Philosophy Pamphlet','Librairie Centrale','7,500'],
    ['GCE A Level Further Maths Pack','Presbook Bookshop','6,000'],
    ['Baccalauréat SVT Revision Guide','Librairie Centrale','5,500']
  ];
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button onClick={onBack} style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="chevron-left"/></button>
        <div><div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Shop</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Partner pamphlets · pay in-app, pick up with a QR code</div></div>
      </div>
      <div style={{marginTop:14}}><SearchInput placeholder="Search pamphlets..."/></div>
      <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:10}}>
        {items.map(([title,partner,price])=>(
          <div key={title} onClick={onOpenPamphlet} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',gap:12,alignItems:'center',cursor:'pointer'}}>
            <div style={{width:56,height:56,borderRadius:10,background:'var(--gradient-gold-deep)',flexShrink:0}}/>
            <div style={{flex:1}}>
              <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div>
              <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Sold by {partner} · QR pickup</div>
              <div style={{marginTop:6,fontWeight:800,color:'var(--text-primary)'}}>{price} <span style={{fontSize:11,color:'var(--text-tertiary)',fontWeight:600}}>FCFA</span></div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
window.ShopScreen = ShopScreen;
