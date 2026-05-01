import re

pbx_path = 'Clipy.xcodeproj/project.pbxproj'
with open(pbx_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if '[CP] Check Pods Manifest.lock' in line: continue
    if '[CP] Embed Pods Frameworks' in line: continue
    if '[CP] Copy Pods Resources' in line: continue
    if 'baseConfigurationReference =' in line and 'Pods-' in line: continue
    if 'Pods_Clipy.framework' in line: continue
    if 'Pods_ClipyTests.framework' in line: continue
    if 'D308B3D847EEAF20B17182CE' in line: continue # Pods group
    if 'D308B3D847EEAF20B17182CE /* Pods */' in line: continue
    
    new_lines.append(line)

with open(pbx_path, 'w') as f:
    f.writelines(new_lines)

print("Cleaned project.pbxproj")
