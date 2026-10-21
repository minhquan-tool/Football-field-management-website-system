/* Weekly read model. All booking mutations stay in the existing booking workspace. */
(() => {
    const $=id=>document.getElementById(id),hourHeight=108,dayNames=['Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','Chủ nhật'];
    let version=0,optionsReady=false,loaded=false, pitchOptions=[], staffView=false, selectedDay="";
    const today=()=>{const parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Ho_Chi_Minh',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(new Date());const value=key=>parts.find(p=>p.type===key).value;return `${value('year')}-${value('month')}-${value('day')}`;};
    function date(value){if(!/^\d{4}-\d{2}-\d{2}$/.test(value))throw Error('Chọn ngày trong tuần hợp lệ.');const result=new Date(value+'T00:00:00Z');if(!Number.isFinite(result.getTime())||result.toISOString().slice(0,10)!==value)throw Error('Ngày không hợp lệ.');return result;}
    function add(value,days){const result=date(value);result.setUTCDate(result.getUTCDate()+days);const iso=result.toISOString().slice(0,10);if(!/^\d{4}-\d{2}-\d{2}$/.test(iso)||iso.startsWith('0000'))throw Error('Tuần nằm ngoài khoảng ngày hỗ trợ.');return iso;}
    function monday(value){const d=date(value);return add(value,-((d.getUTCDay()+6)%7));}
    const format=value=>value.slice(8,10)+'/'+value.slice(5,7)+'/'+value.slice(0,4);
    function minutes(time){if(!/^\d{2}:\d{2}(:\d{2})?$/.test(time))throw Error('Giờ của lượt đặt không hợp lệ.');const [h,m,s=0]=time.split(':').map(Number);if(h>23||m>59||s>59)throw Error('Giờ của lượt đặt không hợp lệ.');return h*60+m+s/60;}
    function node(tag,text,cls){const el=document.createElement(tag);if(text!=null)el.textContent=text;if(cls)el.className=cls;return el;}
    function link(booking){return 'dieu-phoi-san?'+new URLSearchParams({date:booking.ngayChoi,pitch:booking.maSan,booking:booking.maDatSan});}
    function clear(){loaded=false;$('scheduleBoard').replaceChildren();$('scheduleList').replaceChildren();$('scheduleList').hidden=true;$('scheduleScroll').hidden=true;$('schedulePrint').disabled=true;}
    function status(message,error=false){$('scheduleStatus').textContent=message;$('scheduleStatus').dataset.error=String(error);}
    function lanes(rows){const ends=[];return {items:rows.map(booking=>({booking,start:minutes(booking.gioBatDau),end:minutes(booking.gioKetThuc)})).sort((a,b)=>a.start-b.start||a.end-b.end||a.booking.maDatSan.localeCompare(b.booking.maDatSan)).map(item=>{if(item.end<=item.start)throw Error('Lượt đặt có giờ kết thúc không hợp lệ.');let lane=ends.findIndex(end=>end<=item.start);if(lane<0)lane=ends.length;ends[lane]=item.end;return {...item,lane};}),ends};}
    function render(data,pitchLabel,stateLabel){
        const days=Array.from({length:7},(_,index)=>add(data.weekStart,index));const groups=days.map(day=>lanes(data.bookings.filter(b=>b.ngayChoi===day)));
        const items=groups.flatMap(group=>group.items);const startHour=Math.floor(Math.min(7*60,...items.map(i=>i.start))/60),endHour=Math.ceil(Math.max(22*60,...items.map(i=>i.end))/60),height=(endHour-startHour)*hourHeight;
        const board=$('scheduleBoard');board.className='schedule-board';const widths=groups.map(group=>Math.max(130,group.ends.length*152));board.style.gridTemplateColumns='64px '+widths.map(width=>`minmax(${width}px,1fr)`).join(' ');board.style.minWidth=(64+widths.reduce((a,b)=>a+b,0))+'px';
        board.append(node('div','Giờ đá','schedule-corner'));days.forEach((day,index)=>{const header=node('div',null,'schedule-day-title'+(index>=5?' weekend':'')+(day===data.today?' today':''));header.append(node('strong',dayNames[index]),node('span',format(day)+(day===data.today?' · Hôm nay':'')));board.append(header);});
        const axis=node('div',null,'schedule-time-axis');axis.style.height=height+'px';for(let hour=startHour;hour<endHour;hour++){const row=node('div',String(hour).padStart(2,'0')+':00','schedule-hour');row.style.top=(hour-startHour)*hourHeight+'px';row.style.height=hourHeight+'px';axis.append(row);}board.append(axis);
        groups.forEach((group,index)=>{const column=node('div',null,'schedule-day'+(days[index]===data.today?' today':''));column.style.gridColumn=String(index+2);column.style.height=height+'px';column.setAttribute('aria-label',dayNames[index]+' '+format(days[index]));
            group.items.forEach(({booking,start,end,lane})=>{const event=node('a',null,'schedule-event'+(end-start<60?' compact':'')+(end-start<45?' short':'')+(end-start<30?' tiny':''));event.href=link(booking);event.dataset.booking=booking.maDatSan;event.dataset.state=booking.trangThai;const label=`${booking.gioBatDau.slice(0,5)}–${booking.gioKetThuc.slice(0,5)} · ${booking.tenSan} · ${booking.hoTen} · ${booking.trangThai} · ${booking.maDatSan}`;event.title=label;event.setAttribute('aria-label',label);event.style.top=((start-startHour*60)/60*hourHeight)+'px';event.style.height=Math.max(1,(end-start)/60*hourHeight-2)+'px';event.style.left=`calc(${lane/group.ends.length*100}% + 3px)`;event.style.width=`calc(${100/group.ends.length}% - 6px)`;event.append(node('strong',`${booking.gioBatDau.slice(0,5)}–${booking.gioKetThuc.slice(0,5)}`),node('span',booking.tenSan,'event-pitch'),node('span',booking.hoTen,'event-customer'),node('span',booking.trangThai,'event-state'));column.append(event);});board.append(column);
        });
        const list=$('scheduleList'),table=node('table'),head=node('thead'),tr=node('tr');for(const title of ['Ngày','Giờ đá','Sân','Khách hàng','Trạng thái','Mã đặt sân'])tr.append(node('th',title));head.append(tr);table.append(head);const body=node('tbody');for(const booking of data.bookings){const row=node('tr');for(const value of [format(booking.ngayChoi),booking.gioBatDau.slice(0,5)+'–'+booking.gioKetThuc.slice(0,5),booking.tenSan,booking.hoTen,booking.trangThai])row.append(node('td',value));const cell=node('td'),a=node('a',booking.maDatSan);a.href=link(booking);cell.append(a);row.append(cell);body.append(row);}if(!data.bookings.length){const row=node('tr'),cell=node('td','Không có lượt đặt phù hợp trong tuần.');cell.colSpan=6;row.append(cell);body.append(row);}table.append(body);list.append(table);list.hidden=false;
        $('scheduleWeekTitle').textContent=`${format(data.weekStart)} – ${format(data.weekEnd)}`;status(`${data.bookings.length} lượt đặt · ${pitchLabel} · ${stateLabel}`);$('scheduleScroll').hidden=false;$('schedulePrint').disabled=false;loaded=true;if(staffView&&$('staffScheduleMode').value==='day')renderPitchDay(data);
    }

    function setupStaffView(){
        staffView=true;
        const tools=node('div',null,'staff-schedule-tools');
        for(const [id,label,values] of [['staffScheduleMode','Hiển thị',[['day','Sân × giờ trong ngày'],['week','Lịch cả tuần']]],['staffPitchType','Loại sân',[['','Tất cả loại sân']]]]){
            const wrap=node('label',label),select=node('select');select.id=id;for(const [value,text]of values)select.add(new Option(text,value));select.onchange=load;wrap.append(select);tools.append(wrap);
        }
        document.querySelector('.schedule-controls').append(tools);
        $('schedulePrevious').textContent='← Trước';$('schedulePrevious').setAttribute('aria-label','Ngày hoặc tuần trước');$('scheduleNext').textContent='Sau →';$('scheduleNext').setAttribute('aria-label','Ngày hoặc tuần sau');$('scheduleToday').textContent='Hôm nay';
        const note=node('p','Xem lịch theo sân và giờ thực tế; chọn một lượt đặt để mở quản lý. Các khoảng trống cần được kiểm tra lại khi đặt sân.','schedule-help');document.querySelector('.schedule-title>div').append(note);
    }
    function renderPitchDay(data){
        const type=$('staffPitchType');if(type.options.length===1){const seen=new Set();for(const p of pitchOptions)if(p.maLoaiSan&&!seen.has(p.maLoaiSan)){seen.add(p.maLoaiSan);type.add(new Option(p.tenLoaiSan,p.maLoaiSan));}}
        const pitches=pitchOptions.filter(p=>(!$('schedulePitch').value||p.maSan===$('schedulePitch').value)&&(!type.value||p.maLoaiSan===type.value));
        const rows=data.bookings.filter(b=>b.ngayChoi===selectedDay);
        // Never infer a free interval from a status-filtered subset.
        const filtered=$('scheduleState').value!=='ALL';
        const edges=[...new Set([420,1320,...Array.from({length:14},(_,i)=>480+i*60),...rows.flatMap(b=>[minutes(b.gioBatDau),minutes(b.gioKetThuc)])])].sort((a,b)=>a-b);
        const fmt=m=>String(Math.floor(m/60)).padStart(2,'0')+':'+String(Math.floor(m%60)).padStart(2,'0');
        const board=$('scheduleBoard');board.replaceChildren();board.style.cssText='';board.className='schedule-board pitch-time-board';
        const table=node('table'),head=node('thead'),hr=node('tr');hr.append(node('th','Sân bóng · '+format(selectedDay)));for(let i=0;i<edges.length-1;i++){const th=node('th',fmt(edges[i]));th.append(node('small',fmt(edges[i+1])));hr.append(th);}head.append(hr);table.append(head);const body=node('tbody');
        for(const p of pitches){const tr=node('tr'),name=node('td');name.append(node('strong',p.tenSan),node('small',p.tenLoaiSan+' · '+p.maSan));tr.append(name);
            for(let i=0;i<edges.length-1;i++){const cell=node('td'),matches=rows.filter(b=>b.maSan===p.maSan&&minutes(b.gioBatDau)<edges[i+1]&&minutes(b.gioKetThuc)>edges[i]);
                if(matches.length){const key=matches.map(b=>b.maDatSan).sort().join('|');const prior=tr.lastElementChild;if(prior.dataset.bookings===key){prior.colSpan++;continue;}cell.dataset.bookings=key;}if(matches.length)for(const b of matches){const a=node('a',b.hoTen);a.href=link(b);a.dataset.state=b.trangThai;a.append(node('small',b.maDatSan+' · '+b.gioBatDau.slice(0,5)+'–'+b.gioKetThuc.slice(0,5)),node('small',b.trangThai));cell.append(a);}
                else cell.append(node('span',p.trangThai==='Bảo trì'?'Bảo trì':filtered?'Không thuộc bộ lọc':'Chưa có lượt đặt',p.trangThai==='Bảo trì'||filtered?'sw-maintenance':'sw-free'));tr.append(cell);
            }body.append(tr);
        }
        if(!pitches.length){const tr=node('tr'),td=node('td','Không có sân phù hợp.');td.colSpan=edges.length;tr.append(td);body.append(tr);}table.append(body);board.append(table);$('scheduleWeekTitle').textContent='Lịch sân ngày '+format(selectedDay);$('scheduleScroll').setAttribute('aria-label','Lịch sân theo giờ, cuộn ngang để xem thêm');
    }
    async function load(){const token=++version;clear();$('scheduleWeekTitle').textContent='Lịch trong tuần';status('Đang tải lịch…');
        try{date($('scheduleDate').value);const selected={date:$('scheduleDate').value,pitch:$('schedulePitch').value,status:$('scheduleState').value};
            if(!optionsReady){const options=await SanBong.request('booking-options');if(token!==version)return;pitchOptions=options.pitches;for(const pitch of options.pitches)$('schedulePitch').add(new Option(pitch.tenSan,pitch.maSan));optionsReady=true;const initial=new URLSearchParams(location.search).get('pitch');if(initial&&[...$('schedulePitch').options].some(o=>o.value===initial)){selected.pitch=initial;$('schedulePitch').value=initial;}}
            const data=await SanBong.request('staff/weekly-schedule?'+new URLSearchParams(selected));if(token!==version)return;
            selectedDay=selected.date;$('scheduleDate').value=staffView&&$('staffScheduleMode').value==='day'?selected.date:$('scheduleDate').value;render(data,$('schedulePitch').selectedOptions[0].textContent,$('scheduleState').selectedOptions[0].textContent);history.replaceState(null,'','?'+new URLSearchParams({...selected,date:$('scheduleDate').value}));
        }catch(error){if(token===version){clear();status(error.message,true);}}
    }
    function move(days){try{$('scheduleDate').value=add(staffView&&$('staffScheduleMode').value==='day'?($('scheduleDate').value||today()):monday($('scheduleDate').value||today()),staffView&&$('staffScheduleMode').value==='day'?Math.sign(days):days);load();}catch(error){version++;clear();status(error.message,true);}}
    $('scheduleFilters').addEventListener('submit',e=>{e.preventDefault();load();});for(const id of ['schedulePitch','scheduleDate','scheduleState'])$(id).addEventListener('change',load);
    $('schedulePrevious').onclick=()=>move(-7);$('scheduleNext').onclick=()=>move(7);$('scheduleToday').onclick=()=>{$('scheduleDate').value=today();load();};$('scheduleRefresh').onclick=load;$('schedulePrint').onclick=()=>{if(loaded)window.print();};

    document.addEventListener('sanbong:authenticated',e=>{if(!['VT02','VT04'].includes(e.detail.maVaiTro)||!e.detail.permissions.includes('CN02_XEM')){clear();status('Bạn không có quyền xem lịch đá bóng.',true);return;}if(['VT02','VT04'].includes(e.detail.maVaiTro))setupStaffView();const params=new URLSearchParams(location.search);$('scheduleDate').value=/^\d{4}-\d{2}-\d{2}$/.test(params.get('date')||'')?params.get('date'):today();if([...$('scheduleState').options].some(o=>o.value===params.get('status')))$('scheduleState').value=params.get('status');load();});
})();
