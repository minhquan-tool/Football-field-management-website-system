"""Verify equal query results and actual scan/seek evidence of the synthetic benchmark."""
from pathlib import Path
import json,re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]/'exports/rubric-indexes'
results=json.loads((root/'results.json').read_text(encoding='utf-8-sig'))
verified=[]
for case in results:
    values={};ops={};times={}
    for phase in ('before','after'):
        raw=(root/f"{case['case']}-{phase}.txt").read_bytes()
        try:text=raw.decode('utf-8-sig')
        except UnicodeDecodeError:text=raw.decode('cp1252') # first Windows run used sqlcmd's ANSI output
        head=text.split('<ShowPlanXML',1)[0]
        values[phase]=[line.strip() for line in head.splitlines() if re.fullmatch(r'(?:[A-Z]\d{9}|\d+(?:\.\d+)?)',line.strip())]
        if len(values[phase])!=1:raise RuntimeError(f"Expected one benchmark result: {case['case']}/{phase}")
        xml=re.search(r'<ShowPlanXML.*?</ShowPlanXML>',text,re.S)
        if not xml or '\ufffd' in xml.group():raise RuntimeError('Missing or lossy actual plan')
        (root/f"{case['case']}-{phase}.sqlplan").write_text(xml.group(),encoding='utf-8')
        plan=ET.ElementTree(ET.fromstring(xml.group()))
        ops[phase]=sorted({e.attrib['PhysicalOp'] for e in plan.iter() if 'PhysicalOp' in e.attrib})
        times[phase]=[e.attrib for e in plan.iter() if e.tag.endswith('QueryTimeStats')]
    if values['before']!=values['after']:raise RuntimeError('Index changed query results')
    if 'Table Scan' not in ops['before'] or 'Index Seek' not in ops['after']:raise RuntimeError('Expected actual scan-to-seek plan transition')
    verified.append(dict(case=case['case'],sameResult=True,result=values['after'][0],physicalOperators=ops,actualQueryTimeStats=times,beforeLogicalReads=case['beforeLogicalReads'],afterLogicalReads=case['afterLogicalReads']))
(root/'verification.json').write_text(json.dumps(dict(status='PASS',scope='synthetic fixtures, not production speedup',cases=verified),ensure_ascii=False,indent=2),encoding='utf-8')
print('INDEX_EVIDENCE_PASS: 5 identical before/after results, 5 actual scan-to-seek transitions; XML, reads and times retained')
