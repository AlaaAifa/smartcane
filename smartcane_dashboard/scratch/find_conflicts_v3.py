import os
import re

def find_violations(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for i, line in enumerate(lines):
                    if "Container(" in line or "AnimatedContainer(" in line:
                        # Scan forward until the container closing paren
                        bracket_depth = 0
                        has_color = False
                        has_decoration = False
                        
                        # Find the matching paren
                        full_content = "".join(lines[i:])
                        # This is still hard. 
                        # Let's just look for lines within the same indentation level.
                        
                        # Simpler: just check if 'color:' and 'decoration:' appear as direct properties.
                        # We'll check the next 10 lines.
                        for j in range(i, min(i + 15, len(lines))):
                            # Property check: start of line (after whitespace) + property name + colon
                            l = lines[j].strip()
                            if l.startswith("color:"):
                                has_color = True
                            if l.startswith("decoration:"):
                                has_decoration = True
                            if l.startswith(");") or l.startswith("),"):
                                if has_color and has_decoration:
                                    print(f"VIOLATION in {path} near line {i+1}")
                                break

find_violations("lib")
