function Ic({name,size=18,style}) {
  const pascal = name.replace(/(^\w|-\w)/g,m=>m.replace('-','').toUpperCase());
  const nodes = (window.lucide && window.lucide.icons && window.lucide.icons[pascal]) || [];
  const children = nodes.map((n,i)=>React.createElement(n[0],{key:i,...n[1]}));
  return React.createElement('svg',{width:size,height:size,viewBox:'0 0 24 24',fill:'none',stroke:'currentColor',strokeWidth:2,strokeLinecap:'round',strokeLinejoin:'round',style:{flexShrink:0,...style}},children);
}
window.Ic = Ic;
