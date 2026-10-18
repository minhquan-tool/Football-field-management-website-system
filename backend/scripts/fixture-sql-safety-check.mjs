import assert from 'node:assert/strict';
import {readFileSync, readdirSync} from 'node:fs';
import {resolve} from 'node:path';

// Source-level regression only: never connects to SQL Server or runs cleanup.
const files = readdirSync(import.meta.dirname).filter(name => /^(cleanup|prepare)-.*-test\.sql$/.test(name));
for (const file of files) {
    const sql = readFileSync(resolve(import.meta.dirname, file), 'utf8');
    const statements = sql.replace(/--[^\r\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '');
    assert.ok(!/^\s*USE\s+/im.test(statements), `${file}: must not switch database after preflight`);
    assert.match(statements, /^\s*:ON ERROR EXIT\s*$/im, `${file}: sqlcmd must stop on guard failure`);
    assert.match(statements, /\$\(SAN_BONG_TEST_MODE\)/, `${file}: explicit test opt-in required`);
    const guard = statements.indexOf('SanBongEnvironment');
    const write = statements.search(/^\s*(?:INSERT\s+(?:INTO\s+)?|UPDATE\s+|DELETE\s+(?:FROM\s+)?)/im);
    assert.ok(guard >= 0 && write > guard, `${file}: validate the selected database before fixture writes`);
}
console.log(`FIXTURE_SQL_POLICY_PASS: ${files.length} scripts; no SQL executed.`);
