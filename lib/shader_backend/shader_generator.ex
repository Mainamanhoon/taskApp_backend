defmodule ShaderBackend.ShaderGenerator do
  @moduledoc "Fetches GLSL fragment shaders from Google Gemini API."
  require Logger

  @url   "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"


  @spec generate(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def generate(description) when is_binary(description) do
    # Try to get API key from environment variable first, then from config file
    key = System.get_env("GEMINI_API_KEY") || get_api_key_from_config()

    prompt = "Generate a new fragment shader based on this prompt: \"#{description}\"."

    body =
      %{
        contents: [
          %{
            parts: [
              %{
                text: "You are a GLSL fragment shader expert. Generate complete, working fragment shaders based on the user's specific description.

CRITICAL REQUIREMENTS:
- Output ONLY the GLSL code, no explanations or markdown formatting
- ALWAYS start with: precision mediump float;
- ALWAYS include these declarations:
  uniform float u_time;
  uniform vec2 u_resolution;
  uniform vec2 u_mouse;
  varying vec2 fragCoord;

COMMON SENSE & REALISTIC VISUALIZATION:
- Think about how things actually look and behave in real life
- Fireflies: Small, round, bright points that flicker and glow, don't change shape
- Water: Flowing, reflective, with ripples and waves
- Fire: Flickering, orange/yellow, with smoke and embers
- Stars: Small, bright, twinkling points in the sky
- Clouds: Soft, white, billowing shapes that move slowly
- Lightning: Bright, sudden flashes that illuminate briefly
- Smoke: Wispy, gray, flowing upward
- Rain: Falling drops that create ripples on surfaces
- Use realistic physics and behavior patterns
- Consider lighting, shadows, and atmospheric effects
- Make objects behave as they would in nature

SHAPES & OBJECTS FOR VISUAL COMPONENTS:
- Use circles, squares, triangles, and other geometric shapes as building blocks
- Combine multiple shapes to create complex objects (e.g., tree = trunk + leaves)
- Use distance functions (SDF) for precise shape control
- Create organic shapes using noise and mathematical functions
- Layer different shapes to build depth and complexity
- Use shapes to represent real objects (circles for fireflies, rectangles for buildings)
- Consider how shapes interact and overlap
- Use shapes to create patterns, textures, and visual elements

FOCUS ON USER'S REQUEST:
- Create exactly what the user asks for, nothing more
- Don't add features that weren't requested
- Keep it simple if the user asks for something simple
- Make it complex only if the user requests complexity
- Match the user's description as closely as possible

TECHNICAL REQUIREMENTS:
- The shader must compile and run without errors
- Use appropriate techniques for the requested effect
- Keep code clean and well-structured
- Ensure smooth animation if time-based effects are requested

COLOR THEORY REQUIREMENTS:
- Use sophisticated color harmonies (analogous, complementary, triadic)
- Implement smooth color transitions and gradients
- Create atmospheric lighting and mood
- Use color to convey depth and emotion

AVOID:
- Adding unnecessary complexity unless requested
- Including features not mentioned in the user's description
- Over-engineering simple requests
- Generic effects when specific ones are requested
- Unrealistic behavior (e.g., fireflies changing shape)
- Ignoring common sense about how things look

Create a shader that matches the user's description precisely and behaves realistically."
              },
              %{
                text: prompt
              }
            ]
          }
        ],
        generationConfig: %{
          maxOutputTokens: 1500,
          temperature: 0.8
        }
      }
      |> Jason.encode!()

    headers = [
      {"content-type", "application/json"}
    ]

    url = @url <> "?key=" <> key

    Logger.debug("▶️  Calling Gemini API with prompt: #{inspect(description)}")

    with {:ok, %Finch.Response{status: 200, body: r}} <-
           Finch.build(:post, url, headers, body)
           |> Finch.request(ShaderBackend.Finch),
         {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => code} | _]}} | _]}} <-
           Jason.decode(r)
    do
      Logger.debug("✅ Got #{byte_size(code)}-byte shader")
      # Fix common shader issues
      fixed_code = fix_shader_code(code)
      {:ok, String.trim(fixed_code)}
    else
      {:ok, %Finch.Response{status: s, body: b}} ->
        Logger.error("Gemini API HTTP #{s}: #{b}"); {:error, "HTTP #{s}"}
      err ->
        Logger.error("Gemini API error: #{inspect(err)}"); {:error, "API failure"}
    end
  end

  # Fix common shader code issues
  defp fix_shader_code(shader_code) do
    shader_code
    |> ensure_precision_declaration()
    |> ensure_uniform_declarations()
    |> ensure_varying_declaration()
    |> add_missing_functions()
    |> clean_markdown_formatting()
  end

  defp ensure_precision_declaration(code) do
    if String.contains?(code, "precision mediump float") do
      code
    else
      "precision mediump float;\n\n#{code}"
    end
  end

  defp ensure_uniform_declarations(code) do
    cond do
      !String.contains?(code, "uniform float u_time") ->
        code
        |> String.replace("precision mediump float;",
          "precision mediump float;\n\nuniform float u_time;\nuniform vec2 u_resolution;\nuniform vec2 u_mouse;")
      !String.contains?(code, "uniform vec2 u_resolution") ->
        code
        |> String.replace("uniform float u_time;",
          "uniform float u_time;\nuniform vec2 u_resolution;\nuniform vec2 u_mouse;")
      !String.contains?(code, "uniform vec2 u_mouse") ->
        code
        |> String.replace("uniform vec2 u_resolution;",
          "uniform vec2 u_resolution;\nuniform vec2 u_mouse;")
      true ->
        code
    end
  end

  defp ensure_varying_declaration(code) do
    if String.contains?(code, "varying vec2 fragCoord") do
      code
    else
      code
      |> String.replace("uniform vec2 u_mouse;",
        "uniform vec2 u_mouse;\n\nvarying vec2 fragCoord;")
    end
  end

  # Add missing commonly used functions
  defp add_missing_functions(code) do
    code
    |> add_sd_box_function()
    |> add_sd_sphere_function()
    |> add_sd_plane_function()
    |> add_noise_functions()
    |> add_rotation_functions()
  end

  defp add_sd_box_function(code) do
    if String.contains?(code, "sdBox") and !String.contains?(code, "float sdBox") do
      box_function = """

      float sdBox(vec3 p, vec3 b) {
        vec3 q = abs(p) - b;
        return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
      }
      """
      insert_after_uniforms(code, box_function)
    else
      code
    end
  end

  defp add_sd_sphere_function(code) do
    if String.contains?(code, "sdSphere") and !String.contains?(code, "float sdSphere") do
      sphere_function = """

      float sdSphere(vec3 p, float s) {
        return length(p) - s;
      }
      """
      insert_after_uniforms(code, sphere_function)
    else
      code
    end
  end

  defp add_sd_plane_function(code) do
    if String.contains?(code, "sdPlane") and !String.contains?(code, "float sdPlane") do
      plane_function = """

      float sdPlane(vec3 p) {
        return p.y;
      }
      """
      insert_after_uniforms(code, plane_function)
    else
      code
    end
  end

  defp add_noise_functions(code) do
    if String.contains?(code, "noise") and !String.contains?(code, "float noise") do
      noise_functions = """

      float hash(float n) {
        return fract(sin(n) * 43758.5453);
      }

      float noise(vec2 p) {
        vec2 i = floor(p);
        vec2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        float n = i.x + i.y * 57.0;
        return mix(mix(hash(n), hash(n + 1.0), f.x),
               mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
      }
      """
      insert_after_uniforms(code, noise_functions)
    else
      code
    end
  end

  defp add_rotation_functions(code) do
    if String.contains?(code, "rotate") and !String.contains?(code, "vec3 rotate") do
      rotation_functions = """

      vec3 rotateX(vec3 p, float a) {
        float c = cos(a);
        float s = sin(a);
        return vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
      }

      vec3 rotateY(vec3 p, float a) {
        float c = cos(a);
        float s = sin(a);
        return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
      }

      vec3 rotateZ(vec3 p, float a) {
        float c = cos(a);
        float s = sin(a);
        return vec3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
      }
      """
      insert_after_uniforms(code, rotation_functions)
    else
      code
    end
  end

  defp insert_after_uniforms(code, function_code) do
    # Find the position after varying declaration
    case String.split(code, "varying vec2 fragCoord;") do
      [before, rest] ->
        before <> "varying vec2 fragCoord;" <> function_code <> rest
      _ ->
        # If no varying declaration, insert after uniforms
        case String.split(code, "uniform vec2 u_mouse;") do
          [before, rest] ->
            before <> "uniform vec2 u_mouse;\n\nvarying vec2 fragCoord;" <> function_code <> rest
          _ ->
            # Fallback: insert at the beginning after precision
            case String.split(code, "precision mediump float;") do
              [before, rest] ->
                before <> "precision mediump float;\n\nuniform float u_time;\nuniform vec2 u_resolution;\nuniform vec2 u_mouse;\n\nvarying vec2 fragCoord;" <> function_code <> rest
              _ ->
                code
            end
        end
    end
  end

  defp clean_markdown_formatting(code) do
    code
    |> String.replace(~r/^```(?:glsl)?\n?/i, "")
    |> String.replace(~r/```$/, "")
    |> String.replace(~r/^glsl\s*\n?/i, "")
    |> String.replace(~r/^shader\s*\n?/i, "")
    |> String.trim()
  end

  # Read API key from config/env.example file
  defp get_api_key_from_config() do
    config_path = Path.join([File.cwd!(), "config", "env.example"])

    case File.read(config_path) do
      {:ok, content} ->
        # Parse the file to find GEMINI_API_KEY
        lines = String.split(content, "\n")
        api_key_line = Enum.find(lines, fn line ->
          String.starts_with?(String.trim(line), "GEMINI_API_KEY=")
        end)

        case api_key_line do
          nil ->
            Logger.error("GEMINI_API_KEY not found in #{config_path}")
            raise "Set GEMINI_API_KEY env var or add it to config/env.example"
          line ->
            # Extract the API key value
            case String.split(line, "=", parts: 2) do
              ["GEMINI_API_KEY", value] -> String.trim(value)
              _ ->
                Logger.error("Invalid GEMINI_API_KEY format in #{config_path}")
                raise "Invalid GEMINI_API_KEY format in config/env.example"
            end
        end

      {:error, reason} ->
        Logger.error("Could not read #{config_path}: #{reason}")
        raise "Set GEMINI_API_KEY env var or ensure config/env.example exists"
    end
  end
end
