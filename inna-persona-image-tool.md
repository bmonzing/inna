import json
import os
import random
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

import requests
from pydantic import BaseModel, Field
from pydantic.fields import FieldInfo


class Tools:
    def __init__(self):
        pass

    def generate_persona_line_art(
        self,
        persona: str = Field(..., description="Proto-persona JSON string produced by Inna Step 3."),
        persona_id: str = Field(..., description="Slug used for file names, e.g. 'ops_director'."),
        output_dir: str = Field("~/comfyui/output/persona_images", description="Directory (inside ComfyUI's output tree) where generated images are saved."),
        workflow_path: str = Field("/Users/287096/inna/line-art.json", description="Path to the ComfyUI workflow JSON template."),
        comfy_base_url: str = Field("http://127.0.0.1:8188", description="Base URL for the local ComfyUI instance.")
    ) -> str:
        """Generate a single-line persona illustration via ComfyUI using the stored workflow."""
        try:
            persona_data = json.loads(persona)
        except json.JSONDecodeError as exc:
            raise ValueError("Persona must be valid JSON.") from exc

        def resolve_default(value: Any, fallback: Any) -> Any:
            if isinstance(value, FieldInfo):
                if value.default not in (None, ...):
                    return value.default
                factory = value.default_factory
                if factory is not None and callable(factory):
                    return factory()
                return fallback
            return value

        default_output_dir = str((Path.home() / "comfyui" / "output" / "persona_images"))
        output_dir = resolve_default(output_dir, default_output_dir)
        workflow_path = resolve_default(workflow_path, "/Users/287096/inna/line-art.json")
        comfy_base_url = resolve_default(comfy_base_url, "http://127.0.0.1:8188")

        name = (
            persona_data.get("name")
            or persona_data.get("Name")
            or "Unnamed Persona"
        )
        job_title = (
            persona_data.get("job_title")
            or persona_data.get("Job Title")
            or "Professional"
        )
        quote = (
            persona_data.get("quote")
            or persona_data.get("pithy_quotation")
            or persona_data.get("Pithy Quotation")
            or ""
        )
        demographics = (
            persona_data.get("demographics")
            or persona_data.get("Demographics")
            or []
        )
        behaviors = (
            persona_data.get("behaviors")
            or persona_data.get("Behaviors")
            or []
        )
        needs = (
            persona_data.get("needs")
            or persona_data.get("needs_and_wants")
            or persona_data.get("Needs and Wants")
            or persona_data.get("Needs")
            or []
        )

        def clean_phrase(value: str, fallback: str) -> str:
            value = (value or '').strip()
            if not value:
                return fallback
            value = value.rstrip('.')
            return value

        demographic_phrase = clean_phrase(', '.join(demographics), 'modern professional')
        posture_phrase = clean_phrase(behaviors[0] if behaviors else '', 'upright posture, attentive hands')
        gesture_phrase = clean_phrase(behaviors[1] if len(behaviors) > 1 else '', 'confident gesture')
        expression_phrase = clean_phrase(quote, 'calm focus') if len(quote.split()) <= 8 else 'calm, determined expression'
        appearance_phrase = clean_phrase(demographics[0] if demographics else '', 'neat appearance')
        clothing_phrase = f"work-appropriate {job_title.lower()} attire"

        tools_phrase = clean_phrase(needs[0] if needs else '', 'laptop and organized notebook')
        wall_phrase = clean_phrase(needs[1] if len(needs) > 1 else '', 'strategy sketches')
        personal_phrase = clean_phrase(needs[2] if len(needs) > 2 else '', 'succulent plant')

        positive_raw = (
            f"{name}, {job_title}, seated at a desk; "
            f"{posture_phrase}; {expression_phrase}; {appearance_phrase}; {clothing_phrase}. "
            f"Minimal workspace with {tools_phrase}; wall hints ({wall_phrase}); {personal_phrase}."
        )
        positive_words = positive_raw.split()
        if len(positive_words) > 80:
            positive_raw = ' '.join(positive_words[:80])

        notes = (
            f"{name.split()[0] if name else 'Persona'} sits slightly angled with {posture_phrase} and {gesture_phrase}. "
            f"Expression stays {expression_phrase.lower()} to match their approach. "
            f"Environment stays secondary: {tools_phrase}, wall hints of {wall_phrase}, and {personal_phrase} drawn lightly."
        )

        render = {
            'width': 1024,
            'height': 1024,
            'steps': 24,
            'cfg': 5,
            'seed': random.randint(10 ** 5, 10 ** 12),
        }
        persona_prompt = {
            'positive_persona': positive_raw,
            'notes_explanation': notes,
            'render': render,
        }

        workflow_file = Path(workflow_path)
        if not workflow_file.exists():
            raise FileNotFoundError(f"Workflow not found at {workflow_path}")
        workflow = json.loads(workflow_file.read_text(encoding='utf-8'))

        prompt_template = workflow.get('10', {}).get('inputs', {}).get('text')
        if not isinstance(prompt_template, str):
            raise ValueError("Workflow missing expected prompt text at node '10'.")

        prompt_filled = (
            prompt_template.replace('[Name]', name)
            .replace('[Job Title]', job_title)
            .replace('[posture and gesture]', posture_phrase)
            .replace('[expression]', expression_phrase)
            .replace('[appearance]', appearance_phrase)
            .replace('[clothing]', clothing_phrase)
            .replace('[work tools]', tools_phrase)
            .replace('[wall artifacts]', wall_phrase)
            .replace('[personal touches]', personal_phrase)
        )

        workflow['10']['inputs']['text'] = prompt_filled
        workflow['12']['inputs']['seed'] = render['seed']
        workflow['12']['inputs']['steps'] = render['steps']
        workflow['12']['inputs']['cfg'] = render['cfg']

        output_path = Path(output_dir).expanduser()
        output_path.mkdir(parents=True, exist_ok=True)
        filename_prefix = str(output_path / persona_id)
        workflow['17']['inputs']['filename_prefix'] = filename_prefix

        payload = {'prompt': workflow, 'client_id': f"inna-{persona_id}-{datetime.utcnow().timestamp()}"}
        try:
            response = requests.post(
                f"{comfy_base_url.rstrip('/')}/prompt",
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
        except requests.RequestException as exc:
            raise RuntimeError(f"ComfyUI prompt submission failed: {exc}") from exc

        try:
            comfy_ack = response.json()
        except ValueError:
            comfy_ack = {"raw": response.text[:200]}

        result = {
            'persona_id': persona_id,
            'positive_persona': positive_raw,
            'notes_explanation': notes,
            'render': render,
            'workflow_submitted': True,
            'output_prefix': filename_prefix,
            'comfy_response': comfy_ack,
        }
        return json.dumps(result, ensure_ascii=False)
