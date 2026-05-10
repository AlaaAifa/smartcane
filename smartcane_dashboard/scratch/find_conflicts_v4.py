import re
import os

def find_actual_violations(directory):
    pattern = re.compile(r'(Container|AnimatedContainer)\s*\(\s*(?:[^{}]*?)\bcolor\s*:\s*(?:[^{}]*?)\bdecoration\s*:\s*', re.DOTALL)
    # This is still not perfect. Let's do it right.
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find all Container/AnimatedContainer calls
                for match in re.finditer(r'(Container|AnimatedContainer)\s*\(', content):
                    start = match.start()
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
                        # Check direct properties (depth 1)
                        prop_depth = 0
                        has_color = False
                        has_decoration = False
                        
                        i = match.group(0).find('(') + 1 # start inside parens
                        # Simplified tokenization
                        current_token = ""
                        for j in range(len(match.group(0)), len(block)):
                             c = block[j]
                             if c == '(': prop_depth += 1
                             elif c == ')': prop_depth -= 1
                             
                             if prop_depth == 0:
                                 if re.search(r'\bcolor\s*:', current_token):
                                     # Verify it's not a named param of a nested constructor
                                     has_color = True
                                 if re.search(r'\bdecoration\s*:', current_token):
                                     has_decoration = True
                                 
                                 if c == ',' or c == '\n':
                                     current_token = ""
                                 else:
                                     current_token += c
                        
                        if has_color and has_decoration:
                            line = content.count('\n', 0, start) + 1
                            print(f"BINGO: {path} at line {line}")
                            print(block[:100])

find_actual_violations("lib")
