/* Aggregate the existing daily finance report; never add receipts to earned revenue. */
(() => {
    const fields=['doanhThu','tienThu','tienHoan','thucNhan'];
    const iso=d=>d.toISOString().slice(0,10), date=s=>new Date(s+'T00:00:00Z');
    function range(year,month,period){
        if(!Number.isInteger(year)||year<1753||year>9998||!Number.isInteger(month)||month<1||month>12)throw Error('Chọn năm và tháng hợp lệ.');
        const start=period==='day'?`${year}-${String(month).padStart(2,'0')}-01`:`${period==='year'?Math.max(1753,year-4):year}-01-01`;
        const end=period==='day'?iso(new Date(Date.UTC(year,month,0))):`${year}-12-31`;
        return {start,end};
    }
    function key(day,period){
        if(period==='year')return day.slice(0,4);
        if(period==='month')return day.slice(0,7);
        if(period==='day')return day;
        const d=date(day);d.setUTCDate(d.getUTCDate()-((d.getUTCDay()+6)%7));return iso(d);
    }
    function aggregate(rows,start,end,period){
        const buckets=new Map();
        for(let d=date(start);iso(d)<=end;d.setUTCDate(d.getUTCDate()+1)){
            const day=iso(d),k=key(day,period);
            if(!buckets.has(k))buckets.set(k,{key:k,first:day,last:day,...Object.fromEntries(fields.map(f=>[f,0]))});
            buckets.get(k).last=day;
        }
        for(const row of rows){const day=String(row.ngay).slice(0,10);if(day<start||day>end)continue;const b=buckets.get(key(day,period));if(!b)throw Error('Ngày báo cáo không hợp lệ.');for(const f of fields){const n=Number(row[f]??0);if(!Number.isFinite(n))throw Error('Số liệu báo cáo không hợp lệ.');b[f]=Math.round((b[f]+n)*100)/100;}}
        return [...buckets.values()];
    }
    window.SanBongRevenueMath={range,aggregate};
    document.addEventListener('sanbong:authenticated',async event=>{
        const $=id=>document.getElementById(id);if(!$('revenueFilters'))return;
        if(!['VT03','VT04'].includes(event.detail.maVaiTro)||!event.detail.permissions.includes('CN06_XEM')){$('revenueStatus').textContent='Bạn chưa được cấp quyền xem doanh thu.';$('revenueFilters').querySelector('button').disabled=true;return;}
        const money=n=>Number(n).toLocaleString('vi-VN',{maximumFractionDigits:2})+'đ';
        const display=s=>s.slice(8,10)+'/'+s.slice(5,7)+'/'+s.slice(0,4);
        const labels={doanhThu:'Doanh thu khi trả sân',tienThu:'Tiền đã thu',tienHoan:'Tiền đã hoàn',thucNhan:'Thực nhận'};
        const definitions={doanhThu:'Ghi nhận khi hoàn thành lượt sử dụng sân.',tienThu:'Chỉ gồm các khoản thu đã xác nhận.',tienHoan:'Chỉ gồm các khoản đã hoàn thực tế.',thucNhan:'Tiền đã thu trừ tiền đã hoàn.'};
        let buckets=[],period='month',kind='bar',version=0,loaded=false;
        for(let m=1;m<=12;m++)$('revenueMonth').add(new Option('Tháng '+m,String(m)));
        function caption(b,i){return period==='year'?b.key:period==='month'?'Tháng '+Number(b.key.slice(5,7)):period==='week'?'Tuần '+(i+1):b.first.slice(8,10)+'/'+b.first.slice(5,7);}
        const short=n=>new Intl.NumberFormat('vi-VN',{notation:'compact',maximumFractionDigits:1}).format(n);
        function chart(){
            const host=$('revenueChart');host.replaceChildren();$('revenueRows').replaceChildren();if(!loaded)return;
            const metric=$('revenueMetric').value;$('revenueChartTitle').textContent=labels[metric];$('revenueDefinition').textContent=definitions[metric];
            const values=buckets.map(b=>b[metric]);const maximum=Math.max(0,...values),minimum=Math.min(0,...values),span=maximum-minimum||1;
            const low=minimum<0?minimum-span*.1:0,high=maximum>0?maximum+span*.12:minimum<0?0:1;
            const width=Math.max(760,buckets.length*32+100),height=360,left=78,right=24,top=28,bottom=56,plotHeight=height-top-bottom,plotWidth=width-left-right;
            const y=value=>top+(high-value)/(high-low)*plotHeight,step=plotWidth/Math.max(1,buckets.length),x=i=>left+step*(i+.5);
            const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox',`0 0 ${width} ${height}`);svg.setAttribute('width',String(width));svg.style.width='100%';svg.style.minWidth=width+'px';svg.style.height='auto';svg.setAttribute('height',String(height));svg.setAttribute('role','img');svg.setAttribute('aria-label',labels[metric]+'. Bảng số liệu chi tiết ở bên dưới.');
            function node(tag,attrs,text,parent=svg){const el=document.createElementNS(ns,tag);for(const [k,v]of Object.entries(attrs))el.setAttribute(k,String(v));if(text!==undefined)el.textContent=text;parent.append(el);return el;}
            node('title',{},labels[metric]);
            for(let tick=0;tick<=4;tick++){const value=low+(high-low)*tick/4,position=y(value);node('line',{x1:left,y1:position,x2:width-right,y2:position,stroke:'#e7edf6','stroke-dasharray':'4 5'});node('text',{x:left-12,y:position+4,'text-anchor':'end',fill:'#64748b','font-size':13},short(value));}
            node('line',{x1:left,y1:y(0),x2:width-right,y2:y(0),stroke:'#a8bad4'});
            if(kind==='line')node('polyline',{points:values.map((v,i)=>`${x(i)},${y(v)}`).join(' '),fill:'none',stroke:'#1d4ed8','stroke-width':3,'stroke-linejoin':'round','stroke-linecap':'round'});
            values.forEach((value,i)=>{
                const shape=kind==='bar'?node('rect',{x:x(i)-step*.28,y:Math.min(y(value),y(0)),width:Math.max(4,step*.56),height:Math.abs(y(value)-y(0)),rx:4,fill:value<0?'#b42332':'#1d4ed8'}):node('circle',{cx:x(i),cy:y(value),r:4,fill:'#fff',stroke:'#1d4ed8','stroke-width':2});
                shape.setAttribute('tabindex','0');shape.setAttribute('aria-label',caption(buckets[i],i)+': '+money(value));node('title',{},`${display(buckets[i].first)} – ${display(buckets[i].last)}: ${money(value)}`,shape);
                const stride=Math.max(1,Math.ceil(values.length/12));if(i%stride===0||i===values.length-1)node('text',{x:x(i),y:height-24,'text-anchor':'middle',fill:'#526279','font-size':13},caption(buckets[i],i));
                const tr=document.createElement('tr');for(const v of [caption(buckets[i],i),...fields.map(f=>money(buckets[i][f]))]){const td=document.createElement('td');td.textContent=v;tr.append(td);}$('revenueRows').append(tr);
            });host.append(svg);
            const peak=Math.max(...values),peakIndex=values.indexOf(peak);$('revenueTrend').textContent=values.every(v=>v===0)?'Chưa có số liệu phát sinh trong khoảng đã chọn.':`Cao nhất: ${caption(buckets[peakIndex],peakIndex)} · ${money(peak)}`;
        }
        function clear(){loaded=false;buckets=[];$('revenueTotals').replaceChildren();$('revenueTrend').textContent='';chart();}
        async function load(){
            const requestVersion=++version;clear();$('revenueStatus').textContent='Đang tải doanh thu…';$('revenueStatus').dataset.error='false';$('revenueRefresh').disabled=true;
            try{
                const year=Number($('revenueYear').value),month=Number($('revenueMonth').value);period=$('revenuePeriod').value;const {start,end}=range(year,month,period);const pitch=$('revenuePitch').value;
                const ranges=period==='year'?Array.from({length:year-Number(start.slice(0,4))+1},(_,i)=>{const y=Number(start.slice(0,4))+i;return {from:y+'-01-01',to:y+'-12-31'};}):[{from:start,to:end}];
                const responses=await Promise.all(ranges.map(r=>SanBong.request('reports/finance?'+new URLSearchParams({...r,pitch}))));if(requestVersion!==version)return;
                buckets=aggregate(responses.flatMap(r=>r.rows),start,end,period);loaded=true;
                $('revenueRange').textContent=`${display(start)} – ${display(end)} · ${$('revenuePitch').selectedOptions[0].textContent}`;
                for(const f of fields){const card=document.createElement('div');card.className='revenue-total';const label=document.createElement('span'),value=document.createElement('strong');label.textContent=labels[f];value.textContent=money(buckets.reduce((sum,b)=>Math.round((sum+b[f])*100)/100,0));card.append(label,value);$('revenueTotals').append(card);}
                $('revenueStatus').textContent='';chart();
            }catch(error){if(requestVersion===version){clear();$('revenueStatus').textContent=error.message;$('revenueStatus').dataset.error='true';}}
            finally{if(requestVersion===version)$('revenueRefresh').disabled=false;}
        }
        $('revenueFilters').onsubmit=e=>{e.preventDefault();load();};$('revenueRefresh').onclick=load;
        $('revenuePeriod').onchange=()=>{$('revenueMonthLabel').hidden=$('revenuePeriod').value!=='day';load();};
        $('revenueMetric').onchange=chart;
        for(const [id,type]of [['revenueBar','bar'],['revenueLine','line']])$(id).onclick=()=>{kind=type;$('revenueBar').setAttribute('aria-pressed',String(type==='bar'));$('revenueLine').setAttribute('aria-pressed',String(type==='line'));chart();};
        try{const options=await SanBong.request('reports/options');$('revenueYear').value=options.today.slice(0,4);$('revenueMonth').value=String(Number(options.today.slice(5,7)));for(const pitch of options.pitches)$('revenuePitch').add(new Option(pitch.tenSan,pitch.maSan));await load();}catch(error){$('revenueStatus').textContent=error.message;$('revenueStatus').dataset.error='true';}
    });
})();
