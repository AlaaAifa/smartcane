import os
import re

def check_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Match Container( or AnimatedContainer(
    # Then find the content inside the parentheses
    
    idx = 0
    while True:
        match = re.search(r'(Container|AnimatedContainer)\s*\(', content[idx:])
        if not match:
            break
        
        start = idx + match.start()
        # Find closing paren
        depth = 0
        end = -1
        for i in range(start + len(match.group(0)) - 1, len(content)):
            if content[i] == '(': depth += 1
            elif content[i] == ')':
                depth -= 1
                if depth == 0:
                    end = i
                    break
        
        if end != -1:
            block = content[start:end+1]
            # Now we have the block. We need to check if both color: and decoration: are properties of the Container itself.
            # Properties are at depth 1.
            
            d = 0
            has_color = False
            has_decoration = False
            
            # Simple tokenization
            current_prop = ""
            for i in range(len(match.group(0)), len(block)):
                c = block[i]
                if c == '(': d += 1
                elif c == ')': d -= 1
                
                if d == 0:
                    if re.search(r'\bcolor\s*:', current_prop):
                         has_color = True
                    if re.search(r'\bdecoration\s*:', current_prop):
                         has_decoration = True
                    
                    if c == ',' or c == '\n':
                        current_prop = ""
                    else:
                        current_prop += c
            
            if has_color and has_decoration:
                line = content.count('\n', 0, start) + 1
                print(f"BINGO: {path} line {line}")
                print(block[:200])

        idx = start + 1

for root, dirs, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            check_file(os.path.join(root, file))
