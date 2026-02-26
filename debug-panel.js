// ============================================================
// DEBUG PANEL - Visual console logs in the UI
// ============================================================

document.addEventListener('DOMContentLoaded',function(){
  // Create debug panel
  const panel=document.createElement('div');
  panel.id='debugPanel';
  panel.style.cssText=`
    position:fixed;bottom:0;left:0;right:0;max-height:200px;overflow-y:auto;
    background:#1a1a2e;color:#eee;font-family:monospace;font-size:12px;
    padding:10px;z-index:9999;display:none;border-top:3px solid #333;
  `;
  panel.innerHTML=`
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
      <span style="font-weight:bold;color:#fff;">🔧 DEBUG LOGS</span>
      <button onclick="document.getElementById('debugPanel').style.display='none'" 
        style="background:#ff4757;border:none;color:white;padding:4px 10px;cursor:pointer;border-radius:3px;">✕</button>
    </div>
    <div id="debugLogs"></div>
  `;
  document.body.appendChild(panel);
  
  const debugLogs=document.getElementById('debugLogs');
  
  // Toggle with keyboard shortcut (Ctrl+Shift+D)
  document.addEventListener('keydown',e=>{
    if(e.ctrlKey&&e.shiftKey&&e.key==='D'){
      panel.style.display=panel.style.display==='none'?'block':'none';
    }
  });
  
  window.addDebugLog=function(type,msg,data){
    const entry=document.createElement('div');
    entry.style.cssText='padding:3px 0;border-bottom:1px solid #333;';
    
    let icon,color;
    switch(type){
      case 'success':icon='🟢';color='#2ed573';break;
      case 'warn':icon='🟡';color='#ffa502';break;
      case 'error':icon='🔴';color='#ff4757';break;
      default:icon='🔵';color='#70a1ff';
    }
    
    let text=msg;
    if(data){
      text+=' '+JSON.stringify(data);
    }
    
    entry.innerHTML=`<span style="color:${color}">${icon}</span> ${new Date().toLocaleTimeString()} ${text}`;
    debugLogs.insertBefore(entry,debugLogs.firstChild);
    
    while(debugLogs.children.length>50){
      debugLogs.removeChild(debugLogs.lastChild);
    }
  };
  
  console.log('🔧 Debug panel ready. Press Ctrl+Shift+D to toggle.');
});
