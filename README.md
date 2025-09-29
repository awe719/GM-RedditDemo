# GMEXT-Reddit
Repository for GameMaker's Reddit Extension

This repository was created with the intent of presenting users with the latest version available of the extension (even previous to marketplace updates) and also provide a way for the community to contribute with bug fixes and feature implementation.

This extension will work on WASM (GX.games) export.

## Requirements

The user is required to install Reddit build, development and deployment tool Devvit that can be done through npm with the command - `npm install -g devvit` - which required NPM to be installed in your system.

## Workflow

This extension will hook into the build system to interact with the devvit tool providing a seamless workflow when developing and testing your game.
The following steps will guide you through the process of develop and testing your game:

1. Open the **demo project** or create a new project in GameMaker (and import the Reddit extension package)
2. Open the **Reddit extension options** panel
3. Fill in the **output folder** (this folder is a temporary folder into when your Reddit project is created)
4. Fill in the **project name** (the project name needs to be first created in the [Reddit Development Portal](https://developers.reddit.com/new))

> [!NOTE]
> You can select a simple hello-world template (that doesn't really matter).
> You can also ignore the step to run the final command line in your local machine.

5. Select **GX.games** as your target platform.
6. Press play.

> [!NOTE]
> This will compile and build your GameMaker project, create or update your local Devvit project, upload the project to reddit servers and enter development test mode.

7. Use the command line window URL link to open your project in reddit.

## About the Extension

> [!IMPORTANT]
> **GMEXT-Reddit is a build-time helper, not an API wrapper.**

* **Devvit bridge** – Lightweight wrapper that hooks into the build & run process and avoid manual calls to Devvit tooling.
* **One-click build & run** – The extension plugs into GameMaker’s pipeline so that **Build ► Run** automatically
  1. compiles your game
  2. arranges the folder structure Reddit expects
  3. fires up a Devvit playtest command
  4. hot-reloads your module for rapid testing
* **No extra APIs** – Apart from the minimal Devvit stubs needed for compilation, the extension adds **zero** new Reddit or OAuth endpoints. Any additional calls you need can be inserted manually into the generated JavaScript.  

> [!TIP]
> Included in the demo project there is some code to help you get going with your client-server communications. You can check the `<output>/<project_name>/src/server/index.ts` to check the implementation of some save state, load state, submit score and get leaderboard endpoits.
> The respective API interactions are written in GML and can be found inside the demo project.


Because every transformation happens at *build time*, you keep coding entirely in GML with no extra runtime dependencies or performance overhead.

## Documentation

Guides on how to set up a Reddit developer account and your own subreddit can be found in the official [Reddit Developers](https://developers.reddit.com/docs/quickstart) documentation.
