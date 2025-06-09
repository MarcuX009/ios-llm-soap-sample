
## Signing and Capabilities
Before you can build the project on a physical device, you must configure the project signing settings:

Open the project in Xcode and select the project file in the Project Navigator.

Select the app target.

Go to the "Signing & Capabilities" tab.

In the "Team" dropdown, select your personal Apple Developer team.

Xcode may show an error next to the Bundle Identifier. You must change this to a unique value. A common practice is to use a reverse domain name you own (e.g., com.yourcompanyname.AppName).

Once the team is selected and the bundle identifier is unique, the signing errors should disappear, and you can build and run the app.
## Add all dependencies
```bash
https://github.com/gonzalezreal/MarkdownUI.git
```
```bash
https://github.com/ml-explore/mlx-swift-examples
```
```bash
https://github.com/apple/swift-async-algorithms.git
```
<img width="877" alt="image" src="https://github.com/user-attachments/assets/d70d39e4-9138-4122-a3d5-3cce57ce739c" />


Make sure the left panel includes the following dependencies:
<img width="228" alt="image" src="https://github.com/user-attachments/assets/5b70d053-a33e-4e40-b15a-625129b1eb3b" />


## (Optional) If you are not using an MLX format model, convert it to MLX first
You can use the mlx-convert tool to convert your model to MLX format.

##  Add your model into the project
In this case, we use **`qwen3-1.7B-MLX-4bit`** as defined in `LLMRegistry.swift`.

To download the model, run:
```bash
git clone https://huggingface.co/lmstudio-community/Qwen3-1.7B-MLX-4bit ./Qwen3-1.7B-MLX
```

or go to huggingface to find any other model that supports MLX format.

## Build
Be sure to use My Mac (Designed for iPad) or your real device (iPhone) for testing.

You should expect to see this if all goes well:
<img width="1016" alt="image" src="https://github.com/user-attachments/assets/367cece3-3d50-4b7d-a5de-f05af5e6117c" />
