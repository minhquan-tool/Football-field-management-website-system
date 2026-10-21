/* Presentation only: no requests, role decisions or business state changes. */
document.addEventListener('DOMContentLoaded',()=>{
    const content=document.querySelector('main');
    if(content){
        if(!content.id)content.id='fcMainContent';
        const skip=document.createElement('a');skip.className='fc-skip-link';
        skip.href='#'+content.id;skip.textContent='Chuyển đến nội dung chính';
        content.setAttribute('tabindex','-1');document.body.prepend(skip);
    }
    document.querySelectorAll('table').forEach(table=>{
        const parent=table.parentElement;
        if(getComputedStyle(parent).overflowX==='auto'||getComputedStyle(parent).overflowX==='scroll'){
            parent.classList.add('fc-table-scroll');parent.tabIndex=0;parent.setAttribute('role','region');parent.setAttribute('aria-label','Bảng dữ liệu, cuộn ngang để xem thêm');
        }else{const wrapper=document.createElement('div');wrapper.className='fc-table-scroll';wrapper.tabIndex=0;wrapper.setAttribute('role','region');wrapper.setAttribute('aria-label','Bảng dữ liệu, cuộn ngang để xem thêm');table.before(wrapper);wrapper.append(table);}
    });
    document.querySelectorAll('label').forEach(label=>{
        if(label.htmlFor||label.querySelector('input,select,textarea'))return;
        const control=label.nextElementSibling;
        if(control?.matches('input,select,textarea')&&control.id)label.htmlFor=control.id;
    });
    // Preserve controls, IDs and event handlers. Only add presentation/accessibility metadata.
    if(document.body.dataset.publicPage==='true')return;
    let fieldNumber=0,queued=false;
    const textControl='input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]):not([type="submit"]):not([type="button"]):not([type="reset"]),select,textarea';
    const hints={accountUsername:'Nhập tên đăng nhập...',accountPassword:'Nhập mật khẩu mới...',employeeName:'Nhập họ và tên...',employeePhone:'Nhập số điện thoại...',employeeEmail:'Nhập địa chỉ email...',employeeTitle:'Nhập chức vụ...',accountSearch:'Tên, mã hoặc tên đăng nhập...',employeeSearch:'Tên, mã hoặc số điện thoại...'};
    const names={playDate:'Ngày chơi',searchPitch:'Tìm sân',accountSearch:'Tìm tài khoản',employeeSearch:'Tìm nhân viên',employeeActive:'Trạng thái nhân viên',financeBookingId:'Mã đặt sân',financePromo:'Khuyến mãi',financeTransactionDate:'Ngày giao dịch'};
    function enhanceFields(){
        queued=false;
        document.querySelectorAll('label:not([for])').forEach(label=>{
            if(label.querySelector('input,select,textarea'))return;
            const next=label.nextElementSibling;if(!next)return;
            const controls=next.matches(textControl)?[next]:[...next.querySelectorAll(textControl)];
            if(controls.length===1){if(!controls[0].id)controls[0].id='fcFormField'+(++fieldNumber);label.htmlFor=controls[0].id;}
        });
        document.querySelectorAll('form').forEach(form=>{
            form.querySelectorAll(textControl).forEach(control=>{
                if(control.closest('label')||control.labels?.length||control.closest('.input-group'))return;
                const label=document.createElement('label');label.className='fc-field fc-auto-field';
                label.append(document.createTextNode(names[control.id]||control.getAttribute('aria-label')||control.getAttribute('placeholder')||'Giá trị'));
                control.before(label);label.append(control);
            });
        });
        document.querySelectorAll('label').forEach(label=>{
            const control=label.control;if(!control)return;
            if(control.matches('[type="checkbox"],[type="radio"]')){label.classList.add('fc-check-field');return;}
            label.classList.add('fc-field-label');
            if(label.contains(control))label.classList.add('fc-field');
            if(!control.id)control.id='fcFormField'+(++fieldNumber);
            if(!label.htmlFor)label.htmlFor=control.id;
            control.classList.add('fc-input');
            if(label.classList.contains('fc-auto-field')&&label.hidden!==control.hidden)label.hidden=control.hidden;
            if(control.tagName==='INPUT'&&!control.placeholder&&['text','email','tel','password','search','url'].includes(control.type)){
                const caption=[...label.childNodes].filter(n=>n.nodeType===Node.TEXT_NODE).map(n=>n.textContent).join(' ').replace(/\s+/g,' ').trim();
                control.placeholder=hints[control.id]||('Nhập '+(caption.toLocaleLowerCase('vi')||'thông tin').replace(/\s*\*\s*$/,'')+'...');
            }
            const parent=label.parentElement;
            if(parent){const style=getComputedStyle(parent);const row=style.display==='flex'&&['row','row-reverse'].includes(style.flexDirection);parent.classList.toggle('fc-field-row',row);}
        });
        document.querySelectorAll('#accountRows tr').forEach(row=>{
            const cell=row.lastElementChild;if(!cell||cell.querySelector('.fc-action-menu')||cell.querySelectorAll('button').length<3)return;
            const menu=document.createElement('details');menu.className='fc-action-menu';const summary=document.createElement('summary');summary.textContent='Thao tác';const controls=document.createElement('div');controls.className='fc-action-menu-content';while(cell.firstChild)controls.append(cell.firstChild);menu.append(summary,controls);cell.append(menu);
        });
        for(const id of ['accountForm','employeeForm','profileForm','passwordForm','feedbackForm'])document.getElementById(id)?.classList.add('fc-entry-form');
        document.querySelectorAll('form').forEach(form=>{
            for(const button of form.querySelectorAll('button')){
                const caption=button.textContent.trim();
                if(/^(Đóng|Hủy|Hủy bỏ|Quay lại|Bỏ qua)$/i.test(caption))button.classList.add('fc-secondary-action');
                else if(button.type==='submit'&&!/\bbg-(red|green|orange|amber|yellow)-/.test(button.className))button.classList.add('fc-primary-action');
            }
        });
    }
    enhanceFields();
    window.addEventListener('resize',()=>{if(!queued){queued=true;requestAnimationFrame(enhanceFields);}});
    new MutationObserver(()=>{if(!queued){queued=true;queueMicrotask(enhanceFields);}}).observe(document.body,{childList:true,subtree:true,attributes:true,attributeFilter:['hidden']});
});
