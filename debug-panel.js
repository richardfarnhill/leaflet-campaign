// ============================================================
// DEBUG PANEL - Visual console logs in the UI
// ============================================================

// Create debug panel
function createDebugPanel(){
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
  
  // Toggle with keyboard shortcut (Ctrl+Shift+D)
  document.addEventListener('keydown',e=>{
    if(e.ctrlKey&&e.shiftKey&&e.key==='D'){
      panel.style.display=panel.style.display==='none'?'block':'none';
    }
  });
  
  return panel;
}

const debugPanel=createDebugPanel();
const debugLogs=document.getElementById('debugLogs');

function addDebugLog(type,msg,data){
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
  
  // Keep only last 50 logs
  while(debugLogs.children.length>50){
    debugLogs.removeChild(debugLogs.lastChild);
  }
}

// Override Logger to also show in UI
const originalSuccess=Logger.success;
Logger.success=function(msg,data){
  addDebugLog('success',msg,data);
  originalSuccess.call(this,msg,data);
};

const originalWarn=Logger.warn;
Logger.warn=function(msg,data){
  addDebugLog('warn',msg,data);
  originalWarn.call(this,msg,data);
};

const originalError=Logger.error;
Logger.error=function(msg,data){
  addDebugLog('error',msg,data);
  originalError.call(this,msg,data);
};

const originalInfo=Logger.info;
Logger.info=function(msg,data){
  addDebugLog('info',msg,data);
  originalInfo.call(this,msg,data);
};

console.log('🔧 Debug panel ready. Press Ctrl+Shift+D to toggle.');
