import os

def find_conflicts(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endsWith(".dart"):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    # Basic check for Container with both color and decoration
                    # This is very naive but might find something
                    import re
                    # Look for Container( followed by color and decoration before the next closing paren of the container
                    # This is hard with regex, so I'll just look for both strings within a small range
                    containers = re.finditer(r'Container\(|AnimatedContainer\(', content)
                    for match in containers:
                        start = match.start()
                        # Find the end of the container (roughly)
                        end = content.find(')', start + 20) # skip some chars
                        # This is still naive. Let's just scan for lines.
                        
def check_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if "Container(" in line or "AnimatedContainer(" in line:
                # Scan next 15 lines for both color and decoration
                has_color = False
                has_decoration = False
                color_line = -1
                decoration_line = -1
                for j in range(i, min(i + 15, len(lines))):
                    if "color:" in lines[j] and not "BoxDecoration" in lines[j] and not "TextStyle" in lines[j] and not "BorderSide" in lines[j] and not "Icon" in lines[j]:
                         # Check if color is a property of Container
                         # This is tricky. Let's just flag if we see both in same indentation block roughly.
                         has_color = True
                         color_line = j + 1
                    if "decoration:" in lines[j]:
                         has_decoration = True
                         decoration_line = j + 1
                    if ");" in lines[j] or ")," in lines[j]:
                        if has_color and has_decoration:
                            print(f"Conflict in {path} near lines {color_line} and {decoration_line}")
                        break

import sys
for arg in sys.argv[1:]:
    check_file(arg)
