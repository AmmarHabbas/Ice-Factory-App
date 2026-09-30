import os
import json

filepath = r'd:\fawares al-sham vscode\lib\features\workers\workers_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# Add context to _shiftLabel
content = content.replace('String _shiftLabel(String shift) {', 'String _shiftLabel(BuildContext context, String shift) {')
content = content.replace("'Morning  06:00 AM – 02:00 PM'", "context.translate('morning_shift')")
content = content.replace("'Afternoon  02:00 PM – 10:00 PM'", "context.translate('afternoon_shift')")
content = content.replace("'Night  10:00 PM – 06:00 AM'", "context.translate('night_shift')")
content = content.replace('_shiftLabel(worker.shift)', '_shiftLabel(context, worker.shift)')

# Add context to _roleLabel
content = content.replace('String _roleLabel(String role) {', 'String _roleLabel(BuildContext context, String role) {')
content = content.replace("'Driver'", "context.translate('driver')")
content = content.replace("'All Around Worker'", "context.translate('all_around_worker')")
content = content.replace("'Factory Worker'", "context.translate('factory_worker')")
content = content.replace('_roleLabel(worker.role)', '_roleLabel(context, worker.role)')

# Filter chips in workers_screen
content = content.replace("label: 'All'", "label: context.translate('all')")
content = content.replace("label: 'Morning'", "label: context.translate('morning_shift').split(' ')[0]")
content = content.replace("label: 'Afternoon'", "label: context.translate('afternoon_shift').split(' ')[0]")
content = content.replace("label: 'Night Shift'", "label: context.translate('night_shift').split(' ')[0]")

# Pay modal
content = content.replace("'Pay ${worker.firstName}'", "'${context.translate('pay')} ${worker.firstName}'")
content = content.replace("label: 'Salary'", "label: context.translate('salary')")
content = content.replace("label: 'Loan Advance'", "label: context.translate('loan_advance')")
content = content.replace("label: 'Loan Repayment'", "label: context.translate('loan_repayment')")
content = content.replace("'Cancel'", "context.translate('cancel')")
content = content.replace("'Confirm'", "context.translate('confirm')")
content = content.replace("prefixText: '$ '", "prefixText: 'SYP '")
content = content.replace("'Remove Worker'", "context.translate('remove_worker')")

# Some text
content = content.replace("'Search by name or role...'", "context.translate('search_by_name_or_role')")
content = content.replace("'Factory Workforce'", "context.translate('factory_workforce')")
content = content.replace("'No workers found.\\nTap + Add to register one.'", "context.translate('no_workers_found')")

if original != content:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated workers_screen.dart')

