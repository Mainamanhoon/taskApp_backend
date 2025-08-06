# Elixir/Phoenix API for Text-to-Shader Generation

This is the backend for the Dual Interface App, a powerful API built with Elixir and Phoenix. It handles the text-to-shader generation by interfacing with the Google Gemini API and then processing the generated shader code to ensure it's ready for rendering.

## 🛠️ Tech Stack

  * **Backend Framework:** **Phoenix**
  * **Language:** **Elixir**
  * **Concurrency:** **OTP (Open Telecom Platform)**
  * **HTTP Client:** **Finch** (for communicating with the Gemini API)
  * **JSON Library:** **Jason**
  * **CORS:** **cors\_plug**
 
-----
-----

## 🚀 Local Setup

To get the backend server running on your local machine, follow these steps:

1.  **Install Elixir and Erlang:** Make sure you have Elixir and Erlang installed on your system. You can find instructions on the official [Elixir installation page](https://elixir-lang.org/install.html).

2.  **Clone the repository:**

    ```bash
    https://github.com/Mainamanhoon/taskApp_backend.git
    ```

3.  **Install dependencies:**

    ```bash
    mix deps.get
    ```

4.  **Set up environment variables:** Create a `.env` file in the `backend` directory and add your Gemini API key:

    ```
    GEMINI_API_KEY=<your-gemini-api-key>
    ```

5.  **Start the Phoenix server:**

    ```bash
    mix phx.server
    ```

The server will now be running on `http://localhost:4000`.

-----

## ✨ How It Works

This backend is a Phoenix application that exposes a single API endpoint for generating GLSL shaders. When a request is received, it communicates with the Google Gemini API to generate the shader code and then processes the response to ensure it's valid and ready to be used by the frontend.

### Key Features:

  * **AI-Powered Shader Generation:** Utilizes the Google Gemini API to generate complex GLSL fragment shaders from simple text descriptions.
  * **Smart Code Fixing:** Implements a pipeline of functions to automatically fix common issues in the generated shader code, such as missing precision declarations, uniforms, and varying variables.
  * **Production Ready:** Includes CORS configuration, a health check endpoint, and proper error handling, making it ready for production deployment.
  * **High Performance:** Built on Elixir and the BEAM VM, the backend is highly concurrent and can handle a large number of simultaneous requests.

-----

## 🌊 Application Flow

1.  **Request Reception:** The frontend sends a POST request to the `/api/generate_shader` endpoint with a JSON payload containing a `description` of the desired shader.

2.  **Request Validation:** The `ShaderController` validates the incoming request to ensure the `description` parameter is present.

3.  **AI Processing:** The `ShaderGenerator` module calls the Google Gemini API with a detailed prompt that includes the user's description and a set of instructions for generating a valid GLSL fragment shader.

4.  **Code Enhancement:** The `ShaderGenerator` then processes the response from the Gemini API, running a series of "fixer" functions to:

      * Ensure the presence of a `precision mediump float;` declaration.
      * Add any missing `uniform` variables (`u_time`, `u_resolution`, `u_mouse`).
      * Add the `varying vec2 fragCoord;` declaration if it's missing.
      * Inject definitions for commonly used functions like `sdBox`, `sdSphere`, `noise`, etc., if they are used in the generated code but not defined.
      * Clean up any Markdown formatting from the response.

5.  **Response Delivery:** The cleaned and corrected shader code is sent back to the frontend in a JSON response.

-----

## ☁️ Deployment

This backend is designed to be deployed using [Nixpacks](https://nixpacks.com/), which automatically creates a container image from the source code. The `nixpacks.toml` file in the root of the backend project defines the build and start commands.

For a production environment, you'll need to set the following environment variables:

  * `GEMINI_API_KEY`: Your Google Gemini API key.
  * `SECRET_KEY_BASE`: A secret key for signing session cookies. You can generate one with `mix phx.gen.secret`.
  * `PHX_HOST`: The domain name of your application.
  * `PORT`: The port on which the server should listen.

-----



## 🔌 Plugins & Dependencies Analysis
 
  * **Core Phoenix Dependencies:** `phoenix`, `phoenix_pubsub`, `phoenix_html`, `gettext`
  * **API & HTTP Dependencies:** `finch`, `jason`, `cors_plug`, `plug_cowboy`
  * **Development Dependencies:** `phoenix_live_reload`

 -----

## 📁 Folder Structure

The project follows a standard Phoenix application structure:

```
.
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   ├── runtime.exs
│   └── test.exs
├── lib/
│   ├── shader_backend/
│   │   ├── application.ex
│   │   └── shader_generator.ex
│   ├── shader_backend_web/
│   │   ├── controllers/
│   │   │   ├── health_controller.ex
│   │   │   └── shader_controller.ex
│   │   ├── endpoint.ex
│   │   └── router.ex
│   ├── shader_backend.ex
│   └── shader_backend_web.ex
├── priv/
│   ├── gettext/
│   └── static/
├── test/
│   ├── support/
│   │   └── conn_case.ex
│   └── test_helper.exs
├── .formatter.exs
├── .gitignore
├── mix.exs
├── mix.lock
├── nixpacks.toml
└── README.md
```

I hope you enjoy exploring and experimenting with this application\! If you have any questions or suggestions, feel free to open an issue or pull request.
