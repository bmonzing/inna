# Image gen workflow

# **Image gen workflow**

## Summary
1. Generate text for proto-persona(s) in conversation with user.
2. Save proto-persona(s) text for future reference.
3. Use instructions from `persona-image-prompt-module.md` to translate proto-persona(s) text into persona-specific image prompt(s) for `line-art.json`.
4. Generate proto-persona image(s) and save for future reference.

## Workflow details

### 1. Generate text for proto-persona(s) in conversation with user

#### 1.1 Description
- Gather how many personas the client needs and capture any constraints (roles, formats, deadlines).
- Produce each proto-persona with the required sections (name, job title, quotation, demographics, behaviors, needs/wants) and present them for approval.
- Maintain a running table of persona summaries (name → slug → approval status) so later steps know which personas require images.

#### 1.2 Implementation notes
- Update `inna-dev-system.md` to store persona JSON in memory (list keyed by slug) and track approval.
- Ensure `persona_id` slugs are unique; append a numeric suffix if a slug already exists.
- Confirm with the client when the persona set is final before moving to the image generation step.

### 2. Save proto-persona(s) text for future reference

#### 2.1 Description
- Persist persona JSON to a workspace file or database so it can be reused outside the chat.
- Record approval metadata (timestamp, version) to distinguish drafts from final personas.

#### 2.2 Implementation notes
- Extend the workflow log (e.g., `Image_gen_workflow.md` or a dedicated history file) with persona summaries.
- Consider serializing personas into a structured JSON file for downstream automation or auditing.

### 3. Use instructions from `persona-image-prompt-module.md` to translate proto-persona(s) text into prompts

#### 3.1 Description
- Generate positive persona prompt text and notes for each approved persona using the module’s rules.
- Prepare render parameters (seed, steps, cfg) and workflow overrides as needed.

#### 3.2 Implementation notes
- Add helper functions in `inna_persona_image_tool.py` to build the prompt payload; reuse them for both single and batch operations.
- Validate prompts stay within the desired word count (<80 words) and strip trailing punctuation.
- Keep the workflow template (`line-art.json`) in sync with any new placeholders the prompt builder introduces.

### 4. Generate proto-persona image(s) and save for future reference

#### 4.1 Description
- Submit the prepared workflow(s) to ComfyUI and surface the job status (prompt IDs, output prefixes).
- Monitor the ComfyUI output directory until the rendered PNGs appear; notify the client when the files are ready.

#### 4.2 Implementation notes
- Enhance `inna_persona_image_tool.py` with a `generate_persona_line_art_batch` function that loops through multiple personas and returns detailed success/error info.
- Default the output directory to `~/comfyui/output/persona_images` to stay within ComfyUI’s allowed paths.
- Encourage use of a watcher (future web app) to display completed renders without blocking Inna’s conversation.

---

*Notepad ID: 98cdb1c6-04bc-455d-b457-9220ce7c5a8a*

*Created: 10/23/2025, 9:22:49 PM*
