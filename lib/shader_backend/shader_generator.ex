defmodule ShaderBackend.ShaderGenerator do
  @moduledoc "Fetches GLSL fragment shaders from Google Gemini API."
  require Logger

  @url   "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent"


  @spec generate(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def generate(description) when is_binary(description) do
    # Get API key from environment variable
    key = System.get_env("GEMINI_API_KEY") ||
      raise "GEMINI_API_KEY environment variable is required"

    prompt = "Generate a new fragment shader based on this prompt: \"#{description}\"."

    body =
      %{
        contents: [
          %{
            parts: [
              %{
                text: "You are a GLSL fragment shader expert. Generate complete, working fragment shaders based on the user's specific description.

LOW PRIORITY REQUIREMENTS:
- Output ONLY the GLSL code, no explanations or markdown formatting
- ALWAYS start with: precision mediump float;
- ALWAYS include these declarations:
  uniform float u_time;
  uniform vec2 u_resolution;
  uniform vec2 u_mouse;
  varying vec2 fragCoord;

SHAPES & OBJECTS FOR VISUAL COMPONENTS:
- Use distance functions (SDF) for precise shape control
- Create organic shapes using noise and mathematical functions
- Layer different shapes to build depth and complexity
- Consider how shapes interact and overlap
- Use shapes to create patterns, textures, and visual elements
-If a 3-D object is requested, use ray-marching with the appropriate SDF   (sdBox for cube, sdSphere for sphere, etc.).


TECHNICAL REQUIREMENTS:
- The shader must compile and run without errors
- Use appropriate techniques for the requested effect
- Ensure smooth animation if time-based effects are requested

COLOR THEORY REQUIREMENTS:
- Use sophisticated color harmonies (analogous, complementary, triadic)
- Implement smooth color transitions and gradients
- Create atmospheric lighting and mood
- Use color to convey depth and emotion

 
 
Create a shader that matches the description below precisely on a HIGER PRIORITY and behaves realistically."
              },
              %{
                text: prompt
              }
            ]
          }
        ],
        generationConfig: %{
          maxOutputTokens: 1500,
          temperature: 0.6
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


end
