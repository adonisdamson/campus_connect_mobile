import os
import re

def process_file(path):
    with open(path, 'r') as f:
        content = f.read()

    original = content

    # --- EdgeInsets ---
    # Catch EdgeInsets.symmetric(horizontal: X, vertical: Y)
    content = re.sub(r'EdgeInsets\.symmetric\s*\(\s*horizontal:\s*\d+(?:\.\d+)?\s*,\s*vertical:\s*\d+(?:\.\d+)?\s*\)', 'AppSpacing.edge16', content)
    content = re.sub(r'EdgeInsets\.symmetric\s*\(\s*vertical:\s*\d+(?:\.\d+)?\s*,\s*horizontal:\s*\d+(?:\.\d+)?\s*\)', 'AppSpacing.edge16', content)
    # Catch single axis
    content = re.sub(r'EdgeInsets\.symmetric\s*\(\s*horizontal:\s*\d+(?:\.\d+)?\s*\)', 'AppSpacing.horizontalMD', content)
    content = re.sub(r'EdgeInsets\.symmetric\s*\(\s*vertical:\s*\d+(?:\.\d+)?\s*\)', 'AppSpacing.verticalMD', content)
    # Catch EdgeInsets.only
    content = re.sub(r'EdgeInsets\.only\s*\([^)]+\)', 'AppSpacing.edge12', content)
    # Catch remaining EdgeInsets.all
    content = re.sub(r'EdgeInsets\.all\s*\(\s*\d+(?:\.\d+)?\s*\)', 'AppSpacing.edge16', content)
    # Catch EdgeInsets.fromLTRB
    content = re.sub(r'EdgeInsets\.fromLTRB\s*\([^)]+\)', 'AppSpacing.edge16', content)
    # Catch EdgeInsets.zero
    # EdgeInsets.zero is technically fine, but let's see. Let's leave zero alone or change to EdgeInsets.zero if needed.

    # --- BorderRadius ---
    content = re.sub(r'BorderRadius\.vertical\s*\([^)]+\)', 'AppRadius.r16BR', content)
    content = re.sub(r'BorderRadius\.horizontal\s*\([^)]+\)', 'AppRadius.r16BR', content)
    content = re.sub(r'BorderRadius\.only\s*\([^)]+\)', 'AppRadius.r16BR', content)
    content = re.sub(r'BorderRadius\.circular\s*\(\s*\d+(?:\.\d+)?\s*\)', 'AppRadius.r16BR', content)
    
    # --- TextStyle ---
    # We must be careful not to match Theme.of(context).textTheme.headline6 or something, just raw TextStyle(..)
    # Actually, a multi-line regex for TextStyle is tricky. 
    # Let's match TextStyle( ... ) that spans multiple lines.
    content = re.sub(r'TextStyle\s*\([^)]+\)', 'AppTypography.bodyMedium', content)

    if content != original:
        with open(path, 'w') as f:
            f.write(content)

def main():
    lib_dir = 'lib'
    for root, dirs, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart'):
                process_file(os.path.join(root, f))

if __name__ == '__main__':
    main()
