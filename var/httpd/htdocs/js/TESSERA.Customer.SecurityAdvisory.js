(function () {
'use strict';
function init() {
 var form=document.getElementById('AdvisoryForm');if(!form){return;}
 var create=document.getElementById('AdvisoryCreate'),newButton=document.getElementById('AdvisoryNewToggle');
 function showCreate(show){create.hidden=!show;newButton.setAttribute('aria-expanded',String(show));if(show){document.getElementById('AdvisoryName').focus();}else{newButton.focus();}}
 newButton.addEventListener('click',function(){showCreate(create.hidden);});
 document.getElementById('AdvisoryCancel').addEventListener('click',function(){showCreate(false);});
 var mode=document.getElementById('AdvisoryConditionMode'), products=document.getElementById('AdvisoryProducts'), yaml=document.getElementById('AdvisoryCondition'), error=document.getElementById('AdvisoryConditionError'), previous='Products', lastGenerated='';
 function generate() {
  var names=Array.from(products.selectedOptions).map(function(o){return o.textContent;});
  return 'VERSION: 1\nSEARCH:\n  FOR: ITSMConfigItem\n  CLASS: Product\n  AS: Products\n  LIMIT: 1000\n  WHERE:\n    Name:\n      EQUALS: '+JSON.stringify(names)+'\nRETURN:\n  FROM: ALL Products\n  AS: Collection<ITSMConfigItem.Product>\n';
 }
 if(yaml.value.trim()){mode.value='YAML';previous='YAML';document.getElementById('AdvisoryProductMode').hidden=true;document.getElementById('AdvisoryYAMLMode').hidden=false;}
 mode.addEventListener('change',function(){
  error.textContent='';
  if(mode.value==='Products' && yaml.value.trim() && yaml.value!==lastGenerated){
   error.textContent='This YAML has advanced edits. Keep YAML mode to preserve them; clear the condition to start a new Product selection.';mode.value='YAML';return;
  }
  if(mode.value==='YAML' && previous==='Products'){lastGenerated=generate();yaml.value=lastGenerated;}
  document.getElementById('AdvisoryProductMode').hidden=mode.value!=='Products';document.getElementById('AdvisoryYAMLMode').hidden=mode.value!=='YAML';previous=mode.value;
 });
 document.getElementById('AdvisoryProductSearch').addEventListener('input',function(e){var q=e.target.value.toLowerCase();Array.from(products.options).forEach(function(o){o.hidden=o.textContent.toLowerCase().indexOf(q)<0 && !o.selected;});});
 document.getElementById('AdvisoryImportToggle').addEventListener('click',function(e){var box=document.getElementById('AdvisoryImport');box.hidden=!box.hidden;e.target.setAttribute('aria-expanded',String(!box.hidden));});
 var file=document.getElementById('AdvisoryWorkbook'),payload=document.getElementById('AdvisoryPayload'),preview=document.getElementById('AdvisoryPreview'),commit=document.getElementById('AdvisoryImportCommit');
 file.addEventListener('change',function(){payload.value='';preview.textContent='';commit.disabled=true;});
 document.getElementById('AdvisoryPreviewButton').addEventListener('click',function(){
  commit.disabled=true;payload.value='';preview.textContent='';
  if(!file.files[0]){preview.textContent='Choose an Excel workbook.';return;}
  if(file.files[0].size>10*1024*1024){preview.textContent='Workbook exceeds 10MB.';return;}
  file.files[0].arrayBuffer().then(function(buffer){
   var w=XLSX.read(buffer,{type:'array',cellDates:false}),sheet=w.Sheets.SecurityAdvisory;if(!sheet){throw new Error('The SecurityAdvisory sheet is missing.');}
   var rows=XLSX.utils.sheet_to_json(sheet,{defval:''});if(!rows.length||rows.length>500){throw new Error('Use between 1 and 500 advisory rows.');}
   rows.forEach(function(row){Object.keys(row).forEach(function(k){var v=row[k];if(typeof v==='string' && /^\s*[\[{]/.test(v)){try{row[k]=JSON.parse(v);}catch(ignore){}}});row.__ExcelDate1904=!!(w.Workbook&&w.Workbook.WBProps&&w.Workbook.WBProps.date1904);});
   var table=document.createElement('table');var head=document.createElement('tr');['Row','Name','Application'].forEach(function(label){var th=document.createElement('th');th.textContent=label;head.appendChild(th);});table.appendChild(head);
   rows.forEach(function(row,i){var tr=document.createElement('tr');[String(i+1),row.Name||'',row['ZTAM-Application']||''].forEach(function(value){var td=document.createElement('td');td.textContent=String(value);tr.appendChild(td);});table.appendChild(tr);});preview.appendChild(table);payload.value=JSON.stringify(rows);commit.disabled=false;
  }).catch(function(e){preview.textContent=e.message;});
 });
}
if(document.readyState==='loading'){document.addEventListener('DOMContentLoaded',init);}else{init();}
}());
