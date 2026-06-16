function start_prose_llm
    llama-server \
        -m ~/.cache/huggingface/hub/gpt-oss-20b/gpt-oss-20b-Q3_K_M.gguf \
        -c 4096 --parallel 1 -ngl 99 -fa off --port 8891
end
