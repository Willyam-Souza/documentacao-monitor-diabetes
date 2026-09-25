import re
import os

base_path = r'c:\Users\willy\OneDrive\Área de Trabalho\documentacao-monitor-diabetes'

with open(os.path.join(base_path, 'index.html'), 'r', encoding='utf-8') as f:
    orig = f.read()

with open(os.path.join(base_path, 'template.html'), 'r', encoding='utf-8') as f:
    template = f.read()

# 1. Extract Dictionary
dic_match = re.search(r'const dictionaryData = (\[.*?\]);', orig, re.DOTALL)
if dic_match:
    dic_data = dic_match.group(1)
    template = template.replace("const dictionaryData = [];", f"const dictionaryData = {dic_data};")

# 2. Extract SQL
try:
    sql_data = orig.split('<pre id="sql-code">')[1].split('</pre>')[0]
    template = template.replace('<!-- SQL WILL BE INJECTED HERE -->', sql_data)
except IndexError:
    pass

# 3. Extract Stack (Visão Geral - Callouts)
try:
    # Get everything after <div class="stack"> and before the end of the section
    stack_data = orig.split('<div class="stack">')[1].split('</section>')[0]
    # Remove the trailing </div> of the stack
    stack_data = stack_data.rsplit('</div>', 1)[0]
    template = template.replace('<!-- Will inject blocks from old index.html -->', stack_data)
except IndexError:
    pass

# Write back to index.html
with open(os.path.join(base_path, 'index.html'), 'w', encoding='utf-8') as f:
    f.write(template)

print("SUCESSO: Template injetado e consolidado em index.html")
