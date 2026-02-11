# Ollama + Aider configuration
export OLLAMA_API_BASE=http://localhost:11434
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_KEEP_ALIVE="10m"

alias aidev='aider --model ollama/qwen2.5-coder:7b'
