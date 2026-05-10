import re
import sys

def find_actual_conflicts(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # This regex looks for Container or AnimatedContainer
    # then matches content until the end of the constructor
    # then we check if both 'color:' and 'decoration:' are present AS TOP-LEVEL properties of the container
    
    # Simplified approach: find all Container/AnimatedContainer blocks
    # We'll use a simple parser to find the matching parens
    
    idx = 0
    while True:
        match = re.search(r'(Container|AnimatedContainer)\s*\(', content[idx:])
        if not match:
            break
        
        start_idx = idx + match.start()
        # Find matching closing paren
        paren_count = 0
        end_idx = -1
        for i in range(start_idx + len(match.group(0)) - 1, len(content)):
            if content[i] == '(':
                paren_count += 1
            elif content[i] == ')':
                paren_count -= 1
                if paren_count == 0:
                    end_idx = i
                    break
        
        if end_idx != -1:
            block = content[start_idx:end_idx+1]
            # Now we have the block. We need to check if 'color:' and 'decoration:' are properties of the Container itself.
            # We can do this by checking if they appear before any other nested constructors (like BoxDecoration, Column, etc.)
            # Or just check if they are "top-level" in this block.
            
            # Find all properties (roughly)
            # We only care if 'color:' and 'decoration:' both exist at depth 1.
            
            depth = 0
            has_top_color = False
            has_top_decoration = False
            
            # Tokenize by comma or newline roughly
            current_token = ""
            for i in range(len(match.group(0)), len(block)):
                c = block[i]
                if c == '(':
                    depth += 1
                elif c == ')':
                    depth -= 1
                
                if depth == 0:
                    if "color:" in current_token:
                        # Check if it's really the property name
                        if re.search(r'\bcolor\s*:', current_token):
                             has_top_color = True
                    if "decoration:" in current_token:
                        if re.search(r'\bdecoration\s*:', current_token):
                             has_top_decoration = True
                    
                    if c == ',' or c == '\n':
                        current_token = ""
                    else:
                        current_token += c
                else:
                    # just skip nested content
                    pass
            
            if has_top_color and has_top_decoration:
                # Find line number
                line_no = content.count('\n', 0, start_idx) + 1
                print(f"REAL CONFLICT in {path} at line {line_no}")
                print(block[:100] + "...")

        idx = start_idx + 1

for arg in sys.argv[1:]:
    find_actual_conflicts(arg)
