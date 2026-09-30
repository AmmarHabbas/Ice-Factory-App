import os
import re

lib_dir = r'd:\fawares al-sham vscode\lib'

def fix_double_paren(content):
    """Fix CurrencyFormatter.formatSYP(xxx)) -> CurrencyFormatter.formatSYP(xxx)"""
    # Pattern: formatSYP(something)) with extra closing paren
    content = re.sub(
        r'CurrencyFormatter\.formatSYP\(([^)]+)\)\)',
        r'CurrencyFormatter.formatSYP(\1)',
        content
    )
    return content

def remove_duplicate_formatSYP_lines(content):
    """Remove duplicate consecutive CurrencyFormatter.formatSYP lines.
    The regex created duplicates where the old USD line became SYP 
    and the old SYP line also became SYP."""
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        # Check if this line has formatSYP and the line 2 ahead has the same formatSYP call
        if 'CurrencyFormatter.formatSYP(' in stripped:
            # Look ahead to see if there's a duplicate pattern:
            # Line i:   CurrencyFormatter.formatSYP(x),
            # Line i+1: closing stuff like ),
            # Line i+2: Text(
            # Line i+3: CurrencyFormatter.formatSYP(x),
            # OR more commonly:
            # Line i:   CurrencyFormatter.formatSYP(x),
            # Line i+1: ),
            # Line i+2: Text(
            # Line i+3: CurrencyFormatter.formatSYP(x),
            # Line i+4: ),
            
            # Simpler: check if this line and a nearby line (within 4 lines) 
            # have the same formatSYP call
            match = re.search(r'CurrencyFormatter\.formatSYP\([^)]+\)', stripped)
            if match:
                call = match.group(0)
                # Look for pattern where next few lines contain another Text widget with same call
                # Typical broken pattern:
                #   Text(
                #     CurrencyFormatter.formatSYP(b.total),   <-- keep this
                #     style: ...
                #   ),
                #   Text(                                      <-- remove this duplicate
                #     CurrencyFormatter.formatSYP(b.total),
                #     style: ...
                #   ),
                pass
        result.append(lines[i])
        i += 1
    return '\n'.join(result)

count = 0
for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        content = fix_double_paren(content)
        
        if original != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            count += 1
            print(f'Fixed double-paren in: {filepath}')

print(f'\nFixed {count} files')
