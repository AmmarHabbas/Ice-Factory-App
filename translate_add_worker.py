import os
import json

filepath = r'd:\fawares al-sham vscode\lib\features\workers\add_worker_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

original = content

replacements = {
    "'Register New Worker'": "context.translate('register_new_worker') ?? 'Register New Worker'",
    "'Add Worker'": "context.translate('add_worker') ?? 'Add Worker'",
    "'Worker added successfully'": "context.translate('worker_added_successfully') ?? 'Worker added successfully'",
    "'Error: '": "context.translate('error') ?? 'Error: '",
    "'Personal Information'": "context.translate('personal_information') ?? 'Personal Information'",
    "'First Name'": "context.translate('first_name') ?? 'First Name'",
    "'Last Name'": "context.translate('last_name') ?? 'Last Name'",
    "'Phone Number'": "context.translate('phone_number') ?? 'Phone Number'",
    "'Role & Shift'": "context.translate('role_shift') ?? 'Role & Shift'",
    "'Role'": "context.translate('role') ?? 'Role'",
    "'Shift'": "context.translate('shift') ?? 'Shift'",
    "'Salary & Loans'": "context.translate('salary_loans') ?? 'Salary & Loans'",
    "'Monthly Salary (SYP)'": "context.translate('monthly_salary_syp') ?? 'Monthly Salary (SYP)'",
    "'Monthly base salary in SYP'": "context.translate('monthly_base_salary_syp') ?? 'Monthly base salary in SYP'",
    "'Starting Loan Balance (SYP)'": "context.translate('starting_loan_balance_syp') ?? 'Starting Loan Balance (SYP)'",
    "'Any pre-existing debt'": "context.translate('any_pre_existing_debt') ?? 'Any pre-existing debt'",
}

for old, new in replacements.items():
    content = content.replace(old, new)

if original != content:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Updated add_worker_screen.dart')

