import os
import glob
import re

def main():
    assets_dir = 'assets'
    lib_dir = 'lib'
    
    all_assets = []
    for root, _, files in os.walk(assets_dir):
        for file in files:
            if file == '.gitkeep' or file.endswith('.md'): continue
            all_assets.append(os.path.join(root, file))
            
    dart_files = glob.glob(f'{lib_dir}/**/*.dart', recursive=True)
    
    used_assets = set()
    for dart_file in dart_files:
        with open(dart_file, 'r') as f:
            content = f.read()
            # Find strings like 'assets/...'
            matches = re.findall(r'[\'"](assets/[^\'"]+)[\'"]', content)
            used_assets.update(matches)
            
    # Also parse pubspec.yaml
    with open('pubspec.yaml', 'r') as f:
        pubspec_content = f.read()
        
    print("=== ASSET VERIFICATION REPORT ===")
    
    unused_assets = []
    for asset in all_assets:
        # Normalize path
        normalized = asset.replace('\\', '/')
        is_used = False
        for used in used_assets:
            if normalized.endswith(used) or used.endswith(normalized):
                is_used = True
                break
        
        if not is_used:
            # Check if directory is listed in pubspec
            dir_path = os.path.dirname(normalized) + '/'
            if dir_path in pubspec_content:
                pass # it's bundled but maybe not used in code
            unused_assets.append(normalized)
            
    print(f"Total Assets found on disk: {len(all_assets)}")
    print(f"Total Assets referenced in code: {len(used_assets)}")
    
    print("\n--- UNUSED ASSETS ---")
    for asset in unused_assets:
        print(f"DELETE: {asset}")
        try:
            os.remove(asset)
            print(f"  -> Deleted {asset}")
        except Exception as e:
            print(f"  -> Failed to delete: {e}")

    # Find broken references
    print("\n--- BROKEN REFERENCES ---")
    for used in used_assets:
        # Some used assets might be dynamically generated strings, ignore them if they have $
        if '$' in used: continue
        if not os.path.exists(used):
            print(f"BROKEN: {used}")

if __name__ == '__main__':
    main()
