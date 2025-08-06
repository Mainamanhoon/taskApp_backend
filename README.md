 
#   Backend (Phoenix) — Text-to-GLSL API

> Phoenix/Elixir backend that turns natural-language descriptions into **clean, working GLSL fragment shaders** via the Google **Gemini** API, then auto-fixes common issues so the code is ready to render.

 
---

## Features

* **AI-powered shader generation** (Google Gemini)
* **Smart code fixing pipeline**

  * Ensures `precision mediump float;`
  * Adds missing uniforms: `u_time`, `u_resolution`, `u_mouse`
  * Ensures `varying vec2 fragCoord;`
  * Injects commonly used helpers (SDF, noise, rotation) when referenced but undefined
  * Strips markdown formatting/`fences`
* **Production-ready Phoenix app**

  * CORS configured
  * Health endpoint
  * Robust error handling & logging
* **High-performance & concurrent** (OTP/BEAM)

---

## Quick Start

### 1) Prerequisites

* Erlang/OTP & Elixir installed (Elixir ≥ 1.16 recommended)
* A **Google Gemini** API key

### 2) Clone & install deps

```bash
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>/backend
mix deps.get
```

### 3) Configure environment

Use the provided example and set your key:

```bash
cp example.env .env
# Edit .env and set your real key
# GEMINI_API_KEY=your_gemini_api_key_here
source .env
```

**Required env vars:**

* `GEMINI_API_KEY` — your Gemini key (required)
* `PORT` — server port (defaults to **4000** in dev)
* `SECRET_KEY_BASE` — required in production
* `PHX_HOST` — host/domain in production (e.g., `api.example.com`)

### 4) Run

```bash
mix phx.server
# App: http://localhost:4000  (or $PORT)
```

---

## API

### Health

`GET /health`
**200** → `{"status":"ok"}`

### Generate Shader

`POST /api/generate_shader`

**Request body**

```json
{
    "description" : "a roatating cube with a gradient background"
}
```

**Response (200)**

```json
{
    "shader_code": "precision mediump float;\nuniform float u_time;\nuniform vec2 u_resolution;\nuniform vec2 u_mouse;\nvarying vec2 fragCoord;\n\nfloat sdCube(vec3 p, vec3 b) {\n  vec3 q = abs(p) - b;\n  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);\n}\n\nvoid main() {\n  vec2 uv = fragCoord.xy / u_resolution.xy;\n  uv -= 0.5;\n  uv.x *= u_resolution.x/u_resolution.y;\n\n  vec3 col = vec3(uv.y*0.5+0.5, uv.y*0.5, uv.x*0.5+0.5);\n\n  vec3 pos = vec3(uv,0.0);\n  mat2 rot = mat2(cos(u_time), -sin(u_time), sin(u_time), cos(u_time));\n  pos.xy = rot * pos.xy;\n\n  float d = sdCube(pos, vec3(0.2,0.2,0.2));\n  float cube = smoothstep(0.01, 0.0, d);\n  col = mix(col, vec3(1.0,0.5,0.2), cube);\n\n  gl_FragColor = vec4(col, 1.0);\n}"
}
```

> The response contains the cleaned GLSL **fragment shader**.
> If `description` is missing/empty → **400** with an error message.
> Upstream/JSON parsing issues → **5xx** with a descriptive error.

**cURL**

```bash
curl -s -X POST http://localhost:4000/api/generate_shader \
  -H "Content-Type: application/json" \
  -d '{"description":"sparkling fireflies in summer night sky"}'
```

**Fetch (JS)**

```js
const res = await fetch("/api/generate_shader", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ description: "soft neon grid with glow" })
});
const { code } = await res.json();
// -> feed `code` to your WebGL pipeline
```

---

## How It Works (Pipeline)

1. **Prompting Gemini** with a detailed, GLSL-specific system prompt:

   * Output **only** GLSL (no prose/markdown)
   * **Must** start with `precision mediump float;`
   * **Must** include:

     ```glsl
     uniform float u_time;
     uniform vec2  u_resolution;
     uniform vec2  u_mouse;
     varying vec2  fragCoord;
     ```
   * Guidance for realism (e.g., particle sizes, flicker, motion cues)

2. **Fix & Harden**

   * `ensure_precision_declaration/1`
   * `ensure_uniform_declarations/1`
   * `ensure_varying_declaration/1`
   * `add_missing_functions/1`

     * SDF: `sdBox`, `sdSphere`, `sdPlane`
     * Noise/Hash: `hash`, `noise`
     * Rotation: `rotateX`, `rotateY`, `rotateZ`
   * `clean_markdown_formatting/1`

3. **Return JSON** with the cleaned shader code.

---

## Configuration

* **CORS**: Enabled via `cors_plug` for browser clients.
* **HTTP client**: `Finch` (pooled, efficient).
* **JSON**: `Jason`.
* **Port**: Uses `PORT` env var (Phoenix defaults to **4000** in dev).

---

## Project Structure

```
backend/
├─ config/
├─ lib/
│  ├─ shader_backend/
│  │  ├─ application.ex
│  │  └─ shader_generator.ex
│  ├─ shader_backend_web/
│  │  ├─ controllers/
│  │  │  ├─ health_controller.ex
│  │  │  └─ shader_controller.ex
│  │  ├─ endpoint.ex
│  │  └─ router.ex
│  ├─ shader_backend.ex
│  └─ shader_backend_web.ex
├─ priv/
├─ test/
├─ example.env
├─ nixpacks.toml
├─ mix.exs
└─ README.md
```

---

## Development

**Run in dev**

```bash
mix phx.server
```

**Tests**

```bash
mix test
```

**Formatting & lint**

```bash
mix format
```

---

## Deployment

This project includes **Nixpacks** config for containerized deploys.

* Ensure these env vars in your host/platform:

  * `GEMINI_API_KEY` (required)
  * `SECRET_KEY_BASE` (use `mix phx.gen.secret`)
  * `PHX_HOST` (e.g., `api.example.com`)
  * `PORT` (container port you expose)
* Build & run with your platform’s Nixpacks integration (e.g., Railway, Fly, Render).

---

## Error Handling

* Validates `description` presence; otherwise **400**.
* Checks Gemini HTTP status (**200** expected).
* Parses/validates JSON response structure.
* Returns clear, structured errors for upstream or parsing failures.
* Logs details for debugging (avoid leaking secrets in logs).

---

 

 
 

 
 


I hope you enjoy exploring and experimenting with this application\! If you have any questions or suggestions, feel free to open an issue or pull request. XD!
