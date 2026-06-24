import os
import glob

def fix_imports():
    for filepath in glob.glob('lib/**/*.dart', recursive=True):
        with open(filepath, 'r') as f:
            content = f.read()
            
        new_content = content.replace("import 'package:maplibre_gl/maplibre_gl.dart';", 
                                      "import 'package:latlong2/latlong2.dart';\nimport 'package:flutter_map/flutter_map.dart';")
        new_content = new_content.replace('MapLibreMapController', 'MapController')
        
        if content != new_content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f'Fixed {filepath}')

if __name__ == '__main__':
    fix_imports()
