#llm file is used to interact with the LLM model, in this case, we are using the Ollama API to get responses from the model. The ask_llm function takes a prompt as input and returns the response from the model as a string.
from ollama import chat, ChatResponse

def ask_llm(prompt:str) -> str:

    model="qwen3:8b"
    response = chat(model=model, 
                                messages=[
                                    {"role": "user",
                                     "content": prompt}
                                    ])
    res = response['message']['content'].strip()
    return res