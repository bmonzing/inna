import json
from pathlib import Path

md_path = Path('inna-dev-system.md')
json_path = Path('inna-dev.json')

system_prompt = md_path.read_text(encoding='utf-8').rstrip('\n')

data = json.loads(json_path.read_text(encoding='utf-8'))

if not isinstance(data, list) or not data:
    raise ValueError('Expected a list with at least one model entry')

data[0]['params']['system'] = system_prompt

json_path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + '\n', encoding='utf-8')
print('Updated system prompt in inna-dev.json from inna-dev-system.md')
