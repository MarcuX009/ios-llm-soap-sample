
## Add all dependencies
<img width="1044" alt="image" src="https://github.com/user-attachments/assets/52bfa706-78fa-4990-a7bf-a371c01fdb34" />

Make sure the left panel includes the following dependencies:
<img width="228" alt="image" src="https://github.com/user-attachments/assets/3321113a-a9fc-4d07-ac75-819dfa24817c" />

## (Optional) If you are not using an MLX format model, convert it to MLX first
You can use the mlx-convert tool to convert your model to MLX format.

##  Add your model into the project
In this case, we use **`qwen3-1.7B-MLX-4bit`** as defined in `LLMRegistry.swift`.

To download the model, run:
```bash
git clone https://huggingface.co/lmstudio-community/Qwen3-1.7B-MLX-4bit ./Qwen3-1.7B-MLX
```

or go to huggingface to find any other model that supports MLX format.