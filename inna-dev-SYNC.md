## Inna Workspace Model Prompt Management

- Edit the system prompt in `inna-dev-system.md` using regular Markdown.
- When you're ready to sync it back into `inna-dev.json`, run:
  ```bash
  python md-to-json-system.py
  ```
- The script updates the JSON while preserving formatting and special characters.
- You can re-check JSON validity anytime with:
  ```bash
  python -m json.tool inna-dev.json
  ```
