import json

with open('/Users/pranavkoradiya/.gemini/antigravity-ide/brain/ea918c85-1d81-4eb7-ac80-9285b80df0b5/.system_generated/logs/transcript.jsonl', 'r') as f:
    lines = f.readlines()

for line in reversed(lines):
    data = json.loads(line)
    if 'tool_calls' in data:
        for tc in data['tool_calls']:
            if tc.get('function_name') == 'run_command':
                args = tc.get('arguments', {})
                if 'git checkout' in args.get('CommandLine', ''):
                    print("Found git checkout")
