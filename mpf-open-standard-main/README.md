# JL MPF Spec (Modular Personality Format)

**A portable, model-agnostic JSON format for defining reusable AI personalities.**

This project defines a simple, extensible personality schema that works across LLM tools.
It separates an AI personality into clear parts:

- **Identity** – who the agent is
- **Behavior** – how it responds
- **Safety** – what boundaries it follows
- **Extensions** – optional engine-specific features (for example: `jl_engine`)

The goal is to make AI personalities **shareable, consistent, and easy to integrate**
across different systems, frameworks, and models.

---

## Why MPF exists

Every tool invents its own persona format: different field names, structures, and flags
for essentially the same thing. That makes it hard to:

- reuse personalities across apps
- keep behavior consistent between engines
- version and evolve personalities over time

**MPF (Modular Personality Format)** is an open JSON schema that:
- defines a small, stable core
- leaves room for engine-specific extensions
- is human-readable and git-friendly

---

## MPF in plain English

At a high level, an MPF file answers four questions:

1. **Who is this personality?**  
   Name, role, core backstory, intent.

2. **How should it behave?**  
   Tone, style, constraints, conversational norms, “don’ts”.

3. **What safety boundaries apply?**  
   Non-negotiable rules and limits.

4. **What engine-specific extras are needed?**  
   Optional blocks for a given engine (for example `jl_engine`) so tools can
   attach extra metadata without breaking the core schema.

All of this is stored in a single JSON document with a `schema_version` field
so tools know exactly which version of MPF they are dealing with.

---

## Example: minimal MPF personality

```json
{
  "schema_version": "mpf-jl-extensions-v1",
  "identity": {
    "name": "SparkByte",
    "role": "Playful engineering assistant",
    "summary": "Fast-talking, high-clarity helper tuned for technical workflows."
  },
  "behavior": {
    "style": {
      "tone": "playful, precise, non-condescending",
      "formality": "casual-technical"
    },
    "response_rules": [
      "Prefer concrete examples over abstract theory.",
      "Keep explanations tight unless explicitly asked to go deep.",
      "Never hide uncertainty; call it out and suggest next checks."
    ]
  },
  "safety": {
    "boundaries": [
      "Refuse dangerous or clearly harmful requests.",
      "Do not provide workarounds for platform or safety limits."
    ]
  },
  "extensions": {
    "jl_engine": {
      "default_rhythm": "trot",
      "drift_correction": true
    }
  }
}
```

For more complete examples, see the [`examples/`](examples/) directory.

---

## Schema & validation

The canonical JSON schema for MPF with JL Engine extensions lives in:

- [`schema/mpf-jl-extensions-v1.json`](schema/mpf-jl-extensions-v1.json)

A small Python helper is provided in the `jl_mpf_spec` package to load and
validate MPF documents.

```python
from jl_mpf_spec import load_personality, validate_personality

data = load_personality("examples/sparkbyte.mpf.json")
validate_personality(data)
```

The validator checks:

- that the `schema_version` matches the supported version
- that the document satisfies the JSON schema

If validation fails it raises a descriptive exception so tools can surface
clear errors to users.

---

## CLI usage (from source)

After installing this package from source:

```bash
pip install .
```

you can validate MPF files from the command line:

```bash
mpf examples/sparkbyte.mpf.json
```

Example outputs:

- `mpf OK: examples/sparkbyte.mpf.json`  
- `mpf Validation failed: <reason>`

This makes it easy to integrate MPF checks into CI pipelines or editor tooling.

---

## JL Engine extensions

MPF supports engine-specific extensions without breaking compatibility.

This repository includes the `jl_engine` extension namespace, which allows
the JL Engine to attach rhythm, drift/stability configuration, and other
engine-specific knobs under the `extensions.jl_engine` block while keeping
the core MPF structure portable for other tools.

Other projects are free to define their own extension namespaces, e.g.
`"extensions": { "my_engine": { ... } }`,
as long as they do not alter or break the core schema.

---

## Roadmap

Planned and in-progress work includes:

- **Spec refinement**  
  - Collect feedback on the `mpf-jl-extensions-v1` schema.
  - Clarify required vs optional fields and recommended patterns.

- **Language bindings**  
  - Expand beyond Python helpers to additional languages (TypeScript, etc.).

- **Tooling**  
  - Harden the CLI validator and add better error messages.
  - Provide small examples of MPF integration in popular agent frameworks.

- **Docs**  
  - Host a minimal docs site with schema reference, examples, and migration notes.

See the issue tracker for open proposals and discussion.

---

## Contributing

Contributions and critique are welcome.

1. Fork the repo
2. Create a feature branch
3. Add or update tests where appropriate
4. Open a PR describing the change and its impact on the spec

For schema changes, please:
- note whether the change is backwards compatible
- update `schema_version` and/or changelog as needed

Bug reports, questions, and design feedback are all helpful, especially from
people integrating MPF into real tools.

---

## License

MIT License.  
Use it, modify it, ship it — just credit the spec.
